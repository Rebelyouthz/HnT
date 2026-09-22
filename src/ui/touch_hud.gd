extends CanvasLayer

## Phone-safe touch: light / heavy / jump / duck / parkour plus move.
## Layout is 1280×720 design space, scaled 0.5 by PixelStage.


func _ready() -> void:
	layer = 25
	var phone := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if not phone:
		queue_free()
		return
	var ui := PixelStage.attach_canvas(self)
	var m := PixelStage.safe_design_margins()
	var left_x := float(m.x)
	var bot := 720.0 - float(m.w)
	_btn(ui, "LEFT", Vector2(left_x + 8, bot - 96), Vector2(108, 88), "p1_left")
	_btn(ui, "RIGHT", Vector2(left_x + 124, bot - 96), Vector2(108, 88), "p1_right")
	_btn(ui, "PARKOUR", Vector2(left_x + 8, bot - 196), Vector2(108, 88), "p1_dash")
	_btn(ui, "DUCK", Vector2(left_x + 124, bot - 196), Vector2(108, 88), "p1_duck")
	var right_x := 1280.0 - float(m.z)
	_btn(ui, "JUMP", Vector2(right_x - 236, bot - 96), Vector2(108, 88), "p1_jump")
	_btn(ui, "LIGHT", Vector2(right_x - 120, bot - 196), Vector2(108, 88), "p1_light")
	_btn(ui, "HEAVY", Vector2(right_x - 120, bot - 96), Vector2(108, 88), "p1_heavy")


func _btn(host: Control, text: String, pos: Vector2, size: Vector2, action: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	b.add_theme_stylebox_override("pressed", UiKit.panel(Palette.BRICK, Palette.LEMON))
	b.button_down.connect(func() -> void:
		_tap(action, true)
	)
	b.button_up.connect(func() -> void:
		_tap(action, false)
	)
	host.add_child(b)


func _tap(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
