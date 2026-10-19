"""Ninth HF pass: the skinwalker's clips were six copies of one frame
(walk, crawl and gape floated / froze). It has no idle clip, so its walk
frame stands in for the key scale."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keys, genq2, genq6
_frame = keys.frame
def frame(who, clip, i):
    if who == "skinwalker" and clip == "idle":
        clip = "walk"
    return _frame(who, clip, i)
keys.frame = frame
P = genq6.P
genq2.DESC.setdefault("skinwalker", "The pale, emaciated skinwalker creature with long thin limbs and a skull-like face")
P["creep_walk"] = (3.0, "{d} stalks slowly to the right on a treadmill, side view, hunched, long bony legs taking clear jerky steps, arms swaying, a continuous unsettling walk cycle, staying in place.")
P["crawl_fast"] = (3.0, "{d} crawls fast to the right on all fours like a spider, side view, limbs reaching forward one after another in a continuous crawl cycle, staying in place.")
P["gape"] = (2.0, "{d} stands still, then its jaw drops open impossibly wide in a silent scream, the head tilting back, then the mouth snaps shut.")
P["dog_idle"] = (2.5, "{d} sits on its haunches like a dog, panting, ribs heaving, the head twitching and tilting in small unnatural jerks, staying in place.")
J = [
 ("skinwalker_dog", "skinwalker", "dog_idle", ("dog", 0), ("dog", 0), 1414),
 ("skinwalker_walk", "skinwalker", "creep_walk", ("walk", 0), ("walk", 0), 1313),
 ("skinwalker_crawl", "skinwalker", "crawl_fast", ("crawl", 0), ("crawl", 0), 1313),
 ("skinwalker_gape", "skinwalker", "gape", ("gape", 0), ("gape", 0), 1313),
]
if __name__ == "__main__":
    genq6.run(J, sys.argv[1:])
