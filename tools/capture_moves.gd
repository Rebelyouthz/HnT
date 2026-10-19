extends SceneTree

## Records the Father playing a scripted input sequence, one PNG per frame,
## cropped around him, at 1080p with the real renderer. For judging timing,
## combos, hit vs whiff and jump arcs in game rather than in a sprite viewer.
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1920x1080 --windowed --fixed-fps 60 \
##     --script res://tools/capture_moves.gd -- <out_dir> <script> [map]
## script: combo | whiff | kicks | jump | run
## Every frame N saves <out_dir>/f_NNNN.png (720x540 around the Father).

const START := 50
const SCRIPTS := {
	# [frame offset, action, down?]
	"combo": [[0, "light", true], [2, "light", false], [14, "light", true], [16, "light", false], [28, "light", true], [30, "light", false], [46, "heavy", true], [48, "heavy", false], [100, "", false]],
	"whiff": [[0, "light", true], [2, "light", false], [24, "heavy", true], [26, "heavy", false], [80, "", false]],
	"kicks": [[0, "light", true], [2, "light", false], [14, "light", true], [16, "light", false], [30, "heavy", true], [32, "heavy", false], [90, "", false]],
	"jump": [[0, "jump", true], [30, "jump", false], [80, "", false]],
	"run": [[0, "right", true], [70, "right", false], [72, "", false]],
}

var _dir := "user://moves"
var _script := "combo"
var _map := "dock_street"
var _n := 0
var _dad: Node2D
var _seq: Array = []
var _end := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_dir = args[0]
	if args.size() > 1:
		_script = args[1]
	if args.size() > 2:
		_map = args[2]
	_seq = SCRIPTS.get(_script, SCRIPTS["combo"])
	_end = START + int((_seq[_seq.size() - 1] as Array)[0])
	DirAccess.make_dir_recursive_absolute(_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))


func _prepare() -> void:
	var fp := root.get_node_or_null("FamilyProfile")
	if fp != null and fp.get("data") is Dictionary:
		var d := fp.data as Dictionary
		d["intro_done"] = true
		d["named"] = true
		var learned: Dictionary = d.get("dojo", {})
		for k in ["roundhouse", "uppercut", "air_mix"]:
			learned[k] = maxi(1, int(learned.get(k, 0)))
		d["dojo"] = learned
	change_scene_to_file("res://scenes/levels/%s.tscn" % _map)


func _find_dad() -> void:
	for n in root.get_tree().get_nodes_in_group("players"):
		if str(n.get("role")) == "father" and n.has_method("take_hit"):
			_dad = n as Node2D
	if _dad == null:
		var stack: Array[Node] = [root]
		while not stack.is_empty():
			var c: Node = stack.pop_back()
			if str(c.get("role")) == "father" and c.has_method("_attack"):
				_dad = c as Node2D
				break
			stack.append_array(c.get_children())


func _process(_delta: float) -> bool:
	_n += 1
	if _n == 2:
		_prepare()
	if _n > 900:
		print("MOVES no father found")
		quit()
	if _n == START - 20:
		_find_dad()
		if _dad == null:
			# Solo maps spawn only the Son: put the Father next to him.
			var any: Node2D = null
			var stack: Array[Node] = [root]
			while not stack.is_empty() and any == null:
				var c: Node = stack.pop_back()
				if c.has_method("_attack") and c.get("role") != null:
					any = c as Node2D
				stack.append_array(c.get_children())
			if any != null:
				_dad = load("res://src/coop/party.gd").make_father(any.global_position + Vector2(-60, 0), &"p2_")
				any.get_parent().add_child(_dad)
				any.global_position.x -= 140.0
		print("MOVES dad ", _dad)
		if _dad != null and _script != "whiff" and _script != "jump" and _script != "run":
			var p: Node2D = load("res://src/coop/party.gd").spawn_row(_dad.get_parent(), {"title": "Bag Snatch", "x": _dad.global_position.x + 44.0, "y": _dad.global_position.y, "hp": 400, "pmin": _dad.global_position.x + 40.0, "pmax": _dad.global_position.x + 50.0}, 1.0)
			if p != null:
				p.global_position = _dad.global_position + Vector2(44, 0)
	if _dad == null or _n < START:
		return false
	var t := _n - START
	for step: Array in _seq:
		if int(step[0]) == t and str(step[1]) != "":
			var act := StringName(str(_dad.get("prefix")) + str(step[1]))
			if bool(step[2]):
				Input.action_press(act)
			else:
				Input.action_release(act)
	var img := root.get_texture().get_image()
	var xf := root.get_final_transform() * _dad.get_canvas_transform()
	var sp: Vector2 = xf * (_dad.global_position + Vector2(0, -30))
	var r := Rect2i(int(sp.x) - 300, int(sp.y) - 300, 720, 460)
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	img.get_region(r).save_png("%s/f_%04d.png" % [_dir, t])
	if _n >= _end:
		print("MOVES ", _script, " ", t + 1, " frames")
		quit()
	return false
