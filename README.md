# HnT — Revenge & Therapy

Couch **or solo** brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

Playable tonight: **The Basement Clinic** hub, **Dock Street**, then **The Fire Escapes**. Same maps and systems whether you sit one chair or two. Solo spawns fewer enemies so a single body can file the street. Couch 2P keeps the full roster. Drop-in does **not** restock punks.

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

## What is playable (`godot --path .`)

Hub first. Clinic **GO TALK TO THE LANDLORD** starts **solo immediately** — nobody has to plug in P2.

**Run tab** is where you pick the chair:

- **SOLO** (default) — one body (The Son or The Father on P1). Dock Street 3 punks. Fire Escapes 3 punks.
- **COUCH 2P** — both bodies, full roster (6 + 6). Shared lives, leash camera, Family Therapy.

Pad **Start** or keyboard **P** drops the empty chair in mid-run. Enemies stay the count you booked.

- **Two planes, one Camera2D.** Street Y-band + roof gravity. Leash only when two bodies exist.
- **The Son:** hold jump in the air = cape stall. L = Cape Guard. O = batwing (mag 3). Jump-kick, dive, slide hitbox, light-light-heavy launcher.
- **The Father:** `;` near a lamp = web 80–280 px. Jump or `;` again = slingshot. `'` = snare.
- **SNAP:** sprint a back, vault a head, slide, web-in, or cape-dive. World ×0.22. Confirm with light or SNAP.
- **Blood Mart** (Dock Street) is a checkpoint shop, then **The Fire Escapes** with a **Roof Vendor** (ammo 4 scrap, card reroll 1 scrap).
- Shared **3 lives**. Solo downed respawns faster (no partner to slap). Co-op: hold SNAP on the body for the Parenting Slap.

Local 2P and solo. Remote Host/Join is still the next delivery.

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

Phone: on-screen stick left, combat right. Hub tabs hidden in a run.

## Hub

Clinic, Run, Build, Locker, Awards. Clinic + Run start unlocked. Build the Therapy Couch, Wardrobe Cage, Trophy Cabinet to open the rest. Claim Gold/Gems from daily **Today's Coping Goals**, lifetime **Family Progress**, and Awards. Family Profile at `user://family.json`.

## Layout

```
scenes/     hub + Dock Street + Fire Escapes
src/        actors, camera, combat, juice, world, ui, coop/party.gd
data/       buildings, awards, milestones, CBT, cards, shop, encounters
assets/     audio + icon
```

Encounter counts live in `data/encounters.json`. Recount from that file, not from memory.

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
