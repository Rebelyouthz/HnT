extends Node

func _enter_tree() -> void:
	if OS.has_feature("windows") and not OS.has_feature("editor"):
		DisplayServer.window_set_title("Father & Son")
	_bind_keyboard()


func _ready() -> void:
	# Video options and the pixel cursor once the profile is loaded.
	call_deferred("_apply_settings")


func _apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		Gfx.apply(get_tree())
	PixelCursor.install(get_tree())


## F11 / Alt+Enter: fullscreen <-> window. The game boots fullscreen.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_F11 or (k.keycode == KEY_ENTER and k.alt_pressed):
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


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
	_act("p1_duck", [KEY_C])
	_act("p1_pause", [KEY_ESCAPE])
	_mouse("p1_shoot", MOUSE_BUTTON_RIGHT)
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
	_act("p2_duck", [KEY_M])
	_act("p2_pause", [KEY_P])
	_act("ui_accept", [KEY_ENTER, KEY_SPACE])
	_act("ui_cancel", [KEY_ESCAPE])


func _act(name: StringName, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		if not _has_event(name, e):
			InputMap.action_add_event(name, e)


func _mouse(name: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.2)
	var e := InputEventMouseButton.new()
	e.button_index = button
	if not _has_event(name, e):
		InputMap.action_add_event(name, e)


func _has_event(name: StringName, ev: InputEvent) -> bool:
	for existing in InputMap.action_get_events(name):
		if existing.as_text() == ev.as_text():
			return true
	return false
