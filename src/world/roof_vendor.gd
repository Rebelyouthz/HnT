class_name RoofVendor
extends Area2D

var _hint: Label


func _ready() -> void:
	add_to_group("shops")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(170, 90)
	cs.shape = r
	add_child(cs)
	_hint = Label.new()
	_hint.position = Vector2(-100, -78)
	_hint.size = Vector2(200, 48)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 13, Palette.EDGE)
	_hint.text = "ROOF VENDOR"
	add_child(_hint)
	var stall := Polygon2D.new()
	stall.color = Color(0.18, 0.14, 0.12, 0.9)
	stall.polygon = PackedVector2Array([
		Vector2(-70, -20), Vector2(70, -20), Vector2(62, 24), Vector2(-62, 24)
	])
	add_child(stall)
	var cloth := Polygon2D.new()
	cloth.color = Color(0.72, 0.22, 0.2, 0.85)
	cloth.polygon = PackedVector2Array([
		Vector2(-74, -28), Vector2(74, -28), Vector2(70, -16), Vector2(-70, -16)
	])
	add_child(cloth)


func _process(_delta: float) -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs == null:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			_hint.text = "SPECIAL AMMO 4  ·  DOWN+SPECIAL REROLL 1"
			if f._just("special"):
				var y := PadRouter.stick(f.prefix).y
				if y > 0.4:
					_buy(rs, f, "reroll")
				else:
					_buy(rs, f, "ammo")
			return
	_hint.text = "ROOF VENDOR  ·  SHARP OPINIONS"


func _buy(rs: Node, f: Fighter, item: String) -> void:
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
	if not table.has(item):
		return
	var info: Dictionary = table[item]
	var cost := int(info["scrap"])
	if int(rs.scrap) < cost:
		Juice.shout("HE DOES NOT TAKE PROMISES")
		return
	rs.scrap -= cost
	rs.scrap_changed.emit()
	if rs.has_method("note_shop"):
		rs.note_shop()
	if item == "ammo":
		var cap := 3 if f.role == "son" else 6
		f.ammo = cap
		Juice.shout(str(info["line"]))
	else:
		if rs.has_method("request_reroll"):
			rs.request_reroll()
		Juice.shout(str(info["line"]))
	Juice.play("res://assets/audio/shop.wav")
	Juice.claim_burst(Vector2(640, 180), str(info["line"]), 0, 0)
	Juice.toast("reward", "ROOF TIP", str(info["line"]))
