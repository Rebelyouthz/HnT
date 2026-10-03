#!/usr/bin/env python3
"""Make the game's animation clips on your own machine (ROG Ally X or any PC
with a GPU), no Hugging Face quota. Same queue as tools/hf_batch.py, but
runs Wan 2.2 TI2V-5B locally through diffusers.

    python local_wan.py --list              # what is still missing
    python local_wan.py                     # work through the queue
    python local_wan.py --only repo_goon    # one character

Clips land in tools/local_gpu/clips/<who>_<move>.mp4. Push them (or copy
them into /tmp/claude-0/hfv/clips on the dev box) and the slicer turns them
into sprites. Slow on an iGPU (expect 10-40 min a clip); it does not matter,
leave it overnight.
"""
import argparse, json, os, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = HERE / "clips"
STARTS = HERE / "starts"
MODEL = os.environ.get("WAN_MODEL", "Wan-AI/Wan2.2-TI2V-5B-Diffusers")

TAIL = (" Strict side view, locked static camera that never moves or zooms, facing right, full body always in frame, "
        "flat solid green background that never changes, no other people, realistic human motion with weight and momentum, "
        "keep the exact same pixel art style and outfit.")
NEG = ("camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, "
       "morphing, deformed limbs, extra limbs, cropped body, turning toward camera, slow motion")


def queue():
    """The jobs: every <who>_<move> named in queue.json that has no clip yet."""
    q = json.loads((HERE / "queue.json").read_text())
    jobs = []
    for who, row in q["who"].items():
        for move in row["moves"]:
            jobs.append((who, move, row["desc"], q["moves"][move]))
    return jobs


def device():
    import torch
    if torch.cuda.is_available():          # NVIDIA, or AMD with ROCm (shows up as cuda)
        return "cuda", torch.bfloat16
    try:
        import torch_directml                # AMD/Intel on Windows without ROCm
        return torch_directml.device(), torch.float16
    except ImportError:
        pass
    print("No GPU found: running on the CPU (very slow).")
    return "cpu", torch.float32


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--frames", type=int, default=49)    # ~3 s at 16 fps
    ap.add_argument("--steps", type=int, default=30)
    ap.add_argument("--size", default="704x544")
    a = ap.parse_args()
    OUT.mkdir(exist_ok=True)
    todo = [j for j in queue() if not (OUT / f"{j[0]}_{j[1]}.mp4").exists() and (not a.only or j[0] == a.only)]
    if a.list or not todo:
        for who, move, *_ in todo:
            print("missing", who, move)
        print(len(todo), "clips to make")
        return
    import torch
    from diffusers import WanImageToVideoPipeline
    from diffusers.utils import export_to_video, load_image
    dev, dtype = device()
    print("loading", MODEL, "on", dev)
    pipe = WanImageToVideoPipeline.from_pretrained(MODEL, torch_dtype=dtype)
    try:
        pipe.enable_model_cpu_offload()    # keeps VRAM use low on the Ally's shared memory
    except Exception:
        pipe.to(dev)
    w, h = (int(v) for v in a.size.split("x"))
    for who, move, desc, (dur, text) in todo:
        start = STARTS / f"{who}.png"
        if not start.exists():
            print("no start image for", who, "-> put one in", start)
            continue
        t0 = time.time()
        frames = pipe(image=load_image(str(start)).resize((w, h)), prompt=text.format(d=desc) + TAIL,
                      negative_prompt=NEG, height=h, width=w, num_frames=a.frames,
                      num_inference_steps=a.steps, guidance_scale=5.0).frames[0]
        out = OUT / f"{who}_{move}.mp4"
        export_to_video(frames, str(out), fps=16)
        print("OK", out, round(time.time() - t0), "s", flush=True)


if __name__ == "__main__":
    main()
