class_name SurviveField
extends RefCounted

## The survivor hours are TOP-DOWN (Halls of Torment / Vampire Survivors):
## a wide open arena seen from above at an angle instead of the story's side
## street. Every survive map gets its own painted ground (seamless tile from
## assets/sprites/field/<theme>.png), its own scatter of breakables, cars and
## lamps, dark fog at the edges and walls you cannot leave through. Actors
## walk eight ways and are depth-sorted by their feet (RunAct.y_sort).

const W := 2600.0
const H := 1700.0
## Walkable inset from the edges.
const EDGE := 70.0
## Field camera: wider than the street's 1.5x so the horde reads.
const ZOOM := 1.05

const THEMES := {
	"intake_lot": {"weather": "rain", "tile": "lot", "k": 0.2, "night": Color(0.42, 0.46, 0.6), "lamp": Color(1.0, 0.78, 0.45),
		"props": ["dumpster", "barrel", "hydrant", "manhole", "news", "fridge", "booth"], "cars": ["hatchback", "cop_car", "sedan", "van"], "decor": ["cone", "barrier", "drum", "crate", "cart"]},
	"group_circle": {"weather": "leaves", "tile": "circle", "k": 0.16, "night": Color(0.4, 0.46, 0.5), "lamp": Color(0.95, 0.85, 0.55),
		"props": ["kiosk", "barrel", "mail", "manhole", "news", "booth"], "cars": ["sedan"], "decor": ["bench", "bench", "fence", "crate", "cone"]},
	"waiting_room": {"weather": "dust", "tile": "clinic", "k": 0.14, "night": Color(0.42, 0.48, 0.48), "lamp": Color(0.75, 1.0, 0.9),
		"props": ["vending", "fridge", "booth", "barrel", "mail"], "cars": [], "decor": ["bench", "bench", "bench", "crate", "cart"]},
	"sleet_hour": {"weather": "snow", "tile": "sleet", "k": 0.22, "night": Color(0.48, 0.52, 0.66), "lamp": Color(0.8, 0.88, 1.0),
		"props": ["booth", "barrel", "mail", "manhole", "fridge", "news"], "cars": ["hatchback", "cop_car", "sedan"], "decor": ["barrier", "cone", "fence", "drum"]},
	"ledger_dive": {"weather": "drizzle", "tile": "dock", "k": 0.18, "night": Color(0.36, 0.44, 0.56), "lamp": Color(1.0, 0.7, 0.4),
		"props": ["fridge", "vending", "barrel", "kiosk", "mail"], "cars": ["van"], "decor": ["crate", "crate", "drum", "barrier"]},
}


static func theme(map_id: String) -> Dictionary:
	return THEMES.get(map_id, THEMES["intake_lot"])


static func rect() -> Rect2:
	return Rect2(0, 0, W, H)


static func center() -> Vector2:
	return Vector2(W, H) * 0.5


## Turn an act into the top-down field. Called by RunAct before the party.
static func setup(act: RunAct) -> void:
	Fighter.FIELD = true
	Fighter.STREET_MIN = EDGE + 30.0
	Fighter.STREET_MAX = H - EDGE
	act.map_w = W
	act.spawn_at = center()
	act.y_sort_enabled = true


static func build(act: RunAct, map_id: String) -> void:
	_blocks.clear()
	var th := theme(map_id)
	_ground(act, str(th["tile"]), float(th.get("k", 0.2)))
	_walls(act)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_id + "_field")
	var taken: Array[Vector2] = [center()]
	# Each hour has its own shape first (landmarks), then the scatter.
	var lamps := _landmarks(act, map_id, rng, taken)
	# Breakables in loose clusters: cover and loot to dodge round.
	var kinds: Array = th["props"]
	for i in 34:
		var p := _free_spot(rng, taken, 120.0)
		if p == Vector2.INF:
			continue
		taken.append(p)
		var sp := SmashProp.place(act, p, str(kinds[rng.randi() % kinds.size()]))
		sp.z_index = 0
		if i == 0:
			sp.set_meta("syringe", true)
	# Parked cars: big solid blockers that break up the open floor.
	var cars: Array = th["cars"]
	if not cars.is_empty():
		for i in 6:
			var p := _free_spot(rng, taken, 220.0)
			if p == Vector2.INF:
				continue
			taken.append(p)
			_car(act, p, str(cars[rng.randi() % cars.size()]))
	# Scenery that does not break: cones, benches, fences, drums.
	var decor: Array = th.get("decor", [])
	for i in 40:
		if decor.is_empty():
			break
		var p := _free_spot(rng, taken, 70.0)
		if p == Vector2.INF:
			continue
		taken.append(p)
		_decor(act, p, str(decor[rng.randi() % decor.size()]), rng)
	# Lamps on a loose grid: pools of light, the rest falls off into fog.
	var lamp_col: Color = th["lamp"]
	if lamps:
		for gx in 5:
			for gy in 3:
				var p := Vector2((float(gx) + 0.5) * W / 5.0 + rng.randf_range(-120, 120), (float(gy) + 0.5) * H / 3.0 + rng.randf_range(-90, 90))
				_lamp(act, p, lamp_col)
	_fog(act)
	_weather(act, str(th.get("weather", "")))


## The hour's own layout. Returns false when it brings its own lights (no
## street lamps then).
static func _landmarks(act: Node2D, map_id: String, rng: RandomNumberGenerator, taken: Array[Vector2]) -> bool:
	var c := center()
	match map_id:
		"intake_lot":
			# THE FLOODED LOT: two rows of parked cars like real stalls, big
			# flooded patches between, burning drums where people warmed up.
			for row in [380.0, 1300.0]:
				var x := 260.0
				while x < W - 260.0:
					if rng.randf() < 0.72:
						_car(act, Vector2(x, row), ["hatchback", "sedan", "cop_car", "van"][rng.randi() % 4])
						taken.append(Vector2(x, row))
					x += 190.0
			for i in 7:
				var p := Vector2(rng.randf_range(300, W - 300), rng.randf_range(560, 1120))
				FieldLife.puddle(act, p, Vector2(rng.randf_range(60, 140), rng.randf_range(22, 50)))
			for p in [Vector2(520, 840), Vector2(2080, 720), Vector2(1300, 560), Vector2(900, 1180), Vector2(1800, 1150)]:
				FieldLife.fire_barrel(act, p)
				taken.append(p)
			for p in [Vector2(700, 640), Vector2(1900, 980), Vector2(1450, 1180)]:
				FieldLife.steam(act, p)
			for i in 8:
				var p := Vector2(rng.randf_range(100, W - 100), [150.0, H - 110.0][i % 2])
				FieldLife.tree(act, p, true)
			for i in 5:
				var p := _free_spot(rng, taken, 180.0)
				if p != Vector2.INF:
					FieldLife.prop(act, p, "cart_lot", 46.0, rng.randf() < 0.5)
					taken.append(p)
			return true
		"group_circle":
			# GROUP CIRCLE: a fountain at the top of the plaza, a ring of trees
			# and benches round it, planters, a couple of warming drums.
			var fc := c + Vector2(0, -300)
			FieldLife.fountain(act, fc)
			taken.append(fc)
			for i in 12:
				var a := TAU * float(i) / 12.0
				var p := c + Vector2(cos(a) * 720.0, sin(a) * 470.0)
				FieldLife.tree(act, p)
				taken.append(p)
			for i in 8:
				var a := TAU * (float(i) + 0.5) / 8.0
				var p := c + Vector2(cos(a) * 430.0, sin(a) * 280.0)
				_decor(act, p, "bench", rng)
				taken.append(p)
			for i in 6:
				var p := _free_spot(rng, taken, 220.0)
				if p != Vector2.INF:
					FieldLife.solid(FieldLife.prop(act, p, "planter", 70.0), Vector2(60, 14), Vector2(0, -6))
					taken.append(p)
			for p in [c + Vector2(-900, 420), c + Vector2(880, 380), c + Vector2(0, 560)]:
				FieldLife.fire_barrel(act, p)
				taken.append(p)
			for i in 3:
				FieldLife.puddle(act, Vector2(rng.randf_range(300, W - 300), rng.randf_range(300, H - 300)), Vector2(70, 26))
			return true
		"waiting_room":
			# THE WAITING ROOM: blocks of chair rows, the reception desk on
			# top, tube lights that stutter. No street lamps indoors.
			var desk := Vector2(c.x, 300)
			FieldLife.solid(FieldLife.prop(act, desk, "desk", 120.0), Vector2(230, 30), Vector2(0, -10))
			taken.append(desk)
			for bx in [-760.0, -380.0, 380.0, 760.0]:
				for by in [-260.0, 0.0, 260.0, 520.0]:
					var p := c + Vector2(bx, by)
					var n := FieldLife.prop(act, p, "chairs", 72.0)
					n.modulate = Color(0.62, 0.68, 0.78)
					FieldLife.solid(n, Vector2(120, 16), Vector2(0, -6))
					taken.append(p)
			for gx in 6:
				for gy in 4:
					FieldLife.tube(act, Vector2((float(gx) + 0.5) * W / 6.0, (float(gy) + 0.5) * H / 4.0), Color(0.78, 1.0, 0.92))
			return false
		"sleet_hour":
			# THE SLEET HOUR: a frozen pond you slide on, snow heaps, people's
			# fire drums, bare trees.
			var lake := c + Vector2(-560, 120)
			FieldLife.ice(act, lake, Vector2(380, 210))
			taken.append(lake)
			taken.append(lake + Vector2(-220, 0))
			taken.append(lake + Vector2(220, 0))
			for i in 14:
				var p := _free_spot(rng, taken, 160.0)
				if p != Vector2.INF:
					FieldLife.solid(FieldLife.prop(act, p, "snow_pile", rng.randf_range(50.0, 80.0), rng.randf() < 0.5), Vector2(60, 14), Vector2(0, -4))
					taken.append(p)
			for p in [lake + Vector2(460, -150), lake + Vector2(470, 200), c + Vector2(700, -300), c + Vector2(820, 420), c + Vector2(200, 560), c + Vector2(-200, -540)]:
				FieldLife.fire_barrel(act, p)
				taken.append(p)
			for i in 10:
				var p := Vector2(rng.randf_range(100, W - 100), [150.0, H - 110.0][i % 2])
				FieldLife.tree(act, p, true)
			for p in [Vector2(1500, 700), Vector2(2000, 1200)]:
				FieldLife.steam(act, p)
			return true
		"ledger_dive":
			# LEDGER DIVE: black water channels across the dock with plank
			# crossings, bollards on the edges, pallet stacks, tube lights.
			for wy in [520.0, 1150.0]:
				var gaps: Array = [rng.randf_range(400, 800), rng.randf_range(1200, 1500), rng.randf_range(1900, 2300)]
				var x := EDGE
				for g: float in gaps:
					if g - 70.0 > x:
						FieldLife.water(act, Rect2(x, wy - 45.0, g - 70.0 - x, 90.0))
						_block(Rect2(x, wy - 45.0, g - 70.0 - x, 90.0))
					x = g + 70.0
				FieldLife.water(act, Rect2(x, wy - 45.0, W - EDGE - x, 90.0))
				_block(Rect2(x, wy - 45.0, W - EDGE - x, 90.0))
				var bx := 200.0
				while bx < W - 200.0:
					if not gaps.any(func(g: float) -> bool: return absf(g - bx) < 110.0):
						FieldLife.solid(FieldLife.prop(act, Vector2(bx, wy - 54.0), "bollard", 44.0), Vector2(20, 10), Vector2(0, -4))
					bx += 260.0
				for gx in [200.0, 600.0, 1000.0, 1400.0, 1800.0, 2200.0]:
					taken.append(Vector2(gx, wy))
			for i in 9:
				var p := _free_spot(rng, taken, 200.0)
				if p != Vector2.INF and not _blocked(p, 70.0):
					FieldLife.solid(FieldLife.prop(act, p, "pallets", 80.0, rng.randf() < 0.5), Vector2(64, 18), Vector2(0, -6))
					taken.append(p)
			for gx in 5:
				for gy in [0.0, 1.0, 2.0]:
					FieldLife.tube(act, Vector2((float(gx) + 0.5) * W / 5.0, [280.0, 840.0, 1450.0][int(gy)]), Color(1.0, 0.72, 0.45))
			for i in 4:
				FieldLife.puddle(act, Vector2(rng.randf_range(300, W - 300), rng.randf_range(650, 1000)), Vector2(70, 24))
			return false
	return true


## Spots that are not floor (water): spawns and props keep out.
static var _blocks: Array[Rect2] = []


static func _block(r: Rect2) -> void:
	_blocks.append(r)


static func _blocked(p: Vector2, pad := 0.0) -> bool:
	for r in _blocks:
		if r.grow(pad).has_point(p):
			return true
	return false


static func _free_spot(rng: RandomNumberGenerator, taken: Array[Vector2], gap: float) -> Vector2:
	for attempt in 30:
		var p := Vector2(rng.randf_range(EDGE + 120.0, W - EDGE - 120.0), rng.randf_range(EDGE + 140.0, H - EDGE - 60.0))
		var ok := not _blocked(p, 60.0)
		for t in taken:
			if t.distance_to(p) < gap or (t == center() and t.distance_to(p) < 320.0):
				ok = false
				break
		if ok:
			return p
	return Vector2.INF


## One seamless tile, repeated over the whole arena (4 texels a unit).
static func _ground(act: Node2D, tile: String, k: float) -> void:
	var path := "res://assets/sprites/field/%s.png" % tile
	var g := Sprite2D.new()
	g.name = "FieldGround"
	g.centered = false
	g.z_index = -20
	g.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists(path):
		g.texture = load(path)
	else:
		var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
		img.fill(Color(0.16, 0.17, 0.2))
		g.texture = ImageTexture.create_from_image(img)
	g.scale = Vector2(k, k)
	g.region_enabled = true
	# A margin past the walls so the frame never shows black.
	g.position = Vector2(-400, -400)
	g.region_rect = Rect2(0, 0, (W + 800.0) / k, (H + 800.0) / k)
	act.add_child(g)
	act.move_child(g, 0)


static func _walls(act: Node2D) -> void:
	for r in [Rect2(-200, -200, W + 400, 200 + EDGE), Rect2(-200, H - 10.0, W + 400, 220),
			Rect2(-200, -200, 200 + EDGE, H + 400), Rect2(W - EDGE, -200, 200 + EDGE, H + 400)]:
		var b := Blockout.solid(act, r, false)
		b.collision_layer = 1


static func _car(act: Node2D, at: Vector2, who: String) -> void:
	var n := Node2D.new()
	n.position = at
	n.add_to_group("slam_props")
	n.add_to_group("parked_cars")
	n.set_meta("half_w", 70.0)
	n.set_meta("w", 140.0)
	act.add_child(n)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(130, 26)
	cs.shape = r
	cs.position = Vector2(0, -12)
	body.add_child(cs)
	n.add_child(body)
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var ang := TAU * float(i) / 20.0
		pts.append(Vector2(cos(ang) * 74.0, sin(ang) * 14.0))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.45)
	n.add_child(sh)
	if SpriteBook.has_who(who):
		var a := SpriteBook.make_anim(who)
		var fr := a.sprite_frames.get_frame_texture("idle", 0) if a.sprite_frames.has_animation("idle") else null
		var tex_w := 207.0
		var cell_h := 216.0
		if fr is AtlasTexture:
			tex_w = (fr as AtlasTexture).region.size.x
			cell_h = float(fr.get_height())
		var k := 150.0 / tex_w
		a.scale = Vector2(k, k)
		a.position = Vector2(0, 2.0 * k - cell_h * k * 0.5)
		n.add_child(a)


static func _decor(act: Node2D, at: Vector2, who: String, rng: RandomNumberGenerator) -> void:
	var n := Node2D.new()
	n.position = at
	act.add_child(n)
	if not SpriteBook.attach_living(n, who):
		n.queue_free()
		return
	if rng.randf() < 0.5:
		n.scale.x = -1.0
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var ang := TAU * float(i) / 16.0
		pts.append(Vector2(cos(ang) * 22.0, sin(ang) * 6.0))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.4)
	n.add_child(sh)
	n.move_child(sh, 0)
	if who in ["fence", "barrier", "bench", "drum", "crate"]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(44 if who != "fence" else 70, 14)
		cs.shape = r
		cs.position = Vector2(0, -6)
		body.add_child(cs)
		n.add_child(body)


## A street lamp: the post, a pool of light on the ground and a real light.
static func _lamp(act: Node2D, at: Vector2, col: Color) -> void:
	var n := Node2D.new()
	n.position = at
	act.add_child(n)
	var pool := Sprite2D.new()
	pool.texture = LightRig.radial_tex()
	pool.modulate = Color(col.r, col.g, col.b, 0.32)
	pool.scale = Vector2(2.6, 1.6) * (150.0 / float(pool.texture.get_width()))
	pool.z_index = -19
	pool.z_as_relative = false
	Blockout.add_glow(pool)
	n.add_child(pool)
	if not SpriteBook.attach_living(n, "sodium_lamp" if SpriteBook.has_who("sodium_lamp") else "lamp"):
		var post := Line2D.new()
		post.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -96), Vector2(14, -104)])
		post.width = 4.0
		post.default_color = Color(0.12, 0.13, 0.16)
		n.add_child(post)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 3.0
	l.color = col
	l.energy = 1.15
	l.position = Vector2(16, -40)
	n.add_child(l)


## Weather over the frame (it follows the camera): rain on the car park,
## snow in the sleet hour, drizzle on the dock, leaves in the courtyard,
## dust in the clinic light.
static func _weather(act: Node2D, kind: String) -> void:
	if kind == "":
		return
	var w := Weather.new()
	w.kind = kind
	act.add_child(w)
	if kind in ["rain", "drizzle"]:
		NightStreet.rain_bed(act)


class Weather extends Node2D:
	var kind := "rain"

	func _ready() -> void:
		z_index = 25
		var p := GPUParticles2D.new()
		var m := ParticleProcessMaterial.new()
		m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		m.emission_box_extents = Vector3(380, 230, 1)
		match kind:
			"rain", "drizzle":
				m.direction = Vector3(0.18, 1, 0)
				m.spread = 3.0
				m.gravity = Vector3(0, 0, 0)
				m.initial_velocity_min = 260.0
				m.initial_velocity_max = 340.0
				m.scale_min = 1.0
				m.scale_max = 1.6
				m.color = Color(0.62, 0.7, 0.85, 0.45 if kind == "rain" else 0.28)
				p.amount = 260 if kind == "rain" else 120
				p.lifetime = 0.22
			"snow":
				m.direction = Vector3(0.3, 1, 0)
				m.spread = 25.0
				m.gravity = Vector3(0, 6, 0)
				m.initial_velocity_min = 18.0
				m.initial_velocity_max = 42.0
				m.scale_min = 1.5
				m.scale_max = 3.0
				m.color = Color(0.95, 0.97, 1.0, 0.75)
				p.amount = 220
				p.lifetime = 4.0
			"leaves":
				m.direction = Vector3(1, 0.4, 0)
				m.spread = 40.0
				m.gravity = Vector3(0, 4, 0)
				m.initial_velocity_min = 14.0
				m.initial_velocity_max = 30.0
				m.angular_velocity_min = -90.0
				m.angular_velocity_max = 90.0
				m.scale_min = 2.0
				m.scale_max = 3.5
				m.color = Color(0.7, 0.5, 0.22, 0.7)
				p.amount = 40
				p.lifetime = 5.0
			"dust":
				m.direction = Vector3(0.2, -0.2, 0)
				m.spread = 180.0
				m.gravity = Vector3(0, 0, 0)
				m.initial_velocity_min = 3.0
				m.initial_velocity_max = 9.0
				m.scale_min = 1.0
				m.scale_max = 2.0
				m.color = Color(0.9, 0.95, 0.85, 0.35)
				p.amount = 70
				p.lifetime = 6.0
		p.process_material = m
		p.local_coords = false
		p.preprocess = 3.0
		add_child(p)

	func _process(_d: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam:
			global_position = cam.get_screen_center_position()


## Darkness thickening toward the walls: the arena feels bigger than it is.
static func _fog(act: Node2D) -> void:
	var f := Node2D.new()
	f.z_index = 30
	f.add_to_group("field_fog")
	act.add_child(f)
	var depth := 260.0
	var c0 := Color(0.0, 0.0, 0.02, 0.92)
	var c1 := Color(0.0, 0.0, 0.02, 0.0)
	for side in 4:
		var poly := Polygon2D.new()
		var a: PackedVector2Array
		match side:
			0:
				a = PackedVector2Array([Vector2(-400, -400), Vector2(W + 400, -400), Vector2(W + 400, depth), Vector2(-400, depth)])
				poly.vertex_colors = PackedColorArray([c0, c0, c1, c1])
			1:
				a = PackedVector2Array([Vector2(-400, H - depth * 0.6), Vector2(W + 400, H - depth * 0.6), Vector2(W + 400, H + 400), Vector2(-400, H + 400)])
				poly.vertex_colors = PackedColorArray([c1, c1, c0, c0])
			2:
				a = PackedVector2Array([Vector2(-400, -400), Vector2(depth, -400), Vector2(depth, H + 400), Vector2(-400, H + 400)])
				poly.vertex_colors = PackedColorArray([c0, c1, c1, c0])
			3:
				a = PackedVector2Array([Vector2(W - depth, -400), Vector2(W + 400, -400), Vector2(W + 400, H + 400), Vector2(W - depth, H + 400)])
				poly.vertex_colors = PackedColorArray([c1, c0, c0, c1])
		poly.polygon = a
		f.add_child(poly)


## Where a new thug comes from: just off screen, all round the heroes, never
## outside the walls.
static func ring_point(tree: SceneTree) -> Vector2:
	var cam := tree.root.get_viewport().get_camera_2d() if tree else null
	var mid := cam.get_screen_center_position() if cam else center()
	var half := Vector2(640, 360) * 0.5 / (cam.zoom.x if cam else 1.0)
	var r := half.length() + 50.0
	for attempt in 8:
		var p := mid + Vector2.from_angle(randf() * TAU) * r * Vector2(1.0, 0.75)
		if p.x > EDGE + 20.0 and p.x < W - EDGE - 20.0 and p.y > EDGE + 40.0 and p.y < H - EDGE - 10.0 and not _blocked(p, 30.0):
			return p
	# Squeezed into a corner: come in from the far side of the frame.
	return Vector2(clampf(mid.x + (r if mid.x < W * 0.5 else -r), EDGE + 40.0, W - EDGE - 40.0), clampf(mid.y + randf_range(-half.y, half.y), EDGE + 60.0, H - EDGE - 20.0))
