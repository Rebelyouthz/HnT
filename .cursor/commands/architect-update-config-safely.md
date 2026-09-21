---
name: architect-update-config-safely
description: Use when changing an agent setting (LLM, voice, TTS model, language, first message, ASR, guardrails, timeouts, turn-taking, data collection, evaluation criteria) and wanting it to actually apply, or on symptoms like "it won't save", "the change didn't take", "schema mismatch",...
---

# /architect-update-config-safely

Load and follow the project skill **`architect-update-config-safely`** before doing any work.

1. Read `.cursor/skills/architect-update-config-safely/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/architect-update-config-safely` appears in Cursor's `/` menu after a window reload.
