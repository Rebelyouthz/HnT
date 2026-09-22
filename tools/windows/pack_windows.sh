#!/usr/bin/env bash
# Export Godot 4.7.2 Standard Windows player + NSIS per-user Setup.exe
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/home/timmietooth/tools/Godot_v4.7.2-stable_linux.x86_64}"
NSISDIR="${NSISDIR:-$HOME/.local/nsis/usr/share/nsis}"
MAKENSIS="${MAKENSIS:-$HOME/.local/nsis/usr/bin/makensis}"
OUT="$ROOT/build/windows"
mkdir -p "$OUT"
python3 "$ROOT/tools/windows/make_icon.py"
"$GODOT" --headless --path "$ROOT" --import --quit
"$GODOT" --headless --path "$ROOT" --export-release "Windows Desktop" "$OUT/FatherAndSon.exe"
if [[ ! -f "$OUT/FatherAndSon.exe" ]]; then
  echo "export failed: $OUT/FatherAndSon.exe missing" >&2
  exit 1
fi
export NSISDIR
"$MAKENSIS" "$ROOT/tools/windows/FatherAndSon.nsi"
ls -lh "$OUT/FatherAndSon.exe" "$OUT/FatherAndSonSetup.exe"
