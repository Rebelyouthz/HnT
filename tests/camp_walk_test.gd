extends SceneTree

## Hideout: the stick walks you. Solo: only your hero is home. Couch: the
## other hero follows on screen.
## Prints CAMP WALK OK.

var _n := 0
var ok := true
var _x0 := 0.0


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("App").set("solo_role", "son")
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 30:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		paused = false
		var camp := current_scene
		camp.set("_busy", false)
		var w: Node2D = camp.get("_walker")
		var b: Node2D = camp.get("_buddy")
		_check(w.get("role") == "son", "son walks")
		_check(b == null, "solo: no buddy in the hideout")
		_x0 = w.position.x
		# A pad the router binds on any id (solo): stick left.
		root.get_node("PadRouter").call("_bind_move", "p1_", -1)
		var m := InputEventJoypadMotion.new()
		m.device = 3
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = -1.0
		Input.parse_input_event(m)
	if _n == 150:
		var camp := current_scene
		var w: Node2D = camp.get("_walker")
		_check(w.position.x < _x0 - 100.0, "stick walks you (%.0f -> %.0f)" % [_x0, w.position.x])
		var m := InputEventJoypadMotion.new()
		m.device = 3
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = 0.0
		Input.parse_input_event(m)
		root.get_node("App").set("couch", true)
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 190:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		paused = false
		var camp := current_scene
		var w: Node2D = camp.get("_walker")
		var b: Node2D = camp.get("_buddy")
		_check(b != null and b.get("role") == "father", "couch: father is the buddy")
		if b != null:
			_check(absf(b.position.x - w.position.x) < 80.0, "couch: father beside you")
		root.get_node("App").set("couch", false)
		print("CAMP WALK OK" if ok else "CAMP WALK FAILED")
		quit()
	return false
