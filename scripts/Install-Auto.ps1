# Запускает все АВТОМАТИЧЕСКИЕ шаги по порядку. Ручные шаги (регистрация DLL / установщики) выводят подсказку и ждут Enter.
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot\00-prereqs.ps1"
foreach ($n in "01-taskbarx","02-tray-and-news","06-context-menu-verbs","08-console-defaults","09-windows-terminal","10-powershell-profile","11-wallpaper","12-sysmon-tray","13-nerd-font","14-accent-theme","15-startup-review") { Write-Host "`n=== $n ===" -ForegroundColor Cyan; & "$PSScriptRoot\$n.ps1" }
foreach ($n in "03-dwmblurglass","04-explorerblurmica","05-acrylicmenus","07-taskbar-tweaker","16-live-wallpaper") { Write-Host "`n=== $n (нужен ручной шаг) ===" -ForegroundColor Cyan; & "$PSScriptRoot\$n.ps1"; Read-Host "Сделай ручной шаг и нажми Enter" | Out-Null }
Write-Host "`nУстановка завершена, запускаю проверку..." -ForegroundColor Green
& "$PSScriptRoot\Test-Setup.ps1"