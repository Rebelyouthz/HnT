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

## 0z. Controls, start flow, entrances, walking, parkour fails, survivor parity, video clips (latest)

Owner feedback round: pad did not move the hero in game, only right mouse
did anything, video menu stuck on BACK; father glides when he runs (wants
walking in the brawl maps); son idle half-steps; jump too snappy; roof
pillar slides you up; glide only with the bat cape; the cape was a black
box; level-up popped before the street was visible; enemies stood in shot;
swap map 1/2 music; parkour BAD / EPIC FAIL with three falls; survivor
should share the street weapons and cards; three hero levels with depth;
"as smooth as possible" animations via Hugging Face (no Sorceress credits).

- **Pads** (`src/input/pad_router.gd`): SOLO (`not App.two_bodies()`) binds
  every pad to `p1_` (device -1); the last pad touched is `p1_device` (for
  the right stick). Start on the playing pad is pause; drop-in only from a
  second pad after the first was played. Couch keeps the 1-pad = Dad rule.
- **Mouse** (`src/app/boot.gd`): LMB light, MMB heavy, RMB shoot.
- **Menus**: rows are detached (`remove_child`) before `queue_free` in 15
  menus, so the pad focus lands on the new rows; settings wrap to BACK.
- **Start flow**: `StageCard` -> GET READY / GO! on the frozen street
  (`closed` signal); `CouchCamera._snap` frames the heroes at once; the
  starting draw waits for GO + 1.2 s (`create_timer(.., false)`).
- **Entrances** (`src/levels/entry_director.gd`): story encounter rows spawn
  when the camera nears them: walk in from the right, from behind, rappel
  on a rope from the roofs, climb down an in-view fire-escape ladder,
  fliers drop in. Group `entry_pending` keeps last-kill slow-mo honest.
  Not used on FIELD / roof_start / remote co-op / versus.
- **Walking** (`Fighter.WALK_K`, `SIDE_WALK`): story streets walk (father
  0.6, son 0.56 of top speed); run clip only when dashing / >175 px/s. Son
  uses `walk_dr` (real steps) for the profile walk until a new one lands.
- **Feel**: GRAV 1815 / JUMP -539 (same height, ~15% more hang). Glide only
  with the BAT top (`Fighter.can_glide`); sprite heroes never show the old
  polygon cape (CapeFx used for glide/cape moves). Wall run -> wall kick.
  Dock Street roof pillar is a low chimney. Music: Dock Street <-> Intake
  Lot. Talk lines from an absent hero are skipped (`Talk._present`).
- **Roof faces** (`NightStreet.painted`): on painted maps the roof faces are
  a soft shadow + two corners, not a brick slab over the painting.
- **Parkour** (`src/parkour/runner.gd`): release grades `bad` (d<-4 or >90)
  and `epic` (d<-26 or >170); BAD LANDING stumble -45% speed; EPIC FAIL
  (`_epic_fail`: trip / face / back, clips `fail_*`, 1.0/1.8/1.9 s);
  `PARKOUR_SLOPPY=1` test autopilot. `_build()` reads ROOFTOPS level,
  PARKOUR tree and parkour META (speed, jump, windows, boost, air control,
  hang, coyote, score, IRON ANKLES, p_ghost). Tricks have `lv` (1..13);
  locked = FREESTYLE + badge "LOCKED · ROOFTOPS LV n"; NEW TRICK toast on
  level up; HEROES shows the next trick. `Heroes.mode()` = parkour in
  `RooftopRun`.
- **Survivor parity** (`SurviveRun._add_street_arsenal`, `street_cards`):
  found street weapons are picks `w_<id>` (guns MANUAL with tracer
  `bullet` projectiles + magazine from the gun; melee auto-swings with
  `SurvProj.swipe`), damage x `Arsenal.power_mul`. Street level-up cards
  with a `kind` (not `fixed`) deal into picks (kind "card") through the
  act's RunState.
- **Video clips** (Hugging Face, `/tmp`-style queue; spaces that worked:
  `Rchoks/wan555` (fast), `r3gm/wan2-2-fp8da-aoti-preview`; they take
  `input_image` + `last_image` - same image = a closed loop; upload two
  different files or gradio 404s the second). Son `idle`, `fail_trip`,
  `fail_face`, `fail_back` installed (video2sprite --stand-frame 0 --stand
  199). `tools/install_hero_clips.py` batch-installs moves (hit frame =
  furthest-forward silhouette). A standing start pose gives timid steps;
  start from a mid-stride frame for a real walk. `tools/tween_frames.py`
  (optical-flow in-betweens) ghosts fast limbs - not for strikes.
- `tools/anim_probe.gd`: films a scripted input line (full frames).

## 0y. Rooftop parkour run (Vector-style) + one-file installer

**Fire Escapes is now a side-scrolling rooftop chase** (`scenes/levels/fire_escapes.tscn` ->
`src/parkour/rooftop_run.gd`; the old `src/levels/fire_escapes.gd` stays because smoke.gd checks it).

- `src/parkour/roof_course.gd` (RoofCourse): seeded generator, 22 buildings, gaps/drops/step-ups,
  vault boxes, slide bars, climb huts, ramps, roof guards, decor, checkpoint every 4 buildings,
  goal mast. Queries: `ground_at`, `wall_ahead`, `bar_at/bar_ahead`, `ramp_at`, `edge_ahead`,
  `checkpoint_before`. Props: `assets/sprites/roof/*.png` (keyed, lossy import).
- `src/parkour/runner.gd` (Runner): scale 1 m ~ 37 units (son ~67 tall). TOP 290, BOOST 365,
  G 1300, JUMP_V 430. Tricks are LOADED: right stick dir + R1/R2/L1/L2 held, released with left
  stick up at the edge (RELEASE_WIN 0.22). Release vs takeoff edge grades perfect<=24 / good<=48 /
  ok<=90. Landing pose: both sticks down-right (roll) if drop > 95, else both right; held within
  0.16 s of touchdown = PERFECT (boost +55 for 1.3 s, chain grows). Missed roll = hard landing,
  unfinished spin = bail. Vault/kong, slide, climb (h<=150, vx>=50), ledge grab, stumble.
  `Runner.autopilot` (env PARKOUR_AUTO=1) drives captures.
- `src/parkour/hunter.gd`: replays the leader's own trail with a lag (start 2.0 s, max 2.8,
  caught at 0.28). Events nudge the lag (stumble -0.3, hard -0.25, bail -0.3, perfect land +0.22).
- `src/parkour/roof_guard.gd`: kong over (UP) or slide into (DOWN); running into him = baton.
- Results: `ResultsSheet.combat = false` hides SCRAP/PARRIES; `tiles` adds mode tiles
  (GOLD, PERFECT, TRICKS).
- Autopilot run verified: escaped, 17 tricks, 11 perfect landings, 2.8 s ahead.

**Installer:** one file, `FatherAndSonSetup.exe` (~97.4 MiB) on branch `windows-installer`
(single amended commit, force-with-lease). Raw link:
`https://github.com/Rebelyouthz/HnT/raw/windows-installer/FatherAndSonSetup.exe`.
GitHub's per-file cap is 100 MiB - margin is ~2.6 MiB; next growth needs more packing
(lower backdrop quality, trim unused audio). Releases API is 403 for this session type.
System makensis is `/usr/bin/makensis` (pack_windows.sh's default path does not exist here;
run makensis in tools/windows after the export step).

**Open:** parkour co-op (father as p2) not play-tested by a human; skyline far layers are flat
shapes; enemy diagonal walks (Wan quota); red-hero watch item from 0x.

## 0x. Seamless survivor ground, ground litter, survivor HUD

Owner: the mirrored ground tiles showed seams ("klipps ihop... skumma
skarvar") - wanted a real ground with no seams, plus asset sprites on it.

- **One unique ground per map** (`assets/sprites/field/ground_<tile>.webp`,
  3626x2426 at `SurviveField.GROUND_U` = 0.75 world units per texel, margin
  `GROUND_M` 60). Nothing tiles. Built offline by `tools/fieldgen/gen.py`
  (sources in /tmp were FLUX samples): asphalt and cobbles are *image
  quilted* (`tools/fieldgen/quilt.py`, Efros-Freeman min-cut patches); slabs,
  clinic tiles and dock planks are laid piece by piece with real texture cut
  from the sample into each piece (plank rows of random-length boards with
  butt joints + nails). Then macro light variation, stains, cracks, paint
  (lot stall lines follow the car rows at y 380/1300), snow drifts + slush
  ruts, moss in joints, quantised to 72 colours, saved as WebP (import mode
  lossy). Quilting smears regular grids - use piece layout for those.
  Lobby cards use small `thumb_<tile>.png`. Old mirrored `lot/circle/...png`
  removed.
- **Ground litter** (`SurviveField._decals`, `assets/sprites/field/decals/
  <tile>_NN.png`, FLUX sheets on magenta sliced by `tools/fieldgen/slice.py`):
  ~170 flat sprites per map (drains, cans, papers, leaves, rope, crabs,
  slush...), random turn/flip, 11-22 units, darkened, never in water.
- **Survivor HUD**: XP bar across the top with a gold LV badge (glint,
  flash on level), clock + kills under it, ultimate bar under that; the
  lead plate drops the story XP line and purse in FIELD, boss bar steps down,
  objective card tucks under the radar, combo text smaller. Soft oval
  shadow under the heroes (the trapezoid read as a black slab).
- Dark enemy tints (Vault Guard etc.) are lifted toward white so they don't
  turn into black cut-outs at night (`Punk` tint chain end).
- Results show PARRIES for the run (Engine meta `run_parries0`).
- capture.gd: `DUMPHERO=1` (hero tint/material/lights), `REDTEST=w,s`,
  `HPSET=n`, `REDPROBE=1`, `PROBE=x,y` also lists scripted nodes nearby.
- Open: a rare all-red hero seen twice on the field at low HP with the
  wound shader on; no modulate, light or shader param explained it and it
  did not reproduce in 6+ later runs. Watch for it.
- Enemy diagonal walks still wait on the Wan ZeroGPU quota (CancelledError);
  Kontext pose-by-pose gave near-identical frames, not usable.

## 0w. Survivor: own maps, living props, 3D XP crystals, twin-stick magazines

Owner: different maps per survivor hour, living animated objects, XP gems
that pop out of bodies and tumble/land like 3D (survivor only - the main game
pays XP per kill, no orbs), twin-stick with auto + manual weapons: one manual
fires, empty mag -> next gun, all empty -> reload; reload animations.

- **Layouts** (`SurviveField._landmarks`): per map before the scatter (lot car
  rows/puddles/drums, circle fountain + tree ring + benches, clinic chair
  blocks + desk + tube grid, sleet frozen pond + snow heaps, dock water
  channels with gaps + bollards + pallets). `_blocks` keeps props and
  spawns (`ring_point`) out of water. Returns false = no street lamps.
- **Living props** (`src/survive/field_life.gd`): fire_barrel, steam, puddle
  (rain rings), tree (Sway skew), fountain, ice (slippery: Fighter `_ice_v`
  momentum, group "ice" + meta size), water (solid, ripples), tube (Flicker
  hard). Prop art `assets/sprites/field/props/*.png` (FLUX on magenta,
  keyed with a corner-median distance key; /tmp script key2.py).
- **XP crystals** (`src/survive/xp_gem.gd`, `XpGem.pop`): height `_h` +
  shadow, flip (scale.x by cos) + spin, 2 bounces, falls over (`_lie`),
  glint, magnet lifts it; colour by value; elites pop 3. Merge cap calls
  `refresh_tint` (not queue_redraw - that clashes with CanvasItem).
- **Main game orbs gone**: quest_giver/hazard pay XP directly.
- **ManualRack** (`src/survive/manual_rack.gd`): per hero; `MAG` per weapon;
  `can_fire/spend`, swap on dry, reload all (sets Fighter.reload_t so the
  held gun tilts), SNAP cycles, pips under the feet. Survive ability: hold
  fire = all manuals repeat at cd. `Fighter.hold_manual(kind, aim)` mounts
  the gun art, aim pose (`cross`, or hip `_hip` while moving), faces aim
  (`_face` skips while aim_t on the field). New manuals sprayer +
  rivet_rifle (data/survive.json). Main game already had reloads (gun tilt,
  mag drop, sfx).
- **Fixes**: hurt flush stacked per frame -> heroes went solid red (now one
  flush over `_lamp_tint`); wound/spatter coverage capped; combo gold banner
  off on the field. capture: GIVE=ids@f, FIRE=f, OVERVIEW=1.
- **Diagonals**: enemies still pending - Wan ZeroGPU Space errors (quota).

---

## 0v. Survivor goes top-down

Owner: is survivor top-down like Halls of Torment / Vampire Survivors? (It was
not - it ran on the story's side street.) Make it top-down with a good
ground per map, 8 directions for heroes and enemies, survivor menus, better
than Halls of Torment.

- **Field** (`src/survive/survive_field.gd`): `SurviveField.setup(act)` (RunAct,
  for every `SurviveAct`) sets `Fighter.FIELD`, opens the lane
  (`Fighter.STREET_MIN/MAX` are now static vars, reset to 430/520 by every
  act), map 2600x1700, spawn centre, `y_sort_enabled`. `build()` replaces the
  map's `build_world`: tiled ground `assets/sprites/field/<tile>.png` (FLUX,
  pixelated + mirror-tiled 2048, mipmaps on; per-theme scale `k`), walls,
  44 SmashProps, cars, decor (attach_living), 15 lamps (light pools), fog
  at the edges, weather (`Weather` follows the camera). Theme table
  `THEMES` per survive map. `ring_point()` = spawn just off screen.
- **Movement**: Fighter on the field moves 8-way (normalised, y x0.9).
  `Punk._field_chase` = 2D chase to a spot beside the hero, swing when
  |dy|<26. Horde/boss/champion/skinwalker spawn via `ring_point`; titles
  without walking art are skipped on the field (`Horde._no_art`). Camera:
  `CouchCamera.field` (zoom 1.05, both axes, no leash). Hardcoded lane
  clamps (blood, loot/xp floors, boss brain, shrines, events) follow the
  static bounds.
- **8 directions**: `SpriteBook.dir_clip(sf, v, eight)` -> walk / walk_ur /
  walk_dr / walk_up / walk_down (mirrored left by facing). New clips:
  son + father walk_dr/walk_ur, coping_imp walk_dr. Pipeline:
  `/tmp`-style script: FLUX Kontext (`black-forest-labs/FLUX.1-Kontext-Dev`)
  turns the idle frame to a 3/4 front/back view, Wan 2.2 ZeroGPU walks it in
  place (it drifts back to profile after ~1.3 s: cut `--end 1.3..1.6`),
  `tools/video2sprite.py --loop --frames 10 --fps 12 --scale-ref
  <who>/walk_up.json`. **Still missing**: the other enemies' diagonals
  (ZeroGPU quota ran out) - they fall back to the nearest clip.
- **Lobby** (`src/ui/survivor_lobby.gd`, RUN tab > SURVIVOR HOURS,
  `hub._open_survivor`): map cards with the ground art, best per map
  (`Agony.note_best`), AGONY dial (`src/survive/agony.gd`: hp/cap/speed/coins,
  opens per map on a win), hero pick, starter/gear/tree shortcuts,
  `App.start_survivor(map, agony)` (`App.surv_solo`: next_id cleared).
- **Radar** (`src/survive/field_map.gd`): minimap + edge arrows; pins via
  group `map_pins` + meta `pin` (chest/shrine/cursed), `act_boss`, elites.

---

## 0u. Vault reveal + collection, three hero tracks, roof tricks, pinball XP, quick belt

Owner: a drawn card flips, zooms up with rays/shadow/reflection and lands in a
collection under DRAW; sunset rooftop card back; two alike merge a rarity,
two max cards evolve; synergies viewable. Three hero levels (story,
survivor, parkour); rarity up = one more survivor weapon slot; twin-stick
aim. Parkour tricks: right stick + R1/R2/L1/L2, hold on approach, release on
takeoff (graded), hold a landing (roll = both sticks down-forward). XP from
kills and combos like a pinball table; HUD quick slots on the d-pad / 1-4.

- **Vault** (`src/ui/vault_sheet.gd`, `src/app/vault_cards.gd`): collection is
  `vault_inv` {id: copies per rarity}; a card's power level = best rarity + 1.
  Draw rolls the card and its rarity (`_roll_tier`, tokens floor RARE).
  MERGE 2 alike -> next rarity; EVOLVE consumes one LEGENDARY of each of two
  parents (`needs` in data). `PixelCard` scales round its centre - place it by
  its middle (`mid - (W,H)/2`). `capture.gd FILM=N` saves every Nth frame.
- **Hero tracks** (`src/app/heroes.gd`): `level(role, mode)`; `mode()` reads the
  running `RunAct` (survive map -> "survivor", `roof_start` -> "parkour").
  Shared rarity/cap; rank needs any track at the cap. `weapon_slots()` =
  best rarity; survivor slots = 5 + that (+1 tree). `trick_window_mul()`.
- **Twin-stick** (`PadRouter.rstick/mouse_live`, `SurviveAbility._aim`): manual
  weapons aim with the right stick or mouse, fire on a full push / left
  mouse, crosshair `_ret`.
- **Roof tricks** (`src/extras/trick_call.gd`): one per act. Roof edges call a
  trick from `TRICKS` (unlocked by ROOFTOPS level); `ParkourGate` calls its
  trick via `call_gate` and asks `gate_takeoff` (no TimingRing any more):
  "skip" when never held (no penalty), else grade on release (`graded`).
  Landing checks both sticks vs `LANDS`. Prompt is drawn in the 1280x720
  design space (`PixelStage.attach_canvas`). Keyboard: numpad/arrows + O
  SHIFT I U. `Fighter.trick_hold` keeps block off while holding L1.
- **Pinball XP** (`Juice.pinball_kill/xp_mul/_jackpot`): story kill XP x
  (1 + 6%/hit, cap 3.5) + 0.5 per multi-kill + air/scenery/overkill/elite;
  jackpots at combo 10/20/30/40/60; banking pays n*n/30.
- **Quick belt** (`src/app/quick_belt.gd`): flask/adrenaline/energy/smoke,
  run-scoped in `App.run_bag`, one flask to start. D-pad = slots (moving is
  the stick only; duck = left-stick click), keys 1-4 (P2 7-0). HUD rows in
  the bottom corners; pause MOVES lists belt + tricks.
- **Feel**: every jump hangs at the apex (x0.7 gravity under 90 px/s),
  `MAX_FALL` 1150.

---

## 0t. Card vault, mastery, cleaner fights, menu juice

Owner: the screens look messy (survivor and the Intake Lot); a card shop of
unlockable level-up cards (face-down hand, rising price gold -> gems ->
tokens, casino reveal), synergies and evolutions in the tree, tokens from
secrets/bosses/towers/profile levels, a hard-to-reach secret per map; moves
get better with use; icons, fly-in and stat arrows on every equip; toasts
with icons and achievement trophy; loot visible; no XP orbs on story maps.

- **Clutter, found by census** (`tools/autoplay.gd`, `CENSUS=<frame>` prints
  what is on screen): `Juice.hole()` left permanent 6x6 black squares on the
  street for every shot - now a small round chip that fades (cap 20). Bodies:
  `DeathFall.trim()` caps 12 on story streets and 5 in survivor hours, and
  survivor bodies stay 4 s. Survivor horde: `CrowdAI` gives 5 attack tickets
  per hero there and a 3-deep ring for the rest + body spacing
  (`CrowdAI.spread`), phase caps -20% with +20% HP, XP gems merge past 18,
  elite/champion plates only on the nearest (`EliteTag`).
- **CARD VAULT** (`src/app/vault_cards.gd`, `data/vault_cards.json`,
  `src/ui/vault_sheet.gd`): 25 cards (19 + 3 synergies + 3 evolutions),
  stat-driven (`VaultCards.stat(key)` read in punk dmg/crit/heal, run_state
  xp/gold, survive_run xp/pickup/area/cd/dmg). Price ladder `LADDER`, -2 steps
  per night (`on_night`). Hand 9, 12 with brawl node DECK `deck_hand`;
  `deck_synergy` / `deck_evolve` gate those cards. Owned cards join level-up
  draws (story `run_act._cards`, `CardPick` table, survivor `offers()`/pick
  kind "vault"). Card back art: `assets/sprites/vault/card_back.png` (FLUX).
  Tokens: first clear of a map, first tower top per map, 25% from stashes,
  every profile level (+3 gems), elite drops (8%) / regular (0.6%),
  survivor boss chests, VAULT CRATE.
- **VAULT CRATE** (`src/world/secret_ledge.gd`): on the highest, furthest
  roof of every map; first find token + 4 gems + 40 gold.
- **MASTERY** (`src/app/mastery.gd`): uses per move clip, ranks at
  20/60/140/280/500/800: +3% power, -2.5% wind-up, -3% recovery each; shown
  in MOVES.
- **Story XP**: no orbs; XP is credited on the kill with a "+XP" pop. Gear
  drops show the piece's own art; card token drops (`LootDrop` "card_token").
- **Toasts**: lit icon medallion, achievements lead with `ach_trophy` and
  ACHIEVEMENT UNLOCKED; gear toasts carry the item art (`IconBook` also looks
  in `assets/sprites/gear/`).
- **Equip juice**: `Juice.equip_fly()` flies the piece to its slot on the
  doll (overlay, survives the tab rebuild) and rises "▲ DMG +2" arrows; used
  by gear WEAR / EQUIP BEST, suit parts and charms. `capture.gd BTN=text@f`
  presses a button for shots.

---

## 0s. Calmer right side, more ways up, paced unlocks, mission art, gear art

Owner: the right side of the screen is messy; what is the ladder (keep it,
add other ways up); balance and pace unlocks like most games with a big
"DOJO UNLOCKED" banner; unique mission picture per map on RUN instead of tiny
fighters on a big pavement; real item pictures, stat boxes, best-first lists
in gear.

- **Right-side clutter** (found in old screenshots): stacked toasts top-right,
  world labels (parkour hints, tower plaques) readable from across the map,
  neon/puddle reflections mirrored into big ghost letters, and three crude
  drawn placeholders (red box "vending" smash prop, blue drawn blessing
  machine, grey survivor shrine). Fixes: one compact queued toast
  (`Juice._toast_q`), `NearFade` (src/world/near_fade.gd) fades labels in only
  near a player, parkour gate hint range tightened, `wet_reflect.gdshader`
  sheen 0.22->0.15, pool 0.6->0.38, longer smear and less bright-boost, new
  sprites `dock/props/vending.png`, `dock/props/blessing.png`,
  `survive/shrine.png` (drawn code kept only as fallback).
- **Ways up** (`FireEscape.style`): `ladder` (fire escape, unchanged), `pipe`
  (drainpipe; son climbs 1.35x, dad 0.8x) and `boost` (dumpster + crate,
  awning, window ledge, AC box, second awning; 3.4x with springy hops).
  `RunAct._extra_ways_up()` puts one per long roof segment, as far as
  possible from ladders (>= 240 px), clear of cars, gates, shops, towers.
  `tools/ways_show.gd` renders all three side by side.
- **Unlock pacing:** `FamilyProfile.NIGHTS_FOR` - each room in `BUILD_ORDER`
  also needs N finished nights (desk+dojo 0, couch/skill tree 1, ...).
  `build_blocker()` returns "@N" for that, `blocker_text()` makes the UI line
  ("OPENS IN 2 NIGHTS"); Benny says it in camp. The night that opens the next
  room toasts NEW ROOM READY.
- **UNLOCKED banner:** `Juice.unlock_banner(title, sub, icon)` - dark band
  opens, gold rays turn behind the room/feature icon, name slams in from the
  left, "U N L O C K E D" from the right, sparks, then folds shut; queued.
  `carpenter()` uses it with the room icon; `unlock_logo()` uses it outside
  runs (in a run it stays a toast). Upgrades only toast.
- **Mission art:** `assets/sprites/missions/<map>.png` (FLUX Krea, 355x160,
  56-colour quantised, shown 2x). RUN tab header is the map name, the frame
  shows the picture with a slow push-in and a strip "MISSION n/14 · job ·
  TARGET boss"; `StageCard.art()` uses it too. Regenerate with
  `tools/mission_art.py`.
- **Gear:** `assets/sprites/gear/<id>.png` painted icons for all 17 pieces
  (`tools/gear_art.py`, green screen; green items on magenta). `GearIcon.item_id`
  shows them. Lists: owned first by `_power()` (hp 1, dmg 1.6, steam 0.5,
  spd 0.6), suit parts/charms owned+rarest first, "★ BEST YOU OWN" tag and
  an EQUIP BEST button.
- Clamp King `walk_up` sliced; other walk angles still wait for HF quota.

---

## 0r. Menus pass, weekly gauntlet, palettes, options, two polish rounds

Owner: more angles; walk every menu and sub-menu, research and add, art for
everything, deepen the game; two polish rounds (bugs, visuals, physics,
light, sound, shadows, reflections, particles, blood).

- Menus walked (tools/capture.gd now opens any hub sheet: hub:stats, jobs,
  log, profile, settings, intake). Fixed: FAMILY PROFILE text column had no
  width (one letter per line) - now a breathing portrait and a LV / rarity /
  power / title line, styled XP bar; GEAR title hidden by the role buttons;
  READY-green buttons had green-on-green text (`UiKit.dark_text`, 17 spots).
- `UiKit.title_icon(label, icon)`: header icons (new `head_*` pixel icons in
  tools/icon_pack.py) on ARMORY, CODEX, MOVES, HEROES, BUILD, GEAR,
  OPTIONS, STATS, JOBS, NIGHT LOG.
- NIGHT LOG (`src/ui/log_sheet.gd`) replaces the bare session text: stamped
  notes, a KILL TALLY mugshot wall (WANTED on the most-hit), last nights.
- DAILY CONTRACTS: job + pay icons, midnight countdown, ALL THREE bonus
  crate with a day streak (`Contracts.bonus_ready/claim_bonus/streak`).
- WEEKLY GAUNTLET (`src/app/weekly_book.gd`, SOR4-style): one seeded coping
  hour + two pacts per week (`App.start_weekly`, `App.weekly`,
  `SurvExtras.pacts()` returns the weekly pair, `seed()` in SurviveRun),
  best time / tries / weekly pay (hold 3:00: +3 gems +150 gold); a poster on
  the RUN tab (opens after THE INTAKE LOT). Leaving the map goes home.
  `WEEKLY=1` env makes tools/autoplay.gd start it.
- Hero COLOURS (`src/app/palettes.gd`): six palettes re-dye clothes not
  covered by a suit part (`pal` uniform in wound.gdshader, skin kept),
  unlocked by play; swatches over the GEAR paperdoll.
- OPTIONS > GAME: BLOOD AMOUNT (`blood_k`), BODIES STAY (`bodies_stay`,
  DeathFall.stay_secs), HIT STOP (`hitstop_k` scales hitstop + freeze),
  REDUCE FLASHES (`Juice.reduce_flash()`: no white frames / impact flash /
  lens blood).
- Polish: survivor item sort comparator re-rolled (sort broke); Party
  spawn_row deferred in physics; GunGore drip timers keyed by instance id;
  nemesis tag fades under the HUD (HudShy); MOMENTUM meter hidden in
  survivor; blood stains/pools are not left behind parked cars (they drew
  over them); DeathFall ground shadow; bodies splash and slide further on
  wet streets; wet footsteps (splash + new step_wet_1..3.ogg); cold maps
  breath puffs (BodySense._breath); exit-wound sound.
- HF: bag_snatch + bailiff walk_up/down (rescaled). clamp_king walk_up was
  garbled (two clamps) - dropped. The rest of the enemy angles are queued
  in /tmp/claude-0/ang/run_more.sh (retry.sh loops while the ZeroGPU quota
  is out); slice with video2sprite --start 1.0, then rescale like 0q.
- Known: harmless "Lambda capture at index 0 was freed" prints from older
  timer lambdas (43 sites), left as is.

## 0q. The street fights back, hurt gaits, last-kill cam, new walk angles

- DeathFall `_collide`: moving bodies stop dead on lamp posts
  (`street_lamps`, the post shivers) and parked cars (`slam_props`, the car
  rocks), bounce back (knocked up off it when skidding fast), smash through
  `smashables`, treat the screen edge as a wall (WALL SPLAT) and bowl over
  standing thugs when flying fast (`flung`, BOWLED).
- `src/actors/wound_gait.gd` (WoundGait): hurt thugs (<35% HP) LIMP (leg
  wounds: 0.55 speed, dip every step), CLUTCH (gut/blade/bullet: folded
  over, dripping), DAZED (sway); at FINISH health 40% SCOOT back on their
  backside begging (no attacks, no crowd ticket). Thugs walking over a
  settled body may TRIP (45%). Waiting thugs sometimes DRAG a body off the
  street (DeathFall.start_drag/_drag, blood smear). Poses go on `_anim`
  (rotation/position), so `visual` hit reactions still play. Note: negative
  `_anim.rotation` leans the art toward its front.
- WallMark (`src/juice/wall_mark.gd`): a round that exits paints the wall
  behind (hole + blood fan + runs); missed bullets leave bare holes. Drawn
  z 0 just before the first actor (over facades, under people), 30 max.
- Last kill: `Juice.last_kill(body)` stays slow until the body lands (max
  +1 s) and `CouchCamera.follow_body` leans the frame after it (gun kills
  via `HitReact.last_made`).
- HF Wan is back: `father/walk_up`, `punk/walk_up|walk_down`,
  `cop/walk_up|walk_down` (start frames on green from idle frame 0, sliced
  `--start 1.0..1.2 --loop --frames 12 --fps 12`). All up/down clips
  rescaled to the side walk's figure height around the feet
  (`/tmp` script logic: median bbox height ratio; son and father were ~8%
  and ~17% off). Punk picks `walk_up/down` like the heroes.
- `tools/death_show.gd` wave 3 (lamp, car, wall), `tools/wound_show.gd`.

## 0p. Real falls: DeathFall physics, bullet exit wounds, hero falls, declutter

The owner: every kill looked the same; bullets should make holes, some go
through and bleed out the far side, some stay in; the heroes too; bodies
must lie on the ground, never overlap, with real gravity; the right side of
the map was busy.

- `src/juice/death_fall.gd` (DeathFall): a dead body is a stiff rod (H long,
  T thick, measured from the painted part of the frame, `HitReact._used_rect`
  - mind AtlasTexture `margin`) with its centre of mass over the street.
  Flight on gravity (G 1250) with spin and up to two bounces; on its feet it
  topples about the feet like a felled tree (inverted pendulum, 1.5 G/H
  sin); flat it skids on friction with dust, then settles, rolls up/down the
  lane if another body lies there (`_make_room`), drops under the living
  (z 0, moved before the first actor) and bleeds a pool. Scripted beats
  before the physics: sag (knees), jolt (rounds landing), pirouette (hooks),
  clutch, hold.
- `DeathFall.pick()` chooses the fall: zone + move clip + melee weapon +
  round (weapon/zone/dist) + power. 17 styles: crumple, faceplant, topple,
  timber, spin, launch, knockback, sweep, stagger, headshot, blown, kneel,
  legs, blast, homerun, burn, decap, plus the old drawn `death` clip now and
  then. `HitReact.corpse(..., style)` builds it (`_fall`); Punk._die and
  GunGore pass the style; GunGore's flying pieces and neck fountain follow
  the falling body.
- Rounds: `Round._through_chance()` (revolver 0.85, pistol 0.5, SMG 0.35,
  pellets point blank 0.3, head/legs +0.15, gut -0.1; nails/flares stay in).
  A round that goes through keeps flying (x0.55 damage, x0.8 speed, max two
  bodies). `Punk._shot["through"]` drives GunGore: through = exit spray
  forward + a torn exit hole (`BloodSim.add_hole(..., exit=true)`, the
  shader reads a .5 x fraction as exit: wider, ragged, longer run); lodged =
  back-spurt out of the entry hole and a drip.
- Heroes: hurt reacts by height (head / gut / new `trip` / bullet); hero
  bullets 50/50 through or lodged with exit holes; knockdowns vary (30% or
  big blows launch into a gravity arc with a bounce, varied slide); going
  down plays the knockdown fall and then LIES on the street (`LIE_FRAME`
  son 12, father 9) instead of standing in the hurt pose.
- Declutter: SecretStash titles are world-scale (0.5) and fade in only near
  a hero; the MOMENTUM meter fades out when idle; `_spread_props` runs after
  everything is placed, includes WheelToken and keeps loot 70 px off parkour
  gates; drops are added deferred (no physics-flush errors).
- `tools/death_show.gd` renders the 24-fall showcase (run with
  `--fixed-fps 60`, otherwise the slow renderer makes time jump).
  `tools/suit_show.gd` renders the suits parkour film.

## 0o. Codex, guides, survivor depth, rewards desk, loot, throwables, walk angles

Round 2 of the owner's list (see HANDOFF "Round 2"). Everything below is on
`claude/gallant-galileo-5ctrmf` with tests green (smoke / focus / reset,
combo_test all COMBO_OK).

- **Stat colours**: `UiKit.delta_bb(old, new)` white/grey base, green up,
  red down ("x1.05 > x1.15"); card meters grey with the gain in green.
- **Codex discovery** (`src/app/discover.gd`, `src/ui/codex_sheet.gd`): first
  meeting with a thug, boss, weapon, ability, gear, part or place files an
  entry (toast + red dot); CLAIM pays gold/gems, +3 gems every 10.
- **Guided first use** (`src/ui/guide.gd`, `guides.gd`): dim + spotlight +
  speech bubble with Dad/Kid bust, A next / B skip, saved in `guides_done`.
  Every menu and new feature has steps (`Guides.STEPS`). Build order for the
  camp is fixed (`FamilyProfile.BUILD_ORDER`, "BUILD X FIRST").
- **Survivor (Jotunnslayer-style)**: starter weapons with level / mods /
  merge-to-rarity (`surv_starter.gd`, `starter_sheet.gd`), 10 challenges
  that open starters (`surv_challenges.gd`), missions every 70 s + champions
  (`surv_missions.gd`), boss/mission chests (`boss_chest.gd`), and
  `surv_extras.gd`: SHRINES (stand 3 s, pick 1 of 3 blessings), RAMPAGE,
  PACTS (harder hour, more S-COINS; toggled on the starter sheet), CURSED
  CHESTS, evolution FORECAST. Paperdoll got NECKLACE + RING slots.
- **Brawl / parkour extras**: `brawl_more.gd` (FINISHER on low-HP staggered
  thugs, impact frames, screen kill, steam refund, combo bursts);
  `parkour_more.gd` (repo-agent pursuer, BIG AIR letterbox, momentum, rings,
  STYLE grade D-SSS).
- **Rewards desk** (`src/app/reward_book.gd`, `src/ui/rewards_sheet.gd`): gift
  button in the hub top bar with a count; DAILY CRATE (7-day streak),
  CLINIC ROAD (a reward per account level, chest every 5th), CLAIM ALL across
  crate / road / codex / jobs / awards, TITLES (worn under the names),
  POWER rating that counts up in the header (+N) with a breakdown.
- **Loot** (`src/extras/loot_book.gd`): story bosses drop a chest (2 finds,
  minis 1) - a move, a gun part, a suit part or throwables; secret stashes of
  kind "loot" (8 new in `data/secrets.json` `_extra`).
- **Throwables** (`src/extras/throw_lob.gd`): SHOOT + up lobs grenade,
  molotov, flashbang, brick or teargas in an arc; shown in the HUD.
- **Five new level-up cards** (`data/cards.json`, `item_rack.gd`): BRASS
  KNUCKLES, VAMPIRE TOOTH, TIE BOOMERANG, HEAT WAVE, THROWING BAG (icons in
  `tools/icon_pack.py`).
- **Walk angles**: `son/walk_up` (three-quarter back), `son/walk_down`,
  `father/walk_down` from Wan 2.2 image-to-video on HF ZeroGPU
  (`zerogpu-aoti/wan2-2-fp8da-aoti-faster`, start image = the hero's own
  idle frame on green, 720x900) sliced with `tools/video2sprite.py --loop
  --start <s> --fps 12` (Son: `--stand 199 --stand-frame 0`, Father:
  `--scale-ref assets/sprites/father/walk.json`). Fighter picks them when the
  move is mostly up/down the lane. **Still missing: `father/walk_up` and the
  enemies** - the ZeroGPU quota ran out (calls are cancelled at once);
  Sorceress has no credits left (402). Retry the same script later.
- **Hit reactions** (`src/extras/impact_feel.gd`): head shots snap the head
  back, gut shots fold, uppercuts lift, sweeps take the legs; kicks push and
  kick up dust; big hits get a ring, speed lines and a directional camera kick.
- **Crowd AI** (`src/actors/crowd_ai.gd`, hooks in `punk.gd`): two attack
  tickets per hero on story streets; the other thugs hold a ring round the
  hero (front, behind, up and down the lane) until a ticket frees up;
  attackers line up in depth; a thug blocked by a crate or car detours up or
  down the lane. Survivor hordes, bosses, vehicles and shooters are exempt.
- **Pause > MOVES & COMBOS** (`run_hud.gd` `_move_list`): the hero's own
  button loadout and every learned combo with pad/keyboard prompts.
- **GO arrow** (`brawl_more.gd` `GoArrow`): blinks at the right edge after
  2.5 s with no thug within 700 px (story streets only).
- **Fixes**: KitBook dropped `hp_mul` (horde/story HP scaling); survivor
  arenas were cluttered (bystander behind the parked car, vault prompt,
  three pickups per kill); card picks now hold the pause (a stage card
  closing underneath unpaused, so thugs hit you while choosing); HUD hero
  line auto-fits; REP pill no longer cut off; boss charge lane redrawn.
- **Tools**: capture.gd env `REWARD`, `UPFX`, `PRESS`, `SURV_IDS`,
  `SURV_MISSION`, `SURV_SHRINE`, `GUIDE`, `THROW=kind@f`, `CHEST=f`,
  `STICK=x,y@f`, `ITEMS=a,b`, `DUMP=f`; targets `hub:rewards`,
  `hub:starter`, `hub:codex`, `hub:sgear`. autoplay.gd skips guides and
  takes cards itself.

## 0n. Sprite icons, reward fly-up, gunsmith bench, paperdoll, sprite cards

- `tools/pixkit.py`: pixel-art kit (5-step hue-shifted ramps, rim light and
  shade per part, sphere shading, selective outlines, glints).
  `tools/icon_pack.py` draws every icon at 32x32: currency (+16 px flying
  coins), all 56 story cards, survivor gear, slot silhouettes, gun parts,
  skill nodes (all three trees), META upgrades, card-tag emblems, and
  redraws the 54 survivor ability/trait/item/ultimate icons in place.
- `IconBook` (src/ui/icon_book.gd): where each thing finds its icon
  (for_card / for_node / for_meta / for_gear / for_part / for_glyph) and
  `rect(name, px)` for a nearest-filtered TextureRect. Sizes are whole
  multiples of the pixel grid: SIZE_S 128/3 (2 screen px a texel), SIZE_M 64,
  SIZE_L 128. PixelIcon draws the sprite when one exists, so every old glyph
  (currency pills, HUD purse, badges) is now a sprite.
- `RewardFly` (`Juice.rewards`, src/juice/reward_fly.gd): `give(key, amount,
  from)` pops the icon in with rays, counts the number up with ticks, then
  bursts into coins that arc to the counter registered for that key
  (`register(key, control)`); counters show `balance - pending(key)` and
  tick up on `landed`. `upgrade(control, color, text, big)` is the reward-grow
  juice (punch, flash, ring, sparks, rising text, chime/boom), `deny()` shakes
  and buzzes, `reveal()` is the loot reveal for boxes/fuses. Juice.give /
  Juice.upgrade_fx / UiKit.fx_after(root, key, ...) wrap them. claim_burst and
  fly_pills go through it (they used to aim off-screen). Hub pills, the run
  HUD purse, the gunsmith gem wallet and the gear S-COINS wallet are targets.
- `tools/synth_ui.py` -> assets/audio/ui: coin_tick, coin_land, gem_land,
  reward_pop, whoosh, up_rise, up_boom, part_slide, part_click, part_off, deny.
- Gunsmith: `tools/gun_parts.py` makes 14 side-view part sprites at the guns'
  texel scale with anchors; guns.json gains rail/under/mag/window mounts
  (tools/gun_art.py). `Attach.layout()` places them (a muzzle device sits at
  the end of a long barrel), `dress()` puts real sprites on the held gun.
  `GunView` is the bench (pegboard, gun big at whole pixel steps, markers on
  open mounts, padlocks on shut ones; `fit_anim` slides a part on and clicks
  it home, `off_anim` pulls it off and drops it, `preview` shows a ghost).
  `gunsmith_sheet.gd` = bench + stat bars with green/red deltas + part tiles.
- Survivor gear is a paperdoll (`surv_gear_sheet.gd`): the Kid lit in the
  middle, slots joined to the body by lines, cap on his head, charm in his
  hand, totals as stat icons, tiles in rarity frames, details with deltas,
  S-COINS fly out on buys, box/fuse open into a reveal.
- META rows have their icon in a socket; upgrade juice on meta, hero level /
  rarity, skill nodes, moves, element arts, weapon levels, locker gear, camp
  builds.
- Cards: `tools/card_art.py` -> assets/sprites/cards: story frames per rarity
  (bevelled metal, studs, filigree, emblem socket, sunk art window with baked
  glow, ribbon plate, rarity gems), backs, survivor ID-badge cards (enamel
  header, lanyard slot, punched holes, hazard foot) and glow masks. PixelCard
  draws the sprites with the thing's own icon; lit cards rise (card_pick) and
  glow in the rarity colour with sparks running the edge. survive_pick uses
  the badge cards; the focused one rises and glows.
- Survivor weapons: BADGE BOOMERANG, SHREDDER BLADE, FAX BEAM, RUBBER STAMP,
  and MANUAL (SHOOT with empty hands): NAIL DRIVER (hold), PAPERWEIGHT (tap).
- Capture: REWARD=key:amount@frame, UPFX=frame, PRESS=part@frame (gunsmith),
  SURV_IDS=a,b (ui:surv), new target ui:spick.

## 0m. Element arts, grabs, team attacks; feedback pass

- Feedback: Bevel 3D overlay off (`Bevel.ENABLED`), plain frames back. Heroes
  bigger in the hideout (CAMP_K 1.6), title (2.3) and HEROES cards. Lamps 2.9x,
  `AmbientProp.SIZE` for cones/drums/barriers/sodium lamps, vault crate 0.6.
  Intake Lot roof + ladder removed. Viewpoint towers clamped to 56-72% of
  map_w (street towers only). Hideout sawhorses gone. `NightStreet.pixel_roof`
  draws coping + vents + a brick face to the lane; `roofs_strip` painted
  skyline (FLUX, tools/street_strip.py, texel 0.42). LightRig `_glow` is a soft
  radial sprite.
- `Elements` (data/elements.json): 4 arts per hero (dir N/F/U/D), CHI cost,
  levels 1-5 for gold, EVOLVE for 25 gems; 3 grabs per hero; 3 team attacks.
- `ArtMoves` (child of every Fighter, runs first): L+H together -> grab if a
  thug is within 48 (not bosses), else the art for the stick direction; hold H
  + tap SPECIAL with TEAM full -> team attack (partner puppeted, or a phantom
  of the other hero runs in when solo). `Fighter.art_lock` owns the body.
  CHI from hits (`gain_hit`) and kills (`gain_kill`, also TEAM; partner gets
  an assist). Meter arcs drawn under the feet.
- `ElementShot` (ball / tornado / wave) and `ArtFx` (orb, ring, pillar, cone,
  bolt, streak, burst, cracks) are code-drawn additive effects.
- `CouchCamera.punch(tree, amount, secs, at)`: zoom swell toward a point.
- MOVES -> ELEMENTS page (unlock / level / evolve, grab + team list).
- Capture: `art:<art|grab|team>:<id>[:father]` on Dock Street; `hub:moves_el`.
- Dojo TUTORIAL (`DojoSchool`, 13 lessons, `TrainingDummy.struck`), gold once
  per lesson (`school_paid`) + graduation bonus.
- CouchCamera kept overwriting `limit_right` with 3200 in `_ready` (black past
  the ground at the map end) - fixed. Feet occluders use light mask 2.
- GUNSMITH (`Attach`): 5 slots per gun (muzzle/optic/barrel/mag/ammo), 14
  parts bought once with gems, slots open with gun level; drawn on the gun
  (can, scope/red dot, drum, long barrel, laser line). Old gun mods migrate.
- Throwing knives (`ThrowKnife`): THROW with nobody in reach, 2 per night,
  max 6, misses and 8% thug drops lie on the street to pick back up.
- Level-up cards: every card shows a KIND badge (PixelCard.KINDS: PASSIVE /
  ACTIVE / COMPANION / AUTOWEAPON / MANUALWEAPON) and LV / UPGRADE LV.
  14 item cards in data/cards.json ("kind", "max_lv", "lv" texts) level to 3
  when picked again (RunState.card_lv, RunState.offerable). `ItemRack` (one per
  run) runs them: passives as static multipliers (dmg_k, speed_k, chi_k),
  paperboy/repo drones, stapler orbit, molotov lobs, stray cats, pigeon
  sweeps, AIR HORN / SMOKE BOMB actives and the SLINGSHOT on SHOOT with
  empty hands (`ItemRack.shoot`). Survivor pick cards carry the same badge +
  rarity line.
- 40 additions (#94): `BrawlPlus` (backstab, interrupt, juggle scaling, taunt
  on double-tap DUCK, clutch, flinch, prop slam vs lamps/cars "slam_props",
  perfect dodge, together aura + tether, last hit). `ParkourPlus` on roof maps
  (speed lines, afterimages, best-run ghost "ghost_<map>", split times, 5
  graffiti tags, air time FLOW, heavy landing dip, precision pads, medals
  "medal_<map>", wall-run sparks). Menus: hub ticker + NEXT GOAL, living
  header portraits, pentatonic focus ticks, `UiKit.hold_confirm` (evolve,
  rarity), pause BUILD list, run history (STATS), title LAST NIGHT line,
  stage-card tips, parkour RECORDS in BUILD. Survivor's ten go into the
  survivor depth pass (#99). Fire Escapes alley got its cobbles.
- Survivor depth (#99): S-COINS (`SurvCoin`, `SurviveRun.coins`, label via
  `Trees.cur_label`), `SurvGear` (4 slots, 18 pieces, rarity/levels/fuse/box,
  BUILD › SURVIVOR › SURVIVOR GEAR sheet), `LuckyWheel` (+ `WheelToken`) in
  all modes, STARTING DRAW (story) / TALENT DRAW (survivor), roof chest on
  parkour maps, `SurvEvents` (golden thug, bounty, encircle, supply drops,
  milestone chests, panic cry, edge arrows), LIMIT BREAK, DPS share on
  results, harder scaling, six new survivor tree nodes (s_boxes, s_four,
  f_gear, f_wheel, u_limit, u_start2).
- Per-map things: race clock on roof maps, survivor map events (tow truck,
  talking stick, now serving, blizzard, audit); item-card STARTING DRAW.
- `BodySense`: body separation, roof/thug footsteps, parkour sounds.
- Skill nodes: own sprite icon each (`NODE_ICON`); deep trees squeeze rows.
  MOVES › LIBRARY previews the highlighted strike on the hero.
- Windows installer rebuilt and pushed. **Next agent: read
  docs/HANDOFF_NEXT_AGENT.md** (owner's message and what is wanted next).

## 0l. Bosses, three trees + metas, survivor depth, weapon mods, night extras

- **Grounds**: `tools/ground_art.py` paints `lot_ground`, `concrete_floor`,
  `clinic_floor` `_road(_wet).png` (oblique floors that tile sideways).
- **Bosses**: `src/actors/boss_brain.gd` + `boss_fx.gd`, data `data/bosses.json`
  (per boss: hp_mul, move names, moves per damage stage). Moves: charge,
  slam, volley, rain, summon, lane_wave, grab, spin. Zones fill then strike;
  `Fighter.take_hit("crush")` is unblockable (roll/jump/step out), every
  pattern ends OPEN (+50% damage, `BossBrain.PUNISH_MUL`). Base enemy
  hp x1.12 / dmg x1.15 (`Heroes.enemy_*_mul`); boss attempt bonus in
  `RunAct._on_fail`. Capture `ui:boss_<move>`.
- **Weapons**: `Arsenal` levels (1-5, gold) and `MODS` (gems, slots 1/2);
  `power_mul`, `clip_mul`, `reload_mul`, `on_hit` (Punk.take_hit). ARMORY
  shows LV / MODS bench / CARRY (needs META starter kit).
- **Three trees / three metas**: `src/app/trees.gd` (brawl = cbt.json,
  survivor = data/tree_survivor.json TOKENS, parkour = data/tree_parkour.json
  FLOW); `hub_build.gd` mode tabs + REFUND TREE. `Meta.BRANCH_CUR` (body
  gold, survivor tokens, parkour flow). Flow from `FamilyProfile.mark_trick
  / mark_perfect / mark_wallkick / note_tower` (+ `_trick_perks`); tokens
  from `SurviveRun.award_tokens` (fail + clear). Parkour perks in Fighter
  (coyote, air jump, float, hang, roll, stomp chain, `_land_perks`).
- **Survivor**: data/survive.json now has 17 abilities (7 gated by tree
  `unlock`), 15 traits, `evolutions` (LV 7 + item -> chest offers EVOLVE),
  `ultimates` (kills charge `ult_charge`, SPECIAL fires `fire_ult`). Meta and
  tree effects in `SurviveRun` getters; icons `tools/survive_icons.py`.
  CODEX sheet (`src/ui/codex_sheet.gd`): bestiary + boss dodge guide,
  abilities, evolutions, ultimate loadout, records. Capture `ui:surv`.
- **Night extras** (`src/extras/night_extras.gd`): blessing machine, tax
  refund runner, combo milestones, street events; screen-edge wall bounces
  in `Punk._fling`. **Menus**: `Artifacts` (RUN tab), `Contracts` (JOBS),
  desk sheet `src/ui/desk_sheet.gd`. Capture `ui:extras`, `hub:jobs`,
  `hub:codex`, `hub:build_surv`, `hub:build_park`.
- Crew NPCs scale to NPC size on street maps; waiting room uses benches.

## 0k. Hero levels + rarity, gear combine, META, new road, polish

- **Heroes** (`src/app/heroes.gd`, HEROES tab `src/ui/hub_heroes.gd`): level
  with gold (cap 10 + 5 per rarity), rarity common->legendary (grey, green,
  blue, purple, orange; `Rarity.color`) with character shards at the cap
  (`SHARDS`, `RARITY_GOLD`). Save keys `hero_son` / `hero_father`.
  HP + damage + speed bonuses read by `Fighter._ready` and `Punk.take_hit`
  (`Heroes.dmg_mul`, also for gadgets and guns via owner_role). Base HP 80.
- **Shards / gear drops** (`Punk._progress_drops`, `LootDrop` kinds
  `shard_son`, `shard_father`, `gear`; art `tools/loot_art.py`): thugs 5%,
  elites 50%, bosses always, +3 per secret stash. Gear parcels drop a random
  piece at its base rarity (10% one up). Rare loot gets a light pillar.
- **Gear rarity** (`src/app/gear_inv.gd`, save `gear_inv` = counts per
  rarity): three alike combine into the next rarity; best copy is worn;
  rarity x1.35 stats per step above base, level cap 3 + 2 per rarity;
  `FamilyProfile.gear_price` buys copies.
- **META** (`src/app/meta.gd`): BODY (vitality, strength, second wind,
  fortune, shard sense, scavenger, starter kit, spare life) and PARKOUR
  (spring legs, wall runner, air control, flow state, iron ankles; ranks
  need lifetime tricks). Effects wired in fighter / loot / run_state.
- **Roguelite tuning**: `Heroes.enemy_hp_mul` (+13% a map along
  `App.ORDER`) and `enemy_dmg_mul` (+7%); clear gold 30 + 10/map + scrap/4;
  more coins. Results show run shards and a tip after a death.
- **Road**: `tools/road_art.py` -> `assets/backdrops/street_road(_wet).png`,
  one 480-unit-wide image from the kerb down, tiling only sideways;
  `WetStreet` uses `<ground>_road.png` when present, plus lamp light pools.
- Capture modes: `hub:heroes`, `hub:locker_gear`, `ui:loot`.

## 0j. Suits in three parts, five new weapons, ARMORY, polish

**Suits in parts (what / how / why).** Every suit (Bat, Spider, Shaolin,
Ninja) is now MASK + TOP + BOTTOM, each unlocked on its own, mixable, with a
set bonus when all three match. `src/app/suits.gd` holds the data
(`LIST[suit].parts[part]` = title, perk, how, stats; `set`), the save keys
(`suit_parts` owned list, `suit_<role>_<part>` worn) and `_migrate()` for old
whole-suit saves. The wound shader paints per body region (`suit_head`,
`suit_body`, `suit_legs`; legs below `hv.y > 5.2` head radii).
- Perks live in `Fighter` (`suit_part()`, `suit_set()`, `refresh_suit()`):
  bat mask BATWING boomerang (`KitShot.boomerang/pierce`), bat top glide +
  double jump with a drawn flapping cape (`src/actors/cape_fx.gd`, also the
  cowl ears), bat boots BAT DIVE; spider mask dodge 20% (`_sense_dodge`),
  spider top web snare, spider legs jump + WEB SLAM; shaolin head steam x2,
  robe parry +50%, wraps HUNDRED KICKS; ninja hood 3 shuriken, gi vanish
  dash, tabi SHADOW STEP. Sets: bat +20% dmg (Punk.take_hit), spider 40%
  dodge, shaolin -30% damage taken, ninja smoke bomb stun.
- Gadgets fire on THROW when nobody is in grab reach; specials replace the
  default SPECIAL when a bottom is worn. Effects: `src/juice/suit_fx.gd`
  (ring, web, smoke, kick arcs, ghost, slash). New sfx via MMAudio.
- GEAR (`hub_locker.gd`): MASK/TOP/BOTTOM slots, SET meter, one-press full
  sets, part pictures from the idle frame framed per part.
- Unlock counters: `wanted_claimed` (run_act bounty), `side_jobs_done`
  (quest_giver), checked in `Suits.check_progress()` after every save.

**Weapons.** New melee: `baseball_bat`, `machete`, `sledgehammer`
(data/weapons.json `reach`, `slow`, `blurb`); new guns `revolver` (pierces one)
and `flare_gun` (Round kind `flare`, `FireFx`, `Punk.ignite`). Kill
reactions in `Punk._die`: HOME RUN corpse flight, FLATTENED crush,
`GunGore.decap` for the machete, charred `burn` corpse.
- Melee is drawn in the hand now: `tools/held_art.py` -> `assets/sprites/held/`
  + `held.json` (grip/tip); `Fighter._place_melee` rides the frame's leading
  hand (`_front_hand`) and swings by strike phase with an additive trail.
- `src/app/arsenal.gd`: weapons found, kills per weapon, MASTERY (25 kills =
  +15% dmg), melee durability (`USES`, breaks with splinters / bent metal).
- ARMORY sheet (`src/ui/armory_sheet.gd`, hub header), ARSENAL & SUITS stats
  section, weapon of the night on results, LOADOUT in pause, weapon + ammo /
  hits left on the HUD, set toast at the start of a night.

**Polish.** Per-weapon contact (sparks / splinters / red slash / sledge
ring), revolver + flare muzzle flashes and smoke, water splashes where
bullets come down on the wet street.

**Capture modes added:** `ui:suit_<id>` (gadget, double jump/glide,
special), `ui:gun_<melee id>` (melee string), `hub:armory`.

## 0i. Music per place, ElevenLabs voices, four suits, paperdoll GEAR

- **Music** (`tools/ace_music.py`, ACE-Step HF Space, free): assets/audio/music/
  music_dock (the player's own track, Dock Street), music_survive + music_boss
  (metal psytrance styled after it via audio2audio - trim the reference to
  the wanted length or the output is padded with silence), music_menu (title,
  hub, films, results), music_shop (Mixer.push_music/pop_music while a shop
  is open), music_camp. Mixer prefers assets/audio/music/<name>.ogg.
  ElevenLabs music needs a paid plan.
- **Voices**: all lines via ElevenLabs (`tools/eleven_vo.py`, key in
  ~/.config/elevenlabs/key or $ELEVENLABS_API_KEY - never commit; free tier
  10k chars/month, ~3.5k used; library voices like "Rai" are 402 on free).
  New `attack` event: VoBank.attack() on every enemy swing.
- **Suits** (src/app/suits.gd): bat / spider / shaolin / ninja, wearable by
  either fighter, stats added in gear_stat_bonus, perks read via
  Fighter._suit. Unlocks: Gant (bat, spider), 3 dojo masters (shaolin), 3
  stashes (ninja) via Suits.check_progress().
- **GEAR** (src/ui/hub_locker.gd): paperdoll with live fighter, slot boxes,
  GearIcon pixel pictures, green/red stat deltas. Capture: hub:locker.

## 0h. Clean reset, guns, full audio pass, COPAY + bowling 

- **Reset**: Options -> RESET GAME PROGRESS deletes the save, every backup,
  open_room.json and photos, keeps gfx/vol_ options, restarts the game
  (`FamilyProfile.reset_progress()` + `restart_clean()`, tests/reset_test.gd).
- **Bounty crown** rides the measured head per frame; floor (WetStreet z -3,
  blood -1) draws under the actors (a lamp streak used to paint over faces).
- **Guns**: mags + reserve (`Fighter.RELOAD`, `gun_reserve`, `start_reload`,
  `_tick_reload`); shotgun feeds shells, a shot cuts the reload, pump ejects
  the shell; per-gun recoil climb/slide in `_place_gun`; `GunFx.mag`,
  `GunFx.ricochet`, shadow-casting muzzle light (feet LightOccluder2D on
  fighters and punks), flashes last >= 3 drawn frames. Capture:
  `ui:gun_<id>`.
- **Audio**: Sorceress credits ran out -> voices with Kokoro offline
  (`tools/kokoro_vo.py`, voice map inside), effects with the MMAudio HF Space
  (`tools/mmaudio_sfx.py`). New events: `effort` (VoBank.effort on swings),
  `banter` (RunAct._banter), `reload`, `death`, NPC `talk`, bystander `react`,
  new enemy speakers in `VoBank.who_of`. Footsteps x4 + breathing, jump/land,
  whiffs, flips, wall kick, glide, kill thump + body fall, bullet flesh,
  breakables by material, coping hour music. Every referenced audio path
  exists (check: grep res://assets/audio in src vs files).
- **COPAY** (`Fighter.copay`): half of each hit is billable, drains after
  1.2 s at 6/s, landing hits refunds it; gold-glowing hearts in the HUD.
- **Bowling**: `Punk._fling` knocks over and damages thugs in its path.

## 0g. Scale, colours, misses, economy, more HF faces, project skills 

- **Project skills** in `.claude/skills/`: godot-dev, beat-em-up-feel,
  pixel-art-sprites, parallax-backdrops, game-economy. Read them first.
- **60 fps**: render capped at 60 (`Gfx` default `fps_cap` 60,
  `application/run/max_fps=60`) to match the 60 Hz physics.
- **World scale**: measured against painted doors/kerb/bike the people were
  ~20% small. `SpriteBook.ACTOR_K = 1.25` scales fighters/enemies/quest
  givers; strike boxes (`Fighter._spawn_hit`, hop compensated), hurtboxes,
  body capsules and enemy swing range follow; walk speed +10%; street lamps
  x1.9; road stones smaller (`WetStreet.TEXEL 0.09 / 0.048`). Cutscenes keep
  `FILM_SCALE` 1.12.
- **UI**: `PixelIcon` centres a glyph by its real pixels; `UiKit.stat_bbcode`
  / `UiKit.rich` colour gains green and costs red on level-up cards; card
  names have their own colour (`PixelCard._name_col`).
- **Miss vs hit**: a blow the enemy blocks/clashes sets `Punk.blocked_last`
  and the fighter plays `_strike_blocked` (spark, clack, push) instead of the
  full impact; timing-ring misses deflate instead of shaking.
- **Economy**: gems now buy BUILD capstones (`"gems": 1` in cbt.json for
  rep-4 nodes) and dojo master rank (`FamilyProfile.dojo_gem_cost`); halfway
  cart prices x0.45 (were 3-5x a permanent node). All cart buffs verified to
  be read by gameplay.
- **HF**: Roof Runner and Bag Snatch have their own sprites (were the punk);
  Valet death + high/low attacks; Bailiff mid baton + low kick.

## 0f. Two polish rounds: punch, maps, menus, more HF art 

**Combat feel**
- Son strike boards had no contact frame, so hits landed 0.05 s in while the
  drawn fist arrived ~0.35 s later. `tools/strike_timing.py` (idempotent,
  marks `"timed": true`) sets `hit`/`fps`, drops off-model grey-hoodie frames,
  trims long extended holds and closes the cross back to guard. Father
  slide/dive got hit frames too.
- `Juice.kick(dir, px)`: directional camera shove, springs back in world time
  (holds through hitstop). Used on every connect, on kills and when hurt.
- Fighter squash/stretch is live again on the sprite path (`_sq`,
  `_squash_to()`); `Juice.squash()` routes to it. Hits stretch into the
  blow, landings and getting hit crumple.
- Enemy hit-shake + head snap (`Punk._recoil`), heavy input buffered through
  recovery (`_heavy_buf`), short freeze + shove on every kill,
  `Juice.last_kill()` slow-mo on the last thug of a fight (not in the horde).
- Lens blood is a rare edge accent (3.5 s cooldown, max 3 blobs, outer edge).

**HUD / menus**
- Toasts at (960, 92), max 2. Combo counter big, bottom-left, kicks per hit,
  colour heats with the count. Pause shows only meaningful rows in solo.
- Character select: explicit-size dim (title art no longer shows through),
  picked card lifts, other dims. BUILD: dark well behind the trees, info
  strip under them. Tab alerts: one dot on CLINIC only; locked tabs dim.
- Hideout: room continues past the painting (mirrored strip) so the portal
  is in a corner, not a void. Room sheets open centred over a dim.
- Level-up picks: centred, compact, DMG/cooldown line, dealt in, focus lift.

**Maps**: painted road lifted (modulate 1.5) with a near-edge shadow; steam
is soft radial vapour (street life + manholes).

**HF art (Space back up)**: deaths for Coping Imp, Clipboard Flier, Lot
Hydra, Clamp King; high/low attacks for Imp, Flier, Hydra (contact frames set
by eye where the held prop fooled the reach heuristic); drawn idles for the
three Dock Street side-job givers (`"sprite"` key in side_quests.json).

## 0e. Start flow, economy, side jobs, tower, coping hour, five new systems 

**Svenska:** PLAY GAME → välj karaktär (solo / soffa / online med guide för två
städer, resten mörklagt tills Dock Street är klar) → START · DOCK STREET →
introfilm → stage-bild med namn → spelet. Fiender större, gången synkad mot
animationen. XP-kristaller och mynt från fiender, XP-MAGNET i BUILD, en
uppgraderingsvagn halvvägs på varje bana (för dyr på första). Sidouppdrag från
folk på gatan (gult !). I tornet sitter de på räcket med benen över stupet,
kameran tittar ner. Parkour går igenom alla trick. Överlevnadsdelen är nu
Halls of Torment-djup. Fem nya system: nattens villkor, miljödödningar,
nemesis, Rufus hämtar, kombo-rank ger mer loot. Lokal animationsmaskin för
Ally X i tools/local_gpu.

- **Start flow**: `src/ui/character_select.gd` (from title PLAY GAME),
  `src/ui/stage_card.gd` (every story stage, after any film), intro film goes
  straight to Dock Street (`intro_flow.gd`).
- **Scale / stride**: `SpriteBook.FIGHTER_SCALE` 1.12, `ENEMY_SCALE` 1.25,
  `SpriteBook.grow()`; `SpriteBook.stride_rate()` drives walk / run playback.
- **Economy**: `src/world/xp_orb.gd`, coins via `LootDrop` from `Punk._drops`;
  `Fighter.xp_magnet()`; cbt node `xp_magnet`; `src/world/shop_cart.gd` +
  `src/ui/cart_sheet.gd` + `data/cart.json` (buys in `RunState.buffs`).
- **Side jobs**: `src/world/quest_giver.gd`, `quest_item.gd`,
  `data/side_quests.json`, `MissionHud.quest_line()`, NPC recolour
  `src/shaders/npc_tint.gdshader` until NPC art lands (queued).
- **Tower**: real sitting pose (`tools/sit_pose.py` → sit_*.png parts,
  `FilmActor.sit_at(p, face)`), look-down shot, gulls, sway.
- **Parkour**: gates cycle the learned repertoire (`ParkourGate._shown`).
- **Coping hour**: `data/survive.json`, `src/survive/survive_run.gd`
  (build/levels/picks/well), `survive_ability.gd`, `surv_proj.gd`,
  `survive_pick.gd`, `survive_hud.gd`, `horde.gd` (phases, elites),
  icons from `tools/survive_art.py`. Punk hit kind `"skill"`.
- **New systems**: `night_condition.gd`, `hazard.gd`, `nemesis.gd`, Rufus
  fetch in `dog_buddy.gd`, rank multiplier in `Punk._drops`.
- **Art**: Repo Goon + Bailiff animated (FLUX + Wan), cop death.
- **Combo test**: run it headless (`--headless`); under xvfb the slow
  renderer stretches the button holds past the chain window and it reports
  false misses.
- **Local GPU**: `tools/local_gpu/` (README in Swedish).

## 0d. Menus audit, new enemies, the GPU queue (latest)

**Svenska:** Alla menyer och undermenyer genomgångna med skärmdumpar (titel,
options, credits, alla hubb-flikar, statistik, gömstället, dojo, resultat,
kort, paus). Fixat: varje dojo-move och combo visar sin egen pose; kistor
ritade för AWARDS; radiotornet har riktig bild; paus är en ram med OPTIONS.
Två nya fiender på Dock Street: Repo Goon (vanlig) och Bailiff (elit, västen
tar kulor i kroppen, sikta på ansiktet). Deras animationer väntar på HF-kvoten.

- **Dojo icons**: `SpriteBook.move_icon(who, clip)` crops the clip's hit frame;
  `dojo_sheet.gd MOVE_ART` maps every school move to a clip, combos use their
  own finisher clip.
- **Chests**: `tools/chest_art.py` makes `assets/sprites/hub/chest_{locked,ready,open}.png`;
  `hub_awards.gd` shows them above the buttons (ready ones bob).
- **Pause** (`run_hud.gd _toggle_pause`): framed card, OPTIONS opens the
  settings sheet while paused. `tools/capture.gd -- ui:pause out.png` shoots it.
- **Repo Goon / Bailiff**: `data/kits.json`, `party.gd` speeds, `encounters.json`
  (dock_street now 5 solo / 9 co-op; smoke test updated), vest logic in
  `punk.gd` gun damage. `_sprite_who` uses `assets/sprites/repo_goon|bailiff`
  as soon as `idle.json` exists; until then they draw as the punk.
- **GPU queue**: `tools/hf_batch.py` (copy of /tmp/claude-0/hfv/batch.py):
  cop death, FLUX designs, 7 clips per new enemy, map 2 deaths and attack
  clips. Start images for map 2 enemies are their idle frame scaled onto
  green 832x672. ZeroGPU Pro is ~25 min/day; a clip is ~41-69 s.

## 0c. Guns: held in the fist, five weapons that fire differently, gunshot gore (latest)

**Svenska:** Alla skjutvapen hålls i handen och skjuter på riktigt. Fem vapen
som varken beter sig eller ser likadana ut: pistol (nästan osynlig het strimma),
hagelgevär (svärm av små grå hagel, rött patronhylsa), kpist (auto, tunna
strimmor), spikpistol (synlig spik som fastnar i kroppar och väggar) och
FINAL NOTICE (påhittad: långsam pulserande röd bläckboll med kvittoremsor som
går genom alla). Sikta med spaken: upp = huvud, ner = ben, annars bröst.
Huvudskott = blodmoln och hål; hagel på nära håll i huvudet = huvudet flyger
av med fontän ur halsen; i bröstet = genomskjutet hål; i benen = benet skjuts
av och flyger. Kulhål blöder på kroppen.

- **Weapons** (`data/weapons.json`): pistol (bullet, 8 rounds), nailgun (nail),
  shotgun "REPO 12" (9 pellets, spread, two hands), smg "OVERTIME" (auto,
  30 rounds), ray "FINAL NOTICE" (orb, pierces, legendary). Pickups placed
  on Dock Street and the Intake Lot (`run_act.gd _place_weapons`); the pickup
  shows the gun sprite.
- **Art**: `tools/gun_art.py` draws the five pixel guns into
  `assets/sprites/guns/*.png` plus `guns.json` (grip and muzzle points).
- **Holding** (`fighter.gd`): `_mount_gun`, `_place_gun` (grip on the fist of the
  cross hit frame, recoil lift), `_muzzle_global`, `_fire_gun` (zones, spread,
  recoil, flash, casings, empty = drop). Light attack fires when armed; SMG
  auto-fires while held. `_hand_point` finds the fist in the frame.
- **Rounds** (`src/combat/round.gd`, class `Round`): swept lane hit test
  against Punks, per-kind look and flight (bullet, pellet, nail, orb).
- **Muzzle fx** (`src/combat/gun_fx.gd`): per-gun flash shape, smoke, brass or
  red shells that bounce and clink.
- **Gore** (`src/juice/gun_gore.gd`): `wound()` on hits (holes, exit spray,
  reactions), `death()` picks HEADSHOT / DECAPITATED / CLEAN THROUGH / LEG
  DAY / dissolve (ray), with flying head and leg pieces. Shader uniforms
  `cut_head`, `cut_leg`, `gape`, `only` in `wound.gdshader`.
- **Important fix**: `AtlasTexture.get_image()` returns only the region,
  without the margins. Both `BloodSim.head_of_tex` and `_hand_point` now add
  `margin.position` and centre on `tex.get_size()`. Before this the head
  circle was ~30 texels too high on every padded sprite, so face wounds and
  every head-based landmark were off.
- **Tests**: `tools/gun_test.gd -- outdir weapon:zone:dist ...` (frames plus 2x
  crops in the dojo), `tools/gore_shader_test.gd -- out.png` (all shader cut
  states on a punk, deterministic).

## 0a. Painted backdrops on every map but one (latest)

Every map now has its own painted, stitched backdrop strip
(`assets/backdrops/<theme>_strip_*.png` + `.json`, built with
`tools/street_strip.py` from FLUX.1-Krea-dev paintings on Hugging Face
ZeroGPU), in the same rainy painterly style as Dock Street:

| map | theme | sections |
|---|---|---|
| intake_lot | lot | clinic INTAKE ramp, ambulance fence, pay booth, FEEL BETTER PAY LATER billboard, parking garage, medical waste + painted wet asphalt floor |
| group_circle | circle | SUPPORT GROUP TONIGHT, laundromat, church, OPEN TIL 4 liquor, playground, FEELINGS NOT COVERED pharmacy |
| neon_exchange | neon | EXCHANGE, karaoke/pachinko, ARCADE, WE BUY GOLD, motel, CLUB HEMORRHAGE, FIX IT, CASH ONLY FEELINGS |
| waiting_room | waiting | TAKE A NUMBER 9900, NO REFUNDS ON HOPE, PAY BEFORE PAIN, pill counter + mopped tile floor |
| rail_bridge | rail | platform, signal box, depot, graffiti subway cars, RAVEN LINE tunnel, wagon yard |
| city_hall | hall | steps, justice court, records office, RAVEN CARES banner, PUBLIC SERVICE fountain, clock tower, gate |
| copay_orchard | farm | barn, orchard, yurts (MINDFULNESS EXTRA FEE), lake, farmhouse, greenhouse |
| sleet_hour | snow | RETREAT CLOSED FOR WELLNESS lodge, chalets, frozen lake, chairlift, NO REFUNDS IN THE SAUNA, pylons |
| raven_grid | cyber | ramen under a holo koi, night market, UPGRADES ON CREDIT, drone alley, capsule tower |
| ledger_dive | vault | LEDGER vault door, flooded archive, brine spa, pipes, PAY ON TIME cenote, invoice altar |
| invoice_pier | pier | INVOICE PIER warehouse, boathouse, sinking chapel, FINES PAYABLE HERE, lighthouse |
| processing_floor | processing | desks, DENIED stamp press, shredder, records vault, THE FAMILY PLAN desk + concrete floor |

Not done: **fire_escapes** (rooftop skyline): the ZeroGPU daily quota ran
out after one of its six paintings (`/tmp` spec was "roofs"); its
tenements stay until `assets/backdrops/roofs_strip.json` exists.

How a map uses it: `NightStreet.parallax(theme)` → `_backdrop` → `_far_layer`
(shared harbour skyline when the theme has none) + `_strip`. Maps with
street floors lay `WetStreet` (cobbles, or a named painted ground:
`lot_ground`, `clinic_floor`, `concrete_floor`); maps with water/grass/snow
floors keep their own. Blockout tenements are drawn only when the theme has
no backdrop. Repeated moons are painted out per section (one moon per map).
Paintings with strong one-point perspective were dropped or regenerated with
"strictly flat orthographic front elevation" in the prompt: those cannot be
stitched. `street_strip.py name.png@ROW` sets the ground row by hand when the
painting has a big foreground.

Also fixed: a crash in `BloodSim.add_hole` when a sprite's wound material
had no holes array yet.

---

## 0b. Enemies, brutal gore, voices, music, sound (latest)

**What.**
- **Enemies re-animated** with Sorceress AutoSprite from their own pixel art
  (same look, real motion): Bag Snatch / street thugs (`punk`), Mohawk Bo,
  the beat cop, the Shift Lead and Collector Gant. Each has `idle`, `walk`,
  `punch_high`, `punch_mid`, `kick_low`, `hurt`, `death` (the cop keeps his
  old hurt and has no drawn death yet). The swing they play matches the
  height marker over their head, timed so the contact frame lands at the end
  of the wind-up (`Punk._pick_swing`). Ordinary deaths use the drawn fall
  (`HitReact.corpse`, "drawn" branch); launches, blasts and crushes keep the
  tweened ragdoll.
- **Brutal gore** (`BloodSim.gore`): meat chunks, teeth and bone splinters
  that fly, bounce, smear and stay on the street; an **overkill** (a finisher
  or a blow far past the last HP) takes the body apart with a neck fountain,
  a big pool and blood on the camera glass, plus the announcer. Heavy blows
  crack bone and knock teeth out. "Less gore" in options turns all of it off.
- **Voices** (`data/vo_lines.json`, `assets/audio/vo/*.ogg`, `VoBank.line`):
  53 barks in a dry, absurd, dark-comedy tone (original writing): Son and
  Father kill/combo/hurt/block quips, thug/Mohawk/cop/Shift Lead/Gant
  taunts, hurt and death lines, and an announcer (PERFECT, COMBO, COUNTER,
  GUARD BREAK, BRUTAL, OVERKILL). Cooldowns stop spam (1.4 s between any two
  barks, 3 s per speaker).
- **Music** (Suno via Sorceress, instrumental): street, boss, hideout,
  dojo, tension, chase as `assets/audio/music_*.ogg`. `Mixer.play_music`
  plays the `.ogg` when it exists next to the old `.wav` name, looping.
- **Sound effects** (`assets/audio/sfx/*.ogg`): punches, kicks, bone crack,
  skull crunch, squelch, blood spray, gib splat, teeth, body fall, block,
  parry ring, roll, spin whoosh, combo and perfect stings, and a rain bed
  that loops wherever it rains.
- **The user's own clips:** two jump roundhouse takes the user made on
  Sorceress are in. The 360 spinning heel is the Father's new **air attack
  (jump, then heavy)**, the Son got the same air attack cut from his jumping
  roundhouse, and the Father has two new dojo combos: TORNADO HEEL
  (down + light, up + heavy) and HIGH TIDE (jab, cross, forward + light).
  All 17 combos land in `tools/combo_test.gd`.

**Tools:** `tools/vo_gen.py`, `tools/music_gen.py`, `tools/sfx_gen.py`
(Sorceress speech / music / sfx; skip files that exist),
`tools/autoplay.gd` (bot plays a map; with `--write-movie` Godot records
video and audio), `tools/street_tour.gd`.

**Credits:** the Sorceress balance ran down to about 15-27 credits. Earlier
"orphan" animation jobs that were never polled appear to have been billed
after all, on top of their resubmission. Rule for the next agent: always
save the jobIds of every submit before doing anything else, and never
resubmit a batch that may still be running.

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
