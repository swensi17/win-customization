# Общие функции для шагов установки. Подключение в начале шага: . "$PSScriptRoot\lib\Common.ps1"
# Всё здесь рассчитано на чужие ПК: нет winget, урезанные сборки, прокси, лимиты GitHub API, повторный запуск поверх старой установки.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'          # с полосой прогресса Invoke-WebRequest в 5.1 качает в разы медленнее
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Net.WebRequest]::DefaultWebProxy.Credentials = [Net.CredentialCache]::DefaultNetworkCredentials } catch {}
$script:WczUA    = 'win-customization-installer'
$script:WczCache = Join-Path $env:TEMP 'win-customization'
New-Item -ItemType Directory -Force $script:WczCache | Out-Null

function Test-IsAdmin {
  ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Win11 { [int](Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 22000 }

function Get-StartupDir { [Environment]::GetFolderPath('Startup') }

function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
  Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type
}

function New-Shortcut([string]$Lnk, [string]$Target, [string]$Arguments = '', [string]$WorkDir = '', [int]$WindowStyle = 1) {
  $s = (New-Object -ComObject WScript.Shell).CreateShortcut($Lnk)
  $s.TargetPath = $Target; $s.Arguments = $Arguments; $s.WindowStyle = $WindowStyle
  $s.WorkingDirectory = $(if ($WorkDir) { $WorkDir } else { Split-Path $Target })
  $s.Save()
}

# Скачивание с повтором: Invoke-WebRequest (3 попытки) -> curl.exe -> BITS. Пустой или битый файл считается ошибкой.
function Invoke-Download([string]$Url, [string]$OutFile, [int]$Retries = 3, [long]$MinBytes = 1) {
  New-Item -ItemType Directory -Force (Split-Path $OutFile) | Out-Null
  $errs = @()
  for ($i = 1; $i -le $Retries; $i++) {
    try {
      Invoke-WebRequest $Url -OutFile $OutFile -UseBasicParsing -UserAgent $script:WczUA -TimeoutSec 300
      if ((Get-Item $OutFile).Length -ge $MinBytes) { return $OutFile }
      throw 'файл пустой'
    } catch { $errs += "попытка ${i}: $($_.Exception.Message)"; Start-Sleep -Seconds (3 * $i) }
  }
  $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
  if (Test-Path $curl) {
    $p = Start-Process $curl -ArgumentList '-fL', '--retry', '3', '--retry-delay', '3', '-s', '-A', $script:WczUA, '-o', "`"$OutFile`"", "`"$Url`"" -Wait -PassThru -WindowStyle Hidden
    if ($p.ExitCode -eq 0 -and (Test-Path $OutFile) -and (Get-Item $OutFile).Length -ge $MinBytes) { return $OutFile }
    $errs += "curl: код $($p.ExitCode)"
  }
  try {
    Import-Module BitsTransfer -ErrorAction Stop
    Start-BitsTransfer -Source $Url -Destination $OutFile -ErrorAction Stop
    if ((Get-Item $OutFile).Length -ge $MinBytes) { return $OutFile }
  } catch { $errs += "BITS: $($_.Exception.Message)" }
  Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
  throw "Не удалось скачать $Url. Проверь интернет или прокси. ($($errs -join ' | '))"
}

function Test-ZipFile([string]$Path) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  try { $z = [IO.Compression.ZipFile]::OpenRead($Path); $n = $z.Entries.Count; $z.Dispose(); return ($n -gt 0) } catch { return $false }
}

# Файл в кэше %TEMP%\win-customization: при повторном запуске не качается заново. -Zip проверяет целостность архива.
function Get-File([string]$Url, [string]$Name, [switch]$Zip) {
  $out = Join-Path $script:WczCache $Name
  if ((Test-Path $out) -and ((-not $Zip) -or (Test-ZipFile $out))) { return $out }
  for ($i = 1; $i -le 2; $i++) {
    Invoke-Download $Url $out | Out-Null
    if (-not $Zip -or (Test-ZipFile $out)) { return $out }
    Remove-Item $out -Force -ErrorAction SilentlyContinue
  }
  throw "Скачанный архив повреждён: $Url"
}

function Expand-Zip([string]$Zip, [string]$Dest) {
  New-Item -ItemType Directory -Force $Dest | Out-Null
  Expand-Archive -LiteralPath $Zip -DestinationPath $Dest -Force
  Get-ChildItem $Dest -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
}

# Ссылка на файл из последнего релиза GitHub. Сначала API, при лимите (60 запросов в час) или ошибке: страница релиза.
function Get-GitHubAssetUrl([string]$Repo, [string]$Pattern) {
  try {
    $rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing -UserAgent $script:WczUA -TimeoutSec 30
    $a = $rel.assets | Where-Object name -like $Pattern | Select-Object -First 1
    if ($a) { return $a.browser_download_url }
  } catch {}
  $r = Invoke-WebRequest "https://github.com/$Repo/releases/latest" -UseBasicParsing -UserAgent $script:WczUA -TimeoutSec 30
  # репозиторий мог переехать (GitHub перенаправляет): берём владельца и имя из итогового адреса
  $final = $r.BaseResponse.ResponseUri.AbsolutePath          # /owner/repo/releases/tag/v1.2.3
  $parts = $final.Trim('/').Split('/')
  $real = "$($parts[0])/$($parts[1])"; $tag = ($final -split '/tag/')[-1]
  $html = (Invoke-WebRequest "https://github.com/$real/releases/expanded_assets/$tag" -UseBasicParsing -UserAgent $script:WczUA -TimeoutSec 30).Content
  $rx = [regex]::Escape($Pattern).Replace('\*', '[^"/]*')
  $m = [regex]::Match($html, "href=""(/[^""/]+/[^""/]+/releases/download/[^""]+/$rx)""", 'IgnoreCase')
  if ($m.Success) { return "https://github.com$($m.Groups[1].Value)" }
  throw "Не нашёл файл $Pattern в последнем релизе $Repo"
}

# SHA-256, который GitHub публикует для файла релиза (поле digest). $null, если API недоступен.
function Get-GitHubAssetDigest([string]$Repo, [string]$Name) {
  try {
    $rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing -UserAgent $script:WczUA -TimeoutSec 30
    $a = $rel.assets | Where-Object name -eq $Name | Select-Object -First 1
    if ($a.digest -match '^sha256:([0-9a-f]{64})$') { return $Matches[1].ToUpper() }
  } catch {}
  return $null
}

# Неподписанный установщик с GitHub: сверяем SHA-256 с опубликованным; без API доверяем HTTPS-загрузке из официального релиза.
function Assert-GitHubAsset([string]$Path, [string]$Repo) {
  $want = Get-GitHubAssetDigest $Repo (Split-Path $Path -Leaf)
  if (-not $want) { "SHA-256 недоступен (лимит API), файл из официального релиза $Repo по HTTPS"; return }
  if ((Get-FileHash $Path -Algorithm SHA256).Hash -ne $want) {
    Remove-Item $Path -Force -ErrorAction SilentlyContinue
    throw "SHA-256 файла $(Split-Path $Path -Leaf) не совпадает с опубликованным на GitHub, файл удалён"
  }
  "SHA-256 совпадает с опубликованным на GitHub"
}

# Установщик .exe запускаем только с валидной подписью (опционально проверяем издателя).
function Assert-Signed([string]$Path, [string]$Publisher = '') {
  $sig = Get-AuthenticodeSignature $Path
  if ($sig.Status -ne 'Valid' -or ($Publisher -and $sig.SignerCertificate.Subject -notmatch [regex]::Escape($Publisher))) {
    Remove-Item $Path -Force -ErrorAction SilentlyContinue
    throw "Подпись файла $(Split-Path $Path -Leaf) не прошла проверку ($($sig.Status)), файл удалён"
  }
}

# Установщик работает с правами администратора, а программы трея должны жить с обычными правами (как при входе в Windows).
# runas /trustlevel запускает процесс без повышения; если не вышло, обычный запуск.
function Start-UserProcess([string]$Path, [string]$Arguments = '') {
  if (Test-IsAdmin) {
    $cmd = if ($Arguments) { "`"$Path`" $Arguments" } else { "`"$Path`"" }
    try {
      $p = Start-Process "$env:SystemRoot\System32\runas.exe" -ArgumentList "/trustlevel:0x20000 `"$($cmd.Replace('"', '\"'))`"" -WindowStyle Hidden -Wait -PassThru
      if ($p.ExitCode -eq 0) { return }
    } catch {}
  }
  if ($Arguments) { Start-Process $Path -ArgumentList $Arguments } else { Start-Process $Path }
}

function Wait-ProcessUp([string]$Name, [int]$Seconds = 15) {
  for ($i = 0; $i -lt $Seconds; $i++) { if (Get-Process $Name -ErrorAction SilentlyContinue) { return $true }; Start-Sleep 1 }
  return $false
}

# Перезапуск Проводника: Windows поднимает его сама; если нет, запускаем без повышения прав.
function Restart-Shell {
  Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
  if (-not (Wait-ProcessUp explorer 20)) { Start-UserProcess "$env:SystemRoot\explorer.exe"; [void](Wait-ProcessUp explorer 20) }
  Start-Sleep 3
}
