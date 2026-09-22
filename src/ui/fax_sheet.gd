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
	h.text = Copy.FAX
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Once a day. Fax a complaint to City Hall. Eight gold comes back as a clerical error. Intake ice packs itself for the next spawn. The machine still keeps a carbon copy."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	col.add_child(s)
	var n := Label.new()
	n.text = "FAXES FILED  ·  %d" % int(FamilyProfile.data.get("faxes", 0))
	UiKit.apply_label(n, 15, Palette.EDGE)
	col.add_child(n)
	var fax := UiKit.button("FAX TODAY" if FamilyProfile.fax_ready() else "ALREADY FILED", Vector2(280, 52))
	if not FamilyProfile.fax_ready():
		fax.disabled = true
	else:
		fax.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.pulse_ready(fax)
	fax.pressed.connect(func() -> void:
		if FamilyProfile.fax_today():
			Juice.claim_burst(get_viewport_rect().size * 0.5, "FAX FILED", 8, 0)
			Juice.unlock_logo("WARRANT FAX", "The machine ate it. Tape packed itself.", "+8 GOLD")
			VoBank.fax()
			need_refresh.emit()
			closed.emit()
			queue_free()
		else:
			Juice.shout("THE MACHINE ATE YESTERDAY")
	)
	col.add_child(fax)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	fax.grab_focus()
	card.pivot_offset = Vector2(320, 210)
	UiKit.pop_in(card)
