extends Control

signal need_refresh

var _mode_row: HBoxContainer
var _role_row: HBoxContainer
var _go: Button
var _hint: Label
var _counts: StatPanel


## RUN page after Timmie's reference board: a big gold title, a framed
## fight scene made from the game's own art (the wharf backdrop, the Father
## landing a kick on a punk), difficulty buttons stacked on the right, a
## gold lock ribbon when the next boss is gated, START at the bottom.
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var stage := Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)

	var over := UiKit.title("Father & Son", 24, Palette.EDGE)
	over.position = Vector2(0, 0)
	over.size = Vector2(1248, 30)
	over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(over)
	for x in [380.0, 790.0]:
		var line := ColorRect.new()
		line.color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.6)
		line.position = Vector2(x, 15)
		line.size = Vector2(80, 2)
		stage.add_child(line)
	var h := UiKit.title(StageCard.title_of(FamilyProfile.next_run_map()), 46, Palette.EDGE)
	h.position = Vector2(0, 26)
	h.size = Vector2(1248, 56)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(h)

	stage.add_child(_scene(Rect2(40, 96, 720, 330)))

	var right := VBoxContainer.new()
	right.position = Vector2(800, 104)
	right.size = Vector2(300, 330)
	right.add_theme_constant_override("separation", 12)
	stage.add_child(right)
	for pair in [["night_class", "NIGHT CLASS"], ["open_house", "OPEN HOUSE"], ["finals", "FINALS"]]:
		var b := UiKit.button(pair[1], Vector2(300, 56))
		b.add_theme_font_size_override("font_size", 20)
		if App.difficulty == pair[0]:
			var on := UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD)
			on.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.5)
			on.shadow_size = 12
			b.add_theme_stylebox_override("normal", on)
		b.pressed.connect(func() -> void:
			App.difficulty = pair[0]
			FamilyProfile.data["difficulty"] = pair[0]
			FamilyProfile.save()
			need_refresh.emit()
		)
		right.add_child(b)
	var diff_hint := Label.new()
	diff_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diff_hint.custom_minimum_size = Vector2(300, 0)
	match App.difficulty:
		"open_house":
			diff_hint.text = Copy.OPEN_HOUSE
		"finals":
			diff_hint.text = Copy.FINALS
		_:
			diff_hint.text = Copy.NIGHT_CLASS
	UiKit.apply_label(diff_hint, 13, Palette.MUTED)
	right.add_child(diff_hint)
	_mode_row = HBoxContainer.new()
	_mode_row.add_theme_constant_override("separation", 8)
	right.add_child(_mode_row)
	_paint_modes()
	_role_row = HBoxContainer.new()
	_role_row.add_theme_constant_override("separation", 6)
	right.add_child(_role_row)
	_paint_roles()

	# Gold ribbon over the frame's lower edge when a gate blocks the run.
	var ribbon := PanelContainer.new()
	ribbon.name = "Ribbon"
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.86, 0.66, 0.26)
	rs.border_color = UiKit.INK
	rs.set_border_width_all(3)
	rs.content_margin_left = 18
	rs.content_margin_right = 44
	rs.content_margin_top = 6
	rs.content_margin_bottom = 6
	ribbon.add_theme_stylebox_override("panel", rs)
	ribbon.position = Vector2(46, 322)
	stage.add_child(ribbon)
	var lock_lab := Label.new()
	lock_lab.name = "PowerLock"
	lock_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lock_lab.custom_minimum_size = Vector2(420, 0)
	lock_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_lab.add_theme_font_override("font", UiKit.pixel_font())
	lock_lab.add_theme_font_size_override("font_size", 15)
	lock_lab.add_theme_color_override("font_color", UiKit.INK)
	ribbon.add_child(lock_lab)
	var seal := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.55, 0.38, 0.12)
	ss.border_color = UiKit.GOLD
	ss.set_border_width_all(3)
	ss.set_corner_radius_all(36)
	ss.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.6)
	ss.shadow_size = 12
	seal.add_theme_stylebox_override("panel", ss)
	seal.custom_minimum_size = Vector2(72, 72)
	seal.position = Vector2(690, 300)
	seal.name = "Seal"
	var seal_pic := UiKit.portrait(SpriteBook.icon("therapy_couch"), Vector2(56, 56))
	seal.add_child(seal_pic)
	stage.add_child(seal)
	_paint_lock(lock_lab)
	ribbon.visible = lock_lab.visible
	seal.visible = lock_lab.visible

	_go = UiKit.button("START", Vector2(320, 58))
	_go.add_theme_font_override("font", UiKit.title_font())
	_go.add_theme_font_size_override("font_size", 30)
	_go.position = Vector2(464, 446)
	UiKit.pulse_ready(_go)
	_bind_go()
	stage.add_child(_go)

	stage.add_child(_weekly_card())

	var extra := HBoxContainer.new()
	extra.position = Vector2(40, 470)
	extra.add_theme_constant_override("separation", 8)
	var intro_b := UiKit.button(Copy.PLAY_INTRO, Vector2(150, 36))
	intro_b.add_theme_font_size_override("font_size", 12)
	intro_b.pressed.connect(App.play_intro)
	var vs_b := UiKit.button(Copy.VERSUS, Vector2(110, 36))
	vs_b.add_theme_font_size_override("font_size", 12)
	vs_b.pressed.connect(App.start_versus)
	extra.add_child(intro_b)
	extra.add_child(vs_b)
	# NIGHT ARTIFACTS: risk / reward rules for the next nights.
	var art := UiKit.button("ARTIFACTS %d/%d" % [Artifacts.on().size(), Artifacts.MAX_ON], Vector2(150, 36))
	art.add_theme_font_size_override("font_size", 12)
	if not Artifacts.on().is_empty():
		art.add_theme_color_override("font_color", Color(0.85, 0.45, 1.0))
	art.pressed.connect(func() -> void:
		var sh := preload("res://src/ui/desk_sheet.gd").new()
		sh.mode = "artifacts"
		get_tree().current_scene.add_child(sh)
		sh.closed.connect(func() -> void:
			sh.queue_free()
			art.text = "ARTIFACTS %d/%d" % [Artifacts.on().size(), Artifacts.MAX_ON]
			art.grab_focus()
		)
	)
	extra.add_child(art)
	# CARD VAULT: draw level-up cards (opens after the first night out).
	var vault_open := int(FamilyProfile.data.get("runs", 0)) >= 1
	var vb := UiKit.button("CARD VAULT  ·  %d TOKENS" % VaultCards.tokens() if vault_open else "VAULT  ·  AFTER NIGHT 1", Vector2(220, 36))
	vb.add_theme_font_size_override("font_size", 12)
	vb.disabled = not vault_open
	if vault_open:
		vb.add_theme_color_override("font_color", UiKit.GOLD)
	vb.pressed.connect(func() -> void:
		var hub := get_tree().current_scene
		if hub and hub.has_method("_open_vault"):
			hub.call("_open_vault")
		else:
			var sh := preload("res://src/ui/vault_sheet.gd").new()
			get_tree().current_scene.add_child(sh)
			sh.closed.connect(sh.queue_free)
	)
	vb.position = Vector2(40, 514)
	stage.add_child(vb)
	stage.add_child(extra)
	var net := HBoxContainer.new()
	net.position = Vector2(820, 470)
	net.add_theme_constant_override("separation", 8)
	var host := UiKit.button(Copy.HOST, Vector2(190, 36))
	var join := UiKit.button(Copy.JOIN, Vector2(200, 36))
	for b in [host, join]:
		(b as Button).add_theme_font_size_override("font_size", 12)
	host.pressed.connect(func() -> void:
		get_tree().root.add_child(preload("res://src/ui/host_wait.gd").new())
	)
	join.pressed.connect(func() -> void:
		get_tree().root.add_child(preload("res://src/ui/join_sheet.gd").new())
	)
	net.add_child(host)
	net.add_child(join)
	stage.add_child(net)
	_hint = Label.new()
	_hint.visible = false
	stage.add_child(_hint)
	_refresh_copy()
	_go.grab_focus()


## The framed fight: wharf backdrop crop, Father at his side-kick contact
## frame, a punk reeling. All from the shipped sprite sheets, 1:1 on 1080p.
func _scene(r: Rect2) -> Control:
	var frame := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.02, 0.03, 0.06)
	fs.border_color = UiKit.GOLD
	fs.set_border_width_all(5)
	fs.set_corner_radius_all(2)
	fs.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.3)
	fs.shadow_size = 10
	frame.add_theme_stylebox_override("panel", fs)
	frame.position = r.position
	frame.size = r.size
	frame.clip_contents = true
	var view := Control.new()
	view.clip_contents = true
	view.custom_minimum_size = r.size - Vector2(10, 10)
	frame.add_child(view)
	var map_id := FamilyProfile.next_run_map()
	var art_path := "res://assets/sprites/missions/%s.png" % map_id
	if ResourceLoader.exists(art_path):
		# The night's own mission picture, 2x pixels, slowly pushing in.
		var bg := TextureRect.new()
		bg.texture = load(art_path)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = r.size - Vector2(10, 10)
		bg.pivot_offset = bg.size * 0.5
		view.add_child(bg)
		var push := bg.create_tween().set_loops()
		push.tween_property(bg, "scale", Vector2(1.04, 1.04), 9.0).set_trans(Tween.TRANS_SINE)
		push.tween_property(bg, "scale", Vector2.ONE, 9.0).set_trans(Tween.TRANS_SINE)
	else:
		var tex := StageCard.art(map_id)
		if tex:
			var fb := TextureRect.new()
			fb.texture = tex
			fb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			fb.size = r.size - Vector2(10, 10)
			view.add_child(fb)
	# Mission strip along the bottom: act number, the job, the target.
	var act := StoryBook.act(map_id)
	var strip := ColorRect.new()
	strip.color = Color(0.0, 0.0, 0.03, 0.72)
	strip.position = Vector2(0, r.size.y - 10.0 - 64.0)
	strip.size = Vector2(r.size.x - 10.0, 64)
	view.add_child(strip)
	var gold := ColorRect.new()
	gold.color = UiKit.GOLD
	gold.position = strip.position
	gold.size = Vector2(strip.size.x, 2)
	view.add_child(gold)
	var idx := App.ORDER.find(map_id)
	var tag := Label.new()
	tag.text = "MISSION %d/%d" % [idx + 1, App.ORDER.size()] if idx >= 0 else "MISSION"
	tag.position = Vector2(14, strip.position.y + 6.0)
	tag.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(tag, 13, UiKit.GOLD)
	view.add_child(tag)
	var job := Label.new()
	job.text = str(act.get("main", ""))
	job.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	job.position = Vector2(14, strip.position.y + 24.0)
	job.size = Vector2(strip.size.x - 28.0, 36)
	UiKit.apply_label(job, 14, Palette.TEXT)
	view.add_child(job)
	var boss: Variant = act.get("boss", {})
	if boss is Dictionary and str((boss as Dictionary).get("title", "")) != "":
		var tgt := Label.new()
		tgt.text = "TARGET  ·  %s" % str((boss as Dictionary)["title"]).to_upper()
		tgt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tgt.position = Vector2(strip.size.x - 410.0, strip.position.y + 6.0)
		tgt.size = Vector2(300, 16)
		tgt.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(tgt, 13, Palette.BRICK.lightened(0.2))
		view.add_child(tgt)
	return frame


func _actor(host: Control, who: String, clip: String, idx: int, feet: Vector2, flip: bool) -> void:
	var sf := SpriteBook.frames(who)
	if not sf.has_animation(clip) or sf.get_frame_count(clip) == 0:
		return
	var tex := sf.get_frame_texture(clip, clampi(idx, 0, sf.get_frame_count(clip) - 1))
	var pic := TextureRect.new()
	pic.texture = tex
	pic.flip_h = flip
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	# 1 texel = 1 screen px at 1080p (design scale 0.5 x 3).
	var s := Vector2(tex.get_width(), tex.get_height()) / 1.5
	pic.size = s
	pic.position = Vector2(feet.x - s.x * 0.5, feet.y - s.y + 4.0)
	host.add_child(pic)


func _paint_modes() -> void:
	for c in _mode_row.get_children():
		c.queue_free()
	for pair in [[false, Copy.SOLO], [true, Copy.COUCH]]:
		var on: bool = App.couch == pair[0]
		var b := UiKit.button(pair[1], Vector2(146, 36))
		b.add_theme_font_size_override("font_size", 13)
		if on:
			b.add_theme_stylebox_override("normal", UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD))
		b.pressed.connect(func() -> void:
			App.couch = pair[0]
			need_refresh.emit()
		)
		_mode_row.add_child(b)


func _paint_roles() -> void:
	for c in _role_row.get_children():
		c.queue_free()
	_role_row.visible = not App.couch
	if App.couch:
		return
	for pair in [["son", "THE SON"], ["father", "THE FATHER"]]:
		var b := UiKit.button(pair[1], Vector2(110, 36))
		b.add_theme_font_size_override("font_size", 12)
		if App.solo_role == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD))
		b.pressed.connect(func() -> void:
			App.solo_role = pair[0]
			need_refresh.emit()
		)
		var who := str(pair[0])
		_role_row.add_child(UiKit.portrait(SpriteBook.bust(who), Vector2(30, 36)))
		_role_row.add_child(b)


func _count_rows() -> Array:
	return [
		{"name": "SOLO PUNKS", "value": str(Party.count_for("dock_street", false)), "color": Palette.LEMON},
		{"name": "COUCH PUNKS", "value": str(Party.count_for("dock_street", true)), "color": Palette.BRICK},
		{"name": "MAP 2 SOLO", "value": str(Party.count_for("fire_escapes", false)), "color": Palette.EDGE},
		{"name": "MAP 3 SOLO", "value": str(Party.count_for("neon_exchange", false)), "color": Palette.LEMON},
		{"name": "MAP 4 SOLO", "value": str(Party.count_for("rail_bridge", false)), "color": Palette.EDGE},
		{"name": "HALL SOLO", "value": str(Party.count_for("city_hall", false)), "color": Palette.BRICK},
		{"name": "PIER SOLO", "value": str(Party.count_for("invoice_pier", false)), "color": Palette.READY},
		{"name": "FLOOR SOLO", "value": str(Party.count_for("processing_floor", false)), "color": Palette.BRICK},
		{"name": "LOT SOLO", "value": str(Party.count_for("intake_lot", false)), "color": Palette.LEMON},
		{"name": "COUCH EACH", "value": str(Party.count_for("dock_street", true)), "color": Palette.TEXT},
		{"name": "ORCHARD SOLO", "value": str(Party.count_for("copay_orchard", false)), "color": Palette.EDGE},
		{"name": "GRID SOLO", "value": str(Party.count_for("raven_grid", false)), "color": Palette.LEMON},
		{"name": "SLEET SOLO", "value": str(Party.count_for("sleet_hour", false)), "color": Palette.TEXT},
		{"name": "LEDGER SOLO", "value": str(Party.count_for("ledger_dive", false)), "color": Palette.READY},
		{"name": "ACTS", "value": "14", "color": Palette.READY},
		{"name": "HOURS", "value": "5", "color": Palette.EDGE},
		{"name": "HOST", "value": "SON", "color": Palette.LEMON},
		{"name": "JOIN", "value": "FATHER", "color": Palette.BRICK}
	]


func _refresh_copy() -> void:
	if _go:
		_go.text = "START"
		_go.tooltip_text = Copy.GO_COUCH if App.couch else Copy.GO_SOLO
		_bind_go()
	if _hint:
		_hint.text = (Copy.COUCH_HINT if App.couch else Copy.SOLO_HINT) + "  " + Copy.JOIN_HINT + "  " + Copy.REMOTE_HINT
	var lock_lab := get_node_or_null("PowerLock") as Label
	if lock_lab == null:
		for c in get_children():
			lock_lab = c.find_child("PowerLock", true, false) as Label
			if lock_lab:
				break
	if lock_lab:
		_paint_lock(lock_lab)


func _bind_go() -> void:
	if _go == null:
		return
	var hop := FamilyProfile.next_run_map()
	var enter_lock := PowerBook.lock(hop, "enter")
	if not enter_lock.is_empty():
		_go.disabled = true
		_go.text = PowerBook.line(enter_lock)
		if _go.pressed.is_connected(App.start_run):
			_go.pressed.disconnect(App.start_run)
	else:
		_go.disabled = false
		if not _go.pressed.is_connected(App.start_run):
			_go.pressed.connect(App.start_run)


func _paint_lock(lab: Label) -> void:
	var hop := FamilyProfile.next_run_map()
	var enter_lock := PowerBook.lock(hop, "enter")
	if not enter_lock.is_empty():
		lab.text = PowerBook.line(enter_lock)
		lab.visible = true
		return
	var boss_lock := PowerBook.lock(hop, "boss")
	if not boss_lock.is_empty():
		lab.text = PowerBook.line(boss_lock)
		lab.visible = true
		return
	lab.text = ""
	lab.visible = false



## WEEKLY GAUNTLET: a poster pinned in the preview's corner - this week's
## fixed coping hour, its two pacts, the best time and the weekly pay.
func _weekly_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Color(0.12, 0.05, 0.08, 0.94), Palette.BRICK))
	card.position = Vector2(548, 84)
	card.custom_minimum_size = Vector2(218, 0)
	card.rotation = deg_to_rad(2.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.add_child(UiKit.portrait(IconBook.tex("cur_calendar"), Vector2(26, 26)))
	var t := Label.new()
	t.text = "WEEKLY GAUNTLET"
	t.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(t, 14, UiKit.GOLD)
	head.add_child(t)
	v.add_child(head)
	var open := (FamilyProfile.data.get("maps_filed", []) as Array).has(WeeklyBook.MAP)
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(206, 0)
	if open:
		var b := WeeklyBook.best()
		info.text = "%s  ·  same street all week\n%s\nBEST %d:%02d  ·  TRIES %d\n%s" % [WeeklyBook.week_id(), WeeklyBook.rules_text(), b / 60, b % 60, WeeklyBook.tries(), "PAID THIS WEEK" if WeeklyBook.paid() else "HOLD 3:00: +3 GEMS +150 GOLD"]
	else:
		info.text = "File THE INTAKE LOT to open the weekly hour."
	UiKit.apply_label(info, 10, Palette.TEXT)
	v.add_child(info)
	var go := UiKit.button("ENTER" if open else "LOCKED", Vector2(206, 30))
	go.add_theme_font_size_override("font_size", 12)
	go.disabled = not open
	go.pressed.connect(App.start_weekly)
	v.add_child(go)
	return card
