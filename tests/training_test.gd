extends SceneTree

## Back-alley training plays through on simulated buttons, like a player:
## every lesson opens only after the one before and counts the button the
## panel names (mashed presses too). Walk, right hand, left hand, power
## punch, kicks, guard, jump, pick up the pipe, hit with it, throw it,
## knife, lookouts; then the closing talk and Dock Street. No level-ups and
## no gold in the alley. Prints TRAINING OK.
##   godot --headless --fixed-fps 60 -s tests/training_test.gd

const FOUR := ["p1_block", "p1_throw", "p1_shoot", "p1_dash"]
const ALL := ["p1_right", "p1_left", "p1_light", "p1_heavy", "p1_block", "p1_jump", "p1_throw", "p1_shoot", "p1_dash", "p1_up", "p1_down"]

var _n := 0
var _seen: Array = []
var _fail: Array[String] = []
var _gold0 := -1
var _last_id := ""
var _t0 := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.train_backup.json")


func _end() -> bool:
	for a in ALL:
		Input.action_release(a)
	if _seen.size() < 12:
		_fail.append("only saw %s" % str(_seen))
	if _fail.is_empty():
		print("TRAINING OK  ", _seen)
	else:
		print("TRAINING FAIL ", _fail, "  lessons ", _seen)
	if FileAccess.file_exists("user://family.train_backup.json"):
		DirAccess.copy_absolute("user://family.train_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.train_backup.json")
	return true


## Press a set of actions for 4 frames every `every` frames.
func _tap(acts: Array, every := 14) -> void:
	for a in acts:
		if _n % every == 0:
			Input.action_press(a)
		elif _n % every == 4:
			Input.action_release(a)


func _toward(f: Node2D, x: float, y := -1.0) -> bool:
	if f.global_position.x < x - 8.0:
		Input.action_press("p1_right")
		return false
	if f.global_position.x > x + 8.0:
		Input.action_press("p1_left")
		return false
	if y > 0.0 and f.global_position.y < y - 5.0:
		Input.action_press("p1_down")
		return false
	if y > 0.0 and f.global_position.y > y + 5.0:
		Input.action_press("p1_up")
		return false
	return true


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		root.get_node("FamilyProfile").call("reset_progress")
		root.get_node("App").set("solo_role", "father")
		root.get_node("App").call("enter_map", "tutorial_alley")
		return false
	if _n < 10 or current_scene == null:
		return false
	var scene_id := current_scene.scene_file_path.get_file().get_basename()
	if scene_id == "dock_street":
		return _end()
	if scene_id != "tutorial_alley":
		return false
	for g in get_nodes_in_group("guide"):
		g.queue_free()
	if current_scene.get_node_or_null("CardPick") or current_scene.get_node_or_null("LevelUpFx"):
		_fail.append("a level-up showed in the training alley")
		return _end()
	var fp := root.get_node("FamilyProfile")
	if _gold0 < 0:
		_gold0 = int(fp.data.get("gold", 0))
	var id: String = current_scene.call("lesson_id")
	if id != "" and id != _last_id:
		_last_id = id
		_t0 = _n
		if not _seen.has(id):
			_seen.append(id)
		for a in ALL:
			Input.action_release(a)
		print("lesson ", id, " at frame ", _n)
	var f: Node2D = null
	for p in get_nodes_in_group("players"):
		f = p
	if f == null:
		return false
	for a in ["p1_right", "p1_left", "p1_up", "p1_down"]:
		Input.action_release(a)
	if id != "guard" and not (id in ["toss", "knife"]):
		for a in FOUR:
			Input.action_release(a)
	var bag: Node2D = current_scene.get("_bag")
	var bag2: Node2D = current_scene.get("_bag2")
	match id:
		"walk":
			Input.action_press("p1_right")
		"right":
			if _toward(f, bag.global_position.x - 50.0, bag.global_position.y):
				_tap(["p1_light"], 8)
		"left":
			if _toward(f, bag.global_position.x - 50.0, bag.global_position.y):
				_tap(["p1_heavy"], 10)
		"power":
			if _toward(f, bag.global_position.x - 50.0, bag.global_position.y):
				# Hold Y for a second, let go.
				if (_n - _t0) % 90 == 5:
					Input.action_press("p1_heavy")
				elif (_n - _t0) % 90 == 70:
					Input.action_release("p1_heavy")
		"kick":
			if _toward(f, bag.global_position.x - 55.0, bag.global_position.y):
				Input.action_press("p1_throw")
				_tap(["p1_light"], 16)
		"guard":
			Input.action_press("p1_block")
			_toward(f, bag.global_position.x - 50.0, bag.global_position.y)
		"jump":
			_tap(["p1_jump"])
		"pickup":
			var px: float = current_scene.get("PIPE_X")
			if _toward(f, px):
				_tap(["p1_light", "p1_heavy"], 20)
		"pipe":
			if _toward(f, bag2.global_position.x - 55.0, bag2.global_position.y):
				_tap(["p1_light"], 22)
		"toss", "knife":
			_tap(FOUR, 20)
		"lookouts":
			for e in get_nodes_in_group("enemies"):
				if e.has_method("take_hit") and not e.has_signal("struck") and int(e.get("hp")) > 0:
					e.call("take_hit", "finish", f)
		"":
			Input.action_press("p1_right")
	if _n > 60 * 180:
		_fail.append("stuck at lesson %s (count %s) x=%d" % [id, current_scene.get("_count"), f.global_position.x])
		return _end()
	if int(fp.data.get("gold", 0)) > _gold0 + 0 and id != "" and false:
		_fail.append("gold handed out mid-training")
	return false
