#!/usr/bin/env python3
"""Voice every line in data/vo_lines.json with Sorceress speech_generate.

One call per line (1 credit each), all submitted first and then polled, so
the batch renders in parallel. Each result is trimmed of leading/trailing
silence, loudness-normalised and written as assets/audio/vo/<id>.ogg.
Lines whose file already exists are skipped (re-run to fill gaps).

    python3 tools/vo_gen.py            # all missing lines
    python3 tools/vo_gen.py son_kill_1 # just these ids
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import sorceress as S  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/audio/vo"


def ffmpeg() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def find_audio_url(d: dict) -> str:
    for k in ("audioUrl", "url"):
        if isinstance(d.get(k), str) and d[k].startswith("http"):
            return d[k]
    for k in ("result", "audio", "data"):
        v = d.get(k)
        if isinstance(v, dict):
            u = find_audio_url(v)
            if u:
                return u
        if isinstance(v, list) and v and isinstance(v[0], dict):
            u = find_audio_url(v[0])
            if u:
                return u
    return ""


def main() -> None:
    book = json.loads((ROOT / "data/vo_lines.json").read_text())
    voices = book["voices"]
    want = set(sys.argv[1:])
    OUT.mkdir(parents=True, exist_ok=True)
    pending = {}
    for ln in book["lines"]:
        if want and ln["id"] not in want:
            continue
        if not want and (OUT / (ln["id"] + ".ogg")).exists():
            continue
        v = voices[ln["who"]]
        body = {"text": ln["text"], "voice_id": v["voice"], "speed": v.get("speed", 1.0),
                "pitch": v.get("pitch", 0), "emotion": ln.get("emotion", "none"), "language_boost": "English"}
        r = S.call("speech_generate", body)
        d = r.get("data") or r
        jid = d.get("jobId") or r.get("jobId")
        url = find_audio_url(d)
        if url:
            pending[ln["id"]] = ("url", url)
        elif jid:
            pending[ln["id"]] = ("job", jid)
        else:
            print("FAIL submit", ln["id"], json.dumps(r)[:300], flush=True)
    t0 = time.time()
    while pending and time.time() - t0 < 900:
        for lid, (kind, ref) in list(pending.items()):
            url = ref
            if kind == "job":
                j = S.req("GET", "/jobs/" + ref)
                d = j.get("data") or j
                st = d.get("status")
                if st == "failed" or j.get("ok") is False:
                    print("FAIL", lid, json.dumps(j)[:300], flush=True)
                    del pending[lid]
                    continue
                if st != "succeeded":
                    continue
                url = find_audio_url(d)
                if not url:
                    print("NOURL", lid, json.dumps(d)[:400], flush=True)
                    del pending[lid]
                    continue
            raw = OUT / (lid + ".raw")
            S.fetch(url, str(raw))
            # Trim silence at both ends, normalise, mono ogg.
            subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", str(raw), "-af",
                            "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5",
                            "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(OUT / (lid + ".ogg"))], check=True)
            # Keep the untouched take outside the repo for re-trims.
            keep = Path("/tmp/claude-0/vo_raw")
            keep.mkdir(parents=True, exist_ok=True)
            raw.replace(keep / (lid + ".raw"))
            print("OK", lid, flush=True)
            del pending[lid]
        time.sleep(3)
    if pending:
        print("LEFT", list(pending))


if __name__ == "__main__":
    main()
