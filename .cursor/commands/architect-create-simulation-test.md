---
name: architect-create-simulation-test
description: Use when the user wants a full multi-turn conversation test where a simulated user talks to the agent across many turns. Fires on "test the whole flow", "simulate a caller", "write a scenario test", "test that the agent handles an upset customer / a full booking / a multi-step...
---

# /architect-create-simulation-test

Load and follow the project skill **`architect-create-simulation-test`** before doing any work.

1. Read `.cursor/skills/architect-create-simulation-test/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/architect-create-simulation-test` appears in Cursor's `/` menu after a window reload.
