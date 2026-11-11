# [AUTO] SysMonTray: индикатор нагрузки в трее (число 0-100: заполнение RAM, клик переключает на CPU).
# Свой скрипт, внешние программы не нужны. Лежит в C:\SysMonTray, автозапуск через ярлык в Startup.
. "$PSScriptRoot\lib\Common.ps1"
$dst = "C:\SysMonTray"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$PSScriptRoot\..\configs\SysMonTray.ps1" "$dst\SysMonTray.ps1" -Force
$ps    = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$args1 = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst\SysMonTray.ps1`""
New-Shortcut (Join-Path (Get-StartupDir) 'SysMonTray.lnk') $ps $args1 $dst 7
# перезапуск
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'SysMonTray\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 1
Start-UserProcess $ps $args1
Write-Host "SysMonTray запущен. Если значок спрятан под стрелкой ^, перетащи его на панель." -ForegroundColor Yellow
