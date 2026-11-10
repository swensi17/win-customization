# ShellGuard: следит за Проводником. Если explorer.exe перезапустился (завис и был закрыт Windows), TaskbarX и живые обои
# Lively «осиротевают»: панель теряет центр и прозрачность, обои пропадают. Страж перезапускает их сам.
# Запуск: powershell -NoProfile -WindowStyle Hidden -File ShellGuard.ps1   (параметры: -Check только показать состояние, -RepairNow починить сейчас)
param([switch]$Check, [switch]$RepairNow)
$ErrorActionPreference = 'SilentlyContinue'
$logFile   = Join-Path $PSScriptRoot 'guard.log'
$tbExe     = 'C:\TaskbarX\TaskbarX.exe'
$tbArgs    = '-tbs=1 -color=0;0;0;0'
$livelyExe = Join-Path $env:LOCALAPPDATA 'Programs\Lively Wallpaper\Lively.exe'
$livelyProc = 'Lively','Lively.Player.WebView2','Lively.Watchdog'

function Log([string]$m) { try { Add-Content -Path $logFile -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $m) } catch {} }
function Get-ExplorerStart { (Get-Process explorer | Sort-Object StartTime | Select-Object -Last 1).StartTime }
function Get-Stale {
  # устарели ли TaskbarX или Lively: они запущены РАНЬШЕ текущего Проводника
  $ex = Get-ExplorerStart; if (-not $ex) { return $false }
  $tb = Get-Process TaskbarX | Select-Object -First 1; $lv = Get-Process Lively | Select-Object -First 1
  return [bool](($tb -and $tb.StartTime -lt $ex) -or ($lv -and $lv.StartTime -lt $ex))
}
function Repair {
  Start-Sleep -Seconds 10                       # дать Проводнику дорисовать панель задач
  Get-Process TaskbarX | Stop-Process -Force; Start-Sleep -Seconds 1
  if (Test-Path $tbExe) { Start-Process $tbExe -ArgumentList $tbArgs; Log 'TaskbarX перезапущен' }
  if ((Get-Process Lively) -and (Test-Path $livelyExe)) {
    foreach ($n in $livelyProc) { Get-Process $n | Stop-Process -Force }
    Start-Sleep -Seconds 2; Start-Process $livelyExe; Log 'Lively перезапущен'
  }
}

if ($Check) {
  $ex = Get-ExplorerStart; $tb = Get-Process TaskbarX | Select-Object -First 1; $lv = Get-Process Lively | Select-Object -First 1
  "explorer : $ex"; "TaskbarX : $(if ($tb) { $tb.StartTime } else { 'не запущен' })"; "Lively   : $(if ($lv) { $lv.StartTime } else { 'не запущен' })"; "устарели : $(Get-Stale)"
  return
}
if ($RepairNow) { Log 'ручной запуск ремонта'; Repair; return }

$mutex = New-Object System.Threading.Mutex($false, 'Global\ShellGuard_instance')
if (-not $mutex.WaitOne(0)) { return }
Log 'страж запущен'
$known = Get-ExplorerStart; $lastRepair = [datetime]::MinValue
while ($true) {
  Start-Sleep -Seconds 5
  $ex = Get-ExplorerStart
  $changed = ($ex -and $ex -ne $known)
  if ($ex) { $known = $ex }
  if (($changed -or (Get-Stale)) -and ((Get-Date) - $lastRepair).TotalSeconds -gt 90) {
    Log ($(if ($changed) { "Проводник перезапущен ($ex)" } else { 'TaskbarX/Lively старше Проводника' }))
    $lastRepair = Get-Date; Repair
  }
}