---
name: superpolish2
description: >
  Run a full eight-stage Superpolish pass on HnT (Godot 4.7.2, Revenge & Therapy):
  bug hunt, competing-game research, gap analysis, deepen/expand the system,
  performance, then two visual polish rounds with a second bug hunt between them.
  Makes the thing BIGGER, not just prettier. Mandatory when Timmie says
  superpolish, superpolera, polish, polera, superpolish2, gör den bättre, juice,
  dopamin, or names an HnT screen, menu, or system to take next. HnT only — never
  Waterdrop, Pixi, React, npm, or TCC/card work.
---

# Superpolish2 — HnT (Godot 4.7.2)

This skill is **only** for **HnT** (*Revenge & Therapy*) in repo `timmie-dev/HnT`, engine **Godot 4.7.2**, language **GDScript**. It is a **new** skill. Do not overwrite, replace, or edit any existing Superpolish / Waterdrop skill.

A superpolish is not "make it prettier." It is a full eight-stage pass: bug hunt, genre research against real competing games, gap analysis, deepen and expand the system, performance, then **two** separate visual polish rounds with a **second** bug hunt between them.

Timmie's definition: polish with everything included — update, upgrade, look at what exists, research and compare with similar games on the web, analyze what is missing, add it, make the existing thing deeper and more advanced, make the code better for performance, make it visually much better, bug analysis both before and after, refine everything, fill gaps, then visual polish again. Two polish rounds and a great deal of other work.

A superpolish makes the thing **BIGGER**. A menu leaves with more dopamine and depth — not just better shadows. Combat leaves with more to do, earn, and return. A minigame (or a thin system) leaves as a larger game.

**One-line test:** If at the end the only difference is that it looks nicer — you did not do a superpolish. You did a repaint.

Contract: `docs/game-plan.md`. Juice code lives in `src/juice/` (one shared system). Roles are **The Father** (`the_father`) and **The Son** (`the_son`); display names come from character create / Family Profile.

## When to use

Load and follow this skill whenever Timmie says **superpolish**, **superpolera**, **polish**, **polera**, **superpolish2**, **gör den bättre**, **juice**, **dopamin**, or names a screen, menu, or system in HnT to take next (HUD, pause, Profile, Build Compare, The Basement Clinic, Raven Wharf, SNAP, Parenting Slap, CBT Tree, blood, camera, lighting, cards, shops, and the rest).

**When not to use:** Waterdrop Survivor, Pixi.js, React menus, npm card/TCC work, or any other repo. Tiny copy tweaks that are not a named system. Do not treat this skill as a license to redesign something Timmie is already happy with.

## Always-on skills (every superpolish2 task)

If the game-dev **router** does not fire, pick these yourself. Read the matching `SKILL.md` **before** editing. Do not wait to be asked.

| Domain | Load |
| --- | --- |
| Engine | Godot 4.7 plugin / `godot-gdscript`, plus the surface skills: `godot-nodes-scenes`, `godot-2d-movement`, `godot-physics`, `godot-animation`, `godot-resources` |
| Lighting + shadows | `godot-shaders` + `shader-programming`. Scene lights: `CanvasModulate`, `DirectionalLight2D`, `PointLight2D`, `LightOccluder2D` (game plan §10.1) |
| Shaders | `godot-shaders` + `shader-programming` (red-flash, hit-white, wet asphalt, outlines) |
| Camera | `camera-systems` (one `Camera2D` couch cam; shake is an **added offset**, shared budget = max not sum) |
| Menus / HUD | `game-ui-ux` + `godot-ui-control` (Control nodes, Theme, bottom tabs in hub only) |
| Juice | `game-feel` + this skill. Implement in `src/juice/`, never a second copy |
| Character | `create-game-assets`. Bodies built **in parts** (head, torso, arms, legs as child sprites) so gore can detach |
| Audio | `audio-design` + `godot-audio`. **ElevenLabs MCP** generates music, SFX, and English VO (`sound-effects`, `text-to-speech`, `music`, creative studio). `setup-api-key` if the key is missing. Audio-design is the playbook; MCP is the generator |
| Performance (stage 5) | `performance-optimization` |
| Input when touching controls | `input-systems` |

English only: plans, UI, VO, copy, commit messages, and this skill's output.

## Eight stages (keep this order)

Say up front that a full superpolish of a real system is often multi-session. Work in reviewable pieces. Do not skip stages. Do not merge stage 6 and stage 8.

### 1. Bug hunt BEFORE touching anything

Play it. Every control on `p1_` / `p2_` InputMaps (move, jump, light, heavy, special, shoot, block, throw, dash, SNAP, revive, pause). Keyboard, pad, and touch as the device allows.

Hit all three viewports (see Viewports). Read the GDScript, scenes, and data tables (`data/` JSON: cards, enemies, shops, balance). Recount numbers from those files, never from memory.

Backup saves before testing: copy `user://family.json` (Family Profile), not a Waterdrop `wds.save`. Grep the repo first. Never build a second copy of an existing system.

Run Godot tests if a harness exists (GUT, GdUnit4, or `godot --headless` scene scripts under `tests/` / `addons/`). If none exist, play the scene in **Godot 4.7.2** and write a focused test only when the repo already has a harness. Never invent `npm run test:logic`.

Log bugs. Fix them now or mark them explicitly out of scope with a reason.

### 2. Research real games on the web

Search and name **real** shipped games. The benchmark is the **best game in the genre of the thing you are polishing**, not a generic "indie look."

Starting set for HnT (steal feel and rules, not art):

- Combat / co-op street: **Huntdown**, **Streets of Rage 4**, **Double Dragon** (arcade)
- Parkour / roofs: **Vector**
- SNAP windows: **Johnny Trigger**
- In-run cards / Rep tree: **Vampire Survivors**, **20 Minutes Till Dawn**, **Halls of Torment**, **Skul: The Hero Slayer**
- Mobile HUD / silhouette: **Dan the Man**
- Mix / finishers: **Mortal Kombat** (mix, not 2.5D fighter movement)

Name the games in the report. Do not research Hearthstone, Gwent, or Pokémon TCG unless Timmie explicitly asked for a card-battler (he did not; HnT level-up cards are Vampire Survivors-style rule changers, not a TCG).

### 3. Gap analysis

State the gap vs the named benchmark in one paragraph. Propose extras **above** the genre floor. Ask before huge adds if they would blow the slice or fight the game plan.

### 4. Deepen and expand

More to **do**, **earn**, and **return**. Interlocking systems. Real progression (Scrap, Run XP / cards, Rep, Gold, CBT Tree, wanted ladder, shops) — not a reskin of a button.

Then add **this game's twist**. HnT twist: *Revenge & Therapy*, The Father and The Son on one couch camera, black comedy / therapy jargon, **Raven Wharf**, Parenting Slap, SNAP, web + cape. A competent clone of Huntdown or SoR4 is failure.

### 5. Code + performance

Measure. Never assume. Godot Profiler + Visual Profiler. **60 fps hard.** Physics tick 60. Internal render **1280x720**, integer upscale when possible. If a phone sweats, cut the **light budget**, not the tick. Plan is 60, not 120.

Godot cost centers (translate the lesson; do not paste Pixi/React/SVG-filter notes):

- Draw calls / canvas items / Y-sort clutter
- Physics body count (`CharacterBody2D`, `RigidBody2D`, areas)
- `GPUParticles2D` amount caps and unused process material
- Light budget: at most **4** shadowed `PointLight2D` in view; extra glow is Add-blend sprites
- Allocations in `_process` / `_physics_process` (no `get_node` every frame; pool blood drops, numbers, bullets)
- Renderer: **Mobile** on phone, **Forward+** on PC

### 6. Visual polish round one

Light, shadow, material, depth. Easing with **overshoot** (`Tween` back/out, not linear fades). Every action audible **and** visible. Menus must already look like a product, not a debug overlay.

Use `AnimationPlayer` for gameplay events, `AnimatedSprite2D` for pictures, `GPUParticles2D` for mist/sparks, authored sprite sheets for arterial spray and finishers.

### 7. Bug hunt again

Play **what you just built**. All viewports. Pads + touch + mouse. Tests again. Confirm Family Profile backup is intact and the live save still loads.

### 8. Visual polish round two

This is the pass that stops looking **built** and starts looking **finished**. Second juice pass, second light pass, second sound pass. Not leftovers from stage 6.

## Juice checklist

Port the contract to Godot. Shared implementation: `src/juice/` (hitstop, shake offset, freeze frames, bitmap numbers, flash, one reward-burst). Game plan §10.2 is the event table (light / heavy / special / SNAP / kills / finisher / slap / level-up).

- Nothing changes a number silently (HP, Steam, Scrap, Rep, Gold, combo, lives, wanted).
- Every claim, click, purchase, unlock, pickup, and level-up: **sound + motion + a visible statement**.
- Show the reward; do not only grant it. One shared burst system — **never a second copy**. Grep first.
- Hold long enough to read (~700 ms).
- Only the actionable thing moves.
- State is a change of **material** (shader, modulate, stylebox, light energy), not an opacity fade to 0.4.
- Escalate toward the payoff.
- Sound is part of the pass. Ceremonial moments get their own sound: SNAP, Execute / FINISH, Parenting Slap (`GROUNDED`), Family Therapy, level-up cards, shop buy. Generate with ElevenLabs MCP; mix on Godot buses (Master, sfx, vo, music; duck music on VO).
- Light hits: **red flash only**, 2 frames, no particle. Brutality is the reward for heavy / SNAP / finisher.
- Combo callouts at 5 / 10 / 20 / 40. Bitmap font, not system emoji. Display names where copy talks to a person.

## Viewports (every time)

Phone is not a secondary check.

| Target | Size | Input |
| --- | --- | --- |
| iPhone 16 | **393x852** | touch |
| ROG Ally X | **1920x1080** handheld | touch + gamepad, sometimes mouse/keyboard |
| Desktop | **1920x1080** | mouse + keyboard (P1 default); pad for P2 |

Screenshot. **Read the PNG.** Never report visuals from a git diff, a scene tree, or a Control rect. Check safe area / notches on the phone layout. Hub tabs along the **bottom**; combat buttons right, stick left; tabs **hidden in a run**.

## Art rules

- **No emoji.** Icons are hand-built stamps, staples, cape, web, heart stamps — Godot `TextureRect` / SVG / pixel sprites, not emoji fonts and not a React `GameIcon` unless that node exists here (it does not).
- Generated images (ElevenLabs `creative_generate_image` or similar) are **references to hand-code against**. Clean in Aseprite or Pixelorama. Never ship a raw generate as the game sprite.
- References live in **this** repo (`assets/`, `docs/game-plan.md`). Do not pull Waterdrop `referens bilder` or `timmi\waterdroppixi` paths.
- Sharp, crisp, light and shadow. Characters ~72 px tall. Colored outline + silhouette (The Son lemon, The Father brick).
- Menus look like finished product. This is Godot **Control** / **Node2D**, not a canvas-in-browser rectangle.

## Blood / gore (quality bar)

Blood is a **simulator**, not one sprite: heartbeat pump, pulse, spray, drop, drip, pool, squirt, splash, splatter, V-cone from wounds (neck and similar). Gravity and air. Stains on enemies and surroundings.

**10 hit + 10 kill** animations per weapon / projectile / element, matching the weapon. Shotgun spread vs range, blade cleaves, freeze / fire / spark, headshots. Soldier of Fortune-level gore, more realistic. Character built in **parts**.

Do **not** copy any Waterdrop three.js / broken 2.1 blood simulator as code — use it as **intent** only. Implement in **Godot 2D** (and 2.5D lighting) at **60 fps hard**. Data: `vfx_catalog.json` keys `weapon.element.situation.intensity`, plus a fallback. Light hits may only flash red. **Less Gore** toggle (game plan) keeps finishers, strips dismemberment; default is full.

## Do not port from Waterdrop

- TCC / Hearthstone / Gwent / Pokémon pet cards / 100-card decks
- Pixi.js, React menus, `overhaul.css`, GlowFilter, `waterdrop-lighting`, `waterdrop-svg-materials`, `waterdrop-pixi-pitfalls`, `waterdrop-critique`
- `localStorage` `wds.save.v1`
- Rank H20 (HnT account is Family Profile + **Rep** + CBT Tree)
- npm / SVG-filter performance notes as copy-paste; translate the lesson to Godot
- "Canvas menus" as the menu stack

## Non-negotiables

- Recount numbers from source files, never memory.
- Backup Family Profile JSON before testing.
- Grep first. Never a second copy of an existing system.
- Do not redesign what Timmie is happy with.
- English only.
- Roles: The Father, The Son. Display names at character create.
- 60 fps hard. Godot **4.7.2** GDScript. Repo `timmie-dev/HnT`.
- One `Camera2D` in a run. Split-screen only in **Build Compare**.
- Shared lives, Parenting Slap, fail for both.

## What done means

- Bugs found before work are fixed or explicitly out of scope.
- Real games named; gap stated.
- The thing is measurably **BIGGER**.
- It carries HnT theme and humour.
- Performance measured (fps / profiler), not guessed.
- Sound + visible feedback on every meaningful action.
- All three viewports screenshotted; PNGs looked at.
- Godot tests run, or an explicit "no harness yet" with scene-play notes.
- Second visual polish after the second bug hunt.
- The report is true, including what you did **not** do.

## Scope honesty

A full superpolish of a real system is multi-session. Say so up front. Ship reviewable pieces. If blocked, finish everything else and state what was left. Do not claim stage 8 if you only did stage 6.
