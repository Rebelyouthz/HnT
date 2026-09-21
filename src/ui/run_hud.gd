extends CanvasLayer

var _fps: Label
var _son: Label
var _dad: Label
var _pause: Control
var son: Fighter
var father: Fighter


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fps = Label.new()
	_fps.position = Vector2(12, 8)
	UiKit.apply_label(_fps, 14, Palette.LEMON)
	add_child(_fps)

	_son = Label.new()
	_son.position = Vector2(12, 32)
	UiKit.apply_label(_son, 16, Palette.LEMON)
	add_child(_son)

	_dad = Label.new()
	_dad.position = Vector2(900, 32)
	UiKit.apply_label(_dad, 16, Palette.BRICK)
	add_child(_dad)

	var lives := Label.new()
	lives.position = Vector2(560, 10)
	lives.text = "LIVES  [  ]  [  ]  [  ]"
	UiKit.apply_label(lives, 16, Palette.TEXT)
	add_child(lives)

	var hint := Label.new()
	hint.position = Vector2(12, 680)
	hint.text = "A/D move  W/S street  SPACE jump  J light  K heavy  ESC pause"
	UiKit.apply_label(hint, 13, Palette.MUTED)
	add_child(hint)


func bind(p_son: Fighter, p_dad: Fighter) -> void:
	son = p_son
	father = p_dad


func _process(_delta: float) -> void:
	_fps.text = "FPS %d" % int(Engine.get_frames_per_second())
	if son:
		_son.text = "%s\nTHE SON   HP %d  STEAM 100" % [FamilyProfile.son_name(), son.hp]
	if father:
		_dad.text = "%s\nTHE FATHER   HP %d  STEAM 100" % [FamilyProfile.father_name(), father.hp]
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	if _pause and is_instance_valid(_pause):
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		return
	get_tree().paused = true
	_pause = ColorRect.new()
	_pause.color = Color(0, 0, 0, 0.7)
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.process_mode = Node.PROCESS_MODE_ALWAYS
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
	col.position = Vector2(480, 240)
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
