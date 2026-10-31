# Convert the supplied PNG frames to uncompressed 32-bit DIB ICO frames.
# PNG-compressed ICO frames from the original library render incorrectly in
# .NET Framework System.Drawing on the target computer.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$frames=@()
foreach($size in @(16,24,32,48,64,128)){
    $bitmap=New-Object Drawing.Bitmap((Join-Path $root ('assets\icon-source\icon_'+$size+'.png')))
    $stream=New-Object IO.MemoryStream
    $writer=New-Object IO.BinaryWriter($stream)
    try{
        $maskStride=[int]([Math]::Ceiling($size/32.0)*4)
        $writer.Write([uint32]40);$writer.Write([int32]$size);$writer.Write([int32]($size*2))
        $writer.Write([uint16]1);$writer.Write([uint16]32);$writer.Write([uint32]0)
        $writer.Write([uint32](4*$size*$size+$maskStride*$size))
        1..4|ForEach-Object{$writer.Write([uint32]0)}
        for($y=$size-1;$y -ge 0;$y--){for($x=0;$x -lt $size;$x++){
            $pixel=$bitmap.GetPixel($x,$y)
            $writer.Write([byte]$pixel.B);$writer.Write([byte]$pixel.G);$writer.Write([byte]$pixel.R);$writer.Write([byte]$pixel.A)
        }}
        $writer.Write((New-Object byte[] ($maskStride*$size)))
        $writer.Flush();$frames+=,[pscustomobject]@{Size=$size;Bytes=$stream.ToArray()}
    }finally{$writer.Dispose();$stream.Dispose();$bitmap.Dispose()}
}
$output=[IO.File]::Create((Join-Path $root 'assets\msa-app.ico'))
$writer=New-Object IO.BinaryWriter($output)
try{
    $writer.Write([uint16]0);$writer.Write([uint16]1);$writer.Write([uint16]$frames.Count)
    $offset=6+16*$frames.Count
    foreach($frame in $frames){
        $writer.Write([byte]$frame.Size);$writer.Write([byte]$frame.Size);$writer.Write([uint16]0)
        $writer.Write([uint16]1);$writer.Write([uint16]32);$writer.Write([uint32]$frame.Bytes.Length);$writer.Write([uint32]$offset)
        $offset+=$frame.Bytes.Length
    }
    foreach($frame in $frames){$writer.Write([byte[]]$frame.Bytes)}
}finally{$writer.Dispose();$output.Dispose()}
