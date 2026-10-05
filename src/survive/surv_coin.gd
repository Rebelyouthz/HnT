class_name SurvCoin
extends Node2D

## An S-COIN on the street of a survivor hour: walk near it (the magnet pulls)
## and it goes into the hour's purse, paid out as S-COINS at the end.

var amount := 1
var _t := 0.0
var _v := Vector2.ZERO


static func spawn(host: Node, at: Vector2, n := 1) -> void:
	var c := SurvCoin.new()
	c.amount = n
	c.global_position = at
	c._v = Vector2(randf_range(-60, 60), -120)
	host.add_child.call_deferred(c)


func _ready() -> void:
	z_index = 4


func _physics_process(delta: float) -> void:
	_t += delta
	if _t < 0.3:
		_v.y += 600.0 * delta
		position += _v * delta
	var run := SurviveRun.get_run(get_tree())
	var reach := 60.0 * (run.pickup_mul() if run else 1.0)
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			var d := (n as Fighter).global_position.distance_to(global_position)
			if d < 14.0:
				if run:
					run.coins += amount
				Juice.popup_number(global_position + Vector2(0, -20), "+%d S-COIN" % amount, Color(0.55, 1.0, 0.75))
				Mixer.play_sfx("res://assets/audio/cash.wav", 1.5, -8.0)
				queue_free()
				return
			if d < reach and _t > 0.3:
				global_position = global_position.move_toward((n as Fighter).global_position, 260.0 * delta)
	if _t > 14.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var b := sin(_t * 5.0) * 1.5
	var w := absf(cos(_t * 4.0)) * 5.0 + 1.0
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-w, -12 + b, w * 2.0, 10), Color(0.25, 0.85, 0.55))
	draw_rect(Rect2(-w * 0.5, -10 + b, w, 6), Color(0.7, 1.0, 0.85))
