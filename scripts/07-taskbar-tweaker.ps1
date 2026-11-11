# [AUTO] 7+ Taskbar Tweaker: действия мыши на панели задач (закрыть средней кнопкой, колесо, инспектор).
# -Auto: тихая установка (установщик на NSIS, ключ /S), автозапуск скрыто в трее (-hidewnd), запуск без прав администратора.
# Рекомендуемые настройки (см. screenshots/09): средняя кнопка по значку = Закрыть; колесо над панелью = переключение окон;
# двойной клик по пустому месту = Диспетчер задач; ПКМ по значку оставить 'Список переходов'.
param([switch]$Auto)
. "$PSScriptRoot\lib\Common.ps1"
$exe = Get-File "https://rammichael.com/downloads/7tt_setup.exe" "7tt_setup.exe"
Assert-Signed $exe
"Подпись: $((Get-AuthenticodeSignature $exe).SignerCertificate.Subject)"
if (-not $Auto) { Write-Host "`n[MANUAL] Запусти $exe, поставь галочку автозапуска." -ForegroundColor Yellow; Start-Process $exe; return }
Get-Process '7+ Taskbar Tweaker' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $exe -ArgumentList '/S' -Wait
$app = Get-ChildItem "$env:LOCALAPPDATA\Programs\7+ Taskbar Tweaker", "$env:ProgramFiles\7+ Taskbar Tweaker", "${env:ProgramFiles(x86)}\7+ Taskbar Tweaker" -Filter '7+ Taskbar Tweaker.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $app) { throw "7+ Taskbar Tweaker не найден после установки" }
# то же имя значения, что пишет сама программа, чтобы не было двойного автозапуска
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' '7 Taskbar Tweaker' "`"$($app.FullName)`" -hidewnd" 'String'
Start-UserProcess $app.FullName '-hidewnd'
if (Wait-ProcessUp '7+ Taskbar Tweaker' 10) { "7+ Taskbar Tweaker OK" } else { throw "7+ Taskbar Tweaker не запустился" }
