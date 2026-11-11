# [AUTO] ShellGuard: страж, который чинит оформление после зависания Проводника.
# Если explorer.exe завис и Windows его перезапустила, TaskbarX теряет центр и прозрачность панели, а Lively теряет подложку обоев.
# Страж следит за временем запуска Проводника и перезапускает TaskbarX и Lively. Лежит в C:\ShellGuard, автозапуск через ярлык в Startup.
. "$PSScriptRoot\lib\Common.ps1"
$dst = "C:\ShellGuard"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$PSScriptRoot\..\configs\ShellGuard.ps1" "$dst\ShellGuard.ps1" -Force
$ps    = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$args1 = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst\ShellGuard.ps1`""
New-Shortcut (Join-Path (Get-StartupDir) 'ShellGuard.lnk') $ps $args1 $dst 7
# если страж уже запущен, второй экземпляр сам завершится (мьютекс)
Start-UserProcess $ps $args1
"ShellGuard установлен. Состояние без изменений: powershell -File $dst\ShellGuard.ps1 -Check ; журнал: $dst\guard.log"
