# [AUTO] Стеклянная тема Firefox RaiZee (основа: gwfox): прозрачный интерфейс, тёмные страницы.
# Берёт RaiZee-Firefox-Glass.zip из релиза raizeeandsolutions/raizee-glass, сверяет SHA-256 и кладёт в профиль
# только userChrome.css, userContent.css и блок настроек в user.js. AutoConfig в папку Firefox не ставится,
# права администратора не нужны. Применяется после перезапуска Firefox.
param([string]$Tag = 'v6.1')
. "$PSScriptRoot\lib\Common.ps1"
$repo = 'raizeeandsolutions/raizee-glass'

# профиль по умолчанию: секция [Install...] в profiles.ini
$ini = Join-Path $env:APPDATA 'Mozilla\Firefox\profiles.ini'
if (-not (Test-Path $ini)) { throw "Firefox не найден: нет profiles.ini, запусти Firefox хотя бы раз" }
$rel = $null; $inInstall = $false
foreach ($line in Get-Content $ini) {
    if ($line -match '^\[Install') { $inInstall = $true; continue }
    if ($line -match '^\[') { $inInstall = $false }
    if ($inInstall -and $line -match '^Default=(.+)$') { $rel = $Matches[1]; break }
}
if (-not $rel) { throw "Не найден профиль Firefox по умолчанию в profiles.ini" }
$profileDir = Join-Path (Join-Path $env:APPDATA 'Mozilla\Firefox') ($rel -replace '/', '\')
if (-not (Test-Path $profileDir)) { throw "Папка профиля не найдена: $profileDir" }

$zip = Get-File "https://github.com/$repo/releases/download/$Tag/RaiZee-Firefox-Glass.zip" "RaiZee-Firefox-Glass-$Tag.zip" -Zip
$want = $null
try {
    $r = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/tags/$Tag" -UseBasicParsing -TimeoutSec 30
    $want = (($r.assets | Where-Object name -eq 'RaiZee-Firefox-Glass.zip').digest -replace '^sha256:', '')
} catch {}
if ($want -and (Get-FileHash $zip -Algorithm SHA256).Hash -ne $want) { Remove-Item $zip -Force; throw "SHA-256 архива не совпадает с релизом $Tag, файл удалён" }
$src = Join-Path $env:TEMP "win-customization\raizee-ff-$Tag"
Expand-Zip $zip $src
$kit = Get-ChildItem $src -Recurse -Filter 'chrome.css' | Select-Object -First 1 | ForEach-Object DirectoryName
if (-not $kit) { throw "В архиве нет chrome.css" }

$chrome = Join-Path $profileDir 'chrome'
New-Item -ItemType Directory -Force $chrome | Out-Null
# своя тема уже лежит? сохраняем копию рядом, а не затираем молча
foreach ($n in 'userChrome.css', 'userContent.css') {
    $t = Join-Path $chrome $n
    if ((Test-Path $t) -and -not (Test-Path "$t.before-raizee")) { Copy-Item $t "$t.before-raizee" }
}
Copy-Item (Join-Path $kit 'chrome.css') (Join-Path $chrome 'userChrome.css') -Force
Copy-Item (Join-Path $kit 'content-glass.css') (Join-Path $chrome 'userContent.css') -Force
# свои правки поверх темы: круглые стеклянные плитки на новой вкладке, на Windows 10 без двойных кнопок окна
$ov = Join-Path (Split-Path $PSScriptRoot) 'configs\firefox-glass'
Get-Content (Join-Path $ov 'userContent-overrides.css') -Raw -Encoding UTF8 | Add-Content (Join-Path $chrome 'userContent.css') -Encoding UTF8
if (-not (Test-Win11)) {
    Get-Content (Join-Path $ov 'userChrome-overrides-win10.css') -Raw -Encoding UTF8 | Add-Content (Join-Path $chrome 'userChrome.css') -Encoding UTF8
}
Set-Content (Join-Path $chrome 'RaiZee-version.txt') $Tag -Encoding ASCII

# блок настроек в user.js между маркерами, чужие строки не трогаем
$userJs = Join-Path $profileDir 'user.js'
$begin = '// RaiZee prefs begin'; $end = '// RaiZee prefs end'
$lines = if (Test-Path $userJs) { @(Get-Content $userJs) } else { @() }
$kept = New-Object System.Collections.Generic.List[string]; $skip = $false
foreach ($l in $lines) { if ($l.Trim() -eq $begin) { $skip = $true; continue }; if ($l.Trim() -eq $end) { $skip = $false; continue }; if (-not $skip) { $kept.Add($l) } }
$kept.Add($begin)
'toolkit.legacyUserProfileCustomizations.stylesheets", true', 'widget.windows.mica", true', 'widget.windows.mica.popups", 2',
'browser.tabs.allow_transparent_browser", true', 'layout.css.prefers-color-scheme.content-override", 0', 'browser.in-content.dark-mode", true' |
    ForEach-Object { $kept.Add("user_pref(`"$_);") }
$kept.Add($end)
[IO.File]::WriteAllLines($userJs, $kept, (New-Object Text.UTF8Encoding $false))

if (Get-Process firefox -ErrorAction SilentlyContinue) { "Тема установлена, перезапусти Firefox, чтобы она включилась" } else { "Тема Firefox установлена" }
