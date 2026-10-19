# Father & Son: remove every other copy of the game and every old setup file.
#   -Mode install    run by the new Setup.exe before it installs: old installs,
#                    old setups, zips and loose game copies go; the save stays.
#   -Mode uninstall  run by Uninstall.exe: everything above plus this install,
#                    shortcuts and the uninstall entry; -Saves also removes
#                    the save file.
#   -Keep <path>     never touched (the Setup.exe that is running right now).
#
# Never touches a developer copy: any folder at or above a candidate that holds
# project.godot, a .git folder or a .cursor folder is skipped (the Cursor /
# Claude working copy of the game stays exactly as it is).
param(
	[string]$Mode = "install",
	[string]$Keep = "",
	[switch]$Saves
)
$ErrorActionPreference = "SilentlyContinue"

function Norm([string]$p) {
	if ($p -eq "") { return "" }
	try { return [System.IO.Path]::GetFullPath($p).TrimEnd('\').ToLowerInvariant() } catch { return $p.ToLowerInvariant() }
}
$keepN = Norm $Keep
$here = Norm $PSScriptRoot

# A developer working copy somewhere at or above this path?
function Is-DevCopy([string]$path) {
	$d = $path
	if (Test-Path -LiteralPath $d -PathType Leaf) { $d = Split-Path -Parent $d }
	for ($i = 0; $i -lt 6 -and $d; $i++) {
		if ((Test-Path -LiteralPath (Join-Path $d "project.godot")) -or
			(Test-Path -LiteralPath (Join-Path $d ".git")) -or
			(Test-Path -LiteralPath (Join-Path $d ".cursor"))) { return $true }
		$d = Split-Path -Parent $d
	}
	return $false
}

function Remove-Safe([string]$path) {
	$n = Norm $path
	if ($n -eq "" -or $n -eq $keepN) { return }
	if ($keepN -ne "" -and $keepN.StartsWith($n + "\")) { return }
	if (Is-DevCopy $path) { return }
	Remove-Item -LiteralPath $path -Recurse -Force
}

# 1. Close the game if it is running (files in use cannot be removed).
Get-Process -Name "FatherAndSon" | Stop-Process -Force
Start-Sleep -Milliseconds 400

# 2. Old installs in every place a version of the setup ever used.
$installs = @(
	(Join-Path $env:LOCALAPPDATA "FatherAndSon"),
	(Join-Path $env:LOCALAPPDATA "Programs\FatherAndSon"),
	(Join-Path $env:LOCALAPPDATA "Programs\Father & Son"),
	(Join-Path $env:ProgramFiles "FatherAndSon"),
	(Join-Path $env:ProgramFiles "Father & Son"),
	(Join-Path ${env:ProgramFiles(x86)} "FatherAndSon"),
	(Join-Path ${env:ProgramFiles(x86)} "Father & Son")
)
foreach ($dir in $installs) {
	if (-not (Test-Path -LiteralPath $dir)) { continue }
	# The uninstaller runs from a temp copy; its own install dir goes at the end
	# of the NSIS section, so here every install dir can go.
	if ((Norm $dir) -eq $here) { continue }
	Remove-Safe $dir
}

# 3. Old setups, zips and loose copies in the user's folders.
$roots = @(
	(Join-Path $env:USERPROFILE "Downloads"),
	(Join-Path $env:USERPROFILE "Desktop"),
	(Join-Path $env:USERPROFILE "Documents"),
	(Join-Path $env:USERPROFILE "OneDrive\Desktop"),
	(Join-Path $env:USERPROFILE "OneDrive\Skrivbord"),
	(Join-Path $env:USERPROFILE "OneDrive\Documents"),
	(Join-Path $env:USERPROFILE "OneDrive\Dokument"),
	[Environment]::GetFolderPath("Desktop"),
	$env:TEMP
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
$patterns = @("FatherAndSonSetup*.exe", "FatherAndSon*.zip", "FatherAndSon*.7z",
	"Father*Son*Setup*.exe", "FatherAndSon.exe", "FatherAndSon.pck", "FatherAndSon.console.exe")
foreach ($root in $roots) {
	foreach ($pat in $patterns) {
		Get-ChildItem -LiteralPath $root -Filter $pat -File -Recurse -Depth 3 -Force | ForEach-Object {
			$f = $_.FullName
			# A loose FatherAndSon.exe takes its folder with it when that folder
			# is just the unpacked game (no project, nothing else of the user's).
			if ($_.Name -ieq "FatherAndSon.exe" -and $_.Directory.Name -like "FatherAndSon*") {
				Remove-Safe $_.Directory.FullName
			} else {
				Remove-Safe $f
			}
		}
	}
	Get-ChildItem -LiteralPath $root -Directory -Recurse -Depth 2 -Force |
		Where-Object { $_.Name -like "FatherAndSon*" -and (Test-Path -LiteralPath (Join-Path $_.FullName "FatherAndSon*.exe")) } |
		ForEach-Object { Remove-Safe $_.FullName }
}

# 4. Old shortcuts (the new install makes fresh ones).
$links = @(
	[Environment]::GetFolderPath("Desktop"),
	(Join-Path $env:USERPROFILE "OneDrive\Desktop"),
	(Join-Path $env:USERPROFILE "OneDrive\Skrivbord")
)
foreach ($l in $links) {
	if ($l -and (Test-Path -LiteralPath $l)) {
		Get-ChildItem -LiteralPath $l -Filter "Father*Son*.lnk" -File | Remove-Item -Force
	}
}
Remove-Item -LiteralPath (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Father & Son") -Recurse -Force

if ($Mode -eq "uninstall") {
	Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" -Recurse -Force
	netsh advfirewall firewall delete rule name="Father and Son" | Out-Null
	if ($Saves) {
		# Godot keeps the save under app_userdata\<project name>.
		Remove-Item -LiteralPath (Join-Path $env:APPDATA "Godot\app_userdata\HnT") -Recurse -Force
	}
}
exit 0
