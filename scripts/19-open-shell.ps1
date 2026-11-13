# [AUTO] Open-Shell: меню «Пуск» в стиле Windows 7 на тёмном стекле, как Проводник с DWMBlurGlass.
# Ставится только компонент Start Menu (без Classic Explorer и IE), установщик сверяется по SHA-256 из релиза.
# Стандартное меню Windows остаётся: Shift + клик по кнопке «Пуск».
param([switch]$Force)
. "$PSScriptRoot\lib\Common.ps1"
$dir = "$env:ProgramFiles\Open-Shell"
$exe = Join-Path $dir 'StartMenu.exe'
if ((Test-Path $exe) -and -not $Force) {
    "Open-Shell уже установлен: $((Get-Item $exe).VersionInfo.ProductVersion)"
} else {
    if (-not (Test-IsAdmin)) { throw "Нужны права администратора" }
    $url = Get-GitHubAssetUrl 'Open-Shell/Open-Shell-Menu' 'OpenShellSetup_*.exe'
    $setup = Get-File $url ($url -split '/')[-1]
    Assert-GitHubAsset $setup 'Open-Shell/Open-Shell-Menu'
    $r = Start-Process $setup -ArgumentList '/qn', 'ADDLOCAL=StartMenu' -Wait -PassThru
    if (-not (Test-Path $exe)) { throw "Open-Shell не найден после установки (код $($r.ExitCode))" }
}

# настройки пользователя: стиль Windows 7, скин Windows Aero, тёмное стекло с акцентом #1793D1
$k = 'HKCU:\Software\OpenShell\StartMenu\Settings'
Set-Reg $k 'MenuStyle'       'Win7' 'String'
Set-Reg $k 'SkinW7'          'Immersive' 'String'     # плоский скин в духе Windows 10/11, а не Aero из Windows 7
Set-Reg $k 'SkinVariationW7' '' 'String'
Set-Reg $k 'SkinOptionsW7'   ([string[]]('DARK=1', 'LIGHT=0', 'AUTO=0', 'TRANSPARENT_MORE=1', 'TRANSPARENT_LESS=0', 'OPAQUE=0', 'USER_IMAGE=0', 'USER_NAME=0', 'SMALL_ICONS=0', 'DISABLE_MASK=1')) 'MultiString'
# матовое стекло: меньше заливки цветом, больше прозрачности
Set-Reg $k 'GlassOverride'   1
Set-Reg $k 'GlassColor'      0x2A2420        # BGR: графит с синевой (#20242A)
Set-Reg $k 'GlassIntensity'  100
Set-Reg $k 'GlassBlending'   25
Set-Reg $k 'GlassOpacity'    40
Set-Reg $k 'EnableStartButton' 0             # своя кнопка не нужна, меню открывается по кнопке Windows и клавише Win
Set-Reg $k 'MenuShadow'      1
Set-Reg $k 'EnableSettings'  1

# перезапуск меню, чтобы подхватить настройки
Start-Process $exe '-exit' -Wait -ErrorAction SilentlyContinue
Start-Sleep 1
Start-UserProcess $exe '-autorun'
if (Wait-ProcessUp 'StartMenu' 15) { "Open-Shell OK" } else { throw "Open-Shell не запустился" }
