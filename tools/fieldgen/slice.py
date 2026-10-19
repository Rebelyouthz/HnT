import os, numpy as np
from PIL import Image
from scipy import ndimage
OUT="/home/user/hnt/assets/sprites/field/decals"
os.makedirs(OUT, exist_ok=True)
for m in ["lot","circle","clinic","sleet","dock"]:
    a=np.asarray(Image.open(m+".png").convert("RGB")).astype(float)
    r,g,b=a[...,0],a[...,1],a[...,2]
    corners=np.concatenate([a[:8,:8].reshape(-1,3),a[-8:,-8:].reshape(-1,3)])
    bgc=np.median(corners,0)
    dist=np.sqrt(((a-bgc)**2).sum(-1))
    bg=(dist<90)|((r-g>80)&(b-g>40)&(r>150))
    fg=~bg
    fg=ndimage.binary_opening(fg,iterations=1)
    grp=ndimage.binary_dilation(fg,iterations=14)
    lab,n=ndimage.label(grp)
    k=0
    for i,sl in enumerate(ndimage.find_objects(lab)):
        piece=(lab[sl]==i+1)&fg[sl]
        if piece.sum()<900: continue
        h,w=piece.shape
        if h<20 or w<20: continue
        rgb=a[sl].copy()
        edge=ndimage.binary_dilation(~piece,iterations=2)&piece
        mg=np.minimum(rgb[...,1]+30,255)
        rgb[edge,0]=np.minimum(rgb[edge,0],mg[edge]); rgb[edge,2]=np.minimum(rgb[edge,2],mg[edge])
        alpha=ndimage.binary_erosion(piece,iterations=1).astype(np.uint8)*255
        im=Image.fromarray(np.dstack([np.clip(rgb,0,255).astype(np.uint8),alpha]),"RGBA")
        bb=im.getbbox()
        if not bb: continue
        im=im.crop(bb)
        s=128.0/max(im.size)
        if s<1: im=im.resize((max(1,int(im.width*s)),max(1,int(im.height*s))),Image.LANCZOS)
        im.save(f"{OUT}/{m}_{k:02d}.png"); k+=1
    print(m,k)
