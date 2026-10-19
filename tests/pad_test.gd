extends SceneTree

## Controller support: the shipped DB loads, a CONTROLLER SETUP map binds a
## pad's raw buttons / axes to the actions (iPega-style odd layouts).
## Prints PAD OK.

var _n := 0
var ok := true


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("PAD FAIL ", what)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 3:
		var pr: Node = root.get_node("PadRouter")
		var n := int(load("res://src/input/pad_compat.gd").call("load_db"))
		_check(n >= 0, "db load")
		var f := FileAccess.open("res://data/gamecontrollerdb.txt", FileAccess.READ)
		_check(f != null and f.get_length() > 100000, "db shipped")
		var cm := {"jump": {"t": "b", "i": 7}, "light": {"t": "b", "i": 2}, "right": {"t": "a", "i": 4, "v": -1.0}}
		pr.call("_bind_custom", "p2_", 5, cm)
		var e := InputEventJoypadButton.new()
		e.device = 5
		e.button_index = 7 as JoyButton
		e.pressed = true
		Input.parse_input_event(e)
		var m := InputEventJoypadMotion.new()
		m.device = 5
		m.axis = 4 as JoyAxis
		m.axis_value = -0.9
		Input.parse_input_event(m)
		# Plain pads (iPega and friends) steer with the d-pad too.
		pr.call("_bind_device", "p1_", 6)
		var dp := InputEventJoypadButton.new()
		dp.device = 6
		# Solo: the stick on any pad id walks too.
		pr.call("_bind_move", "p1_", -1)
		var any := InputEventJoypadMotion.new()
		any.axis = JOY_AXIS_LEFT_Y
		any.axis_value = 1.0
		any.device = -1
		_check(InputMap.action_has_event("p1_down", any), "any-pad stick bound beside per-pad")
		dp.button_index = JOY_BUTTON_DPAD_LEFT
		dp.pressed = true
		Input.parse_input_event(dp)
	if _n == 6:
		_check(Input.is_action_pressed("p1_left"), "d-pad -> move left")
		_check(Input.is_action_pressed("p2_jump"), "custom button -> jump")
		_check(Input.is_action_pressed("p2_right"), "custom axis (inverted) -> right")
		_check(not Input.is_action_pressed("p2_left"), "left stays off")
		print("PAD OK" if ok else "PAD FAILED")
		quit()
	return false
