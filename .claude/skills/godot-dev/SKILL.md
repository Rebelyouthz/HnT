---
name: godot-dev
description: Working on this Godot 4.7 project (Father & Son) - running, testing, screenshotting, recording and exporting it headless, and the engine pitfalls this codebase has already hit. Use before changing any .gd/.gdshader/.tscn file, adding assets or class_names, or building the Windows installer.
---

# Godot development in this repo

Godot binary: `~/tools/Godot_v4.7.2-stable_linux.x86_64` (call it `$G`).

## Loop for every change
1. New files, new `class_name`, new PNG/JSON assets -> re-import first:
   `$G --headless --path . --import --quit`
2. Smoke test (must print `SMOKE OK`): `$G --headless --path . --script res://tests/smoke.gd`
   It checks exact counts (encounters per map, cbt entries) and some literal
   strings in UI scripts (e.g. "TABLE" in run_hud.gd). If you change those on
   purpose, update `tests/smoke.gd` in the same commit.
3. Combat timing: `$G --headless --path . --script res://tools/combo_test.gd -- son|father`
   Must be 7/7 and 10/10. Run **headless** - under xvfb the slow software
   renderer produces false misses.
4. Look at it: screenshot with
   `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --resolution 1920x1080 --windowed --script res://tools/capture.gd -- <target> out.png <frames>`
   Targets: `title`, `title:play`, `hub:<tab>`, `camp`, `camp:<room>`,
   `ui:pause|cart|cartworld|quest`, `tower:<map>[@summit]`, `<map_id>`.
5. Feel it: record gameplay with
   `--write-movie f.avi --fixed-fps 30 --script res://tools/autoplay.gd -- <map> - <ticks>`
   and cut frames with the imageio ffmpeg binary
   (`python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"`).
   Never commit videos; keep them in the scratchpad.

## Pitfalls already paid for
- `AtlasTexture.get_image()` returns only the region, without margins. Add
  `margin.position` and centre on `tex.get_size()` when measuring a frame.
- `get_meta(key, null)` errors - always give a real default.
- Tool scripts (`extends SceneTree`) cannot reference class_names that depend
  on autoloads; use `has_method()` or `load()`.
- Controls created in code and anchored FULL_RECT before their parent is laid
  out may get size 0 - give overlays an explicit `position`/`size`.
- A ScrollContainer child VBox needs `SIZE_EXPAND_FILL` or rows stay narrow.
- Hitstop lowers `Engine.time_scale`; anything that must run during it uses
  `create_timer(t, true, false, true)` / `set_ignore_time_scale(true)`.
  Effects that *should* freeze with the hit (camera kick, squash) use plain
  scaled delta.
- Never `git checkout` a file with uncommitted work you need: copy it first.

## 60 fps
Physics runs at 60 ticks; rendering is capped to 60 (`Gfx` default
`fps_cap` 60, `application/run/max_fps=60`) so movement written in
`_physics_process` does not judder on 120 Hz screens like the ROG Ally.

## Windows build
`GODOT=$G NSISDIR=/usr/share/nsis MAKENSIS=/usr/bin/makensis bash tools/windows/pack_windows.sh`
-> `build/windows/FatherAndSon.exe` + `FatherAndSonSetup.exe`, checked by
`tests/export_pack.gd` (`EXPORT_PACK_OK`). Delivery goes on the
`windows-installer` branch as three `split -b 81788928` parts + `JOIN.bat`.
