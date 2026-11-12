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
Set-Reg $k 'SkinW7'          'Windows Aero' 'String'
Set-Reg $k 'SkinVariationW7' '' 'String'
Set-Reg $k 'GlassOverride'   1
Set-Reg $k 'GlassColor'      0x1C1410        # BGR: тёмно-синий (#10141C)
Set-Reg $k 'GlassIntensity'  100
Set-Reg $k 'GlassBlending'   60
Set-Reg $k 'GlassOpacity'    55
Set-Reg $k 'EnableStartButton' 0             # своя кнопка не нужна, меню открывается по кнопке Windows и клавише Win
Set-Reg $k 'MenuShadow'      1
Set-Reg $k 'EnableSettings'  1

# перезапуск меню, чтобы подхватить настройки
Start-Process $exe '-exit' -Wait -ErrorAction SilentlyContinue
Start-Sleep 1
Start-UserProcess $exe '-autorun'
if (Wait-ProcessUp 'StartMenu' 15) { "Open-Shell OK" } else { throw "Open-Shell не запустился" }
