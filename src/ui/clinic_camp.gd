extends Control

signal built(id: String)
signal open_sheet(id: String)

const SHEETS := ["pawn_shop", "patrol_desk", "research_lab", "dojo", "workshop", "bounty_board", "radio_tower", "album_wall", "blood_fridge", "streak_locker", "invoice_wheel", "punching_bag", "warrant_fax", "tip_jar", "lost_found", "payphone", "water_cooler", "coat_check", "time_clock", "bleach_closet"]
const COLS := 5


func _ready() -> void:
	custom_minimum_size = Vector2(1180, 680)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.custom_minimum_size = Vector2(1180, 0)
	add_child(center)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	center.add_child(grid)
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	for b in list:
		if typeof(b) == TYPE_DICTIONARY:
			grid.add_child(_spot(b))


func _spot(info: Dictionary) -> Control:
	var id := str(info["id"])
	var lvl := FamilyProfile.building_level(id)
	# The card is a PanelContainer; the badge must not be its child or the
	# container stretches it over the whole card (every card read as a red
	# "!" block). Holder = plain Control: card fills it, badge floats on top.
	# Reference card: navy tile, antique rim (lit gold when it can be built
	# or claimed), big icon, pixel-caps name, padlock over unbuilt rooms.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(212, 214)
	var wrap := PanelContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.clip_contents = false
	var style := UiKit.panel(UiKit.NAVY, UiKit.RIM)
	style.content_margin_top = 8
	wrap.add_theme_stylebox_override("panel", style)
	holder.add_child(wrap)
	wrap.mouse_entered.connect(func() -> void:
		var hi := UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD)
		hi.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.45)
		hi.shadow_size = 12
		hi.content_margin_top = 8
		wrap.add_theme_stylebox_override("panel", hi)
	)
	wrap.mouse_exited.connect(func() -> void:
		wrap.add_theme_stylebox_override("panel", style)
	)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	wrap.add_child(col)
	var roof_row := HBoxContainer.new()
	var roof := Label.new()
	roof.text = "LV %d" % lvl if lvl > 0 else ""
	roof.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(roof, 11, UiKit.GOLD)
	roof_row.add_child(roof)
	if FamilyProfile.is_unseen("build_%s" % id):
		roof_row.add_child(UiKit.new_dot())
	col.add_child(roof_row)
	var pic_wrap := Control.new()
	pic_wrap.custom_minimum_size = Vector2(190, 96)
	var pic := UiKit.portrait(SpriteBook.icon(id), Vector2(190, 96))
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic_wrap.add_child(pic)
	if lvl == 0:
		pic.modulate = Color(0.62, 0.62, 0.7)
		var lock := PixelIcon.new()
		lock.kind = "lock"
		lock.size = Vector2(44, 44)
		lock.position = Vector2(73, 46)
		pic_wrap.add_child(lock)
	col.add_child(pic_wrap)
	var title := Label.new()
	title.text = str(info["name"]).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(196, 0)
	title.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(title, 15, Palette.TEXT if lvl > 0 else Palette.MUTED)
	col.add_child(title)
	var cost := FamilyProfile.build_cost(id)
	var can_pay := int(FamilyProfile.data["gold"]) >= cost
	var b := UiKit.button("BUILD %d" % cost if lvl == 0 else "UPGRADE %d" % cost, Vector2(170, 28))
	b.add_theme_font_size_override("font_size", 12)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not can_pay:
		b.disabled = true
		b.text = "NEED %d GOLD" % cost
	else:
		b.add_theme_stylebox_override("normal", UiKit.panel(UiKit.NAVY_HI, Palette.READY if lvl == 0 else UiKit.RIM))
		if lvl == 0:
			UiKit.pulse_ready(b)
	b.pressed.connect(func() -> void:
		if FamilyProfile.try_build(id):
			Juice.play("res://assets/audio/hammer.wav" if ResourceLoader.exists("res://assets/audio/hammer.wav") else "res://assets/audio/chest.wav")
			Juice.carpenter(str(info["name"]), str(info.get("unlocks", "CAMP")))
			Juice.upgrade_fx(b, Palette.READY, Copy.GROWTH, true)
			built.emit(id)
		else:
			Juice.rewards.deny(b)
			Juice.claim_burst(get_viewport_rect().size * 0.5, "THE CLINIC DOES NOT RUN ON IOUS", 0, 0)
	)
	col.add_child(b)
	if lvl > 0 and id in SHEETS:
		var open := UiKit.button(Copy.OPEN_CAMP, Vector2(170, 28))
		open.add_theme_font_size_override("font_size", 12)
		open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		open.add_theme_stylebox_override("normal", UiKit.panel(UiKit.NAVY_HI, UiKit.GOLD))
		if id == "patrol_desk" and FamilyProfile.patrol_ready():
			UiKit.pulse_ready(open)
			open.text = "CLAIM PATROL"
		elif id == "streak_locker" and int(FamilyProfile.data.get("streak", 0)) >= 3:
			var claimed: Array = FamilyProfile.data.get("streak_claimed", [])
			if not claimed.has(3) or (int(FamilyProfile.data.get("streak", 0)) >= 5 and not claimed.has(5)):
				UiKit.pulse_ready(open)
				open.text = "CLAIM STREAK"
		elif id == "warrant_fax" and FamilyProfile.fax_ready():
			UiKit.pulse_ready(open)
			open.text = "FAX TODAY"
		elif id == "lost_found" and FamilyProfile.lost_found_ready():
			UiKit.pulse_ready(open)
			open.text = "PACK A PIPE"
		elif id == "payphone" and FamilyProfile.payphone_ready():
			UiKit.pulse_ready(open)
			open.text = "DIAL TODAY"
		elif id == "tip_jar" and int(FamilyProfile.data.get("gold", 0)) >= 5:
			UiKit.pulse_ready(open)
			open.text = "TOSS 5 GOLD"
		elif id == "water_cooler" and FamilyProfile.cooler_ready():
			UiKit.pulse_ready(open)
			open.text = "DRINK TODAY"
		elif id == "coat_check" and FamilyProfile.coat_ready():
			UiKit.pulse_ready(open)
			open.text = "PACK TAPE"
		elif id == "time_clock" and FamilyProfile.clock_ready():
			UiKit.pulse_ready(open)
			open.text = "PUNCH IN"
		elif id == "bleach_closet" and FamilyProfile.bleach_ready():
			UiKit.pulse_ready(open)
			open.text = "PACK FIZZ"
		open.pressed.connect(func() -> void:
			FamilyProfile.mark_seen("build_%s" % id)
			open_sheet.emit(id)
		)
		col.add_child(open)
	if can_pay and (lvl == 0 or lvl < 4):
		var bang := UiKit.bang()
		bang.position = Vector2(186, -8)
		holder.add_child(bang)
	# Grow the holder to the card's content height once laid out.
	holder.custom_minimum_size.y = maxf(214.0, wrap.get_combined_minimum_size().y)
	return holder
