class_name VaultCrate
extends StaticBody2D


func _ready() -> void:
	add_to_group("vaults")
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(56, 36)
	cs.shape = sh
	cs.position = Vector2(0, -18)
	add_child(cs)
	var box := Polygon2D.new()
	box.color = Color(0.33, 0.22, 0.14)
	box.polygon = PackedVector2Array([
		Vector2(-28, -36), Vector2(28, -36), Vector2(28, 0), Vector2(-28, 0)
	])
	add_child(box)
	var strap := Polygon2D.new()
	strap.color = Color(0.55, 0.38, 0.18)
	strap.polygon = PackedVector2Array([
		Vector2(-28, -22), Vector2(28, -22), Vector2(28, -16), Vector2(-28, -16)
	])
	add_child(strap)


func covers(pos: Vector2) -> bool:
	return absf(pos.x - global_position.x) < 42.0 and absf(pos.y - global_position.y) < 40.0
