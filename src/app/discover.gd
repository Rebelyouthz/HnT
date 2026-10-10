class_name Discover
extends RefCounted

## The CODEX's memory: the first time you meet a thug, a boss, a weapon, a
## survivor ability, a piece of gear, a gun part or a place, it gets an
## entry. A toast says so, CODEX shows its red dot, and the entry waits in
## the codex with a reward to CLAIM (gold, or gems for bosses and secrets).
## Every 10 entries filed also pays a gem bonus.
##
##   Discover.see("enemy", "Bag Snatch")
##   Discover.claim(cat, id) -> {"gold": n, "gems": n}

const CATS := ["enemy", "boss", "weapon", "ability", "gear", "part", "place"]
const CAT_NAME := {
	"enemy": "THUGS", "boss": "BOSSES", "weapon": "WEAPONS", "ability": "ABILITIES",
	"gear": "GEAR", "part": "GUN PARTS", "place": "PLACES",
}
const REWARD := {
	"enemy": {"gold": 12}, "boss": {"gems": 2, "gold": 40}, "weapon": {"gold": 15},
	"ability": {"gold": 10}, "gear": {"gold": 10}, "part": {"gold": 10}, "place": {"gold": 20, "gems": 1},
}
const BOSSES := ["Shift Lead", "Collector Gant", "Clamp King", "Lot Hydra", "Mayor Raven", "Skinwalker"]
const PLACES := {
	"tutorial_alley": "TUTORIAL ALLEY", "dock_street": "DOCK STREET", "intake_lot": "THE INTAKE LOT",
	"fire_escapes": "FIRE ESCAPES", "waiting_room": "THE WAITING ROOM", "processing_floor": "THE PROCESSING FLOOR",
	"invoice_pier": "INVOICE PIER", "group_circle": "GROUP CIRCLE", "copay_orchard": "COPAY ORCHARD",
	"sleet_hour": "SLEET HOUR", "raven_grid": "RAVEN GRID", "rail_bridge": "RAIL BRIDGE",
	"neon_exchange": "NEON EXCHANGE", "ledger_dive": "LEDGER DIVE", "city_hall": "CITY HALL", "camp": "THE HIDEOUT",
	"dojo_practice": "DOJO",
}
const WEAPONS := ["knife", "pipe", "board", "chain", "crowbar", "baseball_bat", "machete", "sledgehammer", "clipboard", "stapler", "invoice_star", "pistol", "revolver", "nailgun", "smg", "shotgun", "flare_gun", "ray"]

static var _kits: Array = []
static var _abilities: Array = []


## Everything that can be filed in a category, in display order: [id, title].
static func catalog(cat: String) -> Array:
	var out: Array = []
	match cat:
		"enemy":
			if _kits.is_empty():
				var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/kits.json"))
				if d is Dictionary:
					_kits = (d as Dictionary).keys()
			for k in _kits:
				if not (str(k) in BOSSES):
					out.append([str(k), str(k).to_upper()])
		"boss":
			for b in BOSSES:
				out.append([b, b.to_upper()])
		"weapon":
			for w in WEAPONS:
				out.append([w, str(WeaponBook.spec(w).get("title", w)).to_upper()])
		"ability":
			if _abilities.is_empty():
				var s: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
				if s is Dictionary:
					_abilities = (s as Dictionary).get("abilities", [])
			for a: Dictionary in _abilities:
				out.append([str(a["id"]), str(a.get("name", a["id"]))])
		"gear":
			for g in SurvGear.LIST:
				out.append([str(g), str(SurvGear.LIST[g]["name"])])
		"part":
			for p in Attach.LIST:
				out.append([str(p), str(Attach.LIST[p]["title"])])
		"place":
			for k in PLACES:
				out.append([str(k), str(PLACES[k])])
	return out


static func _seen() -> Dictionary:
	var d: Variant = FamilyProfile.data.get("codex_seen", {})
	if not (d is Dictionary):
		d = {}
		FamilyProfile.data["codex_seen"] = d
	return d


static func key(cat: String, id: String) -> String:
	return cat + ":" + id


static func seen(cat: String, id: String) -> bool:
	return _seen().has(key(cat, id))


## 0 = never met, 1 = filed and its reward waits, 2 = claimed.
static func state(cat: String, id: String) -> int:
	return int(_seen().get(key(cat, id), 0))


static func see(cat: String, id: String, title := "") -> void:
	if id == "" or not CATS.has(cat) or seen(cat, id):
		return
	_seen()[key(cat, id)] = 1
	FamilyProfile.flag_unseen("codex")
	FamilyProfile.save()
	var t := title if title != "" else id.to_upper()
	Juice.toast("codex", "CODEX  ·  NEW ENTRY", "%s  ·  %s" % [CAT_NAME[cat], t], icon_for(cat, id))


static func unclaimed() -> int:
	var n := 0
	for k in _seen():
		if int(_seen()[k]) == 1:
			n += 1
	return n


static func filed() -> int:
	return _seen().size()


static func total() -> int:
	var n := 0
	for c in CATS:
		n += catalog(c).size()
	return n


## Pays the entry's reward (and a milestone bonus every 10). Returns what
## was paid, empty when there was nothing to claim.
static func claim(cat: String, id: String) -> Dictionary:
	if state(cat, id) != 1:
		return {}
	_seen()[key(cat, id)] = 2
	var pay: Dictionary = (REWARD.get(cat, {"gold": 10}) as Dictionary).duplicate()
	var claimed := 0
	for k in _seen():
		if int(_seen()[k]) == 2:
			claimed += 1
	if claimed % 10 == 0:
		pay["gems"] = int(pay.get("gems", 0)) + 3
		pay["milestone"] = claimed
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) + int(pay.get("gold", 0))
	FamilyProfile.data["gems"] = int(FamilyProfile.data.get("gems", 0)) + int(pay.get("gems", 0))
	if unclaimed() == 0:
		FamilyProfile.mark_seen("codex")
	FamilyProfile.save()
	return pay


static func icon_for(cat: String, id: String) -> String:
	match cat:
		"enemy":
			return "card_revenge_policy"
		"boss":
			return "node_crown"
		"weapon":
			return "cur_knife" if not Arsenal.is_gun(id) else "cur_ammo"
		"ability":
			var r := ""
			for a: Dictionary in _abilities:
				if str(a.get("id", "")) == id:
					r = str(a.get("icon", ""))
			return r if r != "" else "bolt"
		"gear":
			return IconBook.for_gear(id)
		"part":
			return IconBook.for_part(id)
		"place":
			return "card_escape_clause"
	return "node_score"
