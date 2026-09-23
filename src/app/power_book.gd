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
