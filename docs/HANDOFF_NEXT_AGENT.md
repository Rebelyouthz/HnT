# Handoff to the next agent — Father & Son

## A message from the player / owner

> Thank you so much for all the help. I am grateful for everything, and I hope
> you want to help me finish this. Please do it at the highest possible quality
> and standard: this is meant to be an **AAA+ pixel art game**.

The owner writes in Swedish and wants answers in Swedish. They play on a
ROG Ally (Windows, gamepad) and test the Windows installer.

## What they asked for next (in their words, translated)

1. **Logos / icons as real sprite assets everywhere** instead of hard-coded,
   code-drawn shapes (PixelIcon glyphs, Polygon2D/`_draw` icons). Every
   button, node, card, item, ability, pickup and badge should have a proper
   pixel-art sprite.
2. **Level-up cards made from sprites**: real pixel-art cards with a frame,
   a holder/socket for the logo or picture, and stat text in colour. Animate
   them: the highlighted card rises up and the frame glows in its **rarity
   colour**.
3. **Survivor mode**: lots of auto weapons and manual weapons, and level-up
   cards that are sprites too but **look different from the story mode
   cards**. Survivor has to be at least as deep as the rest of the game
   (they say it is almost more important).
4. Everything else: free hands, but make it as good as possible.
5. Still open from earlier: **#95 super polish of everything + 2 careful
   visual rounds** (camera moments on cool moves, particles, blood, effects,
   "AAA+"), then rebuild the installer and send screenshots.

### Latest wishes (last message before handoff, translated)

> "Thank you for everything, good job." The owner asked that all of this is
> passed on to you:

6. **Paperdoll for equipment**: a character figure that shows every worn
   piece on the body (survivor gear: cap, jacket, shoes, charm; story gear
   too). Swapping a piece updates the doll right away.
7. **Pictures of the weapons being modified (GUNSMITH)**: a large picture
   of the gun, and every attached part must be **visible** on it. Attaching
   a part plays an **animation**, e.g. the bare muzzle → a suppressor
   slides on and clicks into place (sound + flash). Do this for every part
   in every slot on every gun/item (`src/app/attachments.gd` already has
   `dress()`; it needs real sprite parts and attach/detach tweens).
8. **Skill tree icons polished** so they clearly read as **pixel art**:
   crisp, nearest-filtered, outlined and shaded, not blurry downscales
   (`src/ui/hub_build.gd`, `NODE_ICON` / `_node_tex`).
9. **Survivor gear screen and item cards / gunsmith screen**: pictures and
   logos on **everything**, never just plain menu text
   (`src/ui/surv_gear_sheet.gd`, `armory_sheet.gd` `_gunsmith`,
   `ui:items`).
10. **META upgrades get a picture/logo too** (all tree nodes, shop rows,
    meta screens).
11. **JUICE on every upgrade, across all menus in the whole game**: it has
    to *feel*, *show* and *sound* good, with a "reward grow" feeling
    (scale punch, glow, particles, rising sound, number pop).
12. **Rewards must be visible**: when gold, gems, S-COINS or other
    currency is given, show it on screen, **count it up**, then animate the
    coins/gems **flying to their counter in the top corner**, and only then
    tick that counter up (with a small bump on arrival). Same everywhere
    rewards are given: results, chests, wheel, quests, shops, level-ups.

### Round 2 (owner's next message, translated, condensed)

More angles for Dad, the Kid and enemies (up, diagonal up/down); punchier
punch/kick animations, varied hit/kill reactions, blood and wounds; many
combos, finishers, throws, specials; survivor more like Jotunnslayer (unique
enemies and bosses, missions, side quests, challenges, start weapons you can
mod, level and merge to raise rarity); achievements; a codex of everything
with rewards and first-meeting entries; red dots on everything new; reward
feel on claim/upgrade/buy/equip with stat gains shown (white base, green up,
red down); 5+ new things for each mode and 5 for the menus; boss loot chests
and secrets with new weapons, moves, parts, suit parts, throwables and cards;
shoes, necklace and ring in the paperdoll; camp/dojo unlocks in a planned
order with guided first use and speech bubbles; then polish twice.

### Latest (see worklog 0q)

Owner said "continue with everything on the to-do list": bodies vs lamps /
cars / walls / crates / standing thugs, tripping and dragging, wall marks,
last-kill cam, hurt gaits (limp/clutch/dazed/scoot) and the missing walk
angles (father up, punk + cop up/down) are in. Next ideas: angles for the
other enemy types (repo_goon, bailiff, mohawk...), diagonal clips.

### Before that (see worklog 0p)

Owner asked for every suit drawn in a parkour film (done:
`tools/suit_show.gd`, screens/round2/dräkter_parkour.*), varied deaths by
blow/weapon/round with real gravity and no overlapping bodies (DeathFall),
bullets that go through or stay in with exit wounds, the same for the
heroes, and a calmer right side of the map. All first-passed in 0p.

### Done since (round 2, see worklog 0o)

All of round 2 has a first pass: codex, guides, build order, stat colours,
survivor starters/missions/challenges/shrines/pacts/rampage, boss chests,
rewards desk + daily crate + clinic road + titles + power, loot chests and
loot stashes, five throwables, five new cards, finishers and impact frames,
parkour pursuer/rings/style, per-move hit reactions, walk_up/walk_down for
the Kid and walk_down for Dad. Open: `father/walk_up` and enemy angles (HF
ZeroGPU quota / Sorceress credits ran out - same pipeline, retry), more
in-game polish, rebuild the installer.

### Done before (see worklog 0n)

Items 1-3 and 6-12 above have a first full pass: sprite icons everywhere
(IconBook), sprite level-up cards with rise + rarity glow (story and a
different survivor badge card), six new survivor weapons incl. two manual,
equipment paperdoll, gunsmith bench with every part visible and attach
animations, pixel-art skill tree icons, pictures on gear / gunsmith / META,
upgrade juice in the menus, rewards that count up and fly to the corner.
Good next steps: more polish on the icons the owner points at, sprite parts
for melee weapon mods too, story equipment (locker) with the same paperdoll
treatment, more survivor weapons and evolutions for the new ones.

Older open items in the task list: audit entities without sprites, in-run
HUD overlaps, parallax backgrounds, map 1 → film → map 2 flow polish.

## Where things are (repo `/home/user/hnt`, branch `claude/gallant-galileo-5ctrmf`)

Read `docs/CLAUDE_WORKLOG.md` first: sections **0o** and **0n** lists everything done in
the latest sessions with file names. Highlights:

| System | Files |
|---|---|
| Element arts, Tekken grabs, Dad+Son team attacks | `src/combat/elements.gd`, `art_moves.gd`, `element_shot.gd`, `art_fx.gd`, `data/elements.json` |
| Dojo tutorial (13 lessons) | `src/ui/dojo_school.gd`, `src/levels/dojo_practice.gd` |
| Gun attachments (GUNSMITH), throwing knives | `src/app/attachments.gd`, `src/combat/throw_knife.gd`, `src/ui/armory_sheet.gd` |
| Level-up card kinds/levels + 14 items | `src/ui/pixel_card.gd` (KINDS), `src/combat/item_rack.gd`, `data/cards.json` |
| Brawl extras (backstab, interrupt, juggle, taunt...) | `src/extras/brawl_plus.gd` |
| Parkour extras (ghost, medals, tags, race clock...) | `src/extras/parkour_plus.gd` |
| Body separation + footsteps/parkour sounds | `src/extras/body_sense.gd` |
| Survivor depth: S-COINS, gear, events, wheel | `src/survive/surv_gear.gd`, `surv_coin.gd`, `surv_events.gd`, `src/ui/surv_gear_sheet.gd`, `src/ui/lucky_wheel.gd`, `src/extras/wheel_token.gd` |
| Menus: ticker/next goal, hold-confirm, history | `src/ui/hub.gd`, `ui_kit.gd`, `stats_sheet.gd`, `title_screen.gd`, `stage_card.gd` |
| Skill tree node icons | `src/ui/hub_build.gd` (`NODE_ICON`, `_node_tex`) |

Current card art: `PixelCard` draws the frame in code. Item icons use
`PixelIcon` glyphs; survivor icons live in `assets/sprites/survive/*.png`
(generated by `tools/survive_icons.py`). These are the first candidates for
the sprite overhaul the owner wants.

## How to work here

- Godot 4.7.2: `/root/tools/Godot_v4.7.2-stable_linux.x86_64`.
- After adding a `class_name`: `--headless --path . --import --quit`.
- Tests: `--headless --path . --script res://tests/smoke.gd` (also
  `focus_test.gd`, `reset_test.gd`). **Smoke does not load every script**:
  run `--check-only --script res://<file>` on each file you edited.
- Screenshots: `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path .
  --rendering-driver opengl3 --resolution 1920x1080 --windowed --script
  res://tools/capture.gd -- <target> <out.png> <frames> [walk]`. Targets:
  map ids, `hub:<tab>` (clinic, heroes, build, build_surv, build_park,
  moves, moves_lib, moves_el, armory_gun, sgear...), `ui:fight`, `ui:surv`,
  `ui:items`, `ui:items_live`, `ui:gun_<gun>`, `art:<art|grab|team>:<id>[:father]`,
  `camp:x`, `title`. `PROBE=x,y` env lists canvas items at a viewport point.
- The viewport is **640×360** (×3 to 1080p); UI built in 1280×720 design
  coordinates must sit under `PixelStage.attach_canvas(layer)` (DesignRoot).
- AI art: FLUX via HF (`black-forest-labs/FLUX.1-Krea-dev`, token in
  `~/.cache/huggingface/token`, never commit it); see `tools/hf_batch.py`,
  `tools/street_strip.py`, `tools/backdrop.py`.
- Windows installer: `GODOT=... MAKENSIS=/usr/bin/makensis
  NSISDIR=/usr/share/nsis bash tools/windows/pack_windows.sh`, zip
  (stored) `FatherAndSonSetup.exe` + `INSTALLERA.txt`, `split -b 81788928 -d
  -a 1` into `FnS.part*` in the `windows-installer` worktree, regenerate
  `JOIN.bat`, amend and `push --force-with-lease` to `windows-installer`.
  Rebuilt and pushed at the end of this session.
- Commit trailer and no PRs unless asked (see worklog).

## Gotchas found this session

- `CouchCamera._ready` used to overwrite `limit_right` (fixed): levels set it
  before `add_child`.
- Feet `LightOccluder2D`s must stay on light mask 2 or street lamps throw a
  black wedge over the road.
- Thug `take_hit` runs `BrawlPlus.on_blow`; arts deal damage through
  `ArtMoves.strike` (kind `"combo"` with `combo_dmg`).
