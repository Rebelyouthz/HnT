class_name CardPick
extends CanvasLayer

signal picked(id: String)

var _done := false
var _timer := 12.0
var _clock: Label
var ids: Array = []
var _row: HBoxContainer
var _table: Array = []
var _reroll_btn: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	Juice.set_world_scale(0.12)
	Juice.play("res://assets/audio/card.wav")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if typeof(parsed) == TYPE_ARRAY:
		_table = parsed
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_clock = Label.new()
	_clock.position = Vector2(480, 88)
	_clock.size = Vector2(320, 40)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_clock, 18, Palette.LEMON)
	add_child(_clock)
	_row = HBoxContainer.new()
	_row.position = Vector2(40, 140)
	_row.add_theme_constant_override("separation", 16)
	add_child(_row)
	if ids.is_empty():
		for c in _table:
			if bool(c.get("fixed", false)):
				ids.append(c["id"])
	_paint_cards()
	var tools := HBoxContainer.new()
	tools.position = Vector2(360, 430)
	tools.add_theme_constant_override("separation", 14)
	add_child(tools)
	var skip := UiKit.button(Copy.SKIP, Vector2(240, 44))
	skip.pressed.connect(func() -> void:
		_choose("skip")
	)
	tools.add_child(skip)
	_reroll_btn = UiKit.button(Copy.REROLL, Vector2(200, 44))
	_reroll_btn.pressed.connect(_reroll)
	tools.add_child(_reroll_btn)
	_sync_reroll()
	var note := Label.new()
	note.position = Vector2(180, 500)
	note.size = Vector2(920, 48)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "World is slow. Enemies are not paused. Die in the menu. That's the bit. Border is rarity. Legendary shouts. Skip banks nothing."
	UiKit.apply_label(note, 14, Palette.MUTED)
	add_child(note)
	_focus_middle()


func _paint_cards() -> void:
	for c in _row.get_children():
		c.queue_free()
	for i in mini(3, ids.size()):
		var card: Dictionary = {}
		for c in _table:
			if str(c["id"]) == str(ids[i]):
				card = c
				break
		_row.add_child(_card(card, i == 1))


func _focus_middle() -> void:
	if _row.get_child_count() >= 2:
		var b := _row.get_child(1).find_child("Pick", true, false)
		if b is Button:
			(b as Button).grab_focus()


func _border_for(rarity: String, mid: bool) -> Color:
	var c := Rarity.color(rarity)
	if Rarity.normalize(rarity) == "common" and not mid:
		return Palette.MUTED
	return c


func _card(info: Dictionary, mid: bool) -> Control:
	var rarity := Rarity.normalize(str(info.get("rarity", "common")))
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(360, 270)
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), _border_for(rarity, mid)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	wrap.add_child(col)
	var head := HBoxContainer.new()
	var stamp := StampMark.new()
	stamp.accent = Rarity.color(rarity)
	head.add_child(stamp)
	var t := Label.new()
	t.text = str(info.get("name", "?"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.apply_label(t, 18, Rarity.color(rarity) if Rarity.rank(rarity) >= 2 else Palette.LEMON)
	head.add_child(t)
	col.add_child(head)
	var b := Label.new()
	b.text = str(info.get("blurb", ""))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(320, 0)
	UiKit.apply_label(b, 13, Palette.TEXT)
	col.add_child(b)
	col.add_child(StatPanel.new([
		{"name": "TAG", "value": str(info.get("tag", "RULE")), "color": Palette.LEMON},
		{"name": "RARITY", "value": Rarity.label(rarity), "color": Rarity.color(rarity)},
		{"name": "IF YOU TAKE IT", "value": "RULE STAYS THE RUN", "color": Palette.READY}
	]))
	var go := UiKit.button("TAKE IT", Vector2(160, 44))
	go.name = "Pick"
	go.pressed.connect(func() -> void:
		_choose(str(info.get("id", "")))
	)
	col.add_child(go)
	if mid:
		UiKit.pulse_ready(go)
	if Rarity.rank(rarity) >= 3:
		wrap.scale = Vector2(0.92, 0.92)
		var tw := wrap.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(wrap, "scale", Vector2.ONE, 0.22)
	return wrap


func _sync_reroll() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	var n := 0
	if rs:
		n = int(rs.get("rerolls"))
	_reroll_btn.disabled = n <= 0
	_reroll_btn.text = Copy.REROLL if n <= 0 else "%s  x%d" % [Copy.REROLL, n]


func _reroll() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs == null or int(rs.get("rerolls")) <= 0:
		return
	rs.set("rerolls", int(rs.get("rerolls")) - 1)
	var owned: Array = []
	var cards_v: Variant = rs.get("cards")
	if typeof(cards_v) == TYPE_ARRAY:
		owned = (cards_v as Array).duplicate()
	var pool: Array = []
	for c in _table:
		var cid := str(c["id"])
		if owned.has(cid):
			continue
		pool.append(cid)
	pool.shuffle()
	ids = pool.slice(0, 3)
	Juice.play("res://assets/audio/card.wav")
	Juice.shout("SECOND OPINION")
	_paint_cards()
	_sync_reroll()
	_focus_middle()


func _process(delta: float) -> void:
	_timer -= delta / maxf(Engine.time_scale, 0.01)
	_clock.text = "PICK A RULE  ·  %.0f" % maxf(0.0, _timer)
	if _timer <= 0.0 and not _done:
		if ids.size() >= 2:
			_choose(str(ids[1]))
		elif ids.size() == 1:
			_choose(str(ids[0]))
		else:
			_choose("skip")


func _choose(id: String) -> void:
	if _done:
		return
	_done = true
	Juice.set_world_scale(1.0)
	picked.emit(id)
	queue_free()
