# [AUTO] PowerToys: поиск и запуск по Alt+Space, зоны окон (FancyZones), окно поверх остальных, пипетка, текст с экрана.
# Ставится для текущего пользователя (без Program Files), тихо, установщик с подписью Microsoft. Уже стоит - шаг пропускается.
param([switch]$Force)
. "$PSScriptRoot\lib\Common.ps1"
$dir = "$env:LOCALAPPDATA\PowerToys"
$exe = Join-Path $dir 'PowerToys.exe'
if ((Test-Path $exe) -and -not $Force) {
    "PowerToys уже установлен: $((Get-Item $exe).VersionInfo.ProductVersion)"
} else {
    $url = Get-GitHubAssetUrl 'microsoft/PowerToys' 'PowerToysUserSetup-*-x64.exe'
    $setup = Get-File $url ($url -split '/')[-1]
    Assert-Signed $setup 'Microsoft'
    # На части сборок (Lite) служба Windows Installer не открывает MSI из AppData\Local\Package Cache (ошибка 2203, 0x80070003).
    # Поэтому ловим MSI, пока бандл его распаковывает, и при неудаче ставим его сами через msiexec из папки кэша.
    $msi = Join-Path (Split-Path $setup) 'PowerToysUserSetup-x64.msi'
    Remove-Item $msi -ErrorAction SilentlyContinue
    $p = Start-Process $setup -ArgumentList '/quiet', '/norestart' -PassThru
    while (-not $p.HasExited -and -not (Test-Path $msi)) {
        Get-ChildItem "$env:LOCALAPPDATA\Package Cache" -Recurse -Filter 'PowerToys*.msi' -ErrorAction SilentlyContinue |
            Select-Object -First 1 | ForEach-Object { try { Copy-Item $_.FullName $msi -ErrorAction Stop } catch {} }
        Start-Sleep -Milliseconds 50
    }
    $p.WaitForExit()
    if (-not (Test-Path $exe)) {
        if (-not (Test-Path $msi)) { throw "Установщик PowerToys не сработал (лог в $env:TEMP\powertoys-bootstrapper-*.log)" }
        Assert-Signed $msi 'Microsoft'
        "Бандл не поставил PowerToys, ставлю MSI напрямую"
        $r = Start-Process msiexec -ArgumentList '/i', "`"$msi`"", '/qn', '/norestart' -Wait -PassThru
        if ($r.ExitCode -notin 0, 3010 -or -not (Test-Path $exe)) { throw "msiexec вернул $($r.ExitCode), PowerToys не установлен" }
    }
}
# автозапуск PowerToys включает сам (задача в планировщике); запускаем без прав администратора
if (-not (Get-Process PowerToys -ErrorAction SilentlyContinue)) { Start-UserProcess $exe }
if (Wait-ProcessUp 'PowerToys' 20) { "PowerToys OK" } else { throw "PowerToys не запустился" }
