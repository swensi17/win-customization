# SysMonTray: один значок в трее с нагрузкой ПК (0-100). Левый клик: процессор <-> память.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class SysNative {
  [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern bool DestroyIcon(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct MEMORYSTATUSEX { public uint dwLength; public uint dwMemoryLoad; public ulong ullTotalPhys; public ulong ullAvailPhys; public ulong ullTotalPageFile; public ulong ullAvailPageFile; public ulong ullTotalVirtual; public ulong ullAvailVirtual; public ulong ullAvailExtendedVirtual; }
  [DllImport("kernel32.dll")] public static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX m);
}
"@

$mutex = New-Object System.Threading.Mutex($false, 'Global\SysMonTray_instance')
if (-not $mutex.WaitOne(0)) { exit }

$cpuCounter = New-Object System.Diagnostics.PerformanceCounter('Processor', '% Processor Time', '_Total')
[void]$cpuCounter.NextValue()
$script:mode = 'ram'     # ram | cpu
function Log($m) { try { Add-Content -Path (Join-Path $PSScriptRoot 'sysmon.log') -Value ("{0:HH:mm:ss} {1}" -f (Get-Date), $m) } catch {} }

function Get-LoadColor([int]$v) {
  if ($v -ge 90) { return [System.Drawing.Color]::FromArgb(255,105,97) }
  if ($v -ge 75) { return [System.Drawing.Color]::FromArgb(255,204,0) }
  return [System.Drawing.Color]::FromArgb(255,255,255)
}

function New-LoadIcon([int]$value) {
  $bmp = New-Object System.Drawing.Bitmap 32, 32
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $text = "$([math]::Min($value,100))"
  $sf = New-Object System.Drawing.StringFormat([System.Drawing.StringFormat]::GenericTypographic)
  $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'; $sf.FormatFlags = $sf.FormatFlags -bor [System.Drawing.StringFormatFlags]::NoWrap
  $brush = New-Object System.Drawing.SolidBrush (Get-LoadColor $value)
  $px = 30; $font = $null
  while ($px -ge 12) {                       # самый крупный шрифт, при котором число помещается
    $font = New-Object System.Drawing.Font('Segoe UI Semibold', $px, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $m = $g.MeasureString($text, $font, 200, $sf)
    if ($m.Width -le 31 -and $m.Height -le 32) { break }
    $font.Dispose(); $px--
  }
  $g.DrawString($text, $font, $brush, (New-Object System.Drawing.RectangleF(0, 0, 32, 32)), $sf)
  $g.Dispose(); $font.Dispose(); $brush.Dispose()
  $h = $bmp.GetHicon(); $bmp.Dispose()
  return $h
}
$ni = New-Object System.Windows.Forms.NotifyIcon
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$miCpu = $menu.Items.Add('Показывать CPU'); $miRam = $menu.Items.Add('Показывать RAM'); [void]$menu.Items.Add('-')
$miExit = $menu.Items.Add('Выход')
$miCpu.Add_Click({ try { $script:mode = 'cpu'; Log 'menu cpu'; Update-Icon } catch { Log ("ERR menu cpu: " + $_.Exception.Message) } })
$miRam.Add_Click({ try { $script:mode = 'ram'; Log 'menu ram'; Update-Icon } catch { Log ("ERR menu ram: " + $_.Exception.Message) } })
$miExit.Add_Click({ $timer.Stop(); $ni.Visible = $false; $ni.Dispose(); [System.Windows.Forms.Application]::Exit() })
$ni.ContextMenuStrip = $menu
$ni.Add_MouseClick({ param($s, $e) try { Log ("click " + $e.Button); if ($e.Button -eq 'Left') { $script:mode = if ($script:mode -eq 'cpu') { 'ram' } else { 'cpu' }; Update-Icon } } catch { Log ("ERR click: " + $_.Exception.Message) } })
$script:hIcon = [IntPtr]::Zero

function Update-Icon {
  $cpu = [int][math]::Round([math]::Min(100, $cpuCounter.NextValue()))
  $m = New-Object SysNative+MEMORYSTATUSEX; $m.dwLength = [System.Runtime.InteropServices.Marshal]::SizeOf($m)
  [void][SysNative]::GlobalMemoryStatusEx([ref]$m)
  $ram = [int]$m.dwMemoryLoad
  $usedGb = [math]::Round(($m.ullTotalPhys - $m.ullAvailPhys) / 1GB, 1); $totGb = [math]::Round($m.ullTotalPhys / 1GB, 1)
  if ($script:mode -eq 'cpu') { $val = $cpu } else { $val = $ram }
  $new = New-LoadIcon $val
  $ni.Icon = [System.Drawing.Icon]::FromHandle($new)
  if ($script:hIcon -ne [IntPtr]::Zero) { [void][SysNative]::DestroyIcon($script:hIcon) }
  $script:hIcon = $new
  $tip = "RAM: $ram/100 ($usedGb/$totGb ГБ)`nCPU: $cpu/100"; if ($tip.Length -gt 63) { $tip = $tip.Substring(0, 63) }; $ni.Text = $tip
}

Update-Icon
$ni.Visible = $true
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Update-Icon })
$timer.Start()
[System.Windows.Forms.Application]::Run()