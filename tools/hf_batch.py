"""HF ZeroGPU queue (FLUX designs + Wan 2.2 image-to-video clips) for enemy
animations. Runs in priority order; skips finished outputs; stops cleanly
on a ZeroGPU quota error and prints how long to wait.  python3 batch.py"""
import os, sys, re, shutil, time, json
from gradio_client import Client, handle_file
D = os.environ.get("HFV", "/tmp/claude-0/hfv")  # start images, designs, clips
tok = open(os.path.expanduser('~/.cache/huggingface/token')).read().strip()
TAIL = " Strict side view, locked static camera that never moves or zooms, facing right, full body always in frame, flat solid green background that never changes, no other people, realistic human motion with weight and momentum, keep the exact same pixel art style and outfit."
NEG = "camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, cropped body, turning toward camera, slow motion"
MOVES = {
 'npc_idle': (2.5, "{d} stands on the pavement waiting, shifting weight, glancing around and gesturing a little, calm, not fighting."),
 'idle': (2.5, "{d} stands in a loose fighting stance, breathing heavily and bouncing slightly, shifting his weight, ready to brawl."),
 'walk': (2.5, "{d} walks forward to the right with a menacing swagger, fists ready, steady pace."),
 'punch_high': (2.5, "{d} throws a hard right hook at head height with a big shoulder turn, then returns to his fighting stance."),
 'punch_mid': (2.5, "{d} steps in and throws a heavy straight punch at stomach height, leaning forward, then returns to his fighting stance."),
 'kick_low': (2.5, "{d} snaps a low kick at shin height with his right leg, then puts the foot back down in his fighting stance."),
 'hurt': (2.0, "{d} flinches hard as if shoved, his head jerks back and he staggers one step backward, then recovers his balance."),
 'death': (3.0, "Like a movie stuntman, {d} goes limp, collapses and falls backward flat onto the ground, and lies completely still."),
}
DESIGN = {
 "repo_goon": "a heavyset bald debt collection thug with a thick neck, a stained grey track jacket, a fake gold chain, cargo pants and work boots, knuckle tattoos, an angry face",
 "npc_old_woman": "a friendly elderly woman in a long purple raincoat and a headscarf, holding an empty dog leash, worried face",
 "npc_sanitation": "a friendly city sanitation worker in a green high visibility vest and work gloves, holding a broom, tired smile",
 "npc_old_man": "a frail friendly old man in a brown cardigan and slippers with a walking cane, grumpy but kind face",
 "bailiff": "an elite armored riot bailiff in a black tactical vest with the word BAILIFF on it, a dark helmet with a raised visor, knee pads, gloves, a short black baton on the belt, a cold expression",
}
STY_NPC = "detailed 16-bit pixel art video game character sprite in the style of Streets of Rage 4, crisp dark outlines, full body from head to shoes, strict side view facing right, standing relaxed, one single character centred, flat solid bright green background #00b832, no shadow, no text, no other objects"
STY = "detailed 16-bit pixel art video game character sprite in the style of Streets of Rage 4 and Final Fight, crisp dark outlines, full body from head to boots, strict side view facing right, standing in a fighting stance, one single character centred, flat solid bright green background #00b832, no shadow, no text, no other objects"
WHO = {'cop': 'The police officer', 'repo_goon': 'The bald heavyset thug in the grey track jacket', 'bailiff': 'The armored bailiff in the black vest and helmet',
       'clamp_king': 'The burly man with the giant golden wheel clamp', 'clipboard_flier': 'The office clerk with the clipboard',
       'coping_imp': 'The skinny kid in the green hoodie', 'lot_hydra': 'The huge man with the golden claw arm',
       'npc_old_woman': 'The old woman in the purple raincoat', 'npc_sanitation': 'The sanitation worker in the green vest', 'npc_old_man': 'The old man with the cane'}
START = {'cop': '/tmp/claude-0/en/cop.png', 'repo_goon': D + '/repo_goon.png', 'bailiff': D + '/bailiff.png'}
Q = [('clip', 'cop', 'death')]
Q += [('design', 'repo_goon'), ('design', 'bailiff')]
for w in ['repo_goon', 'bailiff']:
    Q += [('clip', w, m) for m in ['idle', 'walk', 'punch_high', 'hurt', 'death', 'punch_mid', 'kick_low']
          if not (w == 'bailiff' and m in ('punch_mid', 'kick_low'))]  # these hang the Space: local queue
Q += [('clip', w, 'death') for w in ['clipboard_flier', 'coping_imp', 'lot_hydra', 'clamp_king']]
Q += [('clip', w, m) for w in ['coping_imp', 'clipboard_flier', 'lot_hydra'] for m in ['punch_high', 'kick_low']]
for w in ['npc_old_woman', 'npc_sanitation', 'npc_old_man']:
    Q += [('design', w), ('clip', w, 'npc_idle')]
    START[w] = D + '/' + w + '.png'


def quota(e):
    m = re.search(r"Try again in ([0-9:]+)", str(e))
    if "quota" in str(e).lower():
        print("QUOTA", m.group(1) if m else "?", flush=True)
        sys.exit(3)


wan = flux = None
for job in Q:
    if job[0] == 'design':
        out = f"{D}/{job[1]}.png"
        if os.path.exists(out):
            continue
        flux = flux or Client("black-forest-labs/FLUX.1-Krea-dev", token=tok)
        try:
            img, s = flux.predict(prompt=DESIGN[job[1]] + ", " + (STY_NPC if job[1].startswith("npc_") else STY), seed=7, randomize_seed=False, width=768, height=960, guidance_scale=4.5, num_inference_steps=28, api_name="/infer")
        except Exception as e:
            quota(e); print("ERR", job, e, flush=True); continue
        shutil.copy(img["path"] if isinstance(img, dict) else img, out)
        print("OK", out, flush=True)
        continue
    _, w, m = job
    out = f"{D}/clips/{w}_{m}.mp4"
    if os.path.exists(out):
        continue
    os.makedirs(D + "/clips", exist_ok=True)
    start = START.get(w, f"{D}/start_{w}.png")
    if not os.path.exists(start):
        print("SKIP no start", w, flush=True); continue
    dur, p = MOVES[m]
    wan = wan or Client("zerogpu-aoti/wan2-2-fp8da-aoti-faster", token=tok)
    t0 = time.time()
    for attempt in range(2):
        try:
            v, s = wan.predict(input_image=handle_file(start), prompt=p.format(d=WHO[w]) + TAIL, steps=6, negative_prompt=NEG, duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=23, randomize_seed=False, api_name="/generate_video")
            shutil.copy(v["video"] if isinstance(v, dict) else v, out)
            print("OK", out, round(time.time() - t0), flush=True)
            break
        except Exception as e:
            quota(e); print("ERR", job, str(e)[:200], flush=True)
print("DONE", flush=True)
