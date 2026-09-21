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
	if Copy.CLEAR != "DOCK STREET FILED":
		push_error("missing clear copy")
		failed += 1
	failed += _exists("res://src/combat/snap_director.gd")
	failed += _exists("res://src/world/web_anchor.gd")
	failed += _exists("res://src/world/fire_escape.gd")
	failed += _exists("res://src/world/light_rig.gd")
	failed += _exists("res://src/world/vault_crate.gd")
	failed += _exists("res://src/shaders/wet_asphalt.gdshader")
	failed += _contains("res://src/combat/snap_director.gd", "WORLD_SCALE := 0.22")
	failed += _contains("res://src/actors/fighter.gd", "STEAM_MAX := 100.0")
	failed += _contains("res://src/actors/fighter.gd", "JUMP_HEIGHT")
	failed += _contains("res://src/world/web_anchor.gd", "MIN_LEN := 80.0")
	failed += _contains("res://src/world/web_anchor.gd", "MAX_LEN := 280.0")
	failed += _contains("res://src/world/light_rig.gd", "MAX_POINT := 3")
	failed += _contains("res://src/levels/dock_street.gd", "ROOF_Y := 248.0")
	var boot := get_root().get_node_or_null("Boot")
	if boot:
		boot._enter_tree()
	if not InputMap.has_action("p2_snap") or not InputMap.has_action("p2_special"):
		push_error("P2 kit actions missing")
		failed += 1
	if not InputMap.has_action("p1_snap") or not InputMap.has_action("p1_dash"):
		push_error("P1 kit actions missing")
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


func _exists(path: String) -> int:
	if not FileAccess.file_exists(path):
		push_error("missing %s" % path)
		return 1
	return 0


func _contains(path: String, needle: String) -> int:
	var body := FileAccess.get_file_as_string(path)
	if not body.contains(needle):
		push_error("%s missing %s" % [path, needle])
		return 1
	return 0
