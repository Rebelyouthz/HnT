extends Control

const TABS := ["clinic", "run", "build", "locker", "awards"]

var _content: Control
var _tab_bar: HBoxContainer
var _gold_pill: HBoxContainer
var _gems_pill: HBoxContainer
var _rep_pill: HBoxContainer
var _log_bang: Control
var _tab_bangs: Dictionary = {}
var _current := "clinic"
var _modal: Control
var _safe: MarginContainer
var _pill_vals := {"gold": "", "gems": "", "rep": ""}
var _avatar_btn: Button
var _avatar_dot: ColorRect
var _logo_dot: ColorRect
var _tab_dots: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	FamilyProfile._roll_daily()
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	_build_chrome()
	var start_tab := App.pending_tab if App.pending_tab in TABS else "clinic"
	App.pending_tab = "clinic"
	_show_tab(start_tab)
	if not FamilyProfile.data.get("named", false):
		_open_intake()
	App.tab_wanted.connect(_show_tab)
	FamilyProfile.changed.connect(_refresh_pills)


func _build_chrome() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var night := ColorRect.new()
	night.color = Color(0.22, 0.25, 0.38, 0.35)
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(night)

	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_safe)
	_apply_safe()

	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)
	_safe.add_child(root)

	root.add_child(_make_top())
	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)
	root.add_child(_make_tabs())


func _make_top() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)

	var avatar_wrap := Control.new()
	avatar_wrap.custom_minimum_size = Vector2(228, 56)
	var avatar := UiKit.button("", Vector2(220, 56))
	_avatar_btn = avatar
	avatar.text = "%s  LV %d\nTHE SON\n%s\nTHE FATHER" % [
		FamilyProfile.son_name(), int(FamilyProfile.data.get("account_level", 1)), FamilyProfile.father_name()
	]
	avatar.pressed.connect(_open_profile)
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_wrap.add_child(avatar)
	_avatar_dot = UiKit.new_dot()
	_avatar_dot.position = Vector2(206, -2)
	avatar_wrap.add_child(_avatar_dot)
	row.add_child(avatar_wrap)

	var logo_box := VBoxContainer.new()
	logo_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var logo := LogoMark.new()
	logo.custom_minimum_size = Vector2(56, 56)
	var logo_wrap := Control.new()
	logo_wrap.custom_minimum_size = Vector2(64, 56)
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo_wrap.add_child(logo)
	_logo_dot = UiKit.new_dot()
	_logo_dot.position = Vector2(48, -2)
	logo_wrap.add_child(_logo_dot)
	var title := Label.new()
	title.text = "%s  ·  %s" % [Copy.LOGO, Copy.SUB]
	UiKit.apply_label(title, 22, Palette.LEMON)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tag := Label.new()
	tag.text = Copy.TAGLINE
	UiKit.apply_label(tag, 13, Palette.MUTED)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var brand := HBoxContainer.new()
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	brand.add_child(logo_wrap)
	var names := VBoxContainer.new()
	names.add_child(title)
	names.add_child(tag)
	brand.add_child(names)
	logo_box.add_child(brand)
	row.add_child(logo_box)

	_gold_pill = UiKit.pill("GOLD", "0", Palette.EDGE)
	_gems_pill = UiKit.pill("GEMS", "0", Palette.LEMON)
	_rep_pill = UiKit.pill("REP", "0", Palette.BRICK)
	row.add_child(_gold_pill)
	row.add_child(_gems_pill)
	row.add_child(_rep_pill)

	var log_btn := UiKit.button("LOG", Vector2(72, 52))
	log_btn.pressed.connect(_open_log)
	var log_wrap := Control.new()
	log_wrap.custom_minimum_size = Vector2(80, 52)
	log_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_wrap.add_child(log_btn)
	_log_bang = UiKit.bang()
	_log_bang.position = Vector2(56, -4)
	log_wrap.add_child(_log_bang)
	row.add_child(log_wrap)
	var gear := UiKit.button(Copy.OPTIONS, Vector2(96, 52))
	gear.pressed.connect(_open_settings)
	row.add_child(gear)

	_refresh_pills()
	return bar


func _make_tabs() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 8)
	bar.add_child(_tab_bar)
	for id in TABS:
		var wrap := Control.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.custom_minimum_size = Vector2(0, 64)
		var b := UiKit.button(_tab_title(id), Vector2(0, 64))
		b.name = id
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.pressed.connect(_show_tab.bind(id))
		wrap.add_child(b)
		var bang := UiKit.bang()
		bang.position = Vector2(12, 6)
		bang.visible = false
		wrap.add_child(bang)
		_tab_bangs[id] = bang
		var dot := UiKit.new_dot()
		dot.position = Vector2(28, 6)
		dot.visible = false
		wrap.add_child(dot)
		_tab_dots[id] = dot
		_tab_bar.add_child(wrap)
	_refresh_tab_locks()
	return bar


func _tab_title(id: String) -> String:
	match id:
		"clinic":
			return Copy.TAB_CLINIC
		"run":
			return Copy.TAB_RUN
		"build":
			return Copy.TAB_BUILD
		"locker":
			return Copy.TAB_LOCKER
		_:
			return Copy.TAB_AWARDS


func _show_tab(id: String) -> void:
	if not FamilyProfile.tab_unlocked(id):
		Juice.claim_burst(Vector2(640, 360), Copy.LOCKED, 0, 0)
		Juice.play("res://assets/audio/ui_click.wav")
		return
	_current = id
	FamilyProfile.data["seen"][id] = true
	FamilyProfile.save()
	for child in _content.get_children():
		child.queue_free()
	var page: Control
	match id:
		"clinic":
			page = preload("res://src/ui/hub_clinic.gd").new()
		"run":
			page = preload("res://src/ui/hub_run.gd").new()
		"build":
			page = preload("res://src/ui/hub_build.gd").new()
		"locker":
			page = preload("res://src/ui/hub_locker.gd").new()
		_:
			page = preload("res://src/ui/hub_awards.gd").new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.modulate.a = 0.0
	_content.add_child(page)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(page, "modulate:a", 1.0, 0.18)
	if page.has_signal("need_refresh"):
		page.need_refresh.connect(_after_page)
	if page.has_signal("need_sheet"):
		page.need_sheet.connect(_open_camp_sheet)
	_refresh_tab_locks()
	_refresh_pills()
	Juice.play("res://assets/audio/ui_click.wav")
	_focus_page(page)


func _after_page() -> void:
	_refresh_pills()
	_refresh_tab_locks()
	_show_tab(_current)


func _refresh_pills() -> void:
	_set_pill(_gold_pill, str(FamilyProfile.data["gold"]), "gold")
	_set_pill(_gems_pill, str(FamilyProfile.data["gems"]), "gems")
	_set_pill(_rep_pill, str(FamilyProfile.data["rep"]), "rep")
	_log_bang.visible = FamilyProfile.unread_log_count() > 0
	_refresh_new_dots()
	if _avatar_btn:
		_avatar_btn.text = "%s  LV %d\nTHE SON\n%s\nTHE FATHER" % [
			FamilyProfile.son_name(), int(FamilyProfile.data.get("account_level", 1)), FamilyProfile.father_name()
		]
	if _log_bang.visible:
		if not _log_bang.has_meta("pulsing"):
			_log_bang.set_meta("pulsing", true)
			UiKit.pulse_ready(_log_bang)
	else:
		_log_bang.remove_meta("pulsing")
		_log_bang.scale = Vector2.ONE


func _set_pill(pill: Node, value: String, key: String) -> void:
	var v := pill.find_child("Value", true, false)
	if v:
		v.text = value
	if _pill_vals.get(key, "") != value and _pill_vals[key] != "":
		var tw := pill.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pill, "scale", Vector2(1.12, 1.12), 0.1)
		tw.tween_property(pill, "scale", Vector2.ONE, 0.14)
	_pill_vals[key] = value


func _refresh_tab_locks() -> void:
	for id in TABS:
		var wrap: Control = null
		for child in _tab_bar.get_children():
			var btn := child.get_node_or_null(id) as Button
			if btn:
				wrap = child
				var unlocked := FamilyProfile.tab_unlocked(id)
				btn.disabled = false
				if unlocked:
					btn.text = _tab_title(id)
				else:
					btn.text = "%s  LOCK" % _tab_title(id)
				var bang: Control = _tab_bangs[id]
				var unseen: bool = unlocked and not bool(FamilyProfile.data["seen"].get(id, false))
				var awards_ready: bool = id == "awards" and unlocked and _has_claim()
				bang.visible = unseen or awards_ready
				var dot: Control = _tab_dots.get(id)
				if dot:
					dot.visible = FamilyProfile.has_menu_alert()
				if id == _current:
					btn.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
				else:
					btn.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.EDGE))


func _has_claim() -> bool:
	var awards: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/awards.json"))
	for a in awards:
		var need: Dictionary = a["need"]
		var ok := true
		for k in need.keys():
			if int(FamilyProfile.data.get(k, 0)) < int(need[k]):
				ok = false
		if ok and not FamilyProfile.data["awards_claimed"].has(a["id"]):
			return true
	return false


func _open_log() -> void:
	FamilyProfile.mark_log_read()
	_refresh_pills()
	_modal_text("SESSION LOG", _log_body())


func _log_body() -> String:
	var lines: PackedStringArray = []
	for item in FamilyProfile.data["log"]:
		lines.append("%s\n%s" % [item["title"], item["body"]])
	return "\n\n".join(lines) if lines else Copy.EMPTY_LOG


func _refresh_new_dots() -> void:
	var alert := FamilyProfile.has_menu_alert()
	if _avatar_dot:
		_avatar_dot.visible = alert
	if _logo_dot:
		_logo_dot.visible = alert
	for id in _tab_dots.keys():
		var d: Control = _tab_dots[id]
		if d:
			d.visible = alert


func _open_profile() -> void:
	if not bool(FamilyProfile.data.get("named", false)):
		_open_intake()
		return
	_clear_modal()
	var sheet := preload("res://src/ui/hub_profile.gd").new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(_clear_modal)
	sheet.need_refresh.connect(_refresh_pills)
	if sheet.has_signal("rename_wanted"):
		sheet.rename_wanted.connect(func() -> void:
			_clear_modal()
			_open_intake()
		)


func _open_camp_sheet(id: String) -> void:
	_clear_modal()
	var path := ""
	match id:
		"pawn_shop":
			path = "res://src/ui/dopamine_shop.gd"
		"patrol_desk":
			path = "res://src/ui/patrol_sheet.gd"
		"research_lab":
			path = "res://src/ui/research_sheet.gd"
		"dojo":
			path = "res://src/ui/dojo_sheet.gd"
		"workshop":
			path = "res://src/ui/workshop_sheet.gd"
		"bounty_board":
			path = "res://src/ui/bounty_sheet.gd"
		"radio_tower":
			path = "res://src/ui/radio_sheet.gd"
		"album_wall":
			path = "res://src/ui/album_sheet.gd"
		"blood_fridge":
			path = "res://src/ui/fridge_sheet.gd"
		"streak_locker":
			path = "res://src/ui/streak_sheet.gd"
		"invoice_wheel":
			path = "res://src/ui/lottery_sheet.gd"
		"punching_bag":
			path = "res://src/ui/bag_sheet.gd"
		"warrant_fax":
			path = "res://src/ui/fax_sheet.gd"
		"tip_jar":
			path = "res://src/ui/tip_sheet.gd"
		"lost_found":
			path = "res://src/ui/lost_sheet.gd"
		"payphone":
			path = "res://src/ui/phone_sheet.gd"
		"water_cooler":
			path = "res://src/ui/cooler_sheet.gd"
		"coat_check":
			path = "res://src/ui/coat_sheet.gd"
		"time_clock":
			path = "res://src/ui/clock_sheet.gd"
		"bleach_closet":
			path = "res://src/ui/bleach_sheet.gd"
		_:
			return
	var sheet: Control = load(path).new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	FamilyProfile.peek_menu()
	_refresh_new_dots()
	if sheet.has_signal("closed"):
		sheet.closed.connect(_clear_modal)
	if sheet.has_signal("need_refresh"):
		sheet.need_refresh.connect(_after_page)


func _open_intake() -> void:
	_clear_modal()
	_modal = ColorRect.new()
	_modal.color = Color(0, 0, 0, 0.72)
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -260
	card.offset_right = 260
	card.offset_top = -160
	card.offset_bottom = 160
	_modal.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = Copy.INTAKE
	UiKit.apply_label(h, 22, Palette.LEMON)
	col.add_child(h)
	var sub := Label.new()
	sub.text = "Roles stay The Father and The Son. You only get to pick the names people shout."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(sub, 14, Palette.MUTED)
	col.add_child(sub)
	var son_in := LineEdit.new()
	son_in.placeholder_text = "The Son's display name"
	son_in.text = str(FamilyProfile.data.get("son_name", ""))
	col.add_child(son_in)
	var dad_in := LineEdit.new()
	dad_in.placeholder_text = "The Father's display name"
	dad_in.text = str(FamilyProfile.data.get("father_name", ""))
	col.add_child(dad_in)
	var go := UiKit.button("FILE THE NAMES", Vector2(200, 44))
	go.pressed.connect(func() -> void:
		FamilyProfile.data["son_name"] = son_in.text.strip_edges()
		FamilyProfile.data["father_name"] = dad_in.text.strip_edges()
		FamilyProfile.data["named"] = true
		FamilyProfile.save()
		_clear_modal()
		_show_tab(_current)
	)
	col.add_child(go)
	go.grab_focus()


func _open_settings() -> void:
	_clear_modal()
	var sheet := preload("res://src/ui/settings_sheet.gd").new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(_clear_modal)
	if sheet.has_signal("need_refresh"):
		sheet.need_refresh.connect(_after_page)


func _focus_page(page: Node) -> void:
	var btn := _first_button(page)
	if btn:
		btn.grab_focus()


func _first_button(n: Node) -> Button:
	if n is Button and (n as Button).visible and not (n as Button).disabled:
		return n
	for c in n.get_children():
		var b := _first_button(c)
		if b:
			return b
	return null


func _apply_safe() -> void:
	if _safe == null:
		return
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.x <= 0:
		_safe.add_theme_constant_override("margin_left", 8)
		_safe.add_theme_constant_override("margin_top", 4)
		_safe.add_theme_constant_override("margin_right", 8)
		_safe.add_theme_constant_override("margin_bottom", 8)
		return
	_safe.add_theme_constant_override("margin_left", maxi(8, safe.position.x))
	_safe.add_theme_constant_override("margin_top", maxi(4, safe.position.y))
	_safe.add_theme_constant_override("margin_right", maxi(8, win.x - safe.end.x))
	_safe.add_theme_constant_override("margin_bottom", maxi(8, win.y - safe.end.y))


func _modal_text(title: String, body: String) -> void:
	_clear_modal()
	_modal = ColorRect.new()
	_modal.color = Color(0, 0, 0, 0.72)
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -300
	card.offset_right = 300
	card.offset_top = -180
	card.offset_bottom = 180
	_modal.add_child(card)
	var col := VBoxContainer.new()
	card.add_child(col)
	var h := Label.new()
	h.text = title
	UiKit.apply_label(h, 22, Palette.LEMON)
	col.add_child(h)
	var t := Label.new()
	t.text = body
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(t, 16, Palette.TEXT)
	col.add_child(t)
	var close := UiKit.button("CLOSE", Vector2(120, 40))
	close.pressed.connect(_clear_modal)
	col.add_child(close)


func _clear_modal() -> void:
	if _modal and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
