# Handoff to the next agent: Father & Son (repo `Rebelyouthz/HnT`)

## A message from the owner first

The owner is a parent building this game with their son. They write in
Swedish and want answers in Swedish. They said:

> "Tack ska du ha för all hjälp." (Thank you for all the help.)

They are very happy with the work so far, and their son loved the feel when
he played it. **Read this whole file, and the code it points to, before you
change anything.** Check every detail yourself; do not trust a summary,
this one included, without looking. Then do the best and most careful job
you can. Small things matter to them: a sprite a few pixels off, a prompt
that names the wrong button, a lesson that will not count. They test on a
**ROG Ally (Windows, gamepad)** through the Windows installer.

Older wishes and history are in `docs/HANDOFF_EARLIER.md` and
`docs/CLAUDE_WORKLOG.md`.

## The goal right now

**The intro film, the guided tutorial and the first map must work
completely** before anything else:

1. Prologue film, then the tutorial alley (13 lessons), then Dock Street
   (map 1).
2. You must be able to **finish map 1** *and* **die on it**, and everything
   must unlock in order along the way (strict guided unlocks, task #196).
3. Balance level-ups and make it **harder**. This session set 2 lives (see
   below). Check that it is fair when played by hand.

## Environment

- Godot **4.7.2** (GDScript). Binary: `G=/root/tools/Godot_v4.7.2-stable_linux.x86_64`.
- Design canvas 640x360 (`PixelStage.DESIGN`, a `Vector2i`; wrap it in
  `Vector2(...)` before doing float math). UI is authored in 1280x720
  coordinates.
- Repo in the cloud container: `/home/user/hnt`. Branch
  `claude/gallant-galileo-5ctrmf`; push with
  `git push -u origin claude/gallant-galileo-5ctrmf`. No PR unless asked.
- After adding a new `class_name` script, reimport first:
  `timeout 600 $G --headless --path . --import --quit`.
- The disk allowance is small. Delete scratch frames and GIFs after use.

### Tests (run all of them before every push)

`cd /home/user/hnt && timeout 400 $G --headless --fixed-fps 60 --path . -s tests/<name>.gd`

| test | what it proves |
|---|---|
| script_load_test | every script compiles |
| smoke | data files and encounters load |
| intro_test | prologue -> alley -> Dock Street, and a second PLAY |
| training_test | all 13 alley lessons complete on simulated buttons |
| **throw_probe** (new) | the alley throw lesson counts realistic X+Y presses (gaps, either order, off-line, far side) |
| **ladder_test** (new) | Dock Street fire escape: the climb clip plays and he reaches the roof |
| **death_test** (new) | 2 lives -> 1 -> 0 -> THERAPY'S OVER -> TRY AGAIN -> back on Dock Street with 2 lives |
| night_flow_test | prologue -> alley -> Dock Street -> camp -> Dock Street -> camp |
| story_flow_test | all film and card hand-offs |
| run_test, brutal_test, dojo_train_test, camp_walk_test, stick_test, shoulder_test, rs_gesture_test | combat and hub flows |
| parkour_test | needs `PARKOUR_AUTO=1` |

Parallel test runs can race on the save file (a harmless "Parse JSON
failed" line). Run them one at a time when in doubt.

Inside an `extends SceneTree` test, do not name class_names (`Fighter`,
`ResultsSheet` ...): they compile before the autoloads exist and the test
fails to load. Use `has_method` / `get()` (see `tests/death_test.gd`).

### Screenshots

`xvfb-run -a -s "-screen 0 1280x720x24" $G --path . --fixed-fps 60 --rendering-driver opengl3 --resolution 1280x720 --windowed --script res://tools/capture.gd -- <map|prologue|skinwalker_film|tower:dock_street> out.png <frames> [walk]`

Pass `--fixed-fps 60` whenever timing matters. Dock Street shows "GET
READY" for its first ~400 frames and the hero is not drawn yet.

## Done this session (all pushed)

- **Bigger people** (the owner asked twice): `SpriteBook.ACTOR_K` 1.25 -> 1.4
  (hitboxes follow), `FATHER_K` 1.14, `SON_K` 1.16. Prologue cast
  `PEOPLE_K` 1.24 (`src/ui/prologue_film.gd`). Waiting-room film cast at true
  room scale (`src/world/skinwalker_film.gd`, `_dress`).
- **Throw lesson fixed** (`src/combat/art_moves.gd`): grab reach and depth
  grow with ACTOR_K; the training bag has its own generous reach
  (`BAG_REACH`, `BAG_DEPTH`) and turns the hero to face it. An empty X+Y in
  the alley says "STEP IN CLOSER" instead of a dojo message. The first hand
  of the chord landing on the bag is no longer called a wrong button
  (`src/levels/tutorial_alley.gd`).
- **Ladder**: the climber draws in front of the rungs (`z_index` 3 on the
  climb plane, back to 0 on the roof or street). The climb clip was
  already wired; `ladder_test` proves it.
- **Difficulty**: `RunState.BASE_LIVES = 2` (META "SPARE LIFE" still adds
  more). The fail sheet now leads with **TRY AGAIN** (same street, fresh
  lives).
- **Move banners** (`Juice.move_banner(head, title, icon)`) roll down from
  the top centre for lesson complete, move learned (dojo) and mastery
  ranks. Toasts stay in the right corner.
- **Pickup hint**: a small speech bubble with the weapon's picture and a
  down arrow fades in when a hero is near (`src/world/weapon_pickup.gd`).
- **Loot pop** (`src/world/loot_drop.gd`): coin-flip spin, two bounces, then
  it lies tipped on its side; every ~2 s it hops, flips, bounces once and
  falls over again.
- **Street declutter**: world hint plaques fade in only near a player
  (`src/world/prox_fade.gd`, `ProxFade.attach(node)`).
- **Skinwalker GIF** of all four clips (walk, crawl, dog, gape) was sent to
  the owner.
- **Installer clean-up and uninstaller** (`tools/windows/Cleanup.ps1`,
  `FatherAndSon.nsi`). The new Setup.exe removes every old install, old
  Setup.exe, zip and loose game folder. It never removes the Setup.exe that
  is running, and never touches a folder with `project.godot`, `.git` or
  `.cursor` at or above it (the owner's Cursor/Claude dev copy must stay).
  Uninstall removes everything and asks before deleting the save. The Start
  menu has "Avinstallera Father & Son".
  Build: `GODOT=$G MAKENSIS=/usr/bin/makensis NSISDIR=/usr/share/nsis bash tools/windows/pack_windows.sh`.
  **Not yet tested on a real Windows machine.** Ask the owner to try it, or
  test the PowerShell in a Windows VM if you have one.

## Todo (priority order; check each one in the running game, not just in code)

1. **Map 1 end to end with hand-like input.** Play the alley and Dock Street
   with simulated pad input, not teleports. Check that every lesson
   completes, that every prompt matches its button, and that the miniboss
   (Shift Lead at x 1380) and the boss (Collector Gant at x 2780) can be
   beaten with the moves the alley taught. Check that the shop cart and the
   crates work and that the clear screen leads on correctly. Then die on
   purpose and confirm the whole death flow again.
2. **Balance pass with 2 lives.** Simulate a fair run (`tools/balance_sim.py`
   exists). Tune enemy damage, boss HP (`data/bosses.json` `hp_mul`),
   level-up pacing (4-8-15-21-27-35-42) and card strength so that a kid who
   learned the alley can clear Dock Street in 1-3 tries.
3. **Strict guided unlocks audit (#196).** Nothing in the hub shows before
   its story moment, and every new feature gets its guided first use.
4. **Scale check on every map** after the ACTOR_K change: props, doors,
   ladders, tower ledge seats, films (`FilmActor` sits at
   `DRAW_SCALE * FILM_SCALE`; standing film actors use plain `make_anim`),
   and the camp (`CAMP_K`). Fix anything that now looks wrong.
5. **Windows installer.** Verify on Windows that `Cleanup.ps1` deletes what
   it should and never the dev copy. Then publish the rebuilt
   `build/windows/FatherAndSonSetup.exe` the way the owner gets it (a
   release zip with `INSTALLERA.txt`, tasks #15 and #201).
6. Transitions (#194): idle/walk in and out, turn, walk/run start and stop.
7. Hideout unfurnished until built, a modern armory, the pet rescue story
   (#235).
8. Finish the declutter (#237): remaining map clutter, realistic blood.
9. Online across cities: a room-code relay on an HF Space (#227).
10. The batch 2 fix list from the playtest (#188).

## Skills and connectors (the owner asked)

The owner wants unused skills and connectors turned off, keeping what the
game needs. From inside a session you can only advise. Tell them, in
Swedish:

- **Skills**: keep the Godot skills, `game-*`, `beat-em-up-feel`,
  `pixel-art-sprites`, `parallax-backdrops`, `superpolish` and `lean-budget`
  (all in `.claude/skills/`), plus the game-character-sprites skill. They
  can turn the rest off with `/skills` in Claude Code or under claude.ai
  Settings -> Capabilities.
- **Connectors**: keep GitHub, Hugging Face (sprite clips) and Context7
  (Godot docs). Epidemic Sound (SFX and music) is used rarely but is worth
  keeping. These were never used for this game and are safe to turn off in
  claude.ai Settings -> Connectors: Canva, Gamma, Adobe for creativity,
  Mobbin, Replit, Nimble, Jam, Mem, Microsoft Learn, HyperFrames, YES2SDK,
  Three.js viewer, Google Drive, Claude Docs and AI Video Prompt Generator.

## Gotchas learned the hard way

- Lesson repeat guards use the wall clock (`Time.get_ticks_msec`). Headless
  tests run faster than real time, so a probe has to reset `_throw_t` for
  each case.
- `pkill -f <name>` kills your own shell if the name is in the command line.
- Light-string slots in saves are `L1`/`L2`/`L3`, not shoulder buttons.
  Never rename them.
- HF clip pipeline: `tools/hf_still_clips.py` + `tools/install_hero_clips.py`.
  Delete `*_preview.gif` afterwards, except the tracked
  `father/hook_r_preview.gif` and `father/punch_r_preview.gif`.
- `Juice` already has a `_banner_q` for unlock banners; the move banner uses
  `_mv_*`.

Thank you for taking care of this. It means a lot to them.
