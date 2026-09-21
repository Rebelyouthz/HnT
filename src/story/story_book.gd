class_name StoryBook
extends Object

const PATH := "res://data/story.json"
static var _cache: Dictionary = {}


static func all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
	return _cache


static func act(map_id: String) -> Dictionary:
	var acts: Variant = all().get("acts", {})
	if typeof(acts) != TYPE_DICTIONARY:
		return {}
	var row: Variant = (acts as Dictionary).get(map_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		return {}
	return row


static func is_survive(map_id: String) -> bool:
	return bool(act(map_id).get("survive", false))


static func who_name(who: String) -> String:
	if who == "father":
		return FamilyProfile.father_name()
	if who == "son":
		return FamilyProfile.son_name()
	return "THE STREET"
