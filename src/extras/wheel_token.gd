class_name WheelToken
extends Node2D

## A spinning wheel on the street: walk into it for a LUCKY WHEEL spin.

var mode := "story"
var _t := 0.0


static func place(host: Node, at: Vector2, m: String) -> WheelToken:
	var w := WheelToken.new()
	w.mode = m
	w.global_position = at
	host.add_child.call_deferred(w)
	return w


func _ready() -> void:
	z_index = 4
	add_to_group("wheel_tokens")


func _physics_process(delta: float) -> void:
	_t += delta
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and (n as Fighter).global_position.distance_to(global_position) < 22.0:
			LuckyWheel.spin(get_tree(), mode)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var b := sin(_t * 3.0) * 3.0
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.85, 0.3, 0.25 + 0.1 * sin(_t * 6.0)))
	draw_set_transform(Vector2(0, -26 + b), _t * 2.0, Vector2.ONE)
	var cols := [Color(1.0, 0.82, 0.3), Color(0.6, 0.5, 1.0), Color(0.4, 0.9, 0.5), Color(1.0, 0.4, 0.3)]
	for i in 8:
		var a0 := TAU * float(i) / 8.0
		var a1 := a0 + TAU / 8.0
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(cos(a0), sin(a0)) * 12.0, Vector2(cos(a1), sin(a1)) * 12.0]), cols[i % 4])
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 24, UiKit.GOLD, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -42 + b), Vector2(4, -42 + b), Vector2(0, -36 + b)]), Color(1, 0.3, 0.3))
