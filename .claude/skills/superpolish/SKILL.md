---
name: superpolish
description: "MANDATORY when Timmie says /superpolish, superpolish, superpolera, polish, polera, 'gör den bättre', juice, dopamin, or names one part of Father & Son to take next (one menu, one screen, one map, one move set, one enemy, one system). A full part-by-part pass: bug hunt, web research against the top-ranked games for that exact thing, gap analysis plus own ideas, deepen/expand, verify, detail/juice/graphics/audio pass, second bug hunt, then a SECOND visual polish, plus performance. Makes the part bigger and better, not just prettier."
---

# /superpolish — Father & Son (Godot 4.7)

Timmie's own process. **One part per run** (one menu, one sheet, one map,
one fighter's move set, one enemy, one system). Name the part first; if he
named nothing, pick the weakest part on the path he plays most (title →
character select → tutorial → stage 1 → boss) and say which one.

> Den ska bli större, djupare och snyggare — inte bara ommålad.

**One-line test:** if the only difference at the end is that it looks nicer,
it was a repaint, not a superpolish.

## Stages (order is the method — do not merge or skip)

### 1. Bug hunt BEFORE touching anything
- Read the part's scripts end to end and trace every value it shows back to
  where it is set and where it is read. The common bug here: data declared and
  rendered but consumed by nothing (or a button that toasts but does nothing).
- Run the tests that cover it (see Verify). Note which failures you
  inherited before you change anything.
- Screenshot it (xvfb, see Verify) and LOOK at the PNG: clipping, overlap,
  2x scale (forgot `PixelStage.attach_canvas`), ballooning autowrap labels
  (need `custom_minimum_size.x`), dead focus for gamepad, unreadable text.
- Write the list down. Fix now or mark out of scope with a reason.

### 2. Research — the web, real top-ranked games
WebSearch (send several searches in one turn) for the best games and the best
write-ups on exactly this thing. Read what players say is great and what they
say is missing. Benchmarks by part (start here, add more):

| Part | Benchmark |
|---|---|
| Brawler combat, enemies, grabs, throws | Streets of Rage 4, River City Girls 2, TMNT Shredder's Revenge, Scott Pilgrim, Sifu, Absolver |
| Fighting moves, juggles, frame data, block/guard | Tekken 8, Street Fighter 6, Guilty Gear Strive, Skullgirls |
| Platforming, parkour, wall/ledge moves | Celeste, Dead Cells, Hollow Knight, Katana ZERO, Vector |
| Roguelike runs, cards, rewards | Hades, Dead Cells, Slay the Spire, Risk of Rain 2, Balatro |
| Survivor / bullet heaven modes | Vampire Survivors, Brotato, Halls of Torment, 20 Minutes Till Dawn, Deep Rock Survivor |
| ARPG/RPG gear, crafting, progression | Diablo IV, Path of Exile 2, Last Epoch, Hades 2 mirror/arcana |
| Pixel art, light, shadow, VFX | Blasphemous 2, Huntdown, Eastward, Children of Morta, Sea of Stars, The Last Night |
| Menus, hub, UI, onboarding | Hades, Persona 5, Dead Cells, Brawlhalla, Balatro, SoR4 |
| Online co-op / invite flow | Brawlhalla, It Takes Two (friend pass), Overcooked 2, Among Us room codes |
| Music and sound | SoR4 (Yuzo Koshiro set), Katana ZERO, Hades (Darren Korb), Hotline Miami |

Name the games and links in the report (Sources list).

### 3. Gap analysis + own ideas
One honest paragraph: where ours falls short of the benchmark. Then a list:
**take** (what they have that we lack), **change**, **add** — and at least
two of your OWN ideas that would put this part above the genre floor,
in this game's voice (father and son, family banter, dark humour). Small
ideas: just do them. Huge ones that change the game plan: build what is safe,
propose the rest.

### 4. Deepen and expand
More to do, earn, choose and come back to. Interlock with existing systems
(FamilyProfile gems/rewards, RunState cards, MoveBook, ArtMoves, dojo,
camp sheets) — never a closed box. **Grep first; never a second copy of a
system that exists.**

### 5. Verify it works
Tests + screenshots + play-through of the changed flow, pad AND keyboard,
P1 and P2, solo and couch (and online if the part touches NetSession).
A new test must be seen to go red on an injected fault before you trust it.

### 6. Detail / effects / juice / graphics / audio — round one
Go through every action of the part and give it all of:
- **Light**: PointLight2D / additive glow sprites, rim light on heroes,
  lamp pools, muzzle/impact flash. Light budget ≤ 4 shadowed lights in view.
- **Shadow**: contact shadow under every actor and prop, drop shadow on UI cards.
- **Reflection**: wet asphalt, puddles, glass, polished floors, chrome on UI.
- **Particles**: dust on land/dash, sparks on block, debris on throws, ambient
  motes; GPUParticles2D with capped amounts, pooled.
- **Blood/gore** (`src/juice/blood.gd`, `gun_gore.gd`, `wall_mark.gd`,
  `face_drip.gd`): spray matching the hit direction and weapon, drips, pools,
  stains on walls/floor; heavier hits = more and darker.
- **Juice** (`src/juice/juice.gd`, `hit_react.gd`, `reward_fly.gd`,
  `chest_pop.gd`): hitstop, shake as added offset, squash/stretch, flash,
  numbers, overshoot easing (Tween TRANS_BACK / ELASTIC), reward flies to the
  counter and holds ~700 ms. Only the actionable thing pulses.
- **Sound + music** (`src/audio/mixer.gd`, `kit_sfx.gd`, `vo_bank.gd`):
  every action audible; ceremonial moments get their own sound; music ducks
  under VO. ElevenLabs (key in ~/.config/elevenlabs/key, never printed) for
  new SFX/VO/music when needed.
- **State is a change of material**, not opacity 0.4.

### 7. Bug hunt again
On what you just built. Tests again, screenshots again, every button, every
input device, both players.

### 8. Visual polish — round two
Fresh eyes on the new screenshots. This round makes it look *finished*:
spacing, alignment to the pixel grid, colour harmony, outline consistency,
timing of every tween, animation arcs, extra detail sprites, secondary motion
(cloth, hair, cables, sparks lingering). Not leftovers from round one.

### Performance (runs alongside 4–8)
Measure, never assume: `Performance.get_monitor` (FPS, draw calls, objects,
nodes) in a headless/xvfb probe, or the profiler. 60 fps hard. No `get_node`
or allocations in `_process`; pool blood drops, numbers, bullets, particles.
Cut light budget before cutting tick or animation frames.

## Quality bar (non-negotiable)
- Pixel style, but more detail: light, shadow, reflections, particles, blood.
- **Never cheat on animation**: no skipped frames, no stretched single frame
  as a "move", no clip that shows a different weapon/limb than the move does,
  no half-done transitions. If a clip is wrong, regenerate it (HF pipeline:
  `tools/hf_hero_moves.py`, `tools/hf_react.py`, `tools/install_hero_clips.py`)
  — check the frames visually before installing.
- Everything must flow: no dead ends, no button without an answer, no screen
  that cannot be left with B/Esc, gamepad focus everywhere.
- No emoji in UI. Hand-built pixel icons.
- Do not redesign what Timmie is happy with.
- Recount numbers from source, never from memory.
- Back up `user://` profile JSON before tests that write saves.

## Project tooling for Verify
- Godot: `G=/root/tools/Godot_v4.7.2-stable_linux.x86_64`
- Tests: `$G --headless --fixed-fps 60 --path . -s tests/<name>.gd`
  (parkour needs `PARKOUR_AUTO=1`). Always: `smoke.gd`, `script_load_test.gd`,
  plus the tests for the part (training_test, run_test, turn_test, pad_test,
  rooms_boot for online…). Run them in background/batch, read only the tail.
- Screenshots: xvfb-run + `--rendering-driver opengl3`, `tools/capture.gd`,
  `tools/moves_film.gd` (env ONLY, WHO, SHOTS), `tools/dev/cap_*.gd`.
  Viewport 640x360, UI on the 1280x720 design canvas (`PixelStage.DESIGN`).
- Rules from CLAUDE.md: `ResourceLoader` not `FileAccess` for res://;
  world sprites via `SpriteBook.DRAW_SCALE` + `world_filter()`.

## Always-load skills (read the SKILL.md before editing)
| Domain | Skills |
|---|---|
| Combat / feel | `beat-em-up-feel`, `game-feel`, `godot-combat-system`, `godot-genre-fighting`, `godot-ability-system` |
| Genres | `godot-genre-action-rpg`, `rpg`, `godot-genre-roguelike`, `survivor-bullethell-design`, `godot-genre-platformer`, `level-design`, `game-ai` |
| Pixel / art | `pixel-art-sprites`, `pixel-perfect-2d`, `parallax-backdrops`, `godot-2d-animation`, `godot-shaders-basics`, `godot-particles` |
| UI / menus | `game-ui-ux`, `godot-ui-theming`, `godot-ui-containers`, `godot-tweening`, `godot-input-handling` |
| Audio | `audio-design`, `godot-audio-systems` |
| Engine | `godot-dev`, `godot-gdscript-mastery`, `godot-state-machine-advanced`, `godot-camera-systems`, `godot-mechanic-secrets` |
| Perf / debug | `godot-performance-optimization`, `godot-debugging-profiling` |
| Online | `godot-multiplayer-networking` |
| Economy | `game-economy` |
| Cost | `lean-budget` (always) |

Load only the rows the part touches.

## Delivery (every superpolish ends like this)
1. Tests green (state any that were red before you started).
2. Commit on the session branch with the standard footer, push.
3. `GODOT=$G MAKENSIS=/usr/bin/makensis NSISDIR=/usr/share/nsis bash tools/windows/pack_windows.sh`
4. `zip -9` build/windows/FatherAndSonSetup.exe → FatherAndSon-Setup.zip,
   upload to HF `timmietooth/father-and-son-builds` (token read from
   ~/.cache/huggingface/token into env only, never printed).
5. Report in Swedish: what was found, what games were compared (Sources),
   what was taken/changed/added, own ideas, what was verified, what was NOT
   done and why, and the download link.

## Done means
- [ ] Pre-existing bugs fixed or listed as out of scope
- [ ] Real games researched and named; gap stated honestly
- [ ] Part is measurably bigger: more to do/earn/choose
- [ ] Own ideas added, in the game's voice
- [ ] Light, shadow, reflection, particles, blood, sound, music all touched
- [ ] Two separate visual polish rounds with a bug hunt between
- [ ] Performance measured
- [ ] Screenshots taken and looked at
- [ ] Report is true — including what was not done

## Scope honesty
A big part can take several runs. Say so up front, ship it in reviewable
pieces, and never claim round two if you only did round one.
