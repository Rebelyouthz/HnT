extends SceneTree
## The fail screen takes the pad: a button has focus, A presses it and the
## game goes back to the hideout. Prints DEATH PAD OK.

var _n := 0
var ok := true
var _scene0 := ""


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _pad(btn: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	e.device = 0
	Input.parse_input_event(e)
	var u := e.duplicate() as InputEventJoypadButton
	u.pressed = false
	Input.parse_input_event(u)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("App").set("solo_role", "father")
		root.get_node("App").call("enter_map", "dock_street")
	if _n > 40 and paused and _n < 100:
		paused = false
	if _n == 90:
		var act := get_first_node_in_group("run_act")
		act.call("_on_fail")
	if _n == 200:
		var f := root.get_viewport().gui_get_focus_owner()
		print("focus: ", f, " ", (f as Button).text if f is Button else "")
		_check(f is Button, "a button has focus on the fail screen")
		_scene0 = current_scene.scene_file_path
		_pad(JOY_BUTTON_A)
	if _n == 320:
		print("scene now: ", current_scene.scene_file_path if current_scene else "<none>")
		_check(current_scene != null and current_scene.scene_file_path != _scene0, "A left the fail screen")
		print("DEATH PAD OK" if ok else "DEATH PAD FAILED")
		quit()
	return false
