extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	FamilyProfile.mark_seen("radio")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.chrome())
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -360
	card.offset_right = 360
	card.offset_top = -200
	card.offset_bottom = 200
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = Copy.RADIO
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var line := FamilyProfile.radio_line()
	var s := Label.new()
	s.text = line
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 16, Palette.TEXT)
	col.add_child(s)
	VoBank.mayor_radio()
	FamilyProfile.hear_radio()
	var stats := StatPanel.new([
		{"name": "HEAT PEAK", "value": str(int(FamilyProfile.data.get("heat_peak", 0))), "color": Palette.BRICK},
		{"name": "PATROLS", "value": str(int(FamilyProfile.data.get("patrols", 0))), "color": Palette.EDGE},
		{"name": "INVOICE", "value": "STILL DUE", "color": Palette.LEMON}
	])
	col.add_child(stats)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		need_refresh.emit()
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()
