# Playbook: оформление Windows 10 в стиле «жидкое стекло»

> Документ для исполнителя (человек или агент). Цель: на чистой Windows 10 получить тот же результат, что на скриншотах ниже.
> Следуй шагам по порядку. После каждого шага выполни блок **VERIFY**. Любой шаг откатывается блоком **ROLLBACK**.

## 0. Теги

<table width="100%">
  <thead>
    <tr><th align="left">Тег</th><th align="left">Значение<br><img src="../screenshots/spacer.png" width="1600" height="1" alt=""></th></tr>
  </thead>
  <tbody>
    <tr><td><code>[AUTO]</code></td><td>Выполняется скриптом без участия пользователя.</td></tr>
    <tr><td><code>[MANUAL]</code></td><td>Делает человек (двойной клик, UAC, GUI). Агент только готовит файлы и объясняет шаг.</td></tr>
    <tr><td><code>[VERIFY]</code></td><td>Проверка, что шаг сработал.</td></tr>
    <tr><td><code>[ROLLBACK]</code></td><td>Как вернуть как было.</td></tr>
    <tr><td><code>[WARN]</code></td><td>Известная ловушка, читать до выполнения.</td></tr>
  </tbody>
</table>

## 1. Целевая система и результат

- Windows 10 Pro 22H2, build 19045, x64; облегчённая сборка Windows 10 Lite от Flibustier (вырезаны Defender, Edge, OneDrive, Hyper-V). Репозиторий рассчитан на все версии Windows 10 x64, проверен на этой сборке.
- Права: обычный пользователь для большинства шагов, UAC для `[MANUAL]`-шагов регистрации.
- Рабочие каталоги: все сторонние программы лежат **в корне диска C:\** (причина в разделе 4).

Результат:

<table width="100%">
  <thead>
    <tr><th align="left">Что</th><th align="left">Как выглядит<br><img src="../screenshots/spacer.png" width="1600" height="1" alt=""></th></tr>
  </thead>
  <tbody>
    <tr><td>Панель задач</td><td>Иконки по центру, панель полностью прозрачная, трей свёрнут в <code>^</code>, «Новости» выключены</td></tr>
    <tr><td>Заголовки и рамки окон</td><td>Размытое тёмное стекло во всех окнах</td></tr>
    <tr><td>Фон Проводника</td><td>Mica/стекло внутри окна</td></tr>
    <tr><td>Меню ПКМ</td><td>Свои пункты («Завершить процесс», «Закрыть зависшие программы», «Диспетчер задач»); акрил в меню через AcrylicMenus (по желанию)</td></tr>
    <tr><td>Терминал</td><td>Windows Terminal по умолчанию, акрил, схема «Arch Glass», заставка с логотипом Windows 7</td></tr>
  </tbody>
</table>

### Эталонные кадры

Панель задач:

<img src="../screenshots/compare/c1-taskbar.png" width="100%">

Трей:

<img src="../screenshots/compare/c2-tray.png" width="100%">

Проводник:

<img src="../screenshots/compare/c3-explorer.png" width="100%">

Терминал:

<img src="../screenshots/compare/c5-terminal.png" width="100%">

## 2. Компоненты

<table width="100%">
  <thead>
    <tr><th align="left">Компонент</th><th align="left">Версия</th><th align="left">Источник</th><th align="left">Путь</th><th align="left">Автозапуск<br><img src="../screenshots/spacer.png" width="1600" height="1" alt=""></th></tr>
  </thead>
  <tbody>
    <tr><td>TaskbarX</td><td>1.7.8.0</td><td>github.com/ChrisAnd1998/TaskbarX</td><td><code>C:\TaskbarX</code></td><td>ярлык в <code>shell:startup</code></td></tr>
    <tr><td>DWMBlurGlass</td><td>2.3.1r</td><td>github.com/Maplespe/DWMBlurGlass</td><td><code>C:\DWMBlurGlass</code></td><td>встроен в DWM после «Установить»</td></tr>
    <tr><td>ExplorerBlurMica</td><td>2.1.0</td><td>github.com/Maplespe/ExplorerBlurMica</td><td><code>C:\ExplorerBlurMica\Release</code></td><td>COM-расширение Проводника</td></tr>
    <tr><td>AcrylicMenus</td><td>v1.0.8</td><td>github.com/krlvm/AcrylicMenus</td><td><code>%LocalAppData%\AcrylicMenus</code></td><td><code>HKCU\...\Run</code> (ставит <code>Install.cmd</code>)</td></tr>
    <tr><td>7+ Taskbar Tweaker</td><td>текущая</td><td>rammichael.com (подпись: Michael Maltsev)</td><td><code>C:\7TaskbarTweaker</code></td><td>ставит установщик</td></tr>
    <tr><td>Windows Terminal</td><td>1.24+</td><td>Microsoft Store <code>9N0DX20HK701</code></td><td>Store</td><td>н/д</td></tr>
  </tbody>
</table>

Нагрузка (замер): суммарно около 40 МБ ОЗУ, процессор около 0 %.

## 3. Порядок выполнения

Быстрый путь: `irm https://raw.githubusercontent.com/swensi17/win-customization/main/Install.ps1 | iex` (или `scripts\Install-Auto.ps1`): переходит в 64-битный PowerShell 5.1, сам просит админа и сверяет пользователя, ставит Visual C++ x64, WebView2 и Windows Terminal, затем всё по порядку (04, 05, 07, 16 без ручных действий), не падает на одной ошибке, в конце печатает итог и запускает Test-Setup. Общие функции (загрузка с повтором, обход лимита GitHub API, проверка подписи и SHA-256, запуск без админа, перезапуск Проводника) лежат в `scripts\lib\Common.ps1`. Вручную остаётся только кнопка «Установить» в DWMBlurGlass и только при первой установке (WARN: у программы нет командной строки; флаг `-SkipManual` пропускает ожидание). WARN: `Install.ps1` держать только в ASCII и без BOM, иначе `irm | iex` падает; остальные `.ps1` наоборот в UTF-8 с BOM, иначе PowerShell 5.1 портит кириллицу. Подробно по шагам:

### Шаг 0. Проверка окружения `[AUTO]`
`scripts\00-prereqs.ps1`
- `[VERIFY]` build ≥ 19041, Windows Terminal установлен, политика `LocalMachine` не `Restricted`/`AllSigned` (иначе профиль PowerShell не загрузится).

### Шаг 1. TaskbarX: центр + прозрачность `[AUTO]`
`scripts\01-taskbarx.ps1`. Аргументы запуска: `-tbs=1 -color=0;0;0;0`.
- `-tbs`: 1 = прозрачная, 2 = блюр, 3 = акрил, 4 = прозрачная с градиентом, 5 = непрозрачная, 0 = выкл.
- Не добавлять `-dtbsowm=1`: он возвращает обычную панель, когда окно развёрнуто (получается серая панель).
- `[VERIFY]` `Get-Process TaskbarX`; иконки по центру; ярлык лежит в `[Environment]::GetFolderPath('Startup')`.
- `[ROLLBACK]` `scripts\99-rollback.ps1`.

### Шаг 2. Трей и «Новости» `[AUTO]`
`scripts\02-tray-and-news.ps1`
- `HKCU\...\Feeds\ShellFeedsTaskbarViewMode = 2` (Новости выкл).
- `HKCU\...\Explorer\EnableAutoTray = 1` (все значки уходят под `^`, системные остаются).
- Затем перезапускается Проводник. `[WARN]` Это закрывает TaskbarX, скрипт запускает его снова.
- `[MANUAL]` Нужные значки (мессенджеры и т.п.) пользователь перетаскивает из `^` на панель сам.
- `[VERIFY]` газеты нет, в трее только системные значки и стрелка.

### Шаг 3. DWMBlurGlass: стекло на рамках всех окон `[AUTO + MANUAL]`
`scripts\03-dwmblurglass.ps1` скачивает в `C:\DWMBlurGlass` и кладёт готовый `config.ini`.
- `[WARN]` Программа выдаёт «приложение должно быть запущено вне папки пользователя». Только `C:\...`.
- `[MANUAL]` Запустить `DWMBlurGlass.exe` → **Установить** (статус «Установлено») → вкладка «Цвета тёмного режима»: `RGBA(0,0,0,100)` для активного и неактивного заголовка → **Сохранить конфигурацию**.
- Если эффект не виден: вкладка «Символы» → скачать символы, затем «Удалить» → «Установить».
- Ключевые значения конфига (`configs\DWMBlurGlass.config.ini`): `blurAmount=35`, `activeBlendColorDark=1677721600` (чёрный, прозрачность около 100/255), `reflection=true`.

<img src="../screenshots/compare/c4-dwm.png" width="100%">

- `[VERIFY]` открыть Проводник: заголовок размытый и полупрозрачный.
- `[ROLLBACK]` в программе кнопка «Удалить».

### Шаг 4. ExplorerBlurMica: фон Проводника `[AUTO + MANUAL]`
`scripts\04-explorerblurmica.ps1` разворачивает `C:\ExplorerBlurMica\Release` и кладёт `config.ini`.
- `[MANUAL]` Запустить `register.cmd` (UAC). Он вызывает `regsvr32` и перезапускает Проводник.
- Конфиг: `effect=2` (Mica), тёмный цвет `0,0,0` с `a=120`.
- `[WARN]` `effect=3` (чистый блюр) даёт неприятное «моргание» при открытии окна: окно сначала резкое, потом включается стекло. Оставлять `effect=2`.
- После регистрации перезапустить TaskbarX (Проводник его убил).
- `[VERIFY]` фон списка файлов в Проводнике тёмный и полупрозрачный.
- `[ROLLBACK]` `uninstall.cmd` в той же папке.

### Шаг 5. AcrylicMenus: акрил в меню ПКМ `[AUTO + MANUAL]`
`scripts\05-acrylicmenus.ps1` → `[MANUAL]` `C:\AcrylicMenus\Installer\Install.cmd` (не `InstallAllUsers`).
- Установщик копирует файлы в `%LocalAppData%\AcrylicMenus`, пишет автозапуск и стартует `AcrylicMenusLoader.exe`.
- `[WARN]` Проект экспериментальный. Работает с классическими меню Win32 (Проводник, рабочий стол), нестандартные меню (Telegram, Electron) не затрагивает.
- `[VERIFY]` ПКМ по рабочему столу: меню размытое и полупрозрачное.
- `[ROLLBACK]` `Installer\Uninstall.cmd`.

![Меню ПКМ](../screenshots/05-context-menu.png)

### Шаг 6. Свои пункты в меню ПКМ `[AUTO]`
`scripts\06-context-menu-verbs.ps1` (только `HKCU`, без администратора).

<table width="100%">
  <thead>
    <tr><th align="left">Где</th><th align="left">Пункт</th><th align="left">Команда<br><img src="../screenshots/spacer.png" width="1600" height="1" alt=""></th></tr>
  </thead>
  <tbody>
    <tr><td>ПКМ по <code>.exe</code></td><td>Завершить процесс</td><td><code>cmd /c for %I in ("%1") do taskkill /f /im "%~nxI"</code></td></tr>
    <tr><td>Фон рабочего стола/папки</td><td>Закрыть зависшие программы</td><td><code>taskkill /f /fi "status eq not responding"</code></td></tr>
    <tr><td>Фон рабочего стола/папки</td><td>Диспетчер задач</td><td><code>taskmgr.exe</code></td></tr>
  </tbody>
</table>

- `[VERIFY]` пункты видны в меню (при необходимости перезапустить Проводник).

### Шаг 7. 7+ Taskbar Tweaker `[AUTO + MANUAL]`
`scripts\07-taskbar-tweaker.ps1` скачивает установщик и **проверяет цифровую подпись** (должна быть `Valid`, издатель Michael Maltsev); при невалидной подписи файл удаляется.
- `[MANUAL]` Запустить установщик, включить автозапуск. Рекомендуемые настройки:
  - Нажатие средней кнопки мыши по значку: **Закрыть**.
  - Колесо мыши над панелью: **переключение между окнами**.
  - Двойное нажатие на панели задач: **Диспетчер задач**.
  - Правая кнопка по значку: оставить «Список переходов».

![7+ Taskbar Tweaker](../screenshots/09-7tt-settings.png)

### Шаг 8. Консоль и терминал по умолчанию `[AUTO]`
`scripts\08-console-defaults.ps1`
- Старая консоль (`HKCU\Console`): прозрачность 215/255, Consolas 18 px, мягкая цветовая таблица, 120×30.
- Терминал по умолчанию: `HKCU\Console\%%Startup`: `DelegationConsole={2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}`, `DelegationTerminal={E12CFF52-A866-4C77-9A90-F570A7AA2C6B}`.
- `[WARN]` Ключ называется буквально `%%Startup`; в PowerShell обращаться через `-LiteralPath`.
- `[VERIFY]` `Win+R` → `cmd` открывается в Windows Terminal.

### Шаг 9. Windows Terminal: тема «Arch Glass» `[AUTO]`
`scripts\09-windows-terminal.ps1` копирует `configs\windows-terminal.settings.json` в
`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` (с бэкапом).

Ключевые параметры:
- Профиль по умолчанию: Windows PowerShell, команда `powershell.exe -NoLogo`.
- Профиль cmd: `cmd.exe /k "cls & prompt $E[38;2;23;147;209m$P$E[0m $E[38;2;158;206;106m❯$E[0m$S"`.
- `profiles.defaults`: шрифт Cascadia Code 12, `opacity=72`, `useAcrylic=true`, отступы `14,10,14,10`, курсор-палка, без полосы прокрутки.
- Схема «Arch Glass»: фон `#0b0f14`, текст `#c9d1d9`, акцент `#1793d1`.
- Тема окна «Arch Glass UI»: строка вкладок со стеклом: `tabRow.background=#12171dB8`, `unfocusedBackground=#12171dA0`, `useAcrylicInTabRow=true`.

`[WARN]` Ловушки конфига:
- В `schemes` цвета только `#rrggbb`. Прозрачность в `selectionBackground` (например, `#1793d155`) ломает загрузку всего файла («Не удалось загрузить параметры»).
- Полностью прозрачная строка вкладок (`...00`) даёт «пропадающие» кнопки окна при потере фокуса и вид «как будто нет фона». Нужен оттенок с непрозрачностью около 60–70 %.
- Шрифт: `JetBrainsMono Nerd Font` (шаг 13), запасной Cascadia Code встроен в Windows Terminal.
- Quake-режим: действие `quakeMode` на `win+sc(41)` (`Win + ~`) и `minimizeToNotificationArea=true`; горячая клавиша работает, пока процесс Windows Terminal запущен.

<img src="../screenshots/20-quake.png" width="520">


<img src="../screenshots/compare/c5-terminal.png" width="100%">

### Шаг 10. Профиль PowerShell и cmd: логотип Windows 7 `[AUTO]`
`scripts\10-powershell-profile.ps1` кладёт в папку профиля `Microsoft.PowerShell_profile.ps1`, общую заставку `Show-Splash.ps1` и оформление cmd `cmd-autorun.cmd` (из `configs\`), а также прописывает `AutoRun` для cmd.

Что делает профиль:
- Заставка: цветной логотип Windows 7 (ASCII, 4 цвета) + информация: пользователь@хост, ОС, аптайм, оболочка, CPU, GPU, RAM, диск C, IP, число процессов, время.
- Приглашение: голубой путь (`~` для домашней папки, длинные пути сокращаются до `…\последние\три\папки`) + зелёная стрелка `❯`. В cmd путь выводится отдельной строкой (`$_` в `prompt`), стрелка ниже.
- Быстрый старт: статичные данные (ОС/CPU/GPU) кэшируются в `%LOCALAPPDATA%\splash-cache.json` на 7 дней, остальное считается без WMI (около 75 мс).
- Демо-режим для публичных скриншотов: файл `splash-demo.json` рядом с профилем (`{"user":"user","host":"pc","ip":"192.168.1.10"}`) подменяет имя, хост и IP на нейтральные. Удали файл, чтобы вернуть реальные значения.
- Заставка включается только в интерактивной консоли (`-not [Console]::IsOutputRedirected`), поэтому скрипты и инструменты её не видят. Отключить вручную: `$env:NO_SPLASH=1`.

- **cmd.** Скрипт `cmd-autorun.cmd` прописывается в `HKCU\Software\Microsoft\Command Processor\AutoRun` значением `if exist "<путь>\cmd-autorun.cmd" call "<путь>\cmd-autorun.cmd"`. Он включает `chcp 65001`, ставит цветное приглашение и вызывает `Show-Splash.ps1 -ShellName "Command Prompt"`. Профиль «Командная строка» в Windows Terminal оставлен обычным `cmd.exe`.
- `[WARN]` AutoRun выполняется при **каждом** запуске cmd, в том числе `cmd /c` из других программ. Поэтому скрипт обязан сразу выходить для неинтерактивных запусков: проверять `%cmdcmdline%` только через отложенное раскрытие (`setlocal EnableDelayedExpansion`, `!cmdcmdline!`), иначе символы `& | ! % "` в чужой команде ломают разбор.
- `[WARN]` Для запуска из терминала `cmdcmdline` равна `cmd.exe ` (без ключей), хвост после `cmd.exe` бывает пустым. Подстановка кавычек на пустой переменной даёт мусор, поэтому к хвосту дописывается символ `x`, и сравнивать нужно с `x`.
- `[VERIFY]` `cmd /c "echo a & echo b | find \"b\""` даёт тот же вывод, что с отключённым автозапуском (`cmd /d /c ...`); новая вкладка `cmd.exe` показывает заставку.
<img src="../screenshots/19-cmd-splash.png" width="520">
`[WARN]` Выравнивание: каждая строка логотипа дополняется пробелами до видимой ширины 46 символов. Если ширина строк логотипа меняется, поправь число 46 в цикле вывода.
`[WARN]` В PowerShell запятая в массиве имеет приоритет над `+`: `"a" + "b",` ломает элементы массива. Склеивай строки внутри одной пары кавычек.

- `[VERIFY]` новая вкладка PowerShell показывает логотип и ровный столбец данных.
- `[ROLLBACK]` вернуть `Microsoft.PowerShell_profile.ps1.bak`.

### Шаг 11. Обои `[AUTO]`
`scripts\11-wallpaper.ps1` (Wallhaven, SFW, тёмные градиенты 4K, около 0,4 и 0,6 МБ) → `C:\Wallpapers`.

### Шаг 12. SysMonTray: индикатор нагрузки в трее `[AUTO]`
`scripts\12-sysmon-tray.ps1` копирует `configs\SysMonTray.ps1` в `C:\SysMonTray`, создаёт ярлык автозапуска в **настоящей** папке Startup и запускает скрипт скрытым окном (`powershell.exe -NoProfile -STA -WindowStyle Hidden -File ...`).
- Поведение: один значок с числом 0–100 (заполнение RAM, цифры белые, жёлтые от 75, красные от 90); левый клик переключает RAM ↔ CPU; подсказка `RAM: N/100 (X/Y ГБ)` и `CPU: N/100`.
- `[WARN]` Текст подсказки `NotifyIcon.Text` не длиннее 63 символов, иначе при обновлении значка возникает исключение и значок перестаёт реагировать.
- `[WARN]` Для цикла сообщений трея нужен режим `-STA`. Без него значок не появляется.
- `[WARN]` Значок появляется под стрелкой `^`, если включён `EnableAutoTray=1`; пользователь перетаскивает его на панель сам.
- `[VERIFY]` `Test-Setup.ps1`: процесс и ярлык автозагрузки; визуально число рядом с `^`.
- `[ROLLBACK]` `99-rollback.ps1` (останавливает процесс, удаляет ярлык и папку `C:\SysMonTray`).

<img src="../screenshots/18-sysmon-tray.png" width="520">

### Шаг 13. Nerd Font `[AUTO]`
`scripts\13-nerd-font.ps1` скачивает JetBrainsMono Nerd Font `v3.5.1` и ставит 4 начертания (Regular, Bold, Italic, BoldItalic) для текущего пользователя: `%LOCALAPPDATA%\Microsoft\Windows\Fonts` + `HKCU\...\Fonts`. В терминале шрифт задан как `JetBrainsMono Nerd Font` (шаг 09), GDI-имя семейства `JetBrainsMono NF`.
- `[WARN]` Архив `.tar.xz` встроенный `tar` Windows 10 не распаковывает (нет `xz`), поэтому используется `.zip`.
- `[WARN]` Если установку выполняет упакованное (MSIX) приложение, запись в `%LOCALAPPDATA%` виртуализируется и шрифт системе не виден. Тогда ставить в `C:\Windows\Fonts` + `HKLM` (нужны права администратора).
- `[VERIFY]` в приглашении внутри git-репозитория видна иконка ветки ``, а не квадрат.

### Шаг 13a. Приглашение и PSReadLine `[AUTO]` (часть профиля, шаг 10)
- Приглашение: путь (`~`, сокращение длинных путей), ветка git (чтение `.git/HEAD` вверх по дереву, без `git.exe`, поддержка worktree через файл `.git`), время последней команды ≥ 0,5 с, стрелка зелёная/красная по `$?` (первая строка функции `prompt`).
- PSReadLine: цвета через ANSI-последовательности, ↑/↓ = `HistorySearchBackward/Forward`, `Tab` = `MenuComplete`. Подсказки `-PredictionSource History` включаются только при версии ≥ 2.1.
- `[WARN]` **Не обновлять PSReadLine из PowerShell Gallery на этой системе.** Версии 2.3.6 и 2.4.5 закрывали консоль Windows Terminal с кодом 5 на первом нажатии клавиши, даже с `-NoProfile`. Встроенный 2.0.0 работает. Если новую версию уже поставили: удалить `Documents\WindowsPowerShell\Modules\PSReadLine\<версия>`; если DLL заблокирована открытым окном, сначала переименовать `PSReadLine.psd1` в этой папке, тогда версия перестаёт быть видимой.

### Шаг 14. Тёмная тема и акцентный цвет `[AUTO]`
`scripts\14-accent-theme.ps1`: `AppsUseLightTheme=0`, `SystemUsesLightTheme=0`, `EnableTransparency=1`; акцент `#1793D1`: `Accent\AccentColorMenu=0xFFD19317` (ABGR), `StartColorMenu`, `AccentPalette` (8×RGBA), `DWM\AccentColor`, `ColorizationColor=0xC41793D1`, `ColorPrevalence=0`. Применяется рассылкой `WM_SETTINGCHANGE` (`ImmersiveColorSet`) без перезапуска Проводника.
- `[WARN]` В PowerShell 5.1 литерал `0xFFD19317` становится отрицательным Int32, и операции с `[uint32]` падают. Значения DWORD задавать через `[Convert]::ToInt32('FFD19317',16)`.
- `[ROLLBACK]` `99-rollback.ps1` восстанавливает значения из `%USERPROFILE%\accent-backup.json`.

### Шаг 15. Автозагрузка `[AUTO]`
`scripts\15-startup-review.ps1 [-Disable <маска>] [-Enable <маска>]`: отключение через `HKCU\...\Explorer\StartupApproved\Run` значением `03 00 00 00` + FILETIME (как «Диспетчер задач»), запись в `Run` остаётся. Не отключать компоненты оформления.

### Шаг 16. Живые обои Aurora Glass `[AUTO + MANUAL]`
`scripts\16-live-wallpaper.ps1` собирает `C:\LivelyWallpapers\aurora-glass.zip` из `configs\lively\aurora-glass\` (`index.html` + `LivelyInfo.json`, `Type=1` = веб-обои) и открывает Lively.
- `[MANUAL]` Lively → `+` → выбрать zip → кликнуть «Aurora Glass».
- `[WARN]` `Lively.exe setwp --file <html|папка|zip>` в Lively 2.x пишет в журнал `Unsupported command import file` для файлов не из библиотеки; импорт только через окно. Класть пакет напрямую в `%LOCALAPPDATA%\Lively Wallpaper\Library\wallpapers` из упакованного приложения бесполезно: запись виртуализируется.
- `[VERIFY]` `%LOCALAPPDATA%\Lively Wallpaper\WallpaperLayout.json` → `LivelyInfoPath` указывает на Aurora Glass.

<img src="../screenshots/21-aurora.png" width="520">

### Шаг 17. ShellGuard: автовосстановление после зависания Проводника `[AUTO]` (по желанию)
`scripts\17-shell-guard.ps1` копирует `configs\ShellGuard.ps1` в `C:\ShellGuard`, создаёт ярлык автозагрузки в **настоящей** папке Startup и запускает скрипт скрытым окном. В `Install-Auto.ps1` не входит.
- Причина: `explorer.exe` иногда зависает (журнал: «Application Hang», Winlogon 1002 «Оболочка неожиданно завершила работу») и перезапускается. TaskbarX и подложка Lively (`WorkerW`) «осиротевают»: панель теряет центр и прозрачность, TaskbarX может вхолостую грузить процессор, живые обои пропадают, остаются статичные.
- Логика: каждые 5 с сравнивается `StartTime` процесса `explorer.exe` с `StartTime` у TaskbarX и Lively; если они старше Проводника, через 10 с TaskbarX перезапускается (`-tbs=1 -color=0;0;0;0`), а Lively перезапускается целиком. Пауза между ремонтами 90 с, журнал `C:\ShellGuard\guard.log`.
- `[WARN]` Повторное применение обоев командой `Lively.exe setwp` / `closewp` в такой ситуации не срабатывает (в журнале Lively нет записей, старый плеер остаётся скрытым): нужен полный перезапуск `Lively.exe`, `Lively.Player.WebView2.exe`, `Lively.Watchdog.exe`.
- `[WARN]` Диагностика: окно плеера `visible=False` и пропавший `WorkerW` (хэндл из журнала Lively `WorkerW initialized`), время запуска `explorer.exe` позже запуска TaskbarX/Lively.
- `[WARN]` Страж лечит последствия. Причину зависания в Lite-сборке выяснить нельзя (отчёты WER отключены); подозреваемые: расширения Проводника AcrylicMenus и ExplorerBlurMica.
- `[VERIFY]` `powershell -File C:\ShellGuard\ShellGuard.ps1 -Check` показывает `устарели : False`; `-RepairNow` перезапускает TaskbarX и Lively, строки видны в `guard.log` и в журнале Lively (`Setting wallpaper`).
- `[ROLLBACK]` `99-rollback.ps1` (останавливает страж, удаляет ярлык и папку `C:\ShellGuard`).

### Шаг 18. PowerToys `[AUTO]`
`scripts\18-powertoys.ps1` скачивает `PowerToysUserSetup-*-x64.exe` из релизов `microsoft/PowerToys`, проверяет подпись Microsoft и ставит тихо для пользователя в `%LOCALAPPDATA%\PowerToys`, затем запускает без прав администратора.
- `[WARN]` Установщик около 320 МБ, кэшируется в `%TEMP%\win-customization`.
- `[WARN]` На Lite-сборке бандл падает с `0x80070003`: служба MSI не открывает файл из `%LOCALAPPDATA%\Package Cache` (ошибка 2203). Скрипт копирует MSI, пока бандл его распаковывает, и ставит его через `msiexec /i ... /qn`.
- `[VERIFY]` процесс `PowerToys` запущен, есть `%LOCALAPPDATA%\PowerToys\PowerToys.exe`, `Alt + Space` открывает поиск.
- `[ROLLBACK]` `99-rollback.ps1` (`msiexec /x` по коду продукта PowerToys из реестра).

### Шаг 19. Open-Shell: меню «Пуск» на стекле `[AUTO]`
`scripts\19-open-shell.ps1` ставит из релиза `Open-Shell/Open-Shell-Menu` только Start Menu (`/qn ADDLOCAL=StartMenu`, SHA-256 сверяется), пишет настройки в `HKCU:\Software\OpenShell\StartMenu\Settings` (`MenuStyle=Win7`, `SkinW7=Windows Aero`, `GlassOverride=1`, `GlassColor=0x1C1410`, `GlassOpacity=55`) и перезапускает `StartMenu.exe`.
- `[WARN]` Установщику нужны права администратора; `StartMenu.exe` запускать от пользователя, иначе меню не перехватит Win.
- `[VERIFY]` процесс `StartMenu` запущен, клавиша Win открывает стеклянное меню.
- `[ROLLBACK]` `99-rollback.ps1` (`msiexec /x` по коду продукта и удаление `HKCU:\Software\OpenShell`).

## 4. Грабли и ограничения

1. **Виртуализация AppData у упакованных (MSIX) агентов.** Если исполнитель запущен из Store-приложения, запись в `%LOCALAPPDATA%` и `%APPDATA%` попадает в `...\Packages\<Приложение>\LocalCache\...`, и Проводник пользователя этих файлов не видит. Симптомы: «Расположение недоступно», ярлык автозагрузки не срабатывает после перезагрузки. Решение: программы в `C:\...`, ярлык автозагрузки писать по реальному пути `...\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`, шаги выполнять с отключённой изоляцией песочницы.
2. **DWMBlurGlass** не запускается из профиля пользователя (см. шаг 3).
3. **Перезапуск Проводника убивает TaskbarX.** После любого `taskkill /f /im explorer.exe` запускать TaskbarX заново.
4. **Окно «Параметры», Магазин, Почта и подобные UWP-окна** не становятся стеклянными: фон рисует само приложение. Стекло достаётся только рамке и заголовку (через DWMBlurGlass).
5. **Telegram, браузеры, Cursor/VS Code**: полноценного размытия фона внутри окна нет. Можно задать только прозрачность окна, это не стекло.
6. **Старые файлы webp** нельзя открыть через `System.Drawing`; при подготовке картинок использовать Pillow.
7. **fastfetch** не использован: логотип нарисован внутри профиля, чтобы не зависеть от внешнего бинарника.

## 5. Финальный чек-лист VERIFY

```powershell
Get-Process TaskbarX, DWMBlurGlass, AcrylicMenusLoader -ErrorAction SilentlyContinue | Select Name
Get-ChildItem ([Environment]::GetFolderPath('Startup')) | Select Name
(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer").EnableAutoTray        # 1
(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds").ShellFeedsTaskbarViewMode # 2
Test-Path "HKCU:\Software\Classes\exefile\shell\EndProcess"                                          # True
(Get-ItemProperty -LiteralPath "HKCU:\Console\%%Startup").DelegationTerminal                         # {E12CFF52-...}
Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Test-Path $PROFILE.CurrentUserCurrentHost
```

Визуально: иконки по центру и прозрачная панель; стеклянные заголовки в Проводнике; стеклянное меню ПКМ; новая вкладка PowerShell с логотипом Windows 7 и ровными столбцами.

## 6. Тонкая настройка

<table width="100%">
  <thead>
    <tr><th align="left">Что менять</th><th align="left">Где</th><th align="left">Эффект<br><img src="../screenshots/spacer.png" width="1600" height="1" alt=""></th></tr>
  </thead>
  <tbody>
    <tr><td>Прозрачность панели</td><td><code>scripts\01-taskbarx.ps1</code>, <code>-tbs=</code> / <code>-color=</code></td><td>2 = блюр, 3 = акрил, 4 = градиент</td></tr>
    <tr><td>Сила размытия заголовков</td><td><code>DWMBlurGlass.config.ini</code>: <code>blurAmount</code></td><td>больше число — «жиже»</td></tr>
    <tr><td>Цвет заголовков</td><td><code>activeBlendColorDark</code> (ARGB в десятичном)</td><td>оттенок и прозрачность стекла</td></tr>
    <tr><td>Стекло Проводника</td><td><code>ExplorerBlurMica.config.ini</code>: <code>effect</code> (1 акрил, 2 Mica, 4 MicaAlt), <code>[dark] a=</code></td><td>прозрачность</td></tr>
    <tr><td>Прозрачность терминала</td><td><code>windows-terminal.settings.json</code>: <code>profiles.defaults.opacity</code></td><td>60–85</td></tr>
    <tr><td>Заставка</td><td>профиль PowerShell: массив <code>$logo</code>, <code>$info</code></td><td>логотип и строки</td></tr>
  </tbody>
</table>

## 7. Откат

`scripts\99-rollback.ps1` убирает всё автоматическое. Ручные компоненты удаляются штатно: DWMBlurGlass («Удалить»), `uninstall.cmd` у ExplorerBlurMica и AcrylicMenus, деинсталлятор 7+ Taskbar Tweaker, затем удалить папки в `C:\`. Настройки терминала и профиля восстанавливаются из `*.bak`.

## 8. Источники

- TaskbarX: https://github.com/ChrisAnd1998/TaskbarX
- DWMBlurGlass: https://github.com/Maplespe/DWMBlurGlass
- ExplorerBlurMica: https://github.com/Maplespe/ExplorerBlurMica
- AcrylicMenus: https://github.com/krlvm/AcrylicMenus
- 7+ Taskbar Tweaker: https://rammichael.com/7-taskbar-tweaker
- Windows Terminal: https://apps.microsoft.com/detail/9n0dx20hk701
- Wallhaven: https://wallhaven.cc
