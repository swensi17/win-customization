# [AUTO] Проверка окружения и установка зависимостей, которых нет на урезанных сборках:
# Visual C++ 2015-2022 x64 (нужен DLL-модам), WebView2 Runtime (нужен Lively), политика запуска для профиля PowerShell.
. "$PSScriptRoot\lib\Common.ps1"
$os = Get-CimInstance Win32_OperatingSystem
$build = [int]$os.BuildNumber
"OS:       $($os.Caption) build $build, $($os.OSArchitecture)"
if (-not [Environment]::Is64BitOperatingSystem) { throw "Нужна 64-битная Windows" }
if ($build -lt 19041) { Write-Warning "Рассчитано на Windows 10 2004+ (build 19041+). На старых сборках часть оформления может не работать." }
if ($build -ge 22000) { Write-Warning "Windows 11: TaskbarX не поддерживается и будет пропущен, остальное ставится." }
"Admin:    $(Test-IsAdmin)"

$free = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
"Disk C:   свободно $free ГБ"
if ($free -lt 1.5) { throw "На диске C мало места ($free ГБ), нужно хотя бы 1.5 ГБ" }

try { Invoke-WebRequest 'https://github.com' -Method Head -UseBasicParsing -TimeoutSec 20 -UserAgent $script:WczUA | Out-Null; "GitHub:   доступен" }
catch { throw "GitHub недоступен ($($_.Exception.Message)). Проверь интернет, прокси или VPN." }

# .NET Framework 4.7.2+ (TaskbarX). В Windows 10 1803+ встроен, на урезанных сборках может быть удалён.
$rel = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Release
if ($rel -ge 461808) { ".NET:     4.7.2+ есть" }
else { Write-Warning ".NET Framework 4.7.2+ не найден: TaskbarX может не запуститься. Установщик .NET 4.8: https://dotnet.microsoft.com/download/dotnet-framework/net48" }

# Visual C++ 2015-2022 x64
$vc = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -ErrorAction SilentlyContinue
if ($vc.Installed -eq 1) { "VC++:     $($vc.Version) есть" }
else {
  "VC++:     нет, ставлю..."
  $exe = Get-File 'https://aka.ms/vs/17/release/vc_redist.x64.exe' 'vc_redist.x64.exe'
  Assert-Signed $exe 'Microsoft'
  $p = Start-Process $exe -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
  if ($p.ExitCode -notin 0, 1638, 3010) { throw "Visual C++ не установился (код $($p.ExitCode))" }
  if ($p.ExitCode -eq 3010) { $global:WczRebootNeeded = $true }
  "VC++:     установлен"
}

# WebView2 Runtime: Lively рисует обои через него. На сборках без Edge его нет.
function Test-WebView2 {
  foreach ($k in 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
                 'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
                 'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}') {
    $pv = (Get-ItemProperty $k -ErrorAction SilentlyContinue).pv
    if ($pv -and $pv -ne '0.0.0.0') { return $pv }
  }
  $d = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView\Application" -Directory -ErrorAction SilentlyContinue | Where-Object Name -match '^\d+\.' | Select-Object -First 1
  if ($d) { return $d.Name }
  return $null
}
$wv = Test-WebView2
if ($wv) { "WebView2: $wv есть" }
else {
  "WebView2: нет, ставлю..."
  try {
    $exe = Get-File 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' 'MicrosoftEdgeWebview2Setup.exe'
    Assert-Signed $exe 'Microsoft'
    Start-Process $exe -ArgumentList '/silent', '/install' -Wait | Out-Null
  } catch { Write-Warning "Онлайн-установщик WebView2 не сработал: $($_.Exception.Message)" }
  if (-not (Test-WebView2)) {
    # без службы обновлений Edge онлайн-установщик не работает: берём полный офлайн-пакет
    "WebView2: пробую полный установщик..."
    $exe = Get-File 'https://go.microsoft.com/fwlink/?linkid=2124701' 'MicrosoftEdgeWebView2RuntimeInstallerX64.exe'
    Assert-Signed $exe 'Microsoft'
    Start-Process $exe -ArgumentList '/silent', '/install' -Wait | Out-Null
  }
  if (Test-WebView2) { "WebView2: установлен" } else { Write-Warning "WebView2 не установился: живые обои Lively могут не работать" }
}

# политика запуска: без неё профиль PowerShell (шаг 10) не загрузится
if ((Get-ExecutionPolicy -Scope CurrentUser) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
  try { Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force -ErrorAction Stop } catch {}
}
$eff = Get-ExecutionPolicy
"Policy:   $eff"
if ($eff -in 'Restricted', 'AllSigned') { Write-Warning "Групповая политика держит ExecutionPolicy = ${eff}: профиль PowerShell (шаг 10) загружаться не будет" }
