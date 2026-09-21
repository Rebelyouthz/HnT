extends Node

var trauma := 0.0
var combo := 0
var combo_ttl := 0.0
var callout := ""
var _callout_t := 0.0
var _base_scale := 1.0
var _hitstop_depth := 0
var _noise_t := 0.0
var _overlay: CanvasLayer
var _sfx: AudioStreamPlayer

const DECAY := 1.35
const MAX_OFFSET := Vector2(12, 8)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 80
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "sfx"
	add_child(_sfx)


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(trauma - DECAY * delta, 0.0)
	_noise_t += delta * 30.0
	if combo > 0:
		_combo_clock(delta)
	if _callout_t > 0.0:
		_callout_t -= delta
		if _callout_t <= 0.0:
			callout = ""


func _combo_clock(delta: float) -> void:
	# Combo lives in world time so SNAP does not eat the meter.
	combo_ttl -= delta
	if combo_ttl <= 0.0:
		combo = 0


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func shake_offset() -> Vector2:
	var shake := trauma * trauma
	if shake <= 0.002:
		return Vector2.ZERO
	return Vector2(
		MAX_OFFSET.x * shake * sin(_noise_t * 1.7),
		MAX_OFFSET.y * shake * sin(_noise_t * 2.3)
	)


func pulse_shake(px: float) -> void:
	add_trauma(clampf(px / 12.0, 0.08, 1.0))


func set_world_scale(s: float) -> void:
	_base_scale = s
	_apply_scale()


func _apply_scale() -> void:
	if _hitstop_depth > 0:
		return
	Engine.time_scale = _base_scale


func hitstop(frames: int) -> void:
	if frames <= 0:
		return
	_hitstop_depth += 1
	Engine.time_scale = 0.08
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	_hitstop_depth = maxi(0, _hitstop_depth - 1)
	if _hitstop_depth == 0:
		Engine.time_scale = _base_scale


func freeze_frames(frames: int) -> void:
	if frames <= 0:
		return
	_hitstop_depth += 1
	Engine.time_scale = 0.02
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	_hitstop_depth = maxi(0, _hitstop_depth - 1)
	if _hitstop_depth == 0:
		Engine.time_scale = _base_scale


func flash_red(node: CanvasItem, frames: int = 2) -> void:
	if node == null:
		return
	var original := node.modulate
	node.modulate = Color(1.0, 0.22, 0.18, 1.0)
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	if is_instance_valid(node):
		node.modulate = original


func flash_white_red(node: CanvasItem) -> void:
	if node == null:
		return
	var original := node.modulate
	node.modulate = Color(1.0, 1.0, 1.0, 1.0)
	await get_tree().create_timer(1.0 / 60.0, true, false, true).timeout
	if is_instance_valid(node):
		node.modulate = Color(1.0, 0.28, 0.2, 1.0)
	await get_tree().create_timer(3.0 / 60.0, true, false, true).timeout
	if is_instance_valid(node):
		node.modulate = original


func squash(node: Node2D, facing: int) -> void:
	if node == null:
		return
	node.scale = Vector2(1.28 * float(facing), 0.7)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(node, "scale", Vector2(float(facing), 1.0), 0.16)


func play(stream_path: String) -> void:
	if has_node("/root/Mixer"):
		Mixer.play_sfx(stream_path)
		return
	if ResourceLoader.exists(stream_path):
		_sfx.stream = load(stream_path)
		_sfx.pitch_scale = randf_range(0.94, 1.06)
		_sfx.play()


func register_hit(kind: String, global_pos: Vector2, dmg: int) -> void:
	combo += 1
	combo_ttl = 1.55
	if kind == "light":
		popup_number(global_pos + Vector2(0, -80), str(dmg), Palette.TEXT)
	elif kind == "snap":
		popup_number(global_pos + Vector2(0, -86), "SNAP", Color(0.86, 0.92, 1.0))
	elif kind == "web-slam":
		popup_number(global_pos + Vector2(0, -86), "OFFICE", Color(1.0, 0.55, 0.2))
	else:
		popup_number(global_pos + Vector2(0, -80), str(dmg), Color(1.0, 0.55, 0.2))
	if combo == 5:
		shout("NICE")
	elif combo == 8:
		shout("RANK B")
	elif combo == 10:
		shout("HOLY HELL, %s" % FamilyProfile.son_name())
	elif combo == 15:
		shout("RANK A")
	elif combo == 20:
		shout("FAMILY POLICY")
	elif combo == 30:
		shout("RANK S")
	elif combo == 40:
		shout("THE THERAPIST IS CRYING")


func shout(line: String) -> void:
	callout = line
	_callout_t = 1.35


func snap_bang(global_pos: Vector2) -> void:
	pulse_shake(8.0)
	register_hit("snap", global_pos, 0)
	kill_burst(global_pos, "snap")
	play("res://assets/audio/snap.wav")
	await freeze_frames(4)
	await hitstop(8)


func kill_burst(global_pos: Vector2, kind: String) -> void:
	if kind == "light":
		return
	var p := CPUParticles2D.new()
	p.global_position = global_pos + Vector2(0, -30)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = 16
	p.lifetime = 0.38
	p.direction = Vector2(0, -1)
	p.spread = 55.0
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 190.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.2
	if kind == "snap":
		p.color = Color(0.9, 0.92, 1.0)
	elif kind == "web-slam":
		p.color = Color(0.55, 0.55, 0.62)
	else:
		p.color = Palette.BRICK
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	await get_tree().create_timer(0.55, true, false, true).timeout
	if is_instance_valid(p):
		p.queue_free()


func popup_number(global_pos: Vector2, text: String, color: Color) -> void:
	var cam := get_viewport().get_camera_2d()
	var screen := global_pos
	if cam:
		screen = cam.get_screen_transform() * global_pos
	var lab := Label.new()
	lab.text = text
	lab.modulate = color
	lab.position = screen + Vector2(-22, -40)
	lab.add_theme_font_size_override("font_size", 22)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 6)
	_overlay.add_child(lab)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(lab, "position:y", lab.position.y - 42.0, 0.45)
	tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.55).set_delay(0.25)
	tw.finished.connect(lab.queue_free)


func claim_burst(from: Vector2, line: String, gold: int, gems: int) -> void:
	play("res://assets/audio/claim.wav")
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
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
	tw.set_ignore_time_scale(true)
	tw.tween_property(lab, "scale", Vector2(1.12, 1.12), 0.18)
	tw.tween_interval(0.52)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.2)
	tw.finished.connect(wrap.queue_free)
	if gold or gems:
		fly_pills(from, gold, gems)


func fly_pills(from: Vector2, gold: int, gems: int) -> void:
	for i in maxi(gold, 0) / 4 + (1 if gold else 0):
		_fly_chip(from, Vector2(980, 18), Palette.EDGE)
	for i in maxi(gems, 0):
		_fly_chip(from, Vector2(1100, 18), Palette.LEMON)


func _fly_chip(from: Vector2, to: Vector2, color: Color) -> void:
	var chip := ColorRect.new()
	chip.size = Vector2(14, 14)
	chip.color = color
	chip.position = from
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(chip)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(chip, "position", to + Vector2(randf_range(-12, 12), randf_range(-6, 6)), 0.7)
	tw.tween_property(chip, "modulate:a", 0.0, 0.12)
	tw.finished.connect(chip.queue_free)


func keep_combo() -> void:
	combo_ttl = maxf(combo_ttl, 1.1)


func toast(kind: String, title: String, body: String) -> void:
	play("res://assets/audio/claim.wav")
	var wrap := PanelContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	var accent := Palette.EDGE
	match kind:
		"achievement":
			accent = Palette.LEMON
		"quest":
			accent = Palette.READY
		"challenge":
			accent = Palette.BRICK
		_:
			accent = Palette.EDGE
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, accent))
	wrap.position = Vector2(860, 86 + _overlay.get_child_count() * 8)
	wrap.size = Vector2(400, 72)
	_overlay.add_child(wrap)
	var col := VBoxContainer.new()
	wrap.add_child(col)
	var k := Label.new()
	k.text = kind.to_upper()
	UiKit.apply_label(k, 11, accent)
	col.add_child(k)
	var t := Label.new()
	t.text = title
	UiKit.apply_label(t, 18, Palette.LEMON)
	col.add_child(t)
	var b := Label.new()
	b.text = body
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(360, 0)
	UiKit.apply_label(b, 13, Palette.TEXT)
	col.add_child(b)
	wrap.scale = Vector2(0.86, 0.86)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(wrap, "scale", Vector2.ONE, 0.18)
	tw.tween_interval(1.8)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.22)
	tw.finished.connect(wrap.queue_free)


func unlock_logo(title: String, sub: String) -> void:
	play("res://assets/audio/chest.wav")
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(wrap)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -240
	card.offset_right = 240
	card.offset_top = -90
	card.offset_bottom = 90
	wrap.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var stamp := Label.new()
	stamp.text = "UNLOCKED"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(stamp, 13, Palette.EDGE)
	col.add_child(stamp)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(t, 32, Palette.LEMON)
	col.add_child(t)
	var s := Label.new()
	s.text = sub
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(s, 15, Palette.TEXT)
	col.add_child(s)
	card.scale = Vector2(0.72, 0.72)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(card, "scale", Vector2(1.08, 1.08), 0.22)
	tw.tween_property(card, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(1.15)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.2)
	tw.finished.connect(wrap.queue_free)

