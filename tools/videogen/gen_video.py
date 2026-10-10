"""Wan 2.2 i2v via HF Inference Providers (fal-ai). Optional end frame."""
import os, sys, base64, argparse
from huggingface_hub import InferenceClient
ap=argparse.ArgumentParser(); ap.add_argument('start'); ap.add_argument('prompt'); ap.add_argument('out')
ap.add_argument('--end'); ap.add_argument('--frames',type=int,default=81); ap.add_argument('--fps',type=int,default=16)
ap.add_argument('--seed',type=int,default=11); ap.add_argument('--res',default='720p')
a=ap.parse_args()
tok=os.environ.get('HF_TOKEN') or open(os.path.expanduser('~/.cache/huggingface/token')).read().strip()
def uri(p): return "data:image/png;base64,"+base64.b64encode(open(p,'rb').read()).decode()
kw=dict(frames_per_second=a.fps, resolution=a.res, enable_prompt_expansion=False)
if a.end: kw['end_image_url']=uri(a.end)
neg="camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, extra fingers, cropped body, turning toward camera, slow motion"
c=InferenceClient(provider="fal-ai", api_key=tok)
try:
    vid=c.image_to_video(open(a.start,'rb').read(), model="Wan-AI/Wan2.2-I2V-A14B", prompt=a.prompt, negative_prompt=neg,
        num_frames=a.frames, seed=a.seed, **kw)
    open(a.out,'wb').write(vid); print("OK", a.out, len(vid))
except Exception as e:
    print("ERR", a.out, type(e).__name__, str(e)[:300])
