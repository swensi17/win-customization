# [AUTO] JetBrainsMono Nerd Font (иконки git, папок и т.п. в приглашении). Установка для текущего пользователя.
. "$PSScriptRoot\lib\Common.ps1"
$ver = "v3.5.1"
$want = 'JetBrainsMonoNerdFont-Regular.ttf','JetBrainsMonoNerdFont-Bold.ttf','JetBrainsMonoNerdFont-Italic.ttf','JetBrainsMonoNerdFont-BoldItalic.ttf'
$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"; New-Item -ItemType Directory -Force $fontDir | Out-Null
$reg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"; if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
$missing = $want | Where-Object { -not (Test-Path (Join-Path $fontDir $_)) }
$tmp = Join-Path $env:TEMP "nerdfont"; New-Item -ItemType Directory -Force $tmp | Out-Null
if ($missing) {
  $zip = Get-File "https://github.com/ryanoasis/nerd-fonts/releases/download/$ver/JetBrainsMono.zip" "JetBrainsMono_$ver.zip" -Zip
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $z = [IO.Compression.ZipFile]::OpenRead($zip)
  try { foreach ($en in $z.Entries | Where-Object { $missing -contains $_.Name }) { [IO.Compression.ZipFileExtensions]::ExtractToFile($en, (Join-Path $tmp $en.Name), $true) } }
  finally { $z.Dispose() }
}
Add-Type -AssemblyName System.Drawing
foreach ($n in $want) {
  $dst = Join-Path $fontDir $n
  if (-not (Test-Path $dst)) { Copy-Item (Join-Path $tmp $n) $dst -Force }   # уже установленный шрифт может быть занят терминалом: не трогаем
  $pfc = New-Object System.Drawing.Text.PrivateFontCollection; $pfc.AddFontFile($dst)
  $style = if ($n -match 'BoldItalic') { 'Bold Italic' } elseif ($n -match 'Bold') { 'Bold' } elseif ($n -match 'Italic') { 'Italic' } else { '' }
  Set-ItemProperty -Path $reg -Name ("{0} {1} (TrueType)" -f $pfc.Families[0].Name, $style).Replace('  ',' ') -Value $dst
  $pfc.Dispose()
}
"Шрифт установлен. В Windows Terminal он задан как 'JetBrainsMono Nerd Font' (шаг 09). Перезапусти терминал."
