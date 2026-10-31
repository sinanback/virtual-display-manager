[CmdletBinding()]
param([string]$ApplicationPath)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(-not $ApplicationPath){$ApplicationPath=Join-Path $root 'dist\Virtual-Display-Manager.ps1'}
if(-not (Test-Path -LiteralPath $ApplicationPath)){throw 'Build the application first, or pass -ApplicationPath.'}
$artifacts=Join-Path $root 'artifacts'
[IO.Directory]::CreateDirectory($artifacts)|Out-Null
$state=Join-Path $artifacts ('test-state-'+[guid]::NewGuid().ToString('N'))
$source=[IO.File]::ReadAllText($ApplicationPath)
$source=$source.Replace('if (-not (Is-Administrator)) {','if ($false) {').Replace('Local\VDD-Yonetici-Auto','Local\VDD-Yonetici-Test-'+[guid]::NewGuid().ToString('N'))
$source=$source.Replace("Join-Path `$env:LOCALAPPDATA 'VDD-Yonetici'",("'"+$state.Replace("'","''")+"'"))
# Avoid a modal help notice in automated window lifecycle tests. Its resources
# and event wiring are checked below; the real notice is a manual release check.
$source=$source.Replace('Hide-Manager $true','Hide-Manager $false')
$checks=@'
function Assert($Value,[string]$Message){if(-not $Value){throw ('FAIL: '+$Message)}}
Assert ((($Strings.tr.Keys|Sort-Object) -join ',') -eq (($Strings.en.Keys|Sort-Object) -join ',')) 'Language key parity'
foreach($language in @('tr','en')){foreach($key in $Strings[$language].Keys){Assert (-not [string]::IsNullOrWhiteSpace($Strings[$language][$key])) ('Nonempty translation '+$language+'/'+$key)}}
$script:language='tr'
Assert ((T HideBody) -match 'Tamamen') 'Turkish close guidance'
Assert ($Strings.en.HideBody -match 'Exit application') 'English close guidance'
Assert (-not $form.ShowInTaskbar) 'No permanent taskbar window entry'
$autoCheck.Checked=$false
$form.Show();[Windows.Forms.Application]::DoEvents();$timer.Stop()
Assert $form.Visible 'Main window visible on launch'
Assert ($install.Visible -and $remove.Visible -and $enable.Visible -and $disable.Visible) 'Buttons rendered before hardware scan'
$uiTime=$script:launchWatch.ElapsedMilliseconds
$script:language='en';Apply-Language;Save-Settings
Assert ($overview.Text -eq 'Overview' -and $remove.Text -eq 'Uninstall driver') 'English interface'
Assert (($tray.ContextMenuStrip.Items|Where-Object Text -eq 'Exit application').Count -eq 1) 'English tray menu'
Assert ((Get-Content $script:settingsFile -Raw|ConvertFrom-Json).language -eq 'en') 'Language persistence'
Add-Activity Completed Enable 'Read-only test event' Info ManualReason
Assert ($activityList.Items[0].SubItems[3].Text -match 'Operation completed') 'English activity translation'
$bmp=New-Object Drawing.Bitmap($form.Width,$form.Height)
$form.DrawToBitmap($bmp,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bmp.Save('__ARTIFACTS__\overview-en.png');$bmp.Dispose()
$script:language='tr';Apply-Language
Assert ($overview.Text -eq 'Genel bakış' -and $remove.Text -eq 'Sürücüyü kaldır') 'Turkish interface'
Assert ($activityList.Items[0].SubItems[3].Text -match 'İşlem tamamlandı') 'Activity retranslated without losing records'
$bmp=New-Object Drawing.Bitmap($form.Width,$form.Height)
$form.DrawToBitmap($bmp,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bmp.Save('__ARTIFACTS__\overview-tr.png');$bmp.Dispose()
$tabs.SelectedTab=$activityTab;[Windows.Forms.Application]::DoEvents()
$bmp=New-Object Drawing.Bitmap($form.Width,$form.Height)
$form.DrawToBitmap($bmp,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bmp.Save('__ARTIFACTS__\activity-tr.png');$bmp.Dispose()
$tabs.SelectedTab=$guideTab;[Windows.Forms.Application]::DoEvents()
$bmp=New-Object Drawing.Bitmap($form.Width,$form.Height)
$form.DrawToBitmap($bmp,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bmp.Save('__ARTIFACTS__\guide-tr.png');$bmp.Dispose()
$fake=[pscustomobject]@{Device=[pscustomobject]@{Enabled=$true;Disabled=$false};Physical=1;DetectionError=$null}
Assert ((Get-AutoTarget $fake) -eq 'Disable') 'Physical display disables enabled VDD'
$fake.Physical=0
Assert ((Get-AutoTarget $fake) -eq 'None') 'Enabled VDD stays enabled without physical displays'
$fake.Device.Enabled=$false;$fake.Device.Disabled=$true
Assert ((Get-AutoTarget $fake) -eq 'Enable') 'No physical displays enables disabled VDD'
$fake.DetectionError='Unknown ancestry'
Assert ((Get-AutoTarget $fake) -eq 'None') 'Unknown ancestry preserves current state'
$fake.DetectionError=$null;$fake.Device.Disabled=$false
Assert ((Get-AutoTarget $fake) -eq 'None') 'Faulty device is not automatically toggled'
$queryWatch=[Diagnostics.Stopwatch]::StartNew()
Start-Work Query
Assert ($null -ne $script:job) 'Background query started'
while($script:job -and $queryWatch.Elapsed.TotalSeconds -lt 30){
    if($script:job.Handle.IsCompleted){Complete-Work}else{Start-Sleep -Milliseconds 30;[Windows.Forms.Application]::DoEvents()}
}
$timer.Stop()
Assert (-not $script:job) 'Background query completes within timeout'
Assert ($null -ne $script:snapshot) ('Read-only hardware snapshot: '+$script:lastError)
Assert ($script:workerReady) 'Background worker initialized'
Write-Output ('UI first shown: '+$uiTime+' ms; first read-only hardware query: '+$queryWatch.ElapsedMilliseconds+' ms; physical displays: '+$script:snapshot.Physical)
$tabs.SelectedTab=$overview;[Windows.Forms.Application]::DoEvents()
$bmp=New-Object Drawing.Bitmap($form.Width,$form.Height)
$form.DrawToBitmap($bmp,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bmp.Save('__ARTIFACTS__\overview-live-tr.png');$bmp.Dispose()
# Exercise the asynchronous completion/policy path without device mutations.
# Start-Work is replaced only inside this generated test process.
$script:capturedActions=@()
function Start-Work {param([string]$Action,[bool]$Automatic);$script:capturedActions+=($Action+':'+$Automatic)}
$script:fakeSnapshot=[pscustomobject]@{Device=[pscustomobject]@{Id='ROOT\TEST';Name='Test VDD';Enabled=$true;Disabled=$false;Code=0};Physical=1;DetectionError=$null;CheckedAt=[datetime]::Now}
$script:fakeResult=[pscustomobject]@{Snapshot=$script:fakeSnapshot;Detail='';Reboot=$false;Verified=$true;Skipped=$false}
function Complete-FakeQuery {
    $ps=[pscustomobject]@{HadErrors=$false}
    $ps|Add-Member ScriptMethod EndInvoke {param($handle);return $script:fakeResult}
    $ps|Add-Member ScriptMethod Dispose {}
    $script:job=[pscustomobject]@{PowerShell=$ps;Handle=$null};$script:jobAction='Query';Complete-Work
}
$autoCheck.Checked=$true;$script:pendingTarget='None';$script:stable=0;$script:retryAfter=[datetime]::MinValue
Complete-FakeQuery;Assert ($script:capturedActions.Count -eq 0) 'Debounce first sample'
Complete-FakeQuery;Assert (($script:capturedActions -join ',') -eq 'Disable:True') 'Second stable sample queues automatic disable'
$script:fakeSnapshot.Physical=0;$script:fakeSnapshot.Device.Enabled=$false;$script:fakeSnapshot.Device.Disabled=$true;$script:fakeSnapshot.Device.Code=22
Complete-FakeQuery;Complete-FakeQuery
Assert (($script:capturedActions -join ',') -eq 'Disable:True,Enable:True') 'Detach queues automatic enable after two samples'
$script:fakeSnapshot.DetectionError='Simulated monitor detection failure'
Complete-FakeQuery;Complete-FakeQuery
Assert ($script:capturedActions.Count -eq 2) 'Detection failure never queues device mutation'
Assert ($footer.Text -eq (T SafeError)) 'Detection failure is visible'
$autoCheck.Checked=$false
$form.Close();Assert (-not $form.Visible -and -not $form.IsDisposed) 'Close hides to tray'
Assert $tray.Visible 'Tray remains active'
Show-Manager;Assert $form.Visible 'Tray can restore main window'
$script:allowExit=$true;$form.Close();Assert $form.IsDisposed 'Explicit exit closes window'
Write-Output 'PASS: localization, saved language, activity translation, first render, safe policy, async hardware query, debounce/attach/detach/failure, hide/restore/exit'
'@
$checks=$checks.Replace('__ARTIFACTS__',$artifacts)
$source=$source.Replace('[Windows.Forms.Application]::Run($form)',$checks)
$testPath=Join-Path $artifacts 'verify-generated.ps1'
[IO.File]::WriteAllText($testPath,$source,(New-Object Text.UTF8Encoding($true)))
& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $testPath
if($LASTEXITCODE -ne 0){throw 'Application verification failed.'}
