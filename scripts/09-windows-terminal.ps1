# [AUTO] Настройки Windows Terminal (акрил, схема "Arch Glass", вкладки-стекло, cmd с цветным приглашением).
$dir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (-not (Test-Path $dir)) { throw "Windows Terminal не установлен (Microsoft Store: 9N0DX20HK701). Запусти его один раз." }
$f = Join-Path $dir "settings.json"
if (Test-Path $f) { Copy-Item $f "$f.bak" -Force }
Copy-Item "$PSScriptRoot\..\configs\windows-terminal.settings.json" $f -Force
"settings.json установлен (бэкап: settings.json.bak)"