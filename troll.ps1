$url = "https://i.imgur.com/xxxxx.jpg"   # remplace par l'URL de ton image
$wp = "$env:TEMP\wp.png"
Invoke-WebRequest -Uri $url -OutFile $wp -UseBasicParsing

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class W {
    [DllImport("User32.dll")]
    public static extern int SystemParametersInfo(int a, int b, string c, int d);
}
"@

[W]::SystemParametersInfo(0x14, 0, $wp, 3)
Remove-Item $wp -Force
