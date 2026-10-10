class_name SurvStarter
extends RefCounted

## STARTER WEAPONS for the coping hour (Jotunnslayer style): pick the
## weapon you walk in with. Each one is yours for good: it LEVELS with
## S-COINS (+8% damage a level), takes up to two MODS, and its RARITY rises
## by MERGING copies (3 copies -> next rarity, +15% damage and more each
## step, +1 projectile at epic). Copies drop from boss chests and gear boxes.
## Locked starters open with survivor challenges.

const MAX_LV := 10
const RARITY := ["common", "uncommon", "rare", "epic", "legendary"]
const MERGE_COPIES := 3
## Which abilities can be starters, and what opens them ("" = from the start).
const LIST := {
	"invoice_toss": "", "coffee": "", "stapler": "", "nail_driver": "",
	"clipboards": "ch_kills_500", "name_badge": "ch_survive_5", "shredder": "ch_evolve_1",
	"fax_beam": "ch_level_20", "rubber_stamp": "ch_boss_1", "paperweight": "ch_nohit_3",
}
const MODS := {
	"heavy": {"title": "HEAVY STOCK", "line": "+25% damage.", "price": 60},
	"rapid": {"title": "RAPID FIRE", "line": "-20% cooldown.", "price": 70},
	"wide": {"title": "WIDE SPREAD", "line": "+30% area.", "price": 60},
	"twin": {"title": "TWIN SHOT", "line": "+1 projectile.", "price": 120},
	"leech": {"title": "LEECH", "line": "1 HP back every 25 hits.", "price": 80},
	"crit": {"title": "HAIR TRIGGER", "line": "+10% crit chance.", "price": 70},
}
const MOD_SLOTS := 2


static func _data() -> Dictionary:
	var d: Variant = FamilyProfile.data.get("surv_start", {})
	if not (d is Dictionary):
		d = {}
	if not (d as Dictionary).has("w"):
		(d as Dictionary)["w"] = {}
	FamilyProfile.data["surv_start"] = d
	return d


static func picked() -> String:
	var p := str(_data().get("pick", ""))
	return p if unlocked(p) else ""


static func pick(id: String) -> void:
	if unlocked(id):
		_data()["pick"] = id
		FamilyProfile.save()


static func unlocked(id: String) -> bool:
	if not LIST.has(id):
		return false
	var need := str(LIST[id])
	return need == "" or SurvChallenges.done(need)


static func w(id: String) -> Dictionary:
	var all: Dictionary = _data()["w"]
	if not all.has(id):
		all[id] = {"lv": 1, "rar": 0, "copies": 0, "mods": []}
	return all[id]


static func level(id: String) -> int:
	return int(w(id).get("lv", 1))


static func rarity(id: String) -> String:
	return RARITY[clampi(int(w(id).get("rar", 0)), 0, 4)]


static func lv_price(id: String) -> int:
	return 25 + level(id) * 20


static func level_up(id: String) -> bool:
	var p := lv_price(id)
	if level(id) >= MAX_LV or int(FamilyProfile.data.get("tokens", 0)) < p:
		return false
	FamilyProfile.data["tokens"] = int(FamilyProfile.data["tokens"]) - p
	w(id)["lv"] = level(id) + 1
	FamilyProfile.save()
	return true


static func copies(id: String) -> int:
	return int(w(id).get("copies", 0))


static func add_copy(id: String) -> void:
	if LIST.has(id):
		w(id)["copies"] = copies(id) + 1
		FamilyProfile.save()


static func can_merge(id: String) -> bool:
	return copies(id) >= MERGE_COPIES and int(w(id).get("rar", 0)) < 4


static func merge(id: String) -> bool:
	if not can_merge(id):
		return false
	w(id)["copies"] = copies(id) - MERGE_COPIES
	w(id)["rar"] = int(w(id).get("rar", 0)) + 1
	FamilyProfile.save()
	return true


static func mods(id: String) -> Array:
	return w(id).get("mods", [])


static func buy_mod(id: String, m: String) -> bool:
	var have := mods(id)
	if have.has(m) or have.size() >= MOD_SLOTS or not MODS.has(m):
		return false
	var p := int(MODS[m]["price"])
	if int(FamilyProfile.data.get("tokens", 0)) < p:
		return false
	FamilyProfile.data["tokens"] = int(FamilyProfile.data["tokens"]) - p
	have.append(m)
	w(id)["mods"] = have
	FamilyProfile.save()
	return true


static func drop_mod(id: String, m: String) -> void:
	var have := mods(id)
	have.erase(m)
	w(id)["mods"] = have
	FamilyProfile.save()


# --- in the run ------------------------------------------------------------

static func dmg_mul(id: String) -> float:
	if id != picked():
		return 1.0
	var r := int(w(id).get("rar", 0))
	return (1.0 + 0.08 * float(level(id) - 1)) * (1.0 + 0.15 * float(r)) * (1.25 if mods(id).has("heavy") else 1.0)


static func cd_mul(id: String) -> float:
	return 0.8 if id == picked() and mods(id).has("rapid") else 1.0


static func area_mul(id: String) -> float:
	return 1.3 if id == picked() and mods(id).has("wide") else 1.0


static func proj_bonus(id: String) -> int:
	if id != picked():
		return 0
	return (1 if mods(id).has("twin") else 0) + (1 if int(w(id).get("rar", 0)) >= 3 else 0)


static func crit_bonus(id: String) -> float:
	return 0.1 if id == picked() and mods(id).has("crit") else 0.0


## What the starter reads like in one line.
static func line(id: String) -> String:
	var bits: Array[String] = ["LV %d" % level(id), Rarity.label(rarity(id))]
	for m in mods(id):
		bits.append(str(MODS[m]["title"]))
	return "  ·  ".join(bits)
