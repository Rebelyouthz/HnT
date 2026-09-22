extends Node

var trauma := 0.0
var combo := 0
var combo_ttl := 0.0
var combo_peak := 0
var last_hitter := "son"
var callout := ""
var _callout_t := 0.0
var _base_scale := 1.0
var _hitstop_depth := 0
var _noise_t := 0.0
var _overlay: CanvasLayer
var _sfx: AudioStreamPlayer
var _toast_box: VBoxContainer
var _toast_at: Dictionary = {}

const TOAST_COOL_MS := 2800
const TOAST_MAX := 3

const DECAY := 1.35
const MAX_OFFSET := Vector2(12, 8)
const COMBO_WINDOW := 1.55
const WORLD_SNAP := 0.25


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 80
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var toast_root := Control.new()
	toast_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(toast_root)
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 1.0
	_toast_box.anchor_right = 1.0
	_toast_box.anchor_top = 0.0
	_toast_box.offset_left = -268
	_toast_box.offset_right = -10
	_toast_box.offset_top = 8
	_toast_box.offset_bottom = 240
	_toast_box.add_theme_constant_override("separation", 4)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_root.add_child(_toast_box)
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
		cash_out()


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


func slowmo(scale: float) -> void:
	Engine.time_scale = clampf(scale, 0.05, 1.0)


func restore_time() -> void:
	if _hitstop_depth == 0:
		Engine.time_scale = _base_scale
	else:
		Engine.time_scale = 0.08


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
	combo_peak = maxi(combo_peak, combo)
	combo_ttl = COMBO_WINDOW
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
		toaster_pop("S+")
	if combo == 5 or combo == 10 or combo == 20:
		toaster_pop(combo_rank())


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
	if combo > 0:
		combo_ttl = maxf(combo_ttl, 1.1)


func combo_frac() -> float:
	if combo < 2:
		return 0.0
	return clampf(combo_ttl / COMBO_WINDOW, 0.0, 1.0)


func combo_rank() -> String:
	if combo >= 40:
		return "S+"
	if combo >= 30:
		return "S"
	if combo >= 20:
		return "A"
	if combo >= 15:
		return "B"
	if combo >= 8:
		return "C"
	if combo >= 5:
		return "D"
	if combo >= 2:
		return "HIT"
	return ""


func break_combo() -> void:
	if combo < 2:
		combo = 0
		combo_ttl = 0.0
		combo_peak = 0
		return
	shout("DROPPED")
	popup_number(Vector2(640, 220), "COMBO DEAD", Palette.BRICK)
	combo = 0
	combo_ttl = 0.0
	combo_peak = 0


func cash_out() -> void:
	var n := combo
	combo = 0
	combo_ttl = 0.0
	if n < 5:
		combo_peak = 0
		return
	var scrap_n := maxi(1, n / 4)
	var xp_n := n / 6
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("street_credit"):
		scrap_n *= 2
	if rs and rs.has_method("add_scrap"):
		rs.add_scrap(scrap_n)
	if rs and rs.has_method("add_xp") and xp_n > 0:
		rs.add_xp(xp_n)
	if rs and rs.has_method("add_points"):
		rs.add_points(last_hitter, n * 6, "bank")
	FamilyProfile.mark_combo_bank(n)
	shout("BANKED  +%d SCRAP" % scrap_n)
	popup_number(Vector2(640, 200), "CASH OUT x%d" % n, Palette.EDGE)
	play("res://assets/audio/claim.wav")
	combo_peak = 0


func land_puff(global_pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.global_position = global_pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 8
	p.lifetime = 0.28
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.gravity = Vector2(0, 240)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.4
	p.color = Color(0.55, 0.52, 0.48, 0.7)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	await get_tree().create_timer(0.4, true, false, true).timeout
	if is_instance_valid(p):
		p.queue_free()


func toast(kind: String, title: String, body: String) -> void:
	if _toast_box == null:
		return
	var now := Time.get_ticks_msec()
	var key := title.strip_edges()
	if _toast_at.has(key) and now - int(_toast_at[key]) < TOAST_COOL_MS:
		return
	_toast_at[key] = now
	while _toast_box.get_child_count() >= TOAST_MAX:
		var oldest := _toast_box.get_child(0)
		_toast_box.remove_child(oldest)
		oldest.queue_free()
	var accent := Palette.EDGE
	match kind:
		"achievement", "unlock":
			accent = Palette.LEMON
		"quest":
			accent = Palette.READY
		"challenge":
			accent = Palette.BRICK
		_:
			accent = Palette.EDGE
	var wrap := PanelContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Color(0.06, 0.06, 0.08, 0.82), accent))
	wrap.custom_minimum_size = Vector2(250, 0)
	_toast_box.add_child(wrap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	wrap.add_child(col)
	var t := Label.new()
	t.text = title
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiKit.apply_label(t, 13, accent)
	col.add_child(t)
	if body != "":
		var b := Label.new()
		b.text = body
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UiKit.apply_label(b, 11, Palette.MUTED)
		col.add_child(b)
	wrap.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(wrap, "modulate:a", 1.0, 0.08)
	tw.tween_interval(1.6)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.18)
	tw.finished.connect(wrap.queue_free)


func unlock_logo(title: String, sub: String, reward: String = "") -> void:
	var body := reward if reward != "" else sub
	toast("unlock", title, body)


func level_up(grant: Dictionary) -> void:
	play("res://assets/audio/levelup.wav" if ResourceLoader.exists("res://assets/audio/levelup.wav") else "res://assets/audio/chest.wav")
	pulse_shake(8.0)
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(wrap)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -300
	card.offset_right = 300
	card.offset_top = -160
	card.offset_bottom = 160
	wrap.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(64, 64)
	col.add_child(mark)
	var t := Label.new()
	t.text = "ACCOUNT LEVEL UP"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(t, 28, Palette.LEMON)
	col.add_child(t)
	var av := Label.new()
	av.text = "%s  ·  %s" % [FamilyProfile.son_name(), FamilyProfile.father_name()]
	av.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(av, 16, Palette.TEXT)
	col.add_child(av)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(520, 22)
	bar.max_value = float(grant.get("need", 100))
	bar.value = float(grant.get("xp", 0))
	bar.show_percentage = false
	col.add_child(bar)
	var got2 := Label.new()
	got2.text = "YOU GOT  ·  LV %d  ·  +8 GOLD  ·  PROFILE FRAME CHECK" % int(grant.get("level", 1))
	got2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(got2, 15, Palette.EDGE)
	col.add_child(got2)
	card.scale = Vector2(0.7, 0.7)
	var tw2 := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.set_ignore_time_scale(true)
	tw2.tween_property(card, "scale", Vector2(1.1, 1.1), 0.24)
	tw2.tween_property(card, "scale", Vector2.ONE, 0.12)
	tw2.tween_interval(1.6)
	tw2.tween_property(wrap, "modulate:a", 0.0, 0.22)
	tw2.finished.connect(wrap.queue_free)
	toast("achievement", "LEVEL UP", "YOU GOT  ·  LV %d  ·  +8 GOLD" % int(grant.get("level", 1)))


func carpenter(title: String, reward: String) -> void:
	play("res://assets/audio/hammer.wav" if ResourceLoader.exists("res://assets/audio/hammer.wav") else "res://assets/audio/chest.wav")
	pulse_shake(5.0)
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(wrap)
	var plank := ColorRect.new()
	plank.color = Color(0.45, 0.32, 0.18)
	plank.size = Vector2(160, 18)
	plank.position = Vector2(560, 380)
	wrap.add_child(plank)
	var saw := ColorRect.new()
	saw.color = Palette.EDGE
	saw.size = Vector2(40, 10)
	saw.position = Vector2(540, 360)
	wrap.add_child(saw)
	var lab := Label.new()
	lab.text = "CAMP UNLOCKED"
	lab.position = Vector2(400, 250)
	lab.size = Vector2(480, 40)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(lab, 32, Palette.LEMON)
	wrap.add_child(lab)
	var sub := Label.new()
	sub.text = "%s\nYOU GOT  ·  %s" % [title, reward]
	sub.position = Vector2(360, 300)
	sub.size = Vector2(560, 60)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(sub, 16, Palette.TEXT)
	wrap.add_child(sub)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(saw, "position:x", 720.0, 0.35)
	tw.parallel().tween_property(plank, "rotation", 0.4, 0.4)
	tw.tween_interval(0.55)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.2)
	tw.finished.connect(wrap.queue_free)


func muzzle(at: Vector2, facing: int, caliber: String) -> void:
	var p := CPUParticles2D.new()
	p.global_position = at
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 10
	p.lifetime = 0.12
	p.direction = Vector2(float(facing), -0.1)
	p.spread = 18.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2.ZERO
	p.color = Color(1.0, 0.82, 0.35, 0.95)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	popup_number(at + Vector2(0, -20), caliber, Palette.EDGE)
	get_tree().create_timer(0.25, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)


func sparks(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.global_position = at
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 12
	p.lifetime = 0.22
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.color = Color(0.95, 0.85, 0.4)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	get_tree().create_timer(0.35, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)


func bam(at: Vector2, role: String = "son") -> void:
	shout("BAM")
	pulse_shake(6.0)
	sparks(at)
	VoBank.bam(role)


func trick_chain(n: int, title: String = "") -> void:
	var line := "CHAIN x%d" % n if title == "" else title
	shout(line)
	pulse_shake(3.0 + float(mini(n, 8)) * 0.4)
	if n >= 3:
		unlock_logo(line, "Named trick. The coach would bill this.", "PARKOUR")


func hole(at: Vector2) -> void:
	var h := ColorRect.new()
	h.color = Color(0.05, 0.04, 0.05, 0.85)
	h.size = Vector2(6, 6)
	h.global_position = at
	h.z_index = 2
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(h)
	else:
		add_child(h)


func named_slowmo() -> void:
	if get_tree().get_first_node_in_group("chase_crash"):
		return
	if get_tree().get_first_node_in_group("snap_director") and Engine.time_scale <= WORLD_SNAP:
		return
	slowmo(0.32)
	get_tree().create_timer(0.14, true, false, true).timeout.connect(func() -> void:
		restore_time()
	)


func smash_burst(at: Vector2, kind: String) -> void:
	pulse_shake(4.0)
	kill_burst(at, "heavy")
	popup_number(at + Vector2(0, -36), kind.to_upper(), Palette.EDGE)
	play("res://assets/audio/smash.wav" if ResourceLoader.exists("res://assets/audio/smash.wav") else "res://assets/audio/hit_heavy.wav")


func kill_cam(at: Vector2) -> void:
	if get_tree().get_first_node_in_group("chase_crash"):
		return
	pulse_shake(10.0)
	shout("KILL CAM")
	popup_number(at + Vector2(0, -70), "KILL CAM", Palette.BRICK)
	play("res://assets/audio/finish.wav")
	freeze_frames(5)


func toaster_pop(rank: String) -> void:
	if rank == "":
		return
	play("res://assets/audio/combo_son.wav" if ResourceLoader.exists("res://assets/audio/combo_son.wav") else "res://assets/audio/claim.wav")
	shout(rank)
	popup_number(Vector2(640, 220), rank, Palette.LEMON)


func revenge_flash(at: Vector2) -> void:
	pulse_shake(6.0)
	sparks(at + Vector2(0, -24))
	kill_burst(at, "heavy")
	popup_number(at + Vector2(0, -48), Copy.REVENGE, Palette.BRICK)
	play("res://assets/audio/revenge.wav" if ResourceLoader.exists("res://assets/audio/revenge.wav") else "res://assets/audio/hit_heavy.wav")
	freeze_frames(3)


func clash(at: Vector2) -> void:
	if get_tree().get_first_node_in_group("chase_crash"):
		pulse_shake(4.0)
		sparks(at)
		play("res://assets/audio/clash.wav" if ResourceLoader.exists("res://assets/audio/clash.wav") else "res://assets/audio/parry.wav")
		return
	freeze_frames(4)
	pulse_shake(7.0)
	sparks(at + Vector2(0, -20))
	popup_number(at + Vector2(0, -48), Copy.CLASH, Palette.LEMON)
	play("res://assets/audio/clash.wav" if ResourceLoader.exists("res://assets/audio/clash.wav") else "res://assets/audio/parry.wav")


func catch_flash(at: Vector2) -> void:
	pulse_shake(3.5)
	sparks(at)
	popup_number(at + Vector2(0, -36), Copy.CATCH, Palette.EDGE)
	play("res://assets/audio/catch.wav" if ResourceLoader.exists("res://assets/audio/catch.wav") else "res://assets/audio/throw.wav")


func geyser(at: Vector2) -> void:
	pulse_shake(4.5)
	var p := CPUParticles2D.new()
	p.global_position = at
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = 18
	p.lifetime = 0.38
	p.direction = Vector2(0, -1)
	p.spread = 28.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 280.0
	p.color = Color(0.45, 0.78, 0.92, 0.9)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	get_tree().create_timer(0.5, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)
	play("res://assets/audio/geyser.wav" if ResourceLoader.exists("res://assets/audio/geyser.wav") else "res://assets/audio/splash.wav")
	popup_number(at + Vector2(0, -40), Copy.GEYSER, Color(0.45, 0.78, 0.92))


func boom(at: Vector2) -> void:
	if get_tree().get_first_node_in_group("chase_crash"):
		pulse_shake(6.0)
		sparks(at)
		play("res://assets/audio/boom.wav" if ResourceLoader.exists("res://assets/audio/boom.wav") else "res://assets/audio/smash.wav")
		popup_number(at + Vector2(0, -40), Copy.BARREL, Palette.BRICK)
		return
	freeze_frames(3)
	pulse_shake(9.0)
	var p := CPUParticles2D.new()
	p.global_position = at
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.32
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 340.0
	p.color = Color(0.92, 0.42, 0.12, 0.95)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	get_tree().create_timer(0.45, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)
	play("res://assets/audio/boom.wav" if ResourceLoader.exists("res://assets/audio/boom.wav") else "res://assets/audio/smash.wav")
	popup_number(at + Vector2(0, -48), Copy.BARREL, Palette.BRICK)
	kill_burst(at, "heavy")


func hood(at: Vector2) -> void:
	if get_tree().get_first_node_in_group("chase_crash"):
		pulse_shake(3.5)
		sparks(at)
		play("res://assets/audio/hood.wav" if ResourceLoader.exists("res://assets/audio/hood.wav") else "res://assets/audio/dash.wav")
		popup_number(at + Vector2(0, -36), Copy.HOOD, Palette.LEMON)
		return
	pulse_shake(4.5)
	var p := CPUParticles2D.new()
	p.global_position = at
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.88
	p.amount = 18
	p.lifetime = 0.28
	p.direction = Vector2(0, -1)
	p.spread = 42.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 240.0
	p.color = Color(0.92, 0.78, 0.28, 0.9)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	get_tree().create_timer(0.42, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)
	play("res://assets/audio/hood.wav" if ResourceLoader.exists("res://assets/audio/hood.wav") else "res://assets/audio/dash.wav")
	popup_number(at + Vector2(0, -40), Copy.HOOD, Palette.LEMON)


func siren() -> void:
	play("res://assets/audio/siren.wav" if ResourceLoader.exists("res://assets/audio/siren.wav") else "res://assets/audio/heat_up.wav")


func phase_flicker(node: CanvasItem) -> void:
	if node == null:
		return
	var original := node.modulate
	node.modulate = Color(original.r, original.g, original.b, 0.12)
	play("res://assets/audio/sfx_phase.wav" if ResourceLoader.exists("res://assets/audio/sfx_phase.wav") else "res://assets/audio/dash.wav")
	get_tree().create_timer(0.06, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.modulate = Color(original.r * 1.15, original.g * 1.1, original.b * 0.85, 1.0)
	)
	get_tree().create_timer(0.14, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.modulate = original
	)


func yellow_stare(at: Vector2) -> void:
	pulse_shake(3.5)
	popup_number(at + Vector2(0, -56), "STARE", Color(0.95, 0.86, 0.12))
	var p := CPUParticles2D.new()
	p.global_position = at + Vector2(0, -70)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 10
	p.lifetime = 0.32
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.color = Color(0.95, 0.86, 0.12, 0.9)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	get_tree().create_timer(0.45, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)


func gape(at: Vector2) -> void:
	pulse_shake(5.0)
	popup_number(at + Vector2(0, -44), "GAPE", Color(0.55, 0.12, 0.14))
	play("res://assets/audio/sfx_gape.wav" if ResourceLoader.exists("res://assets/audio/sfx_gape.wav") else "res://assets/audio/hit_heavy.wav")
	var p := CPUParticles2D.new()
	p.global_position = at + Vector2(0, -40)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 14
	p.lifetime = 0.28
	p.direction = Vector2(0, 1)
	p.spread = 30.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 70.0
	p.color = Color(0.28, 0.06, 0.08, 0.9)
	var host := get_tree().get_first_node_in_group("dock_world")
	if host:
		host.add_child(p)
	else:
		add_child(p)
	get_tree().create_timer(0.42, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)


func whistle(at: Vector2) -> void:
	play("res://assets/audio/sfx_whistle.wav" if ResourceLoader.exists("res://assets/audio/sfx_whistle.wav") else "res://assets/audio/ui_click.wav")
	popup_number(at + Vector2(0, -36), "WHISTLE", Palette.MUTED)


func help_call(at: Vector2) -> void:
	play("res://assets/audio/sfx_help_call.wav" if ResourceLoader.exists("res://assets/audio/sfx_help_call.wav") else "res://assets/audio/vo_son.wav")
	popup_number(at + Vector2(0, -48), "HELP", Color(0.78, 0.72, 0.62))
	pulse_shake(2.5)


func slip(at: Vector2) -> void:
	pulse_shake(7.0)
	freeze_frames(3)
	play("res://assets/audio/sfx_phase.wav" if ResourceLoader.exists("res://assets/audio/sfx_phase.wav") else "res://assets/audio/sting_boss.wav")
	popup_number(at + Vector2(0, -70), Copy.THAT_WALKER, Color(0.95, 0.86, 0.12))
	kill_burst(at, "heavy")

