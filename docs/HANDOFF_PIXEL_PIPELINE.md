# Handoff: pixel pipeline rebuild (read before touching art, camera or HUD)

Branch `claude/gallant-galileo-5ctrmf` changed how every sprite is cut, stored
and drawn. This note says what was wrong, what replaced it, and the rules that
keep it right. `.cursor/skills/pixel-perfect-2d/SKILL.md` is updated to match;
the old version of that skill describes the broken setup.

## What was wrong (and why nobody saw it)

The source boards in `tools/sprite_src/` are good: the Father is ~250 px tall
on his board. In game he was ~45 px, soft, with pink fringes. Three stacked
losses, none visible in the editor at a glance:

1. **Nearest downscale in the slicer.** `fit_feet` shrank a ~250 px figure to
   ~90 px with `Image.NEAREST`: every other source pixel was simply dropped.
2. **Per-frame fit.** Every frame was scaled to fill the 96 px cell on its own,
   so a crouch was drawn bigger than a stance, a kick smaller than an idle.
   Clips "breathed" and popped between each other; bosses were the same
   height as imps.
3. **`stretch/mode = "viewport"` at 640x360 + `DRAW_SCALE 0.5`.** The whole
   game rendered into a 640x360 texture, so a 96 px cel drawn at 0.5 was
   sampled at 48 px (nearest drops half again) and then blown up 3x. UI text
   at font size 14 x 0.5 was rasterised at 7 px and blown up too — that is
   why menus looked blurry.

Also found:
- Chroma key was a hard colour-distance cut, so anti-aliased pink stayed on
  every outline, and walk boards swallowed stray attack poses (the cop's
  baton swing sat inside his walk loop).
- Some boards are 4x4 or 3x4; the old slicer forced 4x3 and cut figures in half.
- 13 of 14 levels drew an opaque full-map "sky" rect at z -8 **in the world
  canvas**, which covers the whole `ParallaxBackground` (a CanvasLayer below
  the world). Every parallax skyline ever built was invisible.
- `CanvasModulate` `Palette.NIGHT` was (0.22, 0.25, 0.38): everything at ~25%.
- `MissionHud` added its panel straight to the CanvasLayer, not through
  `PixelStage.attach_canvas`, so it drew at 2x over the top-right corner.
- Run HUD: the two-line name label sat on top of the HP pips and steam bar;
  the boss name sat on the LIVES line.
- Only Dock Street and Intake Lot use any tile art. The other 12 maps are
  Blockout rectangles (see "Still to do").

## What replaced it

### Rendering
- `project.godot`: `stretch/mode = "canvas_items"`, base 640x360,
  `scale_mode = "fractional"`, `window/size/mode = 3` (fullscreen),
  window override 1280x720 for windowed. The world and UI are rendered at
  window resolution; logical coordinates did not change.
- `Boot`: F11 / Alt+Enter toggles fullscreen.
- `CouchCamera.ZOOM = 1.5`. The street band (y 430-520) fills ~38% of the
  frame; bodies read ~200 px on 1080p. `half` view and the leash divide by
  zoom. Camera y is `clamp(mid.y - 30, 190, 425)`.
- `SpriteBook.DRAW_SCALE = 1/4.5`: **4.5 texels per world unit**. Under the
  1.5x camera on a 1080p window (3x of 640x360) that is exactly one texel per
  screen pixel.
- `SpriteBook.world_filter()`: nearest when the window scale is a multiple
  of 3 (1080p, 4K), trilinear with mipmaps otherwise. Use it for every
  world sprite. UI portraits use `SpriteBook.UI_FILTER`. Sprite `.import`
  files have `mipmaps/generate=true`.

### Sizes (world units stay as before; only texel density changed)
| Thing | Cell | World |
| --- | --- | --- |
| Actor | >= 288 px (per-character, fits every clip) | standing body 198 px = 44 u |
| Prop / pickup / living prop | 216 px | 48 u |
| Tile | 144 px | 32 u |
| Hub icon | 128 px | UI |

`attach_scaled(host, who, y, scl)` still takes the old 96-px-era scale; it
converts with `LEGACY_CELL / CELL`.

### Sprite files
`assets/sprites/<who>/<clip>.png` is one **packed sheet** per clip and
`<clip>.json` holds `{"cell": [w, h], "frames": [{x, y, w, h, ox, oy}]}`.
`SpriteBook.frames(who)` builds `AtlasTexture`s with `margin` so every frame
is the full cell while memory holds only trimmed pixels. There are no
`<clip>/00.png` folders any more. Portraits: `SpriteBook.face(who)`.
`has_who` checks `<who>/idle.json` (or `dog.json`). Tests use
`_min_cels` / `_cel_diff` through SpriteBook.

### Slicer (`python3 tools/slice_sprites.py all`)
Needs Pillow, numpy, scipy (`pip install pillow numpy scipy`). Per board:
1. Figures: an even grid of dark rules when present (`_regular` only accepts
   lines at i*extent/k, so lamp posts and car shadows are not rules), else
   connected ink with small parts glued to their owner and stacked figures
   split at valleys, else the stated `GRID` table.
2. Key per figure: board colour from the figure's own border, border flood +
   enclosed pockets, vignette rims, board-hued blobs on the outside peeled,
   edge ring recoloured from the interior (no pink survives).
3. One body size per character: base scale from idle height, each board
   corrected by body **area** (boards were drawn at different zooms; area
   is pose-invariant).
4. Feet on one baseline; x registered by mask overlap against idle frame 0.
5. Premultiplied Lanczos + hard alpha threshold.
6. Loops drop stray poses (width outliers) and ping-pong under 6 frames.

After slicing: run a Godot import, then set `mipmaps/generate=true` in
`assets/sprites/**/*.png.import`, import again, then the tests.

### Backdrops
`tools/backdrop.py in.png assets/backdrops/<theme>.png --ground 0.855`
finds the pseudo-pixel grid of a generated painting (Fourier comb over edge
energy), takes the median of each block and writes the native-resolution
texture + `<theme>.json` (`ground` = kerb row in texels).
`NightStreet.parallax()` adds it as a mirrored `ParallaxLayer` (motion
0.9, 1.0) at `BACKDROP_TEXEL = 4/3` world units per texel = 6 screen px on
1080p, ground row on the kerb (y 430). Dock Street has one; the tile
tenement patches are skipped when a backdrop exists.

### 3D -> sprite (the plan for new characters and animation)
`tools/render3d.py` (Blender 4.5, headless, CPU): renders a rigged, animated
model orthographic, no anti-aliasing, 8 directions, every frame, as flat
albedo + a screen-space normal map (right, up, out). This is the Dead Cells
pipeline: the game lights the sprite with `CanvasTexture` normal maps and
the existing 2D lights. Verified on a test model: 8 dirs x 25 frames in 10 s.
Models come from image-to-3D (Hugging Face) + Mixamo rig/animations.

### Tools
- `tools/capture.gd`: real-renderer screenshots.
  `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --windowed --script res://tools/capture.gd -- dock_street out.png 240 walk`
  Look at the game at 1080p before calling anything pixel-perfect.
- `tools/web/pack_web.sh`: single-threaded Web/PWA export + itch.io zip.

## Rules that keep it right
- Never resize art with NEAREST to a non-integer factor. Downscale with the
  slicer; upscale only by whole numbers at draw time.
- One scale per character across all clips. Never fit frames individually.
- Never put an opaque full-map rect in the world canvas behind the level;
  backgrounds belong in `NightStreet.parallax`.
- New HUD/UI layers go through `PixelStage.attach_canvas` (design space 1280x720).
- New world sprites: `DRAW_SCALE` + `SpriteBook.world_filter()`.
- Check with `tools/capture.gd` at 1920x1080, not the editor viewport.

## Still to do
- Painted backdrops for the 12 Blockout maps (same pipeline as Dock Street).
- Characters via 3D -> sprite with normal-mapped lighting; bosses without
  sprite sets.
- Hub: profile box overlaps the "THE BASEMENT CLINIC" title; saved numbers
  come back as floats ("GOLD 40.0").

## Video -> sprite moves (Father done, 19 clips)

The old boards have good poses in the wrong order, so they animate badly.
Each move is now generated as a video and cut into a sheet:

1. `tools/videogen/father_spec.py`: per clip a start key pose, an end key
   pose (the peak: fist out, leg extended) and a prompt. Start = guard for
   strikes; the video model draws the in-betweens.
2. `python3 tools/videogen/keys_build.py father_spec father` places both keys
   on a white 1280x720 frame at one body scale.
3. `python3 tools/videogen/run_batch.py father_spec father` runs Wan 2.2
   I2V A14B on Hugging Face Inference Providers (fal-ai, `end_image_url` for
   the end key; 33 frames for strikes, 81 for loops; `HF_TOKEN` env).
4. `tools/video2sprite.py` per clip: keys every frame once (cached as
   `<video>.keyed.npz`), greys magenta spill, scales against `idle.json`
   by body area (one size for every clip), and writes the sheet. Strikes use
   `--start/--end` (guard -> peak), `--hold N` (impact hold), `--retract N`
   (the extension played back, eased) and store `"hit"` = the peak frame.
   Airborne clips use `--anchor center`. Exact cuts used are in the commit.
5. QA: strip of every frame, then `tools/capture_moves.gd` records the
   Father in game (combo | whiff | kicks | jump | run) frame by frame.

## Move system (`src/combat/move_book.gd` + `Fighter`)

- Hitboxes open on the sprite's `hit` frame (`SpriteBook.clip_info`), not on
  the button press. Wind-up is capped per move; the art is sped up to land
  on the contact tick. Clips without `hit` (Son, old boards) keep the old
  near-instant timing.
- Feet are planted during a strike (`plant`), the body steps in (`lunge`),
  no turning mid-swing.
- Stances: every strike ends in a body position (`lead_out`, `rear_out`,
  `low`, `rising`, `kick`, `spun`, plus `run`/`air` from movement). The next
  strike from a live stance skips the wind-up the body already did
  (`ENTRY`), and the same button picks a different move from a different
  stance (low + light -> uppercut, kick stance + light -> front kick,
  sprint + heavy -> running front kick).
- Hit: hitstop holds the extension frame, camera kick, `Juice.impact` star
  + ring + debris, push-off, fast retract, early cancel, long chain window,
  grade shout and impact sound only now.
- Miss: whoosh only, `Juice.whiff` smear, the weight carries forward
  (drift), slow retract, longer recovery, short chain window; a missed
  haymaker/roundhouse stumbles and drops the string.
- Physics-driven clips: walk/run play at foot speed, the jump clip is
  scrubbed by vertical velocity (rise -> flip at apex -> reach down), a
  landing crouch scales with fall speed. Full jumps no longer count as
  fall damage (they land at JUMP*sqrt(FALL_MUL), above the old threshold).
- `SpriteBook` pads every clip of a character into one shared canvas (same
  floor row, same centre), so wider kick cells never shift the body.

Next: Son (same spec format), then enemies.
