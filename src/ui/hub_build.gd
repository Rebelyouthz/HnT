extends Control

signal need_refresh

var _focus: Dictionary = {}
var _stats: StatPanel
var _board: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_right", 16)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	m.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(LogoMark.new())
	head.add_child(UiKit.portrait(SpriteBook.icon("therapy_couch"), Vector2(48, 48)))
	var h := Label.new()
	h.text = "THE CBT TREE"
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	root.add_child(head)
	var s := Label.new()
	s.text = "Three trunks. Each splits left / core / right. Dark until the parent is owned. Lit when it lives in you. Gold in, violence out. Compare is split-screen menus only."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	root.add_child(s)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 10)
	var compare := UiKit.button("BUILD COMPARE", Vector2(200, 40))
	compare.pressed.connect(_compare)
	tools.add_child(compare)
	root.add_child(tools)
	_board = HBoxContainer.new()
	_board.add_theme_constant_override("separation", 12)
	root.add_child(_board)
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/cbt.json"))
	for trunk in ["BODY", "STREET", "SHOW"]:
		_board.add_child(_trunk(trunk, list))
	_stats = StatPanel.new(_stat_rows({}))
	_stats.custom_minimum_size = Vector2(220, 160)
	_board.add_child(_stats)


func _trunk(name: String, list: Array) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := HBoxContainer.new()
	top.add_child(LogoMark.new())
	var t := Label.new()
	t.text = name
	UiKit.apply_label(t, 16, Palette.EDGE if name == "SHOW" else (Palette.BRICK if name == "STREET" else Palette.LEMON))
	top.add_child(t)
	col.add_child(top)
	var owned_n := 0
	var total := 0
	var nodes: Array = []
	for n in list:
		if str(n.get("trunk", "")) != name:
			continue
		total += 1
		if FamilyProfile.has_cbt(str(n.get("id", ""))):
			owned_n += 1
		nodes.append(n)
	var meter := ColorRect.new()
	meter.custom_minimum_size = Vector2(240, 10)
	meter.color = Color(0.08, 0.08, 0.1)
	col.add_child(meter)
	var fill := ColorRect.new()
	fill.color = Palette.READY if owned_n == total else Palette.LEMON
	fill.position = Vector2(0, 0)
	fill.size = Vector2(240.0 * (float(owned_n) / float(maxi(total, 1))), 10)
	meter.add_child(fill)
	var count := Label.new()
	count.text = "%d / %d  ·  %s" % [owned_n, total, "LIT" if owned_n > 0 else "DARK"]
	UiKit.apply_label(count, 12, Palette.MUTED)
	col.add_child(count)
	var graph := HBoxContainer.new()
	graph.add_theme_constant_override("separation", 6)
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(graph)
	var left := VBoxContainer.new()
	var core := VBoxContainer.new()
	var right := VBoxContainer.new()
	for arm in [left, core, right]:
		arm.add_theme_constant_override("separation", 6)
		arm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		graph.add_child(arm)
	var left_l := Label.new()
	left_l.text = "LEFT"
	UiKit.apply_label(left_l, 11, Palette.MUTED)
	left.add_child(left_l)
	var core_l := Label.new()
	core_l.text = "CORE"
	UiKit.apply_label(core_l, 11, Palette.LEMON)
	core.add_child(core_l)
	var right_l := Label.new()
	right_l.text = "RIGHT"
	UiKit.apply_label(right_l, 11, Palette.MUTED)
	right.add_child(right_l)
	for n in nodes:
		var branch := str(n.get("branch", "core"))
		if str(n.get("requires", "")) == "":
			branch = "core"
		match branch:
			"left":
				left.add_child(_node_card(n))
			"right":
				right.add_child(_node_card(n))
			_:
				core.add_child(_node_card(n))
	return col


func _node_card(node: Dictionary) -> Control:
	var id := str(node.get("id", ""))
	var rarity := Rarity.normalize(str(node.get("rarity", "common")))
	var owned := FamilyProfile.has_cbt(id)
	var req := str(node.get("requires", ""))
	var locked := req != "" and not FamilyProfile.has_cbt(req)
	var can := (not owned) and (not locked) and int(FamilyProfile.data["gold"]) >= int(node["gold"]) and int(FamilyProfile.data["rep"]) >= int(node["rep"])
	var row := PanelContainer.new()
	var border := Palette.LOCK
	var fill := Color(0.06, 0.06, 0.08)
	if owned:
		border = Palette.READY
		fill = Rarity.fill(rarity)
	elif can:
		border = Palette.LEMON
		fill = Palette.PANEL
	elif locked:
		border = Palette.LOCK
		fill = Color(0.05, 0.05, 0.07)
	else:
		border = Rarity.color(rarity)
		fill = Palette.PANEL
	row.add_theme_stylebox_override("panel", UiKit.panel(fill, border))
	var box := HBoxContainer.new()
	row.add_child(box)
	var pip := ColorRect.new()
	pip.custom_minimum_size = Vector2(8, 36)
	if owned:
		pip.color = Palette.READY
	elif locked:
		pip.color = Palette.LOCK
	elif can:
		pip.color = Palette.LEMON
	else:
		pip.color = Rarity.color(rarity)
	box.add_child(pip)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(node["name"]), Rarity.label(rarity)]
	UiKit.apply_label(t, 13, Palette.MUTED if locked else Rarity.color(rarity))
	txt.add_child(t)
	var got := Label.new()
	got.text = str(node.get("stat", node.get("blurb", "")))
	UiKit.apply_label(got, 11, Palette.LEMON if not locked else Palette.MUTED)
	txt.add_child(got)
	var b := Label.new()
	if locked:
		b.text = "DARK  ·  BUY %s FIRST" % req.replace("_", " ").to_upper()
	elif owned:
		b.text = str(node["blurb"])
	elif int(FamilyProfile.data["gold"]) < int(node["gold"]):
		b.text = "NEED %d GOLD" % int(node["gold"])
	elif int(FamilyProfile.data["rep"]) < int(node["rep"]):
		b.text = "NEED %d REP" % int(node["rep"])
	else:
		b.text = str(node["blurb"])
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 11, Palette.TEXT if not locked else Palette.LOCK)
	txt.add_child(b)
	box.add_child(txt)
	var buy := UiKit.button("OWNED" if owned else ("%dG" % int(node["gold"])), Vector2(90, 36))
	buy.disabled = owned or locked or int(FamilyProfile.data["gold"]) < int(node["gold"]) or int(FamilyProfile.data["rep"]) < int(node["rep"])
	if can:
		buy.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.pulse_ready(buy)
	buy.pressed.connect(func() -> void:
		if FamilyProfile.try_cbt(id):
			need_refresh.emit()
		else:
			Juice.claim_burst(get_viewport_rect().size * 0.5, "GOLD AND PARENTS FIRST", 0, 0)
	)
	box.add_child(buy)
	row.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_focus = node
			_refresh_stats()
	)
	return row


func _stat_rows(node: Dictionary) -> Array:
	if node.is_empty():
		return [
			{"name": "GOLD", "value": str(int(FamilyProfile.data.get("gold", 0))), "color": Palette.EDGE},
			{"name": "REP", "value": str(int(FamilyProfile.data.get("rep", 0))), "color": Palette.BRICK},
			{"name": "OWNED", "value": str((FamilyProfile.data.get("cbt", []) as Array).size()), "color": Palette.READY}
		]
	return [
		{"name": "STAT", "value": str(node.get("stat", "—")), "color": Palette.LEMON},
		{"name": "GOLD", "value": str(int(node.get("gold", 0))), "color": Palette.EDGE},
		{"name": "REP", "value": str(int(node.get("rep", 0))), "color": Palette.BRICK},
		{"name": "TRUNK", "value": str(node.get("trunk", "")), "color": Palette.TEXT}
	]


func _refresh_stats() -> void:
	if _stats and is_instance_valid(_stats):
		_stats.queue_free()
	_stats = StatPanel.new(_stat_rows(_focus))
	_stats.custom_minimum_size = Vector2(220, 160)
	if _board:
		_board.add_child(_stats)


func _compare() -> void:
	if not FamilyProfile.is_built("compare_mirrors"):
		Juice.claim_burst(get_viewport_rect().size * 0.5, "BUILD THE MIRRORS FIRST. NARCISSISM HAS A COVER CHARGE.", 0, 0)
		return
	Juice.unlock_logo("BUILD COMPARE", "%s  vs  %s. Same tree. Different damage." % [FamilyProfile.son_name(), FamilyProfile.father_name()])
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var row := HBoxContainer.new()
	row.position = Vector2(80, 120)
	row.add_theme_constant_override("separation", 24)
	layer.add_child(row)
	var son_box := VBoxContainer.new()
	var st := Label.new()
	st.text = "%s  ·  THE SON" % FamilyProfile.son_name()
	UiKit.apply_label(st, 18, Palette.LEMON)
	son_box.add_child(st)
	son_box.add_child(StatPanel.new(StatPanel.kit_rows("son")))
	var dad_box := VBoxContainer.new()
	var dt := Label.new()
	dt.text = "%s  ·  THE FATHER" % FamilyProfile.father_name()
	UiKit.apply_label(dt, 18, Palette.BRICK)
	dad_box.add_child(dt)
	dad_box.add_child(StatPanel.new(StatPanel.kit_rows("father")))
	row.add_child(son_box)
	row.add_child(dad_box)
	var close := UiKit.button("CLOSE THE MIRRORS", Vector2(240, 44))
	close.position = Vector2(500, 520)
	close.pressed.connect(layer.queue_free)
	layer.add_child(close)
	close.grab_focus()
