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

## 0h. Clean reset, guns, full audio pass, COPAY + bowling (latest)

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
