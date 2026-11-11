# [AUTO] AcrylicMenus: акрил для классических контекстных меню (ПКМ).
# -Auto повторяет Installer\Install.cmd (для текущего пользователя), но запускает загрузчик без прав администратора.
param([switch]$Auto)
. "$PSScriptRoot\lib\Common.ps1"
$ver = "v1.0.8"; $dst = "C:\AcrylicMenus"
$zip = Get-File "https://github.com/krlvm/AcrylicMenus/releases/download/$ver/AcrylicMenus.zip" "AcrylicMenus_$ver.zip" -Zip
Expand-Zip $zip $dst
if (-not $Auto) {
  Write-Host "`n[MANUAL] Запусти $dst\Installer\Install.cmd (НЕ InstallAllUsers). Он копирует в %LOCALAPPDATA%\AcrylicMenus и добавляет автозапуск (HKCU Run)." -ForegroundColor Yellow
  return
}
$inst = Join-Path $env:LOCALAPPDATA 'AcrylicMenus'
Get-Process AcrylicMenusLoader -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 1
New-Item -ItemType Directory -Force $inst | Out-Null
foreach ($f in 'AcrylicMenus.dll', 'AcrylicMenusLoader.exe') {
  try { Copy-Item "$dst\$f" "$inst\$f" -Force -ErrorAction Stop }
  catch { if (-not (Test-Path "$inst\$f")) { throw } ; Write-Warning "$f занят, оставляю установленный" }
}
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'AcrylicMenus' "$inst\AcrylicMenusLoader.exe" 'String'
Start-UserProcess "$inst\AcrylicMenusLoader.exe"
if (Wait-ProcessUp AcrylicMenusLoader 10) { "AcrylicMenus OK" } else { throw "AcrylicMenusLoader не запустился" }
