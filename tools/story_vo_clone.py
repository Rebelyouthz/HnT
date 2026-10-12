#!/usr/bin/env python3
"""Voice missing story lines when the ElevenLabs quota is out: zero-shot
voice cloning on the Chatterbox Hugging Face space, with each speaker's
reference built from clips of them already in assets/audio/vo/story (so
the clone keeps the cast's ElevenLabs voice). Same file names and
post-processing as tools/story_vo.py; skips clips already on disk.

    python3 tools/story_vo_clone.py [--dry] [--max N] [--who father,son]
"""
import os, subprocess, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import story_vo as S
import eleven_vo as E

SPACE = "ResembleAI/Chatterbox"
REF_DIR = Path(tempfile.gettempdir()) / "story_vo_refs"
BARKS = {"collector": "gant"}


def reference(who: str, lines) -> Path | None:
    """~12 s of the speaker: their longest existing clips, joined."""
    have = [S.clip(w, t) for w, t in lines if w == who and S.clip(w, t).exists()]
    # No story clips yet: the speaker's combat barks carry the same voice.
    if not have:
        bark = BARKS.get(who, who)
        have = sorted((S.ROOT / "assets/audio/vo").glob(bark + "_*.ogg"))
    have.sort(key=lambda p: -p.stat().st_size)
    if not have:
        return None
    REF_DIR.mkdir(exist_ok=True)
    out = REF_DIR / f"{who}.wav"
    if out.exists():
        return out
    pick = have[:4]
    cmd = [E.ffmpeg(), "-y", "-loglevel", "error"]
    for p in pick:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", "".join(f"[{i}:a]" for i in range(len(pick))) + f"concat=n={len(pick)}:v=0:a=1,atrim=0:14",
            "-ac", "1", "-ar", "24000", str(out)]
    subprocess.run(cmd, check=True)
    return out


def main():
    from gradio_client import Client, handle_file
    dry = "--dry" in sys.argv
    cap = int(sys.argv[sys.argv.index("--max") + 1]) if "--max" in sys.argv else 999
    only = set(sys.argv[sys.argv.index("--who") + 1].split(",")) if "--who" in sys.argv else None
    allq = S.queue()
    q = [(w, t) for w, t in allq if not S.clip(w, t).exists() and (only is None or w in only)]
    print(len(q), "lines without a voice")
    if dry or not q:
        return
    tok = Path("~/.cache/huggingface/token").expanduser()
    if tok.exists():
        os.environ["HF_TOKEN"] = tok.read_text().strip()
    c = Client(SPACE, verbose=False)
    done = 0
    for who, text in q:
        if done >= cap:
            break
        ref = reference(who, allq)
        if ref is None:
            print("no reference voice for", who)
            continue
        try:
            wav = c.predict(text, handle_file(str(ref)), 0.55, 0.75, 7, 0.45, True, api_name="/generate_tts_audio")
        except Exception as e:
            print("ERR", who, str(e)[:200], flush=True)
            if "quota" in str(e).lower() or "exceeded" in str(e).lower():
                break
            continue
        subprocess.run([E.ffmpeg(), "-y", "-loglevel", "error", "-i", wav, "-af",
                        "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5",
                        "-ac", "1", "-ar", "32000", "-c:a", "libvorbis", "-q:a", "1", str(S.clip(who, text))], check=True)
        done += 1
        print("OK", who, S.clip(who, text).name, repr(text[:50]), flush=True)


if __name__ == "__main__":
    main()
