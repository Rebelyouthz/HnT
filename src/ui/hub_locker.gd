extends Control

signal need_refresh

var _role := "son"
var _slot := "clothes"
var _col: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_right", 20)
	add_child(m)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_child(sc)
	_col = VBoxContainer.new()
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col.add_theme_constant_override("separation", 10)
	sc.add_child(_col)
	_paint()


func _paint() -> void:
	for c in _col.get_children():
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_child(LogoMark.new())
	head.add_child(UiKit.portrait(SpriteBook.icon("wardrobe_cage"), Vector2(48, 48)))
	var h := Label.new()
	h.text = "AVATAR  ·  LOCKER"
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	_col.add_child(head)
	var s := Label.new()
	s.text = "Clothes, hats, shoes. Every piece has stats. Upgrade three times. Rarity is the border. Movesets stay on the body."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.MUTED)
	_col.add_child(s)
	var bonus := FamilyProfile.gear_stat_bonus(_role)
	_col.add_child(StatPanel.new([
		{"name": "HP", "value": "+%d" % int(bonus["hp"]), "color": Palette.READY},
		{"name": "DMG", "value": "+%d" % int(bonus["dmg"]), "color": Palette.BRICK},
		{"name": "STEAM", "value": "+%d" % int(bonus["steam"]), "color": Palette.LEMON},
		{"name": "SPD", "value": "+%d" % int(bonus["speed"]), "color": Palette.EDGE},
		{"name": "LV", "value": str(int(FamilyProfile.data.get("account_level", 1))), "color": Palette.TEXT}
	]))
	var roles := HBoxContainer.new()
	roles.add_theme_constant_override("separation", 8)
	for pair in [["son", "THE SON"], ["father", "THE FATHER"]]:
		var b := UiKit.button(pair[1], Vector2(180, 40))
		if _role == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			_role = pair[0]
			_paint()
		)
		roles.add_child(b)
	_col.add_child(roles)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	for pair in [["clothes", "CLOTHES"], ["hat", "HATS"], ["shoes", "SHOES"]]:
		var b := UiKit.button(pair[1], Vector2(160, 40))
		if _slot == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Rarity.color("epic")))
		b.pressed.connect(func() -> void:
			_slot = pair[0]
			_paint()
		)
		slots.add_child(b)
	_col.add_child(slots)
	for item in GearBook.for_slot(_slot, _role):
		_col.add_child(_row(item))


func _row(item: Dictionary) -> Control:
	var id := str(item.get("id", ""))
	var rarity := Rarity.normalize(str(item.get("rarity", "common")))
	var owned := FamilyProfile.owns_gear(id)
	var wearing := FamilyProfile.equipped_id(_role, _slot) == id
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	var who := "father" if _role == "father" else "son"
	var face := SpriteBook.tex("res://assets/sprites/%s/idle/00.png" % who)
	row.add_child(UiKit.portrait(face, Vector2(56, 56)))
	var stamp := StampMark.new()
	stamp.accent = Rarity.color(rarity)
	row.add_child(stamp)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(item.get("title", "")), Rarity.label(rarity)]
	UiKit.apply_label(t, 16, Rarity.color(rarity))
	var b := Label.new()
	b.text = str(item.get("blurb", ""))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	v.add_child(t)
	v.add_child(b)
	var st: Dictionary = item.get("stats", {})
	var lvl := FamilyProfile.gear_level(id)
	v.add_child(StatPanel.new([
		{"name": "HP", "value": str(int(st.get("hp", 0)) + lvl), "color": Palette.READY},
		{"name": "DMG", "value": str(int(st.get("dmg", 0)) + lvl), "color": Palette.BRICK},
		{"name": "UP", "value": "%d/3" % lvl, "color": Palette.EDGE}
	]))
	row.add_child(v)
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(160, 0)
	if wearing:
		var on := UiKit.button(Copy.WEARING, Vector2(150, 40))
		on.disabled = true
		on.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		wrap.add_child(on)
	elif owned:
		var wear := UiKit.button(Copy.WEAR, Vector2(150, 40))
		wear.pressed.connect(func() -> void:
			if FamilyProfile.wear_slot(_role, _slot, id):
				Rarity.juice(rarity, str(item.get("title", "")))
				Juice.toast("reward", str(item.get("title", "")), Copy.WEARING)
				need_refresh.emit()
		)
		wrap.add_child(wear)
	else:
		var cost := int(item.get("gold", 0))
		var buy := UiKit.button("%d GOLD" % cost if cost > 0 else "CLAIM", Vector2(150, 40))
		var need_gold := int(FamilyProfile.data.get("gold", 0)) < cost
		var need_rep := int(FamilyProfile.data.get("rep", 0)) < int(item.get("rep", 0))
		var can := not need_gold and not need_rep
		buy.disabled = not can
		if need_rep:
			buy.text = "NEED %d REP" % int(item.get("rep", 0))
		elif need_gold:
			buy.text = "NEED %d GOLD" % cost
		buy.pressed.connect(func() -> void:
			if FamilyProfile.try_buy_gear(id):
				Rarity.juice(rarity, str(item.get("title", "")))
				need_refresh.emit()
		)
		wrap.add_child(buy)
	if owned and lvl < 3:
		var up_cost := int(item.get("upgrade", 20)) * (lvl + 1)
		var up := UiKit.button("UP  %dG" % up_cost, Vector2(150, 36))
		up.pressed.connect(func() -> void:
			if FamilyProfile.try_upgrade_gear(id):
				Rarity.juice(rarity, str(item.get("title", "")))
				Juice.unlock_logo("UPGRADED", "%s is meaner. The clinic noticed." % str(item.get("title", "")))
				need_refresh.emit()
			else:
				Juice.toast("challenge", "GOLD IS ALSO A FEELING", "Upgrade denied.")
		)
		wrap.add_child(up)
	row.add_child(wrap)
	return p
