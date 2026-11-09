# [AUTO + MANUAL] 7+ Taskbar Tweaker: действия мыши на панели задач (закрыть средней кнопкой, колесо, инспектор).
$dst = "C:\7TaskbarTweaker"; New-Item -ItemType Directory -Force $dst | Out-Null
$exe = "$dst\7tt_setup.exe"
Invoke-WebRequest "https://rammichael.com/downloads/7tt_setup.exe" -OutFile $exe -UseBasicParsing
$sig = Get-AuthenticodeSignature $exe
"Signature: $($sig.Status) / $($sig.SignerCertificate.Subject)"
if ($sig.Status -ne 'Valid') { Remove-Item $exe -Force; throw "Подпись не валидна, файл удалён" }
Write-Host "`n[MANUAL] Запусти $exe, поставь галочку автозапуска." -ForegroundColor Yellow
Write-Host "          Рекомендуемые настройки (см. screenshots/09): средняя кнопка по значку = Закрыть; колесо над панелью = переключение окон;"
Write-Host "          двойной клик по пустому месту = Диспетчер задач; ПКМ по значку оставить 'Список переходов'."
Invoke-Item $dst