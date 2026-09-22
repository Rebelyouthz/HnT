extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	FamilyProfile.mark_seen("album")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.chrome())
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -380
	card.offset_right = 380
	card.offset_top = -240
	card.offset_bottom = 240
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(740, 460)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var h := Label.new()
	h.text = Copy.ALBUM
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var s := Label.new()
	s.text = "Polaroids instead of just gold. Claim pins them. The fridge still wants a copy."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/album.json"))
	for row in table:
		col.add_child(_row(row))
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()


func _row(info: Dictionary) -> Control:
	var id := str(info.get("id", ""))
	var rarity := Rarity.normalize(str(info.get("rarity", "common")))
	var owned := FamilyProfile.album_has(id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	if FamilyProfile.is_unseen("album_%s" % id):
		row.add_child(UiKit.new_dot())
	var snap := ColorRect.new()
	snap.custom_minimum_size = Vector2(54, 54)
	snap.color = Rarity.color(rarity)
	row.add_child(snap)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(info.get("title", "")), Rarity.label(rarity)]
	UiKit.apply_label(t, 16, Rarity.color(rarity))
	var b := Label.new()
	b.text = str(info.get("blurb", ""))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	v.add_child(t)
	v.add_child(b)
	row.add_child(v)
	var go := UiKit.button("PINNED" if owned else "CLAIM  +%dG" % int(info.get("gold", 0)), Vector2(160, 40))
	go.disabled = owned or not FamilyProfile.album_ready(info)
	if not go.disabled:
		UiKit.pulse_ready(go)
	go.pressed.connect(func() -> void:
		if FamilyProfile.claim_album(info):
			FamilyProfile.mark_seen("album_%s" % id)
			need_refresh.emit()
			closed.emit()
			queue_free()
	)
	row.add_child(go)
	return p
