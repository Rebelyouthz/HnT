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
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	sc.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var head_row := HBoxContainer.new()
	var head := Label.new()
	head.text = "THE BASEMENT CLINIC"
	UiKit.apply_label(head, 24, Palette.LEMON)
	head_row.add_child(head)
	var event := Label.new()
	event.text = "  ·  %s TONIGHT" % str(App.difficulty).replace("_", " ").to_upper()
	UiKit.apply_label(event, 14, Palette.BRICK)
	head_row.add_child(event)
	col.add_child(head_row)
	var sub := Label.new()
	sub.text = Copy.CLINIC_NIGHT
	UiKit.apply_label(sub, 14, Palette.MUTED)
	col.add_child(sub)

	col.add_child(_daily_strip())

	var play := UiKit.button(Copy.PLAY, Vector2(320, 52))
	play.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	UiKit.pulse_ready(play)
	play.pressed.connect(func() -> void:
		App.couch = false
		App.start_run()
	)
	col.add_child(play)
	var play_sub := Label.new()
	play_sub.text = Copy.CLINIC_PLAY_SUB
	play_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(play_sub, 13, Palette.MUTED)
	col.add_child(play_sub)

	var camp := preload("res://src/ui/clinic_camp.gd").new()
	camp.built.connect(func(id: String) -> void:
		match id:
			"therapy_couch":
				Juice.unlock_logo("BUILD TAB", "The couch is furniture. The tree is a lifestyle.")
			"wardrobe_cage":
				Juice.unlock_logo("LOCKER", "Costumes do not change the web. That is the point.")
			"trophy_cabinet":
				Juice.unlock_logo("AWARDS", "Claim or it did not happen.")
		need_refresh.emit()
	)
	col.add_child(camp)
	play.grab_focus()


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
		UiKit.pulse_ready(b)
	b.pressed.connect(func() -> void:
		if already or value < at:
			return
		claimed.append(at)
		FamilyProfile.grant(int(chest["gold"]), int(chest["gems"]), str(chest["line"]))
		Juice.claim_burst(get_viewport_rect().size * 0.5, str(chest["line"]), int(chest["gold"]), int(chest["gems"]))
		Juice.toast("quest", str(chest["line"]), "TODAY'S COPING. FILED.")
		need_refresh.emit()
	)
	return b
