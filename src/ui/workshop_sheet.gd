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
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -400
	card.offset_right = 400
	card.offset_top = -280
	card.offset_bottom = 280
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(780, 540)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var head := HBoxContainer.new()
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(48, 48)
	head.add_child(mark)
	head.add_child(UiKit.portrait(SpriteBook.icon("workshop"), Vector2(56, 56)))
	var h := Label.new()
	h.text = Copy.WORKSHOP
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Parts, coils, thread, ink. Gear and clothes are one character. Crafting is homework you can sell."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	col.add_child(StatPanel.new([
		{"name": "COIL", "value": str(FamilyProfile.part_n("scrap_coil")), "color": Palette.EDGE},
		{"name": "THREAD", "value": str(FamilyProfile.part_n("clinic_thread")), "color": Palette.LEMON},
		{"name": "INK", "value": str(FamilyProfile.part_n("invoice_ink")), "color": Palette.BRICK}
	]))
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/crafts.json"))
	for row in table:
		if typeof(row) == TYPE_DICTIONARY:
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
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	var stamp := StampMark.new()
	stamp.accent = Rarity.color(rarity)
	row.add_child(stamp)
	if FamilyProfile.is_unseen("craft_%s" % id):
		row.add_child(UiKit.new_dot())
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(info.get("title", "")), Rarity.label(rarity)]
	UiKit.apply_label(t, 16, Rarity.color(rarity))
	var need: Dictionary = info.get("parts", {})
	var parts_bits: PackedStringArray = PackedStringArray()
	for k in need.keys():
		parts_bits.append("%s %d" % [str(k).replace("_", " ").to_upper(), int(need[k])])
	var got := Label.new()
	got.text = "GET  ·  %s  ·  %s" % [str(info.get("grant", "")), " ".join(parts_bits)]
	UiKit.apply_label(got, 12, Palette.LEMON)
	var b := Label.new()
	b.text = str(info.get("blurb", ""))
	if FamilyProfile.has_craft(id):
		b.text = "OWNED  ·  " + b.text
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	v.add_child(t)
	v.add_child(got)
	v.add_child(b)
	row.add_child(v)
	var go := UiKit.button("CRAFT  %dG" % int(info.get("gold", 0)), Vector2(150, 40))
	if FamilyProfile.has_craft(id):
		go.text = "OWNED"
		go.disabled = true
	elif int(FamilyProfile.data.get("gold", 0)) < int(info.get("gold", 0)):
		go.disabled = true
		go.text = "NEED %d GOLD" % int(info.get("gold", 0))
	else:
		for k in need.keys():
			if FamilyProfile.part_n(str(k)) < int(need[k]):
				go.disabled = true
				go.text = "NEED PARTS"
				break
	go.pressed.connect(func() -> void:
		if FamilyProfile.try_craft(id):
			FamilyProfile.mark_seen("craft_%s" % id)
			need_refresh.emit()
			queue_free()
			closed.emit()
		else:
			Juice.shout("PARTS. GOLD. A PERSONALITY.")
	)
	row.add_child(go)
	return p
