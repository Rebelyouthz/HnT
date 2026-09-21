class_name VaultCrate
extends StaticBody2D

var hp := 2
var _box: Polygon2D


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
	_box = Polygon2D.new()
	_box.color = Color(0.33, 0.22, 0.14)
	_box.polygon = PackedVector2Array([
		Vector2(-28, -36), Vector2(28, -36), Vector2(28, 0), Vector2(-28, 0)
	])
	add_child(_box)
	var strap := Polygon2D.new()
	strap.color = Color(0.55, 0.38, 0.18)
	strap.polygon = PackedVector2Array([
		Vector2(-28, -22), Vector2(28, -22), Vector2(28, -16), Vector2(-28, -16)
	])
	add_child(strap)


func covers(pos: Vector2) -> bool:
	return absf(pos.x - global_position.x) < 42.0 and absf(pos.y - global_position.y) < 40.0


func smash() -> void:
	hp -= 1
	Juice.keep_combo()
	Juice.play("res://assets/audio/hit_light.wav")
	if _box:
		_box.modulate = Color(1.2, 0.9, 0.6)
	if hp > 0:
		return
	var orb := ScrapOrb.new()
	orb.amount = 2
	orb.global_position = global_position + Vector2(0, -12)
	var host := get_parent()
	host.add_child(orb)
	Juice.kill_burst(global_position, "heavy")
	Juice.shout("CRATE")
	queue_free()
