class_name DuoDirector
extends Node

var _a_t := -99.0
var _b_t := -99.0
var _a: Fighter
var _b: Fighter


func _ready() -> void:
	add_to_group("duo")
	process_physics_priority = 8


func _physics_process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var players := get_tree().get_nodes_in_group("players")
	if players.size() < 2:
		return
	_a = players[0] as Fighter
	_b = players[1] as Fighter
	if _a == null or _b == null:
		return
	if _a._just("special"):
		_a_t = now
	if _b._just("special"):
		_b_t = now
	if absf(_a_t - _b_t) <= 10.0 / 60.0 and _a_t > 0.0:
		var victim := _shared_enemy()
		if victim:
			_family_therapy(victim)
			_a_t = -99.0
			_b_t = -99.0


func _shared_enemy() -> Punk:
	var best: Punk = null
	var best_d := 70.0
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk:
			var e: Punk = n
			var da := e.global_position.distance_to(_a.global_position)
			var db := e.global_position.distance_to(_b.global_position)
			if da < 64.0 and db < 64.0 and (da + db) * 0.5 < best_d:
				best_d = (da + db) * 0.5
				best = e
	return best


func _family_therapy(e: Punk) -> void:
	e.take_hit("finish", _a)
	Juice.shout("FAMILY THERAPY")
	Juice.freeze_frames(8)
	Juice.hitstop(12)
	Juice.pulse_shake(12.0)
	Juice.play("res://assets/audio/finish.wav")
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("pump"):
		blood.pump(e.global_position, float(_a.facing))
