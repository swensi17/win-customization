# [AUTO] Отключить "Новости и интересы" и свернуть значки трея в стрелку ^.
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name ShellFeedsTaskbarViewMode -Value 2 -Type DWord
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name EnableAutoTray -Value 1 -Type DWord
# перезапуск проводника, затем TaskbarX (он закрывается вместе с проводником)
Stop-Process -Name TaskbarX -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force
Start-Sleep 4
$tb = "C:\TaskbarX\TaskbarX.exe"
if (Test-Path $tb) { Start-Process $tb -ArgumentList "-tbs=1 -color=0;0;0;0" }
"done"