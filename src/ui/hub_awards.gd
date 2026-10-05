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

	var head := HBoxContainer.new()
	var stamp := StampMark.new()
	stamp.accent = Palette.LEMON
	head.add_child(stamp)
	var h := Label.new()
	h.text = "AWARDS  ·  CLAIM OR IT DID NOT HAPPEN"
	UiKit.apply_label(h, 20, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	col.add_child(_recap())

	var awards: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/awards.json"))
	for a in awards:
		col.add_child(_award(a))
	UiKit.focus_first(self)


func _section(title: String, kind: String, value: int, maxv: int) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel())
	var v := VBoxContainer.new()
	box.add_child(v)
	var t := Label.new()
	t.text = "%s  ·  %d / %d" % [title, value, maxv]
	UiKit.apply_label(t, 16, Palette.LEMON)
	v.add_child(t)
	v.add_child(StatPanel.new([
		{"name": "FILLED", "value": "%d / %d" % [value, maxv], "color": Palette.READY},
		{"name": "LEFT", "value": str(maxi(0, maxv - value)), "color": Palette.MUTED}
	]))
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


func _chest(kind: String, chest: Dictionary, value: int) -> Control:
	var key := "daily_claimed" if kind == "daily" else "lifetime_claimed"
	var claimed: Array = FamilyProfile.data[key]
	var at := int(chest["at"])
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(128, 120)
	var b := UiKit.button("CHEST %d" % at, Vector2(120, 40))
	b.position = Vector2(0, 76)
	var already := claimed.has(at)
	var ready := value >= at and not already
	# The chest itself: locked, glowing when it can be claimed, open after.
	var pic := UiKit.portrait(SpriteBook.icon("chest_open" if already else ("chest_ready" if ready else "chest_locked")), Vector2(80, 80))
	pic.position = Vector2(20, -4)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(pic)
	if ready:
		var tw := pic.create_tween().set_loops()
		tw.tween_property(pic, "position:y", -10.0, 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(pic, "position:y", -4.0, 0.45).set_trans(Tween.TRANS_SINE)
	if already:
		b.text = Copy.CLAIMED
		b.disabled = true
	elif not ready:
		b.disabled = true
	else:
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.pulse_ready(b)
	b.pressed.connect(func() -> void:
		if already or value < at:
			return
		claimed.append(at)
		FamilyProfile.grant(int(chest["gold"]), int(chest["gems"]), str(chest["line"]))
		Juice.claim_burst(get_viewport_rect().size * 0.5, str(chest["line"]), int(chest["gold"]), int(chest["gems"]))
		Juice.toast("quest" if kind == "daily" else "challenge", str(chest["line"]), "CLAIMED. THE CLIPBOARD NOTICED.")
		need_refresh.emit()
	)
	wrap.add_child(b)
	if ready:
		var bang := UiKit.bang()
		bang.position = Vector2(100, 0)
		wrap.add_child(bang)
	return wrap


func _award(a: Dictionary) -> Control:
	var need: Dictionary = a["need"]
	var have := 0
	var want := 0
	var ok := true
	for k in need.keys():
		var n := int(need[k])
		var got := int(FamilyProfile.data.get(k, 0))
		want += n
		have += mini(got, n)
		if got < n:
			ok = false
	var claimed: Array = FamilyProfile.data["awards_claimed"]
	var already: bool = claimed.has(a["id"])
	var rarity := Rarity.normalize(str(a.get("rarity", "common")))
	var card := PanelContainer.new()
	var edge := Rarity.color(rarity)
	if ok and not already:
		edge = Palette.READY
	card.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), edge))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var stamp := StampMark.new()
	stamp.accent = Palette.LEMON if already else (Palette.READY if ok else Palette.BADGE)
	row.add_child(stamp)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [str(a["title"]), Rarity.label(str(a.get("rarity", "common")))]
	UiKit.apply_label(t, 16, Rarity.color(str(a.get("rarity", "common"))))
	var b := Label.new()
	b.text = str(a["blurb"])
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	txt.add_child(t)
	txt.add_child(b)
	txt.add_child(StatPanel.new([
		{"name": "PROGRESS", "value": "%d / %d" % [have, maxi(want, 1)], "color": Palette.READY if ok else Palette.MUTED},
		{"name": "GOLD", "value": str(int(a["gold"])), "color": Palette.EDGE},
		{"name": "GEMS", "value": str(int(a["gems"])), "color": Palette.LEMON}
	]))
	row.add_child(txt)
	var btn := UiKit.button(Copy.CLAIM, Vector2(120, 44))
	if already:
		btn.text = Copy.CLAIMED
		btn.disabled = true
	elif not ok:
		btn.disabled = true
		btn.text = "NOT YET"
	else:
		btn.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.pulse_ready(btn)
	btn.pressed.connect(func() -> void:
		if already or not ok:
			return
		claimed.append(a["id"])
		FamilyProfile.grant(int(a["gold"]), int(a["gems"]), Copy.HEALTHY)
		Rarity.juice(rarity, str(a["title"]))
		Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.HEALTHY, int(a["gold"]), int(a["gems"]))
		Juice.toast("achievement", "%s  ·  %s" % [str(a["title"]), Rarity.label(rarity)], Copy.HEALTHY)
		need_refresh.emit()
	)
	row.add_child(btn)
	return card


func _recap() -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	var v := VBoxContainer.new()
	box.add_child(v)
	var t := Label.new()
	t.text = "NIGHT RECAP"
	UiKit.apply_label(t, 16, Palette.LEMON)
	v.add_child(t)
	var lines := [
		"Account LV %d  ·  High table %06d" % [int(FamilyProfile.data.get("account_level", 1)), int(FamilyProfile.data.get("high_score", 0))],
		"Intro %s  ·  Ending %s" % [
			"FILED" if bool(FamilyProfile.data.get("intro_done", false)) else "UNSEEN",
			"FILED" if bool(FamilyProfile.data.get("ending_seen", false)) else "UNSEEN"
		],
		"Director Binder %d  ·  FILE ALIVE %d  ·  Legendary cards %d" % [
			int(FamilyProfile.data.get("family_plan_kills", 0)),
			int(FamilyProfile.data.get("file_alives", 0)),
			int(FamilyProfile.data.get("legendary_takes", 0))
		],
		"Films sit between every act. PAUSE skips the beat. OPTIONS can skip films."
	]
	for line in lines:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(l, 13, Palette.TEXT)
		v.add_child(l)
	return box
