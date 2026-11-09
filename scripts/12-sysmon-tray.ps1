# [AUTO] SysMonTray: индикатор нагрузки в трее (число 0-100: заполнение RAM, клик переключает на CPU).
# Свой скрипт, внешние программы не нужны. Лежит в C:\SysMonTray, автозапуск через ярлык в Startup.
$dst = "C:\SysMonTray"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$PSScriptRoot\..\configs\SysMonTray.ps1" "$dst\SysMonTray.ps1" -Force
$ps   = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$args1 = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst\SysMonTray.ps1`""
# автозапуск: ярлык в НАСТОЯЩЕЙ папке Startup
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) 'SysMonTray.lnk'))
$lnk.TargetPath = $ps; $lnk.Arguments = $args1; $lnk.WorkingDirectory = $dst; $lnk.WindowStyle = 7; $lnk.Save()
# перезапуск
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'SysMonTray' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep 1
Start-Process $ps -ArgumentList $args1 -WindowStyle Hidden
Write-Host "SysMonTray запущен. Если значок спрятан под стрелкой ^, перетащи его на панель." -ForegroundColor Yellow