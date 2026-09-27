#!/usr/bin/env bash
# Fresh Linux box (cloud session): fetch Godot 4.7.2, import, run both suites.
# WITH_TEMPLATES=1 also fetches Windows export templates (~1 GB) for pack_windows.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER=4.7.2
GODOT="$HOME/tools/Godot_v${VER}-stable_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${VER}-stable"
mkdir -p "$HOME/tools"
if [[ ! -x "$GODOT" ]]; then
  curl -fsSL "$URL/Godot_v${VER}-stable_linux.x86_64.zip" -o /tmp/godot.zip
  python3 -c "import zipfile; zipfile.ZipFile('/tmp/godot.zip').extractall('$HOME/tools')"
  chmod +x "$GODOT"
fi
if [[ "${WITH_TEMPLATES:-0}" == 1 ]]; then
  T="$HOME/.local/share/godot/export_templates/${VER}.stable"
  if [[ ! -f "$T/windows_release_x86_64.exe" ]]; then
    mkdir -p "$T"
    curl -fsSL "$URL/Godot_v${VER}-stable_export_templates.tpz" -o /tmp/tpl.tpz
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/tpl.tpz').extractall('/tmp/tpl')"
    cp /tmp/tpl/templates/* "$T/"
  fi
fi
cd "$ROOT"
"$GODOT" --headless --path . --import --quit >/dev/null 2>&1 || true
"$GODOT" --headless --path . --script res://tests/smoke.gd 2>&1 | tail -1
"$GODOT" --headless --path . --script res://tests/rooms_boot.gd 2>&1 | tail -3
echo "GODOT=$GODOT"
