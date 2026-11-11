# Установка всего одной командой. Сам просит права администратора, пропускает уже сделанное, не падает на одной ошибке.
# Вручную остаётся один шаг: кнопка «Установить» в окне DWMBlurGlass (у программы нет командной строки).
# Параметры: -SkipManual (не ждать шаг DWMBlurGlass), -Only 04,05 (только указанные шаги по номеру).
param([switch]$SkipManual, [string[]]$Only)
$ErrorActionPreference = 'Stop'
if ($Only) { $Only = @($Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Write-Host "Нужны права администратора, подтверди запрос UAC..." -ForegroundColor Yellow
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File',"`"$PSCommandPath`"")
  if ($SkipManual) { $a += '-SkipManual' }; if ($Only) { $a += '-Only'; $a += ($Only -join ',') }
  Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$log = Join-Path $env:TEMP 'win-customization-install.log'
Start-Transcript -Path $log -Force | Out-Null
$res = [ordered]@{}
function Run($n, [switch]$Auto) {
  if ($Only -and -not ($Only | Where-Object { $n -like "$_*" })) { return }
  Write-Host "`n=== $n ===" -ForegroundColor Cyan
  try { if ($Auto) { & "$PSScriptRoot\$n.ps1" -Auto } else { & "$PSScriptRoot\$n.ps1" }; $res[$n] = 'OK' }
  catch { $res[$n] = "ОШИБКА: $($_.Exception.Message)"; Write-Host $res[$n] -ForegroundColor Red }
}
& "$PSScriptRoot\00-prereqs.ps1"
# 1) всё, что перезапускает Проводник: до панели задач
Run '13-nerd-font'; Run '04-explorerblurmica' -Auto; Run '05-acrylicmenus' -Auto; Run '07-taskbar-tweaker' -Auto
# 2) DWMBlurGlass: единственный ручной шаг
Run '03-dwmblurglass'
if (-not $SkipManual -and (-not $Only -or ($Only | Where-Object { '03-dwmblurglass' -like "$_*" }))) { Read-Host "В окне DWMBlurGlass нажми 'Установить', затем 'Сохранить конфигурацию', и нажми Enter здесь" | Out-Null }
# 3) панель задач, терминал, оформление
foreach ($n in '01-taskbarx','02-tray-and-news','06-context-menu-verbs','08-console-defaults','09-windows-terminal','10-powershell-profile','11-wallpaper','12-sysmon-tray','14-accent-theme','15-startup-review') { Run $n }
# 4) живые обои и защита от зависания Проводника
Run '16-live-wallpaper' -Auto; Run '17-shell-guard'
Write-Host "`n=== ИТОГ ===" -ForegroundColor Green
$res.GetEnumerator() | ForEach-Object { $c = if ($_.Value -eq 'OK') { 'Green' } else { 'Red' }; Write-Host ("{0,-24} {1}" -f $_.Key, $_.Value) -ForegroundColor $c }
Write-Host "`nПроверка..." -ForegroundColor Green
try { & "$PSScriptRoot\Test-Setup.ps1" } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
Write-Host "`nЖурнал: $log. Рекомендуется перезайти в Windows." -ForegroundColor Yellow
Stop-Transcript | Out-Null