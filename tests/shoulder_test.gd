extends SceneTree

## Shoulder strikes: LB + LIGHT body hook, LB + HEAVY liver shot, RT +
## LIGHT side hook, RT + HEAVY haymaker (plain heavy until drilled). Prints
## SHOULDER OK.

var _n := 0
var _f: Node2D
var _got: Array = []
var _fail: Array[String] = []
const STEPS := [["p1_block", "p1_light", "body_r"], ["p1_block", "p1_heavy", "body_l"], ["p1_dash", "p1_light", "hook_r"], ["p1_dash", "p1_heavy", "heavy"]]


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		# The haymaker is a dojo move: undrilled, RT + HEAVY throws the plain heavy.
		var dj: Dictionary = root.get_node("FamilyProfile").data.get("dojo", {})
		dj.erase("haymaker")
		(root.get_node("FamilyProfile").data.get("dojo_train", {}) as Dictionary).erase("haymaker")
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n == 40:
		_f = get_first_node_in_group("players")
		for g in get_nodes_in_group("guide"):
			g.queue_free()
	for i in STEPS.size():
		var t0 := 60 + i * 60
		if _n == t0:
			Input.action_press(STEPS[i][0])
		if _n == t0 + 3:
			Input.action_press(STEPS[i][1])
		if _n == t0 + 5:
			Input.action_release(STEPS[i][1])
		if _n == t0 + 8:
			_got.append(str(_f.get("_last_kind")))
			_f.set("_last_kind", "")
			Input.action_release(STEPS[i][0])
	if _n == 60 + STEPS.size() * 60 + 10:
		for i in STEPS.size():
			if _got[i] != STEPS[i][2]:
				_fail.append("%s+%s gave %s" % [STEPS[i][0], STEPS[i][1], _got[i]])
		print("SHOULDER OK %s" % [_got] if _fail.is_empty() else "SHOULDER FAIL %s" % [_fail])
		return true
	return false
