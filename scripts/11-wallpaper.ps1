# [AUTO] Тёмные обои 4K с Wallhaven (SFW) и установка на рабочий стол.
# Если Wallhaven недоступен, рисует тёмный градиент в палитре терминала сам, без интернета.
. "$PSScriptRoot\lib\Common.ps1"
$dir = "C:\Wallpapers"; New-Item -ItemType Directory -Force $dir | Out-Null
$files = [ordered]@{ "dark-gradient-1.jpg"="https://w.wallhaven.cc/full/vp/wallhaven-vpopdm.jpg"; "dark-gradient-2.jpg"="https://w.wallhaven.cc/full/3q/wallhaven-3qwq69.jpg" }
foreach ($n in $files.Keys) {
  if (Test-Path "$dir\$n") { continue }
  try { Invoke-Download $files[$n] "$dir\$n" -MinBytes 50000 | Out-Null } catch { Write-Warning "Не скачал $n" }
}
$wp = "$dir\dark-gradient-1.jpg"
if (-not (Test-Path $wp)) {
  Add-Type -AssemblyName System.Drawing
  $w = 3840; $h = 2160
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(13, 17, 28)), ([System.Drawing.Color]::FromArgb(23, 60, 92)), 35
  $g.FillRectangle($br, $rect); $g.Dispose()
  $bmp.Save($wp, [System.Drawing.Imaging.ImageFormat]::Jpeg); $bmp.Dispose()
  "Wallhaven недоступен, нарисован свой градиент"
}
Add-Type @"
using System.Runtime.InteropServices;
public class Wp { [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int SystemParametersInfo(int a, int b, string c, int d); }
"@
[void][Wp]::SystemParametersInfo(20, 0, $wp, 3)
"wallpaper set"
