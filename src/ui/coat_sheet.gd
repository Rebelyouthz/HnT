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
	h.text = Copy.COAT_CHECK
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Once a day. Pack intake tape for the next spawn. SoR4 hid bats in barrels. We hide a wrap on a hanger that still wants a copay."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	col.add_child(s)
	var packed := str(FamilyProfile.data.get("snack_buff", ""))
	var n := Label.new()
	n.text = "PACKED  ·  %s" % (packed.to_upper() if packed != "" else "EMPTY HANGER. SHOCKING.")
	UiKit.apply_label(n, 15, Palette.EDGE if packed != "" else Palette.MUTED)
	col.add_child(n)
	var pack := UiKit.button("PACK TAPE" if FamilyProfile.coat_ready() else "ALREADY PACKED TODAY", Vector2(280, 52))
	if not FamilyProfile.coat_ready():
		pack.disabled = true
	else:
		pack.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.pulse_ready(pack)
	pack.pressed.connect(func() -> void:
		if FamilyProfile.claim_coat():
			Juice.claim_burst(get_viewport_rect().size * 0.5, "TAPE PACKED", 0, 0)
			Juice.unlock_logo("COAT CHECK", "A wrap for later. The hanger still wants a copay.", "CAMP  ·  TAPE")
			VoBank.fridge()
			need_refresh.emit()
			closed.emit()
			queue_free()
		else:
			Juice.shout("THE HANGER ALREADY LIED TODAY")
	)
	col.add_child(pack)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	pack.grab_focus()
	card.pivot_offset = Vector2(320, 210)
	UiKit.pop_in(card)
