extends Control

signal need_refresh

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
	s.text = "Same couch. Same camera. The landlord has throwing stars."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 15, Palette.MUTED)
	col.add_child(s)

	var diff := HBoxContainer.new()
	diff.add_theme_constant_override("separation", 8)
	for pair in [["open_house", "OPEN HOUSE"], ["night_class", "NIGHT CLASS"], ["finals", "FINALS"]]:
		var b := UiKit.button(pair[1], Vector2(180, 44))
		if App.difficulty == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			App.difficulty = pair[0]
			need_refresh.emit()
		)
		diff.add_child(b)
	col.add_child(diff)

	var go := UiKit.button(Copy.PLAY, Vector2(320, 56))
	go.pressed.connect(App.start_run)
	col.add_child(go)

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

	var hint := Label.new()
	hint.text = "P1 keyboard, P2 pad or arrows. Light is a red flash. Heavy is the conversation. Roofs need a fire escape, a cape, or a web — the jump is too honest."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(hint, 14, Palette.TEXT)
	col.add_child(hint)
