---
name: survivor-bullethell-design
description: "Use for ANY balance/design work on the survivor / BONE YARD modes of Father & Son (Godot): wave/spawn pacing, boss design, XP/leveling curves, weapon/card power balance, difficulty tuning, or performance for 50+ simultaneous enemies (roguelike/bullet-hell/ARPG/survivor genre, Vampire Survivors-like). Triggers on: wave, spawn rate, boss, balance, difficulty, leveling, level up, XP curve, power curve, DPS, enemy scaling, wave pacing, run length, meta progression, 50 enemies, bullet hell, roguelike balance."
license: MIT
---

# Survivor / bullet-hell / ARPG design

Genre-expert reference for balancing a Vampire Survivors-like: top-down,
auto/semi-auto weapons, huge enemy counts, timed waves, run-based meta
progression. Written for the sister project Waterdrop Survivor (JS/Pixi);
the design principles carry over unchanged to Father & Son's survivor hours
and BONE YARD (Godot: `src/survive/`, `src/combat/bone_yard.gd`,
`data/*.json`). File paths and `waterdrop-*` skills named below belong to
that project - read them as examples, not as files here. This skill is for
numbers, pacing and structure; visuals go through `superpolish`.

## The genre's core loop and why it's fun

1. **Power grows faster than the player's skill ceiling requires** — the fun
   is watching your build snowball, not landing precise inputs. Enemy
   scaling exists to keep pace with that growth, not to punish it.
2. **Decisions happen between waves of chaos, not during them** — level-up
   card picks are the strategic layer; the 30 seconds after are just
   "survive and watch numbers go up." Don't design mid-combat
   decision-making that competes with screen-clearing spectacle.
3. **The screen should feel dangerous but readable** — 50+ enemies on
   screen only works if enemy *silhouettes and colors* stay legible (see
   `waterdrop-lighting`'s color-identity rule: an enemy's own color must
   never get drowned out) and if damage numbers/hit-feedback don't spam
   into unreadable noise.

## Wave/spawn pacing — this project's actual curve as a worked example

`WAVE_TIMELINE` in `data.js` is a sequence of `{ t, spawn, types, event? }`
checkpoints; `waveAt(time)` picks the last checkpoint `≤ time`. `spawn` is
enemies-per-second (`spawnInterval = 1 / (spawn * spawnMultExtra)` in
`engine.js:spawnWave`), and after `t=300`s there's a chance of double-spawns
per tick (`n = 1 + (rand < time/600 ? 1 : 0)`).

Current curve (0–540s = the "campaign", 540s+ = endless):

| t (s) | spawn/s | notable |
|---|---|---|
| 0 | 1.4 | slime only — a true tutorial breath |
| 20/45/75 | 1.8/2.2/2.6 | ramps enemy *variety* before *density* |
| 110 | 3.0 | **first boss** (bossOcular) |
| 145–230 | 3.2→3.8 | mid-game variety (crystalite/soulshard/charger) |
| 280 | 4.0 | **2nd boss** (bossNecromancer) |
| 430 | 5.0 | **3rd boss** (bossVoidTitan) |
| 540 | 6.0 | **final boss** (bossAida) — campaign end |
| 620+ | 7.0→14.0 | endless, boss every ~120s, spawn rate keeps climbing |

**Design principles this curve follows — keep following them when editing:**

- **Introduce variety before density.** Every early checkpoint adds a new
  enemy TYPE at a similar-or-only-slightly-higher spawn rate, never both a
  new type AND a big density jump in the same beat — that's how players
  learn a new silhouette/threat without being overwhelmed learning it.
- **Boss beats are pacing anchors, not just DPS checks.** Each boss arrives
  right after a density/variety ramp, giving a "the wave was building to
  this" feeling, then the checkpoint right after a boss drops in fresh
  enemy types (a breather + new content, not "more of the same but harder").
- **Endless-mode curve must diverge from campaign-mode curve.** Endless
  spawn-rate deltas (7→8→9.5→11→12.5→14, i.e. accelerating) exist because a
  flat/linear endless ramp gets either trivially easy (build outscales
  linear enemies) or brick-wall-hard at a fixed point — an accelerating
  curve keeps "how far did you get" meaningful as a leaderboard stat.
- **`e.dmgMult = 1 + bossesKilled * 2.0`** (plus a further `×2.5` for
  "heavy" square enemy types) is the actual power-scaling lever, not enemy
  HP alone — tying difficulty to *bosses defeated* (a player-paced
  milestone) rather than *pure elapsed time* means a player who is
  struggling and taking longer between boss kills doesn't get punished with
  ever-higher damage on top of already struggling; a player steamrolling
  bosses fast gets a harder ramp exactly because they demonstrated they can
  handle it. Prefer this "scale off player milestones" pattern over "scale
  off wall-clock time" when adding new scaling systems.

**When asked to "make waves better":** first ask what's actually wrong —
too easy/boring in a specific window, a specific enemy-type introduction
feels bad, endless mode flatlines, or bosses feel like DPS checks instead of
events. Tune the *specific checkpoint* (spawn rate, type list, or event
timing), don't rewrite the whole curve. A full rebalance pass should still
preserve the variety-before-density and boss-as-anchor shape above.

## Boss design

A boss beat needs, in order of importance:

1. **A readable telegraph** before its dangerous attacks (this codebase's
   boss guide-arrow system in `engine.js:updateBossArrow`/
   `pixiRenderer.js:_drawBossArrow` — a directional arrow + distance text
   that "dissolves" when the boss enters view — is the existing pattern for
   "here's a threat approaching," reuse/extend it rather than inventing a
   parallel system).
2. **A visually unique identity beyond palette-swap** — each current boss
   (`bossOcular`, `bossNecromancer`, `bossVoidTitan`, `bossAida`) has a
   distinct extra draw-pass in `_drawEnemies` (a pulsing eye, floating
   skulls, a void core, etc.), not just a bigger/recolored version of a
   regular enemy shape (`_enemyShapeFor`). Keep this pattern for any new
   boss — silhouette + at least one animated unique detail.
3. **A phase or pattern change at an HP threshold**, so a boss fight has an
   arc (calm → intense → desperate) instead of being a flat DPS race. This
   is explicitly on the project's backlog ("Boss fight polish: bigger HP
   bar, phase/special-attack warnings") — when asked to improve bosses,
   this is the highest-value addition, above new visual effects.
4. **HP tuned to fight LENGTH, not fight DIFFICULTY** — a boss fight should
   take roughly 20–45s at the player's expected power level for that
   checkpoint; if bosses die in <5s the fight isn't registering as an
   event, if they take >90s it stops feeling climactic and starts feeling
   like a slog. Tune HP to hit a time window, tune damage/attack patterns
   to hit a "this is dangerous but fair" feeling — don't use one stat to
   solve both problems.

## Leveling / XP / build power curve

- **XP requirement should grow roughly geometrically per level**
  (`addXp`/`_maybeLevelUp` in `engine.js`), not linearly — linear XP curves
  make levels feel identical throughout a run; geometric growth makes early
  levels frequent (fast dopamine, teaches the level-up-card system quickly)
  and late levels rarer-but-still-reachable (each one still feels earned).
- **In-run cards vs. meta upgrades are two different power budgets** —
  in-run cards (picked during a single run, lost on death) should be the
  primary, large power swings; meta upgrades (persistent across runs,
  bought with earned currency) should be *small* multiplicative nudges
  ("tiny meta increments" per this project's own PRD) that make repeat runs
  feel like genuine progress without trivializing the in-run choices. If
  meta power ever outweighs in-run card choices, the level-up screen stops
  mattering — that's the failure mode to watch for when adding new meta
  systems (this project already explicitly rebalanced toward this: "Vampirism
  card: 0.1% lifesteal, skill-tree locked" is a deliberately tiny number).
- **Never let a single card/weapon evolution trivialize the wave curve.**
  When adding a new weapon/card, sanity-check it against the *current* wave
  curve's expected DPS-needed-to-survive at a few checkpoints (t=110,
  t=280, t=540), not just "does it feel good in isolation."

## Damage/difficulty tuning checklist

When asked to rebalance combat numbers, check these levers in this order
(cheapest/most-targeted first):

1. Enemy `dmg`/`hp` in `ENEMIES` (data.js) — the most surgical, single-type fix.
2. `e.dmgMult` scaling formula in `spawnEnemy` — affects the whole late-game
   curve at once, use for "the game gets too hard/easy after boss N," not
   for "this one enemy type feels off."
3. `WAVE_TIMELINE` spawn rate/type list at a checkpoint — density/variety
   pacing, not raw numeric difficulty.
4. Player-side: `run.stats` multipliers (armor, dodge, regen), weapon base
   `damage`/`fireRate` in `data_ext.js` — the offense/defense side of the
   same equation; a "too hard" complaint can be fixed by enemy nerfs OR
   player buffs, pick based on whether the *feeling* is "enemies hit too
   hard" vs. "I can't deal enough damage."

Always change ONE lever per pass when responding to a specific complaint,
and say which lever you chose and why — rebalancing is iterative, and
stacking multiple simultaneous changes makes it impossible to tell which one
fixed (or broke) the feel.

## Performance for 50+ simultaneous enemies

This is a hard requirement for the genre, not a nice-to-have — bullet-hell
survivor games are *defined by* enemy-count spectacle. Patterns already in
use in this codebase, keep following them:

- **Object pooling everywhere** — `this.enemies`/`this.projs`/`this.parts`
  are pooled (`.acquire()`/`.release()`), never `new`'d and garbage-collected
  per-frame. Any new per-frame-spawned entity (new particle type, new
  projectile behavior) must go through the existing pool pattern, not a
  fresh array push.
- **One shared `Graphics` object per layer, cleared and redrawn per frame**
  (`gEnemies.clear()` then loop-and-draw), not one `Graphics`/`Sprite` per
  entity — PixiJS batches a single Graphics object's draw calls far better
  than hundreds of individual display objects. Only break this pattern for
  entities that need a real per-pixel shader (the lit player body/hydro
  projectiles use pooled `Sprite`s with filters — see `waterdrop-lighting` —
  because Graphics can't carry a per-object Filter cheaply at that count;
  everything else stays as shared-Graphics immediate-mode draws).
- **Cache expensive per-frame work that doesn't need to change every
  frame** — `_drawGround`'s starfield/nebula/grid and `_drawDeepSpace`'s
  parallax layers only rebuild when the camera has drifted past a padded
  threshold (~140px), not every frame; this was a measured "biggest win"
  perf fix in this project's history. Apply the same pattern to any new
  expensive-but-slow-changing visual.
- **Avoid O(enemies × projectiles) work becoming O(n²) blowups** — a few
  hundred distance checks per frame (enemies × nearby projectiles for
  light-tinting, AoE hit detection, etc.) is fine; make sure any new
  "for each enemy, for each other entity" loop has an early-exit distance
  check (compare squared distance before `Math.hypot`, or skip once outside
  a small fixed radius) so it stays cheap even as both counts grow.
- **Throttle non-rendering side-channels** — React/HUD state sync was
  throttled to ~30Hz separately from the render loop because PixiJS runs
  the sim loop far faster than React's reconciler wants to be called;
  anything that talks to React, network, or does string/JSON work every
  frame should be throttled independently of the render/physics tick.
- **Quality tiers** (`_qualityHigh` flag already gates some particle counts
  in `spawnBrutalKill`/`spawnHitSparks`) — when adding expensive new
  effects, gate the expensive variant behind the existing quality flag
  rather than assuming high-end hardware.

## Genre landscape — where Waterdrop Survivor sits, and what to borrow

Two dominant structural models in this genre, confirmed by comparing actual
shipped games (Vampire Survivors vs. Brotato):

- **Continuous positioning model (Vampire Survivors)**: one uninterrupted
  ~30-min run, single input verb (move — no manual aim/attack timing),
  difficulty is a single accumulating global multiplier ("Curse") applied to
  preset enemy stats, increasing roughly per-minute — players often aim for
  something like +150% Curse by minute 10 and +280% by minute 20 as a
  survivable pace. Positioning/kiting IS the skill expression.
- **Timed-wave + shop model (Brotato)**: runs are chopped into 20–60s waves,
  each followed by a shop/build phase — the strategic layer is concentrated
  into discrete decision points between bursts of combat, not woven
  continuously through it. Build diversity comes from restricted starting
  characters (e.g. a one-weapon-only character with huge attack speed, or a
  pacifist harvest-economy character) forcing genuinely different playstyles
  per run, not just different power levels.

**Waterdrop Survivor is a continuous-positioning-model game** (`WAVE_TIMELINE`
never pauses combat for a shop phase; meta shopping happens in Camp,
between runs, not between waves within a run). This is a structural
identity, not an accident — if a future request asks for "wave breaks" or
"a shop between waves," that's a request to change the fundamental model
(closer to Brotato), not a small tweak, and is worth confirming explicitly
before building since it reshapes pacing, UI, and the level-up-card economy
all at once.

**Direct parallel worth knowing**: Vampire Survivors' "Curse" is the same
kind of lever as this project's `e.dmgMult = 1 + bossesKilled * 2.0` — a
single global multiplier on preset enemy stats — except Curse scales off
wall-clock time and this project deliberately scales off a player milestone
(bosses killed) instead (see "Wave/spawn pacing" above for why that's the
better fit here). If a future balance pass ever wants a pure time-based
secondary ramp layered on top (e.g. a slow "curse-like" drift alongside the
milestone-based jumps), that's a reasonable, genre-precedented addition —
just don't let it replace the milestone-based scaling, only supplement it.

**Dopamine cadence principle** (Vampire Survivors' defining feel): the game
"barely lets you go a few seconds without something good happening" — XP
orbs, level-ups, chests, drops, constantly overlapping. This project's own
PRD independently arrived at the same principle ("Polish + Dopamine" pass:
claim-burst animations, reward pops, hp-bar pulse, button shine). Treat any
new system (Dock Stations, Artifacts, the Patrol minigame) as needing this
same constant-small-reward cadence, not just a correct-but-flat number
going up.

**Character/loadout diversity (Brotato-style) as a future direction**: if
asked to add more replay variety beyond weapon/card RNG, restricted-loadout
starting characters (weapon-type limits, stat trade-offs baked into the
character itself rather than just skill-tree choices) is a proven pattern
worth proposing — but it's a new system, not implied by the current balance
backlog, so raise it as a suggestion rather than building it unprompted.

Sources: [Brotato vs. Vampire Survivors](https://videochums.com/article/brotato-vs-vampire-survivors), [Vampire Survivors vs Brotato: Which Should You Buy First?](https://choostgames.com/blog/vampire-survivors-vs-brotato/), [Vampire Survivors Design Analysis — Power Fantasy](https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors), [Vampire Survivors Curse](https://rogueranker.com/vampire-survivors-curse/)

## When the user asks to "balance everything" / "make it feel right"

That's underspecified by nature — ask (or infer from recent play feedback)
which specific symptom they mean: too easy/hard at a specific time window,
a specific enemy/boss/weapon feeling off, runs feeling too
short/long/samey, or meta progression outpacing in-run choices. Then apply
the narrowest lever from the checklist above that addresses that symptom,
and say explicitly which number changed and the reasoning — same discipline
as the damage-tuning checklist, applied to the whole system.
