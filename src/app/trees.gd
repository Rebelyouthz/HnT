class_name Trees
extends RefCounted

## Three skill trees, one per way of playing:
##   brawl     the story streets (data/cbt.json, gold + rep)
##   survivor  the coping hours (data/tree_survivor.json, TOKENS)
##   parkour   tricks and traversal (data/tree_parkour.json, FLOW)
## TOKENS are earned in survivor hours (kills, time, the boss); FLOW from
## every trick, perfect trick, wall kick and tower climb.

const MODES := ["brawl", "survivor", "parkour"]
const FILES := {"brawl": "res://data/cbt.json", "survivor": "res://data/tree_survivor.json", "parkour": "res://data/tree_parkour.json"}
const KEYS := {"brawl": "cbt", "survivor": "tree_survivor", "parkour": "tree_parkour"}
const CUR := {"brawl": "gold", "survivor": "tokens", "parkour": "flow"}
const TRUNKS := {"brawl": ["BODY", "STREET", "SHOW"], "survivor": ["ARSENAL", "INSTINCT", "FORTUNE"], "parkour": ["FLOW", "AIR", "IMPACT"]}
const TITLES := {"brawl": "BRAWL", "survivor": "SURVIVOR", "parkour": "PARKOUR"}

static var _cache: Dictionary = {}


static func nodes(mode: String) -> Array:
	if _cache.has(mode):
		return _cache[mode]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILES[mode]))
	_cache[mode] = parsed if parsed is Array else []
	return _cache[mode]


static func node(mode: String, id: String) -> Dictionary:
	for r: Dictionary in nodes(mode):
		if str(r.get("id", "")) == id:
			return r
	return {}


static func owned(mode: String, id: String) -> bool:
	if mode == "brawl":
		return FamilyProfile.has_cbt(id)
	return (FamilyProfile.data.get(KEYS[mode], []) as Array).has(id)


## Survivor and parkour node ids are unique across both trees.
static func has(id: String) -> bool:
	return owned("survivor", id) or owned("parkour", id)


static func balance(mode: String) -> int:
	return int(FamilyProfile.data.get(CUR[mode], 0))


static func cur_label(mode: String) -> String:
	return "S-COINS" if mode == "survivor" else str(CUR[mode]).to_upper()


static func count(mode: String) -> Vector2i:
	var n := 0
	for r: Dictionary in nodes(mode):
		if owned(mode, str(r["id"])):
			n += 1
	return Vector2i(n, nodes(mode).size())


static func state(mode: String, r: Dictionary) -> String:
	var id := str(r.get("id", ""))
	if owned(mode, id):
		return "owned"
	var req := str(r.get("requires", ""))
	if req != "" and not owned(mode, req):
		return "locked"
	if mode == "brawl":
		if int(FamilyProfile.data["gold"]) >= int(r["gold"]) and int(FamilyProfile.data["rep"]) >= int(r["rep"]) and int(FamilyProfile.data["gems"]) >= int(r.get("gems", 0)):
			return "can"
		return "poor"
	return "can" if balance(mode) >= int(r.get("gold", 0)) else "poor"


static func try_buy(mode: String, id: String) -> bool:
	if mode == "brawl":
		return FamilyProfile.try_cbt(id)
	var r := node(mode, id)
	if r.is_empty() or state(mode, r) != "can":
		return false
	FamilyProfile.data[CUR[mode]] = balance(mode) - int(r.get("gold", 0))
	var a: Array = FamilyProfile.data.get(KEYS[mode], [])
	a.append(id)
	FamilyProfile.data[KEYS[mode]] = a
	FamilyProfile.save()
	return true


static func add_tokens(n: int) -> void:
	if n <= 0:
		return
	if has("f_tokens"):
		n = int(round(float(n) * 1.25))
	n = int(round(float(n) * Meta.token_mul() * (1.4 if Artifacts.has("no_lunch") else 1.0)))
	FamilyProfile.data["tokens"] = int(FamilyProfile.data.get("tokens", 0)) + n
	FamilyProfile.data["tokens_total"] = int(FamilyProfile.data.get("tokens_total", 0)) + n


static func add_flow(n: int) -> void:
	if n <= 0:
		return
	FamilyProfile.data["flow"] = int(FamilyProfile.data.get("flow", 0)) + n
	FamilyProfile.data["flow_total"] = int(FamilyProfile.data.get("flow_total", 0)) + n



## Refund a whole tree: every node back for what it cost (rep too for BRAWL).
static func refund(mode: String) -> int:
	var back := 0
	var rep_back := 0
	var key := str(KEYS[mode])
	var owned_ids: Array = (FamilyProfile.data.get(key, []) as Array).duplicate()
	for id in owned_ids:
		var r := node(mode, str(id))
		back += int(r.get("gold", 0))
		rep_back += int(r.get("rep", 0))
	if owned_ids.is_empty():
		return 0
	FamilyProfile.data[key] = []
	FamilyProfile.data[CUR[mode]] = balance(mode) + back
	if mode == "brawl":
		FamilyProfile.data["rep"] = int(FamilyProfile.data.get("rep", 0)) + rep_back
	FamilyProfile.data["respecs"] = int(FamilyProfile.data.get("respecs", 0)) + 1
	FamilyProfile.save()
	return back
