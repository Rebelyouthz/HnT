# HnT — Revenge & Therapy

Couch co-op brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

This repo slice is playable: **The Basement Clinic** hub (Aliens vs Zombies: Invasion layout — bottom tabs, buildings unlock menus, daily/lifetime chests, `!` badges) and a **Dock Street** stub (two bodies, leash camera, light = red flash, heavy = hitstop).

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

## Controls

| Action | The Son (P1) | The Father (P2) |
| --- | --- | --- |
| Move | A/D, W/S | Arrows |
| Jump | Space | Ctrl |
| Light | J | `.` |
| Heavy | K | `/` |
| Pause | Esc | P or Start |

Pad: Xbox layout on device 0 (P1 extras) and device 1 (P2). Phone: on-screen buttons.

## What this slice is

- Hub tabs: Clinic, Run, Build, Locker, Awards. Clinic + Run start unlocked. Build the Therapy Couch, Wardrobe Cage, Trophy Cabinet to open the rest.
- Claim Gold/Gems from daily **Today's Coping Goals**, lifetime **Family Progress**, and Awards. Nothing grants silently.
- Family Profile at `user://family.json`. Name both characters on first launch.
- Dock Street: walk, jump, street-band depth, punch Bag Snatch. End Session from pause to count a run.

Not in yet: SNAP, web, cape, full Raven Wharf, remote Host/Join, ElevenLabs banks. Those follow this vertical slice.

## Layout

```
scenes/     hub + Dock Street
src/        GDScript (actors, camera, juice, ui)
data/       buildings, awards, milestones, CBT JSON
assets/     audio + icon
```

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
