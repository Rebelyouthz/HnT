"""Tenth HF pass: the gaps left in the walk angles and strikes
(clipboard_flier walk_down, lot_hydra walk_up, bailiff walk_up, clamp_king
and roof_runner kick_low) with new prompts and seeds."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keys, genq2, genq6, genq7
P = genq6.P
P["walk_back"] = (3.0, "Back view only: {d} has his back to the camera and walks forward into the distance with steady steps, arms swinging, we see only his back, shoulders and the back of his head, continuous walk cycle on a treadmill, never turning around.")
P["walk_front"] = (3.0, "Front view: {d} faces the camera and walks toward the viewer on a treadmill with clear steps, arms swinging at his sides, continuous walk cycle, staying in place.")
P["kick_front"] = (1.3, "{d} lifts his right leg and snaps a fast, hard kick forward at knee height, the leg straight out to the right, holds it for a moment, then plants the foot back down. Same clothes the whole time.")
J = [
 ("clipboard_flier_walk_down", "clipboard_flier", "walk_front", ("idle", 0), ("idle", 0), 2121),
 ("clamp_king_kick_low", "clamp_king", "kick_front", ("idle", 0), ("idle", 0), 2121),
 ("roof_runner_kick_low", "roof_runner", "kick_front", ("idle", 0), ("idle", 0), 2121),
 ("lot_hydra_walk_up3", "lot_hydra", "walk_back", ("idle", 0), ("idle", 0), 2121),
 ("bailiff_walk_up3", "bailiff", "walk_back", ("idle", 0), ("idle", 0), 2121),
]
if __name__ == "__main__":
    genq6.run(J, sys.argv[1:])
