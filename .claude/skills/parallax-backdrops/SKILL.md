---
name: parallax-backdrops
description: Painted backdrops, parallax layers, the wet street floor and world-scale for this game's maps (Dock Street, Intake Lot and the rest). Use when a map looks flat, dark, mis-scaled, has seams or black voids, or when actors/props look too small or big against the painting.
---

# Backdrops and parallax

## Pieces
- `src/world/night_street.gd`: builds a map's look. A painted backdrop
  (`assets/backdrops/<theme>[_strip_N].png` + `.json` with `ground`, `texel`)
  *is* the city; procedural fog/far layers only run without one.
- `src/world/wet_street.gd`: the road (`street.png` cobbles, `lot_ground.png`
  asphalt) tiled from `TOP` = 426, squashed `TEXEL 0.14 x TEXEL_Y 0.075`,
  plus a reflection pass, lamp streaks and a near-edge shadow.
- Camp: `src/world/camp_hideout.gd` (`camp.png`, texel 2/3; the room is
  extended past its right edge with a mirrored strip).
- Stage card art: `StageCard.art(id)` picks the first strip chunk.

## Rules
- No black voids: the camera limits must stay inside painted area, or extend
  the painting (mirror + darken the edge strip).
- Seams: tiled regions use `TEXTURE_REPEAT_ENABLED`, linear filter for the
  road, nearest for pixel art.
- Brightness: the road texture is ~10% mean luminance; it is lifted with
  `modulate` > 1. Check a 1920x1080 capture after lighting changes.
- **World scale yardstick** (measure, don't guess): in the painting, find the
  kerb line, a door (frame height), a street lamp and the bike. An adult is
  about 0.8-0.9 of a door frame's height; a wheelie bin reaches a hip; a crate
  reaches the knee to the hip. Actors are scaled by `SpriteBook.FIGHTER_SCALE`
  / `ENEMY_SCALE` via `SpriteBook.grow()` (keeps feet in place); props have
  their own scales in the prop scripts. Change both together so the fight
  lane, hit ranges (`reach`, engage distance) and props stay consistent.
- Depth sorting is by y (feet). Parallax `motion_scale` < 1 for far layers.
