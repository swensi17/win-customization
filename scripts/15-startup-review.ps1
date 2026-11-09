# [AUTO] Автозагрузка: показать список и отключить лишнее ТАК ЖЕ, как «Диспетчер задач → Отключить» (обратимо).
# Пример: .\15-startup-review.ps1 -Disable 'Mozilla-Firefox-*'      Включить обратно: -Enable 'Mozilla-Firefox-*'
param([string[]]$Disable = @(), [string[]]$Enable = @())
$run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$sa  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
New-Item -Path $sa -Force | Out-Null
$items = (Get-ItemProperty $run).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
foreach ($i in $items) {
  if ($Disable | Where-Object { $i.Name -like $_ }) { Set-ItemProperty $sa -Name $i.Name -Value ([byte[]](@(3,0,0,0) + [BitConverter]::GetBytes((Get-Date).ToFileTime()))) -Type Binary }
  if ($Enable  | Where-Object { $i.Name -like $_ }) { Set-ItemProperty $sa -Name $i.Name -Value ([byte[]](2,0,0,0,0,0,0,0,0,0,0,0)) -Type Binary }
}
$appr = Get-ItemProperty $sa -ErrorAction SilentlyContinue
foreach ($i in $items) { $f = $appr.($i.Name); "{0,-6} {1}" -f $(if ($f -and $f[0] -eq 3) { 'ВЫКЛ' } else { 'вкл' }), $i.Name }
Get-ChildItem ([Environment]::GetFolderPath('Startup')) | ForEach-Object { "{0,-6} {1} (папка Startup)" -f 'вкл', $_.Name }