extends SceneTree
## Dev: one BONE YARD move on the dojo dummy, frames saved.  -- <who> <move> <out>
var _n := 0
var _who := "father"
var _move := "heart_punch"
var _out := "/tmp/brutal"
var _f: Node2D
var _d: Node2D
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_who = a[0] if a.size() > 0 else _who
	_move = a[1] if a.size() > 1 else _move
	_out = a[2] if a.size() > 2 else _out
func _process(_dl: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("FamilyProfile").data["brutal"] = [_move]
		root.get_node("App").set("solo_role", _who)
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n == 50:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		_f = get_first_node_in_group("players")
		for e in get_nodes_in_group("enemies"):
			if e != _d:
				e.global_position.x += 400
		_d = load("res://src/actors/training_dummy.gd").new()
		_d.set("hp", 400)
		current_scene.add_child(_d)
		_d.global_position = _f.global_position + Vector2(30, 0)
	if _n == 56:
		load("res://src/combat/brutal_run.gd").start(_f, _d, _move)
	if _n > 56 and (_n - 56) % 8 == 0:
		root.get_texture().get_image().save_png("%s_%03d.png" % [_out, _n])
	if _n > 56 + 60 * 2.8:
		quit()
	return false
