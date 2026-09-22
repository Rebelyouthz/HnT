class_name TowerBook
extends Object

## Viewpoint talks, climb windows, rotating descents. Never the same twice in a row.


static func table() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/towers.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


static func map_row(map_id: String) -> Dictionary:
	var maps: Variant = table().get("maps", {})
	if typeof(maps) != TYPE_DICTIONARY:
		return {}
	var row: Variant = (maps as Dictionary).get(map_id, {})
	if typeof(row) == TYPE_DICTIONARY:
		return row
	return {}


static func talk(id: String) -> Dictionary:
	var talks: Variant = table().get("talks", {})
	if typeof(talks) != TYPE_DICTIONARY:
		return {}
	var row: Variant = (talks as Dictionary).get(id, {})
	if typeof(row) == TYPE_DICTIONARY:
		return row
	return {}


static func talk_for_map(map_id: String) -> Dictionary:
	return talk(str(map_row(map_id).get("talk", "mornings")))


static func descents() -> Array:
	var d: Variant = table().get("descents", ["parachute", "zip", "water", "ledge"])
	if typeof(d) == TYPE_ARRAY:
		return d
	return ["parachute", "zip", "water", "ledge"]


static func next_descent() -> String:
	var pool := descents()
	var last := str(FamilyProfile.data.get("last_descent", ""))
	var picks: Array = []
	for d in pool:
		if str(d) != last:
			picks.append(d)
	if picks.is_empty():
		picks = pool
	picks.shuffle()
	var pick := str(picks[0])
	FamilyProfile.data["last_descent"] = pick
	FamilyProfile.save()
	return pick


static func ring_window(map_id: String) -> float:
	var w := float(map_row(map_id).get("window", 0.2))
	match App.difficulty:
		"open_house":
			w += 0.08
		"finals":
			w -= 0.05
	if FamilyProfile.has_cbt("cling_callus"):
		w += 0.06
	var rs := _run_state()
	if rs and rs.has_method("has_card"):
		if bool(rs.call("has_card", "shuttle_rip")):
			w += 0.04
	return clampf(w, 0.08, 0.36)


static func ring_count(map_id: String) -> int:
	var n := int(map_row(map_id).get("rings", 3))
	if App.difficulty == "finals":
		n += 1
	return clampi(n, 3, 6)


static func _run_state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("run_state")
