#!/usr/bin/env python3
"""Fill missing voice lines (data/vo_lines.json) offline with Kokoro TTS on
the CPU - no account or credits. Each line is trimmed, pitch-shaped per
character and loudness-normalised into assets/audio/vo/<id>.ogg.

    pip install kokoro soundfile      (once)
    python3 tools/kokoro_vo.py        # all missing lines
    python3 tools/kokoro_vo.py id ... # just these
"""
import json, subprocess, sys, tempfile
from pathlib import Path
import numpy as np, soundfile as sf
from kokoro import KPipeline

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/audio/vo"
# who: (kokoro voice, speed, pitch factor)
VOICE = {
    "son": ("am_puck", 1.1, 1.06), "father": ("am_onyx", 0.95, 0.94),
    "thug": ("am_fenrir", 1.05, 0.95), "mohawk": ("am_fenrir", 1.0, 0.88),
    "cop": ("am_michael", 0.95, 0.92), "shift_lead": ("am_eric", 1.05, 1.0),
    "gant": ("bm_george", 0.92, 0.9), "announcer": ("am_onyx", 0.9, 0.85),
    "npc_woman": ("af_sarah", 0.9, 0.9), "npc_sal": ("am_echo", 1.0, 0.95),
    "npc_old": ("bm_lewis", 0.85, 0.86), "repo": ("am_fenrir", 0.95, 0.82),
    "bailiff": ("bm_daniel", 1.0, 0.88), "runner": ("am_liam", 1.15, 1.08),
    "snatch": ("am_adam", 1.2, 1.1), "imp": ("am_puck", 1.15, 1.18),
    "valet": ("am_eric", 1.1, 1.02),
}


def ffmpeg() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def main() -> None:
    book = json.loads((ROOT / "data/vo_lines.json").read_text())
    want = set(sys.argv[1:])
    pipes = {}
    for ln in book["lines"]:
        out = OUT / (ln["id"] + ".ogg")
        if want and ln["id"] not in want:
            continue
        if not want and out.exists():
            continue
        v, spd, pitch = VOICE.get(ln["who"], ("am_michael", 1.0, 1.0))
        lang = "b" if v.startswith("b") else "a"
        p = pipes.setdefault(lang, KPipeline(lang_code=lang))
        audio = np.concatenate([np.asarray(x[2]) for x in p(ln["text"], voice=v, speed=spd)])
        with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
            sf.write(tmp.name, audio, 24000)
            sr = int(24000 * pitch)
            af = (f"asetrate={sr},aresample=44100,atempo={1.0 / pitch:.4f},"
                  "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
                  "silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5")
            subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", tmp.name, "-af", af,
                            "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(out)], check=True)
        print("OK", ln["id"], flush=True)


if __name__ == "__main__":
    main()
