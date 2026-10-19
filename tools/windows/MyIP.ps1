# Father & Son - Min IP for onlinespel. Visar numret sonen laser upp for pappa.
Add-Type -AssemblyName PresentationFramework
$lan = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' -and $_.InterfaceAlias -notmatch 'vEthernet|VirtualBox|VMware|Loopback|Bluetooth' } |
  Select-Object -ExpandProperty IPAddress)
if ($lan.Count -eq 0) { $lanText = '(hittar inget natverk)' } else { $lanText = $lan -join '   eller   ' }
try { $wan = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 6).ToString().Trim() } catch { $wan = '(ingen internetkontakt just nu)' }
$msg = @"
SPELA ONLINE MED PAPPA

Samma hus / samma wifi:
      $lanText
   (Pappa kan bara trycka FIND MY SON - inga siffror behovs.)

Pappa i ett ANNAT hus - las upp det har numret:
      $wan

I spelet: PLAY ONLINE  ->  SON - PLAY WITH DAD.
Pappa: PLAY ONLINE  ->  DAD - FIND MY SON  (eller skriv numret).
"@
[System.Windows.MessageBox]::Show($msg, 'Father & Son - Min IP', 'OK', 'Information') | Out-Null
