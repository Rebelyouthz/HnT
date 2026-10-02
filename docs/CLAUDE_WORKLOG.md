# Claude worklog: everything changed on `claude/gallant-galileo-5ctrmf`

**Kort på svenska:** Detta är hela listan över vad Claude har byggt i den här
grenen sedan starten: vad som ändrats, hur det är gjort och varför. Den är
skriven för nästa agent (Grok i Cursor) så att den kan fortsätta utan att
gissa. Allt är pushat till PR https://github.com/Rebelyouthz/HnT/pull/1
(bas: `cursor/meta-sprite-1d4f`). Inga nycklar eller tokens finns i git.

The rest is in English, like the code. Newest work first. Each block says
**what** changed, **how** it works (files), and **why**.

---

## 0. Ground rules the next agent must keep

- **Godot 4.7.2.** Binary in the cloud box: `~/tools/Godot_v4.7.2-stable_linux.x86_64`
  (`tools/cloud_setup.sh` fetches it). After adding a `class_name`, run
  `godot --headless --path . --import --quit` before tests or the class is unknown.
- **Tests:** `godot --headless --path . --script res://tests/smoke.gd` (prints
  `SMOKE OK`) and `res://tests/rooms_boot.gd` (prints `ROOMS_*_OK`). Both pass
  at the head of this branch.
- **Rendering grid:** 640x360 logical, `canvas_items` stretch, design UI
  1280x720 via `PixelStage.attach_canvas`. World sprites draw at
  `SpriteBook.DRAW_SCALE` (1/4.5); `CouchCamera` zoom 1.5; kerb at y 430,
  street band 430-600.
- **Canvas shader rule:** in a canvas `fragment()`, `COLOR` already holds
  texel x modulate. Pass the vertex `COLOR` through a varying (`vcol`) and
  multiply by that, or colours get squared (everything goes dark). All our
  shaders (wound, prop_damage, neon_backdrop, wet_reflect) do this.
- **Secrets never go in git.** Hugging Face token: `~/.cache/huggingface/token`.
  Sorceress key: `~/.config/sorceress/key` (chmod 600) or `$SORCERESS_KEY`.
  `tools/sorceress.py` reads them; nothing else should.
- Nothing is taken from the `waterdroppixi` project (user's explicit rule).

---

## 1. Fighting styles, timed combos, guard heights, roll, get-up attacks (latest)

**What.** The two fighters now fight differently:
- **The Son: FREERUN style** (parkour on people): jumping spinning roundhouse,
  backflip kick, running dropkick with both feet (he lands on his back and
  kips up), flying knee, breakdance floor sweep, cartwheel axe kick,
  superman punch.
- **The Father: DOCKYARD style** (boxing with dock-worker manners): elbow,
  double-fist overhead smash ("hammer"), work-boot push kick, shoulder
  charge, liver hook + overhand, spin and strike, collar-grab headbutt,
  clinch knees.
- 15 combos in total (7 Son, 8 Father), all learned and ranked in the dojo,
  one per fighter known from the start (`starter: true`).
- **Timing matters.** After each strike of a chain reaches its contact frame,
  a ring closes on the fighter. Pressing the next input as it closes is
  PERFECT, anywhere else in the window is GOOD, too late drops the chain. A
  finisher with every beat perfect hits x1.5 and gets the slow-mo.
- **Guard heights.** Hold block (LB / keyboard I). Stick up = HIGH, neutral or
  back = MID, down = LOW. Enemies show the height of their swing over their
  head during the wind-up (red ▲ high, orange ■ mid, yellow ▼ low). Right
  height: nothing gets through, sparks, hitstop, the attacker bounces off and
  a 0.5 s COUNTER window opens (your next light hits as a heavy). Wrong
  height: 70 % of the hit lands and the needed height pops up ("LOW!"). A
  perfect-timed press (just pressed) at the right height is still the
  parry/SNAP from before. Each fighter has three real block poses.
- **Combat roll:** block + dash (LB + RT / I + Shift): roll along the stick,
  backwards with no stick, invulnerable for most of it.
- **Get-up attacks:** while on the floor after a knockdown, light or heavy
  turns the get-up into an attack (Son kip-up kick, Father rising uppercut).
- **Input buffer:** a light pressed during recovery is kept 9 frames and
  thrown the moment the body is free, so chains don't eat presses.
- **Dojo practice floor** (`dojo_practice` map): a sparring dummy that never
  dies, a wall chart of the style's combos with the real buttons (pad or
  keyboard, whichever was used last), a tick when a combo lands and a gold
  star when it lands perfect, the next input written under the fighter
  while a chain is live, and SPAR mode (Tab / L3 / button) where the dummy
  throws slow high/mid/low strikes in rotation to drill the guard. Leave with
  Back/Select, Backspace or the button. Opened from the dojo sheet in camp
  ("PRACTICE ON THE DUMMY AS THE SON / THE FATHER").

**How.**
- `data/combos.json`: styles + combos. A step is `L`/`H`/`J`/`D` (light,
  heavy, jump, dash) with an optional stick prefix `F`/`B`/`U`/`Dn`
  (forward/back relative to the facing). Fields: `clip` (finisher sprite),
  `dmg`, `fx` (`launch`, `fling`, `knockdown`, `crush`, `stun`), `box`,
  `reach`, `vx` (travel), `low`, `gold`, `rarity`, `starter`.
- `src/combat/combo_book.gd` (`ComboBook`): loads the data and holds the
  per-fighter chain reader (`feed`, `beat`, `cold`, `grade_now`). Timing
  constants `PERFECT_AT 0.18 s`, `PERFECT_TOL 0.08`, `WINDOW 0.62`.
- `src/combat/combo_ring.gd` (`ComboRing`): the closing ring, press ticks,
  finish burst, next-input text in the dojo.
- `src/actors/fighter.gd`: `_combo_tok`, `_combo_press`, `_combo_finish`,
  `_roll`, `_try_getup_attack`, `attack_height`, `_clean_block`; the
  intermediate steps still play the normal moves (jab, cross, heavy…), only
  the last press is replaced by the finisher. Facing is locked while a chain
  is live so "back + heavy" is read as back, not a turn. Signal
  `combo_landed(id, perfect)`. Set env `HNT_COMBO_DEBUG=1` to print every
  token.
- `src/actors/punk.gd`: `atk_height` picked at the wind-up (`_pick_height`),
  marker (`_show_height`), `kind == "combo"` damage from the attacker's
  `combo_dmg`, `_combo_fx`.
- `src/combat/move_book.gd`: physics rows for every new clip.
- `src/juice/hit_react.gd`: zones for the new clips (gut, up, low, crush).
- `src/actors/training_dummy.gd`, `src/levels/dojo_practice.gd`,
  `scenes/levels/dojo_practice.tscn`, `src/ui/dojo_board.gd`,
  `src/ui/dojo_sheet.gd` (combo rows + practice buttons),
  `src/app/family_profile.gd` (`try_dojo` also reads combos).
- `src/ui/run_hud.gd`: solo Father now plays in the left plate with his own
  face (it used to show the Son's portrait and an empty right plate).
- `tools/combo_test.gd`: drives every combo on the dummy and prints
  `COMBO_OK/MISS` (headless logic test); with an output folder and a renderer
  it saves finisher frames.

**Animations (how they were made).** Sorceress AutoSprite
(`autosprite_animate`, Grok Imagine 1.5, 720p, ~4 credits/s) from the same
character images as the existing sprites, with a padded start pose ("room":
5:4 then 4:5 canvas) so flips and jumps stay in frame, and a "lying" start
pose cut from the knockdown video for the get-up attacks. Every clip was
checked on a timestamped contact sheet before slicing; bad takes were
redone (the Father's hammer first came with an axe, the high block was a
punch). Keying and slicing are local and free with `tools/video2sprite.py`,
which got:
- `--anchor ground`: each frame keeps its real height above the floor, so
  flips, jumps and kip-ups rise in the art (no fake physics hop).
- `--stand-frame N --stand H`: one body scale per character measured on a
  standing frame (Son 199 px, Father 188 px, same as the old clips).
- `--hit-at seconds`: marks the contact frame the hitbox opens on.
- Green-spill clamp on hands, shoes and hair edges.
About 340 of the 1200 Sorceress credits were used (30 clips including retries).

**Why.** The user asked for a parkour fighting style for the Son, completely
different styles per fighter, at least five combos each with timing,
kicks mixed with punches, jumping roundhouse, backflip kick, the run-up
dropkick that lands on the back, get-up attacks, roll, and a high/mid/low
block on a shoulder button with the stick, learnable in the dojo and
testable on a dummy with the buttons shown, and it had to feel good when
you land something. Nothing old was removed: the jab/cross/gut string,
uppercut, roundhouse, stances, parry and SNAP all work as before.

---

## 2. Dock Street: a whole handcrafted street instead of one facade on repeat

**What.** The Dock Street backdrop is now eight different painted sections
along the full 3200-unit map, in story order: Raven Wharf pawn shop and
laundromat → noodle bar and tattoo parlour → corner grocery with barber pole
→ The Anchor (boarded-up bar, bus stop, payphone) → 24H clinic → auto repair
garage → Dock 7 warehouse with the loading door open → the container yard
and harbour crane where the boss waits.

**How.** Generated with FLUX.1-Krea-dev on Hugging Face ZeroGPU (free daily
quota) with the same prompt frame as the first facade, so the style, light
and palette match. `tools/street_strip.py` finds each painting's kerb, scales
it so everything above the kerb fills the strip height, and joins
neighbours along the vertical path of least colour difference in a 120 px
overlap (2 px feather), then writes `assets/backdrops/dock_strip_0..3.png`
plus `dock_strip.json` (`ground`, `texel 0.26`, `parts`, `sections`).
`NightStreet._strip()` lays the parts left to right in the backdrop
parallax layer (the old single `dock.png` stays as a fallback).
`tools/street_tour.gd` screenshots a map at a list of x positions.

**Why.** The user: the next section of the street should fit the first one,
preferably different along the whole map, handcrafted. (The Grok/Cursor
street work the user mentioned was not on GitHub when this was done, so the
sections were built here; if that work is pushed later it can replace or
join the strip by adding its painting to the `street_strip.py` list.)

---

## 3. Art pipeline notes (Hugging Face and Sorceress)

- **Hugging Face Pro:** the ~$2/month Inference Provider credit is used up
  (router answers 402 until the billing date). ZeroGPU Spaces still work for
  images (FLUX), which is what the backdrops use. Video on ZeroGPU kept
  getting cancelled, so videos come from Sorceress.
- **Sorceress Tool API** (`tools/sorceress.py`): `GET /tools` lists 57 tools.
  Useful here: `autosprite_create_character`, `autosprite_create_start_pose`
  (free; canvas padding or a frame from a video), `autosprite_animate`,
  `autosprite_get_character` (by `assetId`), `image_generate`,
  `parallax_presets` / `parallax_prompt_helper` / `parallax_key`,
  `sfx_generate`, `model_animate` (text-to-motion for 3D). Always save the
  `jobId`s an animate call returns: a job that is never polled stays
  "processing" and its video cannot be fetched (that happened once; those
  orphan clips were never billed). Keep key out of logs.
- **Running locally on a ROG Ally X:** possible but slow. FLUX/Wan need far
  more VRAM than the Ally's shared memory, so expect minutes per image with
  quantised models (ComfyUI + FLUX schnell GGUF) and video is not practical.
  The keying and slicing (`video2sprite.py`, `street_strip.py`) already run
  locally on any PC.

---

## 4. Earlier work on this branch (oldest at the bottom)

Each line: what, then the main files.

- **Handoff notes** for the Sorceress pipeline, high-res backdrops, shader
  colour rule: `docs/HANDOFF_FOR_CURSOR.md`.
- **Knockdown clips** for both fighters (fall, lie, get up) on heavy blows,
  throws, specials, SNAPs; **Son uppercut redone** (old clip turned into the
  Father mid-move): `fighter.gd` `_maybe_knockdown`, `assets/sprites/*/knockdown.*`.
- **Real uppercut for the Father** from a Sorceress video; `tools/sorceress.py`.
- **Shader colour fix** (`vcol` rule above), finer fire-escape ladders,
  street life (steam vents, passing headlights): `src/extras/street_life.gd`.
- **Tutorial alley** high-res painted backdrop with skyline behind.
- **HUD:** player plates with avatar socket, hearts, steam line, XP bar,
  gold/gems/scrap purse; objectives under the boss bar, folding after 9 s;
  bottom lines removed: `run_hud.gd`, `mission_hud.gd`. **Dock Street**
  high-res facade + skyline parallax + fine top-down paving matched to the
  character resolution (texel 0.26 / paving 0.14).
- **Pixel toasts** in design space; account level-up reward screen:
  `juice.gd`.
- **Five extras:** lucky charms (6, wear 3), Rufus the stray dog, spray-can
  tags, a crowned WANTED bounty per street, photo mode: `src/app/charms.gd`,
  `src/extras/*`, `run_act._place_extras`.
- **Parkour:** 23 real tricks as timed button combos, dojo-learnable, each
  with its own body move: `data/parkour.json`, `parkour_gate.gd`,
  `trick_move.gd`.
- **Bat suit (Son) / Spider suit (Father)** found after the map-1 boss, worn
  from the locker, drawn by the wound shader: `src/app/suits.gd`,
  `wound.gdshader` `suit_col`.
- **Options rebuilt** (audio, video: quality, display, resolution, vsync, AA,
  FPS cap, bloom, blur, brightness, CRT; game; controls; double-confirm
  reset), `Gfx` applied at boot, pixel cursor with pad-stick pointer,
  checkpoint saves with CONTINUE: `settings_sheet.gd`, `gfx.gd`,
  `pixel_cursor.gd`, `run_act._save_resume`.
- **Doom-style portraits** that bleed and flinch; **death screen** names the
  killer and the way ("shot with a 9mm", "smashed like a tomato");
  **bosses break in four stages**: `death_cause.gd`, `act_boss.gd`.
- **Level up:** glow, floating LEVEL UP, force wave that knocks thugs back
  and kills the nearly dead, paused 3D rarity card deal with flip-in and
  zoom: `level_up_fx.gd`, `card_pick.gd`, `pixel_card.gd`.
- **Breakables** crack/dent/lose chunks in stages and shatter; cash, coins,
  flasks and one adrenaline syringe per street: `smash_prop.gd`,
  `prop_damage.gdshader`, `loot_drop.gd`.
- **Blood sim:** gravity drops, splats, pools, screen splatter; wound shader
  with face cuts, clothes spatter, bullet holes; zone reactions (gut doubles
  over, low sweeps) and falling corpses: `blood.gd`, `hit_react.gd`,
  `wound.gdshader`.
- **Wet street:** painted road, screen-space puddle reflections, rain
  rings, lamp streaks, mirrored actors: `wet_street.gd`,
  `wet_reflect.gdshader`.
- Outro film after map 1, film before camp, reward screen, level-up cards.
- The Harbour Clock secret tower on Dock Street (climb, talk, choices).
- Clinic main menu in the reference style; timing ring; dojo parkour.
- Prologue film; Vale brothers rescue and live camp construction.
- Menus in the reference style; release workflow; walkable hideout.
- Start screen, story start, speech bubbles, painted tutorial alley.
- Father moves from video, frame-synced strikes, stance combos, hit vs
  whiff feel: `move_book.gd`, `fighter._begin_strike`.
- `tools/video2sprite.py` (video → sprite sheet), `tools/render3d.py`
  (Blender 3D → 8-direction sprites), pixel-perfect pipeline, full-res
  rendering, 1.5x couch camera, Web/PWA export.

---

## 5. Known gaps / good next steps

- Sorceress credits left: about 860 of 1200. Worth spending on: sprite
  versions of the suits, parkour trick sprites, enemy variety, the Father's
  stomp (the generated take came out as a push kick and is used as DOCK BOOT).
- The Father's elbow is a raised-elbow overhand rather than a clean
  horizontal elbow (two video takes refused the pose).
- The other maps still use the older single backdrops; `street_strip.py`
  can do the same for them with new FLUX sections.
- A full playthrough check from map 1 into map 2 by a human is still due.
