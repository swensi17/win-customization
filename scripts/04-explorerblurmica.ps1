# [AUTO] ExplorerBlurMica: стеклянный (Mica) фон внутри Проводника.
# -Auto делает то же, что register.cmd: регистрирует DLL и перезапускает Проводник. Без -Auto только раскладывает файлы.
param([switch]$Auto)
. "$PSScriptRoot\lib\Common.ps1"
$ver = "2.1.0"; $dst = "C:\ExplorerBlurMica"; $dll = "$dst\Release\ExplorerBlurMica.dll"
$zip = Get-File "https://github.com/Maplespe/ExplorerBlurMica/releases/download/$ver/Release_x64.zip" "ExplorerBlurMica_${ver}_x64.zip" -Zip
$tmp = Join-Path $env:TEMP "ebm"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Zip $zip $tmp
$same = (Test-Path $dll) -and ((Get-FileHash $dll).Hash -eq (Get-FileHash "$tmp\Release\ExplorerBlurMica.dll").Hash)
if (-not $same) {
  # DLL загружена в Проводник: на время копирования его нужно закрыть
  if (Test-Path $dll) { Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }
  New-Item -ItemType Directory -Force $dst | Out-Null
  Copy-Item "$tmp\Release" $dst -Recurse -Force
}
Copy-Item "$PSScriptRoot\..\configs\ExplorerBlurMica.config.ini" "$dst\Release\config.ini" -Force
if (-not $Auto) {
  if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-UserProcess "$env:SystemRoot\explorer.exe" }
  Write-Host "`n[MANUAL] Запусти $dst\Release\register.cmd (подтверди UAC). Проводник перезапустится." -ForegroundColor Yellow
  return
}
if (-not (Test-IsAdmin)) { throw "Для регистрации ExplorerBlurMica нужны права администратора" }
$r = Start-Process "$env:SystemRoot\System32\regsvr32.exe" -ArgumentList '/s', "`"$dll`"" -Wait -PassThru
if ($r.ExitCode -ne 0) { throw "regsvr32 вернул код $($r.ExitCode). Проверь, что установлен Visual C++ x64 (шаг 00)" }
Restart-Shell
"ExplorerBlurMica OK"
