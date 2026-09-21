extends SceneTree

func _initialize() -> void:
	var failed := 0
	failed += _check_json("res://data/buildings.json", 9)
	failed += _check_json("res://data/awards.json", 4)
	failed += _check_json("res://data/cbt.json", 6)
	var miles: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/milestones.json"))
	if typeof(miles) != TYPE_DICTIONARY or not miles.has("daily") or (miles["daily"] as Array).size() != 3:
		push_error("milestones.json invalid")
		failed += 1
	var fp := get_root().get_node("FamilyProfile")
	if fp.tab_unlocked("clinic") == false or fp.tab_unlocked("run") == false:
		push_error("Clinic and Run must start unlocked")
		failed += 1
	if fp.tab_unlocked("build"):
		push_error("Build should start locked")
		failed += 1
	if Copy.LOGO != "HnT":
		failed += 1
	if failed > 0:
		push_error("SMOKE FAILED %d" % failed)
		quit(1)
	else:
		print("SMOKE OK")
		quit(0)


func _check_json(path: String, n: int) -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_ARRAY or (parsed as Array).size() != n:
		push_error("%s expected %d entries" % [path, n])
		return 1
	return 0
