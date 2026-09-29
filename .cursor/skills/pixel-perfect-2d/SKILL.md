---
name: pixel-perfect-2d
description: >
  HnT pixel grid: 640x360 logical, canvas_items stretch, 1.5x couch camera,
  4.5 texels per world unit so 1080p shows one sprite texel per screen pixel.
  Packed sprite sheets + JSON, one body size per character, slicer and
  backdrop tools. Use when touching viewport, stretch, Camera2D, SpriteBook,
  sprite sheets, backdrops, HUD layers, or phone presentation.
---

# Pixel-perfect 2D (HnT)

Full story and the bugs this replaced: `docs/HANDOFF_PIXEL_PIPELINE.md`.
The previous version of this skill (viewport stretch, DRAW_SCALE 0.5, 96 px
cells fitted per frame) is what made sprites ~45 px, soft and pink-edged.

## Grid

| Space | Value |
| --- | --- |
| Logical base | **640x360**, `stretch/mode="canvas_items"`, `aspect="keep"`, `scale_mode="fractional"` |
| Window | fullscreen by default; F11 / Alt+Enter toggles; windowed 1280x720 |
| Couch camera | `CouchCamera.ZOOM = 1.5` (view 427x240 world units) |
| Sprite density | **4.5 texels per world unit**, `SpriteBook.DRAW_SCALE = 1/4.5` |
| 1080p | 3x base x 1.5 zoom = 4.5 px per unit = **1 texel : 1 pixel** |
| Design UI | 1280x720 at 0.5 via `PixelStage.attach_canvas` (every HUD layer) |
| Filter | `SpriteBook.world_filter()` (nearest at 3x/6x, trilinear otherwise); UI portraits `SpriteBook.UI_FILTER` |

World coordinates did not change (street y 430-520, roofs 248). Do not
retune hitboxes to fake scale.

## Cells

| Thing | Cell | World |
| --- | --- | --- |
| Actor | >= 288 px, one size per character | standing body 198 px = 44 u |
| Prop / pickup / living prop | 216 px | 48 u |
| Tile | 144 px | 32 u |
| Hub icon | 128 px | UI |
| Backdrop | native grid from `tools/backdrop.py` | `BACKDROP_TEXEL = 4/3` u per texel (6 px on 1080p) |

## Sprites

- `assets/sprites/<who>/<clip>.png` + `<clip>.json` (packed, trimmed,
  `cell` + per-frame `x y w h ox oy`). Load through `SpriteBook.frames()`,
  `SpriteBook.face()`, `SpriteBook.has_who()`. No per-frame PNG folders.
- Make them with `python3 tools/slice_sprites.py all` (Pillow, numpy, scipy),
  then import, set `mipmaps/generate=true` on `assets/sprites/**/*.png.import`,
  import again, run `tests/smoke.gd`.
- One scale per character across all clips (slicer normalises by body area).
  Feet on one baseline. Never fit a frame to its cell on its own.
- Never resize art with NEAREST by a non-integer factor.
- Clips are 8-12+ distinct cels, never under 6. Parkour run is the run cycle
  at speed. Clothes stay locked: Father hoodie + grey sweats + sneakers; Son
  dark tee, open zip, black joggers, worn sneakers.
- New animation: `tools/render3d.py` (Blender, 8 directions, albedo + normal
  map per frame) from a rigged model; light with `CanvasTexture` normal maps.

## Backgrounds

- Painted backdrops go through `NightStreet.parallax` (`assets/backdrops/<theme>.png`).
- Never draw an opaque full-map rect in the world canvas: it hides the
  whole ParallaxBackground (13 maps did this).

## Verify

    xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
      --resolution 1920x1080 --windowed --script res://tools/capture.gd -- dock_street out.png 240 walk

Look at the capture at 1:1 before calling anything pixel-perfect.

## Phone presentation

No IPA. 16:9 letterbox (`aspect=keep`). Touch HUD: light, heavy, jump, duck,
parkour, plus move. Safe-area margins.

## Do not

Pixi, Three.js, rewrite combat, restyle the approved look, go back to
viewport stretch or DRAW_SCALE 0.5.
