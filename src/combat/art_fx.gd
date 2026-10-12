class_name ArtFx
extends Node2D

## Drawn effects for the element arts, grabs and team attacks. Everything is
## code-drawn and additive so it glows over the night streets:
##   orb     the ball gathering between the hands (size driven from outside)
##   ring    a shockwave ellipse on the ground
##   pillar  a column of fire / stone out of the street
##   cone    a fan of flame from a palm strike
##   bolt    a jagged lightning line between two points
##   streak  an ice sheet left on the ground
##   burst   radial sparks on impact
##   cracks  broken asphalt glowing at the seams

var kind := "burst"
var col := Color.WHITE
var size := 40.0
var dir := 1
var life := 0.4
var t := 0.0
var a := Vector2.ZERO
var b := Vector2.ZERO
var hold := false
var _seed := 0
var _rays: Array = []


static func spawn(host: Node, at: Vector2, kind_: String, col_: Color, size_: float, life_: float, dir_ := 1) -> ArtFx:
	var fx := ArtFx.new()
	fx.kind = kind_
	fx.col = col_
	fx.size = size_
	fx.life = life_
	fx.dir = dir_
	fx.global_position = at
	if host != null:
		host.add_child(fx)
	return fx


static func bolt(host: Node, from: Vector2, to: Vector2, col_: Color, life_ := 0.28) -> ArtFx:
	var fx := spawn(host, from, "bolt", col_, 0.0, life_)
	fx.a = Vector2.ZERO
	fx.b = to - from
	return fx


func _ready() -> void:
	_seed = randi()
	z_index = 6 if kind != "streak" and kind != "cracks" and kind != "ring" else 1
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if kind != "cracks" else CanvasItemMaterial.BLEND_MODE_MIX
	material = m
	if kind == "burst" or kind == "cracks":
		for i in 12:
			_rays.append([randf() * TAU, randf_range(0.5, 1.0)])


func _process(delta: float) -> void:
	t += delta
	if not hold and t >= life:
		queue_free()
		return
	queue_redraw()


func _k() -> float:
	return clampf(t / maxf(0.001, life), 0.0, 1.0)


func _draw() -> void:
	var k := _k()
	var fade := 1.0 - k
	match kind:
		"orb":
			var r := size
			var flick := 1.0 + 0.12 * sin(t * 40.0)
			draw_circle(Vector2.ZERO, r * 2.4 * flick, Color(col.r, col.g, col.b, 0.12))
			draw_circle(Vector2.ZERO, r * 1.5 * flick, Color(col.r, col.g, col.b, 0.35))
			draw_circle(Vector2.ZERO, r * flick, col)
			draw_circle(Vector2.ZERO, r * 0.5, Color(1, 1, 0.95, 0.95))
			# Motes drawn in toward the hands.
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed
			for i in 10:
				var ang := rng.randf() * TAU + t * 3.0
				var ph := fmod(t * 2.2 + rng.randf(), 1.0)
				var d := lerpf(r * 5.0, r * 1.1, ph)
				var p := Vector2(cos(ang), sin(ang) * 0.8) * d
				draw_line(p, p * 0.85, Color(col.r, col.g, col.b, 0.8 * ph), 1.5)
		"ring":
			var r := lerpf(size * 0.15, size, sqrt(k))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.9 * fade), 6.0 * fade + 1.0)
			draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 48, Color(1, 1, 1, 0.5 * fade), 2.0)
			draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.12 * fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"pillar":
			var grow := minf(1.0, k * 5.0)
			var h := size * grow
			var w := 16.0 * (1.0 - 0.6 * k)
			for i in 4:
				var ww := w * (1.6 - 0.35 * float(i))
				var c := col.lerp(Color(1, 1, 0.8), 0.25 * float(i))
				c.a = (0.25 + 0.2 * float(i)) * fade
				draw_rect(Rect2(-ww, -h, ww * 2.0, h), c)
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed
			for i in 14:
				var ex := rng.randf_range(-w * 2.0, w * 2.0)
				var ey := -fmod(rng.randf() * h + t * 260.0, maxf(1.0, h + 30.0))
				draw_circle(Vector2(ex, ey), rng.randf_range(1.0, 2.5), Color(1, 0.9, 0.5, fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
			draw_circle(Vector2.ZERO, w * 3.0, Color(col.r, col.g, col.b, 0.4 * fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"cone":
			var reach := size * minf(1.0, k * 4.0)
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed + int(t * 30.0)
			for i in 9:
				var spread := rng.randf_range(-0.45, 0.45)
				var ln := reach * rng.randf_range(0.6, 1.0)
				var tip := Vector2(float(dir) * ln * cos(spread), ln * sin(spread) * 0.6)
				var side := Vector2(0, 6.0 + 4.0 * rng.randf())
				var c := col.lerp(Color(1, 0.95, 0.6), rng.randf() * 0.6)
				c.a = 0.55 * fade
				draw_colored_polygon(PackedVector2Array([-side, tip, side]), c)
			draw_circle(Vector2.ZERO, 12.0 * fade, Color(1, 1, 0.9, fade))
		"bolt":
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed + int(t * 40.0)
			var pts := PackedVector2Array()
			var n := 9
			for i in n + 1:
				var f := float(i) / float(n)
				var p := a.lerp(b, f)
				if i > 0 and i < n:
					p += Vector2(rng.randf_range(-6, 6), rng.randf_range(-9, 9))
				pts.append(p)
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.45 * fade), 7.0)
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.9 * fade), 3.0)
			draw_polyline(pts, Color(1, 1, 1, fade), 1.2)
		"streak":
			var c := Color(col.r, col.g, col.b, 0.45 * fade)
			draw_rect(Rect2(minf(0.0, size * float(dir)), -3.0, absf(size), 7.0), c)
			draw_rect(Rect2(minf(0.0, size * float(dir)), -2.0, absf(size), 1.5), Color(1, 1, 1, 0.6 * fade))
		"burst":
			for r: Array in _rays:
				var ang: float = r[0]
				var ln := size * float(r[1]) * (0.4 + k)
				var v := Vector2(cos(ang), sin(ang) * 0.7)
				draw_line(v * ln * 0.4, v * ln, Color(col.r, col.g, col.b, fade), 2.0)
			draw_circle(Vector2.ZERO, size * 0.4 * fade, Color(1, 1, 0.9, 0.8 * fade))
		"cracks":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
			for r: Array in _rays:
				var ang: float = r[0]
				var ln := size * float(r[1])
				var v := Vector2(cos(ang), sin(ang))
				var mid := v * ln * 0.5 + Vector2(-v.y, v.x) * 6.0
				draw_polyline(PackedVector2Array([Vector2.ZERO, mid, v * ln]), Color(0.05, 0.04, 0.04, 0.9 * fade), 3.0)
				draw_polyline(PackedVector2Array([Vector2.ZERO, mid, v * ln]), Color(col.r, col.g, col.b, 0.8 * fade), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
