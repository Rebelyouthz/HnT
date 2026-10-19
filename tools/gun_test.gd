extends SceneTree

## Shoots a Bag Snatch in the dojo with each gun at a zone and distance and
## saves frames: checks aim pose, rounds, flashes and the gun deaths.
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/gun_test.gd -- /tmp/out shotgun:head:60 pistol:head:300 ...

var _out := "/tmp"
var _cases: Array = []
var _frame := 0
var _f: Node2D
var _cur := 0
var _t := 0
var _target: Node2D
var _party: Script


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0]
	for i in range(1, a.size()):
		_cases.append(a[i].split(":"))


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		var fp := root.get_node("FamilyProfile")
		(fp.data as Dictionary)["intro_done"] = true
		root.get_node("App").call("enter_map", "dojo_practice")
		_party = load("res://src/coop/party.gd")
	if _frame < 40:
		return false
	if _f == null:
		for n in get_nodes_in_group("players"):
			_f = n
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		return false
	_t += 1
	if _cur >= _cases.size():
		quit(0)
		return true
	var c: PackedStringArray = _cases[_cur]
	var w := c[0]
	var zone := c[1]
	var dist := float(c[2])
	if _t == 1:
		_f.global_position = Vector2(500, 492)
		_f.set("facing", 1)
		(_f.get("visual") as Node2D).scale.x = 1.0
		var p: Node2D = _party.spawn_row(_f.get_parent(), {"title": "Bag Snatch", "x": 500 + dist, "y": 492, "home": "street", "hp": 30, "pmin": 0, "pmax": 2000}, 1.0)
		_target = p
		_f.call("equip_pickup", w)
		_f.set("aim_t", 0.6)
	if _t == 20:
		var y := -1.0 if zone == "head" else (1.0 if zone == "legs" else 0.0)
		if y < 0.0:
			Input.action_press("p1_up")
		elif y > 0.0:
			Input.action_press("p1_down")
		# Keep him still and in front.
		if is_instance_valid(_target):
			_target.set("recover", 2.0)
			_target.set("hp", 1 if c.size() < 4 else 999)
		_f.set("gun_cd", 0.0)
		_f.call("_fire_gun")
	if _t == 22:
		Input.action_release("p1_up")
		Input.action_release("p1_down")
	for k in [21, 26, 34, 50, 80]:
		if _t == k:
			var img := root.get_viewport().get_texture().get_image()
			img.save_png("%s/%s_%s_%d_%02d.png" % [_out, w, zone, int(dist), k])
			# And a 2x crop of shooter + target.
			var o := _f.get_global_transform_with_canvas().origin * (float(img.get_width()) / 640.0)
			var r := Rect2i(int(o.x) - 80, int(o.y) - 230, 560, 280).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			var cr := img.get_region(r)
			cr.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_NEAREST)
			cr.save_png("%s/z_%s_%s_%d_%02d.png" % [_out, w, zone, int(dist), k])
	if _t > 90:
		for n in get_nodes_in_group("corpses"):
			n.queue_free()
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_cur += 1
		_t = 0
	return false
