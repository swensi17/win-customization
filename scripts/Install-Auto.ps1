# Установка всего одной командой. Работает на чужих ПК: сам переходит в 64-битный Windows PowerShell 5.1,
# просит права администратора, ставит недостающие зависимости, не падает на одной ошибке и в конце печатает итог.
# Вручную остаётся один шаг: кнопка «Установить» в окне DWMBlurGlass (у программы нет командной строки), и только при первой установке.
# Параметры: -SkipManual (не ждать DWMBlurGlass), -Only 04,05 (только указанные шаги по номеру), -NoPause (не ждать Enter в конце).
param([switch]$SkipManual, [string[]]$Only, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
if ($Only) { $Only = @($Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

function Get-RelaunchArgs {
  $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
  if ($SkipManual) { $a += '-SkipManual' }; if ($NoPause) { $a += '-NoPause' }
  if ($Only) { $a += '-Only'; $a += ($Only -join ',') }
  return $a
}

# 1) нужен 64-битный Windows PowerShell 5.1: в pwsh 7 и в 32-битной оболочке часть команд (Appx, regsvr32 x64, реестр) ведёт себя иначе
$ps51 = Join-Path $env:SystemRoot $(if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { 'Sysnative' } else { 'System32' })
$ps51 = Join-Path $ps51 'WindowsPowerShell\v1.0\powershell.exe'
if ($PSVersionTable.PSEdition -eq 'Core' -or ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess)) {
  & $ps51 @(Get-RelaunchArgs); exit $LASTEXITCODE
}
if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Host "Нужен PowerShell 5.1 (Windows Management Framework 5.1)" -ForegroundColor Red; exit 1 }

# 2) права администратора
. "$PSScriptRoot\lib\Common.ps1"
if (-not (Test-IsAdmin)) {
  Write-Host "Нужны права администратора, подтверди запрос UAC..." -ForegroundColor Yellow
  try { Start-Process $ps51 -Verb RunAs -ArgumentList (Get-RelaunchArgs) } catch { Write-Host "Запрос прав отклонён, установка не запущена." -ForegroundColor Red; exit 1 }
  exit 0
}

# 3) права администратора должны быть у того же пользователя, что сидит за ПК: иначе настройки уйдут в чужой профиль
$shell = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" | Select-Object -First 1
if ($shell) {
  $owner = Invoke-CimMethod -InputObject $shell -MethodName GetOwner
  if ($owner.User -and $owner.User -ne $env:USERNAME) {
    Write-Host "Установщик запущен от пользователя '$env:USERNAME', а за ПК сидит '$($owner.User)'." -ForegroundColor Red
    Write-Host "Настройки применяются к текущему пользователю. Выдай '$($owner.User)' права администратора или войди под администратором и запусти снова." -ForegroundColor Red
    if (-not $NoPause) { Read-Host "Enter для выхода" | Out-Null }; exit 1
  }
}

# 4) один экземпляр
$mutex = New-Object Threading.Mutex($false, 'Global\win-customization-install')
if (-not $mutex.WaitOne(0)) { Write-Host "Установка уже идёт в другом окне." -ForegroundColor Yellow; exit 1 }

$log = Join-Path $env:TEMP 'win-customization-install.log'
try { Start-Transcript -Path $log -Force | Out-Null } catch {}
Get-ChildItem (Split-Path $PSScriptRoot) -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
$res = [ordered]@{}
$sw = [Diagnostics.Stopwatch]::StartNew()

function Want($n) { -not $Only -or ($Only | Where-Object { $n -like "$_*" }) }
function Run($n, [switch]$Auto) {
  if (-not (Want $n)) { return }
  Write-Host "`n=== $n ===" -ForegroundColor Cyan
  try {
    if ($Auto) { & "$PSScriptRoot\$n.ps1" -Auto | Out-Host } else { & "$PSScriptRoot\$n.ps1" | Out-Host }
    $res[$n] = 'OK'
  } catch {
    $res[$n] = "ОШИБКА: $($_.Exception.Message)"
    Write-Host $res[$n] -ForegroundColor Red
  }
}

Write-Host "win-customization: установка" -ForegroundColor Green
# 0) окружение и зависимости: без них дальше смысла нет
Write-Host "`n=== 00-prereqs ===" -ForegroundColor Cyan
try { & "$PSScriptRoot\00-prereqs.ps1" | Out-Host; $res['00-prereqs'] = 'OK' }
catch {
  Write-Host "ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "Без этого установка не пойдёт. Исправь и запусти снова." -ForegroundColor Red
  try { Stop-Transcript | Out-Null } catch {}; $mutex.ReleaseMutex()
  if (-not $NoPause) { Read-Host "Enter для выхода" | Out-Null }; exit 1
}

# 1) всё, что перезапускает Проводник: до панели задач
Run '13-nerd-font'; Run '04-explorerblurmica' -Auto; Run '05-acrylicmenus' -Auto; Run '07-taskbar-tweaker' -Auto
# 2) DWMBlurGlass: ручной шаг только при первой установке
$global:WczDwmNeedsManual = $false
Run '03-dwmblurglass'
if ($global:WczDwmNeedsManual -and -not $SkipManual -and (Want '03-dwmblurglass')) {
  Read-Host "В окне DWMBlurGlass нажми 'Установить', затем 'Сохранить конфигурацию', и нажми Enter здесь" | Out-Null
  if (-not (Get-ScheduledTask -TaskName 'DWMBlurGlass_Extend' -ErrorAction SilentlyContinue)) { $res['03-dwmblurglass'] = 'НЕ ЗАВЕРШЁН: в окне DWMBlurGlass не нажата кнопка «Установить»' }
}
# 3) панель задач, терминал, оформление
foreach ($n in '01-taskbarx', '02-tray-and-news', '06-context-menu-verbs', '09-windows-terminal', '08-console-defaults', '10-powershell-profile', '11-wallpaper', '12-sysmon-tray', '14-accent-theme', '15-startup-review') { Run $n }
# 4) живые обои и защита от зависания Проводника
Run '16-live-wallpaper' -Auto; Run '17-shell-guard'; Run '18-powertoys'

# финальная страховка: после всех перезапусков Проводника панель задач должна быть на месте
if ((Test-Path 'C:\TaskbarX\TaskbarX.exe') -and -not (Test-Win11) -and -not (Get-Process TaskbarX -ErrorAction SilentlyContinue)) { Start-UserProcess 'C:\TaskbarX\TaskbarX.exe' '-tbs=1 -color=0;0;0;0' }

Write-Host "`n=== ИТОГ ($([int]$sw.Elapsed.TotalMinutes) мин) ===" -ForegroundColor Green
$bad = 0
foreach ($e in $res.GetEnumerator()) {
  $ok = $e.Value -eq 'OK'; if (-not $ok) { $bad++ }
  Write-Host ("{0,-24} {1}" -f $e.Key, $e.Value) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
}
if (-not $Only) {
  Write-Host "`nПроверка..." -ForegroundColor Green
  try { & "$PSScriptRoot\Test-Setup.ps1" | Out-Host } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
}
if ($bad) { Write-Host "`nШагов с ошибкой: $bad. Повтор только их: .\Install-Auto.ps1 -Only <номер>. Уже сделанное повторный запуск не ломает." -ForegroundColor Yellow }
if ($global:WczRebootNeeded) { Write-Host "Visual C++ просит перезагрузку." -ForegroundColor Yellow }
Write-Host "`nЖурнал: $log. Чтобы всё подхватилось, выйди из Windows и войди снова." -ForegroundColor Yellow
try { Stop-Transcript | Out-Null } catch {}
$mutex.ReleaseMutex()
if (-not $NoPause) { Read-Host "Enter, чтобы закрыть окно" | Out-Null }
exit $bad
