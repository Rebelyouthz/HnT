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

Gentle by default so the machine never locks up (the Ally X shares 24 GB
between RAM and VRAM):
  * all prompts are encoded first, then the big text encoder (~11 GB) is
    thrown out of memory before the video model loads;
  * the GPU is capped at --vram GB (default 11), the rest goes to RAM;
  * VAE decode runs in tiles, CPU threads are capped at half the cores and
    the process runs at low priority, with a --rest pause between clips.
    python local_wan.py --vram 10 --rest 60   # even gentler
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
            jobs.append((who, move, row["desc"], q["moves"][move][:2], len(q["moves"][move]) > 2 and q["moves"][move][2] == "free"))
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
    ap.add_argument("--vram", type=float, default=11.0)   # GB the GPU may use
    ap.add_argument("--rest", type=int, default=30)       # seconds between clips
    ap.add_argument("--threads", type=int, default=0)     # CPU threads (0 = half the cores)
    a = ap.parse_args()
    OUT.mkdir(exist_ok=True)
    todo = [j for j in queue() if not (OUT / f"{j[0]}_{j[1]}.mp4").exists() and (not a.only or j[0] == a.only)]
    if a.list or not todo:
        for who, move, *_ in todo:
            print("missing", who, move)
        print(len(todo), "clips to make")
        return
    import gc
    import torch
    from diffusers import WanImageToVideoPipeline
    from diffusers.utils import export_to_video, load_image
    _be_gentle(torch, a)
    dev, dtype = device()
    print("loading", MODEL, "on", dev)
    pipe = WanImageToVideoPipeline.from_pretrained(MODEL, torch_dtype=dtype, low_cpu_mem_usage=True)
    # 1) Every prompt through the text encoder once, on the CPU, then drop it.
    jobs = []
    for who, move, desc, (dur, text), free in todo:
        if not (STARTS / f"{who}.png").exists():
            print("no start image for", who, "-> put one in", STARTS / f"{who}.png")
            continue
        # "free" moves (walk toward / away from the camera) drop the side-view rule.
        tail = TAIL.replace(" Strict side view,", "").replace(" facing right,", "") if free else TAIL
        neg = NEG.replace(", turning toward camera", "") if free else NEG
        with torch.no_grad():
            pe, ne = pipe.encode_prompt(prompt=text.format(d=desc) + tail, negative_prompt=neg,
                                        do_classifier_free_guidance=True, device="cpu", dtype=dtype)
        jobs.append((who, move, pe, ne))
    pipe.text_encoder = None
    gc.collect()
    print("prompts encoded, text encoder freed", flush=True)
    # 2) The video model: whole parts move to the GPU only while they run.
    try:
        pipe.enable_model_cpu_offload()
    except Exception:
        pipe.to(dev)
    try:
        pipe.vae.enable_tiling()
    except Exception:
        pass
    w, h = (int(v) for v in a.size.split("x"))
    for i, (who, move, pe, ne) in enumerate(jobs):
        t0 = time.time()
        with torch.no_grad():
            frames = pipe(image=load_image(str(STARTS / f"{who}.png")).resize((w, h)),
                          prompt_embeds=pe, negative_prompt_embeds=ne, height=h, width=w, num_frames=a.frames,
                          num_inference_steps=a.steps, guidance_scale=5.0).frames[0]
        out = OUT / f"{who}_{move}.mp4"
        export_to_video(frames, str(out), fps=16)
        print("OK", out, round(time.time() - t0), "s", flush=True)
        del frames
        gc.collect()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        if i < len(jobs) - 1 and a.rest > 0:
            time.sleep(a.rest)      # let it cool and the desktop breathe


def _be_gentle(torch, a):
    """Cap GPU memory, CPU threads and priority so the machine stays usable."""
    n = a.threads or max(2, (os.cpu_count() or 8) // 2)
    torch.set_num_threads(n)
    if torch.cuda.is_available():
        total = torch.cuda.get_device_properties(0).total_memory / 1024 ** 3
        frac = min(0.95, a.vram / max(total, 1.0))
        torch.cuda.set_per_process_memory_fraction(frac, 0)
        print(f"GPU capped at {a.vram:.0f} of {total:.0f} GB, {n} CPU threads", flush=True)
    try:
        import psutil
        p = psutil.Process()
        p.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS if os.name == "nt" else 10)
    except Exception:
        pass


if __name__ == "__main__":
    main()
