# HnT — Revenge & Therapy

Couch, **solo**, or **remote Host/Join** brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

The Basement Clinic billed them for family therapy they never attended. Mayor Raven holds the eviction **and** the invoice. They collect coping evidence so the clinic does not seize the apartment or the Son's tutoring license. The night is one plot: **story films between every act**, then a late-act climax on **The Processing Floor**.

Playable tonight: hub, **intro film + comic + tutorial + second film**, **fourteen campaign maps** (brawl + five survivor hours + chase crash + Invoice Pier + Processing Floor), **Versus**, Host/Join, **Options + Reset**, pinball scores, avatar gear. Solo spawns fewer enemies. Couch 2P keeps the full roster. Drop-in does **not** restock punks.

## Run locally

1. Install [Godot 4.7.2 Standard](https://godotengine.org/download) (not the .NET build).
2. Open this folder in the editor, or from a terminal:

```bash
godot --path .
```

Headless smoke:

```bash
godot --headless --path . --script res://tests/smoke.gd
```

Rooms (needed for room-code Join and the automatic relay). Host will try to start this itself:

```bash
python3 tools/hnt_rooms.py
```

Default listen: HTTP `8787`, TCP relay `8789`. Change the URL in **Options** if the Father is on another PC.

## How to see the inter-act films

Play a campaign run (**GO ALONE** / **GO TOGETHER** / Host). Clear an act (miniboss then boss). On the results sheet tap the **NEXT** button (or the named next act).

The game hops to a letterbox **act film** (SoR4 comic-between-stages):

1. **Chapter card** — act title.
2. **Lines** — The Father and The Son keep the plot moving.
3. Then the next map loads.

**PAUSE** skips the current beat (chapter card, or the rest of the film). **LIGHT / JUMP** advances a line. Same as the intro.

Remote Host/Join: both peers see the film. The host still advances; the guest gets `film_from` / `film_next` with the begin packet.

**Options → SKIP INTER-ACT FILMS** jumps the night straight to the next map. Intro films still play the first time unless you already filed intake.

Replay intro anytime: Run tab **PLAY INTRO**.

## How the final boss starts

1. File **City Hall** (Mayor Raven). Film to **Copay Orchard**.
2. File orchard → sleet → **Raven Grid** (chase crash) → **Ledger Dive** → **Invoice Pier**.
3. File **Invoice Pier** (Usher Prime, then Dr. Splint). Film to **The Processing Floor**.
3. Bandage desk at the start (24/7 Blood Mart). Mini **Adjuster Prime**. Then **The Family Plan** / Director Binder.

The Family Plan is the late-act climax, not a Mayor palette-swap:

- **Strip armor first.** Four plates. Lights go *CLINK*. Heavies strip plates. SNAP is denied until the suit is a receipt.
- After **ARMOR STRIPPED**, a long pattern fight: X-slash, horizontal sweep, triple slam, invoice rain, then frenzy.
- Portrait + boss sting, then **finale music** when the plates are gone.
- Dedicated **boss HP bar** (armor count while plated).
- **FILE ALIVE:** SNAP while stunned for extra gold (Huntdown take-alive). Still have to finish him.
- Pre-fight film on the way in. **Ending film** after the results **WATCH THE ENDING** button (or auto after the floor files).

## Campaign order (14 maps)

Brawl acts mix **parkour / gun / brawl**. Every act: **miniboss**, later content, **boss** with portrait + name + sting + boss music. Parallax is **multi-layer and themed**.

1. **Dock Street** — Collector Gant. Film.
2. **The Intake Lot** (survivor) — Lot Hydra.
3. **The Fire Escapes** — Lease Hawk.
4. **Group Circle** (survivor) — The Facilitator.
5. **Neon Exchange** — Agent Prime.
6. **The Waiting Room** (survivor) — Number 88.
7. **Rail Bridge** — Conductor 9.
8. **City Hall** — Deputy Raven, then **Mayor Raven**.
9. **Copay Orchard** (brawl, farm/lake/forest/fields) — Scarecrow Ken, then Combine Brute.
10. **Sleet Hour** (survivor, snow) — Plow Cop, then Snowmobile.
11. **Raven Grid** (brawl, cyberpunk + chase) — Grid Kid, lemon courier chase, canal crash, then Invoice Chopper.
12. **Ledger Dive** (survivor, flooded vault / brine spa) — Vault Guard, then Cenote Elite.
13. **Invoice Pier** — Usher Prime, then **Dr. Splint**.
14. **The Processing Floor** — Adjuster Prime, then **The Family Plan**. Ending film.

Survivor hours sit between/after their pair. Solo thinner spawn + slower horde. Co-op denser. Seed encounters stay **solo 3 / coop 6** on every map.

### How the Raven Grid chase starts (and ends)

1. File **Grid Kid** (miniboss). Toast: steal the lemon clinic courier.
2. Walk past **x 1320**. The van spawns. **The Son drives**, **The Father rails 360°**. SPECIAL swaps. Solo: stick steers, shoot 360, SPECIAL hops rail. Not a mil truck.
3. Mix: on-foot before the steal, van through the underpass, then **forced onto a ramp**.
4. **Slow-mo** from in front of the ramp: debris, enemies, the lemon **skewed / tumbling / upside-down**. Close-ups: Father **NOOOO**, Son **AAAA**.
5. New camera. The van **crashes on the far side of the canal**. Enemies do not follow.
6. Gameplay: they **crawl out of different spots**, talk (black humor), then **Invoice Chopper walks in**. The crash is the boss intro.

Wanted 3 = extra patrol. Wanted 5 = heli spotlight.

## Pinball, results, death

Everything scores. Father vs Son on the same run (HUD bottom, pause overlay). After every act and on death: results sheet with table scores, winner line, **account XP bar**, toasts, HIGH TABLE if you beat the fridge. Death still grants XP. High table lives on the Family Profile. Versus ends with the same XP bar energy.

## Avatar / rarity

Locker is clothes / hats / shoes plus Profile **frames / banners / badges**. Every piece has stats and three upgrades. **Common → Uncommon → Rare → Epic → Legendary** on cards, gear, CBT, awards, shop, pickups, crates, cosmetics, research, dojo ranks. Colored borders. Legendary juice. Pause shows the pinball table.

## Options / Reset

Hub **OPTIONS**: volumes, gore, PIN, rooms URL, skip films, **RESET PROGRESS**. Reset asks confirm (**THIS IS GROWTH**), writes `user://family.json.bak` first, then wipes.

## Host / Join

**The Son (Stockholm):** Run tab → **HOST (THE SON)** → text the 6-character code.

**The Father (Dalarna):** **JOIN (THE FATHER)** → paste code → **Connect**. Direct, then automatic relay.

Connect pipeline: LAN UDP → UPnP/direct (~3 s) → TCP relay. Room code is the product. Ports unchanged: game `24567`, rooms HTTP `8787`, relay `8789`.

## Controls

| Action | The Son (P1) | The Father (P2, after join) |
| --- | --- | --- |
| Move | A/D, W/S | Arrows |
| Jump / glide | Space (hold in air) | Ctrl |
| Light / string | J | `.` |
| Heavy (hold to charge) | K | `/` |
| Special (cape / web) | L | `;` |
| Shoot (batwing / snare) | O | `'` |
| Dash / slide (down+dash) | Shift | Alt |
| SNAP / revive | F | N |
| Pause | Esc | P or Start (P also joins if the chair is empty) |

**Pad (Xbox layout).** 0 pads: keyboard. 1 pad: that pad is P2 once he exists; P1 stays keyboard. 2 pads: pad 0 The Son, pad 1 The Father.

| Action | Button |
| --- | --- |
| Move | Left stick / D-pad (radial deadzone 0.22) |
| Jump / glide | A |
| Light / SNAP confirm | X |
| Heavy | Y |
| Special | B |
| Shoot | RB |
| Block | LB |
| Throw | LT |
| Dash / slide | RT (RT + down = slide) |
| SNAP | Right stick click |
| Pause / drop-in | Start |

On a remote Join, The Father uses **P1** on his machine. The Son stays host-authoritative.

## Hub

Clinic, Run, Build, Locker, Awards. Family Profile at `user://family.json`.

### Profile / account

**Top-left avatar** (names + LV) opens **Family Profile**. First launch still files names (intake). Rename lives on the Profile.

Profile shows account level, XP bar, avatar card with **frame / banner / badge**. Equip Steam-like **badges** as proof. Swap **avatar frame**, **profile banner**, and **badge**. Unlocks come from in-game accomplishments (runs, stomps, tricks, dojo masters, finale).

Red **new** dots sit on the avatar, the HnT logo, **every hub tab**, the run HUD banner, and the new item itself until you open Profile / the camp sheet and look at the reward. Big unlock logos always print **YOU GOT** plus the reward. Account **level-up** is a full overlay (XP bar, names, +8 gold, frame check).

### Camp buildings (Clinic tab)

The camp grid is the home screen. **BUILD** plays a carpenter animation in front of you. Upgrade expands stock.

| Building | Where | What |
| --- | --- | --- |
| **Camp Shop** | Clinic camp → BUILD CAMP SHOP → **OPEN** | Chests, lucky wheel, slots. Upgrade the stall: claw at lv2, scratch cards at lv3. Always shows what you got. |
| **Quick Patrol** | Clinic camp → BUILD QUICK PATROL → **OPEN** | **2×/day**, 12 minutes. Idle gold + XP + a coil **while the game is closed and while you play**. Claim when the alley comes home. |
| **Research Center** | Clinic camp → BUILD RESEARCH CENTER → **OPEN** | Silencers, extended mags, hollow rounds, recoil pads, tape wrap. Spend gold + parts. |
| **Martial Arts School** | Clinic camp → BUILD MARTIAL ARTS SCHOOL → **OPEN** | Learn / upgrade moves (uppercut, roundhouse, face stomp, vaults, landing roll). Rank 3 = master + shaolin badge. |
| **Workshop** | Clinic camp → BUILD WORKSHOP → **OPEN** | Craft from scrap coil, clinic thread, invoice ink. Gear + clothes + equipment are one character build. |

Patrol, research, and the dojo are **camp buildings**, not extra bottom tabs. Front Desk is already built (Profile). Street Map is already built (Run).

## Combat / parkour (this slice)

SoR4 mix: duck, jump, air attacks, uppercut (up+heavy), roundhouse (two lights then heavy), air mix (special in the air), dive (down+heavy in the air). Unique finishers score more. **Three stomps on a crushed face**: smash / pop / splash, brain on three. Father vs Son SFX (pitch + named clips). Footsteps scale with speed, silent in air, louder on stumble. High land: **landing roll** (down or dash) or stumble / hard fall.

Guns: unique caliber, recoil, muzzle flash, sparks, bullet holes. Blood simulator: spray, drip, run, pool, stain. HP changes how injured they look and limp.

Parkour gates show **three named tricks** (Vector): just-jump is easy. Up = mid. Special / dash = hard. Perfect window +5–10% speed. Fail: stumble / hard fall / splat and minus points. Combo multiplier stays on the pinball table.

## Layout

```
scenes/     hub + intro, tutorial, fourteen acts, films, versus
src/        actors, story, survive, vs, juice, world, ui, coop, net
data/       story, kits, gear, buildings, awards, CBT, cards, shop, encounters, cosmetics, dojo, research, tricks, dopamine
tools/      hnt_rooms.py, synth_story.py, synth_kit.py
assets/     audio + icon
```

Encounter counts live in `data/encounters.json`. Recount from that file.

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
