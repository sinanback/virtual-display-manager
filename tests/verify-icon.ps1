$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
foreach($size in @(16,24,32,48,64,128)){
    $stream=New-Object IO.MemoryStream(,[IO.File]::ReadAllBytes((Join-Path $root 'assets\msa-app.ico')))
    try{
        $loaded=New-Object Drawing.Icon($stream,$size,$size)
        try{$icon=$loaded.Clone()}finally{$loaded.Dispose()}
    }finally{$stream.Dispose()}
    $actual=$icon.ToBitmap()
    $expected=New-Object Drawing.Bitmap((Join-Path $root ('assets\icon-source\icon_'+$size+'.png')))
    try{
        for($y=0;$y -lt $size;$y++){for($x=0;$x -lt $size;$x++){
            if($actual.GetPixel($x,$y).ToArgb() -ne $expected.GetPixel($x,$y).ToArgb()){
                throw ('ICO pixel mismatch at '+$size+' px: '+$x+','+$y)
            }
        }}
    }finally{$actual.Dispose();$expected.Dispose();$icon.Dispose()}
}
Write-Output 'PASS: all six ICO frames match source PNG pixels after .NET Framework decoding and stream disposal.'
