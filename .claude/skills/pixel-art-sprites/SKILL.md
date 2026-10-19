---
name: pixel-art-sprites
description: Making and fixing character/prop/effect pixel art for this game with Hugging Face (FLUX design + Wan 2.2 image-to-video) and the repo's slicer, including scale matching, contact frames, cleanup and checks. Use when a character, enemy, NPC, prop or effect is missing a sprite, looks off-model, is the wrong size, or an animation lacks punch.
---

# Pixel-art sprites pipeline

Never take anything from the "waterdroppixi" user. Tokens: HF at
`~/.cache/huggingface/token`, Sorceress key only in `~/.config/sorceress/key`
or `$SORCERESS_KEY`. Never commit or echo either.

## Generate
- `tools/hf_batch.py` (copy in `/tmp/claude-0/hfv/batch.py`): queue of
  `('design', who)` (FLUX krea, green-screen side-view sprite in the house
  style) and `('clip', who, move)` (Wan 2.2 i2v from the design). Skips done
  outputs, stops on ZeroGPU quota. Space: `zerogpu-aoti/wan2-2-fp8da-aoti-faster`.
  If it errors, retry later; the same queue exists for a local GPU in
  `tools/local_gpu/` (ROG Ally X).
- Style line: "detailed 16-bit pixel art ... Streets of Rage 4 ... strict side
  view facing right ... flat solid bright green background #00b832".
- Static props/effects: FLUX design only, then key the green and trim.

## Slice
`python3 tools/video2sprite.py clip.mp4 <who> <clip> [--loop] --frames N`
- Size: `--scale-ref assets/sprites/<who>/idle.json` when that JSON has
  `scale`/`src_area`; otherwise `--stand <idle frame height> --stand-frame 0`.
- `--anchor ground` for falls/deaths, `center` for airborne.
- Move `*_preview.gif` out of `assets/` afterwards (scratchpad).
- Strikes: set `"hit"` (contact frame). Reach (`ox + w`) max is a good first
  guess; override by eye when a held prop sticks out from frame 0.
- Deaths: keep the fall plus one rest frame (~12 fps); the corpse system takes
  over after.
- Re-import, smoke test, then look at a contact sheet of every new clip
  before committing (off-model frames: costume colour jumps -> drop them).

## Checks
- Same body height as the character's other clips (no popping between clips).
- Feet on the same baseline; no foot sliding (walk/run playback comes from
  `SpriteBook.stride_rate`).
- Scale against the backdrop: see beat-em-up-feel "Readability".
