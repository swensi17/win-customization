# [AUTO] Тёмные обои 4K с Wallhaven (SFW) и установка на рабочий стол.
$dir = "C:\Wallpapers"; New-Item -ItemType Directory -Force $dir | Out-Null
$files = @{ "dark-gradient-1.jpg"="https://w.wallhaven.cc/full/vp/wallhaven-vpopdm.jpg"; "dark-gradient-2.jpg"="https://w.wallhaven.cc/full/3q/wallhaven-3qwq69.jpg" }
foreach ($n in $files.Keys) { Invoke-WebRequest $files[$n] -OutFile "$dir\$n" -UseBasicParsing }
Add-Type @"
using System.Runtime.InteropServices;
public class Wp { [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int a, int b, string c, int d); }
"@
[void][Wp]::SystemParametersInfo(20, 0, "$dir\dark-gradient-1.jpg", 3)
"wallpaper set"