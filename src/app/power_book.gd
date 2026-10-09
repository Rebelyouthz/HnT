class_name PowerBook
extends Object

## Night Class power checks. Open House skips. One real buy per gated map.
## Autoload names are not in scope for Object class_name under --script.

const PATH := "res://data/power_gates.json"


static func _boot(node_name: String) -> Node:
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	var tree := loop as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


static func enforced() -> bool:
	var app := _boot("App")
	if app == null:
		return true
	return str(app.get("difficulty")) != "open_house"


static func table() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


static func spec(map_id: String) -> Dictionary:
	var row: Variant = table().get(map_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		return {}
	return row as Dictionary


static func lock(map_id: String, when: String = "enter") -> Dictionary:
	if map_id == "" or not enforced():
		return {}
	var row := spec(map_id)
	if row.is_empty():
		return {}
	var gate_when := str(row.get("when", "enter"))
	if when == "enter" and gate_when == "boss":
		return {}
	if when == "boss" and gate_when != "boss" and gate_when != "both":
		return {}
	var need: Variant = row.get("need", {})
	if typeof(need) != TYPE_DICTIONARY:
		return {}
	return _lock_need(need as Dictionary, gate_when)


static func _lock_need(need: Dictionary, gate_when: String) -> Dictionary:
	var shop := str(need.get("shop", ""))
	var shop_name := str(need.get("shop_name", shop.replace("_", " ").to_upper()))
	var node := str(need.get("node", ""))
	var kind := str(need.get("kind", ""))
	var id := str(need.get("id", ""))
	var fp := _boot("FamilyProfile")
	if fp == null:
		return {}
	if shop != "" and not bool(fp.call("is_built", shop)):
		return {
			"kind": "building",
			"id": shop,
			"shop_id": shop,
			"shop_name": shop_name,
			"node": "",
			"when": gate_when,
			"line": "LOCKED · %s" % shop_name
		}
	if _met(fp, kind, id):
		return {}
	var line := "LOCKED · %s" % shop_name
	if node != "":
		line = "LOCKED · %s · %s" % [node, shop_name]
	return {
		"kind": kind,
		"id": id,
		"shop_id": shop,
		"shop_name": shop_name,
		"node": node,
		"when": gate_when,
		"line": line
	}


static func _met(fp: Node, kind: String, id: String) -> bool:
	match kind:
		"cbt":
			return bool(fp.call("has_cbt", id))
		"dojo":
			return bool(fp.call("dojo_learned", id))
		"gear":
			return bool(fp.call("owns_gear", id))
		"research":
			return bool(fp.call("has_research", id))
		"craft":
			return bool(fp.call("has_craft", id))
		"building":
			return bool(fp.call("is_built", id))
		"weapon":
			return bool(fp.call("has_research", id)) or bool(fp.call("has_craft", id))
		_:
			return true


static func line(info: Dictionary) -> String:
	if info.is_empty():
		return ""
	return str(info.get("line", "LOCKED"))


static func boss_x(map_id: String) -> float:
	var path := "res://data/story.json"
	if not FileAccess.file_exists(path):
		return 0.0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0.0
	var acts: Variant = (parsed as Dictionary).get("acts", {})
	if typeof(acts) != TYPE_DICTIONARY:
		return 0.0
	var row: Variant = (acts as Dictionary).get(map_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		return 0.0
	var boss: Variant = (row as Dictionary).get("boss", {})
	if typeof(boss) != TYPE_DICTIONARY:
		return 0.0
	return float((boss as Dictionary).get("x", 0.0))


## Shops the next story maps still need built: the one the family is on
## and the one right after it (its gate shows on the results sheet before
## the map is filed). Those rooms may go up out of the planned order, so
## the story never waits on nights.
static func story_shops() -> PackedStringArray:
	var out: PackedStringArray = []
	var fp := _boot("FamilyProfile")
	var app := _boot("App")
	if fp == null or app == null or not enforced():
		return out
	var order: Array = app.get("ORDER")
	var i := order.find(str(fp.call("next_run_map")))
	if i < 0:
		return out
	for k in range(i, mini(i + 2, order.size())):
		var need: Variant = spec(str(order[k])).get("need", {})
		if typeof(need) != TYPE_DICTIONARY:
			continue
		var shop := str((need as Dictionary).get("shop", ""))
		if shop != "" and not bool(fp.call("is_built", shop)):
			out.append(shop)
	return out


static func _row_of(file: String, id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(file)) if FileAccess.file_exists(file) else null
	var rows: Array = []
	if typeof(parsed) == TYPE_ARRAY:
		rows = parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		rows = (parsed as Dictionary).get("items", [])
	for r in rows:
		if typeof(r) == TYPE_DICTIONARY and str((r as Dictionary).get("id", "")) == id:
			return r
	return {}


## Every buy still missing for map_id's gate, in order:
## [{what, id, name, gold, rep, parts}]. Empty when the way is open.
static func path(map_id: String) -> Array:
	var out: Array = []
	var row := spec(map_id)
	var need_v: Variant = row.get("need", {})
	if not enforced() or typeof(need_v) != TYPE_DICTIONARY:
		return out
	var need := need_v as Dictionary
	var fp := _boot("FamilyProfile")
	if fp == null:
		return out
	var shop := str(need.get("shop", ""))
	var shop_name := str(need.get("shop_name", shop.replace("_", " ").to_upper()))
	if shop != "" and not bool(fp.call("is_built", shop)):
		out.append({"what": "BUILD", "id": shop, "name": shop_name, "gold": int(fp.call("build_cost", shop)), "rep": 0, "parts": {}})
	var kind := str(need.get("kind", ""))
	var id := str(need.get("id", ""))
	if _met(fp, kind, id):
		return out
	var step := {"what": "LEARN", "id": id, "name": str(need.get("node", id.to_upper())), "gold": 0, "rep": 0, "parts": {}}
	match kind:
		"cbt":
			var r := _row_of("res://data/cbt.json", id)
			step["gold"] = int(r.get("gold", 0))
			step["rep"] = int(r.get("rep", 0))
		"dojo":
			var costs: Variant = _row_of("res://data/dojo.json", id).get("gold", [20])
			step["gold"] = int((costs as Array)[0]) if typeof(costs) == TYPE_ARRAY and not (costs as Array).is_empty() else 20
		"gear":
			var r := _row_of("res://data/gear.json", id)
			step["what"] = "BUY"
			step["gold"] = int(r.get("gold", 0))
			step["rep"] = int(r.get("rep", 0))
		"research":
			var r := _row_of("res://data/research.json", id)
			step["what"] = "RESEARCH"
			step["gold"] = int(r.get("gold", 0))
			step["parts"] = r.get("parts", {})
		"craft":
			var r := _row_of("res://data/crafts.json", id)
			step["what"] = "CRAFT"
			step["gold"] = int(r.get("gold", 0))
			step["parts"] = r.get("parts", {})
	out.append(step)
	return out


## "BUILD MARTIAL ARTS SCHOOL 21 G  ▸  LEARN UPPERCUT 20 G"
static func path_line(map_id: String) -> String:
	var bits: PackedStringArray = []
	for s in path(map_id):
		var d := s as Dictionary
		bits.append("%s %s  %d G" % [str(d["what"]), str(d["name"]), int(d["gold"])])
	return "  ▸  ".join(bits)


## First time a gate turns the family back: the clinic covers what is short
## (gold, rep, parts) so the camp buy is always within reach that night.
static func fund(map_id: String) -> int:
	var fp := _boot("FamilyProfile")
	var steps := path(map_id)
	if fp == null or steps.is_empty():
		return 0
	var data: Dictionary = fp.get("data")
	var key := "gate_fund_" + map_id
	if bool(data.get(key, false)):
		return 0
	data[key] = true
	var gold := 0
	var rep := 0
	var parts := {}
	for s in steps:
		var d := s as Dictionary
		gold += int(d["gold"])
		rep = maxi(rep, int(d["rep"]))
		var p: Dictionary = d["parts"]
		for k in p.keys():
			parts[k] = int(parts.get(k, 0)) + int(p[k])
	var short := maxi(0, gold - int(data.get("gold", 0)))
	data["gold"] = int(data.get("gold", 0)) + short
	data["rep"] = maxi(int(data.get("rep", 0)), rep)
	for k in parts.keys():
		var have := int(fp.call("part_n", str(k)))
		if have < int(parts[k]):
			fp.call("add_parts", str(k), int(parts[k]) - have)
	fp.call("save")
	return short
