# [AUTO] TaskbarX: иконки панели задач по центру + прозрачная панель, автозапуск.
. "$PSScriptRoot\lib\Common.ps1"
if (Test-Win11) { "TaskbarX на Windows 11 не поддерживается, шаг пропущен"; return }
$ver    = "1.7.8.0"
$dst    = "C:\TaskbarX"
$tbArgs = "-tbs=1 -color=0;0;0;0"      # 1 = прозрачная, цвет RGBA 0;0;0;0
$zip = Get-File "https://github.com/ChrisAnd1998/TaskbarX/releases/download/$ver/TaskbarX_${ver}_x64.zip" "TaskbarX_${ver}_x64.zip" -Zip
Get-Process TaskbarX -ErrorAction SilentlyContinue | Stop-Process -Force   # запущенный exe не даст перезаписать файлы
Start-Sleep 1
Expand-Zip $zip $dst
# автозапуск: ярлык в настоящей папке Startup
New-Shortcut (Join-Path (Get-StartupDir) 'TaskbarX.lnk') "$dst\TaskbarX.exe" $tbArgs $dst
Start-UserProcess "$dst\TaskbarX.exe" $tbArgs
if (Wait-ProcessUp TaskbarX 10) { "TaskbarX OK" } else { throw "TaskbarX не запустился (нужен .NET Framework 4.7.2+)" }
