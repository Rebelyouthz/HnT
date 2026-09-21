extends Control

signal built(id: String)

const SPOTS := {
	"front_desk": Vector2(40, 40),
	"street_map": Vector2(280, 28),
	"therapy_couch": Vector2(520, 90),
	"compare_mirrors": Vector2(760, 70),
	"wardrobe_cage": Vector2(40, 210),
	"trophy_cabinet": Vector2(280, 210),
	"mail_slot": Vector2(520, 230),
	"bulletin_board": Vector2(760, 230),
	"blood_fridge": Vector2(1000, 140)
}


func _ready() -> void:
	custom_minimum_size = Vector2(1180, 360)
	var floor := ColorRect.new()
	floor.color = Color(0.07, 0.075, 0.1)
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(floor)
	var lamp := ColorRect.new()
	lamp.color = Color(1.0, 0.82, 0.45, 0.08)
	lamp.position = Vector2(200, 0)
	lamp.size = Vector2(700, 360)
	add_child(lamp)
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	for b in list:
		add_child(_spot(b))


func _spot(info: Dictionary) -> Control:
	var id := str(info["id"])
	var pos: Vector2 = SPOTS.get(id, Vector2(40, 40))
	var lvl := FamilyProfile.building_level(id)
	var wrap := PanelContainer.new()
	wrap.position = pos
	wrap.custom_minimum_size = Vector2(210, 140)
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL if lvl > 0 else Palette.PANEL_2, Palette.EDGE if lvl > 0 else Palette.LOCK))
	var col := VBoxContainer.new()
	wrap.add_child(col)
	var roof := Label.new()
	roof.text = "LVL %d" % lvl
	UiKit.apply_label(roof, 12, Palette.EDGE)
	col.add_child(roof)
	var title := Label.new()
	title.text = str(info["name"])
	UiKit.apply_label(title, 14, Palette.LEMON if lvl > 0 else Palette.MUTED)
	col.add_child(title)
	var blurb := Label.new()
	blurb.text = str(info["blurb"])
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(190, 0)
	UiKit.apply_label(blurb, 11, Palette.TEXT)
	col.add_child(blurb)
	var cost := FamilyProfile.build_cost(id)
	var b := UiKit.button("BUILD %d" % cost if lvl == 0 else "UPGRADE %d" % cost, Vector2(180, 32))
	if int(FamilyProfile.data["gold"]) < cost:
		b.disabled = true
	else:
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.READY if lvl == 0 else Palette.EDGE))
		if lvl == 0:
			UiKit.pulse_ready(b)
	b.pressed.connect(func() -> void:
		if FamilyProfile.try_build(id):
			Juice.play("res://assets/audio/chest.wav")
			Juice.claim_burst(get_viewport_rect().size * 0.5, Copy.GROWTH, 0, 0)
			built.emit(id)
		else:
			Juice.claim_burst(get_viewport_rect().size * 0.5, "THE CLINIC DOES NOT RUN ON IOUS", 0, 0)
	)
	col.add_child(b)
	var can_pay := int(FamilyProfile.data["gold"]) >= cost
	if can_pay and (lvl == 0 or lvl < 4):
		var bang := UiKit.bang()
		bang.position = Vector2(182, 4)
		wrap.add_child(bang)
	return wrap
