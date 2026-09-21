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
	card.offset_top = -280
	card.offset_bottom = 280
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(620, 460)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var h := Label.new()
	h.text = Copy.OPTIONS
	UiKit.apply_label(h, 22, Palette.LEMON)
	col.add_child(h)
	var sub := Label.new()
	sub.text = "Volumes, gore, PIN, rooms URL, films. Reset writes a backup first. Host/Join ports do not live here."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(sub, 13, Palette.MUTED)
	col.add_child(sub)
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
	var films := CheckButton.new()
	films.text = Copy.SKIP_BRIDGES
	films.button_pressed = bool(FamilyProfile.data.get("skip_films", false))
	films.toggled.connect(func(on: bool) -> void:
		FamilyProfile.data["skip_films"] = on
		FamilyProfile.save()
	)
	col.add_child(films)
	var reset := UiKit.button(Copy.RESET, Vector2(240, 48))
	reset.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	reset.pressed.connect(_confirm_reset)
	col.add_child(reset)
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
	var pct := Label.new()
	pct.custom_minimum_size = Vector2(48, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiKit.apply_label(pct, 14, Palette.TEXT)
	pct.text = "%d%%" % int(round(s.value * 100.0))
	s.value_changed.connect(func(v: float) -> void:
		FamilyProfile.data[key] = v
		FamilyProfile.save()
		Mixer.apply_volumes()
		pct.text = "%d%%" % int(round(v * 100.0))
	)
	row.add_child(l)
	row.add_child(s)
	row.add_child(pct)
	return row


func _confirm_reset() -> void:
	var wrap := ColorRect.new()
	wrap.color = Color(0, 0, 0, 0.82)
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(wrap)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.BRICK))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -280
	card.offset_right = 280
	card.offset_top = -160
	card.offset_bottom = 160
	wrap.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = Copy.RESET
	UiKit.apply_label(h, 22, Palette.BRICK)
	col.add_child(h)
	var b := Label.new()
	b.text = Copy.RESET_BLURB
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(520, 0)
	UiKit.apply_label(b, 14, Palette.TEXT)
	col.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var yes := UiKit.button(Copy.RESET_CONFIRM, Vector2(220, 48))
	yes.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	yes.pressed.connect(func() -> void:
		FamilyProfile.reset_progress()
		Juice.unlock_logo("WIPED", "Backup at user://family.json.bak. The night starts over.")
		need_refresh.emit()
		closed.emit()
		queue_free()
	)
	var no := UiKit.button(Copy.RESET_NEVER, Vector2(200, 48))
	no.pressed.connect(wrap.queue_free)
	row.add_child(yes)
	row.add_child(no)
	col.add_child(row)
	no.grab_focus()
