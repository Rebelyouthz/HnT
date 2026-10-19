class_name ForgeBook
extends Object

## THE FORGE (Ember, the hideout yard; data/forge.json).
##   SMELT: a spare copy of a gear piece melts into materials (iron, leather,
##   cloth, by slot, more for rarer copies; rare and up also give an EMBER
##   CORE). The last copy of a piece is never offered, so you can not melt
##   what you wear.
##   FORGE: gold + materials make a gear piece (with real stats, worn in the
##   LOCKER) or temper a weapon (found in the ARMORY, +1 level). Three hammer
##   strikes on the anvil decide the quality: a strong forging comes out one
##   rarity higher.
##   SALVAGE BENCH: once a night, a handful of free materials.

const PATH := "res://data/forge.json"
const MATS := ["iron_scrap", "leather_strip", "cloth_roll", "ember_core"]
const MAT_NAME := {"iron_scrap": "IRON", "leather_strip": "LEATHER", "cloth_roll": "CLOTH", "ember_core": "EMBER CORE"}
static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if v is Dictionary:
			_data = v
	return _data


static func is_open() -> bool:
	return StoryBook.has_crew("ember")


static func recipes() -> Array:
	return data().get("recipes", [])


static func recipe(id: String) -> Dictionary:
	for r in recipes():
		if str((r as Dictionary).get("id", "")) == id:
			return r
	return {}


static func title_of(r: Dictionary) -> String:
	if r.has("title"):
		return str(r["title"])
	if str(r.get("kind", "")) == "weapon":
		return "FORGED " + str(WeaponBook.spec(str(r["id"])).get("title", r["id"])).to_upper()
	return str(GearBook.item(str(r["id"])).get("title", r["id"])).to_upper()


static func icon_of(r: Dictionary) -> String:
	var id := str(r.get("id", ""))
	if str(r.get("kind", "")) == "weapon":
		# IconBook also looks in assets/sprites/held (the art the heroes hold).
		return id
	return IconBook.for_gear(id) if IconBook.has(IconBook.for_gear(id)) else "forge_anvil"


static func have(mat: String) -> int:
	return FamilyProfile.part_n(mat)


static func can_forge(r: Dictionary) -> String:
	if int(FamilyProfile.data.get("gold", 0)) < int(r.get("gold", 0)):
		return "NEED %d GOLD" % int(r.get("gold", 0))
	var m: Dictionary = r.get("mats", {})
	for k in m.keys():
		if have(str(k)) < int(m[k]):
			return "NEED %s" % str(MAT_NAME.get(k, k))
	if str(r.get("kind", "")) == "weapon" and Arsenal.found(str(r["id"])) and Arsenal.level(str(r["id"])) >= Arsenal.MAX_LV:
		return "MAX LEVEL"
	return ""


## Spend and make it. quality 0..3 (strong anvil strikes): 2+ raises a gear
## piece one rarity. Returns what came out ({title, icon, rarity, line}).
static func forge(id: String, quality: int) -> Dictionary:
	var r := recipe(id)
	if r.is_empty() or can_forge(r) != "":
		return {}
	FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(r.get("gold", 0))
	FamilyProfile.spend_parts(r.get("mats", {}))
	var out := {"title": title_of(r), "icon": icon_of(r), "quality": quality}
	if str(r.get("kind", "")) == "weapon":
		var had := Arsenal.found(id)
		Arsenal.mark_found(id)
		var lv: Dictionary = FamilyProfile.data.get("weapon_lv", {})
		var n := mini(Arsenal.MAX_LV, Arsenal.level(id) + (1 if had else 0) + (1 if quality >= 3 else 0))
		lv[id] = maxi(1, n)
		FamilyProfile.data["weapon_lv"] = lv
		out["rarity"] = Rarity.normalize(str(WeaponBook.spec(id).get("rarity", "common")))
		out["line"] = "IN THE ARMORY  ·  LEVEL %d" % Arsenal.level(id)
	else:
		var base := GearInv.base_tier(id)
		var t := base + (1 if quality >= 2 else 0)
		GearInv.add(id, t)
		FamilyProfile.flag_unseen("gear_" + id)
		out["rarity"] = Rarity.ORDER[clampi(t, 0, 4)]
		out["line"] = "WEAR IT IN THE LOCKER  ·  %s" % stat_line(id)
	FamilyProfile.data["forged"] = int(FamilyProfile.data.get("forged", 0)) + 1
	FamilyProfile.save()
	return out


static func stat_line(id: String) -> String:
	var st: Dictionary = GearBook.item(id).get("stats", {})
	var bits: PackedStringArray = []
	for k in ["hp", "dmg", "steam", "speed"]:
		var v := int(st.get(k, 0))
		if v != 0:
			bits.append("%s%d %s" % ["+" if v > 0 else "", v, k.to_upper()])
	return "  ".join(bits)


## Spare copies that can go in the furnace: [id, tier] pairs, one per id
## and tier, never the only copy of a piece.
static func smeltable() -> Array:
	var out: Array = []
	var inv: Variant = FamilyProfile.data.get("gear_inv", {})
	if not (inv is Dictionary):
		return out
	for id in (inv as Dictionary).keys():
		var c: Array = GearInv.counts(str(id))
		var total := 0
		for n in c:
			total += int(n)
		if total <= 1:
			continue
		for t in 5:
			if int(c[t]) > 0:
				out.append([str(id), t])
	return out


static func smelt_yield(id: String, t: int) -> Dictionary:
	var slot := str(GearBook.item(id).get("slot", "clothes"))
	var base: Dictionary = (data().get("smelt", {}) as Dictionary).get(slot, {"iron_scrap": 1})
	var out := {}
	for k in base.keys():
		out[k] = int(base[k]) * (1 + t)
	if t >= 2:
		out["ember_core"] = int(out.get("ember_core", 0)) + 1
	return out


static func smelt(id: String, t: int) -> Dictionary:
	var c: Array = GearInv.counts(id)
	var total := 0
	for n in c:
		total += int(n)
	if total <= 1 or int(c[t]) <= 0:
		return {}
	c[t] = int(c[t]) - 1
	(FamilyProfile.data["gear_inv"] as Dictionary)[id] = c
	var got := smelt_yield(id, t)
	for k in got.keys():
		FamilyProfile.add_parts(str(k), int(got[k]))
	FamilyProfile.data["smelted"] = int(FamilyProfile.data.get("smelted", 0)) + 1
	FamilyProfile.save()
	return got


## The salvage bench: once a night (until the next run), free materials.
static func salvage_ready() -> bool:
	return is_open() and int(FamilyProfile.data.get("salvage_run", -1)) != int(FamilyProfile.data.get("runs", 0))


static func salvage() -> Dictionary:
	if not salvage_ready():
		return {}
	var s: Dictionary = data().get("salvage", {})
	var got := {}
	for k in ["iron_scrap", "leather_strip", "cloth_roll"]:
		var rng: Array = s.get(k, [0, 1])
		var n := randi_range(int(rng[0]), int(rng[1]))
		if n > 0:
			got[k] = n
	if randf() < float(s.get("core_chance", 0.1)):
		got["ember_core"] = 1
	for k in got.keys():
		FamilyProfile.add_parts(str(k), int(got[k]))
	FamilyProfile.data["salvage_run"] = int(FamilyProfile.data.get("runs", 0))
	FamilyProfile.save()
	return got
