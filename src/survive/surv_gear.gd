class_name SurvGear
extends RefCounted

## SURVIVOR GEAR: what you wear into the coping hours. Four slots (cap,
## jacket, shoes, charm), every piece with a rarity (common -> legendary) and
## a level (1-5, S-COINS). Pieces drop from survivor runs (end of the hour,
## elite chests, the boss) or come out of a GEAR BOX bought with S-COINS.
## Their stats feed SurviveRun's multipliers.

const SLOTS := ["cap", "jacket", "shoes", "charm"]
const SLOT_NAME := {"cap": "CAP", "jacket": "JACKET", "shoes": "SHOES", "charm": "CHARM"}
const RARITY := ["common", "uncommon", "rare", "epic", "legendary"]
const STAT_NAME := {"dmg": "DAMAGE", "area": "AREA", "cd": "COOLDOWN", "speed": "SPEED", "hp": "MAX HP", "pickup": "MAGNET", "luck": "LUCK", "armor": "ARMOR", "crit": "CRIT", "regen": "REGEN", "xp": "XP", "proj": "AMOUNT"}
const LIST := {
	"night_cap": {"slot": "cap", "name": "NIGHT SHIFT CAP", "stats": {"dmg": 0.06, "xp": 0.05}},
	"hard_hat": {"slot": "cap", "name": "HARD HAT", "stats": {"armor": 0.04, "hp": 6}},
	"tinfoil_hat": {"slot": "cap", "name": "TINFOIL HAT", "stats": {"luck": 0.05, "crit": 0.03}},
	"headset": {"slot": "cap", "name": "CALL CENTRE HEADSET", "stats": {"cd": 0.04, "area": 0.04}},
	"rain_coat": {"slot": "jacket", "name": "RAIN COAT", "stats": {"armor": 0.05, "regen": 0.2}},
	"hi_vis": {"slot": "jacket", "name": "HI-VIS VEST", "stats": {"hp": 10, "pickup": 0.08}},
	"varsity": {"slot": "jacket", "name": "VARSITY JACKET", "stats": {"dmg": 0.07, "crit": 0.02}},
	"lab_coat": {"slot": "jacket", "name": "LAB COAT", "stats": {"area": 0.07, "xp": 0.06}},
	"office_blazer": {"slot": "jacket", "name": "OFFICE BLAZER", "stats": {"cd": 0.05, "proj": 0.25}},
	"crocs": {"slot": "shoes", "name": "HOSPITAL CROCS", "stats": {"speed": 0.06, "regen": 0.15}},
	"high_tops": {"slot": "shoes", "name": "HIGH TOPS", "stats": {"speed": 0.08, "dmg": 0.03}},
	"steel_toes": {"slot": "shoes", "name": "STEEL TOES", "stats": {"armor": 0.04, "dmg": 0.04}},
	"slippers": {"slot": "shoes", "name": "DAD SLIPPERS", "stats": {"pickup": 0.12, "luck": 0.03}},
	"rabbit_foot": {"slot": "charm", "name": "RABBIT FOOT", "stats": {"luck": 0.07, "crit": 0.03}},
	"parking_pass": {"slot": "charm", "name": "PARKING PASS", "stats": {"xp": 0.08, "pickup": 0.06}},
	"family_photo": {"slot": "charm", "name": "FAMILY PHOTO", "stats": {"hp": 8, "regen": 0.25}},
	"loyalty_card": {"slot": "charm", "name": "LOYALTY CARD", "stats": {"cd": 0.05, "luck": 0.03}},
	"brass_bell": {"slot": "charm", "name": "BRASS BELL", "stats": {"area": 0.05, "dmg": 0.04}},
}
const BOX_PRICE := 60
const MAX_LV := 5


static func inv() -> Array:
	var v: Variant = FamilyProfile.data.get("sgear", [])
	return v if v is Array else []


static func worn() -> Dictionary:
	var v: Variant = FamilyProfile.data.get("sgear_on", {})
	return v if v is Dictionary else {}


static func piece(i: int) -> Dictionary:
	var a := inv()
	return a[i] if i >= 0 and i < a.size() else {}


static func rarity_of(p: Dictionary) -> String:
	return RARITY[clampi(int(p.get("rar", 0)), 0, 4)]


## A piece's stat value: base x (1 + 0.5 per rarity step) x (1 + 0.12 per level).
static func value(p: Dictionary, key: String) -> float:
	var base := float((LIST.get(str(p.get("id", "")), {}).get("stats", {}) as Dictionary).get(key, 0.0))
	return base * (1.0 + 0.5 * float(p.get("rar", 0))) * (1.0 + 0.12 * float(int(p.get("lv", 1)) - 1))


## Sum of a stat over everything worn.
static func stat(key: String) -> float:
	var s := 0.0
	for slot in worn():
		s += value(piece(int(worn()[slot])), key)
	return s


static func roll(luck := 0.0) -> Dictionary:
	var ids := LIST.keys()
	var id := str(ids[randi() % ids.size()])
	var r := randf() - luck
	var rar := 4 if r < 0.02 else (3 if r < 0.08 else (2 if r < 0.22 else (1 if r < 0.5 else 0)))
	return {"id": id, "rar": rar, "lv": 1}


static func add(p: Dictionary) -> int:
	var a := inv()
	a.append(p)
	FamilyProfile.data["sgear"] = a
	# Empty slot: wear it at once.
	var slot := str(LIST[str(p["id"])]["slot"])
	var w := worn()
	if not w.has(slot):
		w[slot] = a.size() - 1
		FamilyProfile.data["sgear_on"] = w
	FamilyProfile.save()
	return a.size() - 1


static func drop(luck := 0.0) -> Dictionary:
	var p := roll(luck + (0.15 if Trees.has("f_gear") else 0.0))
	add(p)
	var r := rarity_of(p)
	Rarity.juice(r, str(LIST[str(p["id"])]["name"]))
	Juice.toast("reward", "GEAR  ·  " + Rarity.label(r), str(LIST[str(p["id"])]["name"]))
	return p


static func wear(i: int) -> void:
	var p := piece(i)
	if p.is_empty():
		return
	var w := worn()
	w[str(LIST[str(p["id"])]["slot"])] = i
	FamilyProfile.data["sgear_on"] = w
	FamilyProfile.save()


static func lv_price(p: Dictionary) -> int:
	return 25 * int(p.get("lv", 1)) * (1 + int(p.get("rar", 0)))


static func level_up(i: int) -> bool:
	var a := inv()
	if i < 0 or i >= a.size():
		return false
	var p: Dictionary = a[i]
	if int(p.get("lv", 1)) >= MAX_LV:
		return false
	var c := lv_price(p)
	if int(FamilyProfile.data.get("tokens", 0)) < c:
		return false
	FamilyProfile.data["tokens"] = int(FamilyProfile.data["tokens"]) - c
	p["lv"] = int(p.get("lv", 1)) + 1
	a[i] = p
	FamilyProfile.data["sgear"] = a
	FamilyProfile.save()
	return true


## Three of the same piece and rarity melt into one of the next rarity.
static func can_fuse(i: int) -> bool:
	var p := piece(i)
	if p.is_empty() or int(p.get("rar", 0)) >= 4:
		return false
	var n := 0
	for q: Dictionary in inv():
		if str(q.get("id")) == str(p.get("id")) and int(q.get("rar", 0)) == int(p.get("rar", 0)):
			n += 1
	return n >= 3


static func fuse(i: int) -> bool:
	if not can_fuse(i):
		return false
	var p := piece(i)
	var a := inv()
	var keep: Array = []
	var removed := 0
	for q: Dictionary in a:
		if removed < 3 and str(q.get("id")) == str(p.get("id")) and int(q.get("rar", 0)) == int(p.get("rar", 0)):
			removed += 1
			continue
		keep.append(q)
	keep.append({"id": p["id"], "rar": int(p["rar"]) + 1, "lv": 1})
	FamilyProfile.data["sgear"] = keep
	FamilyProfile.data["sgear_on"] = {}
	# Re-wear the best of each slot.
	for k in keep.size():
		var slot := str(LIST[str(keep[k]["id"])]["slot"])
		var w := worn()
		if not w.has(slot) or int(keep[k]["rar"]) > int(piece(int(w[slot])).get("rar", 0)):
			w[slot] = k
			FamilyProfile.data["sgear_on"] = w
	FamilyProfile.save()
	return true


static func buy_box() -> Dictionary:
	if int(FamilyProfile.data.get("tokens", 0)) < BOX_PRICE:
		return {}
	FamilyProfile.data["tokens"] = int(FamilyProfile.data["tokens"]) - BOX_PRICE
	return drop(0.05)


static func line(p: Dictionary) -> String:
	var bits: Array[String] = []
	for k in (LIST.get(str(p.get("id", "")), {}).get("stats", {}) as Dictionary):
		var v := value(p, str(k))
		bits.append(("+%d %s" % [int(round(v)), STAT_NAME[k]]) if k == "hp" else ("+%d%% %s" % [int(round(v * 100.0)), STAT_NAME[k]]))
	return "  ".join(bits)
