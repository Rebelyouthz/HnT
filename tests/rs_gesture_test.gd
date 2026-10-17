extends SceneTree

## Right-stick punch paths: forward flick = jab, quarter circle = hook,
## half circle up = uppercut, pull back then forward = haymaker, held back
## a second = MEGA PUNCH, RT + forward = front kick. Prints RS OK.

var _n := 0
var _f: Node
var _q: Array = []   # [frames_left, Vector2 or null, expect]
var _cur: Array = []
var _seen: Array = []
var _fail: Array[String] = []
var _pr: Node


func _path(pts: Array, hold := 2, expect := "", dash := false) -> void:
	for p in pts:
		_q.append([hold, p, "", dash])
	_q.append([1, Vector2.ZERO, expect, dash])
	_q.append([50, Vector2.ZERO, "", false])


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		var dj: Dictionary = fp.data.get("dojo", {})
		dj["uppercut"] = 1
		dj["haymaker"] = 1
		dj["power_punch"] = 1
		fp.data["dojo"] = dj
		# A fresh stick loadout: the drilled moves sit on their home paths.
		fp.data.erase("stick_loadout")
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n == 40:
		_f = get_first_node_in_group("players")
		_pr = root.get_node("PadRouter")
		_f.set("facing", 1)
		_path([Vector2(1, 0)], 2, "light")
		_path([Vector2(0, -1), Vector2(0.7, -0.7), Vector2(1, 0)], 2, "hook")
		_path([Vector2(0, 1), Vector2(0.7, 0.7), Vector2(1, 0), Vector2(0.7, -0.7), Vector2(0, -1)], 2, "uppercut")
		_path([Vector2(-1, 0), Vector2(-1, 0), Vector2(1, 0)], 12, "haymaker")
		_path([Vector2(-1, 0), Vector2(-1, 0), Vector2(-1, 0), Vector2(-1, 0), Vector2(-1, 0), Vector2(1, 0)], 14, "power_punch")
		_path([Vector2(1, 0)], 2, "front_kick", true)
	if _n > 40 and _f != null:
		if _cur.is_empty() or _cur[0] <= 0:
			if _q.is_empty():
				var want := ["light", "hook", "uppercut", "haymaker", "power_punch", "front_kick"]
				for w in want:
					if not _seen.has(w):
						_fail.append("missed " + w)
				print("RS OK  %s" % [_seen] if _fail.is_empty() else "RS FAIL %s seen %s" % [_fail, _seen])
				return true
			_cur = _q.pop_front()
		_cur[0] -= 1
		_pr.fake_rs["p1_"] = _cur[1]
		if _cur[3]:
			Input.action_press("p1_dash")
		else:
			Input.action_release("p1_dash")
		if str(_cur[2]) != "" and not _cur.has("done"):
			_cur.append("done")
			_f.set("attack_cd", 0)
			_f.set("anim_atk", "")
		if _cur.has("done") and _cur[0] == 0:
			pass
		var k := str(_f.get("_last_kind"))
		if k != "" and (_seen.is_empty() or _seen[-1] != k):
			_seen.append(k)
	return false
