extends SceneTree

## BONE YARD: opens after the first survivor night with a free token, the
## tree buys a move (hold fills it), a one-life run clears its waves, pays
## tokens and walks into the next open yard. Prints BONEYARD OK.

var _n := 0
var _fail: Array[String] = []
var _phase := 0
var _t := 0
var _tok0 := 0


func _fp() -> Node:
	return root.get_node("FamilyProfile")


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	var by: GDScript = load("res://src/combat/bone_yard.gd")
	var bb: GDScript = load("res://src/combat/brutal_book.gd")
	if _n == 2:
		var fp := _fp()
		fp.data["intro_done"] = true
		fp.data["maps_filed"] = ["dock_street"]
		fp.data["brutal"] = []
		fp.data["fight_tokens"] = 0
		fp.data["boneyard_told"] = false
		fp.data["boneyard_done"] = []
		if not by.open_maps().is_empty():
			_fail.append("open before the survivor night")
		fp.data["maps_filed"] = ["dock_street", "intake_lot"]
		if by.open_maps() != ["butcher_row"]:
			_fail.append("open maps %s" % [by.open_maps()])
		by.check_open()
		if bb.tokens() != 1:
			_fail.append("no free token (%d)" % bb.tokens())
		# The tree: holding on the root buys it.
		var tree: Control = load("res://src/ui/bone_tree.gd").new()
		root.add_child(tree)
		tree.call("_press", "arm_breaker")
		_t = _n
		_phase = 1
	if _phase == 1 and _n == _t + 90:
		if not bb.owned("arm_breaker"):
			_fail.append("holding did not buy arm_breaker")
		if bb.tokens() != 0:
			_fail.append("token not spent")
		if int((_fp().data.get("dojo_train", {}) as Dictionary).get("b_arm_breaker", -1)) != 0:
			_fail.append("no drill entry")
		for c in root.get_children():
			if c is Control and c.has_method("_buy"):
				c.queue_free()
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		# Three yards open: the run walks from the first into the second.
		_fp().data["maps_filed"] = ["dock_street", "intake_lot", "fire_escapes", "group_circle", "waiting_room"]
		_tok0 = bb.tokens()
		by.start()
		_phase = 2
		_t = _n
	if _phase == 2 and _n > _t + 60:
		var act := current_scene
		if _n == _t + 61:
			if root.get_node("App").get("current_map") != "butcher_row":
				_fail.append("run did not start in butcher row")
			var st: Node = get_first_node_in_group("run_state")
			if st == null or int(st.get("lives")) != 1:
				_fail.append("not one life")
		var hero: Node = get_first_node_in_group("players")
		for e in get_nodes_in_group("enemies"):
			if is_instance_valid(e) and int(e.get("hp")) > 0 and hero:
				e.set("hp", 1)
				e.call("take_hit", "finish", hero)
		if root.get_node("App").get("current_map") == "cold_storage":
			if bb.tokens() < _tok0 + 1:
				_fail.append("no tokens for the clear")
			if not by.done("butcher_row"):
				_fail.append("butcher row not marked")
			if by.step != 1:
				_fail.append("step %d" % by.step)
			_phase = 3
			_t = _n
		elif _n > _t + 2400:
			_fail.append("never reached cold storage (wave %s)" % [act.get("_wave")])
			_phase = 3
	if _phase == 3 and _n > _t + 30:
		print("BONEYARD OK" if _fail.is_empty() else "BONEYARD FAIL %s" % [_fail])
		return true
	return false
