class_name OrbitKit
extends Node2D

## Persistent circling hit — Halls of Torment trait, not a meadow auto-attack.

var _t := 0.0
var _cd := 0.0
var radius := 58.0
var owner_fighter: Fighter


func _ready() -> void:
	owner_fighter = get_parent() as Fighter


func _process(delta: float) -> void:
	if owner_fighter == null or not is_instance_valid(owner_fighter) or owner_fighter.downed:
		return
	_t += delta * 3.2
	_cd -= delta
	if _cd <= 0.0:
		_cd = 0.32
		for i in 2:
			var ang := _t + i * PI
			var at := Vector2(cos(ang), sin(ang)) * radius + Vector2(0, -30)
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk and is_instance_valid(n):
					if (n as Node2D).global_position.distance_to(owner_fighter.global_position + at) < 28.0:
						(n as Punk).take_hit("light", owner_fighter)
	queue_redraw()


func _draw() -> void:
	for i in 2:
		var ang := _t + i * PI
		var at := Vector2(cos(ang), sin(ang)) * radius + Vector2(0, -30)
		draw_circle(at, 7.0, Palette.LEMON if owner_fighter and owner_fighter.role == "son" else Palette.BRICK)
