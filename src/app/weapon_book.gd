class_name WeaponBook
extends Object

const PATH := "res://data/weapons.json"
static var _cache: Dictionary = {}


static func all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
	return _cache


static func spec(id: String) -> Dictionary:
	var row: Variant = all().get(id, {})
	return row if typeof(row) == TYPE_DICTIONARY else {}
