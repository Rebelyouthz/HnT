extends SceneTree

## Screenshots along a map: the player is moved to each x and the frame is
## saved, to check the backdrop sections end to end.
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/street_tour.gd -- dock_street /tmp/out 300,800,1300
var _map := "dock_street"
var _out := "/tmp"
var _xs: Array = []
var _frame := 0
var _i := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_map = a[0]
	if a.size() > 1:
		_out = a[1]
	if a.size() > 2:
		for v in a[2].split(","):
			_xs.append(float(v))


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		var fp := root.get_node("FamilyProfile")
		(fp.data as Dictionary)["intro_done"] = true
		(fp.data as Dictionary)["named"] = true
		root.get_node("App").call("enter_map", _map)
	if _frame > 60 and (_frame - 60) % 40 == 0:
		var f: Node2D = null
		for n in get_nodes_in_group("players"):
			f = n
		if f == null:
			return false
		if _i > 0:
			root.get_viewport().get_texture().get_image().save_png("%s/%s_%d.png" % [_out, _map, int(_xs[_i - 1])])
		if _i >= _xs.size():
			quit(0)
			return true
		f.global_position = Vector2(float(_xs[_i]), 490.0)
		for e in get_nodes_in_group("enemies"):
			(e as Node2D).global_position.x = -2000.0
		_i += 1
	return false
