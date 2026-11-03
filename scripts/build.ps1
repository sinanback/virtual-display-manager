[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [string]$DriverBundle
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(-not $OutputDirectory){$OutputDirectory=Join-Path $root 'dist'}
if(-not $DriverBundle){$DriverBundle=Join-Path (Split-Path $root -Parent) 'work\VDD-offline-bundle.zip'}
[IO.Directory]::CreateDirectory($OutputDirectory)|Out-Null
$utf8=New-Object Text.UTF8Encoding($true)
$app=[IO.File]::ReadAllText((Join-Path $root 'src\App.ps1'))
$app=$app.Replace('__RESOURCES__',[IO.File]::ReadAllText((Join-Path $root 'src\Resources.ps1'))).Replace('__BACKEND__',[IO.File]::ReadAllText((Join-Path $root 'src\Backend.ps1'))).Replace('__APP_ICON__',[Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $root 'assets\msa-app.ico'))))
$tokens=$null;$errors=$null
[Management.Automation.Language.Parser]::ParseInput($app,[ref]$tokens,[ref]$errors)|Out-Null
if($errors.Count){throw ($errors.Message -join [Environment]::NewLine)}
$appPath=Join-Path $OutputDirectory 'Virtual-Display-Manager.ps1'
[IO.File]::WriteAllText($appPath,$app,$utf8)
# The first PowerShell process is a short-lived launcher. The long-lived worker
# is created with CREATE_NO_WINDOW through ProcessStartInfo.CreateNoWindow.
$launcherTemplate=@'
@echo off
setlocal
__ENV__
powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$p=New-Object Diagnostics.ProcessStartInfo; $p.FileName=Join-Path $PSHOME 'powershell.exe'; $p.Arguments='-NoProfile -STA -ExecutionPolicy Bypass -EncodedCommand __ENCODED__'; $p.UseShellExecute=$false; $p.CreateNoWindow=$true; [Diagnostics.Process]::Start($p) | Out-Null"
endlocal & exit /b
'@
$standaloneBootstrap=@'
try { & $env:VDD_PS1 } catch { Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Virtual Display Manager') | Out-Null }
'@
$launcher=$launcherTemplate.Replace('__ENV__',"set `"VDD_LAUNCHER=%~f0`"`r`nset `"VDD_PS1=%~dp0Virtual-Display-Manager.ps1`"`r`nset `"VDD_EMBEDDED_CMD=`"`r`nset `"VDD_PACKAGE_OFFSET=`"").Replace('__ENCODED__',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($standaloneBootstrap)))
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'Virtual-Display-Manager.cmd'),$launcher,[Text.Encoding]::ASCII)
$readme=Join-Path $OutputDirectory 'README.txt'
[IO.File]::WriteAllText($readme,[IO.File]::ReadAllText((Join-Path $root 'README.md')),$utf8)
Compress-Archive -LiteralPath @($appPath,(Join-Path $OutputDirectory 'Virtual-Display-Manager.cmd'),$readme) -DestinationPath (Join-Path $OutputDirectory 'Virtual-Display-Manager-v2.0.1-scripts.zip') -Force
if(Test-Path -LiteralPath $DriverBundle){
    # Read only the application prefix at startup. Driver bytes are streamed out
    # by the worker only after the user confirms Install driver.
    $bootstrap=@'
try{$f=[IO.File]::OpenRead($env:VDD_EMBEDDED_CMD);try{$b=New-Object byte[] 131072;$m=New-Object IO.MemoryStream;try{do{$n=$f.Read($b,0,$b.Length);$m.Write($b,0,$n);$r=[Text.Encoding]::UTF8.GetString($m.ToArray());$p=$r.IndexOf('#VDD_PACKAGE_BEGIN');if($m.Length -gt 1048576){throw 'Application prefix is too large.'}}while($p -lt 0 -and $n -gt 0);if($p -lt 0){throw 'Package marker is missing.'};$c=$r.IndexOf('#PS1_PAYLOAD_BEGIN');if($c -lt 0){throw 'Application marker is missing.'};$env:VDD_PACKAGE_OFFSET=[string][Text.Encoding]::UTF8.GetByteCount($r.Substring(0,$p+18));$code=$r.Substring($c+18,$p-$c-18)}finally{$m.Dispose()}}finally{$f.Dispose()};$s=Join-Path $env:TEMP ('VDD-'+[guid]::NewGuid().ToString('N')+'.ps1');[IO.File]::WriteAllText($s,$code,(New-Object Text.UTF8Encoding($true)));try{& $s}finally{Remove-Item -LiteralPath $s -Force -ErrorAction SilentlyContinue}}catch{Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Virtual Display Manager')|Out-Null}
'@
    $header=$launcherTemplate.Replace('__ENV__',"set `"VDD_EMBEDDED_CMD=%~f0`"`r`nset `"VDD_LAUNCHER=`"`r`nset `"VDD_EMBEDDED_PACKAGE=`"").Replace('__ENCODED__',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrap)))+"`r`n#PS1_PAYLOAD_BEGIN`r`n"
    foreach($line in ($header -split "`r?`n")){if($line.Length -gt 8000){throw 'CMD command exceeds the safe command-line limit.'}}
    $target=Join-Path $OutputDirectory 'Virtual-Display-Manager-Portable.cmd'
    $output=[IO.File]::Create($target)
    try{
        $prefix=[Text.Encoding]::UTF8.GetBytes($header+$app+"`r`n#VDD_PACKAGE_BEGIN")
        $output.Write($prefix,0,$prefix.Length)
        $input=[IO.File]::OpenRead($DriverBundle)
        try{$input.CopyTo($output)}finally{$input.Dispose()}
    }finally{$output.Dispose()}
    Compress-Archive -LiteralPath $target -DestinationPath (Join-Path $OutputDirectory 'Virtual-Display-Manager-v2.0.1-windows-x64.zip') -Force
}
$artifacts=Get-ChildItem -LiteralPath $OutputDirectory -File | Where-Object {$_.Name -like 'Virtual-Display-Manager*'}
$hashes=$artifacts|Get-FileHash -Algorithm SHA256|ForEach-Object{$_.Hash.ToLowerInvariant()+'  '+[IO.Path]::GetFileName($_.Path)}
[IO.File]::WriteAllLines((Join-Path $OutputDirectory 'SHA256SUMS.txt'),[string[]]$hashes,[Text.Encoding]::ASCII)
Write-Output ('Built: '+[IO.Path]::GetFullPath($OutputDirectory))
