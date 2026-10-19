extends Control

signal closed
signal need_refresh

var _hits := 0
var _left := 8.0
var _live := true
var _dummy: ColorRect
var _lab: Label
var _timer: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.chrome())
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -300
	card.offset_right = 300
	card.offset_top = -250
	card.offset_bottom = 250
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = Copy.BAG
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var s := Label.new()
	s.text = "Eight seconds. LIGHT or click the dummy. Combo toaster lives here too. The dojo still wants tuition."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	_timer = Label.new()
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_timer, 18, Palette.EDGE)
	col.add_child(_timer)
	_dummy = ColorRect.new()
	_dummy.custom_minimum_size = Vector2(220, 120)
	_dummy.color = Palette.BRICK
	_dummy.gui_input.connect(_on_dummy)
	col.add_child(_dummy)
	_lab = Label.new()
	_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_lab, 20, Palette.LEMON)
	col.add_child(_lab)
	var close := UiKit.button("WALK AWAY", Vector2(160, 44))
	close.pressed.connect(func() -> void:
		_cash()
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	card.pivot_offset = Vector2(300, 250)
	UiKit.pop_in(card)
	_paint()
	UiKit.focus_first(self)


func _process(delta: float) -> void:
	if not _live:
		return
	_left -= delta
	if Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p1_heavy"):
		_hit()
	if _left <= 0.0:
		_cash()
		return
	_paint()


func _on_dummy(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_hit()


func _hit() -> void:
	if not _live:
		return
	_hits += 1
	Juice.keep_combo()
	Juice.register_hit("light" if _hits % 3 != 0 else "heavy", Vector2(640, 360), 4)
	KitSfx.jab("son" if _hits % 2 == 0 else "father")
	if _hits % 3 == 0:
		Juice.bam(Vector2(640, 360), "son")
	_dummy.color = Palette.LEMON if _hits % 2 == 0 else Palette.BRICK
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(_dummy, "scale", Vector2(1.08, 0.92), 0.06)
	tw.tween_property(_dummy, "scale", Vector2.ONE, 0.1)
	_paint()


func _paint() -> void:
	_timer.text = "CLOCK  %.1f" % maxf(_left, 0.0)
	_lab.text = "%d HIT  ·  %s" % [_hits, Juice.combo_rank() if _hits >= 2 else "WARM UP"]


func _cash() -> void:
	if not _live:
		return
	_live = false
	var gold := mini(24, maxi(2, _hits / 2))
	FamilyProfile.mark_bag(_hits)
	FamilyProfile.add_gold(gold)
	Juice.cash_out()
	Juice.claim_burst(get_viewport_rect().size * 0.5, "BAG  %d" % _hits, gold, 0)
	need_refresh.emit()
	closed.emit()
