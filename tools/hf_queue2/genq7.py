"""Seventh HF pass: the 10-frame / 4 fps strikes and 8-frame hurts that the
audit found on survivor enemies, repo_goon, bailiff and Gant."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keys, genq2, genq6
P = genq6.P
P["kick_low"] = (1.3, "{d} snaps a fast low kick at shin height with the front leg, the foot sweeping forward close to the ground, and holds the leg out at the end. Same clothes the whole time.")
P["punch_hard"] = (1.4, "{d} steps in and throws a fast, hard right punch at head height with a big shoulder turn, and holds the arm fully extended at the end. Same clothes the whole time, nothing new appears.")
genq2.DESC.setdefault("gant", "The sleazy debt collector in a white shirt and grey trousers")
P["roll_full"] = (2.0, "{d} dives forward to the right, tucks into one fast forward somersault on the ground and rolls straight back up onto his feet, standing facing right. Same black jacket, nothing on his back, empty hands.")
P["punch_drop"] = (1.4, "{d} lets go of the bag and throws a fast, hard straight right punch at head height, the arm snapping fully out and holding at full reach.")
P["kick_big"] = (1.3, "{d} swings a big fast kick forward at knee height, the whole leg straight out in front, and holds it there at the end.")
hp = genq6.hp
J = []
for e in ["coping_imp", "lot_hydra", "clipboard_flier", "valet", "repo_goon", "bailiff"]:
    J.append((f"{e}_punch_high", e, "punch_hard", ("idle", 0), ("punch_high", keys.hit_of(e, "punch_high")), 606))
    J.append((f"{e}_kick_low", e, "kick_low", ("idle", 0), ("kick_low", keys.hit_of(e, "kick_low")), 606))
J += [
 ("bag_snatch_punch_high3", "bag_snatch", "punch_free", ("idle", 0), ("idle", 0), 707),
 ("repo_goon_hurt", "repo_goon", "hurt_same", ("idle", 0), hp("repo_goon"), 606),
 ("bailiff_hurt", "bailiff", "hurt_same", ("idle", 0), hp("bailiff"), 606),
 ("gant_hurt", "gant", "hurt_same", ("idle", 0), hp("gant"), 606),
 ("lot_hydra_hurt2", "lot_hydra", "hurt_same", ("idle", 0), ("idle", 0), 808),
 ("son_roll_full", "son", "roll_full", ("idle", 0), ("idle", 0), 31),
 ("bag_snatch_punch_high4", "bag_snatch", "punch_drop", ("idle", 0), ("idle", 0), 999),
 ("clipboard_flier_kick_low2", "clipboard_flier", "kick_big", ("idle", 0), ("idle", 0), 99),
 ("gant_kick_low", "gant", "kick_low", ("idle", 0), ("kick_low", keys.hit_of("gant", "kick_low")), 606),
]
if __name__ == "__main__":
    genq6.run(J, sys.argv[1:])
