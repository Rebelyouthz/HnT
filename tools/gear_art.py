import sys, shutil
from pathlib import Path
from gradio_client import Client
tok = (Path.home()/".cache/huggingface/token").read_text().strip()
STY = ", single item, inventory icon, detailed 16-bit pixel art, Streets of Rage 4 style item, bold dark outline, soft top-left light, centered, three-quarter view, whole item visible, flat solid bright green background #00b832, no text, no character, no shadow on background"
P = {
 "hoodie_lemon": "a lemon-yellow cropped zip hoodie with a hood and drawstrings",
 "polo_navy": "a folded-out navy blue polo shirt with a white collar",
 "clinic_scrubs": "a mint green hospital scrubs top with a chest pocket and a clipped ID badge",
 "night_tutor": "a black superhero bodysuit top with a yellow bat emblem and a short black cape",
 "pink_slip": "a red and blue spider-web patterned polo shirt with a pink FIRED rubber stamp mark",
 "billing_suit": "a sharp charcoal business suit jacket with paper invoices pinned to it and a red tie",
 "void_cape": "a flowing deep purple and black legendary cape with starry void lining and gold clasp",
 "eviction_polo": "a golden legendary polo shirt with a stapled red eviction notice on the chest, glowing",
 "headband": "a red sports headband with long tails tied at the back",
 "intake_visor": "a white clinic sun visor with a green cross badge and a small clipboard clip",
 "stapler_crown": "a crown built out of grey office staplers with tiny glowing lights",
 "invoice_halo": "a glowing golden halo made of a curled paper invoice, floating, radiant",
 "parkour_kicks": "a pair of orange and white high-top parkour sneakers",
 "loafer_web": "a pair of polished brown leather dress loafers with spider-web stitching",
 "copay_waders": "a pair of tall green rubber fishing waders boots",
 "roof_gums": "a pair of purple epic sneakers with thick sticky gum soles",
 "gold_wingtips": "a pair of shiny solid gold wingtip dress shoes, legendary, sparkling",
}
out = Path("/tmp/claude-0/gearart/raw")
flux = Client("black-forest-labs/FLUX.1-Krea-dev", token=tok)
for k, p in P.items():
    dst = out / f"{k}.webp"
    if dst.exists():
        continue
    try:
        img, s = flux.predict(prompt=p + STY, seed=5, randomize_seed=False, width=768, height=768, guidance_scale=4.5, num_inference_steps=28, api_name="/infer")
    except Exception as e:
        print("FAIL", k, str(e)[:200]); sys.stdout.flush()
        if "quota" in str(e).lower() or "exceeded" in str(e).lower():
            break
        continue
    shutil.copy(img, dst)
    print("OK", k); sys.stdout.flush()
