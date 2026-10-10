"""Wan 2.2 image-to-video queue (Hugging Face ZeroGPU Spaces) for hero and enemy clips.

Run from this folder: HFQ_DIR=/tmp/claude-0/hfs python3 genq.py > genq.log
Needs ~/.cache/huggingface/token (never committed). Clips that already exist are skipped.
Convert results with tools/install_hero_clips.py (heroes) or tools/video2sprite.py.
"""
import os, sys, time, httpx, json
from gradio_client import Client, handle_file
tok = None if os.environ.get('ANON') else open(os.path.expanduser('~/.cache/huggingface/token')).read().strip()
TAIL = " Strict side view, locked static camera that never moves or zooms, facing right, full body always in frame, flat solid green background that never changes, no other people, realistic human motion with weight and momentum, smooth fluid animation, keep the exact same pixel art style and outfit."
NEG = "camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, cropped body, turning toward camera, slow motion, shuffling, tiny steps"
D = os.environ.get("HFQ_DIR", "/tmp/claude-0/hfs")  # videos land here; start/end images are read from it too (copy tools/hf_queue/starts/* there)
S = D + "/son_start.png"
WALK = "The teenage boy in the black jacket walks to the right on a treadmill with long confident strides, each leg swings far forward and plants heel first while the other pushes off behind, knees bending, clear wide gap between the feet at every step, arms swinging opposite to the legs, slight up and down bob of the body."
BIG = "The teenage boy in the black jacket with long sleeves walks forward to the right on a treadmill like a cartoon character, with big exaggerated steps: the front leg swings far forward with the knee lifted, the back leg stretches far behind, feet wide apart at every step, arms swinging high opposite to the legs, head bobbing up and down with each step, continuous walk cycle."
MID = "The teenage boy in the black jacket with long sleeves walks forward to the right on a treadmill at a brisk natural pace with long clear strides: each step the front heel lands well ahead and the back foot pushes off far behind, knees bending, arms hanging relaxed and swinging gently at his sides, body bobbing slightly, continuous realistic walk cycle."
JOBS = [
 ("son_walk9", 3.0, 3, WALK + " He wears a black zip jacket with long sleeves down to the wrists.", "sleeve"),
 ("son_walk7", 3.0, 101, MID),
 ("son_walk8", 3.0, 202, MID),
 ("son_walk5", 3.0, 41, BIG),
 ("son_walk6", 3.0, 77, BIG),
 ("son_walk4", 3.0, 3, WALK, "stride"),
 ("son_walk2", 3.0, 7, WALK),
 ("son_idle", 2.5, 23, "The teenage boy in the black jacket stands still in place with his feet planted, relaxed, breathing calmly, his body sways very gently and his shoulders rise and fall. He does not take any step and his feet never move."),
 ("son_walk3", 3.0, 11, WALK),
 ("son_trip", 3.0, 5, "The teenage boy in the black jacket is running to the right, catches his foot, stumbles forward with his arms flailing for balance, almost falls, then catches himself and stands back up."),
 ("son_faceplant", 3.5, 9, "The teenage boy in the black jacket is running to the right, trips and falls forward flat onto his chest and face on the ground, lies there a moment, then pushes himself up and stands back up."),
 ("son_backfall", 3.5, 13, "The teenage boy in the black jacket slips, his feet fly out in front of him and he falls backward onto his back on the ground, groans, then rolls over and gets back up on his feet."),
]
import sys as _sys
_sys.path.insert(0, D)
from moves import MOVES as _MV
JOBS += [(n, d, sd, p, "son_idlepose" if k == "son" else k) for (n, d, sd, p, k) in _MV]
SPACES = ["Rchoks/wan555", "kulkas2pintu/wan777", "r3gm/wan2-2-fp8da-aoti-preview"]
_si = 0
pending = [j for j in JOBS if not os.path.exists(f"{D}/{j[0]}.mp4")]
PRI = ["son_sprint", "son_hurt2", "son_roll2"]
pending.sort(key=lambda j: PRI.index(j[0]) if j[0] in PRI else 99)
while pending:
    job = pending[0]
    name, dur, seed, p = job[0], job[1], job[2], job[3]
    st = D + "/" + (job[4] + "_start.png" if len(job) > 4 else "son_start.png")
    en = D + "/" + (job[4] + "_end.png" if len(job) > 4 else "son_end.png")
    out = f"{D}/{name}.mp4"
    try:
        c = Client(SPACES[_si % len(SPACES)], token=tok, download_files=False)
        res = c.predict(input_image=handle_file(st), last_image=handle_file(en), prompt=p + TAIL, steps=6, negative_prompt=NEG, duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=seed, randomize_seed=False, api_name="/generate_video")
        v = res[0]
        url = v["video"]["url"] if isinstance(v.get("video"), dict) else v.get("url")
        r = httpx.get(url, headers=c.headers, timeout=180, follow_redirects=True)
        if r.status_code == 200:
            open(out, "wb").write(r.content); print(time.strftime("%H:%M"), "OK", name, flush=True)
            pending.pop(0)
            continue
        print(time.strftime("%H:%M"), "DL", r.status_code, flush=True)
    except Exception as e:
        print(time.strftime("%H:%M"), "ERR", SPACES[_si % len(SPACES)], name, repr(e)[:160], flush=True)
    _si += 1
    time.sleep(20 if _si % len(SPACES) else 400)
print("ALLDONE", flush=True)
