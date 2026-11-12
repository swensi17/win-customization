# [AUTO] Откат: удаляет всё, что сделали скрипты (кроме ручных установок - см. ниже).
Get-Process TaskbarX -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item "$([Environment]::GetFolderPath('Startup'))\TaskbarX.lnk" -ErrorAction SilentlyContinue
Remove-Item "C:\TaskbarX" -Recurse -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'SysMonTray' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Remove-Item "$([Environment]::GetFolderPath('Startup'))\SysMonTray.lnk" -ErrorAction SilentlyContinue
Remove-Item "C:\SysMonTray" -Recurse -Force -ErrorAction SilentlyContinue
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name ShellFeedsTaskbarViewMode -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name EnableAutoTray -Value 0 -Type DWord
foreach ($k in "exefile\shell\EndProcess","Directory\Background\shell\KillHung","Directory\Background\shell\TaskMgr") { Remove-Item "HKCU:\Software\Classes\$k" -Recurse -Force -ErrorAction SilentlyContinue }
Remove-Item -LiteralPath "HKCU:\Console\%%Startup" -Recurse -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Command Processor" -Name AutoRun -ErrorAction SilentlyContinue
# акцентный цвет: вернуть из бэкапа, если он есть
$bk = Join-Path $env:USERPROFILE "accent-backup.json"
if (Test-Path $bk) { $b = Get-Content $bk -Raw | ConvertFrom-Json
  if ($b.AccentColorMenu) { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name AccentColorMenu -Value $b.AccentColorMenu -Type DWord }
  if ($b.StartColorMenu)  { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name StartColorMenu -Value $b.StartColorMenu -Type DWord }
  if ($b.AccentPalette)   { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name AccentPalette -Value ([Convert]::FromBase64String($b.AccentPalette)) -Type Binary }
  if ($b.AccentColor)     { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name AccentColor -Value $b.AccentColor -Type DWord }
  if ($b.ColorizationColor) { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name ColorizationColor -Value $b.ColorizationColor -Type DWord } }
# автозагрузка: снять отметки «отключено», поставленные шагом 15
Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name 'Mozilla-Firefox-*' -ErrorAction SilentlyContinue
# ShellGuard
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'ShellGuard\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Remove-Item "$([Environment]::GetFolderPath('Startup'))\ShellGuard.lnk" -ErrorAction SilentlyContinue
Remove-Item "C:\ShellGuard" -Recurse -Force -ErrorAction SilentlyContinue
# PowerToys (MSI для пользователя; настройки в %LOCALAPPDATA%\Microsoft\PowerToys остаются)
Get-Process PowerToys* -ErrorAction SilentlyContinue | Stop-Process -Force
Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
    Where-Object { (Get-ItemProperty $_.PSPath).DisplayName -like 'PowerToys*' -and $_.PSChildName -match '^\{.+\}$' } |
    ForEach-Object { Start-Process msiexec -ArgumentList '/x', $_.PSChildName, '/qn', '/norestart' -Wait }
# Windhawk (моды выключаются вместе с ним)
if (Test-Path "$env:ProgramFiles\Windhawk\uninstall.exe") { Start-Process "$env:ProgramFiles\Windhawk\uninstall.exe" -ArgumentList '/S' -Wait }
Write-Host "Вручную: DWMBlurGlass -> 'Удалить'; C:\ExplorerBlurMica\Release\uninstall.cmd; C:\AcrylicMenus\Installer\Uninstall.cmd; 7+ Taskbar Tweaker -> деинсталлятор; затем удали папки в C:\." -ForegroundColor Yellow
Stop-Process -Name explorer -Force