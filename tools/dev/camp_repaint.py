# Repaint one 21:9 slice of the old pixel hideout (ref_<i>.png, nearest x4) at 2K with
# gpt-image-2 via Sorceress (8 credits). Slices: x 0-520, 447-967, 895-1415 of the
# 1415x199 room, padded to 21:9 on top; stitched with 73-texel linear seams.
import sys, json
sys.path.insert(0,'tools'); import sorceress as S
i=int(sys.argv[1]); model=sys.argv[2] if len(sys.argv)>2 else 'gpt-image-2'
ref=S.upload(f'/tmp/claude-0/camp_hd/ref_{i}.png'); sty=S.upload('/tmp/claude-0/camp_hd/style_dock.png')
prompt=("Image 1 is a blurry low-resolution pixel screenshot of a cosy basement hideout in a 2D side-view beat 'em up game. "
 "Repaint image 1 as a crisp, detailed, high-resolution painted pixel-art game background with the same rendering quality, fine detail and lighting style as image 2. "
 "Keep the exact same composition as image 1: every wall, door, shelf, cabinet, poster, sign, lamp, pipe and piece of furniture stays at exactly the same position, size and shape, the same colours and warm lamp light, the same side-on perspective, and the wooden floor line at the same height. "
 "Add fine texture and small believable details (wood grain, brick, scuffs, cables, labels without readable words). The dark band at the very top stays dark. No people, no characters, no readable text, no new large objects, no frame or border.")
r=S.call("image_generate",{"model":model,"prompt":prompt,"aspectRatio":"21:9","params":{"resolution":"2K"},"refImages":[ref,sty]})
print('CALL', json.dumps(r)[:400])
def find(o,key):
    if isinstance(o,dict):
        for k,v in o.items():
            if k==key and isinstance(v,str): return v
            x=find(v,key)
            if x: return x
    if isinstance(o,list):
        for v in o:
            x=find(v,key)
            if x: return x
jid=find(r,'jobId')
if not jid: sys.exit(1)
j=S.job(jid, every=6, timeout=900)
open(f'/tmp/claude-0/camp_hd/job{i}.json','w').write(json.dumps(j))
print('JOB', json.dumps(j)[:700])
urls=[]
def allurls(o):
    if isinstance(o,dict):
        for v in o.values(): allurls(v)
    elif isinstance(o,list):
        for v in o: allurls(v)
    elif isinstance(o,str) and o.startswith('http') and any(e in o.lower() for e in ('.png','.jpg','.jpeg','.webp')): urls.append(o)
allurls(j.get('result',j))
if urls:
    S.fetch(urls[0], f'/tmp/claude-0/camp_hd/out_{i}.png'); print('SAVED', urls[0][:120])
