extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -400
	card.offset_right = 400
	card.offset_top = -280
	card.offset_bottom = 280
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(780, 540)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var head := HBoxContainer.new()
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(48, 48)
	head.add_child(mark)
	var h := Label.new()
	h.text = "CAMP SHOP  ·  DOPAMINE"
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Chests, lucky wheel, slots, claw, scratch. Upgrade the stall and the stock gets meaner. Always shows what you got."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dopamine.json"))
	var lvl := FamilyProfile.building_level("pawn_shop")
	var chests: Array = table.get("chests", [])
	var shown := mini(chests.size(), 1 + lvl)
	for i in shown:
		col.add_child(_chest(chests[i]))
	col.add_child(_wheel(table.get("wheel", {})))
	col.add_child(_slots(table.get("slots", {})))
	if lvl >= 2:
		col.add_child(_claw(table.get("claw", {})))
	if lvl >= 3:
		col.add_child(_scratch(table.get("scratch", {})))
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()


func _chest(info: Dictionary) -> Control:
	var rarity := Rarity.normalize(str(info.get("rarity", "common")))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(info.get("title", "")), Rarity.label(rarity)]
	UiKit.apply_label(t, 16, Rarity.color(rarity))
	v.add_child(t)
	row.add_child(v)
	var b := UiKit.button("%d GOLD" % int(info.get("gold", 0)), Vector2(140, 40))
	b.pressed.connect(func() -> void:
		if int(FamilyProfile.data.get("gold", 0)) < int(info.get("gold", 0)):
			Juice.shout("THE TILL DOES NOT TAKE PROMISES")
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(info.get("gold", 0))
		var pool: Array = info.get("pool", [])
		pool.shuffle()
		_payout(str(pool[0]) if pool.size() > 0 else "gold_small")
		need_refresh.emit()
	)
	row.add_child(b)
	return p


func _wheel(info: Dictionary) -> Control:
	var b := UiKit.button("LUCKY WHEEL  %d GOLD" % int(info.get("gold", 22)), Vector2(360, 48))
	b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	b.pressed.connect(func() -> void:
		if int(FamilyProfile.data.get("gold", 0)) < int(info.get("gold", 22)):
			Juice.shout("THE TILL DOES NOT TAKE PROMISES")
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(info.get("gold", 22))
		Juice.play("res://assets/audio/wheel.wav" if ResourceLoader.exists("res://assets/audio/wheel.wav") else "res://assets/audio/shop.wav")
		var slots: Array = info.get("slots", [])
		var bag: Array = []
		for s in slots:
			for i in int((s as Dictionary).get("w", 1)):
				bag.append(str((s as Dictionary).get("id", "gold_small")))
		bag.shuffle()
		_payout(str(bag[0]) if bag.size() > 0 else "gold_small")
		need_refresh.emit()
	)
	return b


func _slots(info: Dictionary) -> Control:
	var b := UiKit.button("SLOT MACHINE  %d GOLD" % int(info.get("gold", 12)), Vector2(360, 48))
	b.pressed.connect(func() -> void:
		if int(FamilyProfile.data.get("gold", 0)) < int(info.get("gold", 12)):
			Juice.shout("THE TILL DOES NOT TAKE PROMISES")
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(info.get("gold", 12))
		Juice.play("res://assets/audio/slot.wav" if ResourceLoader.exists("res://assets/audio/slot.wav") else "res://assets/audio/shop.wav")
		var reels: Array = info.get("reels", ["gold_small"])
		reels.shuffle()
		_payout(str(reels[0]))
		need_refresh.emit()
	)
	return b


func _claw(info: Dictionary) -> Control:
	var b := UiKit.button("CLAW MACHINE  %d GOLD" % int(info.get("gold", 18)), Vector2(360, 48))
	b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	b.pressed.connect(func() -> void:
		if int(FamilyProfile.data.get("gold", 0)) < int(info.get("gold", 18)):
			Juice.shout("THE TILL DOES NOT TAKE PROMISES")
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(info.get("gold", 18))
		Juice.play("res://assets/audio/shop.wav")
		var pool: Array = info.get("pool", ["gold_small"])
		pool.shuffle()
		_payout(str(pool[0]))
		need_refresh.emit()
	)
	return b


func _scratch(info: Dictionary) -> Control:
	var b := UiKit.button("SCRATCH CARD  %d GOLD" % int(info.get("gold", 8)), Vector2(360, 48))
	b.pressed.connect(func() -> void:
		if int(FamilyProfile.data.get("gold", 0)) < int(info.get("gold", 8)):
			Juice.shout("THE TILL DOES NOT TAKE PROMISES")
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - int(info.get("gold", 8))
		var pool: Array = info.get("pool", ["gold_small"])
		pool.shuffle()
		_payout(str(pool[0]))
		need_refresh.emit()
	)
	return b


func _payout(id: String) -> void:
	if id == "envelope" or id.begins_with("gear_") or id.begins_with("weapon_"):
		FamilyProfile.grant_prize(id)
		return
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dopamine.json"))
	var prizes: Dictionary = table.get("prizes", {})
	if prizes.has(id):
		var p: Dictionary = prizes[id]
		FamilyProfile.grant(int(p.get("gold", 0)), int(p.get("gems", 0)), str(p.get("title", id)))
		var parts: Variant = p.get("parts", {})
		if typeof(parts) == TYPE_DICTIONARY:
			for k in (parts as Dictionary).keys():
				FamilyProfile.add_parts(str(k), int((parts as Dictionary)[k]))
		Juice.unlock_logo(str(p.get("title", id)), "Dopamine. Filed.", "%s  ·  %s" % [id.replace("_", " ").to_upper(), Rarity.label(str(p.get("rarity", "common")))])
		Rarity.juice(str(p.get("rarity", "common")), str(p.get("title", id)))
		return
	if id.begins_with("frame_"):
		FamilyProfile.grant_cosmetic("frame", id, true)
		return
	if id.begins_with("banner_"):
		FamilyProfile.grant_cosmetic("banner", id, true)
		return
	if id.begins_with("badge_"):
		FamilyProfile.grant_cosmetic("badge", id, true)
		return
	if id == "mag_plus" or id == "hollow":
		if not FamilyProfile.has_research(id):
			(FamilyProfile.data["research"] as Array).append(id)
			FamilyProfile.flag_unseen("research_%s" % id)
			FamilyProfile.save()
			Juice.unlock_logo(id.replace("_", " ").to_upper(), "Research fell out of a chest.", "YOU GOT  ·  %s" % id.to_upper())
		return
	FamilyProfile.add_gold(10)
	Juice.unlock_logo("POCKET CHANGE", "The wheel shrugged.", "+10 GOLD")
