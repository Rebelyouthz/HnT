class_name FieldLife
extends RefCounted

## Living things on the survivor field: fire barrels (flames, sparks, a
## flickering light), steam vents (breathing plumes), flooded puddles (rings
## and a glint), flickering tube lights, trees that sway, a fountain with
## falling water, a frozen lake with cracks and a sheen, black water channels
## with slow ripples. Built from code, particles and the prop art in
## assets/sprites/field/props/ (FLUX). Each returns its node.

const PROPS := "res://assets/sprites/field/props/%s.png"


static func prop(host: Node2D, at: Vector2, name: String, h: float, flip := false) -> Node2D:
	var n := Node2D.new()
	n.position = at
	host.add_child(n)
	var path := PROPS % name
	if not ResourceLoader.exists(path):
		return n
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var ang := TAU * float(i) / 16.0
		pts.append(Vector2(cos(ang) * h * 0.38, sin(ang) * h * 0.1))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.42)
	n.add_child(sh)
	var s := Sprite2D.new()
	s.texture = load(path)
	var k := h / float(s.texture.get_height())
	s.scale = Vector2(k * (-1.0 if flip else 1.0), k)
	s.offset = Vector2(0, -s.texture.get_height() * 0.5 + 6.0)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.name = "Art"
	n.add_child(s)
	return n


static func solid(n: Node2D, size: Vector2, off := Vector2.ZERO) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = off
	body.add_child(cs)
	n.add_child(body)


## A tree that sways in the wind (skewing the canopy, not the trunk).
static func tree(host: Node2D, at: Vector2, dead := false) -> Node2D:
	var n := prop(host, at, "dead_tree" if dead else "tree", randf_range(150.0, 190.0), randf() < 0.5)
	solid(n, Vector2(22, 12), Vector2(0, -4))
	var art := n.get_node_or_null("Art") as Sprite2D
	if art:
		var sw := Sway.new()
		sw.target = art
		sw.amp = 0.03 if not dead else 0.015
		n.add_child(sw)
	return n


class Sway extends Node:
	var target: Sprite2D
	var amp := 0.03
	var _t := randf() * 10.0

	func _process(d: float) -> void:
		_t += d
		if target:
			target.skew = amp * sin(_t * 1.3) + amp * 0.4 * sin(_t * 3.1)


## Burning oil drum: flames, sparks going up, smoke, a light that breathes.
static func fire_barrel(host: Node2D, at: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	host.add_child(n)
	SpriteBook.attach_living(n, "drum")
	solid(n, Vector2(26, 12), Vector2(0, -4))
	var fire := CPUParticles2D.new()
	fire.position = Vector2(0, -40)
	fire.amount = 26
	fire.lifetime = 0.55
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fire.emission_rect_extents = Vector2(9, 2)
	fire.direction = Vector2(0, -1)
	fire.spread = 12.0
	fire.gravity = Vector2(0, -60)
	fire.initial_velocity_min = 30.0
	fire.initial_velocity_max = 60.0
	fire.scale_amount_min = 3.0
	fire.scale_amount_max = 6.0
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	g.add_point(0.45, Color(1.0, 0.55, 0.1, 0.9))
	fire.color_ramp = g
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fire.material = mat
	n.add_child(fire)
	var sparks := CPUParticles2D.new()
	sparks.position = Vector2(0, -46)
	sparks.amount = 6
	sparks.lifetime = 1.4
	sparks.direction = Vector2(0, -1)
	sparks.spread = 30.0
	sparks.gravity = Vector2(10, -20)
	sparks.initial_velocity_min = 40.0
	sparks.initial_velocity_max = 90.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.6
	sparks.color = Color(1.0, 0.7, 0.3)
	sparks.material = mat
	n.add_child(sparks)
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(0, -60)
	smoke.amount = 8
	smoke.lifetime = 2.4
	smoke.direction = Vector2(0.2, -1)
	smoke.spread = 15.0
	smoke.gravity = Vector2(8, -10)
	smoke.initial_velocity_min = 14.0
	smoke.initial_velocity_max = 26.0
	smoke.scale_amount_min = 6.0
	smoke.scale_amount_max = 12.0
	var sg := Gradient.new()
	sg.set_color(0, Color(0.25, 0.25, 0.28, 0.35))
	sg.set_color(1, Color(0.2, 0.2, 0.22, 0.0))
	smoke.color_ramp = sg
	n.add_child(smoke)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 2.4
	l.color = Color(1.0, 0.6, 0.25)
	l.energy = 1.2
	l.position = Vector2(0, -36)
	n.add_child(l)
	var pool := Sprite2D.new()
	pool.texture = LightRig.radial_tex()
	pool.modulate = Color(1.0, 0.55, 0.2, 0.35)
	pool.scale = Vector2(1.8, 1.1) * (150.0 / float(pool.texture.get_width()))
	pool.z_index = -19
	pool.z_as_relative = false
	Blockout.add_glow(pool)
	n.add_child(pool)
	var fl := Flicker.new()
	fl.light = l
	fl.pool = pool
	n.add_child(fl)
	return n


class Flicker extends Node:
	var light: PointLight2D
	var pool: Sprite2D
	var base := 1.2
	var hard := false
	var _t := randf() * 5.0
	var _out := 0.0

	func _process(d: float) -> void:
		_t += d
		if light == null:
			return
		var e := base * (0.85 + 0.15 * sin(_t * 9.0) * sin(_t * 5.3))
		if hard:
			# A dying tube: mostly on, sometimes stutters out.
			if _out > 0.0:
				_out -= d
				e = base * 0.08
			elif randf() < d * 0.35:
				_out = randf_range(0.05, 0.4)
		light.energy = e
		if pool:
			pool.modulate.a = 0.12 + 0.25 * e / base


## Steam out of a grate: a slow white plume that pulses.
static func steam(host: Node2D, at: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	host.add_child(n)
	SpriteBook.attach_living(n, "manhole")
	var p := CPUParticles2D.new()
	p.position = Vector2(0, -6)
	p.amount = 18
	p.lifetime = 2.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.direction = Vector2(0.15, -1)
	p.spread = 18.0
	p.gravity = Vector2(6, -14)
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 32.0
	p.scale_amount_min = 8.0
	p.scale_amount_max = 16.0
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.88, 0.92, 0.32))
	g.set_color(1, Color(0.8, 0.82, 0.88, 0.0))
	p.color_ramp = g
	n.add_child(p)
	return n


## Flooded patch: dark water with a sheen, rain rings popping on it.
static func puddle(host: Node2D, at: Vector2, size: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	n.z_index = -18
	n.z_as_relative = false
	host.add_child(n)
	var w := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 28:
		var ang := TAU * float(i) / 28.0
		var r := 1.0 + 0.12 * sin(ang * 3.0 + at.x) + 0.08 * sin(ang * 5.0 + at.y)
		pts.append(Vector2(cos(ang) * size.x, sin(ang) * size.y) * r)
	w.polygon = pts
	w.color = Color(0.05, 0.08, 0.12, 0.72)
	n.add_child(w)
	var sheen := Sprite2D.new()
	sheen.texture = LightRig.radial_tex()
	sheen.modulate = Color(0.55, 0.7, 0.95, 0.18)
	sheen.scale = Vector2(size.x * 1.4, size.y * 1.2) / float(sheen.texture.get_width()) * 2.0
	sheen.position = Vector2(-size.x * 0.2, -size.y * 0.25)
	Blockout.add_glow(sheen)
	n.add_child(sheen)
	var rings := Rings.new()
	rings.size = size
	n.add_child(rings)
	return n


class Rings extends Node2D:
	var size := Vector2(60, 24)
	var _r: Array = []
	var _t := 0.0

	func _process(d: float) -> void:
		_t -= d
		if _t <= 0.0:
			_t = randf_range(0.15, 0.5)
			_r.append([Vector2(randf_range(-0.8, 0.8) * size.x, randf_range(-0.7, 0.7) * size.y), 0.0])
		for e in _r:
			e[1] = float(e[1]) + d
		_r = _r.filter(func(e: Array) -> bool: return float(e[1]) < 0.7)
		queue_redraw()

	func _draw() -> void:
		for e in _r:
			var k := float(e[1]) / 0.7
			draw_set_transform(e[0], 0.0, Vector2(1.0, 0.4))
			draw_arc(Vector2.ZERO, 2.0 + 10.0 * k, 0.0, TAU, 16, Color(0.7, 0.8, 1.0, 0.5 * (1.0 - k)), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A frozen pond: pale ice, cracks, a moving sheen, a snow rim. Slippery
## (Fighter reads the "ice" group).
static func ice(host: Node2D, at: Vector2, size: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	n.z_index = -18
	n.z_as_relative = false
	n.add_to_group("ice")
	n.set_meta("size", size)
	host.add_child(n)
	var rim := Polygon2D.new()
	var ice_p := Polygon2D.new()
	var a := PackedVector2Array()
	var b := PackedVector2Array()
	for i in 36:
		var ang := TAU * float(i) / 36.0
		var r := 1.0 + 0.08 * sin(ang * 4.0 + 1.3) + 0.05 * sin(ang * 7.0)
		a.append(Vector2(cos(ang) * size.x, sin(ang) * size.y) * r * 1.08)
		b.append(Vector2(cos(ang) * size.x, sin(ang) * size.y) * r)
	rim.polygon = a
	rim.color = Color(0.58, 0.62, 0.72, 0.85)
	ice_p.polygon = b
	ice_p.color = Color(0.32, 0.44, 0.56, 0.85)
	n.add_child(rim)
	n.add_child(ice_p)
	var cr := Cracks.new()
	cr.size = size
	n.add_child(cr)
	var sheen := Sprite2D.new()
	sheen.texture = LightRig.radial_tex()
	sheen.modulate = Color(0.9, 0.95, 1.0, 0.25)
	sheen.scale = Vector2(size.x * 0.8, size.y * 0.5) / float(sheen.texture.get_width()) * 2.0
	Blockout.add_glow(sheen)
	n.add_child(sheen)
	var tw := sheen.create_tween().set_loops()
	tw.tween_property(sheen, "position:x", size.x * 0.5, 4.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sheen, "position:x", -size.x * 0.5, 4.0).set_trans(Tween.TRANS_SINE)
	return n


class Cracks extends Node2D:
	var size := Vector2(200, 100)

	func _ready() -> void:
		seed(int(size.x * 7.0))

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(size.x * 13.0 + size.y)
		for k in 9:
			var p := Vector2(rng.randf_range(-0.6, 0.6) * size.x, rng.randf_range(-0.6, 0.6) * size.y)
			for j in 5:
				var q := p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, 34.0) * Vector2(1.0, 0.5)
				draw_line(p, q, Color(0.8, 0.88, 0.95, 0.45), 1.0)
				p = q


## Black water across the dock: not walkable, slow ripples, a light glint.
static func water(host: Node2D, rect: Rect2) -> Node2D:
	var n := Node2D.new()
	n.position = rect.position
	n.z_index = -18
	n.z_as_relative = false
	host.add_child(n)
	var w := ColorRect.new()
	w.size = rect.size
	w.color = Color(0.02, 0.05, 0.08, 0.95)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(w)
	var rp := Ripples.new()
	rp.size = rect.size
	n.add_child(rp)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size - Vector2(0, 16)
	cs.shape = r
	cs.position = rect.size * 0.5
	body.add_child(cs)
	n.add_child(body)
	return n


class Ripples extends Node2D:
	var size := Vector2(400, 80)
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var rows := int(size.y / 14.0)
		for i in rows:
			var y := 7.0 + float(i) * 14.0
			var off := fmod(_t * (14.0 + float(i % 3) * 6.0) + float(i) * 37.0, 60.0)
			var x := -60.0 + off
			while x < size.x:
				draw_line(Vector2(x, y), Vector2(x + 18.0, y), Color(0.4, 0.55, 0.75, 0.25), 1.0)
				x += 60.0


## A round fountain: basin water, a spout of particles, splash rings.
static func fountain(host: Node2D, at: Vector2) -> Node2D:
	var n := prop(host, at, "fountain", 150.0)
	solid(n, Vector2(120, 34), Vector2(0, -10))
	var p := CPUParticles2D.new()
	p.position = Vector2(0, -76)
	p.amount = 40
	p.lifetime = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 22.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 130.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5
	p.color = Color(0.7, 0.85, 1.0, 0.75)
	n.add_child(p)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 1.6
	l.color = Color(0.5, 0.75, 1.0)
	l.energy = 0.7
	l.position = Vector2(0, -40)
	n.add_child(l)
	return n


## A tube light on a pole that stutters (waiting room, dock).
static func tube(host: Node2D, at: Vector2, col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = at
	host.add_child(n)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 2.8
	l.color = col
	l.energy = 1.0
	l.position = Vector2(0, -30)
	n.add_child(l)
	var pool := Sprite2D.new()
	pool.texture = LightRig.radial_tex()
	pool.modulate = Color(col.r, col.g, col.b, 0.3)
	pool.scale = Vector2(2.4, 1.4) * (150.0 / float(pool.texture.get_width()))
	pool.z_index = -19
	pool.z_as_relative = false
	Blockout.add_glow(pool)
	n.add_child(pool)
	var fl := Flicker.new()
	fl.light = l
	fl.pool = pool
	fl.base = 1.0
	fl.hard = true
	n.add_child(fl)
	return n
