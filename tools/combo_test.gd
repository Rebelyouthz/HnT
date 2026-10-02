extends SceneTree

## Drives every learned combo on the dojo dummy and reports which ones land.
## Headless works for the logic; with a renderer it also saves a frame at
## each finisher's contact:
##   xvfb-run -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/combo_test.gd -- son /tmp/out
## Prints COMBO_OK <id> / COMBO_MISS <id>, then COMBO_TEST n/m.

var _who := "son"
var _out := ""
var _f: Node
var _CB: Script
var _queue: Array = []
var _landed: Dictionary = {}
var _frame := 0
var _phase := "boot"
var _wait := 0
var _cur: Dictionary = {}
var _step := 0
var _shots := 0
var _beat_wait := 0
var _log: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_who = args[0]
	if args.size() > 1:
		_out = args[1]


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_CB = load("res://src/combat/combo_book.gd")
		var fp := root.get_node("FamilyProfile")
		var d := fp.data as Dictionary
		d["intro_done"] = true
		d["named"] = true
		var dojo: Dictionary = d.get("dojo", {})
		for c: Dictionary in _CB.all_for(_who):
			dojo[str(c["id"])] = 1
		d["dojo"] = dojo
		root.get_node("App").set_meta("dojo_role", _who)
		root.get_node("App").call("enter_map", "dojo_practice")
	if _frame == 40:
		for n in get_nodes_in_group("players"):
			if n.get("role") != null and n.has_signal("combo_landed"):
				_f = n
		if _f == null:
			print("COMBO_TEST no fighter")
			quit(1)
			return true
		_f.combo_landed.connect(func(id: String, perfect: bool) -> void:
			_landed[id] = perfect
		)
		_queue = _CB.all_for(_who).duplicate()
		_phase = "next"
	if _frame > 40:
		_tick()
	if _frame > 40 + 400 * 15:
		_finish()
	return false


func _release_all() -> void:
	for a in ["light", "heavy", "jump", "dash", "left", "right", "up", "down"]:
		Input.action_release("p1_" + a)


func _tick() -> void:
	if _wait > 0:
		_wait -= 1
		return
	match _phase:
		"next":
			_release_all()
			if _queue.is_empty():
				_finish()
				return
			_cur = _queue.pop_front()
			_step = 0
			# Square up to the dummy, facing it.
			_f.global_position = Vector2(760, 492)
			_f.facing = 1
			_f.visual.scale.x = 1.0
			_f.attack_cd = 0
			_f.steam = 100.0
			_f._combo.hist.clear()
			_wait = 40
			_phase = "ready"
		"ready":
			if _f.attack_cd == 0 and _f._strike_phase == 0 and _f.anim_atk == "":
				_f._combo.hist.clear()
				_phase = "press"
		"press":
			if _out != "":
				# Screenshot mode (slow software renderer): play the
				# finisher directly and grab frames through it.
				_f._combo_finish(_cur)
				_snap_series(str(_cur["id"]))
				_phase = "settle"
				_wait = 90
				return
			var steps: Array = _cur["steps"]
			if _step >= steps.size():
				_phase = "settle"
				_wait = 70
				return
			for a in ["left", "right", "up", "down"]:
				Input.action_release("p1_" + a)
			_press(str(steps[_step]))
			_step += 1
			_phase = "release"
			_wait = 4
		"release":
			_beat_wait = 0
			for a in ["light", "heavy", "jump", "dash"]:
				Input.action_release("p1_" + a)
			# Wait for the beat: contact + PERFECT_AT (or a short gap after J/D).
			_phase = "beat"
			_wait = 1
		"beat":
			var cb = _f._combo
			if _step >= (_cur["steps"] as Array).size():
				_phase = "settle"
				_wait = 70
				if _out != "":
					_snap_later()
				return
			_beat_wait += 1
			if _beat_wait > 90:
				_log.append("timeout@%d" % _step)
				_phase = "press"
			elif cb.ring_t >= 0.0 and _f._clock - cb.ring_t >= _CB.PERFECT_AT - 0.01 and _f.attack_cd == 0:
				_phase = "press"
			elif cb.ring_t >= 0.0 and _f._clock - cb.ring_t > _CB.WINDOW:
				_phase = "press"
		"settle":
			var id: String = str(_cur["id"])
			print("COMBO_%s %s %s %s" % ["OK" if _landed.has(id) else "MISS", id, "perfect" if bool(_landed.get(id, false)) else "", " ".join(_log)])
			_log.clear()
			_phase = "next"


func _press(tok: String) -> void:
	_log.append("%s(cd%d,h%d)" % [tok, _f.attack_cd, _f._combo.hist.size()])
	var parts := tok.split("+")
	var btn := parts[parts.size() - 1]
	var dir := parts[0] if parts.size() > 1 else ""
	match dir:
		"F":
			Input.action_press("p1_right")
		"B":
			Input.action_press("p1_left")
		"U":
			Input.action_press("p1_up")
		"Dn":
			Input.action_press("p1_down")
	match btn:
		"L":
			Input.action_press("p1_light")
		"H":
			# Heavy fires on release: press now, release next frame.
			Input.action_press("p1_heavy")
		"J":
			Input.action_press("p1_jump")
		"D":
			Input.action_press("p1_dash")


func _snap_later() -> void:
	var id: String = str(_cur["id"])
	var t := create_timer(0.35)
	t.timeout.connect(func() -> void:
		var img := root.get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("%s/%s_%s.png" % [_out, _who, id])
	)


func _snap_series(id: String) -> void:
	for k in 4:
		var t := create_timer(0.12 + 0.18 * float(k))
		t.timeout.connect(func() -> void:
			var img := root.get_viewport().get_texture().get_image()
			if img != null:
				img.save_png("%s/%s_%s_%d.png" % [_out, _who, id, k])
		)


func _finish() -> void:
	var total: int = _CB.all_for(_who).size()
	print("COMBO_TEST %d/%d" % [_landed.size(), total])
	quit(0)
