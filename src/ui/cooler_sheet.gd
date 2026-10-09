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
	card.offset_left = -320
	card.offset_right = 320
	card.offset_top = -210
	card.offset_bottom = 210
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(44, 44)
	head.add_child(mark)
	var h := Label.new()
	h.text = Copy.WATER_COOLER
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Once a day. The water is free. Four gold comes back as gossip. A fizz packs itself for the next spawn. Mayor Raven still drinks from the same tank."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	col.add_child(s)
	var n := Label.new()
	n.text = "CUPS  ·  %d" % int(FamilyProfile.data.get("coolers", 0))
	UiKit.apply_label(n, 15, Palette.EDGE)
	col.add_child(n)
	var drink := UiKit.button("DRINK" if FamilyProfile.cooler_ready() else "TANK'S EMPTY TODAY", Vector2(280, 52))
	if not FamilyProfile.cooler_ready():
		drink.disabled = true
	else:
		UiKit.ready_style(drink)
		UiKit.dark_text(drink)
		UiKit.pulse_ready(drink)
	drink.pressed.connect(func() -> void:
		if FamilyProfile.drink_cooler():
			Juice.claim_burst(get_viewport_rect().size * 0.5, "GOSSIP BILLED", 4, 0)
			Juice.unlock_logo("WATER COOLER", "The water is free. The gossip is billed.", "+4 GOLD")
			VoBank.cooler()
			need_refresh.emit()
			closed.emit()
			queue_free()
		else:
			Juice.shout("THE TANK'S EMPTY TODAY")
	)
	col.add_child(drink)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	drink.grab_focus()
	card.pivot_offset = Vector2(320, 210)
	UiKit.pop_in(card)
