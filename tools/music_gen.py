#!/usr/bin/env python3
"""Game music with Sorceress music_generate (Suno, instrumental).

Each cue is one generation (10 credits, ~2 variations); the first variation
is kept as assets/audio/<name>.ogg (both are saved under
/tmp/claude-0/music/ to compare). Mixer loops whatever it is given.

    python3 tools/music_gen.py               # every cue not on disk yet
    python3 tools/music_gen.py music_boss    # just this one
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import sorceress as S  # noqa: E402
from vo_gen import ffmpeg  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
TMP = Path("/tmp/claude-0/music")

CUES = {
    "music_street": ("Dock Street brawl", "gritty 90s arcade beat 'em up street fight music, driving breakbeat drums, dark slap bass, analog synth stabs, rain-soaked neon city at night, Streets of Rage energy, loopable, instrumental"),
    "music_boss": ("Collector", "intense boss battle, fast industrial rock with distorted guitars, pounding drums, dark synth arpeggios, menacing and relentless, instrumental"),
    "music_clinic": ("Hideout", "melancholic lo-fi hip hop with rain, warm Rhodes piano, dusty vinyl drums, tired but hopeful father and son hideout at night, instrumental"),
    "music_dojo": ("Back Alley Dojo", "lo-fi kung fu training beat, boom bap drums, plucked guzheng and bamboo flute, focused and cool, instrumental"),
    "music_tension": ("Overdue", "dark tense synthwave, slow pulsing bass, ticking percussion, suspense before a fight, instrumental"),
    "music_chase": ("Run", "frantic drum and bass chase music, rolling breaks, alarm-like synths, urgent, instrumental"),
}


def find_urls(d) -> list:
    out = []
    if isinstance(d, dict):
        for k, v in d.items():
            if isinstance(v, str) and v.startswith("http") and (".mp3" in v or ".wav" in v or "audio" in k.lower()):
                out.append(v)
            else:
                out.extend(find_urls(v))
    elif isinstance(d, list):
        for v in d:
            out.extend(find_urls(v))
    return out


def main() -> None:
    want = sys.argv[1:] or [k for k in CUES if not (ROOT / "assets/audio" / (k + ".ogg")).exists()]
    TMP.mkdir(parents=True, exist_ok=True)
    jobs = {}
    for name in want:
        title, style = CUES[name]
        r = S.call("music_generate", {"prompt": style, "instrumental": True})
        d = r.get("data") or r
        jid = d.get("jobId") or r.get("jobId")
        if not jid:
            print("FAIL submit", name, json.dumps(r)[:300], flush=True)
            continue
        jobs[name] = jid
    t0 = time.time()
    while jobs and time.time() - t0 < 1500:
        for name, jid in list(jobs.items()):
            j = S.req("GET", "/jobs/" + jid)
            d = j.get("data") or j
            st = d.get("status")
            if st == "failed" or j.get("ok") is False:
                print("FAIL", name, json.dumps(j)[:300], flush=True)
                del jobs[name]
                continue
            if st != "succeeded":
                continue
            urls = [u for u in dict.fromkeys(find_urls(d)) if ".mp3" in u or ".wav" in u or "audio" in u]
            if not urls:
                print("NOURL", name, json.dumps(d)[:600], flush=True)
                del jobs[name]
                continue
            for i, u in enumerate(urls[:2]):
                S.fetch(u, str(TMP / ("%s_%d.mp3" % (name, i))))
            subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", str(TMP / (name + "_0.mp3")),
                            "-af", "loudnorm=I=-18:TP=-1.5", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5",
                            str(ROOT / "assets/audio" / (name + ".ogg"))], check=True)
            print("OK", name, len(urls), flush=True)
            del jobs[name]
        time.sleep(10)
    if jobs:
        print("LEFT", jobs)


if __name__ == "__main__":
    main()
