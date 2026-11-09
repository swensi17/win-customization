# [AUTO] Консоль (conhost) и "терминал по умолчанию" = Windows Terminal.
$k = "HKCU:\Console"
$set = @{ WindowAlpha=215; FaceName="Consolas"; FontSize=0x00120000; FontFamily=54; FontWeight=400; CursorSize=25; QuickEdit=1; ForceV2=1; ScreenBufferSize=0x270f0078; WindowSize=0x001e0078 }
foreach ($n in $set.Keys) { Set-ItemProperty -Path $k -Name $n -Value $set[$n] -Type $(if ($set[$n] -is [string]) {'String'} else {'DWord'}) }
$colors = @{ ColorTable00=0x1e1e1e; ColorTable07=0xd4d4d4; ColorTable10=0x6fd36f; ColorTable11=0xf2c87a; ColorTable12=0x6b6bf0; ColorTable14=0x7ad9f0; ColorTable09=0xf2a85b }
foreach ($n in $colors.Keys) { Set-ItemProperty -Path $k -Name $n -Value $colors[$n] -Type DWord }
# Windows Terminal как терминал по умолчанию
$d = "HKCU:\Console\%%Startup"; New-Item -Path $d -Force | Out-Null
Set-ItemProperty -LiteralPath $d -Name DelegationConsole  -Value "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
Set-ItemProperty -LiteralPath $d -Name DelegationTerminal -Value "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"
"console defaults applied"