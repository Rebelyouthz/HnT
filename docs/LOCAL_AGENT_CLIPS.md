# Clips for the local agent (ROG Ally X)

**Svenska:** Det här är klippen som Hugging Face inte klarar (modellen
vänder gubben mot kameran, gör ett utfall i stället för en spark, eller
kvoten tar slut). Lokala agenten gör dem med `tools/local_gpu/local_wan.py`.
Kön ligger i `tools/local_gpu/queue.json` och innehåller bara de här 29
klippen. Klistra in `docs/LOCAL_AGENT_PROMPT.md` till agenten som vanligt.
Den här listan är bara facit: vad som ska göras och varför.

Run it the usual way (see `docs/LOCAL_AGENT_PROMPT.md`):
`git pull`, then from `tools/local_gpu` with the venv active:
`python local_wan.py --list` (should say 29 clips), then the priority
groups below with `--only <who>`, then plain `python local_wan.py` for the
rest. Push `tools/local_gpu/clips/*.mp4` after every few clips.

## Priority 1: HF failed these several times

| Clip file | Who | Move | Why HF failed |
|---|---|---|---|
| `bailiff_walk_back.mp4` | bailiff | walks away from the camera (back view) | 3 tries; HF turns him around to face the camera |
| `lot_hydra_walk_back.mp4` | lot_hydra | walks away (back view) | HF keeps him facing front, standing still |
| `clipboard_flier_walk_front.mp4` | clipboard_flier | walks toward the camera (front view) | HF made a side-view run |
| `clipboard_flier_kick_front.mp4` | clipboard_flier | knee-high front kick | 2 tries, no kick (arms only) |
| `roof_runner_kick_front.mp4` | roof_runner | knee-high front kick | HF made a lunge step, not a kick |
| `bag_snatch_punch_free.mp4` | bag_snatch | punch with the free fist, bag kept | 4 tries; the bag vanishes or turns into a stick |
| `son_roll.mp4` | son | forward somersault and back up | 3 tries; the jacket morphs mid-roll |

## Priority 2: diagonal walks for the 8-way street movement

Each enemy below needs `walk_ur` (three-quarter back, walking up-right)
and `walk_dr` (three-quarter front, walking down-right). The game mirrors
them for the left side. Today they fall back to the straight up/down walk.

bailiff, lot_hydra, clipboard_flier, roof_runner, bag_snatch, punk, cop,
mohawk, shift_lead, valet, clamp_king (22 clips: `<who>_walk_ur.mp4`,
`<who>_walk_dr.mp4`).

## Priority 3: Mayor Raven (act 1 final boss) needs his own art

He borrows Collector Gant's clips under a charcoal tint and a cape drawn in
code. He needs a design first (Claude makes it with FLUX when the HF quota
is back and drops it in `tools/local_gpu/starts/mayor_raven.png`; skip him
until that file exists): a city mayor in a charcoal three-piece suit and
red tie, long black ninja cape, black raven-beak half mask, slicked grey
hair, throwing stars. Then the usual set: idle, walk, punch_high (throws a
star), kick_low, hurt, death, plus walk_up / walk_down. Deputy Raven (City
Hall mini boss) uses the generic punk today and could share the design in a
grey suit.

## Quality check before pushing

**Svenska:** Kör `python tools/check_clip.py tools/local_gpu/clips/*.mp4`
innan du pushar. Skriptet säger PASS eller FAIL per klipp och sparar en
bildremsa (`<namn>_check.png`) bredvid klippet. Pusha bara de klipp som
får PASS. Gör om de som får FAIL med ett nytt seed.

Every clip must match the ones already in the game, or it cannot be used:

- **832 x 640** pixels (landscape), 16 fps, 1.2-4 s.
- The character fills **about 67 %** of the frame height (65-70 %), with his
  **feet about 94 %** of the way down. That is what the start frame in
  `tools/local_gpu/starts/<who>.png` gives you: start every clip from that
  image, do not crop, zoom or re-frame it.
- Same size in every frame: no zooming camera, no character growing or
  shrinking.
- Never cut off at the frame edge (head, feet, a kicking leg).

`tools/check_clip.py` measures all of this against the clips already made
(`tools/clip_refs.json` holds the numbers), so a clip that passes it will
slice to the same size as the rest.

- The character stays the same person in the same clothes the whole clip.
- Walks: clear steps, feet lift, and the view matches the move (back view
  for `walk_back`/`walk_ur`, front for `walk_front`/`walk_dr`). A clip
  where he turns to face the camera in a back-view move is wrong: delete it
  and run again (the seed changes per run).
- Kicks and punches: the limb reaches out to the right and holds for a
  moment at full reach.
- Flat green background, nothing else in frame, camera never moves.

## After the push (Claude's side)

Claude pulls the clips, slices them with `tools/hf_queue2/slice_pass.py`
style settings (16-frame loops for walks, 12-frame strikes with the peak
frame as the hit), checks them in a preview strip, installs the good ones
with `install_pass.py` and names them in the game: `walk_back` →
`walk_up`, `walk_front` → `walk_down`, `kick_front` → `kick_low`,
`punch_free` → `punch_high`.

## Already done on HF (not in the queue any more)

clamp_king `kick_low` (pass 10), father/son run, skinwalker walk / crawl /
gape / dog, clipboard_flier / lot_hydra / clamp_king / coping_imp walks,
the 4 fps strikes and 8-frame hurts from passes 6-9.
