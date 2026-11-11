# [AUTO + MANUAL] AcrylicMenus: акрил для классических контекстных меню (ПКМ).
param([switch]$Auto)
$ver = "v1.0.8"; $dst = "C:\AcrylicMenus"
New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $env:TEMP "acrylicmenus.zip"
Invoke-WebRequest "https://github.com/krlvm/AcrylicMenus/releases/download/$ver/AcrylicMenus.zip" -OutFile $zip -UseBasicParsing
Expand-Archive $zip -DestinationPath $dst -Force
if ($Auto) {
  # то же, что Install.cmd (для текущего пользователя); echo. закрывает pause в конце
  cmd.exe /c "cd /d `"$dst\Installer`" && echo.| Install.cmd" | Out-Null
  Start-Sleep 2
  if (-not (Get-Process AcrylicMenusLoader -ErrorAction SilentlyContinue)) { throw "AcrylicMenusLoader не запустился" }
  "AcrylicMenus OK"; return
}
Write-Host "`n[MANUAL] Запусти C:\AcrylicMenus\Installer\Install.cmd (НЕ InstallAllUsers). Он копирует в %LOCALAPPDATA%\AcrylicMenus и добавляет автозапуск (HKCU Run)." -ForegroundColor Yellow
Invoke-Item "$dst\Installer"