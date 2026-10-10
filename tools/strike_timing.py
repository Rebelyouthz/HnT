#!/usr/bin/env python3
"""Give the Son's old 12-frame strike boards real timing (one-off, idempotent).

They were sliced without a contact frame, so the game hit at 0.05 s while the
drawn fist arrived ~0.35 s later. Per clip this sets "hit" (the frame where
the limb is fully out) and "fps", drops off-model frames (a grey-hoodie
costume the video model slipped in), trims long extended holds to one frame
past contact so the limb snaps back, and closes clips that ended extended with
a return to guard. The sheet PNG is untouched: only the JSON frame list moves.
"""
import json, os

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
# clip: (frame order, hit index in the NEW order, fps)
PLAN = {
    "son": {
        "jab":        ([0, 1, 2, 3, 7, 8, 9, 10, 11], 2, 18),
        "cross":      ([0, 1, 2, 3, 6, 1, 0], 2, 18),
        "gut":        ([0, 1, 2, 3, 7, 9, 10, 11], 2, 18),
        "heavy":      ([0, 1, 2, 3, 4, 5, 8, 9, 10, 11], 4, 14),
        "roundhouse": ([0, 1, 2, 3, 4, 8, 9, 10, 11], 3, 16),
        "air_mix":    ([0, 1, 2, 3, 4, 6, 8, 9, 10, 11], 4, 16),
        "front_kick": (list(range(12)), 4, 16),
        "side_kick":  (list(range(12)), 5, 16),
        "snap":       ([0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11], 4, 14),
        "slide":      (list(range(12)), 1, 16),
        "dive":       (list(range(12)), 2, 16),
    },
    "father": {
        "slide": (None, 9, None),
        "dive":  (None, 12, None),
    },
}

for who, clips in PLAN.items():
    for clip, (order, hit, fps) in clips.items():
        p = os.path.join(ROOT, who, clip + ".json")
        d = json.load(open(p))
        if d.get("timed"):
            continue
        if order is not None:
            d["frames"] = [d["frames"][i] for i in order]
        d["hit"] = hit
        if fps is not None:
            d["fps"] = float(fps)
        d.setdefault("loop", False)
        d["timed"] = True
        json.dump(d, open(p, "w"), separators=(",", ":"))
        print(who, clip, "frames", len(d["frames"]), "hit", hit)
