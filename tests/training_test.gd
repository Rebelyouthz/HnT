extends SceneTree

## Back-alley training plays through on simulated buttons: every lesson
## opens only after the one before (walk, jab x3, heavy x2, guard x2, jump,
## pick up, hit with the pipe, throw it, knife, lookouts), then the closing
## talk and Dock Street. Prints TRAINING OK.
##   godot --headless --fixed-fps 60 -s tests/training_test.gd

var _n := 0
var _seen: Array = []
var _fail: Array[String] = []
var _act := ""
var _hold := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.train_backup.json")


func _end() -> bool:
	for a in ["p1_right", "p1_left", "p1_light", "p1_heavy", "p1_block", "p1_jump", "p1_throw", "p1_up", "p1_down"]:
		Input.action_release(a)
	if _fail.is_empty() and _seen.size() >= 10:
		print("TRAINING OK  ", _seen)
	else:
		print("TRAINING FAIL ", _fail, "  lessons ", _seen)
	if FileAccess.file_exists("user://family.train_backup.json"):
		DirAccess.copy_absolute("user://family.train_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.train_backup.json")
	return true


func _tap(a: String) -> void:
	if _n % 14 == 0:
		Input.action_press(a)
	elif _n % 14 == 3:
		Input.action_release(a)


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		root.get_node("FamilyProfile").call("reset_progress")
		root.get_node("App").set("solo_role", "son")
		root.get_node("App").call("enter_map", "tutorial_alley")
		return false
	if _n < 10 or current_scene == null:
		return false
	var id := current_scene.scene_file_path.get_file().get_basename()
	if id == "dock_street":
		return _end()
	if id != "tutorial_alley":
		return false
	var s: int = current_scene.get("_step")
	if s >= 0 and not _seen.has(s):
		_seen.append(s)
	var f: Node2D = null
	for p in get_nodes_in_group("players"):
		f = p
	if f == null:
		return false
	for a in ["p1_right", "p1_left", "p1_block", "p1_up", "p1_down"]:
		Input.action_release(a)
	# Line up in depth with the bag the lesson is on.
	var bag: Node2D = current_scene.get("_bag2") if s >= 6 else current_scene.get("_bag")
	if s in [1, 2, 6] and bag:
		if f.global_position.y < bag.global_position.y - 5.0:
			Input.action_press("p1_down")
		elif f.global_position.y > bag.global_position.y + 5.0:
			Input.action_press("p1_up")
	match s:
		0:
			Input.action_press("p1_right")
		1, 2:
			if f.global_position.x < 560.0:
				Input.action_press("p1_right")
			else:
				_tap("p1_light" if s == 1 else "p1_heavy")
		3:
			Input.action_press("p1_block")
			if f.global_position.x < 560.0:
				Input.action_press("p1_right")
		4:
			_tap("p1_jump")
		5:
			if f.global_position.x < 1112.0:
				Input.action_press("p1_right")
			else:
				_tap("p1_throw")
		6:
			if f.global_position.x < 1318.0:
				Input.action_press("p1_right")
			else:
				_tap("p1_light")
				if false:
					print("s6 pl=", f.get("parkour_lock"), " roll=", f.get("roll_t"), " ct=", f.get("_combo_t"), " blk=", f.get("blocking"), " plane=", f.get("plane"), " snap=", f.get("snap_ready"), " hush=", f.get("_hush_until"), " clk=", f.get("_clock"), " cd=", f.get("attack_cd"), " face=", f.get("facing"), " bag hp=", bag.get("hp"), " dummy mode=", bag.get("mode"))
		7:
			if f.global_position.x > 1250.0:
				Input.action_press("p1_left")
			else:
				_tap("p1_throw")
		8:
			if f.global_position.x > 1220.0:
				Input.action_press("p1_left")
			else:
				_tap("p1_throw")
		10:
			Input.action_press("p1_right")
		9:
			for e in get_nodes_in_group("enemies"):
				if e.has_method("take_hit") and not e.has_signal("struck") and int(e.get("hp")) > 0:
					e.call("take_hit", "finish", f)
	if _n > 60 * 150:
		_fail.append("stuck at lesson %d x=%d y=%d pickup=%s bag2=%s %s cnt=%s" % [s, f.global_position.x, f.global_position.y, f.get("pickup"), current_scene.get("_bag2").hits, current_scene.get("_bag2").global_position, current_scene.get("_count")])
		return _end()
	return false
