extends Control

signal need_refresh

var _mode_row: HBoxContainer
var _role_row: HBoxContainer
var _go: Button
var _hint: Label
var _counts: StatPanel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_right", 24)
	add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	m.add_child(col)

	var h := Label.new()
	h.text = "RAVEN WHARF"
	UiKit.apply_label(h, 26, Palette.LEMON)
	col.add_child(h)
	var faces := HBoxContainer.new()
	faces.add_theme_constant_override("separation", 8)
	faces.add_child(UiKit.portrait(SpriteBook.icon("street_map"), Vector2(48, 48)))
	faces.add_child(UiKit.portrait(SpriteBook.tex("res://assets/sprites/father/idle/00.png"), Vector2(48, 48)))
	faces.add_child(UiKit.portrait(SpriteBook.tex("res://assets/sprites/son/idle/00.png"), Vector2(48, 48)))
	col.add_child(faces)
	var s := Label.new()
	s.text = "Starts now. Intro films the first time. Gates play a story film (PAUSE skips the beat). Versus is Father vs Son. Drop-in does not restock the street."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 15, Palette.MUTED)
	col.add_child(s)

	_mode_row = HBoxContainer.new()
	_mode_row.add_theme_constant_override("separation", 8)
	col.add_child(_mode_row)
	_paint_modes()

	_role_row = HBoxContainer.new()
	_role_row.add_theme_constant_override("separation", 8)
	col.add_child(_role_row)
	_paint_roles()

	var diff := HBoxContainer.new()
	diff.add_theme_constant_override("separation", 8)
	for pair in [["open_house", "OPEN HOUSE"], ["night_class", "NIGHT CLASS"], ["finals", "FINALS"]]:
		var b := UiKit.button(pair[1], Vector2(180, 44))
		if App.difficulty == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			App.difficulty = pair[0]
			FamilyProfile.data["difficulty"] = pair[0]
			FamilyProfile.save()
			need_refresh.emit()
		)
		diff.add_child(b)
	col.add_child(diff)
	var diff_hint := Label.new()
	diff_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match App.difficulty:
		"open_house":
			diff_hint.text = Copy.OPEN_HOUSE
		"finals":
			diff_hint.text = Copy.FINALS
		_:
			diff_hint.text = Copy.NIGHT_CLASS
	UiKit.apply_label(diff_hint, 13, Palette.MUTED)
	col.add_child(diff_hint)

	_counts = StatPanel.new(_count_rows())
	col.add_child(_counts)

	_go = UiKit.button(Copy.GO_SOLO if not App.couch else Copy.GO_COUCH, Vector2(360, 56))
	_go.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	UiKit.pulse_ready(_go)
	_bind_go()
	col.add_child(_go)
	var lock_lab := Label.new()
	lock_lab.name = "PowerLock"
	lock_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(lock_lab, 14, Palette.BRICK)
	col.add_child(lock_lab)
	_paint_lock(lock_lab)

	var extra := HBoxContainer.new()
	extra.add_theme_constant_override("separation", 8)
	var intro_b := UiKit.button(Copy.PLAY_INTRO, Vector2(200, 48))
	intro_b.pressed.connect(App.play_intro)
	var vs_b := UiKit.button(Copy.VERSUS, Vector2(200, 48))
	vs_b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	vs_b.pressed.connect(App.start_versus)
	extra.add_child(intro_b)
	extra.add_child(vs_b)
	col.add_child(extra)

	var acts := Label.new()
	acts.text = "1 DOCK  ·  LOT  ·  2 ROOFS  ·  CIRCLE  ·  3 NEON  ·  WAITING  ·  4 RAIL  ·  5 HALL  ·  6 ORCHARD  ·  SLEET  ·  7 GRID (CHASE)  ·  LEDGER  ·  8 PIER  ·  9 FLOOR"
	acts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(acts, 12, Palette.MUTED)
	col.add_child(acts)

	var net := HBoxContainer.new()
	net.add_theme_constant_override("separation", 8)
	var host := UiKit.button(Copy.HOST, Vector2(240, 48))
	var join := UiKit.button(Copy.JOIN, Vector2(240, 48))
	host.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.LEMON))
	join.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.BRICK))
	host.pressed.connect(func() -> void:
		get_tree().root.add_child(preload("res://src/ui/host_wait.gd").new())
	)
	join.pressed.connect(func() -> void:
		get_tree().root.add_child(preload("res://src/ui/join_sheet.gd").new())
	)
	net.add_child(host)
	net.add_child(join)
	col.add_child(net)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 14, Palette.TEXT)
	col.add_child(_hint)
	_refresh_copy()
	_go.grab_focus()


func _paint_modes() -> void:
	for c in _mode_row.get_children():
		c.queue_free()
	for pair in [[false, Copy.SOLO], [true, Copy.COUCH]]:
		var on: bool = App.couch == pair[0]
		var b := UiKit.button(pair[1], Vector2(200, 48))
		if on:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			App.couch = pair[0]
			need_refresh.emit()
		)
		_mode_row.add_child(b)


func _paint_roles() -> void:
	for c in _role_row.get_children():
		c.queue_free()
	_role_row.visible = not App.couch
	if App.couch:
		return
	for pair in [["son", "THE SON"], ["father", "THE FATHER"]]:
		var b := UiKit.button(pair[1], Vector2(200, 44))
		if App.solo_role == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			App.solo_role = pair[0]
			need_refresh.emit()
		)
		var who := str(pair[0])
		_role_row.add_child(UiKit.portrait(SpriteBook.tex("res://assets/sprites/%s/idle/00.png" % who), Vector2(40, 40)))
		_role_row.add_child(b)


func _count_rows() -> Array:
	return [
		{"name": "SOLO PUNKS", "value": str(Party.count_for("dock_street", false)), "color": Palette.LEMON},
		{"name": "COUCH PUNKS", "value": str(Party.count_for("dock_street", true)), "color": Palette.BRICK},
		{"name": "MAP 2 SOLO", "value": str(Party.count_for("fire_escapes", false)), "color": Palette.EDGE},
		{"name": "MAP 3 SOLO", "value": str(Party.count_for("neon_exchange", false)), "color": Palette.LEMON},
		{"name": "MAP 4 SOLO", "value": str(Party.count_for("rail_bridge", false)), "color": Palette.EDGE},
		{"name": "HALL SOLO", "value": str(Party.count_for("city_hall", false)), "color": Palette.BRICK},
		{"name": "PIER SOLO", "value": str(Party.count_for("invoice_pier", false)), "color": Palette.READY},
		{"name": "FLOOR SOLO", "value": str(Party.count_for("processing_floor", false)), "color": Palette.BRICK},
		{"name": "LOT SOLO", "value": str(Party.count_for("intake_lot", false)), "color": Palette.LEMON},
		{"name": "COUCH EACH", "value": str(Party.count_for("dock_street", true)), "color": Palette.TEXT},
		{"name": "ORCHARD SOLO", "value": str(Party.count_for("copay_orchard", false)), "color": Palette.EDGE},
		{"name": "GRID SOLO", "value": str(Party.count_for("raven_grid", false)), "color": Palette.LEMON},
		{"name": "SLEET SOLO", "value": str(Party.count_for("sleet_hour", false)), "color": Palette.TEXT},
		{"name": "LEDGER SOLO", "value": str(Party.count_for("ledger_dive", false)), "color": Palette.READY},
		{"name": "ACTS", "value": "14", "color": Palette.READY},
		{"name": "HOURS", "value": "5", "color": Palette.EDGE},
		{"name": "HOST", "value": "SON", "color": Palette.LEMON},
		{"name": "JOIN", "value": "FATHER", "color": Palette.BRICK}
	]


func _refresh_copy() -> void:
	if _go:
		_go.text = Copy.GO_COUCH if App.couch else Copy.GO_SOLO
		_bind_go()
	if _hint:
		_hint.text = (Copy.COUCH_HINT if App.couch else Copy.SOLO_HINT) + "  " + Copy.JOIN_HINT + "  " + Copy.REMOTE_HINT
	var lock_lab := get_node_or_null("PowerLock") as Label
	if lock_lab == null:
		for c in get_children():
			lock_lab = c.find_child("PowerLock", true, false) as Label
			if lock_lab:
				break
	if lock_lab:
		_paint_lock(lock_lab)


func _bind_go() -> void:
	if _go == null:
		return
	var hop := FamilyProfile.next_run_map()
	var enter_lock := PowerBook.lock(hop, "enter")
	if not enter_lock.is_empty():
		_go.disabled = true
		_go.text = PowerBook.line(enter_lock)
		if _go.pressed.is_connected(App.start_run):
			_go.pressed.disconnect(App.start_run)
	else:
		_go.disabled = false
		if not _go.pressed.is_connected(App.start_run):
			_go.pressed.connect(App.start_run)


func _paint_lock(lab: Label) -> void:
	var hop := FamilyProfile.next_run_map()
	var enter_lock := PowerBook.lock(hop, "enter")
	if not enter_lock.is_empty():
		lab.text = PowerBook.line(enter_lock)
		lab.visible = true
		return
	var boss_lock := PowerBook.lock(hop, "boss")
	if not boss_lock.is_empty():
		lab.text = PowerBook.line(boss_lock)
		lab.visible = true
		return
	lab.text = ""
	lab.visible = false
