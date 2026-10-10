extends SceneTree

## Walk vs run on a story street: hold RIGHT (brisk walk, walk clip), then
## RIGHT + DASH (run, parkour_run clip, faster), then a double tap. Prints
## RUN OK when the run is clearly faster than the walk and uses the run clip.
##   godot --headless --fixed-fps 60 -s tests/run_test.gd

var _n := 0
var _p: Node2D = null
var _x0 := 0.0
var _walk_v := 0.0
var _run_v := 0.0
var _walk_clip := ""
var _run_clip := ""
var _tap_run := false


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.run_backup.json")


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
		change_scene_to_file("res://scenes/levels/tutorial_alley.tscn")
	if _n == 200:
		paused = false
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_p = get_first_node_in_group("players")
		Input.action_press("p1_right")
	if _n == 210 and _p:
		_x0 = _p.global_position.x
	if _n == 240 and _p:
		_walk_v = (_p.global_position.x - _x0) / 0.5
		_walk_clip = str((_p.get("_anim") as AnimatedSprite2D).animation)
		Input.action_press("p1_dash")
	if _n == 262 and _p:
		_x0 = _p.global_position.x
	if _n == 280 and _p:
		_run_v = (_p.global_position.x - _x0) / 0.3
		_run_clip = str((_p.get("_anim") as AnimatedSprite2D).animation)
		Input.action_release("p1_dash")
		Input.action_release("p1_right")
	# Double tap forward: release, tap, release, hold.
	if _n == 420:
		Input.action_press("p1_right")
	if _n == 424:
		Input.action_release("p1_right")
	if _n == 428:
		Input.action_press("p1_right")
	if _n == 450 and _p:
		_tap_run = bool(_p.get("running"))
		Input.action_release("p1_right")
	if _n == 460:
		print("walk %.0f px/s (%s)  run %.0f px/s (%s)  double-tap run %s" % [_walk_v, _walk_clip, _run_v, _run_clip, str(_tap_run)])
		var ok := _run_v > _walk_v * 1.3 and _walk_v > 100.0 and _run_clip == "parkour_run" and _walk_clip.begins_with("walk") and _tap_run
		print("RUN OK" if ok else "RUN FAIL")
		if FileAccess.file_exists("user://family.run_backup.json"):
			DirAccess.copy_absolute("user://family.run_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.run_backup.json")
		quit()
	return false
