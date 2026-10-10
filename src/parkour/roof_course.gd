class_name RoofCourse
extends Node2D

## The rooftop run's course: a line of buildings with gaps, steps up and
## drops, and on the roofs the things a runner has to read at speed:
##   vault  a low box (AC unit, pallets, meter) - UP near it vaults over
##   slide  an overhead pipe on posts - DOWN slides under it
##   climb  a tall hut / shed - UP near it wall-runs up and mantles on
##   ramp   a plank ramp before a big gap - launches high for tricks
##   guard  a security guard - UP kongs over him, DOWN slides into him
## Everything is generated from a seed so a run can be retried the same way.
## Units: the son is ~67 units tall (1 m ~ 37 units).

const ROOF_BASE := 360.0
const FACADE_H := 1500.0
const START_W := 760.0
const GOAL_W := 900.0

var buildings: Array = []   # {x0, x1, y, tint}
var boxes: Array = []       # {type, x0, x1, top, node} - standable (vault / climb)
var bars: Array = []        # {x0, x1, under, node} - slide under
var ramps: Array = []       # {x0, x1, y}
var guards: Array = []      # RoofGuard nodes
var checkpoints: Array = [] # x of safe restarts
var goal_x := 0.0
var end_x := 0.0
var rng := RandomNumberGenerator.new()

static var _tex: Dictionary = {}


static func prop_tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var p := "res://assets/sprites/roof/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]


func build(seed_v: int, count: int) -> void:
	rng.seed = seed_v
	var x := -200.0
	var y := ROOF_BASE
	# The start roof: room to get up to speed.
	_building(x, START_W + 200.0, y)
	x += START_W + 200.0
	checkpoints.append(80.0)
	for i in count:
		var hard := float(i) / float(maxi(1, count - 1))
		var gap := 0.0
		var dy := 0.0
		var roll := rng.randf()
		if roll < 0.45:
			# A gap to jump; wider later on.
			gap = rng.randf_range(70.0, 115.0 + 45.0 * hard)
			dy = rng.randf_range(-30.0, 40.0)
		elif roll < 0.65:
			# A drop to a lower roof (big ones need a roll).
			gap = rng.randf_range(30.0, 90.0)
			dy = rng.randf_range(70.0, 170.0)
		elif roll < 0.82:
			# A step up: the next building's wall has to be climbed.
			gap = 0.0
			dy = -rng.randf_range(60.0, 110.0)
		else:
			gap = rng.randf_range(120.0, 170.0 + 30.0 * hard)
			dy = rng.randf_range(0.0, 30.0)
		y = clampf(y + dy, ROOF_BASE - 230.0, ROOF_BASE + 260.0)
		x += gap
		var w := rng.randf_range(520.0, 980.0)
		var b := _building(x, w, y)
		if i % 4 == 3:
			checkpoints.append(x + 60.0)
		_furnish(b, hard, i)
		# A ramp at the edge before a big gap.
		x += w
	# The way out: the goal roof with the zipline.
	var gy := y
	x += 110.0
	var g := _building(x, GOAL_W, gy)
	goal_x = g["x0"] + 520.0
	end_x = g["x1"]
	_goal_mast(Vector2(goal_x, gy))
	queue_redraw()


func _building(x0: float, w: float, y: float) -> Dictionary:
	var tints := [Color(0.17, 0.13, 0.22), Color(0.2, 0.15, 0.19), Color(0.13, 0.15, 0.22), Color(0.22, 0.17, 0.16), Color(0.15, 0.12, 0.18)]
	var b := {"x0": x0, "x1": x0 + w, "y": y, "tint": tints[rng.randi() % tints.size()], "seed": rng.randi()}
	buildings.append(b)
	return b


## Obstacles and decor on one roof, spaced so each can be read and answered.
func _furnish(b: Dictionary, hard: float, idx: int) -> void:
	var x0: float = b["x0"] + 150.0
	var x1: float = b["x1"] - 150.0
	var y: float = b["y"]
	var at := x0
	var placed := 0
	while at < x1 and placed < 3:
		var r := rng.randf()
		if r < 0.36:
			var kind: String = ["ac", "meter", "fence"][rng.randi() % 3]
			var w := 46.0 if kind == "meter" else (70.0 if kind == "ac" else 120.0)
			var h := 26.0 if kind == "meter" else (30.0 if kind == "ac" else 28.0)
			_box("vault", at, at + w, y - h, kind)
			at += w + rng.randf_range(200.0, 300.0)
		elif r < 0.6:
			var w2 := rng.randf_range(110.0, 170.0)
			_bar(at, at + w2, y - 38.0)
			at += w2 + rng.randf_range(210.0, 300.0)
		elif r < 0.76 and hard > 0.1:
			var kind2: String = ["hut", "shed", "hut_small"][rng.randi() % 3]
			var h2 := rng.randf_range(62.0, 96.0)
			var w3 := rng.randf_range(90.0, 140.0)
			_box("climb", at, at + w3, y - h2, kind2)
			at += w3 + rng.randf_range(230.0, 320.0)
		elif r < 0.88 and idx >= 1:
			var gd := RoofGuard.new()
			gd.position = Vector2(at + 20.0, y)
			add_child(gd)
			guards.append(gd)
			at += rng.randf_range(260.0, 340.0)
		else:
			at += rng.randf_range(120.0, 220.0)
			continue
		placed += 1
	# A plank ramp right at the edge sends you high over the next gap.
	if rng.randf() < 0.3 + 0.2 * hard:
		var rx: float = b["x1"] - 90.0
		ramps.append({"x0": rx, "x1": rx + 70.0, "y": y})
	# Decor behind the run: tanks, dishes, vents, chimneys.
	var n := rng.randi_range(1, 3)
	for k in n:
		var dk: String = ["tank", "dish", "vent", "hook", "chimney", "ladder"][rng.randi() % 6]
		var dx := rng.randf_range(b["x0"] + 40.0, b["x1"] - 40.0)
		_decor(dk, Vector2(dx, y))


func _box(type: String, x0: float, x1: float, top: float, art: String) -> void:
	var n := Node2D.new()
	add_child(n)
	var tex := prop_tex(art)
	if tex:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		var k := Vector2((x1 - x0) / float(tex.get_width()), 0.0)
		var bottom := top + 0.0
		# Fit the box: width exact, height to the top line.
		var h := _ground_y_at(x0) - top
		k.y = h / float(tex.get_height())
		s.scale = k
		s.position = Vector2(x0, top)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		n.add_child(s)
		bottom = top + h
	boxes.append({"type": type, "x0": x0, "x1": x1, "top": top, "node": n, "art": art})


func _bar(x0: float, x1: float, under: float) -> void:
	var n := Node2D.new()
	add_child(n)
	var tex := prop_tex("pipe_bar")
	if tex:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		var floor_y := _ground_y_at(x0)
		var h := floor_y - (under - 22.0)
		s.scale = Vector2((x1 - x0) / float(tex.get_width()), h / float(tex.get_height()))
		s.position = Vector2(x0, under - 22.0)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		n.add_child(s)
	bars.append({"x0": x0, "x1": x1, "under": under, "node": n})


func _decor(kind: String, feet: Vector2) -> void:
	var tex := prop_tex(kind)
	if tex == null:
		return
	var h := {"tank": 90.0, "dish": 120.0, "vent": 80.0, "hook": 60.0, "chimney": 70.0, "ladder": 50.0}.get(kind, 60.0) as float
	h *= rng.randf_range(0.85, 1.15)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var k := h / float(tex.get_height())
	s.scale = Vector2(k, k)
	s.position = feet - Vector2(float(tex.get_width()) * k * 0.5, h)
	s.modulate = Color(0.72, 0.68, 0.78)
	s.z_index = -2
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(s)


func _goal_mast(feet: Vector2) -> void:
	var m := GoalMast.new()
	m.position = feet
	add_child(m)


# --- Queries ---------------------------------------------------------------

func building_at(x: float) -> Dictionary:
	for b in buildings:
		if x >= float(b["x0"]) and x <= float(b["x1"]):
			return b
	return {}


func _ground_y_at(x: float) -> float:
	var b := building_at(x)
	return float(b["y"]) if not b.is_empty() else INF


## The surface under x (roof or the top of a box), or INF over a gap.
func ground_at(x: float, half_w: float = 8.0) -> float:
	var g := INF
	for xx in [x - half_w, x, x + half_w]:
		var b := building_at(xx)
		if not b.is_empty():
			g = minf(g, float(b["y"]))
	for bx in boxes:
		if x + half_w > float(bx["x0"]) and x - half_w < float(bx["x1"]):
			g = minf(g, float(bx["top"]))
	return g


## The first thing in the way ahead of x within `reach`: a box or a taller
## building face. {kind, x, top, box} or {}.
func wall_ahead(x: float, feet_y: float, reach: float) -> Dictionary:
	var best := {}
	var best_x := INF
	for bx in boxes:
		var fx := float(bx["x0"])
		if fx > x - 2.0 and fx < x + reach and float(bx["top"]) < feet_y - 6.0 and fx < best_x:
			best_x = fx
			best = {"kind": str(bx["type"]), "x": fx, "top": float(bx["top"]), "box": bx}
	for b in buildings:
		var fx2 := float(b["x0"])
		if fx2 > x - 2.0 and fx2 < x + reach and float(b["y"]) < feet_y - 6.0 and fx2 < best_x:
			best_x = fx2
			best = {"kind": "wall", "x": fx2, "top": float(b["y"]), "box": {}}
	return best


func bar_at(x: float) -> Dictionary:
	for br in bars:
		if x > float(br["x0"]) - 6.0 and x < float(br["x1"]) + 6.0:
			return br
	return {}


func bar_ahead(x: float, reach: float) -> Dictionary:
	for br in bars:
		if float(br["x0"]) > x and float(br["x0"]) < x + reach:
			return br
	return {}


func ramp_at(x: float) -> Dictionary:
	for r in ramps:
		if x >= float(r["x0"]) and x <= float(r["x1"]):
			return r
	return {}


## Where the roof you are on ends (the takeoff edge), or INF.
func edge_ahead(x: float) -> float:
	var b := building_at(x)
	return float(b["x1"]) if not b.is_empty() else INF


func checkpoint_before(x: float) -> float:
	var best := 80.0
	for c in checkpoints:
		if float(c) <= x:
			best = float(c)
	return best


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	for b in buildings:
		_draw_building(b)
	for r in ramps:
		_draw_ramp(r)


func _draw_building(b: Dictionary) -> void:
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var y: float = b["y"]
	var tint: Color = b["tint"]
	var w := x1 - x0
	var bottom := y + FACADE_H
	# Facade: dusk light from the left, darker toward the street.
	var top_c := tint.lightened(0.08)
	var low_c := tint.darkened(0.55)
	draw_polygon(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, bottom), Vector2(x0, bottom)]),
		PackedColorArray([top_c, top_c.darkened(0.12), low_c, low_c]))
	# Windows: a grid, some lit warm, a few cold TV-blue.
	var r := RandomNumberGenerator.new()
	r.seed = int(b["seed"])
	var cols := int(w / 26.0)
	var off := (w - float(cols) * 26.0) * 0.5 + 8.0
	for row in 18:
		var wy := y + 34.0 + float(row) * 34.0
		for c in cols:
			var wx := x0 + off + float(c) * 26.0
			var lit := r.randf()
			var col := Color(0.07, 0.07, 0.11)
			if lit < 0.14:
				col = Color(1.0, 0.78, 0.42).darkened(r.randf() * 0.25)
			elif lit < 0.18:
				col = Color(0.45, 0.7, 1.0).darkened(0.2)
			draw_rect(Rect2(wx, wy, 10, 15), col.darkened(clampf(float(row) / 22.0, 0.0, 0.6)))
	# Parapet: a lighter cap with a lit edge from the sunset side.
	draw_rect(Rect2(x0 - 3.0, y - 6.0, w + 6.0, 9.0), tint.lightened(0.28))
	draw_rect(Rect2(x0 - 3.0, y - 6.0, w + 6.0, 2.0), Color(1.0, 0.62, 0.38, 0.85))
	draw_rect(Rect2(x0 - 3.0, y + 3.0, w + 6.0, 3.0), Color(0, 0, 0, 0.35))
	# Rim light down the left edge, shadow down the right.
	draw_rect(Rect2(x0, y, 3.0, FACADE_H), Color(1.0, 0.55, 0.35, 0.35))
	draw_rect(Rect2(x1 - 6.0, y, 6.0, FACADE_H), Color(0, 0, 0, 0.3))
	# Gravel speckle along the roof line.
	for k in int(w / 12.0):
		draw_rect(Rect2(x0 + float(k) * 12.0 + r.randf() * 8.0, y - 7.0 - r.randf() * 2.0, 2, 1), tint.lightened(0.45))


func _draw_ramp(r: Dictionary) -> void:
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var y: float = r["y"]
	var pts := PackedVector2Array([Vector2(x0, y), Vector2(x1, y - 26.0), Vector2(x1, y)])
	draw_colored_polygon(pts, Color(0.42, 0.3, 0.2))
	draw_line(Vector2(x0, y), Vector2(x1, y - 26.0), Color(0.75, 0.58, 0.36), 3.0)
	draw_line(Vector2(x1 - 4.0, y - 24.0), Vector2(x1 - 4.0, y), Color(0.2, 0.14, 0.1), 3.0)


## A zipline mast on the last roof: touch it and you are gone.
class GoalMast extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-4, -170, 8, 170), Color(0.3, 0.32, 0.38))
		draw_rect(Rect2(-4, -170, 3, 170), Color(1.0, 0.62, 0.38, 0.6))
		draw_line(Vector2(0, -160), Vector2(900, 260), Color(0.15, 0.15, 0.18), 3.0)
		var a := 0.6 + 0.4 * sin(_t * 6.0)
		draw_circle(Vector2(0, -174), 7.0, Color(1.0, 0.3, 0.2, a))
		draw_colored_polygon(PackedVector2Array([Vector2(4, -166), Vector2(52, -150), Vector2(4, -134)]), Color(0.45, 1.0, 0.6))
