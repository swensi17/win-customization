# [AUTO] JetBrainsMono Nerd Font (иконки git, папок и т.п. в приглашении). Установка для текущего пользователя, без прав администратора.
$ver = "v3.5.1"
$tmp = Join-Path $env:TEMP "nerdfont"; New-Item -ItemType Directory -Force $tmp | Out-Null
$zip = Join-Path $tmp "JetBrainsMono.zip"
Invoke-WebRequest "https://github.com/ryanoasis/nerd-fonts/releases/download/$ver/JetBrainsMono.zip" -OutFile $zip -UseBasicParsing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$want = 'JetBrainsMonoNerdFont-Regular.ttf','JetBrainsMonoNerdFont-Bold.ttf','JetBrainsMonoNerdFont-Italic.ttf','JetBrainsMonoNerdFont-BoldItalic.ttf'
$z = [IO.Compression.ZipFile]::OpenRead($zip)
foreach ($en in $z.Entries | Where-Object { $want -contains $_.Name }) { [IO.Compression.ZipFileExtensions]::ExtractToFile($en, (Join-Path $tmp $en.Name), $true) }
$z.Dispose()
$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"; New-Item -ItemType Directory -Force $fontDir | Out-Null
$reg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"; New-Item -Path $reg -Force | Out-Null
Add-Type -AssemblyName System.Drawing
foreach ($n in $want) {
  $src = Join-Path $tmp $n; $dst = Join-Path $fontDir $n
  Copy-Item $src $dst -Force
  $pfc = New-Object System.Drawing.Text.PrivateFontCollection; $pfc.AddFontFile($dst)
  $style = if ($n -match 'BoldItalic') { 'Bold Italic' } elseif ($n -match 'Bold') { 'Bold' } elseif ($n -match 'Italic') { 'Italic' } else { '' }
  Set-ItemProperty -Path $reg -Name ("{0} {1} (TrueType)" -f $pfc.Families[0].Name, $style).Replace('  ',' ') -Value $dst
}
"Шрифт установлен. В Windows Terminal он задан как 'JetBrainsMono Nerd Font' (шаг 09). Перезапусти терминал."