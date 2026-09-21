---
name: elevenlabs
description: Use the elevenlabs MCP server.
---

# /elevenlabs

Use the **elevenlabs** MCP server configured in `.cursor/mcp.json` (and/or the matching enabled plugin).

Generate music, SFX, and English VO for HnT via ElevenLabs MCP (`creative_generate_speech`, `creative_generate_sound`, image/video as references only — never ship raw generates as sprites).

If the MCP is disconnected, ask Timmie to authenticate it in Cursor Desktop → **Customize → MCP**. This Cloud Project chat may already have `elevenlabs` connected at the Project level even when the HnT repo file is not what this session loaded.
