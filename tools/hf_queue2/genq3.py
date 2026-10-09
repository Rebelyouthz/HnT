"""Third HF pass: retries with other end poses / seeds."""
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
J = [
 ("clipboard_flier_punch_mid2", "clipboard_flier", "punch_mid", ("idle", 0), ("punch_high", keys.hit_of("clipboard_flier", "punch_high")), 77),
 ("lot_hydra_punch_mid2", "lot_hydra", "punch_mid", ("idle", 0), ("punch_high", keys.hit_of("lot_hydra", "punch_high")), 77),
 ("valet_punch_mid2", "valet", "punch_mid", ("idle", 0), ("punch_high", keys.hit_of("valet", "punch_high")), 77),
 ("bag_snatch_death2", "bag_snatch", "death", ("idle", 0), ("death", -3), 77),
 ("bag_snatch_punch_high2", "bag_snatch", "punch_high", ("idle", 0), ("punch_high", keys.hit_of("bag_snatch", "punch_high")), 77),
 ("shift_lead_hurt2", "shift_lead", "hurt", ("idle", 0), ("hurt", round(n("shift_lead", "hurt") * 0.35)), 77),
 ("son_hurt4", "son", "hurt", ("idle", 0), ("hurt", 1), 77),
 ("son_roll_a2", "son", "roll_a", ("roll", 2), ("roll", n("son", "roll") // 2), 77),
 ("son_roll_b2", "son", "roll_b", ("roll", n("son", "roll") // 2), ("roll", -1), 77),
 ("roof_runner_kick_low", "roof_runner", "kick_low", ("idle", 0), ("idle", 0), 77),
 ("clamp_king_kick_low", "clamp_king", "kick_low", ("idle", 0), ("idle", 0), 77),
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
        res = c.predict(input_image=handle_file(st), last_image=handle_file(en), prompt=text.format(d=genq2.DESC[who]) + genq2.TAIL, steps=6,
            negative_prompt=genq2.NEG, duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=seed, randomize_seed=False, api_name="/generate_video")
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
