---
name: fix-agent-qa-ticket
description: Fix an Architect QA triage ticket (agtqa_*) end-to-end via the raw agents API: fetch the ticket + conversation, find the root-cause procedure or prompt text, fix it on a branch, add + run a simulation test proving the fix, then post a summary comment on the ticket. Use when as...
---

# /fix-agent-qa-ticket

Load and follow the project skill **`fix-agent-qa-ticket`** before doing any work.

1. Read `.cursor/skills/fix-agent-qa-ticket/SKILL.md` (and its `references/` only if needed).
2. If this is HnT game work, also read `.cursor/skills/superpolish2/SKILL.md` when the request is polish/juice/hub/menus, and `.cursor/skills/router/SKILL.md` when the engine or discipline is unclear.
3. HnT is Godot 4.7.2 GDScript in `timmie-dev/HnT`. Do not port Waterdrop / Pixi / React / npm / TCC.
4. Do not overwrite Waterdrop Superpolish or other games' skill files.

This command exists so `/fix-agent-qa-ticket` appears in Cursor's `/` menu after a window reload.
