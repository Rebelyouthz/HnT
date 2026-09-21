# HnT — Revenge & Therapy

Couch, **solo**, or **remote Host/Join** brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

The Basement Clinic billed them for family therapy they never attended. Mayor Raven holds the eviction **and** the invoice. They collect coping evidence so the clinic does not seize the apartment or the Son's tutoring license. The night is one plot: **story films between every act**, then a late-act climax on **The Processing Floor**.

Playable tonight: hub, **intro film + comic + tutorial + second film**, **ten campaign maps** (six brawl acts + three survivor hours + Invoice Pier + Processing Floor), **Versus**, Host/Join, **Options + Reset**, pinball scores, avatar gear. Solo spawns fewer enemies. Couch 2P keeps the full roster. Drop-in does **not** restock punks.

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

1. File **City Hall** (Mayor Raven). Film to **Invoice Pier**.
2. File **Invoice Pier** (Usher Prime, then Dr. Splint). Film to **The Processing Floor**.
3. Bandage desk at the start (24/7 Blood Mart). Mini **Adjuster Prime**. Then **The Family Plan** / Director Binder.

The Family Plan is the late-act climax, not a Mayor palette-swap:

- **Strip armor first.** Four plates. Lights go *CLINK*. Heavies strip plates. SNAP is denied until the suit is a receipt.
- After **ARMOR STRIPPED**, a long pattern fight: X-slash, horizontal sweep, triple slam, invoice rain, then frenzy.
- Portrait + boss sting, then **finale music** when the plates are gone.
- Dedicated **boss HP bar** (armor count while plated).
- **FILE ALIVE:** SNAP while stunned for extra gold (Huntdown take-alive). Still have to finish him.
- Pre-fight film on the way in. **Ending film** after the results **WATCH THE ENDING** button (or auto after the floor files).

## Campaign order (10 maps)

Brawl acts mix **parkour / gun / brawl**. Every act: **miniboss**, later content, **boss** with portrait + name + sting + boss music. Parallax is **multi-layer and themed**.

1. **Dock Street** — Collector Gant. Film.
2. **The Intake Lot** (survivor) — Lot Hydra.
3. **The Fire Escapes** — Lease Hawk.
4. **Group Circle** (survivor) — The Facilitator.
5. **Neon Exchange** — Agent Prime.
6. **The Waiting Room** (survivor) — Number 88.
7. **Rail Bridge** — Conductor 9.
8. **City Hall** — Deputy Raven, then **Mayor Raven**.
9. **Invoice Pier** — Usher Prime, then **Dr. Splint**.
10. **The Processing Floor** — Adjuster Prime, then **The Family Plan**. Ending film.

Survivor hours: Halls of Torment bar. Solo thinner spawn + slower horde. Co-op denser.

Wanted 3 = extra patrol. Wanted 5 = heli spotlight. Seed encounters stay **solo 3 / coop 6**, including the new floor.

## Pinball, results, death

Everything scores. Father vs Son on the same run (HUD bottom, pause overlay). After every act and on death: results sheet with table scores, winner line, **account XP bar**, toasts, HIGH TABLE if you beat the fridge. Death still grants XP. High table lives on the Family Profile. Versus ends with the same XP bar energy.

## Avatar / rarity

Locker is clothes / hats / shoes. Every piece has stats and three upgrades. **Common → Uncommon → Rare → Epic → Legendary** on cards, gear, CBT, awards, shop, pickups, crates. Colored borders. Legendary juice. Pause shows the pinball table.

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

## Layout

```
scenes/     hub + intro, tutorial, ten acts, films, versus
src/        actors, story, survive, vs, juice, world, ui, coop, net
data/       story, gear, buildings, awards, CBT, cards, shop, encounters
tools/      hnt_rooms.py, synth_story.py
assets/     audio + icon
```

Encounter counts live in `data/encounters.json`. Recount from that file.

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
