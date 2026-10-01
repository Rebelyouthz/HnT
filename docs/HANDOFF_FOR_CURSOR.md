# To the Cursor agent: what changed, what broke, how to continue

Written by the Claude Code session on branch `claude/gallant-galileo-5ctrmf`
(PR #1 into `cursor/meta-sprite-1d4f`). Read this first, then
`docs/HANDOFF_PIXEL_PIPELINE.md` (rendering + sprite pipeline) and
`docs/AGENT_SETUP.md` (tools, keys, MCP). Timmie's rule: **nothing from the
waterdroppixi repo/folder, ever.**

## 1. What was wrong with the earlier approach (do not repeat)

| Earlier method | What it caused | Replaced by |
| --- | --- | --- |
| `stretch/mode="viewport"` at 640x360, `DRAW_SCALE 0.5` | The whole game was a 640x360 image blown up 3x. Sprites ~45 px, blurry UI text. | `canvas_items` stretch, camera zoom 1.5, `DRAW_SCALE 1/4.5`: one sprite texel = one screen pixel at 1080p. |
| Slicer shrinking with `Image.NEAREST`, each frame fitted to its cell | Half the pixels dropped; poses "breathed" and popped size between clips. | `tools/slice_sprites.py`: one body scale per character, premultiplied Lanczos, feet on one baseline. |
| Animating straight from the AI boards | The boards have good poses **in the wrong order**, so every clip except the kick was choppy nonsense. You cannot fix that by re-cutting. | Video-to-sprite: key poses -> Wan 2.2 video -> `tools/video2sprite.py` (section 3). |
| Opaque full-map "sky" rects in 13 levels | Hid every parallax background ever built. | Removed. Backgrounds only through `NightStreet.parallax`. |
| `Talk` and `MissionHud` added straight to a CanvasLayer | Drawn at 2x, mostly off screen; dialogue was never visible. | Everything UI goes through `PixelStage.attach_canvas`. Talk is speech bubbles now. |
| World labels at 640x360-era font sizes | 4.5x too big under the new camera ("JUMP · UP SAFETY VAULT" over half the screen). | `NightStreet.WORLD_TEXT = 0.5`; use `NightStreet.plaque()` for world text. |
| Board sprites stretched to fit (`attach_scaled(... 3.2x)`) | Smeared props (fire escape). | Never stretch art non-uniformly; draw on the grid or re-cut. |
| Hitbox spawned on button press, 0.48 s anim regardless | Hits landed before the fist moved. | Hitbox opens on the sprite's contact frame (`"hit"` in the clip JSON). |
| Fall-damage threshold 620 with `FALL_MUL` 1.65 | Every normal full jump hurt the player. | Threshold derived from `JUMP * sqrt(FALL_MUL)`. |
| ZeroGPU Spaces for video (Wan) | 404 / cancelled, quota. | HF **Inference Providers** (fal-ai) via `huggingface_hub.InferenceClient`. |

## 2. What exists now (all on the branch, tests green)

- **Start screen** `scenes/ui/title.tscn` (main scene): START GAME / CONTINUE /
  OPTIONS / CREDITS / QUIT. Credits: TimmieTooth (Father), HugoLugo (Son).
- **Story start**: START GAME -> `intro_flow` (alley film, real sprites,
  speech bubbles) -> comic slam -> `tutorial_alley` -> film 2 -> Dock Street.
- **Speech bubbles**: `src/story/talk.gd` + `speech_bubble.gd`. Lines are
  `{"who": "father"|"son"|"", "text": ...}` in `data/story.json`.
- **Hideout** `scenes/levels/camp.tscn` (`src/world/camp_hideout.gd`): walkable
  4-room basement between maps. A station per building (`data/camp.json`,
  x as a fraction of the backdrop), COMMAND BOARD = old hub with every menu,
  PORTAL continues the run. `App.advance()` routes through it;
  `App.back_to_hub()` lands there.
- **Father**: 19 clips from video (idle 32f, walk 24f, run 20f, jump, land,
  duck, hurt, all strikes with contact frame + impact hold + retract).
- **Move system** `src/combat/move_book.gd` + `Fighter`: contact-frame hitboxes,
  planted feet, lunge, stance chains, hit vs whiff feel, physics-driven
  jump/run playback.
- **Backdrops**: dock (Gamma), tutorial alley + 4 hideout rooms (FLUX Krea).
- **Installer**: `.github/workflows/release.yml` -> `FatherAndSonSetup.exe` on
  GitHub Releases (no Godot needed by players).

## 3. The asset "app": how to make sprites, moves and backgrounds

Everything is a script in the repo; there is no separate app to host.
Python deps: `pip install pillow numpy scipy imageio imageio-ffmpeg huggingface_hub gradio_client`.
Keys come from env: `HF_TOKEN` (never commit it).

### A character move (video -> sprite), e.g. the Son
1. Copy `tools/videogen/father_spec.py` to `son_spec.py`. Per clip: start key
   pose `(board.png, index)` (guard for strikes), end key pose (the peak:
   fist out / leg extended), a prompt, a mode (`loop` / `strike` / `air` / `move`).
   Keep the clothes line in `STYLE` locked (Son: dark tee, open zip, black
   joggers, worn sneakers).
2. `python3 tools/videogen/keys_build.py son_spec son` -> `keys/son_<clip>_{a,b}.png`
3. `python3 tools/videogen/run_batch.py son_spec son` -> `vid/son_<clip>.mp4`
   (Wan 2.2 I2V on fal-ai; 33 frames for strikes, 81 for loops).
4. Look at every video (contact sheet) and pick the cut: for strikes the
   frames from guard to full extension.
5. Cut: idle first, it is the scale reference.
   ```
   python3 tools/video2sprite.py vid/son_idle.mp4 son idle --loop --frames 32 --min-cycle 0.8 --max-cycle 2.4 --out OUT
   python3 tools/video2sprite.py vid/son_jab.mp4 son jab --start 0.31 --end 0.91 --frames 8 --hold 2 --retract 7 --fps 56 --scale-ref OUT/son/idle.json --out OUT
   python3 tools/video2sprite.py vid/son_jump.mp4 son jump --start .. --end .. --frames 22 --anchor center --scale-ref OUT/son/idle.json --out OUT
   ```
   The exact Father cuts are in the commit "Father moves from video".
6. QA strip of every frame, copy into `assets/sprites/son/`, Godot import,
   set `mipmaps/generate=true` in the new `.png.import`, import again,
   `tests/smoke.gd`, then `tools/capture_moves.gd` to watch it in game.

### A background
1. FLUX Krea (`black-forest-labs/FLUX.1-Krea-dev` via `gradio_client`, token
   kwarg `token=`), 1344x768, long prompt: "strictly flat orthographic front
   view ... bottom 14 percent is the kerb edge only ... no people, no text".
2. `python3 tools/backdrop.py in.png assets/backdrops/<theme>.png --ground 0.86 --period 2.0`
   then add `"texel": 0.666667` to the JSON for close-up paintings.
3. Call `NightStreet.parallax(self, map_w, "<theme>")` in the level; the
   procedural parallax boxes switch off automatically under a painting.

## 4. Hugging Face limits (what "100" means)

With HF PRO the account gets **$2.00 of Inference Providers credit per
month** (free accounts: $0.10). The usage page shows how much of it is used;
"100" there means **100 % of the included credit is spent**. It resets at the
start of the next monthly billing period. After that, calls either stop or are
billed pay-as-you-go if a card is on file (Settings -> Billing). One Wan 2.2
720p clip on fal costs a sizeable slice of $2, so 17 Father clips used it up.
ZeroGPU Spaces (FLUX Krea backgrounds) are a separate daily GPU-minutes quota
(PRO: much larger, resets daily) and still work when Inference credit is out.
Plan: backgrounds via FLUX Space now; Son/enemy videos next month or with
pay-as-you-go enabled.

## 5. Directives (in this order)

1. **Do not touch** the rendering setup, `SpriteBook`, the slicer or the move
   system without reading the two handoff docs. Never go back to viewport
   stretch, NEAREST shrinking, or per-frame fitting.
2. **Menus: wait.** Timmie is sending reference images; restyle only after
   that, keep the bug fixes (centering, int numbers).
3. **Son moves**: section 3, same clip names as the Father
   (`idle walk parkour_run jump land duck hurt jab cross gut heavy uppercut
   front_kick side_kick roundhouse air_mix slide dive snap`).
4. **Enemies** (11 sets): `idle walk attack hurt` each, same pipeline; one
   scale per enemy, feet on the baseline.
5. **Backdrops for the 12 blockout maps** (section 3); verify each with
   `tools/capture.gd <map> out.png 200 walk` at 1920x1080 before calling it done.
6. Every change: `tests/smoke.gd`, `tests/rooms_boot.gd`, a 1080p capture you
   actually looked at. Commit small, describe what you verified.
7. Release: push a commit with `[release]` in the message (or a `v*` tag) and
   the workflow publishes `FatherAndSonSetup.exe`.
