extends Control

const TABS := ["clinic", "run", "heroes", "build", "locker", "awards"]

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
var _avatar_names: Label
var _avatar_lv: Label
var _avatar_xp: ProgressBar
var _avatar_dot: ColorRect
var _logo_dot: ColorRect
var _tab_dots: Dictionary = {}


func _ready() -> void:
	PixelStage.apply_control(self)
	FamilyProfile._roll_daily()
	Mixer.play_music("res://assets/audio/music/music_menu.ogg")
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
	# The wharf at night behind every menu (reference board), dimmed so the
	# navy cards read on top; 8/3 design px per texel = 4 screen px.
	if ResourceLoader.exists("res://assets/backdrops/dock.png"):
		var city := TextureRect.new()
		city.texture = load("res://assets/backdrops/dock.png")
		city.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		city.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		city.stretch_mode = TextureRect.STRETCH_SCALE
		var tw := float(city.texture.get_width()) * 8.0 / 3.0
		city.size = Vector2(tw, float(city.texture.get_height()) * 8.0 / 3.0)
		city.position = Vector2((1280.0 - tw) * 0.5, 0.0)
		city.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(city)

	var night := ColorRect.new()
	night.color = Color(0.02, 0.03, 0.08, 0.62)
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# No slab across the top: the city shows through (reference board).
	bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)

	var avatar_wrap := Control.new()
	avatar_wrap.custom_minimum_size = Vector2(246, 64)
	var avatar := UiKit.button("", Vector2(240, 64))
	_avatar_btn = avatar
	avatar.pressed.connect(_open_profile)
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_wrap.add_child(avatar)
	# Profile card: both patients, names, account level and XP to next.
	var card := HBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 8
	card.offset_right = -8
	card.add_theme_constant_override("separation", 6)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for who in ["son", "father"]:
		var pic := UiKit.portrait(SpriteBook.bust(who), Vector2(44, 56))
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(pic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_names = UiKit.title("", 15, Palette.TEXT)
	_avatar_names.clip_text = true
	_avatar_names.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_avatar_names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_avatar_names)
	var lv_row := HBoxContainer.new()
	lv_row.add_theme_constant_override("separation", 6)
	lv_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_lv = Label.new()
	UiKit.apply_label(_avatar_lv, 13, Palette.LEMON)
	lv_row.add_child(_avatar_lv)
	_avatar_xp = UiKit.glow_bar(0.0, Palette.READY, Vector2(96, 8))
	_avatar_xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lv_row.add_child(_avatar_xp)
	info.add_child(lv_row)
	card.add_child(info)
	avatar.add_child(card)
	_avatar_dot = UiKit.new_dot()
	_avatar_dot.position = Vector2(232, -2)
	avatar_wrap.add_child(_avatar_dot)
	row.add_child(avatar_wrap)
	var log_btn := UiKit.button("LOG", Vector2(64, 38))
	log_btn.pressed.connect(_open_log)
	var log_wrap := Control.new()
	log_wrap.custom_minimum_size = Vector2(66, 40)
	log_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_wrap.add_child(log_btn)
	_log_bang = UiKit.bang()
	_log_bang.position = Vector2(48, -4)
	log_wrap.add_child(_log_bang)
	row.add_child(log_wrap)
	var stats := UiKit.button("STATS", Vector2(84, 38))
	stats.pressed.connect(_open_stats)
	row.add_child(stats)
	var armory := UiKit.button("ARMORY", Vector2(104, 38))
	armory.pressed.connect(_open_armory)
	row.add_child(armory)
	var codex := UiKit.button("CODEX", Vector2(96, 38))
	codex.pressed.connect(_open_codex)
	row.add_child(codex)
	var jobs := UiKit.button("JOBS", Vector2(76, 38))
	jobs.pressed.connect(_open_jobs)
	var jobs_wrap := Control.new()
	jobs_wrap.custom_minimum_size = Vector2(78, 40)
	jobs.set_anchors_preset(Control.PRESET_FULL_RECT)
	jobs_wrap.add_child(jobs)
	_jobs_bang = UiKit.bang()
	_jobs_bang.position = Vector2(60, -4)
	_jobs_bang.visible = Contracts.ready_count() > 0
	jobs_wrap.add_child(_jobs_bang)
	row.add_child(jobs_wrap)
	var gear := UiKit.button(Copy.OPTIONS, Vector2(100, 38))
	gear.pressed.connect(_open_settings)
	row.add_child(gear)


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
	logo_wrap.visible = false
	logo_box.add_child(logo_wrap)
	row.add_child(logo_box)
	# Currency exactly like the reference board: big pixel icon, the name and
	# the number in cream pixel caps, no boxes, spaced out at the top right.
	var purse := HBoxContainer.new()
	purse.add_theme_constant_override("separation", 26)
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gold_pill = UiKit.pill("GOLD", "0", Palette.EDGE)
	_gems_pill = UiKit.pill("GEMS", "0", Palette.LEMON)
	_rep_pill = UiKit.pill("REP", "0", Palette.BRICK)
	purse.add_child(_gold_pill)
	purse.add_child(_gems_pill)
	purse.add_child(_rep_pill)

	row.add_child(purse)

	_refresh_pills()
	return bar


## Bottom tab bar like the reference: one framed strip, an icon + pixel
## caps per tab, the open tab in a lit gold box.
const TAB_ICON := {"clinic": "front_desk", "run": "street_map", "build": "therapy_couch", "locker": "wardrobe_cage", "awards": "trophy_cabinet", "heroes": "punching_bag"}


func _make_tabs() -> Control:
	var center := CenterContainer.new()
	var bar := PanelContainer.new()
	var st := UiKit.panel(UiKit.NAVY, UiKit.RIM)
	st.content_margin_left = 6
	st.content_margin_right = 6
	st.content_margin_top = 5
	st.content_margin_bottom = 5
	bar.add_theme_stylebox_override("panel", st)
	bar.custom_minimum_size = Vector2(1180, 0)
	center.add_child(bar)
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	bar.add_child(_tab_bar)
	for id in TABS:
		var wrap := Control.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.custom_minimum_size = Vector2(0, 52)
		var b := UiKit.button(_tab_title(id), Vector2(0, 52))
		b.icon = SpriteBook.icon(str(TAB_ICON.get(id, "")))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
		b.add_theme_constant_override("h_separation", 10)
		b.name = id
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.pressed.connect(_show_tab.bind(id))
		wrap.add_child(b)
		var bang := UiKit.bang()
		bang.position = Vector2(2, -12)
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
	return center


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
		"heroes":
			return "HEROES"
		_:
			return Copy.TAB_AWARDS


## Pad / keyboard: LB / RB (or Q / E) step through the tabs.
func _unhandled_input(event: InputEvent) -> void:
	var step := 0
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			step = -1
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			step = 1
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			step = -1
		elif event.keycode == KEY_E:
			step = 1
	if step == 0:
		return
	var i := TABS.find(_current)
	for k in TABS.size():
		i = (i + step + TABS.size()) % TABS.size()
		if FamilyProfile.tab_unlocked(TABS[i]):
			_show_tab(TABS[i])
			Juice.play("res://assets/audio/ui_click.wav")
			get_viewport().set_input_as_handled()
			return


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
		"heroes":
			page = preload("res://src/ui/hub_heroes.gd").new()
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
	_set_pill(_gold_pill, UiKit.num(FamilyProfile.data["gold"]), "gold")
	_set_pill(_gems_pill, UiKit.num(FamilyProfile.data["gems"]), "gems")
	_set_pill(_rep_pill, UiKit.num(FamilyProfile.data["rep"]), "rep")
	_log_bang.visible = FamilyProfile.unread_log_count() > 0
	_refresh_new_dots()
	if _avatar_names:
		_avatar_names.text = "%s  &  %s" % [FamilyProfile.son_name(), FamilyProfile.father_name()]
		var need := maxf(1.0, float(FamilyProfile.account_need()))
		var xp := float(FamilyProfile.data.get("account_xp", 0))
		_avatar_lv.text = "LV %d" % int(FamilyProfile.data.get("account_level", 1))
		_avatar_xp.value = clampf(xp / need, 0.0, 1.0)
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
				btn.text = _tab_title(id)
				# Locked tabs read as dark, not as a word glued on the label.
				btn.modulate = Color.WHITE if unlocked else Color(0.45, 0.45, 0.52)
				var bang: Control = _tab_bangs[id]
				var unseen: bool = unlocked and not bool(FamilyProfile.data["seen"].get(id, false))
				var awards_ready: bool = id == "awards" and unlocked and _has_claim()
				# HEROES: something to spend on (a level, a rarity, a META rank).
				var heroes_ready: bool = id == "heroes" and _heroes_ready()
				bang.visible = unseen or awards_ready or heroes_ready
				var dot: Control = _tab_dots.get(id)
				if dot:
					dot.visible = id == "clinic" and FamilyProfile.has_menu_alert() and not bang.visible
				if id == _current:
					var on := UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD)
					on.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.45)
					on.shadow_size = 10
					btn.add_theme_stylebox_override("normal", on)
				else:
					var off := StyleBoxFlat.new()
					off.bg_color = Color(0, 0, 0, 0)
					off.border_color = Color(UiKit.RIM.r, UiKit.RIM.g, UiKit.RIM.b, 0.35)
					off.border_width_right = 1
					btn.add_theme_stylebox_override("normal", off)


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
	# One global alert reads on the home tab only (and never next to a "!"),
	# not as a red square on every tab.
	for id in _tab_dots.keys():
		var d: Control = _tab_dots[id]
		var bg: Control = _tab_bangs.get(id)
		if d:
			d.visible = alert and id == "clinic" and not (bg != null and bg.visible)


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


var _jobs_bang: Control


func _open_jobs() -> void:
	_clear_modal()
	var sheet := preload("res://src/ui/desk_sheet.gd").new()
	sheet.mode = "contracts"
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(func() -> void:
		_clear_modal()
		if _jobs_bang:
			_jobs_bang.visible = Contracts.ready_count() > 0
	)
	sheet.need_refresh.connect(_refresh_pills)


func _open_codex() -> void:
	_clear_modal()
	var sheet := preload("res://src/ui/codex_sheet.gd").new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(_clear_modal)


func _open_armory() -> void:
	_clear_modal()
	var sheet := preload("res://src/ui/armory_sheet.gd").new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(_clear_modal)


func _open_stats() -> void:
	_clear_modal()
	var sheet := preload("res://src/ui/stats_sheet.gd").new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(_clear_modal)


func _open_camp_sheet(id: String) -> void:
	_clear_modal()
	var path := CampSheets.path(id)
	if path == "":
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
	var m := PixelStage.safe_design_margins()
	_safe.add_theme_constant_override("margin_left", m.x)
	_safe.add_theme_constant_override("margin_top", m.y)
	_safe.add_theme_constant_override("margin_right", m.z)
	_safe.add_theme_constant_override("margin_bottom", m.w)


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



func _heroes_ready() -> bool:
	for r in Heroes.ROLES:
		if Heroes.can_level(r) or Heroes.can_rank(r):
			return true
	for id in Meta.LIST.keys():
		if Meta.blocker(id) == "":
			return true
	return false
