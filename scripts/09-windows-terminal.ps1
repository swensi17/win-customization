# [AUTO] Настройки Windows Terminal (акрил, схема "Arch Glass", вкладки-стекло, cmd с цветным приглашением).
# Если Windows Terminal не установлен, пробует поставить его из релиза GitHub (набор для Windows 10 с зависимостями).
$dir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (-not (Test-Path $dir)) {
  "Windows Terminal не найден, ставлю..."
  try {
    $rel = Invoke-RestMethod "https://api.github.com/repos/microsoft/terminal/releases/latest" -UseBasicParsing
    $asset = $rel.assets | Where-Object name -like '*Windows10_PreinstallKit.zip' | Select-Object -First 1
    if (-not $asset) { throw "в релизе нет набора для Windows 10" }
    $tmp = Join-Path $env:TEMP "wt-kit"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force $tmp | Out-Null
    Invoke-WebRequest $asset.browser_download_url -OutFile "$tmp\kit.zip" -UseBasicParsing
    Expand-Archive "$tmp\kit.zip" -DestinationPath $tmp -Force
    $bundle = Get-ChildItem $tmp -Recurse -Filter '*.msixbundle' | Select-Object -First 1
    $deps = Get-ChildItem $tmp -Recurse -Include '*.appx' | Where-Object FullName -match 'x64' | ForEach-Object FullName
    Add-AppxPackage -Path $bundle.FullName -DependencyPath $deps
    Start-Process wt.exe; Start-Sleep 6; Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Stop-Process -Force
  } catch { throw "Не удалось поставить Windows Terminal автоматически ($($_.Exception.Message)). Поставь вручную (Microsoft Store: 9N0DX20HK701) и запусти один раз." }
}
if (-not (Test-Path $dir)) { throw "Windows Terminal не установлен (Microsoft Store: 9N0DX20HK701). Запусти его один раз." }
$f = Join-Path $dir "settings.json"
if (Test-Path $f) { Copy-Item $f "$f.bak" -Force }
Copy-Item "$PSScriptRoot\..\configs\windows-terminal.settings.json" $f -Force
"settings.json установлен (бэкап: settings.json.bak)"