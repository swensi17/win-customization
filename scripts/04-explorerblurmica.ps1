# [AUTO + MANUAL] ExplorerBlurMica: стеклянный (Mica) фон внутри Проводника.
param([switch]$Auto)
$ver = "2.1.0"; $dst = "C:\ExplorerBlurMica"
New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $env:TEMP "ebm.zip"
Invoke-WebRequest "https://github.com/Maplespe/ExplorerBlurMica/releases/download/$ver/Release_x64.zip" -OutFile $zip -UseBasicParsing
Expand-Archive $zip -DestinationPath $dst -Force
Copy-Item "$PSScriptRoot\..\configs\ExplorerBlurMica.config.ini" "$dst\Release\config.ini" -Force
if ($Auto) {
  # то же, что register.cmd: регистрируем DLL и перезапускаем Проводник (Windows сама поднимет его заново)
  $r = Start-Process regsvr32.exe -ArgumentList '/s', "`"$dst\Release\ExplorerBlurMica.dll`"" -Wait -PassThru
  if ($r.ExitCode -ne 0) { throw "regsvr32 вернул код $($r.ExitCode) (нужны права администратора)" }
  Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
  $t = 0; while (-not (Get-Process explorer -ErrorAction SilentlyContinue) -and $t -lt 20) { Start-Sleep 1; $t++ }
  if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
  "ExplorerBlurMica OK"; return
}
Write-Host "`n[MANUAL] Запусти C:\ExplorerBlurMica\Release\register.cmd (подтверди UAC). Проводник перезапустится." -ForegroundColor Yellow
Write-Host "          После этого перезапусти TaskbarX: scripts\02-tray-and-news.ps1 (последние строки) или 01-taskbarx.ps1"
Invoke-Item "$dst\Release"