---
name: pixel-perfect-2d
description: >
  HnT Full HD pixel grid: 640×360 logical, integer 3× to 1920×1080, Nearest,
  no mipmaps, pixel snap, distinct animation cels. Use when touching viewport,
  stretch, Camera2D, SpriteBook, sprite sheets, or iPhone-safe presentation.
---

# Pixel-perfect 2D (HnT)

Do **not** linear-upscale 1280×720 to 1920×1080. That is 1.5× and blurs.

## Grid

| Space | Size |
| --- | --- |
| Logical viewport | **640×360** |
| Window (PC default) | **1920×1080** |
| Integer scale | **3×** |
| Design UI (existing Control layouts) | 1280×720 drawn at scale **0.5** via `PixelStage` |
| Sprite draw | `SpriteBook.DRAW_SCALE` **0.5** (96px sheet → 48 logical, body ~30–40 → ~90–120 screen) |

`project.godot`: `stretch/mode=viewport`, `aspect=keep`, `scale_mode=integer`. Nearest filter. No mipmaps. `snap_2d_transforms_to_pixel` and `snap_2d_vertices_to_pixel`.

World coordinates stay where they are (street ~y 430–520, crash, towers). The camera shows a 640×360 window into that world. Do not retune hitboxes to fake the scale.

## Sprites

- One pixel grid. Slice with nearest. `TEXTURE_FILTER_NEAREST` on every sprite.
- Clips are **8–12 distinct cels**, never under 6, never the same pose copied. `AnimatedSprite2D` must change silhouette (opposite arm/leg, foot plants).
- Parkour run is the run cycle at speed, not dash-only and not a still.
- Clothes stay locked: Father hoodie + grey sweats + sneakers. Son dark tee, open zip, black joggers, worn sneakers.

## Phone presentation

No IPA. Keep 16:9 with letterbox (`aspect=keep`). Touch HUD: light, heavy, jump, duck, parkour, plus move. Safe-area margins. Do not assume a 16:9 mouse cursor.

## Do not

Pixi, Three.js, rewrite combat, restyle the approved look, extra-high review.
