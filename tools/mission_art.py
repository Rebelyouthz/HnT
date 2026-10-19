import os, sys, shutil
from pathlib import Path
from gradio_client import Client
tok = (Path.home()/".cache/huggingface/token").read_text().strip()
HEROES = "a stubbled father in a grey hoodie and his teenage son in a black zip jacket, seen from behind in the foreground"
STY = ", detailed 16-bit pixel art, Streets of Rage 4 meets Hotline Miami key art, wide cinematic composition, night, rain, neon rim light, deep shadows, rich limited palette, crisp pixels, no text, no letters, no logos, no UI"
P = {
 "tutorial_alley": f"a narrow back alley behind a clinic, puddles, a punching dummy made of trash bags, a flickering neon cross sign, {HEROES} stretching before training",
 "dock_street": f"a rainy harbour street with cranes and a water tower, wet cobblestones, brick tenements with fire escapes, {HEROES} walking toward a hulking debt collector in a long coat with a clipboard and brass knuckles, flanked by beanie street punks, eviction papers blowing",
 "intake_lot": f"a flooded night car park with abandoned cars, a towing truck with a giant wheel clamp, sodium lamps reflecting in water, {HEROES} back to back as a horde of thugs closes in, a three-headed tow-truck monster looming",
 "fire_escapes": f"rooftops and iron fire escapes high above a neon city, water towers, laundry lines, {HEROES} leaping a gap between roofs while a man in a suit with hawk wings of contracts waits on the far roof",
 "group_circle": f"a courtyard with folding chairs set in a circle under string lights, a smiling facilitator in a cardigan holding a talking stick like a weapon, crowds of hooded attendees surrounding {HEROES}",
 "neon_exchange": f"a glowing neon pawn and exchange street with pink and cyan signs and slot machines, agents in black suits and sunglasses, {HEROES} facing an agent holding a warrant",
 "waiting_room": f"an endless fluorescent hospital waiting room with rows of plastic chairs and a ticket number display showing 88, a masked figure holding a ticket, {HEROES} standing ready among lurching patients",
 "rail_bridge": f"a steel rail bridge at night over a river, a freight train with a lit locomotive, a conductor in a cap holding a grenade, {HEROES} standing on the tracks in the rain",
 "city_hall": f"the steps of a gothic city hall with marble statues and a giant clock, a landlord ninja mayor in a black suit with a raven mask throwing shuriken, {HEROES} climbing the steps under a storm",
 "copay_orchard": f"a moonlit orchard and fields with a grain silo and a combine harvester with glowing headlights, a brute in overalls, {HEROES} on a dirt road between apple trees",
 "sleet_hour": f"a frozen lake at night in heavy sleet, pine forest, snowmobiles with headlights circling, {HEROES} standing on cracking ice with breath steaming",
 "raven_grid": f"a neon canal city at night, a lemon-yellow clinic courier van speeding over a ramp, a helicopter with a searchlight overhead, {HEROES} hanging off the van",
 "ledger_dive": f"a flooded bank vault turned into a luxury spa with glowing turquoise water, drowned billboards, columns, {HEROES} waist deep in water facing an elite guard in a bathrobe",
 "invoice_pier": f"a flooded pier warehouse annex with paper invoices floating everywhere, a sinister doctor in a white coat with a giant splint arm behind a desk, {HEROES} walking down the wet corridor",
 "processing_floor": f"a vast industrial processing floor with conveyor belts, stamping machines and red warning lights, an armored corporate director and a huge billing mech, {HEROES} squared up for the final fight",
}
out = Path("/tmp/claude-0/mission/raw"); out.mkdir(parents=True, exist_ok=True)
flux = Client("black-forest-labs/FLUX.1-Krea-dev", token=tok)
for k, p in P.items():
    dst = out / f"{k}.webp"
    if dst.exists():
        continue
    try:
        img, s = flux.predict(prompt=p + STY, seed=11, randomize_seed=False, width=1344, height=608, guidance_scale=4.5, num_inference_steps=28, api_name="/infer")
    except Exception as e:
        print("FAIL", k, str(e)[:200]); sys.stdout.flush()
        if "quota" in str(e).lower() or "exceeded" in str(e).lower():
            break
        continue
    shutil.copy(img, dst)
    print("OK", k); sys.stdout.flush()
