extends Control

signal need_refresh
signal need_sheet(id: String)

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

	# Reference header: lemon in the brick arch, FATHER & SON in gold pixel
	# caps, THE BASEMENT CLINIC under it, tonight's difficulty as a tag.
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", -2)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo_lemon.png")
	logo.custom_minimum_size = Vector2(124, 94)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = SpriteBook.UI_FILTER
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Warm god-rays behind the emblem (reference board).
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.82, 0.4, 0.55))
	g.set_color(1, Color(1.0, 0.82, 0.4, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.55)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 256
	gt.height = 256
	var halo := Control.new()
	halo.custom_minimum_size = Vector2(124, 94)
	halo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var gr := TextureRect.new()
	gr.texture = gt
	gr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gr.position = Vector2(-150, -110)
	gr.size = Vector2(424, 300)
	gr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.add_child(gr)
	logo.position = Vector2.ZERO
	logo.size = Vector2(124, 94)
	logo.custom_minimum_size = Vector2.ZERO
	halo.add_child(logo)
	head.add_child(halo)
	var t := UiKit.title("FATHER & SON", 38, Palette.EDGE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(t)
	var sub := Label.new()
	sub.text = "THE BASEMENT CLINIC  ·  %s TONIGHT" % str(App.difficulty).replace("_", " ").to_upper()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(sub, 14, UiKit.GOLD)
	head.add_child(sub)
	col.add_child(head)

	col.add_child(_daily_strip())

	var play := UiKit.button(Copy.PLAY, Vector2(320, 52))
	play.add_theme_stylebox_override("normal", UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD))
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hop := FamilyProfile.next_run_map()
	var enter_lock := PowerBook.lock(hop, "enter")
	var boss_lock := PowerBook.lock(hop, "boss")
	if not enter_lock.is_empty():
		play.disabled = true
		play.text = PowerBook.line(enter_lock)
	else:
		UiKit.pulse_ready(play)
		play.pressed.connect(func() -> void:
			App.couch = false
			App.start_run()
		)
	col.add_child(play)
	var lock_lab_ref: Label = null
	if not enter_lock.is_empty() or not boss_lock.is_empty():
		var lock_lab := Label.new()
		lock_lab_ref = lock_lab
		lock_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lab.text = PowerBook.line(enter_lock if not enter_lock.is_empty() else boss_lock)
		var way := PowerBook.path_line(hop)
		if way != "":
			lock_lab.text += "\nNEXT:  " + way
		lock_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(lock_lab, 14, Palette.BRICK)
		col.add_child(lock_lab)
	var play_sub := Label.new()
	play_sub.text = Copy.CLINIC_PLAY_SUB
	play_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(play_sub, 13, Palette.MUTED)
	col.add_child(play_sub)

	var featured := preload("res://src/ui/clinic_featured.gd").new()
	featured.pick.connect(_detail)
	col.add_child(featured)
	var all_rooms := UiKit.button("ALL CAMP ROOMS  ▸", Vector2(300, 44))
	all_rooms.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	all_rooms.pressed.connect(_all_rooms)
	col.add_child(all_rooms)
	# PLAY (and what still blocks it) right under the title, then the rooms:
	# a new family sees how to go out before the camp board.
	var at := head.get_index() + 1
	col.move_child(play, at)
	if lock_lab_ref != null:
		col.move_child(lock_lab_ref, at + 1)
		at += 1
	col.move_child(featured, at + 1)
	col.move_child(all_rooms, at + 2)
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
		UiKit.dark_text(b)
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


func _on_built(id: String) -> void:
	# An upgrade is a toast; the first build is the big banner.
	if FamilyProfile.building_level(id) > 1:
		Juice.toast("unlock", "%s  ·  LV %d" % [id.replace("_", " ").to_upper(), FamilyProfile.building_level(id)], "Upgraded.")
		need_refresh.emit()
		return
	match id:
		"therapy_couch":
			Juice.unlock_logo("SKILL TREE", "The couch is furniture. The tree is a lifestyle.", "TAB  ·  BUILD", SpriteBook.icon(id))
		"wardrobe_cage":
			Juice.unlock_logo("LOCKER", "Costumes do not change the web. That is the point.", "TAB  ·  LOCKER", SpriteBook.icon(id))
		"trophy_cabinet":
			Juice.unlock_logo("AWARDS", "Claim or it did not happen.", "TAB  ·  AWARDS", SpriteBook.icon(id))
		"pawn_shop":
			Juice.unlock_logo("DOPAMINE SHOP", "Chests, wheel, slots. Upgrade the stall and the stock gets meaner.", "SHOP  ·  DOPAMINE", SpriteBook.icon(id))
		"patrol_desk":
			Juice.unlock_logo("QUICK PATROL", "2×/day. Ticks while you play and while the fridge is closed.", "PATROL  ·  IDLE", SpriteBook.icon(id))
		"research_lab":
			Juice.unlock_logo("RESEARCH CENTER", "Silencers, mags, hollow feelings.", "RESEARCH", SpriteBook.icon(id))
		"dojo":
			Juice.unlock_logo("MARTIAL ARTS SCHOOL", "Learn. Master. Pin a shaolin badge.", "DOJO", SpriteBook.icon(id))
		"workshop":
			Juice.unlock_logo("WORKSHOP", "Parts in. A body out. Gear is the build.", "CRAFT", SpriteBook.icon(id))
		"tip_jar":
			Juice.unlock_logo("TIP JAR", "Five gold. The jar might love you back.", "CAMP  ·  TIP", SpriteBook.icon(id))
		"lost_found":
			Juice.unlock_logo("LOST AND FOUND", "A pipe for later. Tutoring can wait.", "CAMP  ·  PACK", SpriteBook.icon(id))
		"payphone":
			Juice.unlock_logo("PAYPHONE", "Dial City Hall. The cord is sticky.", "CAMP  ·  PHONE", SpriteBook.icon(id))
		"water_cooler":
			Juice.unlock_logo("WATER COOLER", "The water is free. The gossip is billed.", "CAMP  ·  COOLER", SpriteBook.icon(id))
		"coat_check":
			Juice.unlock_logo("COAT CHECK", "Tape on a hanger. The copay still wants a wrap.", "CAMP  ·  TAPE", SpriteBook.icon(id))
		"time_clock":
			Juice.unlock_logo("TIME CLOCK", "Punch in. Six gold. The shift still wants a copay.", "CAMP  ·  SHIFT", SpriteBook.icon(id))
		"bleach_closet":
			Juice.unlock_logo("BLEACH CLOSET", "A fizz for later. The mop still wants tuition.", "CAMP  ·  FIZZ", SpriteBook.icon(id))
		_:
			var info := {}
			var list: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
			if list is Array:
				for b: Variant in list:
					if b is Dictionary and str((b as Dictionary)["id"]) == id:
						info = b
			Juice.carpenter(str(info.get("name", id.replace("_", " "))), str(info.get("unlocks", "CAMP")), id)
	need_refresh.emit()


## Card popup: big picture, name, what it unlocks, the blurb, level, and the
## actions (OPEN / BUILD / UPGRADE) - the card itself stays a clean picture.
func _detail(id: String) -> void:
	var info := {}
	var list: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	if list is Array:
		for b: Variant in list:
			if b is Dictionary and str((b as Dictionary)["id"]) == id:
				info = b
	var lvl := FamilyProfile.building_level(id)
	var cost := FamilyProfile.build_cost(id)
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var card := PanelContainer.new()
	var st := preload("res://src/ui/clinic_featured.gd").card_style(true)
	st.content_margin_left = 22
	st.content_margin_right = 22
	st.content_margin_top = 18
	st.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", st)
	card.position = Vector2(330, 60)
	card.custom_minimum_size = Vector2(620, 0)
	layer.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var pic := UiKit.portrait(SpriteBook.icon(id), Vector2(570, 210))
	col.add_child(pic)
	var title := UiKit.title(preload("res://src/ui/clinic_featured.gd").card_name(id, str(info.get("name", id))), 34, Palette.EDGE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var tag := Label.new()
	tag.text = ("LV %d" % lvl if lvl > 0 else "NOT BUILT") + "  ·  UNLOCKS  " + str(info.get("unlocks", "CAMP")).to_upper()
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(tag, 15, UiKit.GOLD)
	col.add_child(tag)
	var blurb := Label.new()
	blurb.text = str(info.get("blurb", ""))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(blurb, 16, Palette.TEXT)
	col.add_child(blurb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	var can_pay := int(FamilyProfile.data["gold"]) >= cost
	if lvl > 0 and (id in CampSheets.PATHS or CampSheets.TAB_OF.has(id)):
		var open := UiKit.button("OPEN", Vector2(170, 50))
		open.pressed.connect(func() -> void:
			layer.queue_free()
			if CampSheets.TAB_OF.has(id):
				App.tab_wanted.emit(str(CampSheets.TAB_OF[id]))
			else:
				need_sheet.emit(id)
		)
		row.add_child(open)
	if lvl < 4:
		var b := UiKit.button(("BUILD  %d G" if lvl == 0 else "UPGRADE  %d G") % cost, Vector2(220, 50))
		b.disabled = not can_pay
		if not can_pay:
			b.text = "NEED %d GOLD" % cost
		var blk := FamilyProfile.build_blocker(id)
		if blk != "":
			b.disabled = true
			b.text = FamilyProfile.blocker_text(id)
			b.custom_minimum_size = Vector2(320, 50)
		b.pressed.connect(func() -> void:
			if FamilyProfile.try_build(id):
				Juice.play("res://assets/audio/hammer.wav")
				layer.queue_free()
				_on_built(id)
		)
		row.add_child(b)
	var close := UiKit.button("CLOSE", Vector2(140, 50))
	close.pressed.connect(layer.queue_free)
	row.add_child(close)
	(row.get_child(0) as Button).call_deferred("grab_focus")
	UiKit.pop_in(card)


## Every room, the full grid (the old camp board) in a scroll sheet.
func _all_rooms() -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var sc := ScrollContainer.new()
	sc.position = Vector2(20, 10)
	sc.size = Vector2(1210, 520)
	layer.add_child(sc)
	var camp := preload("res://src/ui/clinic_camp.gd").new()
	camp.built.connect(func(bid: String) -> void:
		layer.queue_free()
		_on_built(bid)
	)
	camp.open_sheet.connect(func(sid: String) -> void:
		layer.queue_free()
		need_sheet.emit(sid)
	)
	sc.add_child(camp)
	var close := UiKit.button("CLOSE", Vector2(160, 44))
	close.position = Vector2(545, 538)
	close.pressed.connect(layer.queue_free)
	layer.add_child(close)
	close.call_deferred("grab_focus")
