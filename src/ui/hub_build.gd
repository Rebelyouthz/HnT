extends Control

signal need_refresh

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_top", 12)
	add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	m.add_child(col)
	var h := Label.new()
	h.text = "THE CBT TREE"
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var s := Label.new()
	s.text = "Cognitive Behavioral whatever. Gold in, violence out. Compare is split-screen menus only."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	col.add_child(s)

	var compare := UiKit.button("BUILD COMPARE", Vector2(220, 44))
	compare.pressed.connect(_compare)
	col.add_child(compare)

	var list: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/cbt.json"))
	for node in list:
		col.add_child(_node_row(node))


func _node_row(node: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UiKit.panel())
	var box := HBoxContainer.new()
	row.add_child(box)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [node["trunk"], node["name"]]
	UiKit.apply_label(t, 16, Palette.LEMON)
	var b := Label.new()
	b.text = str(node["blurb"])
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	txt.add_child(t)
	txt.add_child(b)
	box.add_child(txt)
	var owned: Array = FamilyProfile.data["cbt"]
	var buy := UiKit.button("OWNED" if owned.has(node["id"]) else "%d GOLD" % int(node["gold"]), Vector2(140, 40))
	buy.disabled = owned.has(node["id"]) or int(FamilyProfile.data["gold"]) < int(node["gold"]) or int(FamilyProfile.data["rep"]) < int(node["rep"])
	buy.pressed.connect(func() -> void:
		if owned.has(node["id"]):
			return
		if int(FamilyProfile.data["gold"]) < int(node["gold"]):
			Juice.claim_burst(get_viewport_rect().size * 0.5, "GOLD IS ALSO A FEELING", 0, 0)
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(node["gold"])
		owned.append(node["id"])
		FamilyProfile.save()
		Juice.claim_burst(get_viewport_rect().size * 0.5, "COPING MECHANISM INSTALLED", 0, 0)
		need_refresh.emit()
	)
	box.add_child(buy)
	return row


func _compare() -> void:
	if not FamilyProfile.is_built("compare_mirrors"):
		Juice.claim_burst(get_viewport_rect().size * 0.5, "BUILD THE MIRRORS FIRST. NARCISSISM HAS A COVER CHARGE.", 0, 0)
		return
	Juice.claim_burst(get_viewport_rect().size * 0.5, "%s  vs  %s. Same tree. Different damage." % [FamilyProfile.son_name(), FamilyProfile.father_name()], 0, 0)
