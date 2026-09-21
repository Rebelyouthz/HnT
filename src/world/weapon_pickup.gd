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
	if kind == "knife":
		p.color = Color(0.82, 0.84, 0.9)
		p.polygon = PackedVector2Array([Vector2(-16, -3), Vector2(16, 0), Vector2(-16, 3)])
	else:
		p.color = Color(0.45, 0.32, 0.2)
		p.polygon = PackedVector2Array([Vector2(-20, -4), Vector2(20, -4), Vector2(20, 4), Vector2(-20, 4)])
	add_child(p)
	body_entered.connect(_grab)


func _grab(b: Node) -> void:
	if b is Fighter:
		(b as Fighter).equip_pickup(kind)
		Juice.play("res://assets/audio/shop.wav")
		Juice.popup_number(global_position, kind.to_upper(), Palette.EDGE)
		queue_free()
