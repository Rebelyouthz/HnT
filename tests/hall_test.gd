extends SceneTree

## Chapter 8 (City Hall) check: the cabinet drops, three side quests and
## spray cans are on the map; a cabinet lands on a thug (FILED) and a hero,
## and the filing counts for Retired Clerk Abe's quest. Prints HALL OK.
##   godot --headless --fixed-fps 60 -s tests/hall_test.gd

var _n := 0
var _line: Node = null
var _thug: Node = null
var _p: Node2D = null
var _hp0 := 0
var _hank: Node = null
var _fail: Array[String] = []
var _warned := false


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.hall_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		root.get_node("App").set("current_map", "city_hall")
		change_scene_to_file("res://scenes/levels/city_hall.tscn")
	if _n > 200 and _n < 900:
		paused = false
	if _n == 220:
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_line = get_first_node_in_group("cabinet_drop")
		if _line == null:
			_fail.append("no cabinet drop")
		var givers := 0
		var cans := 0
		for n in current_scene.get_children():
			var sc: Script = n.get_script()
			var path := sc.resource_path if sc else ""
			if path.ends_with("quest_giver.gd"):
				givers += 1
				var q: Dictionary = n.get("quest")
				if str(q.get("id", "")) == "filed_guard":
					_hank = n
			elif path.ends_with("spray_can.gd"):
				cans += 1
		if givers < 3:
			_fail.append("quest givers %d" % givers)
		if cans != 3:
			_fail.append("spray cans %d" % cans)
		_p = get_first_node_in_group("players")
		# Abe's quest is taken; a thug and the hero stand where cabinets land.
		if _hank:
			_hank.set("state", "active")
		_thug = load("res://src/coop/party.gd").spawn_row(current_scene, {
			"title": "Bag Snatch", "x": _p.global_position.x + 110.0, "y": 480, "home": "street",
			"hp": 40, "pmin": _p.global_position.x + 110.0, "pmax": _p.global_position.x + 130.0
		}, 1.0)
		_thug.set_physics_process(false)
		_thug.set_process(false)
		_p.global_position.y = 480.0
		_p.set_physics_process(false)
		_hp0 = int(_p.get("hp"))
		_line.process_mode = Node.PROCESS_MODE_ALWAYS
		_line.set("_cd", 99.0)
		_line.call("drop_at", Vector2(_p.global_position.x + 110.0, 480.0))
		_line.call("drop_at", Vector2(_p.global_position.x, 480.0))
	if _n > 220 and _n < 900 and _line and not (_line.get("_drops") as Array).is_empty():
		_warned = true
	if _n == 600:
		if not _warned:
			_fail.append("no shadow before the cabinet")
		if is_instance_valid(_thug) and int(_thug.get("hp")) > 0:
			_fail.append("thug not FILED")
		if int(_p.get("hp")) >= _hp0:
			_fail.append("hero not hit by the cabinet")
		if _hank and int(_hank.get("count")) < 1 and str(_hank.get("state")) == "active":
			_fail.append("filing did not count for Abe")
		if _fail.is_empty():
			print("HALL OK")
		else:
			print("HALL FAIL ", _fail)
		if FileAccess.file_exists("user://family.hall_backup.json"):
			DirAccess.copy_absolute("user://family.hall_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.hall_backup.json")
		return true
	return false
