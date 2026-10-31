# Virtual Display Manager 2.0 · Windows PowerShell 5.1 / Windows 10–11 x64
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$script:launchWatch=[Diagnostics.Stopwatch]::StartNew()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
__RESOURCES__
$script:BackendCode=@'
__BACKEND__
'@
$script:dataRoot=Join-Path $env:LOCALAPPDATA 'VDD-Yonetici'
$script:settingsFile=Join-Path $script:dataRoot 'settings.json'
$script:logFile=Join-Path $script:dataRoot 'activity.jsonl'
$script:language='tr'
try {
    if (Test-Path -LiteralPath $script:settingsFile) {
        $saved=Get-Content -LiteralPath $script:settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($saved.language -in @('tr','en')) { $script:language=$saved.language }
    }
} catch { }
function T([string]$Key) { return [string]$script:Strings[$script:language][$Key] }
function Is-Administrator {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    try { (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } finally { $id.Dispose() }
}
if (-not (Is-Administrator)) {
    try {
        $launcher=if($env:VDD_EMBEDDED_CMD){$env:VDD_EMBEDDED_CMD}else{$env:VDD_LAUNCHER}
        if ($launcher) {
            Start-Process $env:ComSpec -Verb RunAs -WindowStyle Hidden -ArgumentList ('/c ""'+$launcher+'""')
        } else {
            Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -File "'+$PSCommandPath+'"')
        }
    } catch { [Windows.Forms.MessageBox]::Show((T Elevation),(T App))|Out-Null }
    return
}
$script:mutex=New-Object Threading.Mutex($false,'Local\VDD-Yonetici-Auto')
$script:ownsMutex=$false
try { $script:ownsMutex=$script:mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $script:ownsMutex=$true }
if (-not $script:ownsMutex) { [Windows.Forms.MessageBox]::Show((T Already),(T App))|Out-Null; $script:mutex.Dispose(); return }
[Windows.Forms.Application]::EnableVisualStyles()
$script:events=New-Object 'Collections.Generic.List[object]'
$script:snapshot=$null; $script:job=$null; $script:worker=$null; $script:workerReady=$false
$script:lastError=$null; $script:lastSignature=$null; $script:lastDetectionError=$null
$script:pendingTarget='None'; $script:stable=0; $script:nextPoll=[datetime]::MinValue; $script:retryAfter=[datetime]::MinValue
$script:allowExit=$false; $script:closingNotice=$false; $script:updating=$false; $script:storageWarning=$false
$script:icons=@{}; $script:jobAction='Query'; $script:jobAutomatic=$false
try {
    if (Test-Path -LiteralPath $script:logFile) {
        foreach ($line in (Get-Content -LiteralPath $script:logFile -Tail 300 -Encoding UTF8)) {
            try { $script:events.Add(($line|ConvertFrom-Json)) } catch { }
        }
    }
} catch { }
function Save-Settings {
    try {
        [IO.Directory]::CreateDirectory($script:dataRoot)|Out-Null
        $json=@{language=$script:language; version=2}|ConvertTo-Json
        $temp=$script:settingsFile+'.tmp'
        [IO.File]::WriteAllText($temp,$json,(New-Object Text.UTF8Encoding($true)))
        Move-Item -LiteralPath $temp -Destination $script:settingsFile -Force
    } catch { $script:storageWarning=$true }
}
function Add-Activity {
    param([string]$Key,[string]$Action='',[string]$Detail='',[string]$Level='Info',[string]$Source='')
    $entry=[pscustomobject]@{time=[datetime]::UtcNow.ToString('o'); level=$Level; key=$Key; action=$Action; detail=$Detail; source=$Source}
    $script:events.Add($entry)
    if($script:events.Count -gt 500){$script:events.RemoveAt(0)}
    try {
        [IO.Directory]::CreateDirectory($script:dataRoot)|Out-Null
        if((Test-Path -LiteralPath $script:logFile) -and (Get-Item -LiteralPath $script:logFile).Length -gt 2MB){Move-Item -LiteralPath $script:logFile -Destination ($script:logFile+'.old') -Force}
        Add-Content -LiteralPath $script:logFile -Value ($entry|ConvertTo-Json -Compress) -Encoding UTF8
    } catch { $script:storageWarning=$true }
    if($script:activityList){ Add-ActivityRow $entry }
}
function Add-ActivityRow($Entry) {
    $item=New-Object Windows.Forms.ListViewItem(([datetime]::Parse($Entry.time).ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss')))
    $item.SubItems.Add((T $Entry.level))|Out-Null
    $action=if($Entry.action){T $Entry.action}else{T $Entry.key}
    $item.SubItems.Add($action)|Out-Null
    $message=(T $Entry.key)
    if($Entry.source){$message+=' · '+(T $Entry.source)}
    if($Entry.detail){$message+=' · '+$Entry.detail}
    $item.SubItems.Add($message)|Out-Null
    $item.Tag=$Entry
    if($Entry.level -eq 'Error'){$item.ForeColor=[Drawing.Color]::Firebrick}
    elseif($Entry.level -eq 'Warning'){$item.ForeColor=[Drawing.Color]::DarkGoldenrod}
    $script:activityList.Items.Insert(0,$item)|Out-Null
    if($script:activityList.Items.Count -gt 500){$script:activityList.Items.RemoveAt(500)}
}
function Get-AutoTarget($Snapshot) {
    if(-not $Snapshot -or -not $Snapshot.Device -or $Snapshot.DetectionError -or $null -eq $Snapshot.Physical){return 'None'}
    if($Snapshot.Physical -gt 0 -and $Snapshot.Device.Enabled){return 'Disable'}
    if($Snapshot.Physical -eq 0 -and $Snapshot.Device.Disabled){return 'Enable'}
    return 'None'
}
function New-Label([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H) {
    $c=New-Object Windows.Forms.Label; $c.Text=$Text; $c.SetBounds($X,$Y,$W,$H); return $c
}
function New-Button([int]$X,[int]$Y,[int]$W=240,[int]$H=44) {
    $c=New-Object Windows.Forms.Button; $c.SetBounds($X,$Y,$W,$H)
    $c.FlatStyle='Flat'; $c.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(205,215,225)
    $c.BackColor=[Drawing.Color]::White; $c.Cursor=[Windows.Forms.Cursors]::Hand; return $c
}
$script:form=New-Object Windows.Forms.Form
$form.ClientSize=New-Object Drawing.Size(880,700)
$form.AutoScaleMode='Dpi'; $form.StartPosition='CenterScreen'; $form.FormBorderStyle='FixedDialog'; $form.MaximizeBox=$false
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(244,247,251)
$form.ShowInTaskbar=$false
$iconStream=New-Object IO.MemoryStream(,[Convert]::FromBase64String('__APP_ICON__'))
try {
    $loadedIcon=New-Object Drawing.Icon($iconStream)
    try{$script:brandIcon=$loadedIcon.Clone()}finally{$loadedIcon.Dispose()}
}finally{$iconStream.Dispose()}
$form.Icon=$script:brandIcon
$header=New-Object Windows.Forms.Panel; $header.SetBounds(0,0,880,112); $header.BackColor=[Drawing.Color]::FromArgb(22,44,75)
$title=New-Label '' 26 18 520 38; $title.Font=New-Object Drawing.Font('Segoe UI Semibold',23); $title.ForeColor=[Drawing.Color]::White
$subtitle=New-Label '' 29 67 550 25; $subtitle.ForeColor=[Drawing.Color]::FromArgb(191,210,233)
$languageButton=New-Button 690 18 158 35; $languageButton.Font=New-Object Drawing.Font('Segoe UI Semibold',10)
$credit=New-Label '' 530 69 318 24; $credit.TextAlign='MiddleRight'; $credit.ForeColor=[Drawing.Color]::FromArgb(191,210,233); $credit.Font=New-Object Drawing.Font('Segoe UI',9)
$cipher=[Security.Cryptography.Aes]::Create()
try {
    $cipher.Key=[Convert]::FromBase64String('2a4uo5p9j/VfOOaTncycOe7feZeC/pptfq9OEit3p+w='); $cipher.IV=[Convert]::FromBase64String('FQY5rG6vhdckNS6lPvv88A==')
    $bytes=[Convert]::FromBase64String('YRRZv7/0Jg1TmqtJeDCoow/N6+6lxHf8ilVn/xvYWOI='); $decryptor=$cipher.CreateDecryptor()
    try{$script:creditName=([Text.Encoding]::UTF8.GetString($decryptor.TransformFinalBlock($bytes,0,$bytes.Length)) -split ' : ',2)[1]}finally{$decryptor.Dispose()}
}finally{$cipher.Dispose()}
$header.Controls.AddRange(@($title,$subtitle,$languageButton,$credit)); $form.Controls.Add($header)
$tabs=New-Object Windows.Forms.TabControl; $tabs.SetBounds(22,130,836,522); $tabs.Padding=New-Object Drawing.Point(18,8)
$overview=New-Object Windows.Forms.TabPage; $activityTab=New-Object Windows.Forms.TabPage; $guideTab=New-Object Windows.Forms.TabPage
foreach($page in @($overview,$activityTab,$guideTab)){$page.BackColor=[Drawing.Color]::White;$tabs.TabPages.Add($page)}
$status=New-Label '' 24 22 770 36; $status.Font=New-Object Drawing.Font('Segoe UI Semibold',18)
$physical=New-Label '' 26 67 740 27; $physical.Font=New-Object Drawing.Font('Segoe UI Semibold',11)
$deviceDetail=New-Label '' 26 101 764 70; $deviceDetail.ForeColor=[Drawing.Color]::DimGray; $deviceDetail.AutoEllipsis=$true
$install=New-Button 26 185 374; $remove=New-Button 420 185 374
$enable=New-Button 26 243 374; $disable=New-Button 420 243 374
$autoCheck=New-Object Windows.Forms.CheckBox; $autoCheck.SetBounds(26,307,768,30); $autoCheck.Checked=$true
$modeHint=New-Label '' 27 343 768 46; $modeHint.ForeColor=[Drawing.Color]::DimGray
$refresh=New-Button 258 403 310 42
$overview.Controls.AddRange(@($status,$physical,$deviceDetail,$install,$remove,$enable,$disable,$autoCheck,$modeHint,$refresh))
$logHint=New-Label '' 18 16 786 43; $logHint.ForeColor=[Drawing.Color]::DimGray
$script:activityList=New-Object Windows.Forms.ListView; $activityList.SetBounds(18,66,786,264); $activityList.View='Details'; $activityList.FullRowSelect=$true; $activityList.GridLines=$false; $activityList.HideSelection=$false
foreach($width in @(155,90,180,600)){ $activityList.Columns.Add('', $width)|Out-Null }
$activityDetail=New-Object Windows.Forms.TextBox; $activityDetail.SetBounds(18,341,786,70); $activityDetail.Multiline=$true; $activityDetail.ReadOnly=$true; $activityDetail.ScrollBars='Vertical'; $activityDetail.BackColor=[Drawing.Color]::FromArgb(248,250,252)
$export=New-Button 18 424 250 36; $openLogs=New-Button 284 424 250 36
$activityTab.Controls.AddRange(@($logHint,$activityList,$activityDetail,$export,$openLogs))
$guide=New-Object Windows.Forms.TextBox; $guide.SetBounds(18,16,786,445); $guide.Multiline=$true; $guide.ScrollBars='Vertical'; $guide.ReadOnly=$true; $guide.BorderStyle='None'; $guide.BackColor=[Drawing.Color]::White; $guide.Font=New-Object Drawing.Font('Segoe UI',10.5)
$guideTab.Controls.Add($guide)
$footer=New-Label '' 27 665 720 24; $footer.ForeColor=[Drawing.Color]::DimGray
$version=New-Label 'v2.0.0' 773 665 80 24; $version.TextAlign='MiddleRight'; $version.ForeColor=[Drawing.Color]::DimGray
$form.Controls.AddRange(@($tabs,$footer,$version))
$tray=New-Object Windows.Forms.NotifyIcon; $tray.Icon=$script:brandIcon; $tray.Visible=$true
$menu=New-Object Windows.Forms.ContextMenuStrip
$showMenu=$menu.Items.Add(''); $autoMenu=New-Object Windows.Forms.ToolStripMenuItem; $autoMenu.CheckOnClick=$true; $autoMenu.Checked=$true; $menu.Items.Add($autoMenu)|Out-Null
$refreshMenu=$menu.Items.Add(''); $menu.Items.Add((New-Object Windows.Forms.ToolStripSeparator))|Out-Null; $exitMenu=$menu.Items.Add(''); $tray.ContextMenuStrip=$menu
function Update-StateView {
    $busy=($null -ne $script:job -and $script:jobAction -ne 'Query')
    $s=$script:snapshot; $d=if($s){$s.Device}else{$null}
    $key=if(-not $s){'Checking'}elseif(-not $d){'Missing'}elseif($d.Enabled){'On'}elseif($d.Disabled){'Off'}else{'Fault'}
    $status.Text=T $key
    $status.ForeColor=if($key -eq 'On'){[Drawing.Color]::ForestGreen}elseif($key -in @('Fault','Unknown')){[Drawing.Color]::DarkOrange}else{[Drawing.Color]::FromArgb(42,62,85)}
    $physical.Text=(T Physical)+': '+$(if($s -and $null -ne $s.Physical){[string]$s.Physical}else{'—'})
    $deviceDetail.Text=if($d){(T Device)+': '+$d.Name+"`r`n"+(T DeviceId)+': '+$d.Id+"`r`n"+(T ErrorCode)+': '+$d.Code}elseif($s){T NoDevice}else{T Checking}
    $install.Enabled=(-not $busy -and $s -and -not $d)
    $remove.Enabled=(-not $busy -and $null -ne $d)
    $enable.Enabled=(-not $busy -and -not $autoCheck.Checked -and $d -and -not $d.Enabled)
    $disable.Enabled=(-not $busy -and -not $autoCheck.Checked -and $d -and $d.Enabled)
    $autoCheck.Enabled=-not $busy; $autoMenu.Enabled=-not $busy; $refresh.Enabled=-not $busy; $refreshMenu.Enabled=-not $busy
    $modeHint.Text=if($autoCheck.Checked){T AutoHint}else{T ManualHint}
    $errorPresent=($script:lastError -or ($s -and $s.DetectionError) -or $key -eq 'Fault')
    $iconKey=if($errorPresent){'Warning'}elseif($key -eq 'On'){'On'}else{'Off'}
    if($script:icons.ContainsKey($iconKey)){$tray.Icon=$script:icons[$iconKey]}
    $short=if($errorPresent){T Unknown}else{T $key}
    $trayText='VDD · '+$short+' · '+$(if($autoCheck.Checked){T AutoEnabled}else{T AutoDisabled})
    $tray.Text=$trayText.Substring(0,[Math]::Min(63,$trayText.Length))
    $footer.Text=if($busy){T Busy}elseif($script:storageWarning){T SavingError}elseif($errorPresent){T SafeError}elseif($script:stable -gt 0 -and $script:pendingTarget -ne 'None'){T Pending}elseif($s){(T Updated)+': '+$s.CheckedAt.ToString('HH:mm:ss')}else{T Checking}
    $footer.ForeColor=if($errorPresent -or $script:storageWarning){[Drawing.Color]::Firebrick}else{[Drawing.Color]::DimGray}
}
function Apply-Language {
    $script:updating=$true
    try {
        $form.Text=T App; $title.Text=T App; $subtitle.Text=T Subtitle; $languageButton.Text=T Language; $credit.Text=(T Editor)+' : '+$script:creditName
        $overview.Text=T Dashboard; $activityTab.Text=T Activity; $guideTab.Text=T Guide
        $install.Text=T Install; $remove.Text=T Remove; $enable.Text=T Enable; $disable.Text=T Disable; $refresh.Text=T Refresh; $autoCheck.Text=T Auto
        $logHint.Text=T LogHint; $export.Text=T Export; $openLogs.Text=T OpenLogs
        $keys=@('Time','Level','Operation','Detail'); for($i=0;$i -lt 4;$i++){$activityList.Columns[$i].Text=T $keys[$i]}
        $showMenu.Text=T Show; $autoMenu.Text=T AutoMenu; $refreshMenu.Text=T Refresh; $exitMenu.Text=T Exit
        $guide.Text=(T GuideText) -replace '\r?\n',"`r`n"
        $guide.Select(0,0)
        $activityList.BeginUpdate()
        try{$activityList.Items.Clear();foreach($entry in $script:events){Add-ActivityRow $entry}}finally{$activityList.EndUpdate()}
        $activityDetail.Clear(); Update-StateView
    } finally { $script:updating=$false }
}
function Start-Work([string]$Action='Query',[bool]$Automatic=$false) {
    if($script:job){return}
    try {
        if(-not $script:worker){
            $script:worker=[Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
            $script:worker.ApartmentState='MTA'; $script:worker.ThreadOptions='ReuseThread'; $script:worker.Open()
        }
        $ps=[Management.Automation.PowerShell]::Create(); $ps.Runspace=$script:worker
        if(-not $script:workerReady){$ps.AddScript($script:BackendCode)|Out-Null}
        $ps.AddScript('param($action,$automatic,$context) Invoke-Backend $action $automatic $context').AddArgument($Action).AddArgument($Automatic).AddArgument(@{Embedded=$env:VDD_EMBEDDED_CMD;Offset=$env:VDD_PACKAGE_OFFSET;Package=$env:VDD_EMBEDDED_PACKAGE})|Out-Null
        $script:jobAction=$Action; $script:jobAutomatic=$Automatic
        $script:job=[pscustomobject]@{PowerShell=$ps; Handle=$ps.BeginInvoke()}
        if($Action -ne 'Query'){Add-Activity Requested $Action '' Info $(if($Automatic){'AutoReason'}else{'ManualReason'})}
        Update-StateView
    } catch {
        $message=$_.Exception.Message
        if($script:lastError -ne $message){Add-Activity Failure $Action $message Error}
        $script:lastError=$message; $script:nextPoll=(Get-Date).AddSeconds(15)
        if($ps -and -not $script:job){$ps.Dispose()}
        Update-StateView
    }
}
function Complete-Work {
    $job=$script:job; $action=$script:jobAction; $automatic=$script:jobAutomatic; $result=$null
    try {
        $results=$job.PowerShell.EndInvoke($job.Handle)
        if($job.PowerShell.HadErrors){throw ($job.PowerShell.Streams.Error|Out-String)}
        $result=$results | Select-Object -Last 1
        if(-not $result -or -not $result.Snapshot){throw 'The worker returned no device snapshot.'}
        $script:workerReady=$true; $script:snapshot=$result.Snapshot; $script:lastError=$null
        if(-not $script:icons.Count){
            $script:icons.On=[VddHardware]::StateIcon($script:brandIcon,[Drawing.Color]::ForestGreen.ToArgb()); $script:icons.Off=[VddHardware]::StateIcon($script:brandIcon,[Drawing.Color]::Gray.ToArgb()); $script:icons.Warning=[VddHardware]::StateIcon($script:brandIcon,[Drawing.Color]::DarkOrange.ToArgb())
        }
        $d=$script:snapshot.Device
        $signature=if($d){$d.Id+'|'+$d.Code+'|'+$script:snapshot.Physical}else{'Missing|'+$script:snapshot.Physical}
        if($signature -ne $script:lastSignature){Add-Activity Changed '' $signature; $script:lastSignature=$signature}
        if($script:snapshot.DetectionError -and $script:snapshot.DetectionError -ne $script:lastDetectionError){Add-Activity Failure '' $script:snapshot.DetectionError Warning}
        $script:lastDetectionError=$script:snapshot.DetectionError
        if($action -ne 'Query'){
            if($result.Skipped){Add-Activity Changed $action 'Connection changed before execution; no device change was made.' Warning}
            elseif(-not $result.Verified){Add-Activity NotVerified $action $result.Detail Warning; $script:retryAfter=(Get-Date).AddSeconds(15)}
            else{Add-Activity Completed $action $result.Detail Info $(if($automatic){'AutoReason'}else{'ManualReason'})}
            if($result.Reboot){Add-Activity Reboot $action '' Warning; $tray.ShowBalloonTip(6000,(T App),(T Reboot),[Windows.Forms.ToolTipIcon]::Warning)}
        }
    } catch {
        $message=$_.Exception.Message
        if($message -match 'OFFLINE_PACKAGE_MISSING'){$message=T OfflineMissing}
        if($message -ne $script:lastError){Add-Activity Failure $action $message Error}
        $script:lastError=$message; $script:stable=0; $script:pendingTarget='None'; $script:retryAfter=(Get-Date).AddSeconds(15)
        if($action -ne 'Query' -and -not $automatic){[Windows.Forms.MessageBox]::Show((T Failure)+"`n`n"+$message,(T App),'OK','Error')|Out-Null}
    } finally { $job.PowerShell.Dispose(); $script:job=$null; $script:nextPoll=(Get-Date).AddSeconds(3) }
    Update-StateView
    if($result -and $action -eq 'Query' -and $autoCheck.Checked -and -not $script:lastError -and -not $script:queuedAction){
        $target=Get-AutoTarget $script:snapshot
        if($target -eq $script:pendingTarget){$script:stable++}else{$script:pendingTarget=$target;$script:stable=1}
        if($target -eq 'None'){$script:stable=0}
        if($target -ne 'None' -and $script:stable -ge 2 -and (Get-Date) -ge $script:retryAfter){$script:stable=0;Start-Work $target $true}
        Update-StateView
    }
}
function Show-Manager {$form.Show();$form.WindowState='Normal';$form.Activate()}
function Hide-Manager([bool]$Explain=$false) {
    if($Explain -and -not $script:closingNotice){
        $script:closingNotice=$true
        try{[Windows.Forms.MessageBox]::Show($form,((T HideBody).Replace('\n',"`n")),(T HideTitle),'OK','Information')|Out-Null}finally{$script:closingNotice=$false}
    }
    $form.Hide(); Add-Activity Hidden
}
function Request-Action([string]$Action) {
    if($script:job -and $script:jobAction -ne 'Query'){return}
    $titleKey=$Action+'Title'; $bodyKey=$Action+'Body'
    if($Action -in @('Install','Remove','Disable')){
        if([Windows.Forms.MessageBox]::Show($form,(T $bodyKey),(T $titleKey),'YesNo','Warning') -ne 'Yes'){return}
    }
    if($script:job){
        # Queue behind an in-flight read; never race a hardware mutation.
        $script:queuedAction=$Action
    }else{Start-Work $Action}
    if($Action -eq 'Remove'){$autoCheck.Checked=$false}
}
$languageButton.Add_Click({$script:language=if($script:language -eq 'tr'){'en'}else{'tr'};Save-Settings;Apply-Language;Add-Activity LangChanged '' $script:language})
$install.Add_Click({Request-Action Install});$remove.Add_Click({Request-Action Remove});$enable.Add_Click({Request-Action Enable});$disable.Add_Click({Request-Action Disable})
$refresh.Add_Click({$script:nextPoll=[datetime]::MinValue});$refreshMenu.Add_Click({$script:nextPoll=[datetime]::MinValue})
$autoCheck.Add_CheckedChanged({
    if($script:updating){return}
    $autoMenu.Checked=$autoCheck.Checked; $script:stable=0;$script:pendingTarget='None';$script:nextPoll=[datetime]::MinValue
    Add-Activity ModeChanged '' '' Info $(if($autoCheck.Checked){'AutoEnabled'}else{'AutoDisabled'});Update-StateView
})
$autoMenu.Add_Click({$autoCheck.Checked=$autoMenu.Checked})
$tray.Add_DoubleClick({Show-Manager});$showMenu.Add_Click({Show-Manager})
$exitMenu.Add_Click({
    if($script:job -and $script:jobAction -ne 'Query'){[Windows.Forms.MessageBox]::Show((T Busy),(T App))|Out-Null;return}
    if([Windows.Forms.MessageBox]::Show((T ExitBody),(T ExitTitle),'YesNo','Question') -eq 'Yes'){$script:allowExit=$true;$form.Close()}
})
$form.Add_FormClosing({param($sender,$e)
    if(-not $script:allowExit -and $e.CloseReason -eq 'UserClosing'){$e.Cancel=$true;Hide-Manager $true}
})
$form.Add_Resize({if($form.WindowState -eq 'Minimized'){Hide-Manager}})
$activityList.Add_SelectedIndexChanged({
    if($activityList.SelectedItems.Count){$entry=$activityList.SelectedItems[0].Tag;$activityDetail.Text=(T $entry.key)+"`r`n"+$entry.detail}
})
$openLogs.Add_Click({try{[IO.Directory]::CreateDirectory($script:dataRoot)|Out-Null;Start-Process explorer.exe -ArgumentList ('"'+$script:dataRoot+'"')}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,(T App))|Out-Null}})
$export.Add_Click({
    $dialog=New-Object Windows.Forms.SaveFileDialog; $dialog.Filter='JSON Lines (*.jsonl)|*.jsonl';$dialog.FileName='VDD-activity-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.jsonl'
    try{if($dialog.ShowDialog($form) -eq 'OK'){
        $lines=@($script:events|ForEach-Object{$_|ConvertTo-Json -Compress})
        [IO.File]::WriteAllLines($dialog.FileName,[string[]]$lines,(New-Object Text.UTF8Encoding($true)))
        [Windows.Forms.MessageBox]::Show((T Exported),(T App))|Out-Null
    }}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,(T Failure))|Out-Null}finally{$dialog.Dispose()}
})
$timer=New-Object Windows.Forms.Timer;$timer.Interval=150
$timer.Add_Tick({
    try {
        if($script:job){if($script:job.Handle.IsCompleted){Complete-Work};return}
        if($script:queuedAction){$action=$script:queuedAction;$script:queuedAction=$null;Start-Work $action;return}
        if((Get-Date) -ge $script:nextPoll){Start-Work Query}
    } catch {$script:lastError=$_.Exception.Message;Add-Activity Failure '' $script:lastError Error;Update-StateView}
})
$form.Add_Shown({$script:launchWatch.Stop();Add-Activity Started '' ('UI ready: '+$script:launchWatch.ElapsedMilliseconds+' ms');$timer.Start()})
Apply-Language
try {[Windows.Forms.Application]::Run($form)}finally{
    $timer.Stop();$timer.Dispose()
    if($script:job){$script:job.PowerShell.Stop();$script:job.PowerShell.Dispose()}
    if($script:worker){$script:worker.Close();$script:worker.Dispose()}
    Add-Activity Stopped
    $tray.Visible=$false;$tray.Dispose();$menu.Dispose()
    foreach($icon in $script:icons.Values){$icon.Dispose()}
    $form.Dispose()
    $script:brandIcon.Dispose()
    if($script:ownsMutex){$script:mutex.ReleaseMutex()};$script:mutex.Dispose()
}
