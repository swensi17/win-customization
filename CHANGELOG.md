# Changelog

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии по [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

### Добавлено
- ShellGuard (`scripts/17-shell-guard.ps1`, по желанию): сам перезапускает TaskbarX и Lively после зависания и перезапуска Проводника.

## [1.2.0] - 2026-11-09

### Добавлено
- JetBrainsMono Nerd Font и приглашение PowerShell с веткой git, временем выполнения команды и цветом стрелки по результату (`scripts/13-nerd-font.ps1`).
- Подсветка синтаксиса PSReadLine в палитре терминала, поиск по истории стрелками, меню по `Tab`.
- Quake-режим Windows Terminal на `Win + ~`.
- Тёмная тема Windows и приложений, акцентный цвет `#1793D1` (`scripts/14-accent-theme.ps1`).
- Обратимая чистка автозагрузки (`scripts/15-startup-review.ps1`).
- Живые обои «Aurora Glass» для Lively (`configs/lively/aurora-glass`, `scripts/16-live-wallpaper.ps1`).
- 6 новых проверок в `Test-Setup.ps1` (всего 26).

### Известные проблемы
- PSReadLine 2.3.6 и 2.4.5 из PowerShell Gallery закрывают консоль на первом нажатии клавиши на Windows 10 22H2 в Windows Terminal; используется встроенный 2.0.0 (без серых подсказок из истории).
- Lively 2.x не импортирует обои из командной строки, импорт пакета вручную через окно программы.

## [1.1.0] - 2026-11-09

### Добавлено
- Индикатор нагрузки в трее (SysMonTray): одно число 0–100, RAM по умолчанию, клик переключает на CPU, подсказка с гигабайтами (`scripts/12-sysmon-tray.ps1`).
- Оформление `cmd`: та же заставка Windows 7 и цветное приглашение для любого интерактивного `cmd` через защищённый `AutoRun` (`configs/cmd-autorun.cmd`).
- Общая заставка `configs/Show-Splash.ps1` для PowerShell и cmd, демо-режим для публичных скриншотов.
- Самопроверка `scripts/Test-Setup.ps1` (20 пунктов) и её запуск в конце `Install-Auto.ps1`.
- Английская версия README (`README.en.md`), переключатель языка.
- Новая демо-гифка по сценам, бейджи (звёзды, последний коммит, релиз), раздел «Частые проблемы».
- Шаблоны issues и PR, `CONTRIBUTING.md`, этот `CHANGELOG.md`.

### Изменено
- Приглашение PowerShell: домашняя папка как `~`, длинные пути сокращаются до последних трёх папок; в cmd путь отдельной строкой.

### Исправлено
- `AutoRun` для cmd не срабатывает на `cmd /c` и `cmd /k` из других программ; спецсимволы в чужих командах ничего не ломают.

## [1.0.0] - 2026-11-09

### Добавлено
- Первая версия: TaskbarX, DWMBlurGlass, ExplorerBlurMica, AcrylicMenus, свои пункты меню ПКМ, 7+ Taskbar Tweaker, Windows Terminal (тема «Arch Glass»), профиль PowerShell с заставкой, обои, playbook и откат.

[1.2.0]: https://github.com/swensi17/win-customization/releases/tag/v1.2.0
