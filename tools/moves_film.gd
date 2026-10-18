extends SceneTree

## Every input in the training alley, filmed: one row of frames per move.
const OUT := "/tmp/claude-0/-home-user-Cursor-game/c1368381-f1a9-5ff4-8de3-c7ed53e24c3a/scratchpad/moves/"
# [name, [[frame, "press"/"release", action], ...], length]
var MOVES := [
	["X", [[0, "p", "p1_light"], [3, "r", "p1_light"]], 40],
	["X_X_X", [[0, "p", "p1_light"], [3, "r", "p1_light"], [14, "p", "p1_light"], [17, "r", "p1_light"], [28, "p", "p1_light"], [31, "r", "p1_light"]], 70],
	["Y", [[0, "p", "p1_heavy"], [3, "r", "p1_heavy"]], 44],
	["Y_Y_Y", [[0, "p", "p1_heavy"], [3, "r", "p1_heavy"], [16, "p", "p1_heavy"], [19, "r", "p1_heavy"], [32, "p", "p1_heavy"], [35, "r", "p1_heavy"]], 80],
	["holdY", [[0, "p", "p1_heavy"], [50, "r", "p1_heavy"]], 90],
	["fwdY", [[0, "p", "p1_right"], [2, "p", "p1_heavy"], [5, "r", "p1_heavy"], [8, "r", "p1_right"]], 48],
	["Y_then_up", [[0, "p", "p1_heavy"], [3, "p", "p1_up"], [5, "r", "p1_heavy"], [10, "r", "p1_up"]], 48],
	["downX", [[0, "p", "p1_down"], [2, "p", "p1_light"], [5, "r", "p1_light"], [8, "r", "p1_down"]], 44],
	["downY", [[0, "p", "p1_down"], [2, "p", "p1_heavy"], [5, "r", "p1_heavy"], [8, "r", "p1_down"]], 48],
	["L1_block", [[0, "p", "p1_block"], [40, "r", "p1_block"]], 44],
	["L1_up_high", [[0, "p", "p1_up"], [1, "p", "p1_block"], [40, "r", "p1_block"], [41, "r", "p1_up"]], 44],
	["L1_down_low", [[0, "p", "p1_down"], [1, "p", "p1_block"], [40, "r", "p1_block"], [41, "r", "p1_down"]], 44],
	["L1_X", [[0, "p", "p1_block"], [4, "p", "p1_light"], [7, "r", "p1_light"], [30, "r", "p1_block"]], 46],
	["L1_Y", [[0, "p", "p1_block"], [4, "p", "p1_heavy"], [7, "r", "p1_heavy"], [30, "r", "p1_block"]], 50],
	["L2_X", [[0, "p", "p1_throw"], [4, "p", "p1_light"], [7, "r", "p1_light"], [30, "r", "p1_throw"]], 46],
	["L2_Y", [[0, "p", "p1_throw"], [4, "p", "p1_heavy"], [7, "r", "p1_heavy"], [30, "r", "p1_throw"]], 50],
	["R2_X", [[0, "p", "p1_dash"], [4, "p", "p1_light"], [7, "r", "p1_light"], [20, "r", "p1_dash"]], 46],
	["R2_Y", [[0, "p", "p1_dash"], [4, "p", "p1_heavy"], [7, "r", "p1_heavy"], [20, "r", "p1_dash"]], 50],
	["X+Y_grab", [[0, "p", "p1_light"], [1, "p", "p1_heavy"], [5, "r", "p1_light"], [5, "r", "p1_heavy"]], 70],
	["jump_X", [[0, "p", "p1_jump"], [4, "r", "p1_jump"], [10, "p", "p1_light"], [13, "r", "p1_light"]], 50],
	["jump_Y", [[0, "p", "p1_jump"], [4, "r", "p1_jump"], [10, "p", "p1_heavy"], [13, "r", "p1_heavy"]], 56],
	["pickup", [[0, "p", "p1_light"], [1, "p", "p1_heavy"], [5, "r", "p1_light"], [5, "r", "p1_heavy"]], 40],
	["pipe_X", [[0, "p", "p1_light"], [3, "r", "p1_light"]], 50],
	["pipe_Y", [[0, "p", "p1_heavy"], [3, "r", "p1_heavy"]], 56],
	["pipe_XXY", [[0, "p", "p1_light"], [3, "r", "p1_light"], [22, "p", "p1_light"], [25, "r", "p1_light"], [46, "p", "p1_heavy"], [49, "r", "p1_heavy"]], 100],
	["four_throw", [[0, "p", "p1_block"], [0, "p", "p1_throw"], [0, "p", "p1_shoot"], [0, "p", "p1_dash"], [6, "r", "p1_block"], [6, "r", "p1_throw"], [6, "r", "p1_shoot"], [6, "r", "p1_dash"]], 40],
	["throw", [[0, "p", "p1_light"], [1, "p", "p1_heavy"], [5, "r", "p1_light"], [5, "r", "p1_heavy"]], 96],
	["throw_slam", [[0, "p", "p1_light"], [1, "p", "p1_heavy"], [5, "r", "p1_light"], [5, "r", "p1_heavy"], [74, "p", "p1_down"], [76, "p", "p1_heavy"], [79, "r", "p1_heavy"], [82, "r", "p1_down"]], 130],
	["four_knife", [[0, "p", "p1_block"], [0, "p", "p1_throw"], [0, "p", "p1_shoot"], [0, "p", "p1_dash"], [6, "r", "p1_block"], [6, "r", "p1_throw"], [6, "r", "p1_shoot"], [6, "r", "p1_dash"]], 40],
]
var SHOTS := int(OS.get_environment("SHOTS")) if OS.get_environment("SHOTS") != "" else 8

var _n := 0
var _f: Node2D
var _mi := -1
var _t0 := 0
var _rows: Array = []
var _cur: Array = []
var _log: Array = []


func _hero_crop() -> Image:
	var img := root.get_viewport().get_texture().get_image()
	var p := _f.get_global_transform_with_canvas().origin
	var sc := float(img.get_width()) / float(root.get_viewport().get_visible_rect().size.x)
	var cx := int(p.x * sc)
	var cy := int(p.y * sc)
	var r := Rect2i(clampi(cx - 260, 0, img.get_width() - 520), clampi(cy - 420, 0, img.get_height() - 480), 520, 480)
	var c := img.get_region(r)
	c.resize(260, 240)
	return c


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	for g in get_nodes_in_group("guide"):
		g.queue_free()
	if _n == 2:
		root.get_node("FamilyProfile").call("reset_progress")
		root.get_node("FamilyProfile").data["dojo_learned"] = {"uppercut": 1, "roundhouse": 1}
		root.get_node("App").set("solo_role", OS.get_environment("WHO") if OS.get_environment("WHO") != "" else "father")
		root.get_node("App").call("enter_map", "tutorial_alley")
		return false
	if _n < 200 or current_scene == null:
		return false
	if _n == 200:
		var only := OS.get_environment("ONLY")
		if only != "":
			var keep := only.split(",")
			MOVES = MOVES.filter(func(m): return str(m[0]) in keep)
		current_scene.call("_begin", 10)
		for f in get_nodes_in_group("players"):
			_f = f
		_next()
		return false
	if _f == null:
		return false
	var t := _n - _t0
	var m: Array = MOVES[_mi]
	for ev in m[1]:
		if int(ev[0]) == t:
			if str(ev[1]) == "p":
				Input.action_press(str(ev[2]))
			else:
				Input.action_release(str(ev[2]))
	var length := int(m[2])
	var every := maxi(1, length / SHOTS)
	if t % every == 0 and _cur.size() < SHOTS:
		_cur.append(_hero_crop())
		_log.append("%s t=%d anim=%s atk=%s blk=%s pick=%s" % [m[0], t, _f.get("_anim").animation if _f.get("_anim") else "-", _f.get("anim_atk"), _f.get("blocking"), _f.get("pickup")])
	if t >= length + 30:
		_rows.append([m[0], _cur])
		_next()
	return false


func _next() -> void:
	_cur = []
	_mi += 1
	for a in ["p1_light", "p1_heavy", "p1_block", "p1_throw", "p1_shoot", "p1_dash", "p1_up", "p1_down", "p1_right", "p1_left", "p1_jump"]:
		Input.action_release(a)
	if _mi >= MOVES.size():
		_save()
		quit()
		return
	var name := str(MOVES[_mi][0])
	# Line up a step from the bag, facing it.
	_f.global_position = Vector2(640.0 - (130.0 if name.begins_with("four") else 58.0), 492.0)
	_f.set("facing", 1)
	if name == "pickup":
		var wp: Node2D = load("res://src/world/weapon_pickup.gd").new()
		wp.set("kind", "pipe")
		wp.global_position = _f.global_position
		current_scene.add_child(wp)
	if name == "throw" or name == "throw_slam":
		_f.global_position = Vector2(1000.0, 492.0)
		var p: Node = load("res://src/coop/party.gd").call("spawn_row", current_scene, {"title": "Bag Snatch", "x": 1044.0, "y": 492, "home": "street", "hp": 200, "pmin": 900.0, "pmax": 1200.0}, 1.0)
		if p:
			p.set("recover", 2.0)
			p.set("kit", {"attack": "light", "block": 0.0})
	if name == "four_knife":
		_f.set("pickup", "")
		_f.set("knives", 3)
	_f.set("attack_cd", 0)
	_t0 = _n + 1


func _save() -> void:
	var w := 260 * SHOTS
	for i in range(0, _rows.size(), 9):
		var chunk: Array = _rows.slice(i, i + 9)
		var sheet := Image.create(w + 160, 240 * chunk.size(), false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.1, 0.1, 0.14))
		for r in chunk.size():
			var shots: Array = chunk[r][1]
			for k in shots.size():
				var im: Image = shots[k]
				im.convert(Image.FORMAT_RGBA8)
				sheet.blit_rect(im, Rect2i(0, 0, 260, 240), Vector2i(160 + k * 260, r * 240))
		sheet.save_png(OUT + "sheet_%s_%d.png" % [OS.get_environment("WHO") if OS.get_environment("WHO") != "" else "father", i / 9])
	var f := FileAccess.open(OUT + "log.txt", FileAccess.WRITE)
	for r in _rows:
		f.store_line(str(r[0]))
	for l in _log:
		f.store_line(l)
