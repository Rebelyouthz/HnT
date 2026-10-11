extends SceneTree

## The Rooftop Run (Fire Escapes) played start to finish by the runner's
## autopilot: the countdown lets go, the hunter starts after you, the run
## reaches the zipline mast, the map is filed, the results sheet comes up,
## and its NEXT goes on toward Group Circle (chapter card, hideout or the
## map itself). With PARKOUR_SLOPPY set, the autopilot misses some jumps
## and the run has to come back from the checkpoints or end on the retry
## card. Prints PARKOUR OK on success.
##   PARKOUR_AUTO=1 godot --headless --fixed-fps 60 -s tests/parkour_test.gd

var _n := 0
var _phase := "boot"
var _t0 := 0
var _fail: Array[String] = []
var _notes: Array = []
var _went := false
var _hunted := false
var _max_x := 0.0
var _falls := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.parkour_backup.json")


func _find(script_end: String) -> Node:
	for c in root.find_children("*", "", true, false):
		var sc: Script = c.get_script()
		if sc != null and str(sc.resource_path).ends_with(script_end):
			return c
	return null


func _finish() -> bool:
	var sloppy := OS.get_environment("PARKOUR_SLOPPY") != ""
	if _fail.is_empty():
		print("PARKOUR OK", "  (sloppy)" if sloppy else "")
		for r in _notes:
			print("  ", r)
	else:
		print("PARKOUR FAIL ", _fail)
	if FileAccess.file_exists("user://family.parkour_backup.json"):
		DirAccess.copy_absolute("user://family.parkour_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.parkour_backup.json")
	return true


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	match _phase:
		"boot":
			if _n < 2:
				return false
			var fp := root.get_node("FamilyProfile")
			fp.call("reset_progress")
			var g: Array = []
			for gk in load("res://src/ui/guides.gd").STEPS:
				g.append(str(gk))
			fp.data["guides_done"] = g
			fp.data["intro_done"] = true
			fp.data["skip_films"] = false
			fp.call("mark_map_filed", "dock_street")
			fp.call("mark_map_filed", "intake_lot")
			root.get_node("App").set("difficulty", "open_house")
			change_scene_to_file("res://scenes/levels/fire_escapes.tscn")
			_phase = "run"
			_t0 = _n
		"run":
			var run := current_scene
			if run == null or not run is Node2D or run.get("course") == null:
				if _n - _t0 > 120:
					_fail.append("fire_escapes never loaded")
					return _finish()
				return false
			var rns: Array = run.get("runners")
			if rns.is_empty():
				return false
			var rn: Node2D = rns[0]
			_max_x = maxf(_max_x, rn.position.x)
			if bool(run.get("_go")):
				_went = true
			var h: Node = run.get("hunter")
			if h != null and bool(h.get("active")):
				_hunted = true
			if bool(run.get("_respawning")):
				_falls += 1 if _n % 30 == 0 else 0
			var sheet := _find("results_sheet.gd")
			var retry: Node = null
			for b in root.find_children("*", "Button", true, false):
				if (b as Button).text.begins_with("TRY AGAIN") and (b as Button).is_visible_in_tree():
					retry = b
			if sheet != null:
				var goal := float(run.get("course").get("goal_x"))
				_notes.append("escaped at %.0f / goal %.0f in %.1fs, lives left %d" % [_max_x, goal, float(_n - _t0) / 60.0, int(rn.get("lives"))])
				if not (root.get_node("FamilyProfile").data.get("maps_filed", []) as Array).has("fire_escapes"):
					_fail.append("fire_escapes not filed after the escape")
				if str(sheet.get("headline")) != "ESCAPED":
					_fail.append("sheet headline %s" % sheet.get("headline"))
				_phase = "next"
				_t0 = _n
				return false
			if retry != null:
				_notes.append("retry card at %.0f after %.1fs (sloppy autopilot)" % [_max_x, float(_n - _t0) / 60.0])
				if OS.get_environment("PARKOUR_SLOPPY") == "":
					_fail.append("clean autopilot lost the run at %.0f" % _max_x)
				if int(root.get_node("FamilyProfile").data.get("roof_tries", 0)) < 1:
					_fail.append("a lost run did not count a try")
				return _finish()
			if _n - _t0 > 60 * 150:
				_fail.append("run never ended (x %.0f, went %s, hunted %s)" % [_max_x, _went, _hunted])
				return _finish()
		"next":
			if _n - _t0 == 150:
				if not _went or not _hunted:
					_fail.append("countdown/hunter: went %s hunted %s" % [_went, _hunted])
				var sheet := _find("results_sheet.gd")
				if sheet == null:
					_fail.append("results sheet vanished")
					return _finish()
				sheet.call("_go_next")
				_t0 = _n
				_phase = "after"
		"after":
			var id := ""
			if current_scene != null:
				id = current_scene.scene_file_path.get_file().get_basename()
			if id in ["act_film", "camp", "group_circle"]:
				_notes.append("NEXT went to %s" % id)
				return _finish()
			if _n - _t0 > 600:
				_fail.append("NEXT stayed on %s" % id)
				return _finish()
	return false
