import sys, subprocess, os, json
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
spec=__import__(sys.argv[1]); who=sys.argv[2]; only=sys.argv[3].split(',') if len(sys.argv)>3 else None
os.makedirs('vid',exist_ok=True)
def job(item):
    clip,(st,en,prompt,mode)=item
    out=f'vid/{who}_{clip}.mp4'
    if os.path.exists(out): return clip,'cached'
    frames = 81 if mode=='loop' else 33
    args=['python3','gen_video.py',f'keys/{who}_{clip}_a.png',prompt+spec.STYLE,out,'--frames',str(frames),'--fps','16']
    if en: args+=['--end',f'keys/{who}_{clip}_b.png']
    for attempt in range(2):
        r=subprocess.run(args,capture_output=True,text=True,timeout=1500)
        if os.path.exists(out): return clip,'ok'
    return clip,'FAIL '+(r.stdout+r.stderr)[-200:]
items=[(k,v) for k,v in spec.SPEC.items() if (not only or k in only)]
with ThreadPoolExecutor(4) as ex:
    for clip,res in ex.map(job, items):
        print(clip,res,flush=True)
print('BATCH DONE')
