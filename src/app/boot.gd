extends Node

func _enter_tree() -> void:
	_bind_keyboard()
	_act("p2_left", [KEY_LEFT])
	_act("p2_right", [KEY_RIGHT])
	_act("p2_up", [KEY_UP])
	_act("p2_down", [KEY_DOWN])
	_act("p2_jump", [KEY_CTRL])
	_act("p2_light", [KEY_PERIOD])
	_act("p2_heavy", [KEY_SLASH])
	_act("p2_special", [KEY_SEMICOLON])
	_act("p2_shoot", [KEY_APOSTROPHE])
	_act("p2_block", [KEY_BRACKETLEFT])
	_act("p2_throw", [KEY_BRACKETRIGHT])
	_act("p2_dash", [KEY_ALT])
	_act("p2_snap", [KEY_N])
	_act("p2_pause", [KEY_P])
	_bind_pads()


func _bind_keyboard() -> void:
	_act("p1_left", [KEY_A])
	_act("p1_right", [KEY_D])
	_act("p1_up", [KEY_W])
	_act("p1_down", [KEY_S])
	_act("p1_jump", [KEY_SPACE])
	_act("p1_light", [KEY_J])
	_act("p1_heavy", [KEY_K])
	_act("p1_special", [KEY_L])
	_act("p1_shoot", [KEY_O])
	_act("p1_block", [KEY_I])
	_act("p1_throw", [KEY_U])
	_act("p1_dash", [KEY_SHIFT])
	_act("p1_snap", [KEY_F])
	_act("p1_pause", [KEY_ESCAPE])
	_act("ui_accept", [KEY_ENTER, KEY_SPACE])
	_act("ui_cancel", [KEY_ESCAPE])


func _bind_pads() -> void:
	_joy_btn("p1_jump", JOY_BUTTON_A, 0)
	_joy_btn("p1_light", JOY_BUTTON_X, 0)
	_joy_btn("p1_heavy", JOY_BUTTON_Y, 0)
	_joy_btn("p1_special", JOY_BUTTON_B, 0)
	_joy_btn("p1_shoot", JOY_BUTTON_RIGHT_SHOULDER, 0)
	_joy_btn("p1_block", JOY_BUTTON_LEFT_SHOULDER, 0)
	_joy_axis("p1_left", JOY_AXIS_LEFT_X, -1.0, 0)
	_joy_axis("p1_right", JOY_AXIS_LEFT_X, 1.0, 0)
	_joy_axis("p1_up", JOY_AXIS_LEFT_Y, -1.0, 0)
	_joy_axis("p1_down", JOY_AXIS_LEFT_Y, 1.0, 0)
	_joy_axis("p1_dash", JOY_AXIS_TRIGGER_RIGHT, 1.0, 0)
	_joy_axis("p1_throw", JOY_AXIS_TRIGGER_LEFT, 1.0, 0)
	_joy_btn("p1_snap", JOY_BUTTON_RIGHT_STICK, 0)
	_joy_btn("p1_pause", JOY_BUTTON_START, 0)

	_joy_btn("p2_jump", JOY_BUTTON_A, 1)
	_joy_btn("p2_light", JOY_BUTTON_X, 1)
	_joy_btn("p2_heavy", JOY_BUTTON_Y, 1)
	_joy_btn("p2_special", JOY_BUTTON_B, 1)
	_joy_btn("p2_shoot", JOY_BUTTON_RIGHT_SHOULDER, 1)
	_joy_btn("p2_block", JOY_BUTTON_LEFT_SHOULDER, 1)
	_joy_axis("p2_left", JOY_AXIS_LEFT_X, -1.0, 1)
	_joy_axis("p2_right", JOY_AXIS_LEFT_X, 1.0, 1)
	_joy_axis("p2_up", JOY_AXIS_LEFT_Y, -1.0, 1)
	_joy_axis("p2_down", JOY_AXIS_LEFT_Y, 1.0, 1)
	_joy_axis("p2_dash", JOY_AXIS_TRIGGER_RIGHT, 1.0, 1)
	_joy_axis("p2_throw", JOY_AXIS_TRIGGER_LEFT, 1.0, 1)
	_joy_btn("p2_snap", JOY_BUTTON_RIGHT_STICK, 1)
	_joy_btn("p2_pause", JOY_BUTTON_START, 1)
	_joy_btn("p2_dropin", JOY_BUTTON_START, 1)


func _act(name: StringName, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		if not _has_event(name, e):
			InputMap.action_add_event(name, e)


func _joy_btn(name: StringName, button: JoyButton, device: int) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.2)
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.device = device
	if not _has_event(name, e):
		InputMap.action_add_event(name, e)


func _joy_axis(name: StringName, axis: JoyAxis, value: float, device: int) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.25)
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	e.device = device
	if not _has_event(name, e):
		InputMap.action_add_event(name, e)


func _has_event(name: StringName, ev: InputEvent) -> bool:
	for existing in InputMap.action_get_events(name):
		if existing.as_text() == ev.as_text():
			return true
	return false
