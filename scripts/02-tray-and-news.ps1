# [AUTO] Отключить "Новости и интересы" и свернуть значки трея в стрелку ^.
. "$PSScriptRoot\lib\Common.ps1"
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" ShellFeedsTaskbarViewMode 2
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" EnableAutoTray 1
# перезапуск проводника, затем TaskbarX (он теряет панель вместе с проводником)
Stop-Process -Name TaskbarX -Force -ErrorAction SilentlyContinue
Restart-Shell
$tb = "C:\TaskbarX\TaskbarX.exe"
if ((Test-Path $tb) -and -not (Test-Win11)) { Start-UserProcess $tb "-tbs=1 -color=0;0;0;0" }
"done"
