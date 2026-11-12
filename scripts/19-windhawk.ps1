# [AUTO] Windhawk: магазин модов для Windows (панель задач, трей, часы, меню). Моды ставятся из окна программы.
# Установщик с GitHub (ramensoftware/windhawk) сверяется по SHA-256 из релиза, ставится тихо (NSIS, /S). Уже стоит - шаг пропускается.
param([switch]$Force)
. "$PSScriptRoot\lib\Common.ps1"
$exe = "$env:ProgramFiles\Windhawk\windhawk.exe"
if ((Test-Path $exe) -and -not $Force) {
    "Windhawk уже установлен: $((Get-Item $exe).VersionInfo.ProductVersion)"
} else {
    $url = Get-GitHubAssetUrl 'ramensoftware/windhawk' 'windhawk_setup.exe'
    $setup = Get-File $url 'windhawk_setup.exe'
    Assert-GitHubAsset $setup 'ramensoftware/windhawk'
    Start-Process $setup -ArgumentList '/S' -Wait
    if (-not (Test-Path $exe)) { throw "Windhawk не найден после установки" }
}
# Windhawk сам ставит службу и автозапуск; окно управления открывается из трея
if (Wait-ProcessUp 'windhawk' 20) { "Windhawk OK" } else { Start-UserProcess $exe '-tray-only'; if (Wait-ProcessUp 'windhawk' 15) { "Windhawk OK" } else { throw "Windhawk не запустился" } }
