extends SceneTree

func _initialize() -> void:
	var failed := 0
	failed += _check_json("res://data/buildings.json", 9)
	failed += _check_json("res://data/awards.json", 8)
	failed += _check_json("res://data/cbt.json", 8)
	failed += _check_json("res://data/cards.json", 11)
	var miles: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/milestones.json"))
	if typeof(miles) != TYPE_DICTIONARY or not miles.has("daily") or (miles["daily"] as Array).size() != 3:
		push_error("milestones.json invalid")
		failed += 1
	var shop: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
	if typeof(shop) != TYPE_DICTIONARY or not (shop as Dictionary).has("ammo") or not (shop as Dictionary).has("grenade"):
		push_error("shop.json missing vendor items")
		failed += 1
	if not (shop as Dictionary).has("catalogs"):
		push_error("shop catalogs missing")
		failed += 1
	failed += _encounters()
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
	if Copy.GO_SOLO != "GO ALONE" or Copy.FIRE_CLEAR != "FIRE ESCAPES FILED":
		push_error("missing solo/fire copy")
		failed += 1
	if Copy.WAITING != "WAITING FOR FATHER" or Copy.CONNECT != "CONNECT":
		push_error("missing host/join copy")
		failed += 1
	if Copy.HALL_CLEAR != "CITY HALL FILED":
		push_error("missing city hall copy")
		failed += 1
	var app := get_root().get_node("App")
	if app.couch != false:
		push_error("App.couch must default false so hub GO starts solo")
		failed += 1
	if app.density_coop != false:
		push_error("density must default solo")
		failed += 1
	failed += _exists("res://src/combat/snap_director.gd")
	failed += _exists("res://src/world/web_anchor.gd")
	failed += _exists("res://src/world/fire_escape.gd")
	failed += _exists("res://src/world/light_rig.gd")
	failed += _exists("res://src/world/vault_crate.gd")
	failed += _exists("res://src/shaders/wet_asphalt.gdshader")
	failed += _exists("res://src/shaders/neon_flicker.gdshader")
	failed += _exists("res://src/coop/party.gd")
	failed += _exists("res://src/levels/run_act.gd")
	failed += _exists("res://src/levels/fire_escapes.gd")
	failed += _exists("res://src/levels/neon_exchange.gd")
	failed += _exists("res://src/levels/rail_bridge.gd")
	failed += _exists("res://src/levels/city_hall.gd")
	failed += _exists("res://src/world/roof_vendor.gd")
	failed += _exists("res://src/world/street_shop.gd")
	failed += _exists("res://src/actors/mayor_raven.gd")
	failed += _exists("res://src/net/net_session.gd")
	failed += _exists("res://src/ui/host_wait.gd")
	failed += _exists("res://src/ui/join_sheet.gd")
	failed += _exists("res://src/ui/stat_panel.gd")
	failed += _exists("res://src/input/pad_router.gd")
	failed += _exists("res://scenes/levels/fire_escapes.tscn")
	failed += _exists("res://scenes/levels/neon_exchange.tscn")
	failed += _exists("res://scenes/levels/rail_bridge.tscn")
	failed += _exists("res://scenes/levels/city_hall.tscn")
	failed += _exists("res://tools/hnt_rooms.py")
	failed += _contains("res://src/combat/snap_director.gd", "WORLD_SCALE := 0.22")
	failed += _contains("res://src/actors/fighter.gd", "STEAM_MAX := 100.0")
	failed += _contains("res://src/actors/fighter.gd", "JUMP_HEIGHT")
	failed += _contains("res://src/actors/fighter.gd", "jump-kick")
	failed += _contains("res://src/world/web_anchor.gd", "MIN_LEN := 80.0")
	failed += _contains("res://src/world/web_anchor.gd", "MAX_LEN := 280.0")
	failed += _contains("res://src/world/light_rig.gd", "MAX_POINT := 3")
	failed += _contains("res://src/levels/dock_street.gd", "ROOF_Y := 248.0")
	failed += _contains("res://src/levels/run_act.gd", "Party.encounters")
	failed += _contains("res://src/levels/run_act.gd", "Party.all_past")
	failed += _contains("res://src/app/app.gd", "var couch: bool = false")
	failed += _contains("res://src/app/app.gd", "neon_exchange")
	failed += _contains("res://src/juice/juice.gd", "func toast(")
	failed += _contains("res://src/juice/juice.gd", "func unlock_logo(")
	failed += _contains("res://src/input/pad_router.gd", "drop_in.emit(device)")
	failed += _contains("res://src/ui/hub_run.gd", "Copy.GO_SOLO")
	failed += _contains("res://src/ui/hub_run.gd", "host_wait.gd")
	failed += _contains("res://src/ui/hub_clinic.gd", "App.couch = false")
	failed += _contains("res://src/net/net_session.gd", "GAME_PORT := 24567")
	failed += _contains("res://src/ui/copy.gd", "WAITING FOR FATHER")
	failed += _contains("res://src/actors/mayor_raven.gd", "PHASE 3")
	var boot := get_root().get_node_or_null("Boot")
	if boot:
		boot._enter_tree()
	if not InputMap.has_action("p2_snap") or not InputMap.has_action("p2_special"):
		push_error("P2 kit actions missing")
		failed += 1
	if not InputMap.has_action("p1_snap") or not InputMap.has_action("p1_dash"):
		push_error("P1 kit actions missing")
		failed += 1
	var net := get_root().get_node_or_null("NetSession")
	if net == null:
		push_error("NetSession autoload missing")
		failed += 1
	if failed > 0:
		push_error("SMOKE FAILED %d" % failed)
		quit(1)
	else:
		print("SMOKE OK")
		quit(0)


func _encounters() -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("encounters.json missing")
		return 1
	var n := 0
	n += _map_counts(parsed, "dock_street", 3, 6)
	n += _map_counts(parsed, "fire_escapes", 3, 6)
	n += _map_counts(parsed, "neon_exchange", 3, 6)
	n += _map_counts(parsed, "rail_bridge", 3, 6)
	n += _map_counts(parsed, "city_hall", 3, 6)
	return n


func _map_counts(parsed: Variant, map_id: String, solo_n: int, coop_n: int) -> int:
	var row: Variant = (parsed as Dictionary).get(map_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		push_error("%s missing in encounters" % map_id)
		return 1
	var solo: Variant = (row as Dictionary).get("solo", [])
	var coop: Variant = (row as Dictionary).get("coop", [])
	if typeof(solo) != TYPE_ARRAY or (solo as Array).size() != solo_n:
		push_error("%s solo expected %d" % [map_id, solo_n])
		return 1
	if typeof(coop) != TYPE_ARRAY or (coop as Array).size() != coop_n:
		push_error("%s coop expected %d" % [map_id, coop_n])
		return 1
	if solo_n >= coop_n:
		push_error("%s solo is not thinner than coop" % map_id)
		return 1
	return 0


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
