# HnT — Revenge & Therapy

Couch, **solo**, or **remote Host/Join** brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

The Basement Clinic billed them for family therapy they never attended. Mayor Raven holds the eviction **and** the invoice. They collect coping evidence so the clinic does not seize the apartment or the Son's tutoring license.

Playable tonight: hub, **intro film + comic + tutorial + second film**, **nine campaign maps** (six brawl acts + three survivor hours woven between the first three brawl acts), **Versus**, Host/Join. Solo spawns fewer enemies. Couch 2P keeps the full roster. Drop-in does **not** restock punks.

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

Default listen: HTTP `8787`, TCP relay `8789`. Change the URL in Session Settings if the Father is on another PC.

## How to start intro / tutorial

**First GO** (Clinic **GO TALK TO THE LANDLORD** or Run **GO ALONE** / **GO TOGETHER**) plays intake if `intro_done` is false in `user://family.json`:

1. **Film 1** — letterbox, silhouettes, the invoice.
2. **Comic** — three panels slam in.
3. **Tutorial Alley** — parkour ledge, pistol pickup, punch the dummy, walk right.
4. **Film 2** — then **Dock Street**.

**PAUSE** skips the current beat. **LIGHT / JUMP** advances a line.

Replay anytime: Run tab **PLAY INTRO**. Remote Host/Join skips intake and starts Dock Street so Stockholm does not wait through a movie.

## How to start Versus

Run tab **VERSUS**. Mortal Kombat-style **best of three**, The Father vs The Son, same kits, one camera.

- Keyboard: P1 WASD/JKL vs P2 arrows / `.` `/`
- One pad: keyboard P1, pad P2. Two pads: pad 0 / pad 1.
- Round splash, banter, finishers **GROUNDED** (Father) and **YOU'RE FIRED** (Son).
- **PAUSE** exits to the clinic.

## Campaign order (9 maps)

Brawl acts mix **parkour / gun / brawl** stretches (plaques). Every act: **miniboss**, later content, **boss** with portrait + name + sting + boss music. Parallax is **multi-layer and themed** on every map.

1. **Dock Street** — Collector Gant. Then a coping hour.
2. **The Intake Lot** (survivor) — flooded car park, magnet chips, elite pack, Lot Hydra. **Not** a Vampire Survivors meadow.
3. **The Fire Escapes** — Lease Hawk on the high ledge.
4. **Group Circle** (survivor) — courtyard share. The Facilitator.
5. **Neon Exchange** — Agent Prime. Pawn & Plate.
6. **The Waiting Room** (survivor) — fluorescent forever. Number 88.
7. **Rail Bridge** — Conductor 9. Toll Booth.
8. **City Hall** — Deputy Raven, then **Mayor Raven**. Continues.
9. **Invoice Pier** — distinct annex: water, cranes, chapel. Usher Prime, then **Dr. Splint**. Not a Dock Street palette-swap.

Survivor hours: Halls of Torment bar — density curve, pickup magnet, XP gems, elite packs, coping chests, extra level-up cards (`COPING MAGNET`, `ORBIT FORM`, `DRIP FEED`, `VACUUM HOUR`). Solo thinner spawn + slower horde. Co-op denser.

Wanted 3 = extra patrol. Wanted 5 = heli spotlight. Unchanged on brawl maps: seed encounters stay **solo 3 / coop 6**.

## Host / Join

**The Son (Stockholm):** Run tab → **HOST (THE SON)** → text the 6-character code.

**The Father (Dalarna):** **JOIN (THE FATHER)** → paste code → **Connect**. Direct, then automatic relay.

Connect pipeline: LAN UDP → UPnP/direct (~3 s) → TCP relay. Room code is the product.

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

New pickups: **board**, **pistol** (six shots) in gun stretches, plus pipe / knife.

## Hub

Clinic, Run, Build, Locker, Awards. Family Profile at `user://family.json`.

## Layout

```
scenes/     hub + intro, tutorial, nine acts, versus
src/        actors, story, survive, vs, juice, world, ui, coop, net
data/       story, buildings, awards, CBT, cards, shop, encounters
tools/      hnt_rooms.py, synth_story.py
assets/     audio + icon
```

Encounter counts live in `data/encounters.json`. Recount from that file.

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
