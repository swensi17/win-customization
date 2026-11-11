# [AUTO] Настройки Windows Terminal (акрил, схема "Arch Glass", вкладки-стекло, cmd с цветным приглашением).
# Если Windows Terminal нет: ставит его из релиза GitHub (набор для Windows 10 с зависимостями).
# Если на сборке вырезана установка приложений (AppX): ставит портативную версию в C:\WindowsTerminal с ярлыком в меню Пуск.
. "$PSScriptRoot\lib\Common.ps1"
$cfg = "$PSScriptRoot\..\configs\windows-terminal.settings.json"
$pkgDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$portable = "C:\WindowsTerminal"

function Install-Settings([string]$dir) {
  New-Item -ItemType Directory -Force $dir | Out-Null
  $f = Join-Path $dir "settings.json"
  if (Test-Path $f) { Copy-Item $f "$f.bak" -Force }
  Copy-Item $cfg $f -Force
  "settings.json -> $f (бэкап: settings.json.bak)"
}

if (Get-AppxPackage Microsoft.WindowsTerminal* -ErrorAction SilentlyContinue) { Install-Settings $pkgDir; return }
if (Test-Path "$portable\WindowsTerminal.exe") { Install-Settings "$portable\settings"; return }

"Windows Terminal не найден, ставлю..."
$err = $null
try {
  $kit = Get-File (Get-GitHubAssetUrl 'microsoft/terminal' '*Windows10_PreinstallKit.zip') 'wt-preinstallkit.zip' -Zip
  $tmp = Join-Path $env:TEMP "wt-kit"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Zip $kit $tmp
  $bundle = Get-ChildItem $tmp -Recurse -Filter '*.msixbundle' | Select-Object -First 1
  $deps = @(Get-ChildItem $tmp -Recurse -Include '*.appx', '*.msix' | Where-Object { $_.Name -match 'x64' } | ForEach-Object FullName)
  if ($deps.Count) { Add-AppxPackage -Path $bundle.FullName -DependencyPath $deps -ForceApplicationShutdown }
  else { Add-AppxPackage -Path $bundle.FullName -ForceApplicationShutdown }
} catch { $err = $_.Exception.Message }

if (Get-AppxPackage Microsoft.WindowsTerminal* -ErrorAction SilentlyContinue) { Install-Settings $pkgDir; return }

Write-Warning "Установка приложения не прошла ($err). Ставлю портативную версию."
$zip = Get-File (Get-GitHubAssetUrl 'microsoft/terminal' 'Microsoft.WindowsTerminal_*_x64.zip') 'wt-portable-x64.zip' -Zip
$tmp = Join-Path $env:TEMP "wt-portable"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Zip $zip $tmp
$exe = Get-ChildItem $tmp -Recurse -Filter 'WindowsTerminal.exe' | Select-Object -First 1
if (-not $exe) { throw "В портативном архиве нет WindowsTerminal.exe" }
New-Item -ItemType Directory -Force $portable | Out-Null
Copy-Item "$($exe.DirectoryName)\*" $portable -Recurse -Force
New-Item -ItemType File -Force "$portable\.portable" | Out-Null      # режим портативной версии: настройки в папке settings
New-Shortcut (Join-Path ([Environment]::GetFolderPath('Programs')) 'Windows Terminal.lnk') "$portable\WindowsTerminal.exe"
Install-Settings "$portable\settings"
"Портативный Windows Terminal: $portable (ярлык в меню Пуск)"
