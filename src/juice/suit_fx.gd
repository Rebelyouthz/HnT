class_name SuitFx
extends Node2D

## One-shot drawn effects for the suit perks: a ground shockwave ring
## (BAT DIVE), a web burst (WEB SLAM), a smoke bomb (NINJA), kick arcs
## (HUNDRED KICKS) and a dodge afterimage (SPIDER SENSE).

var mode := "ring"
var life := 0.4
var size := 80.0
var dir := 1.0
var tint := Color.WHITE
var _t := 0.0
var _seed := 0


static func spawn(at: Vector2, mode_: String, size_: float = 80.0, dir_: float = 1.0, tint_: Color = Color.WHITE) -> SuitFx:
	var fx := SuitFx.new()
	fx.mode = mode_
	fx.size = size_
	fx.dir = dir_
	fx.tint = tint_
	fx.life = {"ring": 0.42, "web": 0.55, "smoke": 0.9, "kicks": 0.16, "ghost": 0.3, "slash": 0.2}.get(mode_, 0.4)
	fx.global_position = at
	fx._seed = randi()
	var tree := Engine.get_main_loop() as SceneTree
	var host: Node = tree.get_first_node_in_group("dock_world") if tree else null
	if host == null and tree:
		host = tree.current_scene
	if host:
		host.add_child(fx)
	return fx


func _ready() -> void:
	z_index = 4 if mode != "smoke" else 6
	if mode == "ring" or mode == "web" or mode == "kicks" or mode == "slash":
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if mode != "web" else CanvasItemMaterial.BLEND_MODE_MIX
		cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = cm


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var f := clampf(_t / life, 0.0, 1.0)
	var eo := 1.0 - pow(1.0 - f, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	match mode:
		"ring":
			# Flat ellipse on the street plane, fast out, fading thin.
			var r := size * (0.25 + 0.95 * eo)
			var a := 1.0 - f
			_ellipse(r, r * 0.28, Color(tint.r, tint.g, tint.b, 0.75 * a), 6.0 * a + 1.0)
			_ellipse(r * 0.7, r * 0.2, Color(1, 1, 1, 0.5 * a), 3.0 * a + 1.0)
			for i in 10:
				var ang := rng.randf() * TAU
				var d := r * rng.randf_range(0.6, 1.05)
				var p := Vector2(cos(ang) * d, sin(ang) * d * 0.28)
				draw_line(p, p + Vector2(0, -rng.randf_range(6, 18) * a), Color(0.75, 0.7, 0.62, 0.8 * a), 2.0)
		"web":
			var r := size * (0.3 + 0.7 * eo)
			var a := 1.0 - f * f
			var col := Color(0.95, 0.96, 1.0, 0.75 * a)
			var spokes := 9
			var tips: Array[Vector2] = []
			for i in spokes:
				var ang := TAU * float(i) / float(spokes) + rng.randf_range(-0.12, 0.12)
				var tip := Vector2(cos(ang), sin(ang) * 0.75) * r * rng.randf_range(0.85, 1.1)
				tips.append(tip)
				draw_line(Vector2.ZERO, tip, col, 2.0)
			for ring in [0.35, 0.62, 0.9]:
				for i in spokes:
					var p1: Vector2 = tips[i] * ring
					var p2: Vector2 = tips[(i + 1) % spokes] * ring
					var mid := (p1 + p2) * 0.5 * 0.9
					draw_polyline(PackedVector2Array([p1, mid, p2]), col, 1.5)
		"smoke":
			for i in 9:
				var ang := rng.randf() * TAU
				var d := size * 0.55 * eo * rng.randf_range(0.3, 1.0)
				var p := Vector2(cos(ang) * d, sin(ang) * d * 0.5 - 20.0 * eo - rng.randf_range(0, 18))
				var rad := size * rng.randf_range(0.22, 0.38) * (0.6 + 0.6 * eo)
				var g := rng.randf_range(0.28, 0.42)
				draw_circle(p, rad, Color(g, g, g + 0.03, 0.75 * (1.0 - f)))
				draw_circle(p + Vector2(-rad * 0.25, -rad * 0.25), rad * 0.55, Color(g + 0.15, g + 0.15, g + 0.18, 0.5 * (1.0 - f)))
		"kicks", "slash":
			# A hot crescent swept in front: the trail of a foot.
			var a := 1.0 - f
			var pts := PackedVector2Array()
			var n := 10
			var r := size * (0.8 + 0.3 * eo)
			var tilt := rng.randf_range(-0.7, 0.5)
			for i in n + 1:
				var s := float(i) / float(n)
				var ang := lerpf(-1.1, 1.1, s) + tilt
				pts.append(Vector2(cos(ang) * r * dir, sin(ang) * r * 0.55))
			draw_polyline(pts, Color(tint.r, tint.g, tint.b, 0.8 * a), 4.0 * a + 1.0)
			draw_polyline(pts, Color(1, 1, 1, 0.9 * a), 2.0)
		"ghost":
			var a := 1.0 - f
			draw_rect(Rect2(Vector2(-size * 0.22, -size), Vector2(size * 0.44, size)), Color(tint.r, tint.g, tint.b, 0.35 * a))
			for i in 3:
				var y := -size * (0.25 + 0.25 * float(i))
				draw_line(Vector2(-size * 0.4 * dir, y), Vector2(-size * (0.9 + 0.4 * eo) * dir, y), Color(tint.r, tint.g, tint.b, 0.6 * a), 2.0)


func _ellipse(rx: float, ry: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var ang := TAU * float(i) / 32.0
		pts.append(Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_polyline(pts, col, w, true)
