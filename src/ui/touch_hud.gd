extends CanvasLayer

func _ready() -> void:
	layer = 25
	if not DisplayServer.is_touchscreen_available():
		queue_free()
		return
	_btn("LEFT", Vector2(24, 560), Vector2(110, 90), "p1_left")
	_btn("RIGHT", Vector2(150, 560), Vector2(110, 90), "p1_right")
	_btn("JUMP", Vector2(980, 560), Vector2(120, 80), "p1_jump")
	_btn("LIGHT", Vector2(1120, 500), Vector2(120, 80), "p1_light")
	_btn("HEAVY", Vector2(1120, 600), Vector2(120, 80), "p1_heavy")


func _btn(text: String, pos: Vector2, size: Vector2, action: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 18)
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
