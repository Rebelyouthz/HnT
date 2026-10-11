"""Run fix_spec jobs on free ZeroGPU Spaces: FLF when an end key is given, else plain I2V.
python3 run_fix.py [who_clip,...]  -> vid/<who>_<clip>.mp4"""
import sys, os, shutil
from gradio_client import Client, handle_file
import fix_spec as F
tok=open(os.path.expanduser('~/.cache/huggingface/token')).read().strip()
NEG="camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, extra fingers, cropped body, turning toward camera, slow motion, sparks, glow, effects"
only=sys.argv[1].split(',') if len(sys.argv)>1 else None
os.makedirs('vid',exist_ok=True)
flf=i2v=None
for who,clip,a,b,prompt,dur in F.JOBS:
    tag=f'{who}_{clip}'
    if only and tag not in only: continue
    out=f'vid/{tag}.mp4'
    if os.path.exists(out): print(tag,'cached',flush=True); continue
    try:
        if b:
            flf=flf or Client("multimodalart/wan-2-2-first-last-frame", token=tok)
            v,s=flf.predict(start_image_pil=handle_file(a), end_image_pil=handle_file(b), prompt=prompt+F.STYLE, negative_prompt=NEG,
                            duration_seconds=dur, steps=8, guidance_scale=1, guidance_scale_2=1, seed=23, randomize_seed=False, api_name="/generate_video")
        else:
            i2v=i2v or Client("zerogpu-aoti/wan2-2-fp8da-aoti-faster", token=tok)
            v,s=i2v.predict(input_image=handle_file(a), prompt=prompt+F.STYLE, steps=6, negative_prompt=NEG, duration_seconds=dur,
                            guidance_scale=1, guidance_scale_2=1, seed=23, randomize_seed=False, api_name="/generate_video")
        path=v['video'] if isinstance(v,dict) else v
        shutil.copy(path,out); print(tag,'ok',flush=True)
    except Exception as e:
        print(tag,'ERR',str(e)[:300],flush=True)
        if 'quota' in str(e).lower(): break
print('FIX DONE')
