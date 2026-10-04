#!/usr/bin/env python3
"""Sound effects from text with MMAudio (HF Space hkchengrex/MMAudio), free.
Writes each to its game path (.wav or .ogg by extension), trimmed and
loudness-normalised. Existing files are skipped.

    python3 tools/mmaudio_sfx.py            # all missing
    python3 tools/mmaudio_sfx.py sfx/ricochet.ogg
"""
import subprocess, sys, os
from pathlib import Path
from gradio_client import Client

ROOT = Path(__file__).resolve().parent.parent
A = ROOT / "assets/audio"
NEG = "music, speech, talking, singing, background noise"
# path: (prompt, seconds)
SFX = {
    "body_fall.wav": ("heavy limp body falling onto wet street pavement, thud and splash", 1.5),
    "boss_roar.wav": ("huge angry man roaring a war cry, deep and furious, close", 2),
    "car_pass.wav": ("car driving past on a wet night street, tyres hissing on water", 3),
    "cash.wav": ("coins clinking into a pocket, bright short cash pickup", 1),
    "dog_bark.wav": ("medium dog barking twice, friendly, outdoors at night", 1.5),
    "heal.wav": ("soft magical healing chime with a warm shimmer, video game", 1.5),
    "level_up.wav": ("triumphant arcade level up jingle, short bright synth fanfare", 2),
    "shutter.wav": ("camera shutter click and film wind, close", 1),
    "spray.wav": ("spray paint can rattle and hiss, short burst", 1.5),
    "zap.wav": ("electric zap, crackling high voltage spark burst", 1),
    "sfx/mag_drop.ogg": ("empty pistol magazine falling and clattering on concrete", 1),
    "sfx/mag_in.ogg": ("pistol magazine inserted and slide racked, sharp metallic click clack", 1),
    "sfx/mag_out.ogg": ("pistol magazine release, metal click and slide out", 1),
    "sfx/ricochet.ogg": ("bullet ricochet whine off a brick wall, sharp ping", 1),
    "sfx/shell_in.ogg": ("shotgun shell pushed into the tube, single metallic click", 1),
    "sfx/shotgun_pump.ogg": ("pump action shotgun racking, metallic slide clack, close up, dry", 1),
    "sfx/foot_1.ogg": ("single sneaker footstep on wet cobblestone street, close", 1),
    "sfx/foot_2.ogg": ("single running footstep on wet asphalt, light splash", 1),
    "sfx/foot_3.ogg": ("single heavy boot step on wet pavement, close", 1),
    "sfx/foot_4.ogg": ("quick sneaker step scuff on wet stone, close", 1),
    "sfx/breath_run.ogg": ("young man breathing hard while running, two heavy breaths", 2),
    "sfx/jump.ogg": ("athlete jumping, cloth whoosh and sneaker push off, short exhale", 1),
    "sfx/land.ogg": ("person landing a jump on wet street, sneaker thud and small splash", 1),
    "sfx/whiff_punch.ogg": ("fast punch swinging through air and missing, sharp whoosh", 1),
    "sfx/whiff_kick.ogg": ("fast kick cutting through air, heavy whoosh", 1),
    "sfx/flip.ogg": ("acrobat doing a backflip, fast cloth whoosh spin", 1),
    "sfx/wall_kick.ogg": ("foot kicking off a brick wall, thump and scrape", 1),
    "sfx/glide.ogg": ("wind rushing past while falling and gliding, whoosh", 2),
    "sfx/crate_break.ogg": ("wooden crate smashed apart, splintering wood and planks falling", 1.5),
    "sfx/glass_break.ogg": ("window glass shattering, shards falling on pavement", 1.5),
    "sfx/metal_bang.ogg": ("heavy hit on a metal trash bin, loud clang", 1),
    "sfx/bullet_flesh.ogg": ("bullet hitting a body, wet meaty thwack", 1),
    "sfx/bullet_wall.ogg": ("bullet impact on brick wall, sharp crack and debris", 1),
    "sfx/kill_hit.ogg": ("massive finishing punch impact, deep bone crunch and thud, cinematic", 1),
}


def ffmpeg() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def main() -> None:
    tok = open(os.path.expanduser("~/.cache/huggingface/token")).read().strip()
    want = sys.argv[1:] or [k for k in SFX if not (A / k).exists()]
    c = Client("hkchengrex/MMAudio", token=tok)
    for rel in want:
        prompt, sec = SFX[rel]
        out = A / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        try:
            src = c.predict(prompt=prompt, negative_prompt=NEG, seed=7, num_steps=25, cfg_strength=4.5,
                            duration=max(1.0, float(sec)), api_name="/text_to_audio")
        except Exception as e:
            print("ERR", rel, str(e)[:160], flush=True)
            continue
        codec = ["-c:a", "libvorbis", "-q:a", "5"] if rel.endswith(".ogg") else ["-c:a", "pcm_s16le"]
        af = ("silenceremove=start_periods=1:start_threshold=-50dB,areverse,"
              "silenceremove=start_periods=1:start_threshold=-50dB,areverse,"
              f"atrim=0:{sec},afade=t=out:st={max(0.05, sec - 0.08)}:d=0.08,loudnorm=I=-14:TP=-1.0")
        subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", str(src), "-af", af, "-ac", "1",
                        "-ar", "44100", *codec, str(out)], check=True)
        print("OK", rel, flush=True)


if __name__ == "__main__":
    main()
