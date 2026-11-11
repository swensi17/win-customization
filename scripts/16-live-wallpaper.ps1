# [AUTO] Живые обои «Aurora Glass» для Lively Wallpaper: тёмные градиенты в палитре терминала, только CSS-анимация.
# Сам ставит Lively, если его нет (скачивает с GitHub, проверяет подпись), кладёт обои в библиотеку и применяет их.
param([switch]$Auto)
$src = Join-Path $PSScriptRoot "..\configs\lively\aurora-glass"
$dst = "C:\LivelyWallpapers"; New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $dst "aurora-glass.zip"
Compress-Archive -Path "$src\*" -DestinationPath $zip -Force
"Пакет обоев: $zip"
$lively = Join-Path $env:LOCALAPPDATA "Programs\Lively Wallpaper\Lively.exe"

if (-not (Test-Path $lively) -and $Auto) {
  "Lively не найден, скачиваю последнюю версию..."
  $rel = Invoke-RestMethod "https://api.github.com/repos/rocksdanister/lively/releases/latest" -UseBasicParsing
  $asset = $rel.assets | Where-Object name -like 'lively_setup_x86_full_*.exe' | Select-Object -First 1
  if (-not $asset) { throw "Не нашёл установщик Lively в релизе. Поставь вручную: https://github.com/rocksdanister/lively" }
  $exe = Join-Path $env:TEMP $asset.name
  Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing
  $sig = Get-AuthenticodeSignature $exe
  "Подпись установщика: $($sig.Status)"
  if ($sig.Status -ne 'Valid') { Remove-Item $exe -Force; throw "Подпись установщика Lively не валидна, файл удалён. Поставь вручную: https://github.com/rocksdanister/lively" }
  Start-Process $exe -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -Wait
  if (-not (Test-Path $lively)) { throw "Lively не установился" }
}

if ($Auto -and (Test-Path $lively)) {
  # импорт = папка с LivelyInfo.json в библиотеке Lively (имя папки случайное, как у самой программы)
  $lib = Join-Path $env:LOCALAPPDATA "Lively Wallpaper\Library\wallpapers"
  New-Item -ItemType Directory -Force $lib | Out-Null
  $mine = Get-ChildItem $lib -Directory -ErrorAction SilentlyContinue | Where-Object { (Test-Path "$($_.FullName)\LivelyInfo.json") -and ((Get-Content "$($_.FullName)\LivelyInfo.json" -Raw) -match 'Aurora Glass') } | Select-Object -First 1
  if ($mine) { $wp = $mine.FullName; Copy-Item "$src\*" $wp -Recurse -Force }
  else {
    $name = (-join ((97..122) + (48..57) | Get-Random -Count 8 | ForEach-Object { [char]$_ })) + '.' + (-join ((97..122) + (48..57) | Get-Random -Count 3 | ForEach-Object { [char]$_ }))
    $wp = Join-Path $lib $name; New-Item -ItemType Directory -Force $wp | Out-Null; Copy-Item "$src\*" $wp -Recurse -Force
  }
  # полный перезапуск Lively (повторное применение командой на живом экземпляре не срабатывает)
  Get-Process Lively, Lively.Player.WebView2, Lively.Watchdog -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep 2
  Start-Process $lively; Start-Sleep 6
  Start-Process $lively -ArgumentList 'setwp','--file',"`"$wp`""
  "Aurora Glass импортированы ($wp). Если обои не сменились, выбери «Aurora Glass» в окне Lively."
  return
}

Write-Host "`n[MANUAL] Открой Lively Wallpaper -> кнопка '+' (Add wallpaper) -> выбери $zip -> кликни по 'Aurora Glass'." -ForegroundColor Yellow
Write-Host "          Командная строка Lively (setwp) в версии 2.x не импортирует новые файлы, поэтому импорт через окно программы."
if (Test-Path $lively) { Start-Process $lively } else { Write-Host "Lively не найден. Запусти шаг с параметром -Auto или поставь: https://github.com/rocksdanister/lively" }