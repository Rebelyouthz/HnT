extends SceneTree

## While a story errand leads, nothing else opens: the hideout's other
## rooms say what comes first, and in the menu only the button under the
## arrow presses (A on another one is eaten). Prints STORY LOCK OK.

var _n := 0
var _bad: Array[String] = []
var _other_pressed := false
var _other: BaseButton = null


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.lock_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	var fp := root.get_node("FamilyProfile")
	if _n == 2:
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		fp.data["errand_told_dock_street"] = true
		(fp.data["guides_done"] as Array).append("errand_dock_street")
		change_scene_to_file("res://scenes/levels/camp.tscn")
	var cs := current_scene
	var eg := get_first_node_in_group("errand_guide")
	if _n == 340:
		for gd in get_nodes_in_group("guide"):
			gd.queue_free()
	if _n == 360:
		print("errand target: ", eg.get("target") if eg else "none")
		if eg == null or not str(eg.get("target")).begins_with("station:"):
			_bad.append("no errand pointing at a room (%s)" % (str(eg.get("target")) if eg else "none"))
		cs.call("_use", {"id": "dojo", "locked": false})
		cs.call("_use", {"id": "bulletin_board", "locked": false})
	if _n == 370:
		if cs.get("_overlay") != null:
			_bad.append("another room opened while the story leads")
		var tk: Object = cs.get("_talk")
		if tk != null and tk.has_method("_close"):
			tk.call("_close")
		cs.call("_use", {"id": str(eg.get("target")).substr(8), "locked": false})
	if _n == 400:
		if cs.get("_overlay") == null:
			_bad.append("the errand's own room did not open")
		print("menu target: ", eg.get("target"))
		var tgt: Control = eg.get("_target_ctrl")
		for c in root.find_children("*", "BaseButton", true, false):
			var b := c as BaseButton
			if b != tgt and not b.disabled and b.is_visible_in_tree() and b.focus_mode != Control.FOCUS_NONE and (tgt == null or not (tgt.is_ancestor_of(b) or b.is_ancestor_of(tgt))) and str(b.get_meta("key", "")).begins_with("tab_"):
				_other = b
				break
		if _other == null:
			_bad.append("no other button to try")
		else:
			_other.pressed.connect(func() -> void: _other_pressed = true)
			_other.grab_focus()
	if _n == 404 and _other != null:
		if not bool(eg.call("blocks", _other)):
			_bad.append("%s not locked while the arrow is elsewhere" % str(_other.get_meta("key", "")))
		if bool(eg.call("blocks", eg.get("_target_ctrl"))):
			_bad.append("the arrow's own button is locked")
	if _n == 415:
		print("STORY LOCK OK" if _bad.is_empty() else "STORY LOCK FAIL " + str(_bad))
		if FileAccess.file_exists("user://family.lock_backup.json"):
			DirAccess.copy_absolute("user://family.lock_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.lock_backup.json")
		quit(0 if _bad.is_empty() else 1)
	return false
