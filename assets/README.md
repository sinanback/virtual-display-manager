# Application icon

`msa-app.ico` is a multi-resolution dark-background application icon rebuilt from the existing PNG frames supplied by the project owner from:

`S:\MSA_Logo_Kutuphanesi\01_MSA_Logolar\06_Uygulama_Ikonlari\koyu\icon_*.png`

The original PNG-compressed ICO rendered as corrupted pixels through .NET Framework System.Drawing. `scripts/build-icon.ps1` writes standard 32-bit DIB frames (16/24/32/48/64/128 px) without changing the supplied PNG pixels. `tests/verify-icon.ps1` checks exact pixel equality after native ICO loading and stream disposal. The source PNG frames are retained in `icon-source` for reproducible conversion.

The build embeds the icon in the PS1/CMD application; the logo library is not required on the end user's computer. The window retains the original logo. The notification icon uses the same logo with a small green/gray/orange status badge, generated in memory.

This brand asset is provided for this project. It is not an upstream Virtual Display Driver or Microsoft asset. No additional logo license is inferred or granted by the build script.

