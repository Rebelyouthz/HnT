#!/usr/bin/env python3
"""Sound effects with Sorceress sfx_generate -> assets/audio/sfx/<name>.ogg.

seed-audio for one-shots (1 credit per second), suno-sounds for loops
(flat 2 credits). Existing files are skipped.

    python3 tools/sfx_gen.py            # all missing
    python3 tools/sfx_gen.py bone_crack # just these
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
from music_gen import find_urls  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/audio/sfx"

# name: (prompt, seconds or "loop")
SFX = {
    "punch_light": ("quick hard bare-knuckle punch to the face, short dry slap with a thud", 1),
    "punch_heavy": ("very heavy cinematic punch impact, deep body thump with a crack, video game brawler", 1),
    "kick_heavy": ("brutal kick into the ribs, deep thud with a crunch and a grunt of air", 1),
    "bone_crack": ("sharp sickening bone snapping crack, close and dry", 1),
    "skull_crunch": ("heavy crunchy skull smash with a wet splat, horror game", 1),
    "gore_squelch": ("wet meaty squelch of flesh being hit hard, blood splatter", 1),
    "blood_spray": ("short pressurised blood spray hiss and wet splatter on pavement", 1),
    "gib_splat": ("big wet gore explosion, chunks of flesh slapping onto wet ground", 2),
    "teeth": ("teeth breaking and small pieces scattering and clattering on asphalt", 1),
    "body_fall": ("heavy limp body falling flat onto wet street pavement, thud and splash", 1),
    "block_hit": ("solid forearm block absorbing a punch, muffled thud with a short leather slap", 1),
    "parry_ring": ("sharp parry clash, crisp impact with a bright metallic ring", 1),
    "roll": ("body rolling fast across wet asphalt, cloth rustle and a light thump", 1),
    "whoosh_spin": ("fast heavy whoosh of a spinning kick cutting the air", 1),
    "combo_sting": ("punchy arcade combo hit sting, synth stab with a bass drop", 1),
    "perfect_sting": ("bright arcade perfect timing chime with a shimmering synth sparkle", 1),
    "rain_loop": ("heavy rain on a night city street, distant traffic, water gurgling in gutters, seamless ambience", "loop"),
}


def main() -> None:
    want = sys.argv[1:] or [k for k in SFX if not (OUT / (k + ".ogg")).exists()]
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = {}
    for name in want:
        prompt, sec = SFX[name]
        body = {"prompt": prompt}
        if sec == "loop":
            body.update({"model": "suno-sounds", "loop": True})
        else:
            body.update({"model": "seed-audio", "targetDuration": sec})
        r = S.call("sfx_generate", body)
        d = r.get("data") or r
        jid = d.get("jobId") or r.get("jobId")
        if not jid:
            print("FAIL submit", name, json.dumps(r)[:300], flush=True)
            continue
        jobs[name] = jid
    t0 = time.time()
    while jobs and time.time() - t0 < 900:
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
            urls = list(dict.fromkeys(find_urls(d)))
            if not urls:
                print("NOURL", name, json.dumps(d)[:500], flush=True)
                del jobs[name]
                continue
            raw = OUT / (name + ".raw")
            S.fetch(urls[0], str(raw))
            af = "loudnorm=I=-14:TP=-1" if SFX[name][1] != "loop" else "loudnorm=I=-24:TP=-2"
            if SFX[name][1] != "loop":
                af = "silenceremove=start_periods=1:start_threshold=-50dB," + af
            subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", str(raw), "-af", af, "-ac", "1" if SFX[name][1] != "loop" else "2",
                            "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(OUT / (name + ".ogg"))], check=True)
            raw.unlink()
            print("OK", name, flush=True)
            del jobs[name]
        time.sleep(4)
    if jobs:
        print("LEFT", jobs)


if __name__ == "__main__":
    main()
