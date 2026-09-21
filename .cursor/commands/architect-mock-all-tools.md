---
name: architect-mock-all-tools
description: Use when a simulation test needs every tool call mocked so runs are deterministic and never hit live systems. Fires on "mock all tools", "mock the tools in this test", "the test says no mock matched", "tool returned an error in my test run", "stop my test calling the real API"...
---

# /architect-mock-all-tools

Load and follow the project skill **`architect-mock-all-tools`** before doing any work.

1. Read `.cursor/skills/architect-mock-all-tools/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/architect-mock-all-tools` appears in Cursor's `/` menu after a window reload.
