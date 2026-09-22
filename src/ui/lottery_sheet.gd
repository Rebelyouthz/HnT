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
	card.offset_left = -340
	card.offset_right = 340
	card.offset_top = -220
	card.offset_bottom = 220
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = Copy.LOTTERY
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var s := Label.new()
	s.text = "Two gems. One spin. The invoice is a raffle now. Mayor Raven calls this civic engagement."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	col.add_child(s)
	var spins := Label.new()
	spins.text = "SPINS FILED  ·  %d" % int(FamilyProfile.data.get("lottery_spins", 0))
	UiKit.apply_label(spins, 15, Palette.EDGE)
	col.add_child(spins)
	var spin := UiKit.button("SPIN  2 GEMS", Vector2(280, 52))
	spin.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	spin.pressed.connect(_spin)
	col.add_child(spin)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	spin.grab_focus()
	card.pivot_offset = Vector2(340, 220)
	UiKit.pop_in(card)


func _spin() -> void:
	var pay := FamilyProfile.spin_lottery()
	if pay.is_empty():
		Juice.shout("THE WHEEL WANTS GEMS")
		return
	Juice.play("res://assets/audio/wheel.wav" if ResourceLoader.exists("res://assets/audio/wheel.wav") else "res://assets/audio/claim.wav")
	VoBank.lottery()
	var title := str(pay.get("title", "RECEIPT"))
	Juice.unlock_logo("INVOICE LOTTERY", title, str(pay.get("got", title)))
	Juice.claim_burst(get_viewport_rect().size * 0.5, title, int(pay.get("gold", 0)), int(pay.get("gems", 0)))
	need_refresh.emit()
	closed.emit()
	queue_free()
