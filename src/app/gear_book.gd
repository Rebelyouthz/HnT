class_name GearBook
extends Object

const PATH := "res://data/gear.json"
static var _cache: Dictionary = {}


static func all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
	return _cache


static func items() -> Array:
	var v: Variant = all().get("items", [])
	return v if typeof(v) == TYPE_ARRAY else []


static func item(id: String) -> Dictionary:
	for row in items():
		if typeof(row) == TYPE_DICTIONARY and str((row as Dictionary).get("id", "")) == id:
			return row
	return {}


static func for_slot(slot: String, role: String) -> Array:
	var out: Array = []
	for row in items():
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = row
		if str(d.get("slot", "")) != slot:
			continue
		var who := str(d.get("role", "any"))
		if who != "any" and who != role:
			continue
		out.append(d)
	return out
