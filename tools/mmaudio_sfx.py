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
    "sfx/mag_drop.ogg": ("empty pistol magazine falling and clattering on concrete", 0.6),
    "sfx/mag_in.ogg": ("pistol magazine inserted and slide racked, sharp metallic click clack", 1),
    "sfx/mag_out.ogg": ("pistol magazine release, metal click and slide out", 0.6),
    "sfx/ricochet.ogg": ("bullet ricochet whine off a brick wall, sharp ping", 1),
    "sfx/shell_in.ogg": ("shotgun shell pushed into the tube, single metallic click", 1),
    "sfx/shotgun_pump.ogg": ("pump action shotgun racking, metallic slide clack, close up, dry", 1),
    "sfx/foot_1.ogg": ("single sneaker footstep on wet cobblestone street, close", 0.4),
    "sfx/foot_2.ogg": ("single running footstep on wet asphalt, light splash", 0.4),
    "sfx/foot_3.ogg": ("single heavy boot step on wet pavement, close", 0.4),
    "sfx/foot_4.ogg": ("quick sneaker step scuff on wet stone, close", 0.4),
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
    "sfx/gun_pistol.ogg": ("single 9mm pistol gunshot, sharp crack with short echo in a city street", 1),
    "sfx/gun_smg.ogg": ("single submachine gun shot, fast snappy crack", 0.4),
    "sfx/gun_throw.ogg": ("metal throwing star whizzing through the air, sharp whoosh", 0.7),
    "sfx/gun_web.ogg": ("sticky web shot, quick elastic thwip", 0.6),
    "sfx/melee_pipe.ogg": ("metal pipe smashing into a body, hollow metallic clang and thud", 1),
    "sfx/melee_board.ogg": ("wooden plank whacking a person, hard wood smack", 1),
    "sfx/melee_knife.ogg": ("knife slash through cloth and flesh, sharp swish and cut", 0.8),
    "sfx/melee_chain.ogg": ("heavy chain whipping and hitting, metal rattle and smack", 1),
    "sfx/melee_crowbar.ogg": ("crowbar hitting a body, heavy metallic thunk", 1),
    "sfx/melee_light.ogg": ("plastic clipboard slapping a face, sharp light smack", 0.7),
    "sfx/hit_jab.ogg": ("quick snappy jab punch to the face, light crisp smack", 0.6),
    "sfx/hit_cross.ogg": ("hard straight right punch to the jaw, solid smack with a thud", 0.7),
    "sfx/hit_gut.ogg": ("punch to the stomach, deep muffled body thud with air knocked out", 0.8),
    "sfx/hit_heavy.ogg": ("huge haymaker punch impact, heavy crunch and deep thud", 0.9),
    "sfx/hit_uppercut.ogg": ("rising uppercut punch to the chin, sharp bone crack and smack", 0.8),
    "sfx/hit_front_kick.ogg": ("front kick into the chest, solid thump", 0.7),
    "sfx/hit_side_kick.ogg": ("powerful side kick into the ribs, heavy body thud with crunch", 0.8),
    "sfx/hit_roundhouse.ogg": ("spinning roundhouse kick to the head, loud whip slap impact", 0.8),
    "sfx/hit_knee.ogg": ("knee strike into the ribs, dull heavy thud", 0.7),
    "sfx/hit_elbow.ogg": ("sharp elbow strike to the face, hard crack", 0.6),
    "sfx/hit_stomp.ogg": ("heavy boot stomping on a body on the ground, crunch", 0.8),
    "sfx/hit_headbutt.ogg": ("headbutt, two skulls knocking, dull hard thud", 0.7),
    "sfx/hit_sweep.ogg": ("leg sweep, swish and a body slamming onto pavement", 1),
    "sfx/hit_dive.ogg": ("flying kick crashing into a body, heavy impact thud", 0.9),
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
        # Normalise first so quiet takes are not trimmed away, then cut the
        # leading silence, keep `sec`, fade the tail.
        af = ("loudnorm=I=-14:TP=-1.0,silenceremove=start_periods=1:start_threshold=-40dB,"
              f"atrim=0:{sec},afade=t=out:st={max(0.05, sec * 0.7)}:d={max(0.03, sec * 0.3):.3f}")
        subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-i", str(src), "-af", af, "-ac", "1",
                        "-ar", "44100", *codec, str(out)], check=True)
        print("OK", rel, flush=True)


if __name__ == "__main__":
    main()
