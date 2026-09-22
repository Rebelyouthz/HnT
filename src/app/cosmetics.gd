class_name Cosmetics
extends Object

const PATH := "res://data/cosmetics.json"
static var _cache: Dictionary = {}


static func all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
	return _cache


static func list_for(kind: String) -> Array:
	var row: Variant = all().get(kind, [])
	return row if typeof(row) == TYPE_ARRAY else []


static func item(kind: String, id: String) -> Dictionary:
	for row in list_for(kind):
		if typeof(row) == TYPE_DICTIONARY and str((row as Dictionary).get("id", "")) == id:
			return row
	return {}


static func tint(kind: String, id: String) -> Color:
	var spec := item(kind, id)
	var t: Variant = spec.get("tint", [0.4, 0.4, 0.45])
	if typeof(t) == TYPE_ARRAY and (t as Array).size() >= 3:
		return Color(float(t[0]), float(t[1]), float(t[2]))
	return Palette.PANEL


static func need_ok(spec: Dictionary) -> bool:
	var need: Variant = spec.get("need", {})
	if typeof(need) != TYPE_DICTIONARY:
		return true
	for k in (need as Dictionary).keys():
		if int(FamilyProfile.data.get(str(k), 0)) < int((need as Dictionary)[k]):
			return false
	return true
