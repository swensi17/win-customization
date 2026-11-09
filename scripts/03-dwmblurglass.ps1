# [AUTO + MANUAL] DWMBlurGlass: стекло на заголовках и рамках ВСЕХ окон.
# ВАЖНО: программа ОТКАЗЫВАЕТСЯ запускаться из папки пользователя -> ставим в C:\DWMBlurGlass.
$ver = "2.3.1r"; $dst = "C:\DWMBlurGlass"
New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $env:TEMP "DWMBlurGlass_x64.zip"
Invoke-WebRequest "https://github.com/Maplespe/DWMBlurGlass/releases/download/$ver/DWMBlurGlass_2.3.1_x64.zip" -OutFile $zip -UseBasicParsing
$tmp = Join-Path $env:TEMP "dwmbg"; Expand-Archive $zip -DestinationPath $tmp -Force
Copy-Item "$tmp\Release\*" $dst -Recurse -Force
Copy-Item "$PSScriptRoot\..\configs\DWMBlurGlass.config.ini" "$dst\data\config.ini" -Force
Unblock-File "$dst\DWMBlurGlass.exe"
Write-Host "`n[MANUAL] Запусти C:\DWMBlurGlass\DWMBlurGlass.exe двойным кликом -> нажми 'Установить' (статус станет 'Установлено')." -ForegroundColor Yellow
Write-Host "          Затем 'Сохранить конфигурацию'. Вкладка 'Символы': при необходимости скачай символы."
Invoke-Item $dst