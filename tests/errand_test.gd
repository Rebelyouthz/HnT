extends SceneTree

## The first story errand, played with the arrow: a new family back at the
## hideout before Gant (THICK SKIN at the THERAPY COUCH, Benny still held).
## Each step presses what the arrow is on and checks the next target:
## command board -> room card -> BUILD -> BUILD tab -> THICK SKIN (BUY)
## -> READY. Prints ERRAND OK on success.
##   godot --headless --fixed-fps 60 -s tests/errand_test.gd

var _n := 0
var _fail: Array[String] = []
var _want: Array = ["station:command_board", "card_therapy_couch", "build_btn_therapy_couch", "tab_build", "node_buy_thick_skin"]
var _step := 0
var _seen: Array = []


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.errand_backup.json")


func _guide() -> Node:
	return get_first_node_in_group("errand_guide")


func _ctrl(key: String) -> Control:
	for c in root.find_children("*", "Control", true, false):
		if str(c.get_meta("key", "")) == key and (c as Control).is_visible_in_tree():
			return c
	return null


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		g.append("errand_dock_street")
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 330:
		if _guide() == null:
			_fail.append("no errand guide at the hideout")
			return _end()
	if _n > 330 and _n % 30 == 0 and _step < _want.size():
		var g := _guide()
		if g == null:
			_fail.append("guide gone at step %d" % _step)
			return _end()
		var t := str(g.get("target"))
		_seen.append(t)
		if t != _want[_step]:
			if _n > 330 + 30 * 40:
				_fail.append("step %d wants %s, arrow on %s" % [_step, _want[_step], t])
				return _end()
			return false
		# Do what the arrow says.
		if t == "station:command_board":
			current_scene.call("_open_hub", "clinic")
		else:
			var c := _ctrl(t)
			if c is BaseButton:
				(c as BaseButton).pressed.emit()
		_step += 1
	if _step >= _want.size() and _n % 30 == 0:
		var g2 := _guide()
		if g2 and not load("res://src/app/power_book.gd").path("dock_street").is_empty():
			return false
		if g2 and str(g2.get("_label")).begins_with("READY"):
			return _end()
		if _n > 3000:
			_fail.append("never READY (arrow %s)" % (str(g2.get("target")) if g2 else "-"))
			return _end()
	return false


func _end() -> bool:
	if _fail.is_empty():
		print("ERRAND OK  ", _seen)
	else:
		print("ERRAND FAIL ", _fail, "  seen ", _seen)
	if FileAccess.file_exists("user://family.errand_backup.json"):
		DirAccess.copy_absolute("user://family.errand_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.errand_backup.json")
	return true
