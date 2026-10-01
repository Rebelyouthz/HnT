"""Key poses from old AI boards on a shared white canvas: one body size, feet on one baseline."""
import sys, numpy as np
sys.path.insert(0,'/home/user/hnt/tools')
import slice_sprites as S
from pathlib import Path
from PIL import Image
W=H=768
def frames(board):
    return S.raw_frames(Path('/home/user/hnt/tools/sprite_src/'+board),'feet')
def place(imgs, scales, out_paths, center=False):
    ref=None; ref_x=0
    for im, s, p in zip(imgs, scales, out_paths):
        r=S._trim(S.resample(im, s, hard=False))
        m=r[...,3]>=0.5
        if ref is None:
            ref=m; x=(W-r.shape[1])//2; ref_x=x
        else:
            start=(ref.shape[1]-m.shape[1])//2
            x=ref_x+S._best_dx(ref, m, start, int(max(m.shape[1], ref.shape[1])*0.45))
        y=(H-r.shape[0])//2 if center else H-30-r.shape[0]
        x=int(np.clip(x,0,W-r.shape[1])); y=int(np.clip(y,0,H-r.shape[0]))
        bg=np.ones((H,W,3),np.float32); a=r[...,3:4]
        bg[y:y+r.shape[0],x:x+r.shape[1]]=r[...,:3]*a+bg[y:y+r.shape[0],x:x+r.shape[1]]*(1-a)
        Image.fromarray((bg*255).astype(np.uint8)).save(p)
