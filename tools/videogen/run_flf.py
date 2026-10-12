"""Wan 2.2 first/last-frame on a free ZeroGPU Space (multimodalart/wan-2-2-first-last-frame).
python3 run_flf.py son_spec son [clip,clip]  -> vid/<who>_<clip>.mp4 (skips existing). Stops on quota."""
import sys, os, shutil
from gradio_client import Client, handle_file
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
spec=__import__(sys.argv[1]); who=sys.argv[2]; only=sys.argv[3].split(',') if len(sys.argv)>3 else None
tok=open(os.path.expanduser('~/.cache/huggingface/token')).read().strip()
NEG="camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, extra fingers, cropped body, turning toward camera, slow motion, sparks, glow, effects"
os.makedirs('vid',exist_ok=True)
c=Client("multimodalart/wan-2-2-first-last-frame", token=tok)
for clip,(st,en,prompt,mode) in spec.SPEC.items():
    if only and clip not in only: continue
    out=f'vid/{who}_{clip}.mp4'
    if os.path.exists(out): print(clip,'cached',flush=True); continue
    a=f'keys/{who}_{clip}_a.png'; b=f'keys/{who}_{clip}_b.png' if en else a
    dur=3.3 if mode=='loop' else 2.1
    try:
        v,s=c.predict(start_image_pil=handle_file(a), end_image_pil=handle_file(b), prompt=prompt+spec.STYLE,
                      negative_prompt=NEG, duration_seconds=dur, steps=8, guidance_scale=1, guidance_scale_2=1,
                      seed=23, randomize_seed=False, api_name="/generate_video")
        path=v['video'] if isinstance(v,dict) else v
        shutil.copy(path,out); print(clip,'ok',out,flush=True)
    except Exception as e:
        print(clip,'ERR',str(e)[:300],flush=True)
        if 'quota' in str(e).lower(): break
print('FLF DONE')
