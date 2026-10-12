"""Second HF pass: first/last frame cut from the game's own poses, so the
clip has to go somewhere (punch to full reach, fall to lying, recoil)."""
import os, sys, time, json, httpx
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keys
from gradio_client import Client, handle_file
D = os.path.dirname(os.path.abspath(__file__))
tok = open(os.path.expanduser("~/.cache/huggingface/token")).read().strip()
Q = json.load(open("/home/user/hnt/tools/local_gpu/queue.json"))["who"]
DESC = {k: v["desc"] for k, v in Q.items()}
DESC.update({"valet": "The parking valet", "son": "The teenage boy in the black jacket"})
TAIL = " Strict side view facing right, locked static camera that never moves or zooms, full body always in frame, flat solid green background that never changes, no other people, realistic human motion with weight and momentum, keep the exact same pixel art style, colours and outfit."
NEG = "camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, cropped body, turning toward camera, slow motion, standing back up"
P = {
 "punch_high": (1.4, "{d} steps in and throws a fast, hard right punch at head height with a big shoulder turn, and holds the arm fully extended at the end."),
 "punch_mid": (1.4, "{d} steps in and drives a fast straight punch at stomach height, leaning forward, and holds the arm fully extended at the end."),
 "hurt": (1.0, "{d} is hit hard in the face: the head snaps back, the shoulders twist and the body recoils backward off balance."),
 "death": (2.2, "Like a movie stuntman, {d} is knocked out cold, the knees buckle, and the body collapses and falls flat onto the ground, then lies completely still."),
 "roll_a": (1.2, "{d} dives forward and tucks into a somersault, rolling head over heels on the ground."),
 "roll_b": (1.2, "{d} finishes the forward somersault, comes up out of the roll and stands back up on his feet."),
}
def n_of(who, clip):
    return len(json.load(open(f"{keys.SP}/{who}/{clip}.json"))["frames"])
def has(who, clip):
    return os.path.exists(f"{keys.SP}/{who}/{clip}.json")
JOBS = []
for e in ["punk", "cop", "mohawk", "shift_lead", "bag_snatch", "roof_runner"]:
    JOBS.append((f"{e}_punch_high", e, "punch_high", ("idle", 0), ("punch_high", keys.hit_of(e, "punch_high"))))
    JOBS.append((f"{e}_hurt", e, "hurt", ("idle", 0), ("hurt", round(n_of(e, "hurt") * 0.35))))
    JOBS.append((f"{e}_death", e, "death", ("idle", 0), ("death", -1)))
JOBS.append(("son_hurt3", "son", "hurt", ("idle", 0), ("hurt", round(n_of("son", "hurt") * 0.35))))
JOBS.append(("son_roll_a", "son", "roll_a", ("idle", 0), ("roll", n_of("son", "roll") // 2)))
JOBS.append(("son_roll_b", "son", "roll_b", ("roll", n_of("son", "roll") // 2), ("roll", -1)))
for e in ["bag_snatch", "clipboard_flier", "coping_imp", "lot_hydra", "roof_runner", "valet", "clamp_king"]:
    src = "attack" if has(e, "attack") else "punch_high"
    JOBS.append((f"{e}_punch_mid", e, "punch_mid", ("idle", 0), (src, keys.hit_of(e, src))))
JOBS.append(("valet_death", "valet", "death", ("idle", 0), ("death", -1)))
if __name__ == "__main__":
    SPACES = ["Rchoks/wan555", "kulkas2pintu/wan777", "r3gm/wan2-2-fp8da-aoti-preview"]
    si = 0
    pending = [j for j in JOBS if not os.path.exists(f"{D}/{j[0]}.mp4")]
    print("JOBS", len(pending), flush=True)
    while pending:
        name, who, move, a, b = pending[0]
        st, en = f"{D}/k_{name}_a.png", f"{D}/k_{name}_b.png"
        keys.key(who, a[0], a[1], st); keys.key(who, b[0], b[1], en)
        dur, text = P[move]
        try:
            c = Client(SPACES[si % len(SPACES)], token=tok, download_files=False)
            res = c.predict(input_image=handle_file(st), last_image=handle_file(en), prompt=text.format(d=DESC[who]) + TAIL, steps=6,
                negative_prompt=NEG, duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=1234, randomize_seed=False, api_name="/generate_video")
            v = res[0]
            url = v["video"]["url"] if isinstance(v.get("video"), dict) else v.get("url")
            r = httpx.get(url, headers=c.headers, timeout=180, follow_redirects=True)
            if r.status_code == 200:
                open(f"{D}/{name}.mp4", "wb").write(r.content); print(time.strftime("%H:%M"), "OK", name, flush=True)
                pending.pop(0); continue
            print(time.strftime("%H:%M"), "DL", r.status_code, flush=True)
        except Exception as ex:
            print(time.strftime("%H:%M"), "ERR", SPACES[si % len(SPACES)], name, repr(ex)[:160], flush=True)
        si += 1
        time.sleep(20 if si % len(SPACES) else 400)
    print("ALLDONE", flush=True)
