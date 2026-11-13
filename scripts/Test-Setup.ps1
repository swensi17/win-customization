<#
  Test-Setup.ps1: проверка результата установки. Ничего не меняет.
  Печатает [ OK ] / [FAIL] / [skip] по каждому пункту и возвращает код выхода = число [FAIL].
  Запуск: .\Test-Setup.ps1
#>
param([string]$LocalAppData = $env:LOCALAPPDATA)

$script:fail = 0; $script:ok = 0; $script:skip = 0
function Check([string]$name, [scriptblock]$test, [switch]$Optional) {
  $res = $false
  try { $res = [bool](& $test) } catch { $res = $false }
  if ($res)        { Write-Host ("[ OK ] " + $name) -ForegroundColor Green; $script:ok++ }
  elseif ($Optional) { Write-Host ("[skip] " + $name + " (необязательно)") -ForegroundColor DarkGray; $script:skip++ }
  else             { Write-Host ("[FAIL] " + $name) -ForegroundColor Red; $script:fail++ }
}
function Reg($path, $name) { (Get-ItemProperty -LiteralPath $path -ErrorAction Stop).$name }
$ps51Profile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$win11 = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 22000
# настройки терминала: установленное приложение или портативная версия в C:\WindowsTerminal (шаг 09)
$wtPkg = [bool](Get-AppxPackage Microsoft.WindowsTerminal* -ErrorAction SilentlyContinue)
$wtSettings = if ($wtPkg) { Join-Path $LocalAppData 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json' } else { 'C:\WindowsTerminal\settings\settings.json' }

Write-Host "`n== Панель задач и трей ==" -ForegroundColor Cyan
Check "TaskbarX запущен"                               { Get-Process TaskbarX -ErrorAction Stop } -Optional:$win11
Check "TaskbarX в автозагрузке (ярлык в Startup)"      { Test-Path (Join-Path ([Environment]::GetFolderPath('Startup')) 'TaskbarX.lnk') } -Optional:$win11
Check "Трей свёрнут (EnableAutoTray = 1)"              { (Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'EnableAutoTray') -eq 1 }
Check "«Новости» выключены (ShellFeedsTaskbarViewMode = 2)" { (Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode') -eq 2 }

Write-Host "`n== Стекло окон ==" -ForegroundColor Cyan
Check "DWMBlurGlass установлен в C:\DWMBlurGlass"      { Test-Path 'C:\DWMBlurGlass\DWMBlurGlass.exe' }
Check "DWMBlurGlass загружен в DWM (нужны права администратора)" { (Get-Process dwm -ErrorAction Stop).Modules.ModuleName -match 'DWMBlurGlass' } -Optional
Check "ExplorerBlurMica загружен в Проводник"          { (Get-Process explorer -ErrorAction Stop | ForEach-Object { $_.Modules.ModuleName }) -match 'ExplorerBlurMica' }
Check "AcrylicMenus запущен"                           { Get-Process AcrylicMenusLoader -ErrorAction Stop } -Optional
Check "7+ Taskbar Tweaker запущен"                     { Get-Process | Where-Object { $_.Name -like '7+ Taskbar*' -or $_.Name -like '7tt*' } | Select-Object -First 1 } -Optional

Write-Host "`n== Меню ПКМ ==" -ForegroundColor Cyan
Check "Пункт «Завершить процесс» для .exe"             { Test-Path 'HKCU:\Software\Classes\exefile\shell\EndProcess\command' }
Check "Пункт «Закрыть зависшие программы»"             { Test-Path 'HKCU:\Software\Classes\Directory\Background\shell\KillHung\command' }
Check "Пункт «Диспетчер задач»"                        { Test-Path 'HKCU:\Software\Classes\Directory\Background\shell\TaskMgr\command' }

Write-Host "`n== Терминал и PowerShell ==" -ForegroundColor Cyan
Check "Windows Terminal установлен"                    { $wtPkg -or (Test-Path 'C:\WindowsTerminal\WindowsTerminal.exe') }
Check "Терминал по умолчанию = Windows Terminal"       { (Reg 'HKCU:\Console\%%Startup' 'DelegationTerminal') -eq '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}' } -Optional:(-not $wtPkg)
Check "Настройки терминала: схема «Arch Glass»"        { (Get-Content $wtSettings -Raw) -match 'Arch Glass' }
Check "Профиль PowerShell установлен"                  { (Get-Content $ps51Profile -Raw -ErrorAction Stop) -match 'splash' }
Check "Заставка Show-Splash.ps1 рядом с профилем"      { Test-Path (Join-Path (Split-Path $ps51Profile) 'Show-Splash.ps1') }
Check "cmd оформлен (AutoRun указывает на cmd-autorun.cmd)" { ((Get-ItemProperty 'HKCU:\Software\Microsoft\Command Processor' -ErrorAction Stop).AutoRun -match 'cmd-autorun\.cmd') -and (Test-Path (Join-Path (Split-Path $ps51Profile) 'cmd-autorun.cmd')) }

Write-Host "`n== Индикатор нагрузки ==" -ForegroundColor Cyan
Check "SysMonTray запущен"                             { Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'SysMonTray' } | Select-Object -First 1 }
Check "SysMonTray в автозагрузке (ярлык в Startup)"    { Test-Path (Join-Path ([Environment]::GetFolderPath('Startup')) 'SysMonTray.lnk') }
Check "ShellGuard запущен (чинит оформление после зависания Проводника)" { Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'ShellGuard\.ps1' } | Select-Object -First 1 } -Optional
Check "ShellGuard в автозагрузке (ярлык в Startup)"     { Test-Path (Join-Path ([Environment]::GetFolderPath('Startup')) 'ShellGuard.lnk') } -Optional
Check "PowerToys установлен и запущен"                  { (Test-Path "$env:LOCALAPPDATA\PowerToys\PowerToys.exe") -and (Get-Process PowerToys -ErrorAction SilentlyContinue) }
Check "Open-Shell: меню «Пуск» на стекле запущено"     { (Get-Process StartMenu -ErrorAction SilentlyContinue) -and (Get-ItemProperty 'HKCU:\Software\OpenShell\StartMenu\Settings').SkinW7 -eq 'Immersive' }
Write-Host "`n== Шрифт, тема, Quake, обои ==" -ForegroundColor Cyan
Check "Nerd Font установлен (JetBrainsMono NF)"        { Add-Type -AssemblyName System.Drawing; ((New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object Name -match 'JetBrainsMono NF') }
Check "Терминал использует Nerd Font"                  { (Get-Content $wtSettings -Raw) -match 'JetBrainsMono Nerd Font' }
Check "Quake-режим: Win + ~ (quakeMode)"               { (Get-Content $wtSettings -Raw) -match 'quakeMode' }
Check "Тёмная тема Windows и приложений"               { $p = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; $p.AppsUseLightTheme -eq 0 -and $p.SystemUsesLightTheme -eq 0 }
Check "Акцентный цвет #1793D1"                         { ('{0:X8}' -f (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent').AccentColorMenu) -eq 'FFD19317' }
Check "Пакет живых обоев Aurora Glass"                 { Test-Path 'C:\LivelyWallpapers\aurora-glass.zip' } -Optional
Write-Host ("`nИтого: {0} OK, {1} FAIL, {2} пропущено" -f $script:ok, $script:fail, $script:skip) -ForegroundColor $(if ($script:fail) {'Red'} else {'Green'})
if ($script:fail) { Write-Host "Что делать: смотри docs/AGENT_PLAYBOOK.md и раздел «Частые проблемы» в README." -ForegroundColor Yellow }
exit $script:fail