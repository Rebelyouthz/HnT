"""Fifth HF pass: kicks, retries, back walks, survivor hurts."""
import os, sys, time, httpx
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keys, genq2
from gradio_client import Client, handle_file
D = genq2.D
P = dict(genq2.P)
P["kick_low"] = (1.3, "{d} snaps a fast low kick at shin height with the front leg, the foot sweeping forward close to the ground, then plants it back down.")
P["roll_a"] = (1.2, "{d} dives forward to the right and tucks into a forward somersault, head down, rolling over his shoulder toward the right.")
P["roll_b"] = (1.2, "{d} finishes the forward somersault to the right, rolls up onto his feet and stands up facing right.")
n = genq2.n_of
P["kick_low"] = (1.3, "{d} snaps a fast low kick at shin height with the front leg, the foot sweeping forward close to the ground, and holds the leg out at the end.")
P["punch_free"] = (1.4, "{d} keeps the bag at his hip and throws a fast hard punch with his free right fist at head height, and holds the arm fully extended at the end.")
P["hurt_clean"] = (1.0, "{d} is hit hard in the face with empty hands: the head snaps back and the body recoils backward off balance. He holds nothing new.")
P["walk_up"] = (3.5, "{d} turns around so we see his back, and walks straight away from the camera into the distance on a treadmill, back view, the back of his head toward us, continuous walk cycle.")
P["walk_down"] = (3.5, "{d} turns to face the camera and walks toward the viewer on a treadmill with big clear steps, knees lifting, front view, continuous walk cycle.")
def hp(w):
    return ("hurt", round(n(w, "hurt") * 0.35))
J = [
 ("punk_kick_low", "punk", "kick_low", ("idle", 0), ("kick_low", keys.hit_of("punk", "kick_low")), 1234),
 ("cop_kick_low", "cop", "kick_low", ("idle", 0), ("kick_low", keys.hit_of("cop", "kick_low")), 1234),
 ("mohawk_kick_low", "mohawk", "kick_low", ("idle", 0), ("kick_low", keys.hit_of("mohawk", "kick_low")), 1234),
 ("shift_lead_kick_low", "shift_lead", "kick_low", ("idle", 0), ("kick_low", keys.hit_of("shift_lead", "kick_low")), 1234),
 ("bag_snatch_kick_low", "bag_snatch", "kick_low", ("idle", 0), ("kick_low", keys.hit_of("bag_snatch", "kick_low")), 1234),
 ("bag_snatch_punch_high3", "bag_snatch", "punch_free", ("idle", 0), ("punch_high", keys.hit_of("bag_snatch", "punch_high")), 303),
 ("shift_lead_hurt3", "shift_lead", "hurt_clean", ("idle", 0), hp("shift_lead"), 303),
 ("clamp_king_punch_high", "clamp_king", "punch_high", ("idle", 0), ("attack", keys.hit_of("clamp_king", "attack")), 1234),
 ("clipboard_flier_walk_up2", "clipboard_flier", "walk_up", ("idle", 0), ("idle", 0), 303),
 ("lot_hydra_walk_up2", "lot_hydra", "walk_up", ("idle", 0), ("idle", 0), 303),
 ("valet_walk_up2", "valet", "walk_up", ("idle", 0), ("idle", 0), 303),
 ("lot_hydra_walk_down2", "lot_hydra", "walk_down", ("idle", 0), ("idle", 0), 303),
 ("coping_imp_hurt", "coping_imp", "hurt", ("idle", 0), hp("coping_imp"), 1234),
 ("lot_hydra_hurt", "lot_hydra", "hurt", ("idle", 0), hp("lot_hydra"), 1234),
 ("clipboard_flier_hurt", "clipboard_flier", "hurt", ("idle", 0), hp("clipboard_flier"), 1234),
 ("valet_hurt", "valet", "hurt", ("idle", 0), hp("valet"), 1234),
 ("clamp_king_hurt", "clamp_king", "hurt", ("idle", 0), hp("clamp_king"), 1234),
]
SPACES = ["Rchoks/wan555", "kulkas2pintu/wan777", "r3gm/wan2-2-fp8da-aoti-preview"]
si = 0
pending = [j for j in J if not os.path.exists(f"{D}/{j[0]}.mp4")]
print("JOBS", len(pending), flush=True)
while pending:
    name, who, move, a, b, seed = pending[0]
    st, en = f"{D}/k_{name}_a.png", f"{D}/k_{name}_b.png"
    keys.key(who, a[0], a[1], st); keys.key(who, b[0], b[1], en)
    dur, text = P[move]
    try:
        c = Client(SPACES[si % len(SPACES)], token=genq2.tok, download_files=False)
        res = c.predict(input_image=handle_file(st), last_image=handle_file(en), prompt=text.format(d=genq2.DESC[who]) + (genq2.TAIL.replace(' Strict side view facing right,', '') if move.startswith('walk') else genq2.TAIL), steps=6,
            negative_prompt=(genq2.NEG.replace(', turning toward camera', '') if move.startswith('walk') else genq2.NEG + ', holding a stick, holding a pole, weapon'), duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=seed, randomize_seed=False, api_name="/generate_video")
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
