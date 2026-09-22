class_name HeliSweep
extends Node2D

var map_w := 3000.0
var _dir := 1.0
var _burn := 0.0


func _process(delta: float) -> void:
	position.x += 140.0 * _dir * delta
	if position.x > map_w - 80.0:
		_dir = -1.0
	elif position.x < 80.0:
		_dir = 1.0
	position.y = 40.0 + 7.0 * sin(Time.get_ticks_msec() * 0.004)
	_burn -= delta
	if _burn > 0.0:
		return
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter):
			continue
		var f: Fighter = n
		if f.downed or f.van_seat != "":
			continue
		if absf(f.global_position.x - global_position.x) > 90.0:
			continue
		if f.hop < -80.0 or f.plane == "roof":
			continue
		f.take_hit("light", self)
		_burn = 0.55
		Juice.shout("SPOTLIGHT")
		break
