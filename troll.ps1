$url = "https://i.imgur.com/IXL5WXD.jpeg"
$wp = "$env:TEMP\wp.jpg"

Invoke-WebRequest -Uri $url -OutFile $wp -UseBasicParsing

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class W {
    [DllImport("User32.dll", CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfo(int a, int b, string c, int d);
}
"@

# Définit le style "Fill" (remplir l'écran) dans le registre
New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value "10" -Force | Out-Null
New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value "0" -Force | Out-Null

# Applique le fond d'écran
[W]::SystemParametersInfo(0x14, 0, $wp, 3)

Remove-Item $wp -Force -ErrorAction SilentlyContinue
