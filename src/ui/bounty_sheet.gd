extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	FamilyProfile.mark_seen("bounty")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var chrome := ChromePanel.new()
	chrome.set_anchors_preset(Control.PRESET_FULL_RECT)
	chrome.modulate.a = 0.18
	add_child(chrome)
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
	h.text = Copy.BOUNTY
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var s := Label.new()
	s.text = "Street contracts. Claim is required. The radio will lie about who hired you."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/bounties.json"))
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
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	if FamilyProfile.is_unseen("bounty_%s" % id):
		row.add_child(UiKit.new_dot())
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(info.get("title", "")), Rarity.label(rarity)]
	UiKit.apply_label(t, 16, Rarity.color(rarity))
	var b := Label.new()
	b.text = "%s\nPROGRESS  %d / %d  ·  +%dG  ·  +%d XP" % [
		str(info.get("blurb", "")),
		FamilyProfile.bounty_progress(id),
		int(info.get("need", 1)),
		int(info.get("gold", 0)),
		int(info.get("xp", 0))
	]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	v.add_child(t)
	v.add_child(b)
	row.add_child(v)
	var claimed := FamilyProfile.bounty_claimed(id)
	var go := UiKit.button("FILED" if claimed else "CLAIM", Vector2(120, 40))
	go.disabled = claimed or not FamilyProfile.bounty_ready(id)
	if not go.disabled:
		UiKit.pulse_ready(go)
	go.pressed.connect(func() -> void:
		if FamilyProfile.claim_bounty(id):
			FamilyProfile.mark_seen("bounty_%s" % id)
			need_refresh.emit()
			closed.emit()
			queue_free()
	)
	row.add_child(go)
	return p
