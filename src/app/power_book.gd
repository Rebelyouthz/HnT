class_name PowerBook
extends Object

## Night Class power checks. Open House skips. One real buy per gated map.

const PATH := "res://data/power_gates.json"


static func enforced() -> bool:
	return App.difficulty != "open_house"


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
	if shop != "" and not FamilyProfile.is_built(shop):
		return {
			"kind": "building",
			"id": shop,
			"shop_id": shop,
			"shop_name": shop_name,
			"node": "",
			"when": gate_when,
			"line": "LOCKED · %s" % shop_name
		}
	if _met(kind, id):
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


static func _met(kind: String, id: String) -> bool:
	match kind:
		"cbt":
			return FamilyProfile.has_cbt(id)
		"dojo":
			return FamilyProfile.dojo_learned(id)
		"gear":
			return FamilyProfile.owns_gear(id)
		"research":
			return FamilyProfile.has_research(id)
		"craft":
			return FamilyProfile.has_craft(id)
		"building":
			return FamilyProfile.is_built(id)
		"weapon":
			return FamilyProfile.has_research(id) or FamilyProfile.has_craft(id)
		_:
			return true


static func line(info: Dictionary) -> String:
	if info.is_empty():
		return ""
	return str(info.get("line", "LOCKED"))


static func boss_x(map_id: String) -> float:
	var act := StoryBook.act(map_id)
	var boss: Variant = act.get("boss", {})
	if typeof(boss) != TYPE_DICTIONARY:
		return 0.0
	return float((boss as Dictionary).get("x", 0.0))
