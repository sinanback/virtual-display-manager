# Executed exclusively in the worker runspace. Never touches WinForms controls.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Management
if (-not ('VddHardware' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Text;
using System.Runtime.InteropServices;
public static class VddHardware {
    [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] static extern uint CM_Locate_DevNodeW(out uint node, string id, uint flags);
    [DllImport("cfgmgr32.dll")] static extern uint CM_Get_Parent(out uint parent, uint node, uint flags);
    [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] static extern uint CM_Get_Device_IDW(uint node, StringBuilder id, uint length, uint flags);
    [DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr icon);
    public static string Parent(string id) {
        uint node, parent;
        if (CM_Locate_DevNodeW(out node,id,0)!=0 || CM_Get_Parent(out parent,node,0)!=0) throw new InvalidOperationException("Cannot resolve monitor ancestry: " + id);
        var text=new StringBuilder(512);
        if (CM_Get_Device_IDW(parent,text,512,0)!=0) throw new InvalidOperationException("Cannot read parent device ID.");
        return text.ToString();
    }
    public static Icon StateIcon(Icon logo, int color) {
        using(var b=new Bitmap(32,32)) using(var g=Graphics.FromImage(b)) using(var brush=new SolidBrush(Color.FromArgb(color))) {
            g.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent); g.DrawIcon(logo,new Rectangle(0,0,32,32));
            g.FillEllipse(Brushes.White,20,20,12,12); g.FillEllipse(brush,22,22,8,8);
            IntPtr h=b.GetHicon();
            try { using(var borrowed=Icon.FromHandle(h)) return (Icon)borrowed.Clone(); } finally { DestroyIcon(h); }
        }
    }
}
"@
}
function Get-DeviceSnapshot {
    $device = $null
    $query = New-Object Management.ManagementObjectSearcher("SELECT * FROM Win32_PnPEntity WHERE PNPClass='DISPLAY'")
    $query.Options.Timeout = [timespan]::FromSeconds(8)
    try {
        $items=$query.Get()
        try {
            foreach ($item in $items) {
                try {
                    $name=[string]$item.Name; $id=[string]$item.PNPDeviceID
                    if ($item.Present -eq $false) { continue }
                    if ($name -in @('Virtual Display Driver','IddSampleDriver Device HDR') -or $id -like 'ROOT\MTTVDD*') {
                        $code=[int]$item.ConfigManagerErrorCode
                        if ($device) { throw 'Multiple VDD devices found; remove duplicate devices before using automatic control.' }
                        $device=[pscustomobject]@{Name=$name; Id=$id; Code=$code; Enabled=($code -eq 0); Disabled=($code -eq 22); Path=$item.Path.Path}
                    }
                } finally { $item.Dispose() }
            }
        } finally { $items.Dispose() }
    } finally { $query.Dispose() }
    $count=$null; $detectionError=$null
    try { $count=Get-PhysicalDisplays $device } catch { $detectionError=$_.Exception.Message }
    [pscustomobject]@{Device=$device; Physical=$count; DetectionError=$detectionError; CheckedAt=[datetime]::Now}
}
function Get-PhysicalDisplays {
    param($Device)
    $query=New-Object Management.ManagementObjectSearcher('root\wmi','SELECT * FROM WmiMonitorConnectionParams')
    $query.Options.Timeout=[timespan]::FromSeconds(8)
    $count=0
    try {
        $items=$query.Get()
        try {
            foreach ($item in $items) {
                try {
                    if (-not $item.Active) { continue }
                    if ([uint32]$item.VideoOutputTechnology -notin @(0,1,2,3,4,5,6,8,9,10,11,12,13,15,16,2147483648)) { continue }
                    $id=([string]$item.InstanceName) -replace '_\d+$',''
                    $resolved=$false; $virtual=$false
                    for($depth=0;$depth -lt 16;$depth++) {
                        if (($Device -and $id -eq $Device.Id) -or $id -like 'ROOT\MTTVDD*') { $virtual=$true; $resolved=$true; break }
                        if ($id -like 'PCI\*' -or $id -like 'USB\*') { $resolved=$true; break }
                        $id=[VddHardware]::Parent($id)
                    }
                    if (-not $resolved) { throw 'Physical monitor ancestry could not be verified.' }
                    if (-not $virtual) { $count++ }
                } finally { $item.Dispose() }
            }
        } finally { $items.Dispose() }
    } finally { $query.Dispose() }
    return $count
}
function Invoke-HiddenTool {
    param([string]$File,[string]$Arguments,[int[]]$SuccessCodes=@(0,3010))
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=$File; $info.Arguments=$Arguments
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $process=New-Object Diagnostics.Process
    $process.StartInfo=$info
    try {
        if (-not $process.Start()) { throw 'Cannot start installation tool.' }
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(300000)) { throw 'The driver tool did not finish within five minutes. Check Task Manager before retrying.' }
        $output=$stdout.Result + [Environment]::NewLine + $stderr.Result
        if ($process.ExitCode -notin $SuccessCodes) { throw ('Tool exit code '+$process.ExitCode+': '+$output.Trim()) }
        [pscustomobject]@{Reboot=($process.ExitCode -eq 3010); Code=$process.ExitCode; Detail=$output.Trim()}
    } finally { $process.Dispose() }
}
function Install-OfflineDriver {
    param($Context)
    $temp=Join-Path $env:TEMP ('VDD-Install-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($temp)|Out-Null
    try {
        $bundle=[string]$Context.Package
        if ($Context.Embedded -and [long]$Context.Offset -gt 0) {
            $bundle=Join-Path $temp 'bundle.zip'
            $input=[IO.File]::OpenRead([string]$Context.Embedded)
            try {
                $input.Position=[long]$Context.Offset
                $output=[IO.File]::Create($bundle)
                try { $input.CopyTo($output) } finally { $output.Dispose() }
            } finally { $input.Dispose() }
        }
        if (-not $bundle -or -not (Test-Path -LiteralPath $bundle)) { throw 'OFFLINE_PACKAGE_MISSING' }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $offline=Join-Path $temp 'offline'
        [IO.Compression.ZipFile]::ExtractToDirectory($bundle,$offline)
        $driver=Get-ChildItem -LiteralPath $offline -Recurse -Filter 'Signed-Driver-*.zip' | Select-Object -First 1
        if ($driver) { [IO.Compression.ZipFile]::ExtractToDirectory($driver.FullName,(Join-Path $offline 'driver')) }
        $inf=Get-ChildItem -LiteralPath $offline -Recurse -Filter 'MttVDD.inf' | Select-Object -First 1
        $devcon=Get-ChildItem -LiteralPath $offline -Recurse -Filter 'devcon.exe' | Select-Object -First 1
        if (-not $inf -or -not $devcon) { throw 'The offline bundle must contain MttVDD.inf and devcon.exe.' }
        $vc=Get-ChildItem -LiteralPath $offline -Recurse -Filter 'vc_redist.x64.exe' | Select-Object -First 1
        $reboot=$false
        if ($vc) { $r=Invoke-HiddenTool $vc.FullName '/install /quiet /norestart' @(0,3010,1638); $reboot=$r.Reboot }
        $result=Invoke-HiddenTool $devcon.FullName ('install "'+$inf.FullName+'" "Root\MttVDD"') @(0,1)
        [pscustomobject]@{Reboot=($reboot -or $result.Code -eq 1); Detail=$result.Detail}
    } finally {
        # Only the GUID directory created above is removed.
        if ([IO.Path]::GetFullPath($temp).StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\VDD-Install-',[StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
function Invoke-Backend {
    param([string]$Action,[bool]$Automatic,$Context)
    $detail=''; $reboot=$false; $skipped=$false
    if ($Action -eq 'Install') {
        $before=Get-DeviceSnapshot
        if ($before.Device) { throw 'A VDD device is already installed.' }
        $r=Install-OfflineDriver $Context; $detail=$r.Detail; $reboot=$r.Reboot
    } elseif ($Action -ne 'Query') {
        $before=Get-DeviceSnapshot
        if (-not $before.Device) { throw 'VDD device not found.' }
        if ($Automatic) {
            if ($before.DetectionError) { throw $before.DetectionError }
            if (($Action -eq 'Disable' -and $before.Physical -eq 0) -or ($Action -eq 'Enable' -and $before.Physical -gt 0)) { $skipped=$true }
        }
        if (-not $skipped) {
            if ($Action -eq 'Remove') {
                $r=Invoke-HiddenTool (Join-Path $env:SystemRoot 'System32\pnputil.exe') ('/remove-device "'+$before.Device.Id+'"')
                $detail=$r.Detail; $reboot=$r.Reboot
            } else {
                $device=New-Object Management.ManagementObject($before.Device.Path)
                try {
                    $result=$device.InvokeMethod($Action,$null,$null)
                    $returnCode=[uint32]$result.ReturnValue
                    $reboot=[bool]$result.rebootNeeded
                    $result.Dispose()
                    if ($returnCode -ne 0) { throw ('Windows device method returned '+$returnCode) }
                } finally { $device.Dispose() }
            }
        }
    }
    $snapshot=Get-DeviceSnapshot
    $verified=$true
    if (-not $skipped) {
        switch ($Action) {
            Enable { $verified=($snapshot.Device -and $snapshot.Device.Enabled) }
            Disable { $verified=($snapshot.Device -and $snapshot.Device.Disabled) }
            Remove { $verified=($null -eq $snapshot.Device) }
            Install { $verified=($null -ne $snapshot.Device) }
        }
    }
    [pscustomobject]@{Snapshot=$snapshot; Detail=$detail; Reboot=$reboot; Verified=$verified; Skipped=$skipped}
}
