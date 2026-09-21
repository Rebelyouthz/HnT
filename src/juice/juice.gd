extends Node

var shake_amp := 0.0
var _overlay: CanvasLayer
var _sfx: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 80
	add_child(_overlay)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "sfx"
	add_child(_sfx)


func _process(delta: float) -> void:
	shake_amp = move_toward(shake_amp, 0.0, 28.0 * delta)


func shake_offset() -> Vector2:
	if shake_amp <= 0.05:
		return Vector2.ZERO
	return Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amp


func pulse_shake(px: float) -> void:
	shake_amp = maxf(shake_amp, px)


func hitstop(frames: int) -> void:
	if frames <= 0:
		return
	var sec := frames / 60.0
	Engine.time_scale = 0.08
	await get_tree().create_timer(sec, true, false, true).timeout
	Engine.time_scale = 1.0


func flash_red(node: CanvasItem, frames: int = 2) -> void:
	var original := node.modulate
	node.modulate = Color(1.0, 0.22, 0.18, 1.0)
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	if is_instance_valid(node):
		node.modulate = original


func play(stream_path: String) -> void:
	if ResourceLoader.exists(stream_path):
		_sfx.stream = load(stream_path)
		_sfx.pitch_scale = randf_range(0.94, 1.06)
		_sfx.play()


func popup_number(global_pos: Vector2, text: String, color: Color) -> void:
	var cam := get_viewport().get_camera_2d()
	var screen := global_pos
	if cam:
		screen = cam.get_screen_transform() * global_pos
	var lab := Label.new()
	lab.text = text
	lab.modulate = color
	lab.position = screen + Vector2(-20, -40)
	lab.add_theme_font_size_override("font_size", 22)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 6)
	_overlay.add_child(lab)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "position:y", lab.position.y - 42.0, 0.45)
	tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.55).set_delay(0.25)
	tw.finished.connect(lab.queue_free)


func claim_burst(from: Vector2, line: String, gold: int, gems: int) -> void:
	play("res://assets/audio/claim.wav")
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(wrap)
	var lab := Label.new()
	lab.text = line
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 28)
	lab.add_theme_color_override("font_color", Palette.LEMON)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lab.add_theme_constant_override("outline_size", 8)
	lab.position = from + Vector2(-160, -20)
	lab.size = Vector2(320, 40)
	wrap.add_child(lab)
	var extra := Label.new()
	var bits: PackedStringArray = []
	if gold:
		bits.append("+%d GOLD" % gold)
	if gems:
		bits.append("+%d GEMS" % gems)
	extra.text = "  ·  ".join(bits)
	extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	extra.position = from + Vector2(-160, 22)
	extra.size = Vector2(320, 28)
	extra.add_theme_font_size_override("font_size", 18)
	extra.add_theme_color_override("font_color", Palette.EDGE)
	wrap.add_child(extra)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "scale", Vector2(1.12, 1.12), 0.18)
	tw.tween_interval(0.52)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.2)
	tw.finished.connect(wrap.queue_free)
