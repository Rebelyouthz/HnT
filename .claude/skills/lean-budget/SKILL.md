---
name: lean-budget
description: "Keep token/credit/time cost low without lowering quality. Load at the start of every long task (superpolish, code review, art pipeline, builds) and whenever a session runs long or paid APIs (Sorceress, ElevenLabs, HF inference) are involved."
---

# Lean budget — spend on results, not on overhead

Quality is fixed; waste is what gets cut. Never trade away a test,
a screenshot check or a correct animation to save cost — cut the reading,
re-reading and guessing instead.

## Reading code
- Grep first (`Grep` with a tight pattern + glob), then Read only the line
  range you need (`offset`/`limit`). Never Read a 2000-line script whole to
  change one function.
- Don't re-read a file you just edited or already have in context.
- Use `head`/`tail` on logs and test output; Godot tests: read the last
  5–20 lines, and grep for `ERROR|FAIL|SCRIPT ERROR` instead of dumping all.
- No sub-agents unless Timmie asks — they start cold and re-read everything.

## Running things
- Batch independent commands/tests in one call or one parallel turn.
- Long Godot runs, builds and uploads: run in background and do other work,
  don't poll with sleep.
- Run the focused tests for the part while iterating; the full suite once
  before commit.

## Images and video
- Crop screenshots to the area under review before reading them; read one
  contact sheet instead of 12 frames.
- Capture at the game's native 640x360 (or the 1280x720 design canvas) — not
  1080p — unless checking fine pixel detail.

## Paid generators
- Sorceress credits are nearly gone: use Hugging Face pipelines
  (`tools/hf_hero_moves.py`, `tools/hf_react.py`) first.
- Before any paid/remote generation: write the exact prompt, the seed and the
  trim plan; generate one, check frames, only then batch the rest.
- Reuse existing clips/sounds (grep `assets/`) before generating new ones.
- Keys are never printed; mask any output that could contain them.

## Talking
- Short progress notes; no restating plans or summaries of what the diff
  already shows. The final report in Swedish is complete but tight.

## What is never cut
Tests before commit, visual check of every changed screen/clip, the second
bug hunt and second polish round of /superpolish, and the build + upload.
