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
	card.offset_top = -220
	card.offset_bottom = 220
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(44, 44)
	head.add_child(mark)
	var h := Label.new()
	h.text = Copy.TIP_JAR
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Five gold. Toss it. Sometimes a gem. Sometimes a snack. Sometimes the jar eats it and thanks you for the civic engagement. The clipboard still wants a receipt."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	col.add_child(s)
	var n := Label.new()
	n.text = "TIPS TOSSED  ·  %d" % int(FamilyProfile.data.get("tips", 0))
	UiKit.apply_label(n, 15, Palette.EDGE)
	col.add_child(n)
	var gold := int(FamilyProfile.data.get("gold", 0))
	var toss := UiKit.button("TOSS 5 GOLD" if gold >= 5 else "THE JAR DOES NOT TAKE IOUS", Vector2(280, 52))
	if gold < 5:
		toss.disabled = true
	else:
		toss.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.pulse_ready(toss)
	toss.pressed.connect(func() -> void:
		var pay: Dictionary = FamilyProfile.toss_tip()
		if pay.is_empty():
			Juice.shout("THE JAR DOES NOT TAKE IOUS")
			return
		Juice.claim_burst(get_viewport_rect().size * 0.5, str(pay.get("line", "TIPPED")), int(pay.get("gold", 0)), int(pay.get("gems", 0)))
		VoBank.tip()
		need_refresh.emit()
		closed.emit()
		queue_free()
	)
	col.add_child(toss)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	toss.grab_focus()
	card.pivot_offset = Vector2(320, 220)
	UiKit.pop_in(card)
