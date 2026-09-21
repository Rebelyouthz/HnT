class_name ScrapOrb
extends Area2D

var amount := 3


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8
	cs.shape = c
	add_child(cs)
	var p := Polygon2D.new()
	p.color = Color(0.75, 0.78, 0.82)
	p.polygon = PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)])
	add_child(p)
	body_entered.connect(_eat)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)


func _eat(b: Node) -> void:
	if b is Fighter:
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_scrap"):
			rs.add_scrap(amount)
		Juice.keep_combo()
		Juice.popup_number(global_position, "+%d SCRAP" % amount, Palette.EDGE)
		Juice.play("res://assets/audio/ui_click.wav")
		queue_free()
