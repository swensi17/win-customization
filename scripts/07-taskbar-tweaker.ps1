# [AUTO + MANUAL] 7+ Taskbar Tweaker: действия мыши на панели задач (закрыть средней кнопкой, колесо, инспектор).
param([switch]$Auto)
$dst = "C:\7TaskbarTweaker"; New-Item -ItemType Directory -Force $dst | Out-Null
$exe = "$dst\7tt_setup.exe"
Invoke-WebRequest "https://rammichael.com/downloads/7tt_setup.exe" -OutFile $exe -UseBasicParsing
$sig = Get-AuthenticodeSignature $exe
"Signature: $($sig.Status) / $($sig.SignerCertificate.Subject)"
if ($sig.Status -ne 'Valid') { Remove-Item $exe -Force; throw "Подпись не валидна, файл удалён" }
if ($Auto) {
  # установщик на NSIS: /S = тихая установка; запуск скрыто в трее + автозапуск через HKCU\Run
  Start-Process $exe -ArgumentList '/S' -Wait
  $app = Get-ChildItem "$env:ProgramFiles\7+ Taskbar Tweaker", "${env:ProgramFiles(x86)}\7+ Taskbar Tweaker" -Filter '7+ Taskbar Tweaker.exe' -ErrorAction SilentlyContinue | Select -First 1
  if (-not $app) { throw "7+ Taskbar Tweaker не найден после установки" }
  New-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name '7+ Taskbar Tweaker' -Value "`"$($app.FullName)`" -hidewnd" -Force | Out-Null
  if (-not (Get-Process '7+ Taskbar Tweaker' -ErrorAction SilentlyContinue)) { Start-Process $app.FullName -ArgumentList '-hidewnd' }
  "7+ Taskbar Tweaker OK (рекомендуемые действия мыши: Options -> см. README)"; return
}
Write-Host "`n[MANUAL] Запусти $exe, поставь галочку автозапуска." -ForegroundColor Yellow
Write-Host "          Рекомендуемые настройки (см. screenshots/09): средняя кнопка по значку = Закрыть; колесо над панелью = переключение окон;"
Write-Host "          двойной клик по пустому месту = Диспетчер задач; ПКМ по значку оставить 'Список переходов'."
Invoke-Item $dst