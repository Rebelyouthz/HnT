extends SceneTree

## Walks the whole story from Dock Street to the ending, one map hand-off at
## a time, the way a cleared map hands off: App.advance(next). Films and the
## hideout are skipped through by calling what their own buttons call. For
## every hop it checks that the chapter card plays when the story has one,
## that the two set pieces (skinwalker, parachute) play, and that the next
## map really loads. Prints STORY OK on success.
##   godot --headless --fixed-fps 60 -s tests/story_flow_test.gd

var _n := 0
var _pairs: Array = []
var _i := -1
var _seen: Array = []
var _wait := 0
var _fail: Array[String] = []
var _last_scene: Node = null


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.story_backup.json")


func _scene_id() -> String:
	if current_scene == null or current_scene.scene_file_path == "":
		return ""
	return current_scene.scene_file_path.get_file().get_basename()


func _next_pair() -> void:
	_i += 1
	_seen.clear()
	_wait = 0
	if _i >= _pairs.size():
		return
	var a: String = _pairs[_i][0]
	var b: String = _pairs[_i][1]
	var app := root.get_node("App")
	app.set("current_map", a)
	app.set("camp_next", "")
	var rs: Node = load("res://src/coop/run_state.gd").new()
	root.add_child(rs)
	app.call("advance", b, rs)
	rs.queue_free()


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
		fp.data["skip_films"] = false
		# Gates are their own test (errand_all_test): walk the story open.
		root.get_node("App").set("gates_off", true)
		var order: Array = root.get_node("App").get("ORDER")
		for k in order.size() - 1:
			_pairs.append([order[k], order[k + 1]])
		_pairs.append([order[order.size() - 1], "ending"])
		_next_pair()
		return false
	if _n < 3:
		return false
	paused = false
	if _i >= _pairs.size():
		if _fail.is_empty():
			print("STORY OK  (%d hand-offs)" % _pairs.size())
		else:
			print("STORY FAIL ", _fail)
		if FileAccess.file_exists("user://family.story_backup.json"):
			DirAccess.copy_absolute("user://family.story_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.story_backup.json")
		return true
	var id := _scene_id()
	if current_scene != _last_scene:
		_last_scene = current_scene
		_wait = 0
		if id != "":
			_seen.append(id)
	_wait += 1
	var a: String = _pairs[_i][0]
	var b: String = _pairs[_i][1]
	if _wait == 20:
		match id:
			"act_film":
				current_scene.call("_leave")
			"camp":
				if b == "ending":
					_check(a, b)
					_next_pair()
				else:
					root.get_node("App").call("leave_camp")
			"skinwalker_film":
				current_scene.call("_leave")
			"parachute_fall":
				current_scene.call("_go_sleet")
			_:
				if id == b or (b == "ending" and id in ["camp", "hub"]):
					_check(a, b)
					_next_pair()
				elif _wait == 20 and _seen.size() > 0 and id == a:
					pass
	if _wait > 400:
		_fail.append("%s->%s stuck on %s (saw %s)" % [a, b, id, _seen])
		_next_pair()
	return false


func _check(a: String, b: String) -> void:
	var sb: GDScript = load("res://src/story/story_book.gd")
	if b != "ending" and bool(sb.call("has_bridge", a, b)) and not _seen.has("act_film"):
		_fail.append("%s->%s no chapter card (saw %s)" % [a, b, _seen])
	if a == "neon_exchange" and not _seen.has("skinwalker_film"):
		_fail.append("neon->waiting skipped the skinwalker film (saw %s)" % [_seen])
	if a == "copay_orchard" and not _seen.has("parachute_fall"):
		_fail.append("orchard->sleet skipped the parachute (saw %s)" % [_seen])
	print("hop ", a, " -> ", b, "  ", _seen)
