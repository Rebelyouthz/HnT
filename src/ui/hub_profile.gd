extends Control

signal closed
signal need_refresh
signal rename_wanted

var _role := "son"
var _col: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -480
	card.offset_right = 480
	card.offset_top = -320
	card.offset_bottom = 320
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(940, 620)
	card.add_child(sc)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	sc.add_child(_col)
	FamilyProfile.peek_menu()
	_paint()


func _paint() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	var head := HBoxContainer.new()
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(56, 56)
	head.add_child(mark)
	if FamilyProfile.has_unseen():
		head.add_child(UiKit.new_dot())
	var h := Label.new()
	h.text = Copy.PROFILE
	UiKit.apply_label(h, 26, Palette.LEMON)
	head.add_child(h)
	_col.add_child(head)
	_col.add_child(_avatar_card())
	var bar := UiKit.glow_bar(clampf(float(FamilyProfile.data.get("account_xp", 0)) / float(maxi(1, FamilyProfile.account_need())), 0.0, 1.0), UiKit.GOLD, Vector2(880, 14))
	_col.add_child(bar)
	var xp := Label.new()
	xp.text = "ACCOUNT LV %d  ·  %d / %d XP  ·  HIGH TABLE %06d" % [
		int(FamilyProfile.data.get("account_level", 1)),
		int(FamilyProfile.data.get("account_xp", 0)),
		FamilyProfile.account_need(),
		int(FamilyProfile.data.get("high_score", 0))
	]
	UiKit.apply_label(xp, 14, Palette.EDGE)
	_col.add_child(xp)
	_col.add_child(StatPanel.new([
		{"name": "RUNS", "value": str(int(FamilyProfile.data.get("runs", 0))), "color": Palette.LEMON},
		{"name": "TRICKS", "value": str(int(FamilyProfile.data.get("tricks", 0))), "color": Palette.EDGE},
		{"name": "STOMPS", "value": str(int(FamilyProfile.data.get("stomps", 0))), "color": Palette.BRICK},
		{"name": "PATROLS", "value": str(int(FamilyProfile.data.get("patrols", 0))), "color": Palette.READY}
	]))
	var roles := HBoxContainer.new()
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
	_col.add_child(_section("FRAMES", "frames", "frame"))
	_col.add_child(_section("BANNERS", "banners", "banner"))
	_col.add_child(_section("BADGES  ·  EQUIP AS PROOF", "badges", "badge"))
	var names := UiKit.button("RENAME THE PATIENTS", Vector2(280, 44))
	names.pressed.connect(func() -> void:
		rename_wanted.emit()
		closed.emit()
		queue_free()
	)
	_col.add_child(names)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	_col.add_child(close)
	close.grab_focus()


func _avatar_card() -> Control:
	var p := PanelContainer.new()
	var tint := Cosmetics.tint("banners", FamilyProfile.equipped_cosmetic(_role, "banner"))
	p.add_theme_stylebox_override("panel", UiKit.panel(tint, Cosmetics.tint("frames", FamilyProfile.equipped_cosmetic(_role, "frame"))))
	var row := HBoxContainer.new()
	p.add_child(row)
	row.add_theme_constant_override("separation", 14)
	# The patient's own face, breathing, in the chosen frame.
	var pic := UiKit.portrait(SpriteBook.bust(_role), Vector2(84, 108))
	pic.pivot_offset = Vector2(42, 108)
	var br := pic.create_tween().set_loops()
	br.tween_property(pic, "scale", Vector2(1.0, 1.03), 1.4).set_trans(Tween.TRANS_SINE)
	br.tween_property(pic, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE)
	row.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := Label.new()
	t.text = FamilyProfile.son_name() if _role == "son" else FamilyProfile.father_name()
	UiKit.apply_label(t, 20, Palette.LEMON if _role == "son" else Palette.BRICK)
	v.add_child(t)
	var b := Label.new()
	b.text = "FRAME %s  ·  BANNER %s  ·  BADGE %s" % [
		FamilyProfile.equipped_cosmetic(_role, "frame").replace("_", " ").to_upper(),
		FamilyProfile.equipped_cosmetic(_role, "banner").replace("_", " ").to_upper(),
		FamilyProfile.equipped_cosmetic(_role, "badge").replace("_", " ").to_upper() if FamilyProfile.equipped_cosmetic(_role, "badge") != "" else "NONE"
	]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	v.add_child(b)
	var lv := Label.new()
	lv.text = "LV %d  ·  %s  ·  POWER %d  ·  %s" % [Heroes.level(_role), Heroes.rarity_name(_role).to_upper(), Heroes.power(_role), RewardBook.title()]
	UiKit.apply_label(lv, 12, UiKit.GOLD)
	v.add_child(lv)
	row.add_child(v)
	return p


func _section(title: String, json_key: String, kind: String) -> Control:
	var box := VBoxContainer.new()
	var h := Label.new()
	h.text = title
	UiKit.apply_label(h, 16, Palette.LEMON)
	box.add_child(h)
	for spec in Cosmetics.list_for(json_key):
		if typeof(spec) != TYPE_DICTIONARY:
			continue
		box.add_child(_row(spec, kind))
	return box


func _row(spec: Dictionary, kind: String) -> Control:
	var id := str(spec.get("id", ""))
	var rarity := Rarity.normalize(str(spec.get("rarity", "common")))
	var owned_key := "owned_frames" if kind == "frame" else ("owned_banners" if kind == "banner" else "owned_badges")
	var owned: Array = FamilyProfile.data.get(owned_key, [])
	var has := owned.has(id)
	var ok := Cosmetics.need_ok(spec)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	var stamp := StampMark.new()
	stamp.accent = Rarity.color(rarity)
	row.add_child(stamp)
	if FamilyProfile.is_unseen(id):
		row.add_child(UiKit.new_dot())
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(spec.get("title", "")), Rarity.label(rarity)]
	UiKit.apply_label(t, 15, Rarity.color(rarity))
	var b := Label.new()
	b.text = str(spec.get("blurb", ""))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 12, Palette.TEXT)
	v.add_child(t)
	v.add_child(b)
	row.add_child(v)
	var btn := UiKit.button("EQUIP" if has else ("LOCKED" if not ok else "CLAIM"), Vector2(120, 40))
	btn.disabled = (not has and not ok)
	if has and FamilyProfile.equipped_cosmetic(_role, kind) == id:
		btn.text = "ON"
		btn.disabled = true
	btn.pressed.connect(func() -> void:
		if has:
			FamilyProfile.wear_cosmetic(_role, kind, id)
			Juice.toast("reward", str(spec.get("title", "")), "YOU GOT IT ON THE PROFILE. Proof.")
			_paint()
			need_refresh.emit()
			return
		if FamilyProfile.grant_cosmetic(kind, id, true):
			FamilyProfile.wear_cosmetic(_role, kind, id)
			_paint()
			need_refresh.emit()
	)
	row.add_child(btn)
	return p
