class_name SurviveChest
extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(36, 28)
	cs.shape = r
	add_child(cs)
	var box := Polygon2D.new()
	box.color = Color(0.78, 0.62, 0.18)
	box.polygon = PackedVector2Array([
		Vector2(-18, -28), Vector2(18, -28), Vector2(18, 0), Vector2(-18, 0)
	])
	Blockout.add_glow(box)
	add_child(box)
	body_entered.connect(_open)
	Juice.popup_number(global_position, "CHEST", Palette.EDGE)


func _open(b: Node) -> void:
	if not (b is Fighter):
		return
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_scrap"):
		rs.add_scrap(8)
	if rs and rs.has_method("add_xp"):
		rs.add_xp(22)
	Juice.unlock_logo("COPING CHEST", "Halls of Torment called. It wants its loot table back.")
	Juice.toast("reward", "CHEST", "Scrap, XP, and a worse personality.")
	Juice.play("res://assets/audio/chest.wav")
	if rs and rs.has_signal("need_cards"):
		rs.emit_signal("need_cards")
	queue_free()
