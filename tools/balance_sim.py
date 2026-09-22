#!/usr/bin/env python3
"""Whole-game balance sim. Night Class vs Finals. Covers every currency, weapon, shop, tree node."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path("/home/timmietooth/projects/HnT")
DATA = ROOT / "data"


def load(name: str):
    return json.loads((DATA / name).read_text())


encounters = load("encounters.json")
story = load("story.json")
cbt = load("cbt.json")
shop = load("shop.json")
weapons = load("weapons.json")
gear = load("gear.json")["items"]
cards = load("cards.json")
dojo = load("dojo.json")
research = load("research.json")
awards = load("awards.json")
kits = load("kits.json")
parts = load("parts.json")
secrets = load("secrets.json")
towers = load("towers.json")
milestones = load("milestones.json")
buildings = load("buildings.json")

SON_HP = 92
DAD_HP = 118
LIGHT_IN = 6
HEAVY_IN = 16
JAB = 6
HEAVY_OUT = 22
LIVES = 3
XP_GATES = [70, 160, 260, 380]
CLEAR_GOLD = 12
GATE_GOLD = 4
START_GOLD = 40
START_GEMS = 3
START_REP = 1
START_SCRAP_COIL = 2

ORDER = [
    "dock_street", "intake_lot", "fire_escapes", "group_circle",
    "neon_exchange", "waiting_room", "rail_bridge", "city_hall",
    "copay_orchard", "sleet_hour", "raven_grid", "ledger_dive",
    "invoice_pier", "processing_floor",
]


def hp_mul(diff: str) -> float:
    return {"open_house": 0.75, "night_class": 1.0, "finals": 1.35}[diff]


def telegraph(diff: str) -> float:
    return {"open_house": 1.45, "night_class": 1.0, "finals": 0.7}[diff]


def loop(diff: str, density: str) -> dict:
    gold = START_GOLD
    gems = START_GEMS
    rep = START_REP
    scrap = 0
    xp = 0
    levels = 0
    account_xp = 0
    account_lv = 1
    deaths = 0
    lives = LIVES
    hp = SON_HP
    parts_have = {"scrap_coil": START_SCRAP_COIL, "clinic_thread": 0, "invoice_ink": 0}
    cards_taken = 0
    lunch = 0
    towers_ok = 0
    secrets_ok = 0
    cbt_owned: list[str] = []
    dojo_ranks: dict[str, int] = {}
    research_owned: list[str] = []
    notes: list[str] = []

    def need_account() -> int:
        return 100 + account_lv * 50

    def buy_cbt() -> None:
        nonlocal gold
        for node in cbt:
            nid = node["id"]
            if nid in cbt_owned:
                continue
            req = node.get("requires") or ""
            if req and req not in cbt_owned:
                continue
            if gold >= int(node["gold"]) and rep >= int(node["rep"]):
                gold -= int(node["gold"])
                cbt_owned.append(nid)
                notes.append(f"buy CBT {nid} gold={gold}")
                return

    def maybe_shop() -> None:
        nonlocal scrap, lunch
        if scrap >= 5 and lunch == 0:
            scrap -= 5
            lunch = 1

    for map_id in ORDER:
        pack = encounters[map_id][density]
        mul = hp_mul(diff)
        street_hp = sum(int(round(e["hp"] * mul)) for e in pack)
        act = story["acts"][map_id]
        mini = int(round(int(act.get("miniboss", {}).get("hp", 100)) * mul))
        boss = act.get("boss", {})
        if boss.get("kind") == "family_plan":
            boss_hp = int(round(720 * mul))
        elif boss.get("kind") == "mayor_raven":
            boss_hp = int(round(240 * mul))
        else:
            boss_hp = int(round(int(boss.get("hp", 160)) * mul))
        total_hp = street_hp + mini + boss_hp
        avg_dmg = (JAB + HEAVY_OUT) * 0.5
        hits_out = max(1, int(total_hp / avg_dmg))
        land = 1.05 if diff == "finals" else (0.55 if diff == "open_house" else 0.72)
        # One incoming light every ~4 swings if you are average. Heavies are rare.
        incoming = hits_out * 0.22 * land * LIGHT_IN + hits_out * 0.04 * land * HEAVY_IN
        # Survive hours drip chip instead of a full brawl trade.
        if act.get("survive"):
            incoming *= 0.72
        hp -= incoming
        map_deaths = 0
        while hp <= 0 and lives > 0:
            lives -= 1
            deaths += 1
            map_deaths += 1
            hp = SON_HP * 0.4
        if lives <= 0:
            notes.append(f"WIPE on {map_id} after {deaths} deaths")
            lives = LIVES
            hp = SON_HP
            deaths += 1
            gold = max(0, gold - 4)
        xp += 18 + len(pack) * 8 + (14 if act.get("survive") else 0)
        scrap += 6 + len(pack) * 2
        gold += CLEAR_GOLD + GATE_GOLD + scrap // 5
        account_xp += 24 + (8 if map_deaths == 0 else 4)
        while account_xp >= need_account():
            account_xp -= need_account()
            account_lv += 1
            gold += 8
        while levels < len(XP_GATES) and xp >= XP_GATES[levels]:
            levels += 1
            cards_taken += 1
        if map_id in towers["maps"]:
            towers_ok += 1
            if lunch:
                lunch = 0
                gold += 0
        if map_id in secrets:
            secrets_ok += 1
            sk = secrets[map_id].get("kind")
            if sk == "lunch":
                lunch = 1
            elif sk == "gems":
                gems += int(secrets[map_id].get("gems", 1))
            elif sk == "parts":
                parts_have[secrets[map_id]["item"]] = parts_have.get(secrets[map_id]["item"], 0) + int(secrets[map_id].get("n", 1))
        maybe_shop()
        if map_id in ("dock_street", "fire_escapes", "neon_exchange", "city_hall", "invoice_pier"):
            buy_cbt()
            rep += 1
        if map_id in ("intake_lot", "group_circle", "waiting_room", "sleet_hour", "ledger_dive"):
            gold += 6
        # cheap award drip
        gold += 8 if map_id == "dock_street" else 0
        hp = min(SON_HP + (12 if "thick_skin" in cbt_owned else 0) + (8 if "iron_gut" in cbt_owned else 0), hp + 20)

    # leftover gold vs remaining tree
    unbought = [n["id"] for n in cbt if n["id"] not in cbt_owned]
    dojo_cost = sum(int(d["gold"][0]) for d in dojo)
    research_cost = sum(int(r["gold"]) for r in research)
    award_gold = sum(int(a.get("gold", 0)) for a in awards)
    weapon_ids = list(weapons.keys())
    shop_items = [k for k in shop if k != "catalogs"]

    return {
        "diff": diff,
        "density": density,
        "deaths": deaths,
        "gold_end": gold,
        "gems_end": gems,
        "rep_end": rep,
        "scrap_end": scrap,
        "xp": xp,
        "card_picks": cards_taken,
        "account_lv": account_lv,
        "cbt_owned": len(cbt_owned),
        "cbt_left": unbought,
        "towers": towers_ok,
        "secrets": secrets_ok,
        "parts": parts_have,
        "notes": notes[-8:],
        "catalog": {
            "weapons": weapon_ids,
            "shop": shop_items,
            "cards": len(cards),
            "cbt": len(cbt),
            "dojo": len(dojo),
            "research": len(research),
            "gear": len(gear),
            "awards": len(awards),
            "buildings": len(buildings),
            "parts": list(parts.keys()),
            "dojo_first_rank_gold": dojo_cost,
            "research_gold": research_cost,
            "award_gold_pool": award_gold,
            "milestones_daily": len(milestones["daily"]),
        },
    }


def main() -> None:
    reports = [
        loop("night_class", "solo"),
        loop("finals", "solo"),
        loop("night_class", "coop"),
        loop("finals", "coop"),
    ]
    print("=== HnT balance sim ===")
    for r in reports:
        print(
            f"{r['diff']:12} {r['density']:4}  deaths={r['deaths']:2}  gold={r['gold_end']:4}  "
            f"rep={r['rep_end']}  xp={r['xp']}  cards={r['card_picks']}  cbt={r['cbt_owned']}/{r['catalog']['cbt']}  "
            f"acc={r['account_lv']}  towers={r['towers']} secrets={r['secrets']}"
        )
        if r["cbt_left"]:
            print("  leftover CBT:", ", ".join(r["cbt_left"]))
        if r["notes"]:
            print("  notes:", " | ".join(r["notes"]))
    cat = reports[0]["catalog"]
    print("catalog weapons", cat["weapons"])
    print("catalog shop", cat["shop"])
    print("parts", list(parts.keys()), "dojo first-ranks", cat["dojo_first_rank_gold"], "research", cat["research_gold"], "awards pool", cat["award_gold_pool"])
    nc = reports[0]
    fin = reports[1]
    print("--- verdict ---")
    if 0 <= nc["deaths"] <= 4:
        print("Night Class solo: a few deaths across 14 acts. Dock+Lot gold covers a CBT root (40g) after one clear + Intake Form.")
    else:
        print(f"Night Class solo: deaths={nc['deaths']}. Still two loops; menu upgrades are gold-gated not death-gated.")
    if fin["deaths"] > nc["deaths"]:
        print(f"Finals kills more ({fin['deaths']} vs {nc['deaths']}). Two loops stand. Do not thicken 3/6.")
    print("Open House stays assist (HP 0.75, telegraph 1.45). Not a third campaign.")
    out = ROOT / "tools" / "balance_sim_out.json"
    out.write_text(json.dumps(reports, indent=2))
    print("wrote", out)


if __name__ == "__main__":
    main()
