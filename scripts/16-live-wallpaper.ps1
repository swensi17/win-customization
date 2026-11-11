# [AUTO] Живые обои «Aurora Glass» для Lively Wallpaper: тёмные градиенты в палитре терминала, только CSS-анимация.
# -Auto: ставит Lively, если его нет (последний релиз с GitHub, SHA-256 сверяется с опубликованным), кладёт обои в библиотеку и применяет их.
# WebView2 Runtime, без которого Lively не рисует обои, ставит шаг 00.
param([switch]$Auto)
. "$PSScriptRoot\lib\Common.ps1"
$src = Join-Path $PSScriptRoot "..\configs\lively\aurora-glass"
$dst = "C:\LivelyWallpapers"; New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $dst "aurora-glass.zip"
Compress-Archive -Path "$src\*" -DestinationPath $zip -Force
"Пакет обоев: $zip"
$lively = Join-Path $env:LOCALAPPDATA "Programs\Lively Wallpaper\Lively.exe"

if (-not $Auto) {
  Write-Host "`n[MANUAL] Открой Lively Wallpaper -> кнопка '+' (Add wallpaper) -> выбери $zip -> кликни по 'Aurora Glass'." -ForegroundColor Yellow
  if (Test-Path $lively) { Start-UserProcess $lively } else { Write-Host "Lively не найден: запусти шаг с -Auto или поставь https://github.com/rocksdanister/lively" }
  return
}

if (-not (Test-Path $lively)) {
  "Lively не найден, скачиваю последнюю версию..."
  $url = Get-GitHubAssetUrl 'lively-community/lively' 'lively_setup_x86_full_*.exe'
  $exe = Get-File $url (Split-Path $url -Leaf)
  Assert-GitHubAsset $exe 'lively-community/lively'     # установщик Lively не подписан: проверяем по хэшу
  $p = Start-Process $exe -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-' -Wait -PassThru
  if (-not (Test-Path $lively)) { throw "Lively не установился (код $($p.ExitCode))" }
}

# импорт = папка с LivelyInfo.json в библиотеке Lively (имя папки случайное, как у самой программы)
$lib = Join-Path $env:LOCALAPPDATA "Lively Wallpaper\Library\wallpapers"
New-Item -ItemType Directory -Force $lib | Out-Null
$mine = Get-ChildItem $lib -Directory -ErrorAction SilentlyContinue | Where-Object {
  $j = Join-Path $_.FullName 'LivelyInfo.json'; (Test-Path $j) -and ((Get-Content $j -Raw -ErrorAction SilentlyContinue) -match 'Aurora Glass') } | Select-Object -First 1
if ($mine) { $wp = $mine.FullName }
else {
  $chars = [char[]]'abcdefghijklmnopqrstuvwxyz0123456789'
  $name = (-join (1..8 | ForEach-Object { $chars | Get-Random })) + '.' + (-join (1..3 | ForEach-Object { $chars | Get-Random }))
  $wp = Join-Path $lib $name; New-Item -ItemType Directory -Force $wp | Out-Null
}
Copy-Item "$src\*" $wp -Recurse -Force

# полный перезапуск Lively (повторное применение командой на живом экземпляре не срабатывает)
Get-Process Lively, Lively.Player.WebView2, Lively.Watchdog -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
Start-UserProcess $lively
[void](Wait-ProcessUp Lively 20); Start-Sleep 6
Start-UserProcess $lively "setwp --file `"$wp`""
"Aurora Glass в библиотеке Lively ($wp). Если обои не сменились, выбери «Aurora Glass» в окне Lively."
