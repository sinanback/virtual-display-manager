[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PackagePath)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$artifacts=Join-Path $root 'artifacts'
[IO.Directory]::CreateDirectory($artifacts)|Out-Null
$report=Join-Path $artifacts ('package-check-'+[guid]::NewGuid().ToString('N')+'.json')
$env:VDD_VERIFY_REPORT=$report
$env:VDD_VERIFY_ERROR=$report+'.error'
$env:VDD_EMBEDDED_CMD=[IO.Path]::GetFullPath($PackagePath)
$line=(Get-Content -LiteralPath $PackagePath -TotalCount 8 | Where-Object {$_ -like 'powershell.exe *'} | Select-Object -First 1)
$match=[regex]::Match($line,'-EncodedCommand ([A-Za-z0-9+/=]+)')
if(-not $match.Success){throw 'Encoded bootstrap not found.'}
$bootstrap=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($match.Groups[1].Value))
$probe=@'
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class VddConsoleProbe { [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); }'
$tokens=$null;$errors=$null
[Management.Automation.Language.Parser]::ParseFile($s,[ref]$tokens,[ref]$errors)|Out-Null
if($errors.Count){throw ($errors.Message -join '; ')}
$stream=[IO.File]::OpenRead($env:VDD_EMBEDDED_CMD)
try{$stream.Position=[long]$env:VDD_PACKAGE_OFFSET;$signature=New-Object byte[] 4;$stream.Read($signature,0,4)|Out-Null}finally{$stream.Dispose()}
[pscustomobject]@{ConsoleHandle=[VddConsoleProbe]::GetConsoleWindow().ToInt64();PackageOffset=[long]$env:VDD_PACKAGE_OFFSET;Signature=[BitConverter]::ToString($signature);ScriptLength=(Get-Item -LiteralPath $s).Length;Parsed=$true}|ConvertTo-Json|Set-Content -LiteralPath $env:VDD_VERIFY_REPORT -Encoding UTF8
'@
$bootstrap=$bootstrap.Replace('try{& $s}',('try{'+$probe+'}'))
$bootstrap=$bootstrap.Replace("catch{Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.MessageBox]::Show(`$_.Exception.Message,'Virtual Display Manager')|Out-Null}",'catch{[IO.File]::WriteAllText($env:VDD_VERIFY_ERROR,($_|Out-String));exit 1}')
$newEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrap))
$newLine=$line.Replace($match.Groups[1].Value,$newEncoded)
# The test adds diagnostics to the launch command; invoke that command from a
# PS1 to avoid introducing test-only CMD command-line length constraints.
$command=$newLine.Substring($newLine.IndexOf('-Command "')+10).TrimEnd('"')
& ([scriptblock]::Create($command))
$deadline=(Get-Date).AddSeconds(20)
while(-not (Test-Path -LiteralPath $report) -and -not (Test-Path -LiteralPath $env:VDD_VERIFY_ERROR) -and (Get-Date) -lt $deadline){Start-Sleep -Milliseconds 100}
if(Test-Path -LiteralPath $env:VDD_VERIFY_ERROR){throw (Get-Content -LiteralPath $env:VDD_VERIFY_ERROR -Raw)}
if(-not (Test-Path -LiteralPath $report)){throw 'Package bootstrap test timed out.'}
$r=Get-Content -LiteralPath $report -Raw|ConvertFrom-Json
if($r.ConsoleHandle -ne 0 -or $r.Signature -ne '50-4B-03-04' -or -not $r.Parsed){throw 'Package bootstrap verification failed.'}
Write-Output ('PASS: console-free child, valid extracted application, lazy ZIP offset '+$r.PackageOffset+', prefix-only startup ('+$r.ScriptLength+' script bytes).')
