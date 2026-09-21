class_name HeliSweep
extends Node2D

var map_w := 3000.0
var _dir := 1.0


func _process(delta: float) -> void:
	position.x += 140.0 * _dir * delta
	if position.x > map_w - 80.0:
		_dir = -1.0
	elif position.x < 80.0:
		_dir = 1.0
	position.y = 40.0 + 7.0 * sin(Time.get_ticks_msec() * 0.004)
