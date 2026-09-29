extends Control

signal built(id: String)
signal open_sheet(id: String)

const SHEETS := ["pawn_shop", "patrol_desk", "research_lab", "dojo", "workshop", "bounty_board", "radio_tower", "album_wall", "blood_fridge", "streak_locker", "invoice_wheel", "punching_bag", "warrant_fax", "tip_jar", "lost_found", "payphone", "water_cooler", "coat_check", "time_clock", "bleach_closet"]
const COLS := 7


func _ready() -> void:
	custom_minimum_size = Vector2(1180, 680)
	var floor := ColorRect.new()
	floor.color = Color(0.07, 0.075, 0.1)
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(floor)
	var lamp := ColorRect.new()
	lamp.color = Color(1.0, 0.82, 0.45, 0.08)
	lamp.position = Vector2(200, 0)
	lamp.size = Vector2(700, 460)
	add_child(lamp)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.position = Vector2(16, 12)
	add_child(grid)
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
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(154, 188)
	var wrap := PanelContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.clip_contents = false
	var style := UiKit.frame(Palette.EDGE, 0.26) if lvl > 0 else UiKit.panel(Color(0.06, 0.065, 0.09, 0.95), Palette.LOCK)
	wrap.add_theme_stylebox_override("panel", style)
	holder.add_child(wrap)
	holder.resized.connect(func() -> void:
		holder.custom_minimum_size.y = maxf(holder.custom_minimum_size.y, wrap.get_combined_minimum_size().y)
	)
	var col := VBoxContainer.new()
	wrap.add_child(col)
	var roof_row := HBoxContainer.new()
	var roof := Label.new()
	roof.text = "LVL %d" % lvl
	UiKit.apply_label(roof, 12, Palette.EDGE)
	roof_row.add_child(roof)
	if FamilyProfile.is_unseen("build_%s" % id):
		roof_row.add_child(UiKit.new_dot())
	col.add_child(roof_row)
	var portrait := SpriteBook.icon(id)
	var pic := UiKit.portrait(portrait, Vector2(128, 72))
	if lvl == 0:
		pic.modulate = Color(0.55, 0.55, 0.62)
	col.add_child(pic)
	var title := UiKit.title(str(info["name"]).to_upper(), 14, Palette.LEMON if lvl > 0 else Palette.MUTED)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(140, 0)
	col.add_child(title)
	var unlocks := Label.new()
	unlocks.text = "UNLOCKS  ·  %s" % str(info.get("unlocks", "CAMP"))
	UiKit.apply_label(unlocks, 11, Palette.EDGE if lvl > 0 else Palette.MUTED)
	col.add_child(unlocks)
	var blurb := Label.new()
	blurb.text = str(info["blurb"])
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(140, 0)
	UiKit.apply_label(blurb, 11, Palette.TEXT)
	col.add_child(blurb)
	var cost := FamilyProfile.build_cost(id)
	var can_pay := int(FamilyProfile.data["gold"]) >= cost
	var b := UiKit.button("BUILD %d" % cost if lvl == 0 else "UPGRADE %d" % cost, Vector2(136, 32))
	if not can_pay:
		b.disabled = true
		b.text = "NEED %d GOLD" % cost
	else:
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.READY if lvl == 0 else Palette.EDGE))
		if lvl == 0:
			UiKit.pulse_ready(b)
	b.pressed.connect(func() -> void:
		if FamilyProfile.try_build(id):
			Juice.play("res://assets/audio/hammer.wav" if ResourceLoader.exists("res://assets/audio/hammer.wav") else "res://assets/audio/chest.wav")
			Juice.carpenter(str(info["name"]), str(info.get("unlocks", "CAMP")))
			Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.GROWTH, 0, 0)
			built.emit(id)
		else:
			Juice.claim_burst(get_viewport_rect().size * 0.5, "THE CLINIC DOES NOT RUN ON IOUS", 0, 0)
	)
	col.add_child(b)
	if lvl > 0 and id in SHEETS:
		var open := UiKit.button(Copy.OPEN_CAMP, Vector2(136, 32))
		open.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
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
		bang.position = Vector2(132, -8)
		holder.add_child(bang)
	# Grow the holder to the card's content height once laid out.
	holder.custom_minimum_size.y = maxf(188.0, wrap.get_combined_minimum_size().y)
	return holder
