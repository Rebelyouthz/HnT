# Agent setup: tools, MCP servers, skills, keys

Everything the Claude Code session used on branch `claude/gallant-galileo-5ctrmf`,
so the Cursor agent can do the same. Read `docs/HANDOFF_PIXEL_PIPELINE.md` first.

**Secrets never go in git.** Keys are read from environment variables. Timmie
sets the values in Cursor (Settings -> environment / MCP config), not in this
repo. The variable names are fixed below.

| Variable | What | Where Timmie gets it |
| --- | --- | --- |
| `HF_TOKEN` | Hugging Face token (ZeroGPU image models, image-to-3D, video) | huggingface.co/settings/tokens (fine-grained, "Make calls to Inference Providers" + read) |
| `AUTOSPRITE_API_KEY` | AutoSprite MCP (sprite sheets from video, rigged 3D models) | autosprite.io account |

## Local tools

```bash
bash tools/cloud_setup.sh                      # Godot 4.7.2 into ~/tools, import, both test suites
pip install pillow numpy scipy gradio_client   # slicer, backdrop snapper, HF client
# Blender 4.5 LTS (3D -> sprite renderer), headless:
curl -sSL -o blender.tar.xz https://download.blender.org/release/Blender4.5/blender-4.5.14-linux-x64.tar.xz
tar -xf blender.tar.xz -C ~/tools
# Screenshots with a real renderer on Linux:
sudo apt-get install -y xvfb nsis
```

On Windows the same works natively (Godot/Blender GUI builds; Python from python.org).

## Resolution, in one paragraph

The game renders at the **window's full resolution** (1920x1080 on a 1080p
screen, fullscreen by default). `640x360` is only the coordinate system that
positions are written in, not a render size. Before this branch the game drew
into a real 640x360 image and stretched it 3x, so a 1080p screen only ever
showed 640x360 real pixels and sprites came out ~45 px tall. Now sprites carry
4.5 texels per world unit and the camera zooms 1.5x, so on 1080p every sprite
pixel is one screen pixel (a standing body is ~198 real pixels tall).
Do not go back to `stretch/mode = "viewport"`.

## MCP servers

### AutoSprite (sprite sheets + rigged 3D)
Cursor `.cursor/mcp.json` (keep the key in the env, not in the file):
```json
{
  "mcpServers": {
    "autosprite": {
      "url": "https://www.autosprite.io/api/mcp",
      "headers": { "Authorization": "Bearer ${env:AUTOSPRITE_API_KEY}" }
    }
  }
}
```
Claude Code CLI equivalent:
`claude mcp add autosprite https://www.autosprite.io/api/mcp -t http --header "Authorization: Bearer $AUTOSPRITE_API_KEY"`

Useful tools: `upload_character` (our own art), `generate_spritesheet`
(idle/walk/run/attack/jump/custom, side view, from a generated video),
`regenerate_spritesheet` (free re-cut at another size/frame count),
`generate_character_3d_model` (rigged GLB, 50 credits),
`generate_character_3d_animations` (5 credits per clip: punch_jab, kick,
hit_chest, hit_knockback, death, roll, jump_*, sprint_*, kip_up, ...).
Account had 25 credits on 2026-09-29.

Pipeline for 8 directions + real lighting: `upload_character` ->
`generate_character_3d_model` -> `generate_character_3d_animations` ->
download GLB -> `blender -b -P tools/render3d.py -- model.glb out/ --dirs 8`
-> albedo + normal-map frames -> pack like `tools/slice_sprites.py` does.

### Hugging Face
The HF MCP connector blocks Space calls (`gradio=none`), so call Spaces
directly with `gradio_client` and `HF_TOKEN`:
```python
from gradio_client import Client
c = Client("black-forest-labs/FLUX.1-Krea-dev", token=os.environ["HF_TOKEN"])
img, seed = c.predict(prompt="...", width=1344, height=768, api_name="/infer")
```
Verified working: `black-forest-labs/FLUX.1-Krea-dev` (backgrounds).
Did not work on the free quota: `zerogpu-aoti/wan2-2-fp8da-aoti-faster`
(image-to-video) - app error, likely the per-call GPU limit.
Candidates for image-to-3D: Hunyuan3D / TRELLIS Spaces. Free ZeroGPU quota is a
few minutes a day; HF PRO raises it.

### Gamma (already connected in Claude)
`generate_image` made the Dock Street backdrop (best quality so far). 70 credits
per image; 330 left on 2026-09-29.

## Skills

- `.cursor/skills/pixel-perfect-2d/SKILL.md` - rewritten for this pipeline. Follow it.
- `.cursor/skills/superpolish2/SKILL.md` - unchanged.
- Anthropic `game-character-sprites` skill (fixed-cell sprite packs, QA checks)
  - its imagegen step is replaced here by AutoSprite / 3D render.

## What worked and what did not

| Tried | Result |
| --- | --- |
| Old slicer (NEAREST shrink, per-frame fit) + viewport stretch 640x360 | Sprites ~45 px, soft, pink fringe, size popping between clips. Replaced. |
| New slicer (`tools/slice_sprites.py`) | Clean, consistent, 1:1 on 1080p. |
| Gamma image -> `tools/backdrop.py` (grid snap) | True pixel-grid backdrop. Dock Street done. |
| FLUX Krea with a short prompt | Wrong perspective, people in shot. Use long prompts (see backdrop prompt in the handoff) or Gamma. |
| Wan 2.2 video via free ZeroGPU | Failed (quota). Use AutoSprite `generate_spritesheet` instead. |
| Blender `tools/render3d.py` | Works: 8 dirs x 25 frames + normal maps in ~10 s on CPU. Needs a rigged model. |
