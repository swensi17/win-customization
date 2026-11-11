# [AUTO] Тёмная тема Windows и приложений + акцентный цвет #1793D1 (тот же голубой, что в терминале). Только HKCU.
. "$PSScriptRoot\lib\Common.ps1"
$acc = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"; $dwm = "HKCU:\Software\Microsoft\Windows\DWM"
$pz  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
# бэкап текущих значений
$b = @{}; $a = Get-ItemProperty $acc -ErrorAction SilentlyContinue; $d = Get-ItemProperty $dwm -ErrorAction SilentlyContinue
$b.AccentColorMenu = $a.AccentColorMenu; $b.StartColorMenu = $a.StartColorMenu; $b.AccentPalette = if ($a.AccentPalette) { [Convert]::ToBase64String($a.AccentPalette) } else { $null }
$b.AccentColor = $d.AccentColor; $b.ColorizationColor = $d.ColorizationColor
$b | ConvertTo-Json | Set-Content (Join-Path $env:USERPROFILE "accent-backup.json")
# палитра: 3 светлее, базовый, 3 темнее, нейтральный серый (байты RGBA)
$pal = [byte[]](0xA2,0xD4,0xED,0, 0x74,0xBE,0xE3,0, 0x45,0xA9,0xDA,0, 0x17,0x93,0xD1,0, 0x12,0x76,0xA7,0, 0x0E,0x58,0x7D,0, 0x09,0x3B,0x54,0, 0x6B,0x6B,0x6B,0)
New-Item -Path $acc -Force | Out-Null
Set-ItemProperty $acc -Name AccentPalette   -Value $pal -Type Binary
Set-ItemProperty $acc -Name AccentColorMenu -Value ([Convert]::ToInt32('FFD19317',16)) -Type DWord   # ABGR
Set-ItemProperty $acc -Name StartColorMenu  -Value ([Convert]::ToInt32('FF7D580E',16)) -Type DWord
Set-Reg $dwm AccentColor ([Convert]::ToInt32('FFD19317',16))
Set-Reg $dwm ColorizationColor ([Convert]::ToInt32('C41793D1',16))
Set-Reg $dwm ColorizationAfterglow ([Convert]::ToInt32('C41793D1',16))
Set-Reg $dwm ColorPrevalence 0      # заголовки не красить: там стекло DWMBlurGlass
Set-Reg $pz AppsUseLightTheme 0
Set-Reg $pz SystemUsesLightTheme 0
Set-Reg $pz EnableTransparency 1
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class ThemeBc { [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, UIntPtr w, string l, uint f, uint t, out UIntPtr r); }
"@
$r = [UIntPtr]::Zero; foreach ($s in "ImmersiveColorSet","WindowsThemeElement") { [void][ThemeBc]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, $s, 2, 3000, [ref]$r) }
"Тёмная тема и акцент #1793D1 применены. Бэкап: $env:USERPROFILE\accent-backup.json"
