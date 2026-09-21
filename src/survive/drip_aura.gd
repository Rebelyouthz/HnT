class_name DripAura
extends Node2D

var _cd := 0.0
var owner_fighter: Fighter


func _ready() -> void:
	owner_fighter = get_parent() as Fighter


func _process(delta: float) -> void:
	if owner_fighter == null or not is_instance_valid(owner_fighter) or owner_fighter.downed:
		return
	_cd -= delta
	if _cd > 0.0:
		return
	_cd = 0.72
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and is_instance_valid(n):
			if (n as Node2D).global_position.distance_to(owner_fighter.global_position) < 86.0:
				(n as Punk).take_hit("light", owner_fighter)
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2(0, -28), 80.0, 0.0, TAU, 28, Color(0.45, 0.9, 0.55, 0.28), 2.0)
