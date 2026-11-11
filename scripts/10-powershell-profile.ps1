# [AUTO] Профиль PowerShell и оформление cmd: заставка с логотипом Windows 7 + минималистичное приглашение.
# Кладёт в папку профиля: Microsoft.PowerShell_profile.ps1, Show-Splash.ps1 (общая заставка), cmd-autorun.cmd (оформление cmd)
# и прописывает HKCU\Software\Microsoft\Command Processor\AutoRun (срабатывает только для обычного интерактивного cmd).
. "$PSScriptRoot\lib\Common.ps1"
# путь именно Windows PowerShell 5.1 через папку «Документы» (учитывает перенос папки и OneDrive), даже если шаг запущен из pwsh
$dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell'
$p = Join-Path $dir 'Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Force $dir | Out-Null
if (Test-Path $p) { Copy-Item $p "$p.bak" -Force }
Copy-Item "$PSScriptRoot\..\configs\Microsoft.PowerShell_profile.ps1" $p -Force
Copy-Item "$PSScriptRoot\..\configs\Show-Splash.ps1"   "$dir\Show-Splash.ps1" -Force
Copy-Item "$PSScriptRoot\..\configs\cmd-autorun.cmd"   "$dir\cmd-autorun.cmd" -Force
Get-ChildItem $dir -File | Unblock-File -ErrorAction SilentlyContinue   # иначе RemoteSigned не даст загрузить скачанный профиль
$autorun = Join-Path $dir 'cmd-autorun.cmd'
$key = 'HKCU:\Software\Microsoft\Command Processor'
New-Item -Path $key -Force | Out-Null
$old = (Get-ItemProperty $key -ErrorAction SilentlyContinue).AutoRun
if ($old -and $old -notmatch 'cmd-autorun\.cmd') { Write-Warning "AutoRun уже задан другим значением и будет заменён: $old" }
# если файл исчезнет, cmd не выдаст ошибок
Set-ItemProperty -Path $key -Name AutoRun -Value ('if exist "{0}" call "{0}"' -f $autorun) -Type String
"profile  -> $p"
"splash   -> $dir\Show-Splash.ps1"
"cmd      -> $autorun (AutoRun прописан)"
