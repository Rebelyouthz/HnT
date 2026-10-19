extends SceneTree

## Throw lesson with a player's hands: X and Y a few frames apart (either
## order), stick still pushed toward the bag, standing where the punch
## lessons left him, a little off the bag's line. Prints THROW PROBE lines.
##   godot --headless --fixed-fps 60 -s tests/throw_probe.gd

var _n := 0
var _case := 0
var _t := 0
var _count0 := 0
var _res: Array = []
const CASES := [
	# [dx from bag, dy, first, gap frames, stick toward]
	[-50.0, 0.0, "p1_light", 2, true],
	[-50.0, 0.0, "p1_heavy", 2, true],
	[-56.0, 18.0, "p1_light", 3, true],
	[-56.0, -18.0, "p1_heavy", 4, false],
	[-60.0, 26.0, "p1_light", 1, true],
	[-44.0, 10.0, "p1_light", 0, false],
	[-84.0, 30.0, "p1_heavy", 3, true],
	[40.0, 0.0, "p1_light", 2, false],
]


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.probe_backup.json")


func _finish() -> bool:
	for a in ["p1_light", "p1_heavy", "p1_right"]:
		Input.action_release(a)
	print("THROW PROBE ", _res)
	if FileAccess.file_exists("user://family.probe_backup.json"):
		DirAccess.copy_absolute("user://family.probe_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.probe_backup.json")
	return true


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		root.get_node("FamilyProfile").call("reset_progress")
		root.get_node("App").set("solo_role", "father")
		root.get_node("App").call("enter_map", "tutorial_alley")
		return false
	if _n < 30 or current_scene == null or current_scene.scene_file_path.get_file().get_basename() != "tutorial_alley":
		return _n > 3000 and _finish()
	for g in get_nodes_in_group("guide"):
		g.queue_free()
	var sc := current_scene
	var f: Node2D = null
	for p in get_nodes_in_group("players"):
		f = p
	var bag: Node2D = sc.get("_bag")
	if _n == 30:
		var i := 0
		for l in sc.get("LESSONS"):
			if str(l["id"]) == "throw":
				break
			i += 1
		sc.call("_begin", i)
		return false
	if sc.call("lesson_id") != "throw":
		return _finish()
	if _case >= CASES.size():
		return _finish()
	var c: Array = CASES[_case]
	if _t == 0:
		sc.set("_count", 0)
		# The lesson's repeat guard runs on the wall clock; headless frames
		# outrun it, so each case starts with it clear.
		sc.set("_throw_t", -9.0)
		_count0 = 0
		f.global_position = bag.global_position + Vector2(c[0], c[1])
		f.set("facing", 1)
	_t += 1
	var first: String = c[2]
	var second := "p1_heavy" if first == "p1_light" else "p1_light"
	if c[4]:
		Input.action_press("p1_right")
	if _t == 20:
		Input.action_press(first)
	if _t == 20 + int(c[3]):
		Input.action_press(second)
	if _t == 34:
		Input.action_release(first)
		Input.action_release(second)
		Input.action_release("p1_right")
	if _t == 110:
		var cnt := int(sc.get("_count")) if sc.get("_count") != null else -1
		_res.append("case%d %s" % [_case, "COUNTED" if cnt > _count0 else "missed (count %d)" % cnt])
		_case += 1
		_t = 0
	return false
