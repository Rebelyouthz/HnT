extends CanvasLayer

func _ready() -> void:
	layer = 25
	if not DisplayServer.is_touchscreen_available():
		queue_free()
		return
	_btn("LEFT", Vector2(24, 560), Vector2(100, 80), "p1_left")
	_btn("RIGHT", Vector2(140, 560), Vector2(100, 80), "p1_right")
	_btn("UP", Vector2(82, 470), Vector2(100, 70), "p1_up")
	_btn("JUMP", Vector2(860, 560), Vector2(100, 80), "p1_jump")
	_btn("LIGHT", Vector2(980, 500), Vector2(100, 70), "p1_light")
	_btn("HEAVY", Vector2(1100, 500), Vector2(100, 70), "p1_heavy")
	_btn("CAPE", Vector2(980, 590), Vector2(100, 70), "p1_special")
	_btn("SHOT", Vector2(1100, 590), Vector2(100, 70), "p1_shoot")
	_btn("SNAP", Vector2(1220, 540), Vector2(50, 110), "p1_snap")
	_btn("DASH", Vector2(24, 470), Vector2(100, 70), "p1_dash")


func _btn(text: String, pos: Vector2, size: Vector2, action: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 16)
	b.button_down.connect(func() -> void:
		_tap(action, true)
	)
	b.button_up.connect(func() -> void:
		_tap(action, false)
	)
	add_child(b)


func _tap(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
