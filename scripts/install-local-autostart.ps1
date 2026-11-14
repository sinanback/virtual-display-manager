[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PackagePath,[bool]$StartEnabled=$true,[bool]$RecoveryEnabled=$true)
$ErrorActionPreference='Stop'
$install=Join-Path $env:ProgramData 'VirtualDisplayManager'
[IO.Directory]::CreateDirectory($install)|Out-Null
$package=Join-Path $install 'Virtual-Display-Manager-Portable.cmd'
if([IO.Path]::GetFullPath($PackagePath) -ne [IO.Path]::GetFullPath($package)){Copy-Item -LiteralPath $PackagePath -Destination $package -Force}
# Read only the application prefix, retaining the driver's lazy extraction.
$stream=[IO.File]::OpenRead($package)
try {
    $bytes=New-Object byte[] 1048576
    $length=$stream.Read($bytes,0,$bytes.Length)
    $prefix=[Text.Encoding]::UTF8.GetString($bytes,0,$length)
} finally { $stream.Dispose() }
$begin=$prefix.IndexOf('#PS1_PAYLOAD_BEGIN')
$end=$prefix.IndexOf('#VDD_PACKAGE_BEGIN')
if($begin -lt 0 -or $end -le $begin){throw 'Invalid portable application package.'}
$app=$prefix.Substring($begin+18,$end-$begin-18)
$tokens=$null;$errors=$null
[Management.Automation.Language.Parser]::ParseInput($app,[ref]$tokens,[ref]$errors)|Out-Null
if($errors.Count){throw ($errors.Message -join '; ')}
$offset=[Text.Encoding]::UTF8.GetByteCount($prefix.Substring(0,$end+18))
[IO.File]::WriteAllText((Join-Path $install 'Virtual-Display-Manager.ps1'),$app,(New-Object Text.UTF8Encoding($true)))
$wrapper=@'
param([switch]$Resume)
$ErrorActionPreference='Stop'
$data=Join-Path $env:LOCALAPPDATA 'VDD-Yonetici'
[IO.Directory]::CreateDirectory($data)|Out-Null
$log=Join-Path $data 'startup.log'
$paused=Join-Path $data 'monitoring-paused'
if($Resume){Remove-Item -LiteralPath $paused -Force -ErrorAction SilentlyContinue}
elseif(Test-Path -LiteralPath $paused){exit 0}
$guard=New-Object Threading.Mutex($false,'Local\VirtualDisplayManager-Supervisor')
$owns=$false
try{$owns=$guard.WaitOne(0)}catch [Threading.AbandonedMutexException]{$owns=$true}
if(-not $owns){$guard.Dispose();exit 0}
try {
    $existing=$null
    try{$existing=[Threading.Mutex]::OpenExisting('Local\VDD-Yonetici-Auto')}catch [Threading.WaitHandleCannotBeOpenedException]{}
    if($existing){$existing.Dispose();exit 0}
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ([datetime]::UtcNow.ToString('o')+' Starting Virtual Display Manager 2.0.3; PID='+$PID)
    $env:VDD_EMBEDDED_CMD=Join-Path $PSScriptRoot 'Virtual-Display-Manager-Portable.cmd'
    $env:VDD_PACKAGE_OFFSET='__OFFSET__'
    $env:VDD_LAUNCHER=$null
    $env:VDD_EMBEDDED_PACKAGE=$null
    & (Join-Path $PSScriptRoot 'Virtual-Display-Manager.ps1')
    [IO.File]::WriteAllText($paused,[datetime]::UtcNow.ToString('o'))
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ([datetime]::UtcNow.ToString('o')+' Normal application exit; PID='+$PID)
    exit 0
} catch {
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ([datetime]::UtcNow.ToString('o')+' Unexpected exit; PID='+$PID+'; '+($_|Out-String))
    exit 1
} finally {if($owns){$guard.ReleaseMutex()};$guard.Dispose()}
'@
$wrapper=$wrapper.Replace('__OFFSET__',[string]$offset)
$wrapperPath=Join-Path $install 'Start-Manager.ps1'
[IO.File]::WriteAllText($wrapperPath,$wrapper,(New-Object Text.UTF8Encoding($true)))
$user=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments='-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$wrapperPath+'"'
$action=New-ScheduledTaskAction -Execute $exe -Argument ($arguments+' -Resume')
$trigger=New-ScheduledTaskTrigger -AtLogOn -User $user
$principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([timespan]::Zero) -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'Virtual Display Manager' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Virtual display monitoring at user logon; restart after unexpected failure. Explicit Exit application stops monitoring until the next logon or manual start.' -Force | Out-Null
$recovery=New-ScheduledTaskAction -Execute $exe -Argument $arguments
$repeat=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(10)) -RepetitionInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'Virtual Display Manager Recovery' -Action $recovery -Trigger $repeat -Principal $principal -Settings $settings -Description 'Check once per minute. Recover unexpected exits; respect the explicit Exit application pause until next logon.' -Force | Out-Null
if(-not $StartEnabled){Disable-ScheduledTask -TaskName 'Virtual Display Manager'|Out-Null}
if(-not $RecoveryEnabled){Disable-ScheduledTask -TaskName 'Virtual Display Manager Recovery'|Out-Null}
Write-Output ('Installed: '+$install+'; task: Virtual Display Manager; user: '+$user+'; package offset: '+$offset)
