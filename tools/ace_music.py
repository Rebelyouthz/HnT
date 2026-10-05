#!/usr/bin/env python3
"""Instrumental game music with ACE-Step (HF Space ACE-Step/ACE-Step), free.
Optionally styled after a reference track (audio2audio). Output: ogg in
assets/audio/music/. Existing files are skipped.

    python3 tools/ace_music.py [name ...]
"""
import os, subprocess, sys
from pathlib import Path
from gradio_client import Client, handle_file

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/audio/music"
REF = os.environ.get("MUSIC_REF", "")  # optional style reference (not committed)
# name: (prompt, seconds, use reference, seed)
TRACKS = {
    "music_survive": ("melodic psytrance, metal, distorted electric guitar riffs, bagpipe-like lead melody, rolling psy bassline, 140 bpm, relentless, epic, video game survival horde, instrumental", 150, True, 7),
    "music_boss": ("heavy metal psytrance, thrash guitar riffs, double kick drums, dark acid synth leads, 145 bpm, aggressive, climactic, video game boss battle, instrumental", 120, True, 13),
    "music_menu": ("calm melodic synthwave, soft clean electric guitar, warm pads, slow 90 bpm, night city, hopeful, video game main menu, instrumental", 120, False, 21),
    "music_shop": ("chill lofi hip hop, mellow electric piano, soft vinyl crackle, slow 80 bpm, cozy shop, relaxed, instrumental", 90, False, 5),
    "music_camp": ("calm ambient downtempo, soft acoustic guitar, gentle synth pads, rain outside, hideout at night, warm, instrumental", 120, False, 9),
}


def ffmpeg() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def main() -> None:
    tok = open(os.path.expanduser("~/.cache/huggingface/token")).read().strip()
    want = sys.argv[1:] or [k for k in TRACKS if not (OUT / (k + ".ogg")).exists()]
    c = Client("ACE-Step/ACE-Step", token=tok)
    OUT.mkdir(parents=True, exist_ok=True)
    for name in want:
        prompt, sec, use_ref, seed = TRACKS[name]
        ref = REF if (use_ref and REF and os.path.exists(REF)) else None
        try:
            r = c.predict(audio_duration=sec, prompt=prompt, lyrics="[instrumental]", infer_step=60,
                          guidance_scale=15.0, scheduler_type="euler", cfg_type="apg", omega_scale=10.0,
                          manual_seeds=str(seed), guidance_interval=0.5, guidance_interval_decay=0.0,
                          min_guidance_scale=3.0, use_erg_tag=True, use_erg_lyric=False, use_erg_diffusion=True,
                          oss_steps="", guidance_scale_text=0.0, guidance_scale_lyric=0.0,
                          audio2audio_enable=bool(ref), ref_audio_strength=0.35,
                          ref_audio_input=handle_file(ref) if ref else None, lora_name_or_path="none",
                          api_name="/__call__")
        except Exception as e:
            print("ERR", name, str(e)[:200], flush=True)
            continue
        src = r[0] if isinstance(r, (list, tuple)) else r
        # Gentle fades at both ends so the loop point does not click.
        af = f"afade=t=in:d=0.4,afade=t=out:st={sec - 1.5}:d=1.5,loudnorm=I=-15:TP=-1.5"
        subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", str(src), "-af", af, "-ar", "44100",
                        "-c:a", "libvorbis", "-q:a", "5", str(OUT / (name + ".ogg"))], check=True)
        print("OK", name, flush=True)


if __name__ == "__main__":
    main()
