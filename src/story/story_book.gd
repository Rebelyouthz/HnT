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
	if who == "collector":
		return "COLLECTOR GANT"
	var crew: Variant = all().get("crew", {})
	if crew is Dictionary and (crew as Dictionary).has(who):
		return str(((crew as Dictionary)[who] as Dictionary).get("name", who.to_upper()))
	return "THE STREET"


## Has the family rescued this crew member (benny / rico)?
static func has_crew(who: String) -> bool:
	return bool(FamilyProfile.data.get("crew_" + who, false))


static func rescue(map_id: String) -> Dictionary:
	var v: Variant = act(map_id).get("rescue", {})
	return v if v is Dictionary else {}


static func bridge_key(from_id: String, to_id: String) -> String:
	return "%s->%s" % [from_id, to_id]


static func has_bridge(from_id: String, to_id: String) -> bool:
	return not bridge(from_id, to_id).is_empty()


static func bridge(from_id: String, to_id: String) -> Dictionary:
	var row: Variant = all().get("bridges", {})
	if typeof(row) != TYPE_DICTIONARY:
		return {}
	var item: Variant = (row as Dictionary).get(bridge_key(from_id, to_id), {})
	if typeof(item) != TYPE_DICTIONARY:
		return {}
	return item


static func ending() -> Dictionary:
	var row: Variant = all().get("ending", {})
	if typeof(row) != TYPE_DICTIONARY:
		return {}
	return row


static func chapter_card(kind: String, from_id: String, to_id: String) -> Dictionary:
	if kind == "ending":
		var e := ending()
		return {"title": str(e.get("title", "EPILOGUE")), "sub": str(e.get("sub", ""))}
	var b := bridge(from_id, to_id)
	return {
		"title": str(b.get("title", str(b.get("chapter", "NEXT SESSION")))),
		"sub": str(b.get("sub", ""))
	}


static func film_lines(kind: String, from_id: String, to_id: String) -> Array:
	if kind == "ending":
		var v: Variant = ending().get("lines", [])
		return v if typeof(v) == TYPE_ARRAY else []
	var v2: Variant = bridge(from_id, to_id).get("lines", [])
	return v2 if typeof(v2) == TYPE_ARRAY else []
