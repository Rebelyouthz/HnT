"""Eighth HF pass: locomotion that floats (one pose repeated) - the
father's run and the survivor enemies' side walks (two in the wrong
outfit)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import genq2, genq6
P = genq6.P
P["run_side"] = (3.0, "{d} sprints hard to the right on a treadmill, side view, big strides, knees driving high, arms pumping, both feet leaving the ground on every stride, a continuous run cycle, staying in place.")
P["walk_brisk"] = (3.0, "{d} walks briskly to the right on a treadmill, side view, clear alternating steps, heels striking the ground, arms swinging, a continuous walk cycle, staying in place. Same clothes the whole time.")
genq2.DESC.setdefault("father", "The bearded father in a grey hoodie and grey sweatpants")
J = [
 ("father_run", "father", "run_side", ("idle", 0), ("idle", 0), 1212),
 ("clipboard_flier_walk", "clipboard_flier", "walk_brisk", ("idle", 0), ("idle", 0), 1212),
 ("lot_hydra_walk", "lot_hydra", "walk_brisk", ("idle", 0), ("idle", 0), 1212),
 ("clamp_king_walk", "clamp_king", "walk_brisk", ("idle", 0), ("idle", 0), 1212),
 ("coping_imp_walk", "coping_imp", "walk_brisk", ("idle", 0), ("idle", 0), 1212),
 ("son_run", "son", "run_side", ("idle", 0), ("idle", 0), 1212),
]
if __name__ == "__main__":
    genq6.run(J, sys.argv[1:])
