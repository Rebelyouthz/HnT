class_name StreetShop
extends Area2D

@export var catalog := "pawn_plate"
@export var title := "SHOP"
@export var idle := "SHOP"
@export var hint := "SPECIAL"

var _hint: Label
var _items: Array = []


func _ready() -> void:
	add_to_group("shops")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(180, 90)
	cs.shape = r
	add_child(cs)
	var stall := Polygon2D.new()
	stall.color = Color(0.18, 0.16, 0.14, 0.96)
	stall.polygon = PackedVector2Array([
		Vector2(-78, -22), Vector2(78, -22), Vector2(70, 26), Vector2(-70, 26)
	])
	add_child(stall)
	var chrome := Polygon2D.new()
	chrome.color = Color(0.79, 0.64, 0.15, 0.85)
	chrome.polygon = PackedVector2Array([
		Vector2(-80, -26), Vector2(80, -26), Vector2(76, -18), Vector2(-76, -18)
	])
	add_child(chrome)
	Blockout.add_glow(chrome)
	var cloth := Polygon2D.new()
	cloth.color = Color(0.72, 0.22, 0.2, 0.85) if catalog != "toll_booth" else Color(0.2, 0.45, 0.4, 0.85)
	cloth.polygon = PackedVector2Array([
		Vector2(-82, -32), Vector2(82, -32), Vector2(78, -18), Vector2(-78, -18)
	])
	add_child(cloth)
	Blockout.add_glow(cloth)
	_hint = Label.new()
	_hint.position = Vector2(-110, -78)
	_hint.size = Vector2(220, 48)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 13, Palette.EDGE)
	_hint.text = idle
	add_child(_hint)
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
	var cats: Dictionary = table.get("catalogs", {})
	_items = cats.get(catalog, [])
	if not _items.is_empty():
		var bits: PackedStringArray = []
		for item in _items:
			if table.has(item):
				var row: Dictionary = table[item]
				bits.append("%s %d %s" % [
					str(item).replace("_", " ").to_upper(),
					int(row["scrap"]),
					Rarity.label(str(row.get("rarity", "common")))
				])
		hint = "SPECIAL  " + "  ·  ".join(bits)


func _process(_delta: float) -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs == null:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			_hint.text = hint
			_hint.modulate = Color(1.2, 1.15, 0.7)
			if f._just("special"):
				var y := f._stick().y
				_pick(rs, f, y)
			return
	_hint.text = idle
	_hint.modulate = Color.WHITE


func _pick(rs: Node, f: Fighter, y: float) -> void:
	if _items.is_empty():
		return
	var idx := 0
	if y > 0.4:
		idx = mini(1, _items.size() - 1)
	elif y < -0.4:
		idx = mini(2, _items.size() - 1)
	_buy(rs, f, str(_items[idx]))


func _buy(rs: Node, f: Fighter, item: String) -> void:
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
	if not table.has(item):
		return
	var info: Dictionary = table[item]
	var cost := int(info["scrap"])
	if item == "sell_pickup":
		if f.pickup == "":
			Juice.shout("NOTHING TO PAWN BUT THE BITTERNESS")
			return
		Juice.last_hitter = f.role
		rs.scrap += 5
		rs.scrap_changed.emit()
		f.pickup = ""
		if rs.has_method("note_shop"):
			rs.note_shop()
		Juice.shout(str(info["line"]))
		Rarity.buy(title, info)
		Juice.play("res://assets/audio/shop.wav")
		return
	if int(rs.scrap) < cost:
		Juice.shout("THE TILL DOES NOT TAKE PROMISES")
		return
	Juice.last_hitter = f.role
	rs.scrap -= cost
	rs.scrap_changed.emit()
	if rs.has_method("note_shop"):
		rs.note_shop()
	match item:
		"armor_tape":
			f.armored = true
			f.tape_t = 18.0
		"pipe_kit":
			f.equip_pickup("pipe")
		"grenade":
			f.grenades += 1
		"spark_ammo":
			f.ammo = (3 if f.role == "son" else 6) + 2
		"ammo":
			f.ammo = 3 if f.role == "son" else 6
		"reroll":
			if rs.has_method("request_reroll"):
				rs.request_reroll()
		"bandage":
			f.bandage += 1
		"thermos":
			f.steam = Fighter.STEAM_MAX
		"lunch":
			if rs.has_method("add_lunch"):
				rs.add_lunch()
	Juice.shout(str(info["line"]))
	Juice.play("res://assets/audio/shop.wav")
	Juice.claim_burst(Vector2(320, 90), str(info["line"]), 0, 0)
	Rarity.buy(title, info)
