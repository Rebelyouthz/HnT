class_name BrutalBook
extends Object

## The BONE YARD moves: extreme finishers bought with FIGHT TOKENS on the
## reverse tree in the dojo (data/brutal.json), then drilled 3 times on the
## dummy before they work in the street. Done with a GRAB on a BROKEN thug
## (under 45% health): neutral, forward or back picks the move; supers
## need the FURY meter full and go off with LB + RB.

const PATH := "res://data/brutal.json"
const BROKEN := 0.45
static var _rows: Array = []


static func all() -> Array:
	if _rows.is_empty():
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if v is Array:
			_rows = v
	return _rows


static func row(id: String) -> Dictionary:
	for r in all():
		if str(r.get("id", "")) == id:
			return r
	return {}


static func _fp() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	return loop.root.get_node_or_null("FamilyProfile") if loop else null


static func owned(id: String) -> bool:
	var fp := _fp()
	return fp != null and (fp.data.get("brutal", []) as Array).has(id)


static func tokens() -> int:
	var fp := _fp()
	return int(fp.data.get("fight_tokens", 0)) if fp else 0


static func add_tokens(n: int, why: String) -> void:
	var fp := _fp()
	if fp == null or n <= 0:
		return
	fp.data["fight_tokens"] = tokens() + n
	fp.save()
	Juice.toast("reward", "+%d FIGHT TOKEN%s" % [n, "" if n == 1 else "S"], why)


## Why it can't be bought yet ("" = it can).
static func blocker(id: String) -> String:
	var r := row(id)
	if r.is_empty():
		return "UNKNOWN"
	if owned(id):
		return "OWNED"
	var needs: Array = r.get("needs", [])
	var any := needs.is_empty()
	for n in needs:
		if owned(str(n)):
			any = true
	if not any:
		return "UNLOCK %s FIRST" % str(row(str(needs[0])).get("title", needs[0]))
	var fp := _fp()
	if bool(r.get("big", false)) and fp and not bool(fp.data.get("boneyard_full", false)):
		return "CLEAR ALL THREE BONE YARD MAPS IN ONE LIFE"
	if tokens() < int(r.get("cost", 1)):
		return "NEED %d FIGHT TOKEN%s" % [int(r.get("cost", 1)), "" if int(r.get("cost", 1)) == 1 else "S"]
	return ""


static func unlock(id: String) -> bool:
	if blocker(id) != "":
		return false
	var fp := _fp()
	var r := row(id)
	fp.data["fight_tokens"] = tokens() - int(r.get("cost", 1))
	var own: Array = fp.data.get("brutal", [])
	own.append(id)
	fp.data["brutal"] = own
	if not rivals(id).is_empty():
		make_active(id)
	# Bought, not known: three clean reps on the dojo dummy first.
	var tr: Dictionary = fp.data.get("dojo_train", {})
	tr["b_" + id] = 0
	fp.data["dojo_train"] = tr
	fp.save()
	return true


## Owned and drilled (or on the dojo mat, where it is being drilled).
static func usable(id: String) -> bool:
	if not owned(id):
		return false
	var fp := _fp()
	return fp.call("dojo_trained", "b_" + id) or App.current_map == "dojo_practice"


static func dir_of(r: Dictionary) -> String:
	var inp := str(r.get("input", ""))
	if inp.contains("FORWARD"):
		return "F"
	if inp.contains("BACK"):
		return "B"
	return "N"


## The move this hero does for a grab in that direction, strongest first.
static func for_grab(role: String, dir: String, pickup: String) -> String:
	var best := ""
	var best_row := -1
	for r in all():
		if bool(r.get("big", false)) or str(r.get("hero", "")) != role:
			continue
		var id := str(r["id"])
		var weapon: Array = r.get("weapon", [])
		if not weapon.is_empty() and not weapon.has(pickup):
			continue
		if dir_of(r) != dir or not usable(id) or benched(id):
			continue
		# A weapon in hand picks its own move first.
		var score := int(r.get("row", 0)) + (100 if not weapon.is_empty() else 0)
		if score > best_row:
			best_row = score
			best = id
	return best


## Owned moves of the same hero on the same grab (weapon moves aside): only one
## can answer a grab, the rest sit on the bench until picked.
static func rivals(id: String) -> Array:
	var r := row(id)
	var out: Array = []
	if r.is_empty() or bool(r.get("big", false)):
		return out
	for o in all():
		var oid := str(o["id"])
		if oid == id or bool(o.get("big", false)) or not owned(oid):
			continue
		if str(o["hero"]) == str(r["hero"]) and dir_of(o) == dir_of(r) and o.has("weapon") == r.has("weapon"):
			out.append(oid)
	return out


static func benched(id: String) -> bool:
	var fp := _fp()
	return fp != null and (fp.data.get("brutal_off", []) as Array).has(id)


## Make this the move that answers its grab; its rivals go to the bench.
static func make_active(id: String) -> void:
	var fp := _fp()
	if fp == null:
		return
	var off: Array = fp.data.get("brutal_off", [])
	off.erase(id)
	for o in rivals(id):
		if not off.has(o):
			off.append(o)
	fp.data["brutal_off"] = off
	fp.save()


static func super_for(role: String, dir: String) -> String:
	var pick := ""
	for r in all():
		if bool(r.get("big", false)) and str(r.get("hero", "")) == role and usable(str(r["id"])):
			if pick == "" or (dir == "F" and str(r["id"]) == "flamingo_reaper"):
				pick = str(r["id"])
	return pick


static func broken(e: Node) -> bool:
	if e is TrainingDummy:
		return true
	var mx := maxi(1, int(e.get("max_hp")))
	return float(int(e.get("hp"))) / float(mx) <= BROKEN
