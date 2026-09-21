extends Control

signal need_refresh
signal closed

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -320
	card.offset_right = 320
	card.offset_top = -240
	card.offset_bottom = 240
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(620, 460)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var h := Label.new()
	h.text = "SESSION SETTINGS"
	UiKit.apply_label(h, 22, Palette.LEMON)
	col.add_child(h)
	col.add_child(_vol("MASTER", "vol_master"))
	col.add_child(_vol("SFX", "vol_sfx"))
	col.add_child(_vol("MUSIC", "vol_music"))
	col.add_child(_vol("VO", "vol_vo"))
	var gore := CheckButton.new()
	gore.text = "LESS GORE  (keeps finishers, strips the mess)"
	gore.button_pressed = FamilyProfile.less_gore()
	gore.toggled.connect(func(on: bool) -> void:
		FamilyProfile.data["less_gore"] = on
		FamilyProfile.save()
	)
	col.add_child(gore)
	var pin := LineEdit.new()
	pin.placeholder_text = "Optional 4-digit PIN"
	pin.secret = true
	pin.max_length = 4
	pin.text = str(FamilyProfile.data.get("pin", ""))
	pin.text_changed.connect(func(t: String) -> void:
		FamilyProfile.data["pin"] = t
		FamilyProfile.save()
	)
	col.add_child(pin)
	var rooms := LineEdit.new()
	rooms.placeholder_text = "Rooms URL (default http://127.0.0.1:8787)"
	rooms.text = str(FamilyProfile.data.get("rooms_url", "http://127.0.0.1:8787"))
	rooms.text_changed.connect(func(t: String) -> void:
		FamilyProfile.data["rooms_url"] = t.strip_edges()
		FamilyProfile.save()
	)
	col.add_child(rooms)
	var map := Label.new()
	map.text = "\n".join(PadRouter.map_lines())
	map.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map.custom_minimum_size = Vector2(580, 0)
	UiKit.apply_label(map, 13, Palette.TEXT)
	col.add_child(map)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()


func _vol(title: String, key: String) -> Control:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(90, 0)
	UiKit.apply_label(l, 14, Palette.EDGE)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(FamilyProfile.data.get(key, 1.0))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void:
		FamilyProfile.data[key] = v
		FamilyProfile.save()
		Mixer.apply_volumes()
	)
	row.add_child(l)
	row.add_child(s)
	return row
