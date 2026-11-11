# [AUTO + MANUAL] DWMBlurGlass: стекло на заголовках и рамках ВСЕХ окон.
# ВАЖНО: программа ОТКАЗЫВАЕТСЯ запускаться из папки пользователя -> ставим в C:\DWMBlurGlass.
# Установленный DWMBlurGlass узнаём по задаче планировщика DWMBlurGlass_Extend: тогда ручной шаг не нужен.
. "$PSScriptRoot\lib\Common.ps1"
$ver = "2.3.1r"; $dst = "C:\DWMBlurGlass"
$installed = [bool](Get-ScheduledTask -TaskName 'DWMBlurGlass_Extend' -ErrorAction SilentlyContinue)
$zip = Get-File "https://github.com/Maplespe/DWMBlurGlass/releases/download/$ver/DWMBlurGlass_2.3.1_x64.zip" "DWMBlurGlass_2.3.1_x64.zip" -Zip
$tmp = Join-Path $env:TEMP "dwmbg"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Zip $zip $tmp
New-Item -ItemType Directory -Force "$dst\data" | Out-Null
# если DWMBlurGlass уже работает, его DLL загружена в dwm.exe и занята: оставляем установленную версию
foreach ($f in Get-ChildItem "$tmp\Release" -Recurse -File) {
  $to = Join-Path $dst $f.FullName.Substring("$tmp\Release".Length + 1)
  New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
  try { Copy-Item $f.FullName $to -Force -ErrorAction Stop } catch { Write-Warning "$($f.Name) занят (DWMBlurGlass уже работает), оставляю установленный" }
}
Copy-Item "$PSScriptRoot\..\configs\DWMBlurGlass.config.ini" "$dst\data\config.ini" -Force
Unblock-File "$dst\DWMBlurGlass.exe"
$global:WczDwmNeedsManual = -not $installed
if ($installed) { "DWMBlurGlass уже установлен, конфиг обновлён. Применить: окно DWMBlurGlass -> 'Сохранить конфигурацию'"; return }
Write-Host "`n[MANUAL] В окне DWMBlurGlass нажми 'Установить' (статус станет 'Установлено'), затем 'Сохранить конфигурацию'." -ForegroundColor Yellow
Write-Host "          Вкладка 'Символы': если просит, скачай символы."
Start-Process "$dst\DWMBlurGlass.exe"
