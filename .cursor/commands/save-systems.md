---
name: save-systems
description: Design save/load for game state — choosing what to serialize, file formats, save slots, atomic crash-safe writes, schema versioning and migration, and autosave. Engine-neutral. Use when the user mentions save system, save/load, game state persistence, save slots, autosave, sav...
---

# /save-systems

Load and follow the project skill **`save-systems`** before doing any work.

1. Read `.cursor/skills/save-systems/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/save-systems` appears in Cursor's `/` menu after a window reload.
