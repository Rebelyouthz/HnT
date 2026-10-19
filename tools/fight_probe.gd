extends SceneTree

## Fight bot on a story map: walks at the nearest thug, mashes light/heavy,
## jumps now and then, and saves a frame every N ticks (fresh scratch save).
##   xvfb-run ... --fixed-fps 60 --script res://tools/fight_probe.gd -- <map> <out_prefix> [frames] [every]

var _n := 0
var _map := "dock_street"
var _out := ""
var _frames := 2400
var _every := 60


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_map = a[0]
	_out = a[1]
	if a.size() > 2:
		_frames = int(a[2])
	if a.size() > 3:
		_every = int(a[3])


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		if FileAccess.file_exists("user://family.json"):
			DirAccess.copy_absolute("user://family.json", "user://family.fight_backup.json")
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		Engine.set_meta("probe_no_draw", true)
		change_scene_to_file("res://scenes/levels/%s.tscn" % _map)
	if _n > 240:
		_drive()
	if _n % _every == 0 and _n > 240:
		root.get_texture().get_image().save_png("%s_%05d.png" % [_out, _n])
	if _n >= _frames:
		if FileAccess.file_exists("user://family.fight_backup.json"):
			DirAccess.copy_absolute("user://family.fight_backup.json", "user://family.json")
		quit()
	return false


func _drive() -> void:
	var hero: Node2D = get_first_node_in_group("players") as Node2D
	if hero == null:
		return
	var best: Node2D = null
	var bd := 1e9
	for e in get_nodes_in_group("enemies"):
		var n2 := e as Node2D
		if n2 == null or not n2.is_visible_in_tree():
			continue
		var d := n2.global_position.distance_to(hero.global_position)
		if d < bd:
			bd = d
			best = n2
	for k in ["p1_left", "p1_right", "p1_up", "p1_down"]:
		Input.action_release(k)
	if best == null or bd > 900.0:
		Input.action_press("p1_right")
	else:
		var dx := best.global_position.x - hero.global_position.x
		var dy := best.global_position.y - hero.global_position.y
		if absf(dx) > 70.0:
			Input.action_press("p1_right" if dx > 0.0 else "p1_left")
		if absf(dy) > 14.0:
			Input.action_press("p1_down" if dy > 0.0 else "p1_up")
	var t := _n % 48
	_tap("p1_light", t == 0 or t == 12 or t == 24)
	_tap("p1_heavy", t == 36)
	_tap("p1_jump", _n % 600 == 300)


func _tap(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)
