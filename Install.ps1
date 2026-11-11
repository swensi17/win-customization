# Установка в одну команду (PowerShell от любого пользователя, права администратора запросит сам):
#   irm https://raw.githubusercontent.com/swensi17/win-customization/main/Install.ps1 | iex
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dst = 'C:\win-customization'
$zip = Join-Path $env:TEMP 'win-customization.zip'
Write-Host "Скачиваю win-customization..." -ForegroundColor Cyan
Invoke-WebRequest 'https://github.com/swensi17/win-customization/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing
$tmp = Join-Path $env:TEMP 'win-customization-src'; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $zip -DestinationPath $tmp -Force
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$tmp\win-customization-main\*" $dst -Recurse -Force
Get-ChildItem $dst -Recurse -File | Unblock-File
& "$dst\scripts\Install-Auto.ps1"