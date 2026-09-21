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
	var s := Label.new()
	s.text = "Starts now. The other chair is optional. Drop-in does not restock the street."
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

	_counts = StatPanel.new(_count_rows())
	col.add_child(_counts)

	_go = UiKit.button(Copy.GO_SOLO if not App.couch else Copy.GO_COUCH, Vector2(360, 56))
	_go.pressed.connect(App.start_run)
	col.add_child(_go)

	var net := HBoxContainer.new()
	var host := UiKit.button(Copy.HOST, Vector2(240, 48))
	var join := UiKit.button(Copy.JOIN, Vector2(240, 48))
	host.pressed.connect(func() -> void:
		Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.HOST_HINT, 0, 0)
	)
	join.pressed.connect(func() -> void:
		Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.HOST_HINT, 0, 0)
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
		_role_row.add_child(b)


func _count_rows() -> Array:
	return [
		{"name": "SOLO PUNKS", "value": str(Party.count_for("dock_street", false)), "color": Palette.LEMON},
		{"name": "COUCH PUNKS", "value": str(Party.count_for("dock_street", true)), "color": Palette.BRICK},
		{"name": "MAP 2 SOLO", "value": str(Party.count_for("fire_escapes", false)), "color": Palette.EDGE},
		{"name": "MAP 2 COUCH", "value": str(Party.count_for("fire_escapes", true)), "color": Palette.BRICK}
	]


func _refresh_copy() -> void:
	if _go:
		_go.text = Copy.GO_COUCH if App.couch else Copy.GO_SOLO
	if _hint:
		_hint.text = (Copy.COUCH_HINT if App.couch else Copy.SOLO_HINT) + "  " + Copy.JOIN_HINT + "  P1 keyboard, P2 pad or arrows after join. Light is a red flash. Heavy is the conversation."
