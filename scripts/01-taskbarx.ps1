# [AUTO] TaskbarX: иконки панели задач по центру + прозрачная панель, автозапуск.
$ver  = "1.7.8.0"
$dst  = "C:\TaskbarX"
$tbArgs = "-tbs=1 -color=0;0;0;0"      # 1 = прозрачная, цвет RGBA 0;0;0;0
New-Item -ItemType Directory -Force $dst | Out-Null
$zip = Join-Path $env:TEMP "TaskbarX_x64.zip"
Invoke-WebRequest "https://github.com/ChrisAnd1998/TaskbarX/releases/download/$ver/TaskbarX_${ver}_x64.zip" -OutFile $zip -UseBasicParsing
Expand-Archive $zip -DestinationPath $dst -Force
# автозапуск: ЯРЛЫК В НАСТОЯЩЕЙ папке Startup
$startup = [Environment]::GetFolderPath('Startup')
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$startup\TaskbarX.lnk")
$lnk.TargetPath = "$dst\TaskbarX.exe"; $lnk.Arguments = $tbArgs; $lnk.WorkingDirectory = $dst; $lnk.Save()
Get-Process TaskbarX -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process "$dst\TaskbarX.exe" -ArgumentList $tbArgs
Start-Sleep 3
if (Get-Process TaskbarX -ErrorAction SilentlyContinue) { "TaskbarX OK" } else { Write-Error "TaskbarX не запустился" }