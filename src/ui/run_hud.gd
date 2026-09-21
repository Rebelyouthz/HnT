extends CanvasLayer

var _fps: Label
var _son: Label
var _dad: Label
var _lives: Label
var _call: Label
var _combo: Label
var _hint: Label
var _snap_a: Label
var _snap_b: Label
var _steam_a: ColorRect
var _steam_b: ColorRect
var _scrap: Label
var _wanted: Label
var _pause: Control
var son: Fighter
var father: Fighter
var state: RunState
var _join_grace := 0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fps = Label.new()
	_fps.position = Vector2(12, 6)
	UiKit.apply_label(_fps, 14, Palette.LEMON)
	add_child(_fps)

	_son = Label.new()
	_son.position = Vector2(12, 28)
	UiKit.apply_label(_son, 15, Palette.LEMON)
	add_child(_son)
	_steam_a = _bar(Vector2(12, 78), Palette.LEMON)

	_dad = Label.new()
	_dad.position = Vector2(900, 28)
	_dad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dad.size = Vector2(368, 48)
	UiKit.apply_label(_dad, 15, Palette.BRICK)
	add_child(_dad)
	_steam_b = _bar(Vector2(1048, 78), Palette.BRICK)

	_lives = Label.new()
	_lives.position = Vector2(500, 8)
	_lives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lives.size = Vector2(280, 24)
	UiKit.apply_label(_lives, 16, Palette.TEXT)
	add_child(_lives)

	_scrap = Label.new()
	_scrap.position = Vector2(500, 56)
	_scrap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scrap.size = Vector2(280, 20)
	UiKit.apply_label(_scrap, 14, Palette.EDGE)
	add_child(_scrap)

	_wanted = Label.new()
	_wanted.position = Vector2(820, 8)
	UiKit.apply_label(_wanted, 13, Palette.BRICK)
	add_child(_wanted)

	_combo = Label.new()
	_combo.position = Vector2(560, 36)
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo.size = Vector2(160, 24)
	UiKit.apply_label(_combo, 18, Palette.EDGE)
	add_child(_combo)

	_call = Label.new()
	_call.position = Vector2(280, 90)
	_call.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_call.size = Vector2(720, 40)
	UiKit.apply_label(_call, 26, Palette.LEMON)
	add_child(_call)

	_snap_a = _snap_lab()
	_snap_b = _snap_lab()

	_hint = Label.new()
	_hint.position = Vector2(12, 668)
	_hint.size = Vector2(1250, 44)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 13, Palette.MUTED)
	_hint.text = _prompt_line()
	add_child(_hint)


func _bar(pos: Vector2, color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = Vector2(220, 8)
	bg.color = Color(0, 0, 0, 0.55)
	add_child(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size = Vector2(220, 8)
	fill.color = color
	add_child(fill)
	return fill


func _snap_lab() -> Label:
	var l := Label.new()
	l.text = "SNAP"
	l.visible = false
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.apply_label(l, 22, Color(0.86, 0.92, 1.0))
	add_child(l)
	return l


func bind(p_son: Fighter, p_dad: Fighter, p_state: RunState = null) -> void:
	var joining := (p_dad != null and father == null) or (p_son != null and son == null)
	son = p_son
	father = p_dad
	state = p_state
	if joining:
		_join_grace = 18


func _prompt_line() -> String:
	if son == null or father == null:
		return PadRouter.p1_prompt() + "  ·  " + Copy.JOIN_HINT
	return PadRouter.p1_prompt() + "  ·  " + PadRouter.p2_prompt()


func _process(_delta: float) -> void:
	if _join_grace > 0:
		_join_grace -= 1
	_fps.text = "FPS %d" % int(Engine.get_frames_per_second())
	var left: Fighter = son if son else father
	var right: Fighter = father if son else null
	_paint_fighter(_son, _steam_a, _snap_a, left, left != null and left.role == "son")
	_paint_fighter(_dad, _steam_b, _snap_b, right, false)
	var life_n := 3
	if state:
		life_n = state.lives
	var stamps := ""
	for i in 3:
		stamps += "[  ] " if i < life_n else "[x] "
	_lives.text = "LIVES  " + stamps
	_combo.text = "" if Juice.combo < 2 else "%d HIT" % Juice.combo
	_call.text = Juice.callout
	if state:
		_scrap.text = "SCRAP  %d   XP  %d" % [state.scrap, state.xp]
		var w := ""
		for i in 5:
			w += "I" if i < state.wanted else "."
		_wanted.text = "" if state.wanted == 0 else "WANTED  " + w
	_hint.text = _prompt_line()
	if _join_grace > 0:
		return
	if Input.is_action_just_pressed("p1_pause"):
		_toggle_pause()
	elif Input.is_action_just_pressed("p2_pause") and father != null and son != null:
		_toggle_pause()


func _paint_fighter(lab: Label, bar: ColorRect, snap: Label, f: Fighter, lemon_slot: bool) -> void:
	if f == null or not is_instance_valid(f):
		lab.text = ""
		bar.size.x = 0
		snap.visible = false
		return
	var kit := ("BATWING %d" % f.ammo) if f.role == "son" else ("WEB SHOT %d" % f.ammo)
	var title := FamilyProfile.son_name() if f.role == "son" else FamilyProfile.father_name()
	var role := "THE SON" if f.role == "son" else "THE FATHER"
	lab.text = "%s\n%s   HP %d  STEAM %d  %s" % [title, role, f.hp, int(f.steam), kit]
	if lemon_slot:
		lab.add_theme_color_override("font_color", Palette.LEMON)
	else:
		lab.add_theme_color_override("font_color", Palette.BRICK)
	bar.size.x = 220.0 * (f.steam / Fighter.STEAM_MAX)
	_place_snap(snap, f)


func _place_snap(lab: Label, f: Fighter) -> void:
	lab.visible = f.snap_ready and not f.downed
	if not lab.visible:
		return
	var cam := get_viewport().get_camera_2d()
	var gp := f.global_position + Vector2(0, -110)
	if cam:
		lab.position = cam.get_screen_transform() * gp + Vector2(-28, 0)
	else:
		lab.position = gp


func _toggle_pause() -> void:
	if _pause and is_instance_valid(_pause):
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		return
	get_tree().paused = true
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_pause = layer
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var col := VBoxContainer.new()
	col.position = Vector2(480, 220)
	col.add_theme_constant_override("separation", 12)
	layer.add_child(col)
	var t := Label.new()
	t.text = Copy.PAUSE
	UiKit.apply_label(t, 28, Palette.LEMON)
	col.add_child(t)
	var r := UiKit.button("RESUME", Vector2(220, 48))
	r.process_mode = Node.PROCESS_MODE_ALWAYS
	r.pressed.connect(_toggle_pause)
	col.add_child(r)
	var end := UiKit.button("END SESSION", Vector2(220, 48))
	end.process_mode = Node.PROCESS_MODE_ALWAYS
	end.pressed.connect(func() -> void:
		get_tree().paused = false
		FamilyProfile.mark_run_finished(false)
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		App.back_to_hub("awards")
	)
	col.add_child(end)
	if state:
		col.add_child(StatPanel.new([
			{"name": "LIVES", "value": str(state.lives), "color": Palette.READY},
			{"name": "SCRAP", "value": str(state.scrap), "color": Palette.EDGE},
			{"name": "XP", "value": str(state.xp), "color": Palette.LEMON},
			{"name": "WANTED", "value": str(state.wanted), "color": Palette.BRICK},
			{"name": "MODE", "value": "COUCH" if App.density_coop else "SOLO", "color": Palette.TEXT}
		]))
	r.grab_focus()
