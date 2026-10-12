extends SceneTree

## BONE YARD moves: every timeline plays on the dojo dummy (each one tells
## the school a "b_<id>" rep), a grab on a broken dummy picks the hero's
## move, and on the street a brutal move kills a real thug. Prints BRUTAL OK.

var _n := 0
var _f: Node2D
var _d: Node2D
var _ids: Array = []
var _k := 0
var _reps: Array = []
var _fail: Array[String] = []
var _thug: Node2D
var _t0 := 0


func _fp() -> Node:
	return root.get_node("FamilyProfile")


func _process(_dl: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		_fp().data["intro_done"] = true
		for r in load("res://src/combat/brutal_book.gd").all():
			_ids.append(str(r["id"]))
		_fp().data["brutal"] = _ids.duplicate()
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n == 40:
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_f = get_first_node_in_group("players")
		_d = load("res://src/actors/training_dummy.gd").new()
		_d.set("hp", 400)
		current_scene.add_child(_d)
		_d.global_position = _f.global_position + Vector2(30, 0)
		_d.connect("struck", func(kind: String) -> void: _reps.append(kind))
		_t0 = _n + 5
	# Every move in turn on the dummy.
	if _n == _t0 and _k < _ids.size():
		_d.global_position = _f.global_position + Vector2(30, 0)
		var r: Node = load("res://src/combat/brutal_run.gd").start(_f, _d, _ids[_k])
		if r == null:
			_fail.append("no run for " + _ids[_k])
		_k += 1
		_t0 = _n + 200
	if _k >= _ids.size() and _n == _t0 - 1:
		for id in _ids:
			if not _reps.has("b_" + id):
				_fail.append("no rep for " + id)
		if float(_f.get("art_lock")) > 0.0:
			_fail.append("hero still locked")
		# A grab on the broken dummy picks a move by itself.
		_d.global_position = _f.global_position + Vector2(24, 0)
		_reps.clear()
		_f.get("arts").call("_start_lh")
	if _k >= _ids.size() and _n == _t0 + 160:
		if _reps.is_empty():
			_fail.append("grab on broken dummy did no brutal move")
		root.get_node("App").call("enter_map", "dock_street")
	if _k >= _ids.size() and _n == _t0 + 260:
		_f = get_first_node_in_group("players")
		for e in get_nodes_in_group("enemies"):
			if e.get("vehicle") == "" and not e.is_queued_for_deletion():
				_thug = e
				break
		if _thug == null:
			_fail.append("no thug on dock street")
		else:
			_thug.global_position = _f.global_position + Vector2(30, 0)
			_thug.set("hp", 5)
			load("res://src/combat/brutal_run.gd").start(_f, _thug, "spine_rip")
	if _k >= _ids.size() and _n == _t0 + 420:
		if _thug != null and is_instance_valid(_thug) and int(_thug.get("hp")) > 0:
			_fail.append("thug survived spine_rip (hp %d)" % int(_thug.get("hp")))
		if int(_fp().data.get("brutal_kills", 0)) < 1:
			_fail.append("brutal kill not counted")
		print("BRUTAL OK  moves=%d" % _ids.size() if _fail.is_empty() else "BRUTAL FAIL %s" % [_fail])
		return true
	if _n > 8000:
		print("BRUTAL FAIL timeout k=%d" % _k)
		return true
	return false
