extends SceneTree
## Dev: a thug takes jabs to the head (nose bleed, spit, black eye), saved.  -- <out.png>
var _n := 0
var _out := "/tmp/bruise.png"
var _e: Node2D
var _h: Node2D
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else _out
func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["skip_films"] = true
		root.get_node("App").call("enter_map", "butcher_row")
	if _n == 200:
		_h = get_first_node_in_group("players")
		for e in get_nodes_in_group("enemies"):
			_e = e
			break
		_e.set("hp", 900)
		_e.set_physics_process(false)
	if _e and _n > 200 and _n < 320 and _n % 12 == 0:
		_e.global_position = _h.global_position + Vector2(36, 0)
		_h.set("_strike_clip", "jab")
		_e.call("take_hit", "light", _h)
	if _n == 330:
		var img := root.get_texture().get_image()
		var p: Vector2 = _e.get_global_transform_with_canvas().origin * (float(img.get_width()) / float(root.get_visible_rect().size.x))
		var r := Rect2i(int(p.x) - 240, int(p.y) - 420, 480, 480).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
		img.get_region(r).save_png(_out)
		quit()
	return false
