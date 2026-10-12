import os
from gradio_client import Client
from PIL import Image
tok=open(os.path.expanduser('~/.cache/huggingface/token')).read().strip()
c=Client("black-forest-labs/FLUX.1-Krea-dev", token=tok)
BASE="16-bit pixel art game sprite sheet, objects seen exactly from directly above (top-down orthographic), each object separate and well spaced in a loose grid with lots of empty space between them, flat solid pure magenta background (#FF00FF), no shadows on the background, no text, crisp dark outlines: "
P={
 "lot": "a square storm drain grate, a round iron manhole cover, a crushed soda can, a paper coffee cup on its side, a folded newspaper, a dark oil puddle, a flattened cardboard box, scattered broken glass shards, a lost sneaker, a crumpled parking ticket",
 "circle": "a cluster of orange fallen autumn leaves, a cluster of brown dry leaves, a crumpled newspaper page, a handful of cigarette butts, a dropped paper flyer, a pigeon feather pile, a broken umbrella lying flat, a chalk hopscotch drawing, a paper bag, a soda bottle",
 "clinic": "a dropped clipboard with paper forms, scattered loose paper sheets, a paper coffee cup, a spilled pill bottle with pills, a blue rubber glove, a crumpled tissue, a yellow wet floor puddle, a dropped name badge on a lanyard, a magazine lying open, a paper ticket number slip",
 "sleet": "a patch of grey slush, a small snow pile, a dropped red knitted scarf, a lost mitten, a broken ice chunk, a bag of road salt, a frozen puddle, scattered rock salt, a snowy fallen branch, a paper cup half buried in snow",
 "dock": "a coiled thick rope, a dead fish, a red crab, a rusty chain loop, a green glass bottle, a tangled fishing net, a metal bucket on its side, a wooden crate lid, a rusty anchor, a puddle of sea water with seaweed",
}
for k,p in P.items():
    if os.path.exists(k+".png"): continue
    try:
        r=c.predict(BASE+p, 5, False, 1024, 1024, 4.5, 28, api_name="/infer")
        src=r[0] if isinstance(r,(list,tuple)) else r
        Image.open(src).convert("RGB").save(k+".png"); print("ok",k,flush=True)
    except Exception as e: print("err",k,repr(e)[:200],flush=True)
