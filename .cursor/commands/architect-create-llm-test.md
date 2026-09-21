---
name: architect-create-llm-test
description: Use when the user wants a single-turn test that checks WHAT the agent says for a given turn. Fires on "add a test that the agent greets the caller", "test that it always reads the disclosure", "make sure it refuses off-topic questions", "write an eval for this reply", or "add...
---

# /architect-create-llm-test

Load and follow the project skill **`architect-create-llm-test`** before doing any work.

1. Read `.cursor/skills/architect-create-llm-test/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/architect-create-llm-test` appears in Cursor's `/` menu after a window reload.
