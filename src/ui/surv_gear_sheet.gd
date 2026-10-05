extends Control

## SURVIVOR GEAR: the four worn slots on top, every piece you own below
## (rarity frame, stats, level). WEAR / LEVEL UP (S-COINS) / FUSE (three of
## a kind into the next rarity), and a GEAR BOX for S-COINS.

signal closed

var _focus_key := ""


func _ready() -> void:
	_paint()


func _paint() -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Color(0.3, 0.9, 0.6), 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -600
	card.offset_right = 600
	card.offset_top = -340
	card.offset_bottom = 340
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	var t := UiKit.title("SURVIVOR GEAR", 28, Color(0.4, 1.0, 0.7))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var wallet := Label.new()
	wallet.text = "S-COINS %d   " % int(FamilyProfile.data.get("tokens", 0))
	UiKit.apply_label(wallet, 16, Color(0.5, 1.0, 0.75))
	head.add_child(wallet)
	var box := _btn("GEAR BOX  %d S-COINS" % SurvGear.BOX_PRICE, Vector2(220, 36), "box")
	box.disabled = int(FamilyProfile.data.get("tokens", 0)) < SurvGear.BOX_PRICE
	box.pressed.connect(func() -> void:
		if not SurvGear.buy_box().is_empty():
			Juice.play("res://assets/audio/chest.wav")
			_focus_key = "box"
			_paint()
	)
	head.add_child(box)
	var close := _btn("CLOSE", Vector2(110, 36), "close")
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	col.add_child(head)
	var sub := Label.new()
	sub.text = "Worn into every survivor hour. Pieces drop from hours past 2:00, elite chests and wins. Three of the same piece and rarity FUSE into the next rarity."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(1160, 0)
	UiKit.apply_label(sub, 12, Palette.MUTED)
	col.add_child(sub)
	# Worn slots.
	var worn_row := HBoxContainer.new()
	worn_row.add_theme_constant_override("separation", 10)
	col.add_child(worn_row)
	var w := SurvGear.worn()
	for slot in SurvGear.SLOTS:
		var p := SurvGear.piece(int(w.get(slot, -1))) if w.has(slot) else {}
		worn_row.add_child(_tile(slot, p, -1, true))
	# Totals.
	var tot: Array[String] = []
	for k in SurvGear.STAT_NAME:
		var v := SurvGear.stat(str(k))
		if v > 0.0:
			tot.append(("+%d %s" % [int(round(v)), SurvGear.STAT_NAME[k]]) if k == "hp" else ("+%d%% %s" % [int(round(v * 100.0)), SurvGear.STAT_NAME[k]]))
	var tl := Label.new()
	tl.text = "WORN TOTAL  ·  " + ("   ".join(tot) if not tot.is_empty() else "nothing yet")
	UiKit.apply_label(tl, 13, UiKit.GOLD)
	col.add_child(tl)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	var a := SurvGear.inv()
	if a.is_empty():
		var e := Label.new()
		e.text = "No gear yet. Survive past 2:00, open elite chests, or buy a GEAR BOX."
		UiKit.apply_label(e, 14, Palette.MUTED)
		grid.add_child(e)
	for i in a.size():
		var p: Dictionary = a[i]
		grid.add_child(_tile(str(SurvGear.LIST[str(p["id"])]["slot"]), p, i, false))
	UiKit.pop_in(card)
	var want := _focus_key
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and not (b as Button).disabled:
				(b as Button).grab_focus()
				return
		if is_instance_valid(close):
			close.grab_focus()
	, CONNECT_ONE_SHOT)


func _btn(txt: String, sz: Vector2, key: String) -> Button:
	var b := UiKit.button(txt, sz)
	b.add_theme_font_size_override("font_size", 11)
	b.set_meta("key", key)
	return b


func _tile(slot: String, p: Dictionary, idx: int, worn_view: bool) -> Control:
	var rar := SurvGear.rarity_of(p) if not p.is_empty() else "common"
	var rc := Rarity.color(rar)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rar) if not p.is_empty() else Color(0.05, 0.05, 0.08), rc if not p.is_empty() else Palette.MUTED))
	panel.custom_minimum_size = Vector2(285, 120 if worn_view else 132)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	var top := Label.new()
	top.text = SurvGear.SLOT_NAME[slot] + ("  ·  " + Rarity.label(rar) if not p.is_empty() else "  ·  EMPTY")
	UiKit.apply_label(top, 11, rc if not p.is_empty() else Palette.MUTED)
	v.add_child(top)
	if p.is_empty():
		return panel
	var nm := Label.new()
	nm.text = "%s  LV %d" % [str(SurvGear.LIST[str(p["id"])]["name"]), int(p.get("lv", 1))]
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 15, rc.lerp(Color.WHITE, 0.3))
	v.add_child(nm)
	var st := Label.new()
	st.text = SurvGear.line(p)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size = Vector2(265, 0)
	UiKit.apply_label(st, 11, Palette.TEXT)
	v.add_child(st)
	if worn_view:
		return panel
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var w := SurvGear.worn()
	var is_worn := int(w.get(slot, -1)) == idx
	var wb := _btn("WORN" if is_worn else "WEAR", Vector2(70, 28), "wear_%d" % idx)
	wb.disabled = is_worn
	wb.pressed.connect(func() -> void:
		SurvGear.wear(idx)
		Juice.play("res://assets/audio/claim.wav")
		_focus_key = "wear_%d" % idx
		_paint()
	)
	row.add_child(wb)
	var lvl := int(p.get("lv", 1))
	var lb := _btn(("LV+ %d" % SurvGear.lv_price(p)) if lvl < SurvGear.MAX_LV else "MAX", Vector2(90, 28), "lv_%d" % idx)
	lb.disabled = lvl >= SurvGear.MAX_LV or int(FamilyProfile.data.get("tokens", 0)) < SurvGear.lv_price(p)
	lb.pressed.connect(func() -> void:
		if SurvGear.level_up(idx):
			Juice.play("res://assets/audio/claim.wav")
			_focus_key = "lv_%d" % idx
			_paint()
	)
	row.add_child(lb)
	var fb := _btn("FUSE x3", Vector2(90, 28), "fuse_%d" % idx)
	fb.disabled = not SurvGear.can_fuse(idx)
	UiKit.hold_confirm(fb, func() -> void:
		if SurvGear.fuse(idx):
			Rarity.juice(SurvGear.RARITY[mini(4, int(p.get("rar", 0)) + 1)], "FUSED")
			_focus_key = "box"
			_paint()
	)
	row.add_child(fb)
	v.add_child(row)
	return panel
