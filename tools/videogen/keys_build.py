import os, sys, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import keypose as K
SPEC=__import__(sys.argv[1]).SPEC; who=sys.argv[2]
cache={}
def fr(b):
    if b not in cache: cache[b]=K.frames(b)
    return cache[b]
def area(b): return float(np.median([(f.img[...,3]>=0.5).sum() for f in fr(b)]))
ib=SPEC['idle'][0][0]
base=600.0/float(np.median([f.img.shape[0] for f in fr(ib)])); ba=area(ib)
def scale(b): return base*np.sqrt(ba/area(b))
for clip,(st,en,prompt,mode) in SPEC.items():
    imgs=[fr(st[0])[st[1]].img]; sc=[scale(st[0])]; outs=['keys/%s_%s_a.png'%(who,clip)]
    if en: imgs.append(fr(en[0])[en[1]].img); sc.append(scale(en[0])); outs.append('keys/%s_%s_b.png'%(who,clip))
    K.place(imgs, sc, outs, center=(mode=='air'))
print('done', len(SPEC))
