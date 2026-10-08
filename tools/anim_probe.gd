extends SceneTree

## Films the solo hero doing a scripted input line, cropped around him.
##   xvfb-run ... --script res://tools/anim_probe.gd -- <out_dir> <role> <map> <seq> [every]
## seq: "right@0-80,light@90,light@104,heavy@120,end@170" (frame offsets from 60).

var START := 60
var _dir := ""
var _role := "father"
var _map := "dock_street"
var _seq: Array = []
var _end := 200
var _every := 2
var _n := 0
var _hero: Node2D


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_dir = a[0]
	_role = a[1]
	_map = a[2]
	for part in a[3].split(","):
		var act := part.get_slice("@", 0)
		var span := part.get_slice("@", 1)
		var s := int(span.get_slice("-", 0))
		var e := int(span.get_slice("-", 1)) if span.contains("-") else s + 3
		if act == "end":
			_end = s
		else:
			_seq.append([act, s, e])
	if a.size() > 4:
		_every = int(a[4])
	if a.size() > 5:
		START = int(a[5])
	DirAccess.make_dir_recursive_absolute(_dir)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["named"] = true
		root.get_node("App").set("solo_role", _role)
		change_scene_to_file("res://scenes/levels/%s.tscn" % _map)
	if _n == START - 5:
		for p in root.get_tree().get_nodes_in_group("players"):
			_hero = p
	if _hero == null or _n < START:
		return false
	var t := _n - START
	var pre := str(_hero.get("prefix"))
	for st in _seq:
		if t == int(st[1]):
			Input.action_press(pre + str(st[0]))
		if t == int(st[2]):
			Input.action_release(pre + str(st[0]))
	if t % _every == 0:
		var img := root.get_texture().get_image()
		img.save_png("%s/f_%04d.png" % [_dir, t])
	if t >= _end:
		print("PROBE done ", _hero.get("role"), " ", _hero.get("anim").animation if _hero.get("anim") else "")
		quit()
	return false
