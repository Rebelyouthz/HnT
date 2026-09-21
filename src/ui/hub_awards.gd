extends Control

signal need_refresh

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_right", 18)
	add_child(m)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_child(sc)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	sc.add_child(col)

	col.add_child(_section(Copy.DAILY, "daily", int(FamilyProfile.data["daily_progress"]), 5))
	col.add_child(_section(Copy.LIFE, "lifetime", int(FamilyProfile.data["lifetime_points"]), 12))

	var h := Label.new()
	h.text = "AWARDS  ·  CLAIM OR IT DID NOT HAPPEN"
	UiKit.apply_label(h, 20, Palette.LEMON)
	col.add_child(h)

	var awards: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/awards.json"))
	for a in awards:
		col.add_child(_award(a))


func _section(title: String, kind: String, value: int, maxv: int) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel())
	var v := VBoxContainer.new()
	box.add_child(v)
	var t := Label.new()
	t.text = "%s  ·  %d / %d" % [title, value, maxv]
	UiKit.apply_label(t, 16, Palette.LEMON)
	v.add_child(t)
	var bar := ProgressBar.new()
	bar.max_value = maxv
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	v.add_child(bar)
	var row := HBoxContainer.new()
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/milestones.json"))
	for chest in table[kind]:
		row.add_child(_chest(kind, chest, value))
	v.add_child(row)
	return box


func _chest(kind: String, chest: Dictionary, value: int) -> Button:
	var key := "daily_claimed" if kind == "daily" else "lifetime_claimed"
	var claimed: Array = FamilyProfile.data[key]
	var at := int(chest["at"])
	var b := UiKit.button("CHEST %d" % at, Vector2(120, 40))
	var already := claimed.has(at)
	var ready := value >= at and not already
	if already:
		b.text = Copy.CLAIMED
		b.disabled = true
	elif not ready:
		b.disabled = true
	else:
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
	b.pressed.connect(func() -> void:
		if already or value < at:
			return
		claimed.append(at)
		FamilyProfile.grant(int(chest["gold"]), int(chest["gems"]), str(chest["line"]))
		Juice.claim_burst(get_viewport_rect().size * 0.5, str(chest["line"]), int(chest["gold"]), int(chest["gems"]))
		need_refresh.emit()
	)
	return b


func _award(a: Dictionary) -> Control:
	var need: Dictionary = a["need"]
	var ok := true
	for k in need.keys():
		if int(FamilyProfile.data.get(k, 0)) < int(need[k]):
			ok = false
	var claimed: Array = FamilyProfile.data["awards_claimed"]
	var already: bool = claimed.has(a["id"])
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel())
	var row := HBoxContainer.new()
	card.add_child(row)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = str(a["title"])
	UiKit.apply_label(t, 16, Palette.LEMON)
	var b := Label.new()
	b.text = str(a["blurb"])
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	txt.add_child(t)
	txt.add_child(b)
	row.add_child(txt)
	var btn := UiKit.button(Copy.CLAIM, Vector2(120, 40))
	if already:
		btn.text = Copy.CLAIMED
		btn.disabled = true
	elif not ok:
		btn.disabled = true
		btn.text = "NOT YET"
	else:
		btn.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
	btn.pressed.connect(func() -> void:
		if already or not ok:
			return
		claimed.append(a["id"])
		FamilyProfile.grant(int(a["gold"]), int(a["gems"]), Copy.HEALTHY)
		Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.HEALTHY, int(a["gold"]), int(a["gems"]))
		need_refresh.emit()
	)
	row.add_child(btn)
	return card
