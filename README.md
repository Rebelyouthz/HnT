# HnT — Revenge & Therapy

Couch co-op brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

Playable tonight: **The Basement Clinic** hub (Aliens vs Zombies: Invasion layout) and **Dock Street / Raven Wharf Act 1** — street + roofs on one camera, local 2P.

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

Hub first. **Run → GO TALK TO THE LANDLORD** loads Dock Street.

- **Two bodies, one Camera2D.** The Son (P1) and The Father (P2). Leash at 70% of the screen. Shake is camera offset, max not sum.
- **Street plane:** beat-em-up Y-band. Jump is ~80 px — it will not reach the roofs.
- **Roof plane:** real gravity. Fire escapes climb. Vault crates on the street. A gap that needs **cape glide** or **web**.
- **The Son:** hold jump in the air = cape stall. L = Cape Guard. O = batwing shuriken (mag 3, one ricochet off metal).
- **The Father:** ; near a lamp/beam = web pendulum (80–280 px). Jump or ; again = slingshot. ' = web snare.
- **SNAP:** sprint a back, vault a head, slide, web-in, or cape-dive. World ×0.22, press **F** / **N**. Miss and you are in their face.
- **Juice:** light = red flash. Heavy = white+red and hitstop. SNAP = freeze + `SNAP` number.
- **Steam** on both. Shared **3 lives**. Hold SNAP on a downed partner for the Parenting Slap. Reach **24/7 Blood Mart** together to file the street.
- Night lights: `CanvasModulate` + moon + three shadowed lamps. No emoji in the HUD.

Local 2P only. Remote Host/Join is still the next delivery.

## Controls

| Action | The Son (P1) | The Father (P2) |
| --- | --- | --- |
| Move | A/D, W/S | Arrows |
| Jump / glide | Space (hold in air) | Ctrl |
| Light | J | `.` |
| Heavy (hold to charge) | K | `/` |
| Special (cape / web) | L | `;` |
| Shoot (batwing / snare) | O | `'` |
| Dash / slide (down+dash) | Shift | Alt |
| SNAP / revive | F | N |
| Pause | Esc | P or Start |

Pad: Xbox layout, device 0 and 1. Dash = RT, SNAP = stick click. Phone: on-screen buttons.

## Hub

Clinic, Run, Build, Locker, Awards. Clinic + Run start unlocked. Build the Therapy Couch, Wardrobe Cage, Trophy Cabinet to open the rest. Claim Gold/Gems from daily **Today's Coping Goals**, lifetime **Family Progress**, and Awards. Family Profile at `user://family.json`.

## Layout

```
scenes/     hub + Dock Street
src/        actors, camera, combat, juice, world, ui
data/       buildings, awards, milestones, CBT JSON
assets/     audio + icon
```

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
