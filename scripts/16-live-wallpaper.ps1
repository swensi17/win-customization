# [AUTO + MANUAL] Живые обои «Aurora Glass» для Lively Wallpaper: тёмные градиенты в палитре терминала, только CSS-анимация.
$src = Join-Path $PSScriptRoot "..\configs\lively\aurora-glass"
$dst = "C:\LivelyWallpapers"; New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $dst "aurora-glass.zip"
Compress-Archive -Path "$src\*" -DestinationPath $zip -Force
"Пакет обоев: $zip"
Write-Host "`n[MANUAL] Открой Lively Wallpaper -> кнопка '+' (Add wallpaper) -> выбери $zip -> кликни по 'Aurora Glass'." -ForegroundColor Yellow
Write-Host "          Командная строка Lively (setwp) в версии 2.x не импортирует новые файлы, поэтому импорт через окно программы."
$lively = Join-Path $env:LOCALAPPDATA "Programs\Lively Wallpaper\Lively.exe"
if (Test-Path $lively) { Start-Process $lively } else { Write-Host "Lively не найден. Установка: Microsoft Store или https://github.com/rocksdanister/lively" }