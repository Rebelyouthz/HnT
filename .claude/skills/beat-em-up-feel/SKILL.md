---
name: beat-em-up-feel
description: Game feel for this beat 'em up / platformer - hit timing, hitstop, camera, squash, recoil, input buffering, readable feedback, miss vs hit, scale and readability. Use when touching fighter.gd, punk.gd, move_book.gd, juice.gd, blood.gd, HUD feedback, or when anything "feels weak, floaty, sluggish or unclear".
---

# Beat 'em up game feel checklist

The rule of thumb: **every input gets an answer within one frame, every
connect gets a body, a camera and a sound, and a miss looks different from a
hit.**

## Strike anatomy (src/combat/move_book.gd + fighter.gd `_begin_strike`)
- The hitbox opens on the clip's `hit` frame (JSON). A clip without `hit`
  falls back to "contact at 0.05 s" - always give strike clips a `hit` frame
  (`tools/strike_timing.py` for old boards; video2sprite `--hit-at`/reach for
  new ones; check by eye when the character holds a prop).
- Wind-up is capped by `startup_cap`; the art is sped up to reach its peak on
  the contact tick. Long extended holds after contact feel sluggish: keep at
  most one frame past contact, then retract fast.
- Stances (`ENTRY`) let a follow-up skip part of its wind-up: chains should
  feel faster than single hits.

## On a connect (`_strike_impact`)
- Hitstop scaled by weight (`stop`: jab 3 .. heavy 8-12 frames).
- `Juice.pulse_shake` (random trauma) **and** `Juice.kick(dir, px)` (a shove
  the way the blow travels - this is what makes light hits read).
- Attacker squash/stretch into the blow (`_squash_to`), victim recoil shake
  and head snap (`Punk._recoil`), small push-off on the attacker.
- Impact star/ring (`Juice.impact`) and the hit sound **only on a connect**.

## On a miss (`_strike_whiff`)
- Whoosh, a short air streak (`Juice.whiff`), over-commit drift, slower
  retract, longer recovery. No impact burst, no hit spark, no hit sound.
- "MISS" style popups must not reuse hit/explosion art.

## Getting hit / kills
- Player hurt: camera jolt toward the knock direction, crumple squash, red
  flash, short hitstop.
- Every kill: short freeze + shove. Last enemy of a fight: `Juice.last_kill()`
  slow motion (never in the coping-hour horde).

## Responsiveness
- Buffer presses made during recovery (`_light_buf`, `_heavy_buf`, `jump_buf`)
  ~9 frames and fire them the first free frame. Coyote time on jumps.
- Combo counter pops on every hit and heats in colour; keep it out of the
  speech-bubble column.

## Readability
- Fighters must read at the scale of the street: compare actor height with
  the painted doors (~1.0-1.1x a person's height to the door frame top),
  kerb and street lamps. Props (crates, barrels, bins, lamps, bike) follow the
  same yardstick. Measure in a 1920x1080 capture, do not guess.
- Feedback text: at most two toasts, nothing large over the fighting lane,
  lens blood only as a rare edge accent.
