class_name ElementShot
extends Node2D

## A thrown element art travelling down the lane at foot level, drawn at
## body height (h). Styles:
##   ball     fireball / phoenix (trail, light pool on the ground)
##   tornado  wind kick whirlwind (slow, juggles; evolved pulls in)
##   wave     thunder clap shockwave hugging the street
## Hits each thug once (tornado re-hits every 0.35 s), through ArtMoves.strike.

var by: Fighter
var style := "ball"
var elem := "fire"
var dir := 1
var speed := 520.0
var r := 10.0
var h := -36.0
var dmg := 20
var fx := "knockdown"
var pierce := false
var pull := false
var life := 1.2
var rehit := 0.0
var trail_fire := false
var _t := 0.0
var _hit := {}
var _trail: Array[Vector2] = []
var _fire_cd := 0.0


func _ready() -> void:
	z_index = 5
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	add_to_group("element_shots")


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life or by == null or not is_instance_valid(by):
		_pop()
		return
	_trail.push_front(global_position)
	if _trail.size() > 12:
		_trail.pop_back()
	global_position.x += float(dir) * speed * delta
	if trail_fire:
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd = 0.12
			FireFx.ground(get_parent(), global_position, 1.6)
	var now := _t
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var e: Punk = n
		if e.hp <= 0 or not is_instance_valid(e):
			continue
		var dx := absf(e.global_position.x - global_position.x)
		var dy := absf(e.global_position.y - global_position.y)
		if dx > r + 14.0 or dy > 26.0:
			if pull and dx < 110.0 and dy < 40.0:
				e.global_position.x = move_toward(e.global_position.x, global_position.x, 90.0 * delta)
			continue
		var id := e.get_instance_id()
		if _hit.has(id) and (rehit <= 0.0 or now - float(_hit[id]) < rehit):
			continue
		_hit[id] = now
		ArtMoves.strike(by, e, dmg, fx, elem)
		if not pierce:
			_pop()
			return
	queue_redraw()


func _pop() -> void:
	var host := get_parent()
	if host != null:
		ArtFx.spawn(host, global_position + Vector2(0, h), "burst", Elements.color(elem), r * 3.0, 0.3)
		ArtFx.spawn(host, global_position, "ring", Elements.color(elem), r * 5.0, 0.4)
	queue_free()


func _draw() -> void:
	var c := Elements.color(elem)
	# Light pool on the street under it.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, r * 3.2, Color(c.r, c.g, c.b, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	match style:
		"ball":
			for i in _trail.size():
				var p := _trail[i] - global_position + Vector2(0, h)
				var f := 1.0 - float(i) / float(_trail.size())
				draw_circle(p, r * (0.3 + 0.7 * f), Color(c.r, c.g, c.b, 0.35 * f))
			var o := Vector2(0, h)
			var flick := 1.0 + 0.1 * sin(_t * 50.0)
			draw_circle(o, r * 2.0 * flick, Color(c.r, c.g, c.b, 0.2))
			draw_circle(o, r * flick, c)
			draw_circle(o, r * 0.55, Color(1, 1, 0.9))
			if pierce and elem == "fire":
				# Phoenix wings.
				var wing := r * 2.4
				var flap := sin(_t * 18.0) * 0.5
				for s in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([o, o + Vector2(-float(dir) * wing * 0.8, s * wing * (0.6 + flap)), o + Vector2(-float(dir) * wing * 1.4, s * wing * 0.2)]), Color(c.r, c.g * 0.8, c.b, 0.55))
		"tornado":
			for i in 7:
				var y := -8.0 - float(i) * 10.0
				var w := 10.0 + float(i) * 5.0
				var spin := _t * 14.0 + float(i)
				draw_set_transform(Vector2(sin(spin) * 3.0, y), 0.0, Vector2(1.0, 0.28))
				draw_arc(Vector2.ZERO, w, spin, spin + PI * 1.4, 18, Color(c.r, c.g, c.b, 0.75), 3.0)
				draw_arc(Vector2.ZERO, w * 0.7, spin + PI, spin + PI * 2.2, 14, Color(1, 1, 1, 0.45), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"wave":
			var rng := RandomNumberGenerator.new()
			rng.seed = int(_t * 30.0)
			for i in 9:
				var x := (float(i) - 4.0) * r * 0.5
				var hh := (r * 2.4) * (1.0 - absf(float(i) - 4.0) / 5.0) * rng.randf_range(0.7, 1.1)
				draw_line(Vector2(x, 0), Vector2(x + float(dir) * 3.0, -hh), Color(c.r, c.g, c.b, 0.8), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, r * 2.0, -PI * 0.5 - float(dir) * 0.9, -PI * 0.5 + float(dir) * 0.9, 16, Color(1, 1, 1, 0.8), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
