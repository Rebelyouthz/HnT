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
var _pause: Control
var son: Fighter
var father: Fighter
var state: RunState


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
	_lives.position = Vector2(520, 8)
	_lives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lives.size = Vector2(240, 24)
	UiKit.apply_label(_lives, 16, Palette.TEXT)
	add_child(_lives)

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
	_hint.text = "SON  WASD  SPACE jump/glide  J light  K heavy  L cape  O batwing  SHIFT dash  F SNAP  ·  DAD  arrows  CTRL jump  . / ; web  ' snare  ALT dash  N SNAP"
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
	son = p_son
	father = p_dad
	state = p_state


func _process(_delta: float) -> void:
	_fps.text = "FPS %d" % int(Engine.get_frames_per_second())
	if son:
		var kit := "BATWING %d" % son.ammo
		_son.text = "%s\nTHE SON   HP %d  STEAM %d  %s" % [
			FamilyProfile.son_name(), son.hp, int(son.steam), kit
		]
		_steam_a.size.x = 220.0 * (son.steam / Fighter.STEAM_MAX)
		_place_snap(_snap_a, son)
	if father:
		var kit := "WEB SHOT %d" % father.ammo
		_dad.text = "%s\nTHE FATHER   HP %d  STEAM %d  %s" % [
			FamilyProfile.father_name(), father.hp, int(father.steam), kit
		]
		_steam_b.size.x = 220.0 * (father.steam / Fighter.STEAM_MAX)
		_place_snap(_snap_b, father)
	var life_n := 3
	if state:
		life_n = state.lives
	var stamps := ""
	for i in 3:
		stamps += "[  ] " if i < life_n else "[x] "
	_lives.text = "LIVES  " + stamps
	_combo.text = "" if Juice.combo < 2 else "%d HIT" % Juice.combo
	_call.text = Juice.callout
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		_toggle_pause()


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
		FamilyProfile.mark_run_finished()
		App.back_to_hub("awards")
	)
	col.add_child(end)
