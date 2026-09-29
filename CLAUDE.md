# HnT — Father & Son

Godot 4.7.2 (Standard, not .NET) GDScript brawler. See README.md for the game.

## First thing in a fresh/cloud session
    bash tools/cloud_setup.sh
Downloads Godot to ~/tools, imports, runs both suites. Expect `SMOKE OK` and
`ROOMS_BOOT_OK / ROOMS_HTTP_OK / ROOMS_RELAY_OK`. Run it again after any change.

## Windows Setup
    WITH_TEMPLATES=1 bash tools/cloud_setup.sh
    bash tools/windows/pack_windows.sh   # needs makensis (apt install nsis; MAKENSIS=makensis NSISDIR=/usr/share/nsis)
pack_windows.sh boots the shipped exe (tests/export_pack.gd) and fails if art is missing.

## Web / phone (PWA)
    bash tools/web/pack_web.sh   # build/web/ + build/FatherAndSonWeb.zip (upload to itch.io or any HTTPS host)
Single-threaded Web export, so no COOP/COEP headers are needed. Host/Join rooms do not run in a browser.

## Art pipeline (read docs/HANDOFF_PIXEL_PIPELINE.md first)
canvas_items stretch, 1.5x couch camera, 4.5 texels per world unit (1:1 on 1080p).
    pip install pillow numpy scipy
    python3 tools/slice_sprites.py all        # boards -> packed sheets + JSON
    python3 tools/backdrop.py in.png assets/backdrops/<theme>.png
    blender -b -P tools/render3d.py -- model.glb out/ --dirs 8   # 3D -> sprites + normals
Screenshots at 1080p: tools/capture.gd under xvfb (see the handoff).

## Rules
- Load res:// assets with `ResourceLoader.exists` / `load`, never `FileAccess` —
  imported files are invisible to FileAccess in an export (the 0.1.0 Setup shipped blank sprites).
- World sprites: `SpriteBook.DRAW_SCALE` + `SpriteBook.world_filter()`. HUD layers via
  `PixelStage.attach_canvas`. No opaque full-map rects in the world canvas.
- Remote `github` = GitHub (Rebelyouthz/HnT). `origin` = Cursor.
