class_name WeaponPickup
extends Area2D

var kind := "pipe"


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 12)
	cs.shape = r
	add_child(cs)
	var p := Polygon2D.new()
	match kind:
		"knife":
			p.color = Color(0.82, 0.84, 0.9)
			p.polygon = PackedVector2Array([Vector2(-16, -3), Vector2(16, 0), Vector2(-16, 3)])
		"pistol":
			p.color = Color(0.22, 0.22, 0.24)
			p.polygon = PackedVector2Array([Vector2(-14, -6), Vector2(16, -4), Vector2(16, 4), Vector2(-10, 6), Vector2(-18, 2)])
		"nailgun":
			p.color = Color(0.28, 0.24, 0.18)
			p.polygon = PackedVector2Array([Vector2(-16, -8), Vector2(18, -5), Vector2(18, 5), Vector2(-12, 8), Vector2(-20, 2)])
		"board":
			p.color = Color(0.55, 0.38, 0.18)
			p.polygon = PackedVector2Array([Vector2(-24, -5), Vector2(24, -5), Vector2(24, 5), Vector2(-24, 5)])
		"chain":
			p.color = Color(0.62, 0.64, 0.68)
			p.polygon = PackedVector2Array([Vector2(-28, -3), Vector2(28, -3), Vector2(26, 3), Vector2(-26, 3)])
		"crowbar":
			p.color = Color(0.42, 0.18, 0.14)
			p.polygon = PackedVector2Array([Vector2(-22, -5), Vector2(18, -4), Vector2(22, 2), Vector2(14, 6), Vector2(-22, 5)])
		"clipboard":
			p.color = Color(0.88, 0.82, 0.7)
			p.polygon = PackedVector2Array([Vector2(-12, -14), Vector2(12, -14), Vector2(12, 12), Vector2(-12, 12)])
		"stapler":
			p.color = Color(0.72, 0.22, 0.18)
			p.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(12, -8), Vector2(12, 6), Vector2(-10, 6)])
		"invoice_star":
			p.color = Palette.EDGE
			p.polygon = PackedVector2Array([Vector2(0, -14), Vector2(6, -4), Vector2(14, 0), Vector2(6, 4), Vector2(0, 14), Vector2(-6, 4), Vector2(-14, 0), Vector2(-6, -4)])
		"can":
			p.color = Color(0.82, 0.22, 0.18)
			p.polygon = PackedVector2Array([Vector2(-8, -10), Vector2(8, -10), Vector2(8, 10), Vector2(-8, 10)])
		"envelope":
			p.color = Color(0.92, 0.9, 0.82)
			p.polygon = PackedVector2Array([Vector2(-14, -8), Vector2(14, -8), Vector2(14, 8), Vector2(-14, 8)])
		_:
			p.color = Color(0.45, 0.32, 0.2)
			p.polygon = PackedVector2Array([Vector2(-20, -4), Vector2(20, -4), Vector2(20, 4), Vector2(-20, 4)])
	add_child(p)
	p.color = Rarity.color(Rarity.of_pickup(kind))
	body_entered.connect(_grab)


func _grab(b: Node) -> void:
	if b is Fighter:
		var f: Fighter = b
		f.equip_pickup(kind)
		var rarity := Rarity.of_pickup(kind)
		Juice.play("res://assets/audio/shop.wav")
		Juice.popup_number(global_position, "%s  %s" % [kind.to_upper(), Rarity.label(rarity)], Rarity.color(rarity))
		Rarity.juice(rarity, kind.to_upper())
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_points"):
			rs.add_points(f.role, 16 + Rarity.rank(rarity) * 8, "pickup")
		queue_free()
