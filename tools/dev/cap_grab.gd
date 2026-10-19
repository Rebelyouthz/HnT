extends SceneTree

## Dev: a grab on the dojo dummy, frames saved.  -- <father|son> <out_prefix>
var _n := 0
var _who := "father"
var _out := ""
var _h: Node2D
var _d: Node2D


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_who = a[0] if a.size() > 0 else "father"
	_out = a[1] if a.size() > 1 else "/tmp/grab"


func _process(_dt: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["guides_done"] = load("res://src/ui/guides.gd").STEPS.keys() if load("res://src/ui/guides.gd").STEPS is Dictionary else []
		root.get_node("App").set("solo_role", _who)
		root.get_node("App").set_meta("dojo_role", _who)
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n > 10 and paused:
		paused = false
	if _n == 60:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		_h = get_first_node_in_group("players")
		for e in get_nodes_in_group("enemies"):
			_d = e
		_h.global_position = _d.global_position + Vector2(-26, 0)
		_h.set("facing", 1)
		_h.set("chi", 100.0)
		Input.action_press("p1_light")
		Input.action_press("p1_heavy")
	if _n == 63:
		Input.action_release("p1_light")
		Input.action_release("p1_heavy")
	if _n in [66, 76, 86, 100]:
		root.get_texture().get_image().save_png("%s_%d.png" % [_out, _n])
		var who: Array = []
		for p in get_nodes_in_group("players"):
			who.append(str(p.get("role")))
		print("F", _n, " players=", who, " anim=", _h.get("anim_atk"), " dummy=", _d.get("title"))
	return _n > 102
