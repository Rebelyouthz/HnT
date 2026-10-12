"""Sixth HF pass: the worst clips left after the animation audit (static
walks, outfit morphs mid-punch, choppy deaths) plus pass-5 leftovers."""
import os, sys, time, httpx
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keys, genq2
from gradio_client import Client, handle_file
D = genq2.D
genq2.DESC.setdefault("repo_goon", "The big bald tattooed repo man in a grey work jumpsuit")
P = dict(genq2.P)
# genq5 runs its queue on import, so its prompts are repeated here.
P["roll_a"] = (1.2, "{d} dives forward to the right and tucks into a forward somersault, head down, rolling over his shoulder toward the right.")
P["roll_b"] = (1.2, "{d} finishes the forward somersault to the right, rolls up onto his feet and stands up facing right.")
P["punch_free"] = (1.4, "{d} keeps the bag at his hip and throws a fast hard punch with his free right fist at head height, and holds the arm fully extended at the end.")
P["walk_up"] = (3.5, "{d} turns around so we see his back, and walks straight away from the camera into the distance on a treadmill, back view, the back of his head toward us, continuous walk cycle.")
P["walk_down"] = (3.5, "{d} turns to face the camera and walks toward the viewer on a treadmill with big clear steps, knees lifting, front view, continuous walk cycle.")
P["punch_chest"] = (1.4, "{d} steps in and drives a fast, hard straight punch at chest height with a big shoulder turn, and holds the arm fully extended at the end. Same clothes the whole time.")
P["hurt_same"] = (1.0, "{d} is hit hard in the face: the head snaps back, the shoulders twist and the body recoils backward off balance. Same clothes, empty hands, nothing new appears.")
P["death_long"] = (2.2, "Like a movie stuntman, {d} is knocked out cold: the knees buckle, the body twists, collapses and falls flat onto the ground, bounces once, then lies completely still.")
P["walk_side"] = (3.0, "{d} walks to the right on a treadmill with a confident, heavy stride, arms swinging, side view, continuous walk cycle, staying in place.")
P["walk_away"] = (3.0, "Seen from behind the whole time, {d} walks straight away from the camera into the distance on a treadmill, we only see his back and the back of his head, continuous walk cycle, he never turns around.")
P["hurt_hold"] = (1.0, "{d} is hit hard in the face: the head snaps back and the body recoils backward off balance, still gripping the giant golden clamp with both hands the whole time. Nothing flies off.")
P["hurt_vest"] = (1.0, "{d} in the orange high-visibility vest is hit hard in the face: the head snaps back and the body recoils backward off balance. Empty hands, nothing flies off, same vest the whole time.")
P["idle_breathe"] = (2.0, "{d} stands in a fighting stance, breathing heavily, shoulders rising and falling, shifting his weight from foot to foot, fists ready.")
n = genq2.n_of
def hp(w):
    return ("hurt", round(n(w, "hurt") * 0.35))
J = [
 ("cop_walk_down", "cop", "walk_down", ("idle", 0), ("idle", 0), 303),
 ("punk_punch_mid", "punk", "punch_chest", ("idle", 0), ("punch_high", keys.hit_of("punk", "punch_high")), 303),
 ("shift_lead_punch_mid", "shift_lead", "punch_chest", ("idle", 0), ("punch_high", keys.hit_of("shift_lead", "punch_high")), 303),
 ("valet_hurt", "valet", "hurt_same", ("idle", 0), ("hurt", 1), 303),
 ("son_walk_up", "son", "walk_up", ("idle", 0), ("idle", 0), 303),
 ("son_walk_down", "son", "walk_down", ("idle", 0), ("idle", 0), 303),
 ("bailiff_walk_up", "bailiff", "walk_up", ("idle", 0), ("idle", 0), 303),
 ("clamp_king_death", "clamp_king", "death_long", ("idle", 0), ("death", -1), 1234),
 ("coping_imp_death", "coping_imp", "death_long", ("idle", 0), ("death", -1), 1234),
 ("lot_hydra_death", "lot_hydra", "death_long", ("idle", 0), ("death", -1), 1234),
 ("clipboard_flier_death", "clipboard_flier", "death_long", ("idle", 0), ("death", -1), 1234),
 ("shift_lead_hurt", "shift_lead", "hurt_same", ("idle", 0), hp("shift_lead"), 77),
 ("bag_snatch_punch_high", "bag_snatch", "punch_free", ("idle", 0), ("punch_high", keys.hit_of("bag_snatch", "punch_high")), 77),
 ("coping_imp_hurt", "coping_imp", "hurt_same", ("idle", 0), hp("coping_imp"), 1234),
 ("clipboard_flier_hurt", "clipboard_flier", "hurt_same", ("idle", 0), hp("clipboard_flier"), 1234),
 ("clamp_king_hurt", "clamp_king", "hurt_same", ("idle", 0), hp("clamp_king"), 1234),
 ("clipboard_flier_walk_up", "clipboard_flier", "walk_up", ("idle", 0), ("idle", 0), 77),
 ("lot_hydra_walk_up", "lot_hydra", "walk_up", ("idle", 0), ("idle", 0), 77),
 ("valet_walk_up", "valet", "walk_up", ("idle", 0), ("idle", 0), 77),
 ("lot_hydra_walk_down", "lot_hydra", "walk_down", ("idle", 0), ("idle", 0), 77),
 ("son_roll_a", "son", "roll_a", ("idle", 0), ("roll", n("son", "roll") // 2), 77),
 ("valet_hurt2", "valet", "hurt_same", ("idle", 0), ("death", 2), 505),
 ("valet_walk", "valet", "walk_side", ("idle", 0), ("idle", 0), 505),
 ("son_walk_up2", "son", "walk_away", ("walk_up", -1), ("walk_up", -1), 909),
 ("bailiff_walk_up2", "bailiff", "walk_away", ("idle", 0), ("idle", 0), 909),
 ("shift_lead_hurt2", "shift_lead", "hurt_vest", ("idle", 0), ("hurt", 2), 4242),
 ("bag_snatch_punch_high2", "bag_snatch", "punch_free", ("idle", 0), ("kick_low", 0), 4242),
 ("clamp_king_hurt2", "clamp_king", "hurt_hold", ("idle", 0), ("idle", 0), 4242),
 ("repo_goon_idle", "repo_goon", "idle_breathe", ("idle", 0), ("idle", 0), 4242),
 ("son_roll_b", "son", "roll_b", ("roll", n("son", "roll") // 2), ("roll", -1), 77),
]
SPACES = ["Rchoks/wan555", "kulkas2pintu/wan777", "r3gm/wan2-2-fp8da-aoti-preview"]
def run(J, only=()):
    only = set(only)
    si = 0
    pending = [j for j in J if not os.path.exists(f"{D}/{j[0]}.mp4") and (not only or j[0] in only)]
    print("JOBS", len(pending), flush=True)
    fails = 0
    while pending:
        name, who, move, a, b, seed = pending[0]
        st, en = f"{D}/k_{name}_a.png", f"{D}/k_{name}_b.png"
        keys.key(who, a[0], a[1], st); keys.key(who, b[0], b[1], en)
        dur, text = P[move]
        walk = move.startswith("walk")
        try:
            c = Client(SPACES[si % len(SPACES)], token=genq2.tok, download_files=False)
            res = c.predict(input_image=handle_file(st), last_image=handle_file(en),
                prompt=text.format(d=genq2.DESC[who]) + (genq2.TAIL.replace(' Strict side view facing right,', '') if walk else genq2.TAIL), steps=6,
                negative_prompt=(genq2.NEG.replace(', turning toward camera', '') if walk else genq2.NEG + ', holding a stick, holding a pole, weapon, changing clothes, new jacket, vest'),
                duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=seed, randomize_seed=False, api_name="/generate_video")
            v = res[0]
            url = v["video"]["url"] if isinstance(v.get("video"), dict) else v.get("url")
            r = httpx.get(url, headers=c.headers, timeout=180, follow_redirects=True)
            if r.status_code == 200:
                open(f"{D}/{name}.mp4", "wb").write(r.content); print(time.strftime("%H:%M"), "OK", name, flush=True)
                pending.pop(0); fails = 0; continue
            print(time.strftime("%H:%M"), "DL", r.status_code, flush=True)
        except Exception as ex:
            print(time.strftime("%H:%M"), "ERR", SPACES[si % len(SPACES)], name, repr(ex)[:200], flush=True)
            fails += 1
        si += 1
        time.sleep(20 if si % len(SPACES) else 300)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    run(J, sys.argv[1:])
