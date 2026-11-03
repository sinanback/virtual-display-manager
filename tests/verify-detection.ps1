[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'src\Backend.ps1')
function Assert($Value,[string]$Message) { if(-not $Value) { throw ('FAIL: '+$Message) }; Write-Output ('PASS: '+$Message) }
$live=Get-DeviceSnapshot
if($live.DetectionError) { throw ('Live read-only detection: '+$live.DetectionError) }
Write-Output ('Live read-only physical count: '+$live.Physical)
$pathType=[VddHardware].GetNestedType('DisplayPath',[Reflection.BindingFlags]::NonPublic)
$adapterType=[VddHardware].GetNestedType('AdapterName',[Reflection.BindingFlags]::NonPublic)
if([Runtime.InteropServices.Marshal]::SizeOf([Activator]::CreateInstance($pathType)) -ne 72 -or [Runtime.InteropServices.Marshal]::SizeOf([Activator]::CreateInstance($adapterType)) -ne 276) {
    throw 'Unexpected Windows DisplayConfig structure layout.'
}
$device=[pscustomobject]@{Id='ROOT\DISPLAY\0000';Enabled=$false;Disabled=$true;Code=22}
$script:targets=@(); $script:nativeFails=$false; $script:wmiFails=$true; $script:wmiCount=2; $script:wmiCalls=0
function Get-ActiveDisplayTargets {
    if($script:nativeFails) { throw 'Native display query unavailable' }
    return $script:targets
}
function Get-WmiPhysicalDisplays {
    param($Device)
    $script:wmiCalls++
    if($script:wmiFails) { throw 'Not supported' }
    return $script:wmiCount
}
Assert ((Get-PhysicalDisplays $device) -eq 0) 'Headless native topology stays zero when WMI would throw Not supported'
Assert ($script:wmiCalls -eq 0) 'Successful empty native topology does not depend on WMI'
$script:targets=@([pscustomobject]@{AdapterId=$device.Id;Technology=5})
Assert ((Get-PhysicalDisplays $device) -eq 0) 'VDD reporting HDMI technology is not counted as a physical monitor'
$script:targets+=@([pscustomobject]@{AdapterId='PCI\TEST_GPU';Technology=5},[pscustomobject]@{AdapterId='USB\TEST_DISPLAY';Technology=16})
Assert ((Get-PhysicalDisplays $device) -eq 2) 'Physical GPU and USB monitors count while VDD is active'
$script:targets=@([pscustomobject]@{AdapterId='PCI\TEST_GPU';Technology=-2147483648})
Assert ((Get-PhysicalDisplays $device) -eq 1) 'Internal laptop panel is physical'
$script:targets=@([pscustomobject]@{AdapterId='ROOT\REMOTE';Technology=17},[pscustomobject]@{AdapterId='ROOT\WIRELESS';Technology=15})
Assert ((Get-PhysicalDisplays $device) -eq 0) 'Indirect virtual and Miracast displays do not block headless activation'
$script:nativeFails=$true; $script:wmiFails=$false
Assert ((Get-PhysicalDisplays $device) -eq 2) 'Legacy WMI fallback works when native API is unavailable'
$script:wmiFails=$true; $failed=$false
try { Get-PhysicalDisplays $device | Out-Null } catch { $failed=$_.Exception.Message -match 'DisplayConfig:.*WMI fallback:' }
Assert $failed 'Two failed detectors never masquerade as zero monitors'

# Simulate backend mutations, including the final connection check. No real
# hardware-changing function is called by any scenario below.
$script:mutations=@(); $script:physical=0; $script:detectionError=$null
function Get-DeviceSnapshot { [pscustomobject]@{Device=$device;Physical=$script:physical;DetectionError=$script:detectionError} }
function Invoke-DeviceStateChange {
    param($Device,[string]$Action)
    $script:mutations+=$Action
    $Device.Enabled=($Action -eq 'Enable'); $Device.Disabled=($Action -eq 'Disable')
    return $false
}
$r=Invoke-Backend Enable $true
Assert ($r.Verified -and -not $r.Skipped -and $device.Enabled) 'Headless automatic enable reaches the device backend'
$script:physical=1; $r=Invoke-Backend Disable $true
Assert ($r.Verified -and $device.Disabled) 'Monitor attach disables VDD'
$script:physical=0; $r=Invoke-Backend Disable $true
Assert ($r.Skipped -and $script:mutations.Count -eq 2) 'Monitor detached before disable: mutation cancelled'
$script:physical=1; $r=Invoke-Backend Enable $true
Assert ($r.Skipped -and $script:mutations.Count -eq 2) 'Monitor attached before enable: mutation cancelled'
$script:physical=0; $r=Invoke-Backend Enable $true
Assert ($r.Verified -and $device.Enabled) 'Last monitor detached: virtual screen restored'
$script:detectionError='Both detectors failed'; $failed=$false
try { Invoke-Backend Disable $true | Out-Null } catch { $failed=$true }
Assert ($failed -and $script:mutations.Count -eq 3) 'Unknown topology cannot mutate a device'
