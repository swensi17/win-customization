# Show-Splash.ps1: заставка с логотипом Windows 7 и данными о системе.
# Вызывается из профиля PowerShell и из cmd (cmd-autorun.cmd). Работает только в интерактивной консоли.
param([string]$ShellName = "PowerShell $($PSVersionTable.PSVersion)")
if ($env:NO_SPLASH -or [Console]::IsOutputRedirected -or [Console]::IsInputRedirected) { return }
$e = [char]27
function C($r,$g,$b){ "$e[38;2;${r};${g};${b}m" }
$rs = "$e[0m"
$c1 = C 243 83 37; $c2 = C 128 188 0; $c3 = C 5 166 240; $c4 = C 255 186 8
$dim = C 120 130 145; $acc = C 23 147 209
  # static info cached for 7 days (CIM is slow)
  $cacheFile = Join-Path $env:LOCALAPPDATA 'splash-cache.json'
  $cache = $null
  if (Test-Path $cacheFile) { try { $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json } catch {} }
  if (-not $cache -or ((Get-Date) - [datetime]$cache.when).TotalDays -gt 7) {
    $os  = Get-CimInstance Win32_OperatingSystem
    $cache = [pscustomobject]@{
      when = (Get-Date).ToString('o')
      os   = ($os.Caption -replace 'Майкрософт ','' -replace 'Microsoft ','')
      cpu  = ((Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+',' ')
      gpu  = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    }
    try { $cache | ConvertTo-Json | Set-Content $cacheFile -Encoding UTF8 } catch {}
  }
  # optional demo mode (public screenshots): <папка профиля>\splash-demo.json -> {"user":"user","host":"pc","ip":"192.168.1.10"}
  $dUser = $env:USERNAME; $dHost = $env:COMPUTERNAME; $dIp = $null
  $demoFile = Join-Path (Split-Path $PROFILE) 'splash-demo.json'
  if (Test-Path $demoFile) { try { $dm = Get-Content $demoFile -Raw | ConvertFrom-Json; if ($dm.user) { $dUser = $dm.user }; if ($dm.host) { $dHost = $dm.host }; if ($dm.ip) { $dIp = $dm.ip } } catch {} }
  # fast dynamic info (no WMI)
  $ms = [Environment]::TickCount; if ($ms -lt 0) { $ms += 4294967296 }
  $up = [TimeSpan]::FromMilliseconds($ms)
  $ci = $null; try { Add-Type -AssemblyName Microsoft.VisualBasic; $ci = New-Object Microsoft.VisualBasic.Devices.ComputerInfo } catch {}
  if ($ci) { $ramT = [math]::Round($ci.TotalPhysicalMemory/1GB,1); $ramU = [math]::Round(($ci.TotalPhysicalMemory-$ci.AvailablePhysicalMemory)/1GB,1) } else { $ramT = '?'; $ramU = '?' }
  $dr = New-Object IO.DriveInfo 'C'; $dT = [math]::Round($dr.TotalSize/1GB); $dU = $dT - [math]::Round($dr.AvailableFreeSpace/1GB)
  $ip = $dIp
  if (-not $ip) { foreach ($n in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
    if ($n.OperationalStatus -eq 'Up' -and $n.NetworkInterfaceType -ne 'Loopback') {
      $a = $n.GetIPProperties().UnicastAddresses | Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
      if ($a) { $ip = $a.Address.ToString(); break }
    }
  } }
  $procs = [Diagnostics.Process]::GetProcesses().Count

  $logo = @(
    '{1}        ,.=:!!t3Z3z.,                ',
    '{1}       :tt:::tt333EE3                ',
    '{1}       Et:::ztt33EEEL{2} @Ee.,      ..,   ',
    '{1}      ;tt:::tt333EE7{2} ;EEEEEEttttt33#  ',
    '{1}     :Et:::zt333EEQ.{2} $EEEEEEttttt33QL ',
    '{1}     it::::tt333EEF{2} @EEEEEEttttt33F   ',
    '{1}    ;3=*^```"*4EEV{2} :EEEEEEttttt33@.   ',
    '{3}    ,.=::::it=., {1}`{2} @EEEEEEtttz33QF   ',
    '{3}   ;::::::::zt33){2}   "4EEEtttji3P*     ',
    '{3}  :t::::::::tt33.{4}:Z3z..{2}  ``{4} ,..g.    ',
    '{3}  i::::::::zt33F{4} AEEEtttt::::ztF      ',
    '{3} ;:::::::::t33V{4} ;EEEttttt::::t3       ',
    '{3} E::::::::zt33L{4} @EEEtttt::::z3F       ',
    '{3}{3=*^```"*4E3){4} ;EEEtttt:::::tZ`       ',
    '{3}             `{4} :EEEEtttt::::z7         ',
    '{4}                 "VEzjt:;;z>*`           '
  )
  $info = @(
    '', '',
    "$acc$dUser$rs$dim@$rs$acc$dHost$rs",
    '',
    "${acc}OS     $rs$($cache.os)",
    "${acc}Uptime $rs$('{0}d {1}h {2}m' -f $up.Days,$up.Hours,$up.Minutes)",
    "${acc}Shell  ${rs}$ShellName",
    "${acc}CPU    $rs$($cache.cpu)",
    "${acc}GPU    $rs$($cache.gpu)",
    "${acc}RAM    $rs$ramU / $ramT GB",
    "${acc}Disk C $rs$dU / $dT GB",
    "${acc}IP     $rs$ip",
    "${acc}Procs  $rs$procs",
    "${acc}Time   $rs$(Get-Date -Format 'dd.MM.yyyy HH:mm')",
    '',
    "$c1██$c2██$c3██$c4██$rs"
  )
  Write-Host ""
  for ($i=0; $i -lt $logo.Count; $i++) {
    $l = $logo[$i].Replace('{1}',$c1).Replace('{2}',$c2).Replace('{3}',$c3).Replace('{4}',$c4)
    $t = if ($i -lt $info.Count) { $info[$i] } else { '' }
    $raw = $logo[$i] -replace '\{[1-4]\}',''; $pad = ' ' * [math]::Max(0, 46 - $raw.Length); Write-Host ($l + $rs + $pad + '  ' + $t)
  }
  Write-Host ""
