extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.chrome())
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -360
	card.offset_right = 360
	card.offset_top = -260
	card.offset_bottom = 260
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(44, 44)
	head.add_child(mark)
	var h := Label.new()
	h.text = Copy.FRIDGE
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Gold in. Feelings out. Packed snacks ride into the next run. The clipboard still bills the calories."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	var packed := str(FamilyProfile.data.get("snack_buff", ""))
	var packed_l := Label.new()
	packed_l.text = "PACKED  ·  %s" % (packed.to_upper() if packed != "" else "EMPTY. SHOCKING.")
	UiKit.apply_label(packed_l, 15, Palette.EDGE if packed != "" else Palette.MUTED)
	col.add_child(packed_l)
	for row in [
		{"id": "bandage", "title": "BLOOD ORANGE TAPE", "blurb": "Auto-bandage at 30% next run.", "gold": 12},
		{"id": "tape", "title": "INTAKE ICE", "blurb": "Four seconds of street armor on spawn.", "gold": 18},
		{"id": "steam", "title": "LEMON FIZZ", "blurb": "Spawn with a full Steam tank.", "gold": 10},
		{"id": "boost", "title": "TUTORING BAR", "blurb": "Next run starts with trick speed.", "gold": 8}
	]:
		col.add_child(_snack(row))
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()
	card.pivot_offset = Vector2(360, 260)
	UiKit.pop_in(card)


func _snack(info: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	var row := HBoxContainer.new()
	p.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = str(info["title"])
	UiKit.apply_label(t, 16, Palette.LEMON)
	v.add_child(t)
	var b := Label.new()
	b.text = str(info["blurb"])
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 12, Palette.TEXT)
	v.add_child(b)
	row.add_child(v)
	var buy := UiKit.button("%d GOLD" % int(info["gold"]), Vector2(140, 40))
	buy.pressed.connect(func() -> void:
		if FamilyProfile.buy_snack(str(info["id"]), int(info["gold"])):
			Juice.claim_burst(get_viewport_rect().size * 0.5, "PACKED  ·  %s" % str(info["title"]), 0, 0)
			VoBank.fridge()
			need_refresh.emit()
			closed.emit()
			queue_free()
		else:
			Juice.shout("THE FRIDGE DOES NOT TAKE IOUS")
	)
	row.add_child(buy)
	return p
