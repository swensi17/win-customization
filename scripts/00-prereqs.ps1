# [AUTO] Проверка окружения. Ничего не меняет.
$os = Get-CimInstance Win32_OperatingSystem
"OS:      $($os.Caption) build $($os.BuildNumber)"
if ([int]$os.BuildNumber -lt 19041) { Write-Warning "Нужна Windows 10 2004+ (build 19041+)" }
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"Admin:   $admin"
"Terminal: " + ((Get-AppxPackage Microsoft.WindowsTerminal* | Select -Expand Version) -join ', ')
"Policy:  LocalMachine=$(Get-ExecutionPolicy -Scope LocalMachine)  (нужен RemoteSigned или мягче для профиля PowerShell)"
Add-Type -AssemblyName System.Drawing
"Fonts:   " + (((New-Object System.Drawing.Text.InstalledFontCollection).Families | ? Name -match 'Cascadia Code').Count -gt 0)
# ВАЖНО: если агент запущен из упакованного приложения (MSIX), запись в %LOCALAPPDATA% / %APPDATA% виртуализируется.
# Папки для программ ниже лежат в C:\ именно поэтому. См. docs/AGENT_PLAYBOOK.md, раздел "Грабли".