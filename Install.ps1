# One-command install (PowerShell; asks for administrator rights itself):
#   irm https://raw.githubusercontent.com/swensi17/win-customization/main/Install.ps1 | iex
# Downloads the latest repo to C:\win-customization and runs scripts\Install-Auto.ps1.
# The file is ASCII only and has no BOM: a BOM breaks 'irm | iex', and non-ASCII text breaks old consoles.
& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  try { Set-ExecutionPolicy -Scope Process Bypass -Force } catch {}
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
  try { [Net.WebRequest]::DefaultWebProxy.Credentials = [Net.CredentialCache]::DefaultNetworkCredentials } catch {}

  if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Host "PowerShell 5.1 is required (Windows Management Framework 5.1)" -ForegroundColor Red; return }
  if (-not [Environment]::Is64BitOperatingSystem) { Write-Host "64-bit Windows is required" -ForegroundColor Red; return }

  $dst = 'C:\win-customization'
  $url = 'https://github.com/swensi17/win-customization/archive/refs/heads/main.zip'
  $zip = Join-Path $env:TEMP 'win-customization-main.zip'

  if (Test-Path "$dst\.git") {
    Write-Host "$dst is a git repository, using it as is" -ForegroundColor Yellow
  } else {
    Write-Host "Downloading win-customization..." -ForegroundColor Cyan
    $ok = $false
    for ($i = 1; $i -le 3 -and -not $ok; $i++) {
      try { Invoke-WebRequest $url -OutFile $zip -UseBasicParsing -TimeoutSec 120; $ok = $true } catch { Start-Sleep -Seconds (3 * $i) }
    }
    if (-not $ok -and (Test-Path "$env:SystemRoot\System32\curl.exe")) {
      & "$env:SystemRoot\System32\curl.exe" -fsL --retry 3 -o $zip $url; $ok = ($LASTEXITCODE -eq 0)
    }
    if (-not $ok) { Write-Host "Download failed. Check the internet connection, proxy or VPN." -ForegroundColor Red; return }
    $tmp = Join-Path $env:TEMP 'win-customization-src'
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    try { Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force } catch { Write-Host "The archive is corrupted, run the command again." -ForegroundColor Red; return }
    $src = Get-ChildItem $tmp -Directory | Select-Object -First 1
    New-Item -ItemType Directory -Force $dst | Out-Null
    Copy-Item "$($src.FullName)\*" $dst -Recurse -Force
  }
  Get-ChildItem $dst -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

  # separate process: the installer picks 64-bit PowerShell 5.1 and asks for administrator rights
  $ps = Join-Path $env:SystemRoot $(if (-not [Environment]::Is64BitProcess) { 'Sysnative' } else { 'System32' })
  & (Join-Path $ps 'WindowsPowerShell\v1.0\powershell.exe') -NoProfile -ExecutionPolicy Bypass -File "$dst\scripts\Install-Auto.ps1"
}
