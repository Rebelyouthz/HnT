class_name PhotoMode
extends CanvasLayer

## Photo mode in a run: P (or the pad's Back/Select) freezes the street and
## hides the HUD; click / A takes the picture (flash, shutter, saved to
## user://photos), B / P / ESC goes back to the fight.

var _on := false
var _ui: Control
var _hidden: Array = []


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = PixelStage.attach_canvas(self)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.visible = false
	var frame := Control.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.size = Vector2(1280, 720)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(func() -> void:
		var c := Color(1, 1, 1, 0.8)
		for p: Vector2 in [Vector2(40, 40), Vector2(1240, 40), Vector2(40, 680), Vector2(1240, 680)]:
			var sx := 1.0 if p.x < 640 else -1.0
			var sy := 1.0 if p.y < 360 else -1.0
			frame.draw_rect(Rect2(p.x - (0 if sx > 0 else 40), p.y - (0 if sy > 0 else 4), 40, 4), c)
			frame.draw_rect(Rect2(p.x - (0 if sx > 0 else 4), p.y - (0 if sy > 0 else 40), 4, 40), c)
	)
	_ui.add_child(frame)
	var l := Label.new()
	l.text = "PHOTO MODE   ·   CLICK / A  SNAP   ·   P / B  BACK"
	l.position = Vector2(0, 660)
	l.size = Vector2(1280, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 16, Palette.TEXT)
	l.name = "Hint"
	_ui.add_child(l)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	var toggle := (key != null and key.pressed and not key.echo and key.keycode == KEY_P) or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_BACK)
	if toggle:
		_toggle_photo(not _on)
		get_viewport().set_input_as_handled()
		return
	if not _on:
		return
	if (key != null and key.pressed and key.keycode == KEY_ESCAPE) or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_B):
		_toggle_photo(false)
		get_viewport().set_input_as_handled()
	elif (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_A):
		_snap()
		get_viewport().set_input_as_handled()


func _toggle_photo(on: bool) -> void:
	if on and get_tree().paused:
		return
	_on = on
	get_tree().paused = on
	_ui.visible = on
	if on:
		_hidden.clear()
		for n in get_tree().current_scene.find_children("*", "CanvasLayer", true, false):
			if n != self and (n as CanvasLayer).visible and (n as CanvasLayer).layer > 0 and (n as CanvasLayer).layer < 100:
				(n as CanvasLayer).visible = false
				_hidden.append(n)
	else:
		for n in _hidden:
			if is_instance_valid(n):
				(n as CanvasLayer).visible = true
		_hidden.clear()


func _snap() -> void:
	_ui.visible = false
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://photos")
	var path := "user://photos/hnt_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	img.save_png(path)
	_ui.visible = true
	Juice.play("res://assets/audio/shutter.wav" if ResourceLoader.exists("res://assets/audio/shutter.wav") else "res://assets/audio/ui_click.wav")
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.size = Vector2(1280, 720)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.35)
	tw.tween_callback(flash.queue_free)
	var hint := _ui.get_node("Hint") as Label
	hint.text = "SAVED  ·  " + ProjectSettings.globalize_path(path).get_file()
