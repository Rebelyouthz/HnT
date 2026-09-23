class_name BloodMart
extends Area2D

var _hint: Label


func _ready() -> void:
	add_to_group("shops")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(160, 90)
	cs.shape = r
	add_child(cs)
	_hint = Label.new()
	_hint.position = Vector2(-90, -70)
	_hint.size = Vector2(180, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_hint, 13, Palette.READY)
	_hint.text = "24/7  ·  SPECIAL BUYS"
	add_child(_hint)
	SpriteBook.attach_scaled(self, "blood_mart", 8.0, Vector2(1.15, 1.15))


func _process(_delta: float) -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs == null:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			_hint.text = "SPECIAL BANDAGE  ·  DOWN THERMOS  ·  UP LUNCH"
			_hint.modulate = Color(1.15, 1.2, 0.7)
			if f._just("special"):
				var y := PadRouter.stick(f.prefix).y
				if y > 0.4:
					_buy(rs, f, "thermos")
				elif y < -0.4:
					_buy(rs, f, "lunch")
				else:
					_buy(rs, f, "bandage")
			return
	_hint.text = "24/7 BLOOD MART"
	_hint.modulate = Color.WHITE


func _buy(rs: Node, f: Fighter, item: String) -> void:
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
	var info: Dictionary = table[item]
	var cost := int(info["scrap"])
	if int(rs.scrap) < cost:
		Juice.shout("THE FRIDGE DOES NOT RUN ON IOUS")
		return
	Juice.last_hitter = f.role
	rs.scrap -= cost
	rs.scrap_changed.emit()
	if rs.has_method("note_shop"):
		rs.note_shop()
	if item == "bandage":
		f.bandage += 1
	elif item == "lunch":
		if rs.has_method("add_lunch"):
			rs.add_lunch()
	else:
		f.steam = Fighter.STEAM_MAX
	Juice.shout(str(info["line"]))
	Juice.play("res://assets/audio/shop.wav")
	Juice.claim_burst(Vector2(640, 200), str(info["line"]), 0, 0)
	Rarity.buy("24/7", info)
