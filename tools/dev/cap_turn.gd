extends SceneTree
## Dev: facing right, LEFT + LIGHT: the turn punch, frames saved.  -- <who> <out>
var _n := 0
var _who := "father"
var _out := "/tmp/turn"
var _h: Node2D
var _t0 := 0
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_who = a[0] if a.size() > 0 else _who
	_out = a[1] if a.size() > 1 else _out
func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("App").set("solo_role", _who)
		root.get_node("App").call("enter_map", "dock_street")
	if _n > 10 and paused:
		paused = false
	if _n == 60:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		_h = get_first_node_in_group("players")
		_h.set("facing", 1)
	if _n == 66:
		Input.action_press("p1_left")
		Input.action_press("p1_light")
		_t0 = Time.get_ticks_msec()
	if _n == 68:
		Input.action_release("p1_light")
	if _n > 66 and _t0 > 0:
		var dt := Time.get_ticks_msec() - _t0
		var an = _h.get("_anim")
		print("n=%d dt=%d facing=%s clip=%s anim=%s fr=%s vs=%s" % [_n, dt, _h.get("facing"), _h.get("_strike_clip"), an.animation if an else "-", an.frame if an else "-", _h.get("visual").scale.x])
		if _n % 2 == 1:
			root.get_texture().get_image().save_png("%s_%03d.png" % [_out, _n])
		if _n > 90:
			quit()
	return false
