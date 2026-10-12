#!/usr/bin/env bash
# Export the Web/PWA build (single-threaded, no COOP/COEP headers needed) + a zip for itch.io.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-$HOME/tools/Godot_v4.7.2-stable_linux.x86_64}"
OUT="$ROOT/build/web"
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT" --import --quit
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"
if [[ ! -f "$OUT/index.pck" ]]; then
  echo "export failed: $OUT/index.pck missing" >&2
  exit 1
fi
(cd "$OUT" && python3 -c "import zipfile,os; z=zipfile.ZipFile('../FatherAndSonWeb.zip','w',zipfile.ZIP_DEFLATED); [z.write(f) for f in sorted(os.listdir('.'))]")
ls -lh "$ROOT/build/FatherAndSonWeb.zip"
