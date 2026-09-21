extends Control

signal need_refresh

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(sc)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	sc.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var head := Label.new()
	head.text = "THE BASEMENT CLINIC"
	UiKit.apply_label(head, 24, Palette.LEMON)
	col.add_child(head)
	var sub := Label.new()
	sub.text = Copy.BUILD_HINT
	UiKit.apply_label(sub, 14, Palette.MUTED)
	col.add_child(sub)

	col.add_child(_daily_strip())

	var play := UiKit.button(Copy.PLAY, Vector2(280, 48))
	play.pressed.connect(func() -> void:
		App.start_run()
	)
	col.add_child(play)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)

	var list: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	for b in list:
		grid.add_child(_building_card(b))


func _daily_strip() -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	var row := VBoxContainer.new()
	box.add_child(row)
	var t := Label.new()
	t.text = Copy.DAILY
	UiKit.apply_label(t, 14, Palette.LEMON)
	row.add_child(t)
	row.add_child(_rail("daily", int(FamilyProfile.data["daily_progress"]), 5))
	return box


func _rail(kind: String, value: int, maxv: int) -> Control:
	var wrap := VBoxContainer.new()
	var bar := ProgressBar.new()
	bar.max_value = maxv
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	wrap.add_child(bar)
	var chests := HBoxContainer.new()
	chests.alignment = BoxContainer.ALIGNMENT_CENTER
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/milestones.json"))
	for chest in table[kind]:
		chests.add_child(_chest_btn(kind, chest, value))
	wrap.add_child(chests)
	return wrap


func _chest_btn(kind: String, chest: Dictionary, value: int) -> Button:
	var at := int(chest["at"])
	var claimed: Array = FamilyProfile.data["daily_claimed" if kind == "daily" else "lifetime_claimed"]
	var already := claimed.has(at)
	var ready := value >= at and not already
	var b := UiKit.button("CHEST %d" % at, Vector2(110, 36))
	if already:
		b.text = Copy.CLAIMED
		b.disabled = true
	elif not ready:
		b.disabled = true
		b.text = "CHEST %d" % at
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


func _building_card(info: Dictionary) -> Control:
	var id := str(info["id"])
	var lvl := FamilyProfile.building_level(id)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE if lvl > 0 else Palette.LOCK))
	var col := VBoxContainer.new()
	card.add_child(col)
	var title := Label.new()
	title.text = str(info["name"])
	UiKit.apply_label(title, 16, Palette.LEMON if lvl > 0 else Palette.MUTED)
	col.add_child(title)
	var blurb := Label.new()
	blurb.text = str(info["blurb"])
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(blurb, 12, Palette.TEXT)
	col.add_child(blurb)
	var meta := Label.new()
	meta.text = "LVL %d  ·  UNLOCKS %s" % [lvl, info["unlocks"]]
	UiKit.apply_label(meta, 12, Palette.MUTED)
	col.add_child(meta)
	var cost := FamilyProfile.build_cost(id)
	var b := UiKit.button("BUILD  %d GOLD" % cost if lvl == 0 else "UPGRADE  %d GOLD" % cost, Vector2(0, 36))
	if FamilyProfile.data["gold"] < cost:
		b.disabled = true
	b.pressed.connect(func() -> void:
		if FamilyProfile.try_build(id):
			Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.GROWTH, 0, 0)
			Juice.play("res://assets/audio/chest.wav")
			need_refresh.emit()
		else:
			Juice.claim_burst(get_viewport_rect().size * 0.5, "THE CLINIC DOES NOT RUN ON IOUS", 0, 0)
	)
	col.add_child(b)
	if lvl == 0:
		var bang := UiKit.bang()
		bang.position = Vector2(8, 8)
		card.add_child(bang)
	return card
