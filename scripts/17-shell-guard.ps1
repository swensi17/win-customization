# [AUTO] ShellGuard: страж, который чинит оформление после зависания Проводника.
# Если explorer.exe завис и Windows его перезапустила, TaskbarX теряет центр и прозрачность панели, а Lively теряет подложку обоев.
# Страж следит за временем запуска Проводника и перезапускает TaskbarX и Lively. Лежит в C:\ShellGuard, автозапуск через ярлык в Startup.
$dst = "C:\ShellGuard"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$PSScriptRoot\..\configs\ShellGuard.ps1" "$dst\ShellGuard.ps1" -Force
$ps    = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$args1 = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst\ShellGuard.ps1`""
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) 'ShellGuard.lnk'))
$lnk.TargetPath = $ps; $lnk.Arguments = $args1; $lnk.WorkingDirectory = $dst; $lnk.WindowStyle = 7; $lnk.Save()
# если страж уже запущен, второй экземпляр сам завершится (мьютекс)
Start-Process $ps -ArgumentList $args1 -WindowStyle Hidden
"ShellGuard установлен. Состояние без изменений: powershell -File $dst\ShellGuard.ps1 -Check ; журнал: $dst\guard.log"