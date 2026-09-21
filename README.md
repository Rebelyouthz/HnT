# HnT — Revenge & Therapy

Couch, **solo**, or **remote Host/Join** brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

Playable tonight: **The Basement Clinic** hub, then **five Raven Wharf acts** — Dock Street, The Fire Escapes, Neon Exchange, Rail Bridge, City Hall (Mayor Raven). Solo spawns fewer enemies. Couch 2P keeps the full roster. Drop-in does **not** restock punks. Remote: The Son Hosts, The Father Joins.

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

Default listen: HTTP `8787`, TCP relay `8789`. Change the URL in Session Settings if the Father is on another PC (point it at the machine running rooms).

## What is playable (`godot --path .`)

Hub first. Clinic **GO TALK TO THE LANDLORD** starts **solo immediately**.

**Run tab**

- **SOLO** (default) — one body. 3 punks per act (City Hall 3 + Mayor Raven).
- **COUCH 2P** — both bodies, 6 punks per act, same device, one Camera2D.
- **HOST (THE SON)** — one button. Waiting screen: huge **room code**, **IP (backup)**, status **WAITING FOR FATHER**. Cancel Host.
- **JOIN (THE FATHER)** — paste room code (preferred) or expand **IP (backup)**, **Connect**. Status Connecting… then **Direct** or **Relay**.

Connect pipeline (automatic, no extra taps): same LAN UDP → UPnP/direct (~3 s) → TCP relay through HnT Rooms. Room code is the product. IP is Timmie's backup.

Pad **Start** or keyboard **P** drops the empty chair in a local run. Enemies stay the count you booked. Remote already has two bodies.

### Acts

1. **Dock Street** — street + roofs, 24/7 Blood Mart, continue to roofs.
2. **The Fire Escapes** — Vector gaps, Roof Vendor (ammo / card reroll).
3. **Neon Exchange** — agents + police, wanted ladder, **Pawn & Plate** (tape, pipe, sell pickup).
4. **Rail Bridge** — street under, roofs on boxcars, drones / toll bots, **Toll Booth** (grenade, spark ammo).
5. **City Hall** — climbable statues, **Mayor Raven** (street / roof / lights-out). SNAP after stun. No shop.

Wanted 3 = extra patrol. Wanted 5 = heli spotlight.

- **The Son:** hold jump in the air = cape stall. L = Cape Guard. O = batwing (mag 3). Jump-kick, dive, slide, light-light-heavy launcher, light-light-special string.
- **The Father:** `;` near a lamp = web 80–280 px. Jump or `;` again = slingshot. `'` = snare. Up+shoot with a grenade = a boundary with a timer.
- **SNAP:** sprint a back, vault a head, slide, web-in, or cape-dive. World ×0.22.

Shared **3 lives**. Solo downed respawns faster. Co-op: hold SNAP on the body for the Parenting Slap.

## Host / Join steps

**The Son (Stockholm)**

1. Run tab → **HOST (THE SON)**.
2. Text Timmie the 6-character code. Do not explain the IP.
3. Wait. Status stays **WAITING FOR FATHER** until he connects. Then Dock Street starts with co-op density.

**The Father (Dalarna)**

1. Run tab → **JOIN (THE FATHER)**.
2. Paste the code. **Connect**.
3. If Direct fails, relay kicks in by itself. Expand **IP (backup)** only if the code cannot resolve (same LAN, rooms down).

Two Godot windows on one PC: Host, then Join with the same code. LAN should win.

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

**Pad (Xbox layout).** 0 pads: keyboard. 1 pad: that pad is P2 (The Father) once he exists; P1 stays keyboard. 2 pads: pad 0 The Son, pad 1 The Father.

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

On a remote Join, The Father uses **P1** on his machine (keyboard or his pad). The Son stays host-authoritative.

## Hub

Clinic, Run, Build, Locker, Awards. Clinic + Run start unlocked. Family Profile at `user://family.json`.

## Layout

```
scenes/     hub + five act scenes
src/        actors, camera, combat, juice, world, ui, coop, net
data/       buildings, awards, milestones, CBT, cards, shop, encounters
tools/      hnt_rooms.py (room codes + TCP relay)
assets/     audio + icon
```

Encounter counts live in `data/encounters.json`. Recount from that file, not from memory.

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
