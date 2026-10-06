extends SceneTree

## Plays a map by itself and saves a frame every few ticks, for a video of
## the real game: walks right, fights whatever is in front (jab strings,
## heavies, a learned combo now and then), blocks at the called height.
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/autoplay.gd -- dock_street /tmp/frames 900
var _map := "dock_street"
var _out := "/tmp"
var _ticks := 900
var _frame := 0
var _shot := 0
var _f: Node2D
var _act := 0
var _last_x := 0.0
var _stuck := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_map = a[0]
	if a.size() > 1:
		_out = a[1]
	if a.size() > 2:
		_ticks = int(a[2])


func _release() -> void:
	for k in ["left", "right", "up", "down", "light", "heavy", "block", "jump", "dash"]:
		Input.action_release("p1_" + k)


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		var fp := root.get_node("FamilyProfile")
		var d := fp.data as Dictionary
		d["intro_done"] = true
		d["named"] = true
		var g_done: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g_done.append(str(gk))
		d["guides_done"] = g_done
		root.get_node("App").call("enter_map", _map)
		return false
	if _frame < 50:
		return false
	if _f == null or not is_instance_valid(_f):
		for n in get_nodes_in_group("players"):
			_f = n
		if _f == null:
			return false
	# Card deals and banners pause the game: take the first card.
	if paused:
		# Take the first card of any deal directly.
		if _frame % 30 == 0:
			for n in root.find_children("*", "CanvasLayer", true, false):
				if n.has_method("_choose") and n.get_script() != null and str(n.get_script().resource_path).ends_with("card_pick.gd"):
					n.call("_choose", 0)
				elif n.has_method("_pick") and n.get_script() != null and str(n.get_script().resource_path).ends_with("survive_pick.gd"):
					var offs: Array = n.get("_offers")
					if not offs.is_empty():
						n.call("_pick", offs[0])
		if _frame % 20 == 0:
			Input.action_press("ui_accept")
		elif _frame % 20 == 2:
			Input.action_release("ui_accept")
		return false
	# Keep the hero alive for the film.
	_f.set("hp", maxi(int(_f.get("hp")), 20))
	_drive()
	if _out != "" and _out != "-" and _frame % 3 == 0:
		root.get_viewport().get_texture().get_image().save_png("%s/f_%05d.png" % [_out, _shot])
		_shot += 1
	if _frame > 50 + _ticks:
		quit(0)
		return true
	return false


func _drive() -> void:
	_release()
	var near: Node2D = null
	var nd := 9999.0
	for e in get_nodes_in_group("enemies"):
		var n := e as Node2D
		if n == null or not is_instance_valid(n) or int(n.get("hp")) <= 0:
			continue
		var dx := n.global_position.x - _f.global_position.x
		if dx > -40.0 and absf(dx) < nd and absf(n.global_position.y - _f.global_position.y) < 60.0:
			nd = absf(dx)
			near = n
	if near != null and nd < 70.0:
		var h := str(near.get("atk_height"))
		if float(near.get("telegraph")) > 0.0 and h != "":
			Input.action_press("p1_block")
			if h == "high":
				Input.action_press("p1_up")
			elif h == "low":
				Input.action_press("p1_down")
			return
		_act += 1
		var beat := _act % 40
		if beat in [1, 9, 17]:
			Input.action_press("p1_light")
		elif beat == 24:
			Input.action_press("p1_right")
			Input.action_press("p1_heavy")
		elif beat in [25, 26]:
			Input.action_press("p1_right")
		if near.global_position.y > _f.global_position.y + 4.0:
			Input.action_press("p1_down")
		elif near.global_position.y < _f.global_position.y - 4.0:
			Input.action_press("p1_up")
		return
	Input.action_press("p1_right")
	# Blocked by a prop: smash it, hop over it.
	if absf(_f.global_position.x - _last_x) < 0.5:
		_stuck += 1
	else:
		_stuck = 0
	_last_x = _f.global_position.x
	if _stuck > 20:
		if _stuck % 12 == 0:
			Input.action_press("p1_light")
		if _stuck > 90 and _stuck % 30 == 0:
			Input.action_press("p1_jump")
		if _stuck > 160:
			_f.global_position.x += 60.0
			_stuck = 0
	if near != null and nd < 200.0:
		if near.global_position.y > _f.global_position.y + 6.0:
			Input.action_press("p1_down")
		elif near.global_position.y < _f.global_position.y - 6.0:
			Input.action_press("p1_up")
