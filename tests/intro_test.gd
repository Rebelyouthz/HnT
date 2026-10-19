extends SceneTree

## A brand-new family: PLAY goes prologue film -> back-alley training ->
## Dock Street, the intro is marked done, and a second PLAY skips straight
## to the street. Films get a while to play on their own, then are skipped
## the way their skip buttons do. Prints INTRO OK on success.
##   godot --headless --fixed-fps 60 -s tests/intro_test.gd

var _n := 0
var _seen: Array = []
var _last: Node = null
var _wait := 0
var _fail: Array[String] = []
var _phase := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.intro_backup.json")


func _id() -> String:
	if current_scene == null:
		return ""
	return current_scene.scene_file_path.get_file().get_basename()


func _done() -> bool:
	if _fail.is_empty():
		print("INTRO OK  ", _seen)
	else:
		print("INTRO FAIL ", _fail, "  saw ", _seen)
	if FileAccess.file_exists("user://family.intro_backup.json"):
		DirAccess.copy_absolute("user://family.intro_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.intro_backup.json")
	return true


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	var fp := root.get_node("FamilyProfile")
	if _n == 2:
		fp.call("reset_progress")
		fp.data["intro_done"] = false
		root.get_node("App").call("start_run")
		return false
	if _n < 3:
		return false
	if current_scene != _last:
		_last = current_scene
		_wait = 0
		if _id() != "":
			_seen.append(_id())
	_wait += 1
	var id := _id()
	if _phase == 0:
		match id:
			"prologue":
				if _wait == 60 * 25:
					current_scene.call("_finish")
			"tutorial_alley":
				if _wait == 60 * 3:
					current_scene.call("skip_training")
			"dock_street":
				if _wait == 120:
					if not bool(fp.data.get("intro_done", false)):
						_fail.append("intro not marked done")
					for want in ["prologue", "tutorial_alley"]:
						if not _seen.has(want):
							_fail.append("skipped " + want)
					_phase = 1
					_seen.append("|second PLAY|")
					root.get_node("App").call("start_run")
		if _n > 60 * 120 and _phase == 0:
			_fail.append("stuck on " + id)
			return _done()
	else:
		if _wait == 60 and id != "":
			if id != "dock_street":
				_fail.append("second PLAY went to " + id)
			return _done()
		if _n > 60 * 140:
			_fail.append("second PLAY stuck")
			return _done()
	return false
