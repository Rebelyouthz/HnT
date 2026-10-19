extends SceneTree

## Uppercut launches a street thug, air hits keep him up (rising pull each
## hit), and he always lands. Prints JUGGLE OK.

var _n := 0
var _p: Node2D
var _f: Node2D
var _peak := 0.0
var _hits := 0
var _fail: Array[String] = []


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n == 40:
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_f = get_first_node_in_group("players")
		_p = load("res://src/actors/training_dummy.gd").new()
		_p.set("hp", 400)
		_p.set("home", "street")
		current_scene.add_child(_p)
		_p.global_position = _f.global_position + Vector2(40, 0)
	if _n == 50:
		_p.call("take_hit", "uppercut", _f)
		if float(_p.get("lift_v")) >= 0.0:
			_fail.append("uppercut did not launch")
	if _n > 50 and _n < 200 and is_instance_valid(_p):
		_peak = minf(_peak, float(_p.get("lift")))
		if _n % 9 == 0 and bool(_p.call("airborne")) and _hits < 6:
			_p.call("take_hit", "light", _f)
			_hits += 1
	if _n == 260:
		if _peak > -40.0:
			_fail.append("peak only %d" % int(_peak))
		if int(_p.get("juggle_n")) != 0 or float(_p.get("lift")) < 0.0:
			_fail.append("never landed (lift %d)" % int(_p.get("lift")))
		if _hits < 2:
			_fail.append("only %d air hits" % _hits)
		print("JUGGLE OK  peak=%d air_hits=%d" % [int(_peak), _hits] if _fail.is_empty() else "JUGGLE FAIL %s" % [_fail])
		return true
	return false
