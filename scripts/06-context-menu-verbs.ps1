# [AUTO] Свои пункты в ПКМ: "Завершить процесс" (для .exe), "Закрыть зависшие программы", "Диспетчер задач" (фон рабочего стола/папки).
function Add-Verb($path, $label, $icon, $cmd) {
  New-Item -Path $path -Force | Out-Null
  Set-ItemProperty -Path $path -Name MUIVerb -Value $label
  Set-ItemProperty -Path $path -Name Icon -Value $icon
  New-Item -Path "$path\command" -Force | Out-Null
  Set-ItemProperty -Path "$path\command" -Name "(default)" -Value $cmd
}
$b = "HKCU:\Software\Classes"
Add-Verb "$b\exefile\shell\EndProcess"                  "Завершить процесс"           "imageres.dll,-98" 'cmd.exe /c for %I in ("%1") do taskkill /f /im "%~nxI"'
Add-Verb "$b\Directory\Background\shell\KillHung"       "Закрыть зависшие программы"  "imageres.dll,-98" 'cmd.exe /c taskkill /f /fi "status eq not responding"'
Add-Verb "$b\Directory\Background\shell\TaskMgr"        "Диспетчер задач"             "taskmgr.exe"      'taskmgr.exe'
"context menu verbs added (HKCU, без прав администратора)"