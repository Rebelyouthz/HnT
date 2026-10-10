#!/usr/bin/env python3
"""Voice data/vo_lines.json with ElevenLabs TTS (eleven_multilingual_v2).
Key from $ELEVENLABS_API_KEY or ~/.config/elevenlabs/key (never in git).
Writes assets/audio/vo/<id>.ogg (trimmed, normalised). Overwrites unless
--missing. Costs ~1 credit per character.

    python3 tools/eleven_vo.py [--missing] [id ...]
"""
import json, os, subprocess, sys, tempfile, time, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/audio/vo"
VOICE = {
    "son": "TX3LPaxmHKxFdv7VOQHJ", "father": "pNInz6obpgDQGcFmaJgB", "thug": "N2lVS1w4EtoT3dr4eOWO",
    "mohawk": "SOYHLrjzK2X1ezoPC6cr", "cop": "onwK4e9ZLuTAKqWW03F9", "shift_lead": "iP95p4xoKVk53GoZ742B",
    "gant": "JBFqnCBsd6RMkjVDRZzb", "announcer": "nPczCjzI2devNBz1zQrb", "npc_woman": "XrExE9yKIg1WjnnlVkGX",
    "npc_sal": "bIHbv24MWmeRgasZH58o", "npc_old": "pqHfZKP75CvOlQylNhV4", "repo": "CwhRBWXzGAHq8TQ4Fs17",
    "bailiff": "cjVigY5qzO86Huf0OWal", "runner": "IKne3meq5aSn9XLyUdCD", "snatch": "iP95p4xoKVk53GoZ742B",
    "imp": "FGY2WhTYpPnrIDTdsKH5", "valet": "SAz9YHcvj6GT2YYXdXww", "bystander": "bIHbv24MWmeRgasZH58o",
    "bystander_f": "EXAVITQu4vr4xnSDxMaL",
}
# Shouts and pain want more style / less stability than talk.
STYLE = {"attack": (0.25, 0.75), "effort": (0.25, 0.75), "hurt": (0.25, 0.7), "death": (0.35, 0.5), "kill": (0.35, 0.6), "taunt": (0.4, 0.55)}


def key() -> str:
    k = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    return k or (Path.home() / ".config/elevenlabs/key").read_text().strip()


def ffmpeg() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def tts(text: str, voice: str, stab: float, style: float) -> bytes:
    body = json.dumps({"text": text, "model_id": "eleven_multilingual_v2",
                       "voice_settings": {"stability": stab, "similarity_boost": 0.8, "style": style, "use_speaker_boost": True}}).encode()
    r = urllib.request.Request(f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128", data=body, method="POST")
    r.add_header("xi-api-key", key())
    r.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(r, timeout=120) as f:
        return f.read()


def main() -> None:
    args = sys.argv[1:]
    missing = "--missing" in args
    want = {a for a in args if not a.startswith("--")}
    book = json.loads((ROOT / "data/vo_lines.json").read_text())
    for ln in book["lines"]:
        out = OUT / (ln["id"] + ".ogg")
        if want and ln["id"] not in want:
            continue
        if missing and out.exists():
            continue
        v = VOICE.get(ln["who"])
        if not v:
            continue
        stab, style = STYLE.get(ln["ev"], (0.45, 0.3))
        try:
            mp3 = tts(ln["text"], v, stab, style)
        except Exception as e:
            print("ERR", ln["id"], str(e)[:200], flush=True)
            if "401" in str(e) or "402" in str(e) or "quota" in str(e).lower():
                break
            continue
        with tempfile.NamedTemporaryFile(suffix=".mp3") as tmp:
            tmp.write(mp3)
            tmp.flush()
            subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", tmp.name, "-af",
                            "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5",
                            "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(out)], check=True)
        print("OK", ln["id"], flush=True)
        time.sleep(0.3)


if __name__ == "__main__":
    main()
