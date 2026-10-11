extends SceneTree

## Chapter 7 (Rail Bridge) check: the freight line, three side quests and
## spray cans are on the map; a train warns, then runs over a thug left on
## the back rails (LAST STOP) and knocks a hero off the track, and the run
## over counts for Boxcar Hank's quest. Prints RAIL OK on success.
##   godot --headless --fixed-fps 60 -s tests/rail_test.gd

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
		DirAccess.copy_absolute("user://family.json", "user://family.rail_backup.json")


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
		root.get_node("App").set("current_map", "rail_bridge")
		change_scene_to_file("res://scenes/levels/rail_bridge.tscn")
	if _n > 200 and _n < 900:
		paused = false
	if _n == 220:
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_line = get_first_node_in_group("freight_line")
		if _line == null:
			_fail.append("no freight line")
		var givers := 0
		var cans := 0
		for n in current_scene.get_children():
			var sc: Script = n.get_script()
			var path := sc.resource_path if sc else ""
			if path.ends_with("quest_giver.gd"):
				givers += 1
				var q: Dictionary = n.get("quest")
				if str(q.get("id", "")) == "hobo_hank":
					_hank = n
			elif path.ends_with("spray_can.gd"):
				cans += 1
		if givers < 3:
			_fail.append("quest givers %d" % givers)
		if cans != 3:
			_fail.append("spray cans %d" % cans)
		_p = get_first_node_in_group("players")
		# Hank's quest is taken; a thug and the hero stand on the rails.
		if _hank:
			_hank.set("state", "active")
		_thug = load("res://src/coop/party.gd").spawn_row(current_scene, {
			"title": "Bag Snatch", "x": _p.global_position.x + 120.0, "y": 444, "home": "street",
			"hp": 40, "pmin": _p.global_position.x + 110.0, "pmax": _p.global_position.x + 130.0
		}, 1.0)
		_thug.set_physics_process(false)
		_thug.set_process(false)
		_p.global_position.y = 444.0
		_p.set_physics_process(false)
		_hp0 = int(_p.get("hp"))
		_line.process_mode = Node.PROCESS_MODE_ALWAYS
		_line.set("_cd", 0.2)
	if _n > 220 and _n < 900 and _line and str(_line.get("_state")) == "warn":
		_warned = true
	if _n == 600:
		if not _warned:
			_fail.append("no warning before the train")
		if is_instance_valid(_thug) and int(_thug.get("hp")) > 0:
			_fail.append("thug survived the train")
		if int(_p.get("hp")) >= _hp0 and absf(_p.global_position.y - 444.0) < 15.0:
			_fail.append("hero not hit by the train")
		if _hank and int(_hank.get("count")) < 1 and str(_hank.get("state")) == "active":
			_fail.append("run over did not count for Hank")
		if _fail.is_empty():
			print("RAIL OK")
		else:
			print("RAIL FAIL ", _fail)
		if FileAccess.file_exists("user://family.rail_backup.json"):
			DirAccess.copy_absolute("user://family.rail_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.rail_backup.json")
		return true
	return false
