@echo off
rem cmd-autorun.cmd: оформление интерактивного cmd (заставка + цветное приглашение).
rem Запускается через HKCU\Software\Microsoft\Command Processor\AutoRun.
rem Срабатывает ТОЛЬКО для обычного cmd.exe без ключей (/c, /k, ...) и один раз на цепочку процессов.
setlocal EnableDelayedExpansion
if defined CMD_STYLED exit /b 0
set "CL=!cmdcmdline!"
rem хвост после cmd.exe; символ x не даёт переменной остаться пустой
set "REST=!CL:*cmd.exe=!x"
set REST=!REST:"=!
set "REST=!REST: =!"
if not "!REST!"=="x" exit /b 0
endlocal & set "CMD_STYLED=1"
chcp 65001 >nul
prompt $E[38;2;23;147;209m$P$E[0m$_$E[38;2;158;206;106m❯$E[0m$S
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Show-Splash.ps1" -ShellName "Command Prompt"
exit /b 0