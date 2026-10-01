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
	logo.custom_minimum_size = Vector2(150, 113)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = SpriteBook.UI_FILTER
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_child(logo)
	var t := UiKit.title("FATHER & SON", 44, Palette.EDGE)
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
	if not enter_lock.is_empty() or not boss_lock.is_empty():
		var lock_lab := Label.new()
		lock_lab.text = PowerBook.line(enter_lock if not enter_lock.is_empty() else boss_lock)
		lock_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(lock_lab, 14, Palette.BRICK)
		col.add_child(lock_lab)
	var play_sub := Label.new()
	play_sub.text = Copy.CLINIC_PLAY_SUB
	play_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(play_sub, 13, Palette.MUTED)
	col.add_child(play_sub)

	var camp := preload("res://src/ui/clinic_camp.gd").new()
	camp.built.connect(func(id: String) -> void:
		match id:
			"therapy_couch":
				Juice.unlock_logo("BUILD TAB", "The couch is furniture. The tree is a lifestyle.", "TAB  ·  BUILD")
			"wardrobe_cage":
				Juice.unlock_logo("LOCKER", "Costumes do not change the web. That is the point.", "TAB  ·  LOCKER")
			"trophy_cabinet":
				Juice.unlock_logo("AWARDS", "Claim or it did not happen.", "TAB  ·  AWARDS")
			"pawn_shop":
				Juice.unlock_logo("CAMP UNLOCKED", "Chests, wheel, slots. Upgrade the stall and the stock gets meaner.", "SHOP  ·  DOPAMINE")
			"patrol_desk":
				Juice.unlock_logo("QUICK PATROL", "2×/day. Ticks while you play and while the fridge is closed.", "PATROL  ·  IDLE")
			"research_lab":
				Juice.unlock_logo("RESEARCH CENTER", "Silencers, mags, hollow feelings.", "RESEARCH")
			"dojo":
				Juice.unlock_logo("MARTIAL ARTS SCHOOL", "Learn. Master. Pin a shaolin badge.", "DOJO")
			"workshop":
				Juice.unlock_logo("WORKSHOP", "Parts in. A body out. Gear is the build.", "CRAFT")
			"tip_jar":
				Juice.unlock_logo("TIP JAR", "Five gold. The jar might love you back.", "CAMP  ·  TIP")
			"lost_found":
				Juice.unlock_logo("LOST AND FOUND", "A pipe for later. Tutoring can wait.", "CAMP  ·  PACK")
			"payphone":
				Juice.unlock_logo("PAYPHONE", "Dial City Hall. The cord is sticky.", "CAMP  ·  PHONE")
			"water_cooler":
				Juice.unlock_logo("WATER COOLER", "The water is free. The gossip is billed.", "CAMP  ·  COOLER")
			"coat_check":
				Juice.unlock_logo("COAT CHECK", "Tape on a hanger. The copay still wants a wrap.", "CAMP  ·  TAPE")
			"time_clock":
				Juice.unlock_logo("TIME CLOCK", "Punch in. Six gold. The shift still wants a copay.", "CAMP  ·  SHIFT")
			"bleach_closet":
				Juice.unlock_logo("BLEACH CLOSET", "A fizz for later. The mop still wants tuition.", "CAMP  ·  FIZZ")
		need_refresh.emit()
	)
	if camp.has_signal("open_sheet"):
		camp.open_sheet.connect(func(id: String) -> void:
			need_sheet.emit(id)
		)
	col.add_child(camp)
	# Cards right under the logo like the reference; daily goals + GO below.
	col.move_child(camp, 1)
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
