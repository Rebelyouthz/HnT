---
name: architect-generate-agent
description: Use when the user asks to generate, build, or create a new agent from a description ("create an agent for X", "build a chatbot that does Y"). There is no one-shot generate endpoint over REST; ask clarifying questions, then build via create and refine via patch.
---

# /architect-generate-agent

Load and follow the project skill **`architect-generate-agent`** before doing any work.

1. Read `.cursor/skills/architect-generate-agent/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/architect-generate-agent` appears in Cursor's `/` menu after a window reload.
