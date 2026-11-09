# --- Windows 7 splash + prompt (git, duration, status) + PSReadLine ---
$e = [char]27
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) { Clear-Host }
if ($Host.Name -eq 'ConsoleHost' -and -not $env:NO_SPLASH) { & (Join-Path (Split-Path $PROFILE) 'Show-Splash.ps1') }

# PSReadLine: подсветка синтаксиса и серые подсказки из истории (нужна версия 2.1+)
if (Get-Module PSReadLine) {
  $c = { param($r,$g,$b) "$e[38;2;${r};${g};${b}m" }
  $colors = @{
    Command = (& $c 122 162 247); Parameter = (& $c 187 154 247); String = (& $c 158 206 106)
    Variable = (& $c 224 175 104); Number = (& $c 255 158 100); Operator = (& $c 137 221 255)
    Comment = (& $c 86 95 137); Keyword = (& $c 187 154 247); Member = (& $c 125 207 255)
  }
  if ((Get-Module PSReadLine).Version -ge [version]'2.1.0') {
    $colors.InlinePrediction = (& $c 86 95 137)
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
  }
  Set-PSReadLineOption -Colors $colors -BellStyle None -HistoryNoDuplicates
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
  Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar     # принять подсказку посимвольно / до конца строки
}

# текущая ветка git без запуска git.exe (быстро): ищем .git вверх по дереву
function Get-PromptGitBranch {
  $d = (Get-Location).ProviderPath
  while ($d) {
    $g = Join-Path $d '.git'
    if (Test-Path -LiteralPath $g -PathType Container) { $head = Join-Path $g 'HEAD'; break }
    if (Test-Path -LiteralPath $g -PathType Leaf) {
      $gd = ((Get-Content -LiteralPath $g -TotalCount 1) -replace '^gitdir:\s*','').Trim()
      if (-not [IO.Path]::IsPathRooted($gd)) { $gd = Join-Path $d $gd }
      $head = Join-Path $gd 'HEAD'; break
    }
    $p = Split-Path $d -Parent; if (-not $p -or $p -eq $d) { return $null }; $d = $p
  }
  if (-not $head -or -not (Test-Path -LiteralPath $head)) { return $null }
  $h = Get-Content -LiteralPath $head -TotalCount 1
  if ($h -match '^ref: refs/heads/(.+)$') { return $Matches[1] }
  return $h.Substring(0, [math]::Min(7, $h.Length))
}

function prompt {
  $ok = $?                                              # должно быть первой строкой
  $blue = "$e[38;2;23;147;209m"; $purple = "$e[38;2;187;154;247m"; $yellow = "$e[38;2;224;175;104m"
  $green = "$e[38;2;158;206;106m"; $red = "$e[38;2;247;118;142m"; $dim = "$e[38;2;86;95;137m"; $rs = "$e[0m"
  $loc = (Get-Location).Path -replace [regex]::Escape($HOME),'~'
  $parts = $loc -split '\\'
  if ($parts.Count -gt 4) { $loc = '…\' + ($parts[-3..-1] -join '\') }      # длинный путь: только последние 3 папки
  $out = "$blue$loc$rs"
  $branch = Get-PromptGitBranch
  if ($branch) { $out += " $purple$([char]0xE0A0) $branch$rs" }
  $last = Get-History -Count 1
  if ($last) {
    $sec = ($last.EndExecutionTime - $last.StartExecutionTime).TotalSeconds
    if ($sec -ge 0.5) { $t = if ($sec -ge 60) { '{0}m{1:00}s' -f [int][math]::Floor($sec/60), [int]($sec%60) } else { '{0:0.0}s' -f $sec }; $out += " $yellow$([char]0xF017) $t$rs" }
  }
  $arrow = if ($ok) { "$green❯$rs" } else { "$red❯$rs" }
  "$out $arrow "
}