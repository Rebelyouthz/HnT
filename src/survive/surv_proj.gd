class_name SurvProj
extends Node2D

## Everything the survive abilities throw or leave behind, drawn in code at
## the street's pixel scale: invoices (spinning paper), staples, hold-music
## notes, coffee puddles, lightning, shockwave rings, magnet mines, the
## photo flash. Damage goes through Punk.take_hit("skill", self) with
## skill_dmg filled from SurviveRun.hit().

var kind := "invoice"
var ability := ""
var vel := Vector2.ZERO
var pierce := 1
var life := 2.0
var radius := 30.0
var skill_dmg := 6
var _t := 0.0
var _hits: Dictionary = {}
var _tick := 0.0
static var _leech := 0
var owner_f: Node2D
var target := Vector2.ZERO
var start := Vector2.ZERO
var _slammed := false


static func shoot(host: Node, k: String, ab: String, at: Vector2, v: Vector2, pierce_n: int, owner_f: Node2D = null) -> void:
	var p := SurvProj.new()
	p.kind = k
	p.ability = ab
	p.vel = v
	p.pierce = pierce_n
	p.life = 1.6 if k != "note" else 2.2
	if k == "cart":
		p.life = 3.0
	if k == "badge":
		p.life = 1.4
	if k == "blade":
		var run := SurviveRun.get_run(host.get_tree())
		p.life = float(run.row("abilities", ab).get("life", 4.0)) if run else 4.0
	p.owner_f = owner_f
	p.global_position = at
	host.add_child(p)


## A melee swing drawn as a fading arc (damage is dealt by the caller).
static func swipe(host: Node, at: Vector2, ang: float, r: float) -> void:
	var p := SurvProj.new()
	p.kind = "swipe"
	p.vel = Vector2.from_angle(ang)
	p.radius = r
	p.life = 0.2
	p.global_position = at
	host.add_child(p)


## A straight fax beam from `at` along `v` (already damaged by the caller).
static func beam(host: Node, ab: String, at: Vector2, v: Vector2) -> void:
	var p := SurvProj.new()
	p.kind = "beam"
	p.ability = ab
	p.vel = v
	p.life = 0.3
	p.global_position = at
	host.add_child(p)


## A giant DENIED stamp: a shadow grows on the spot, then it slams.
static func stamp(host: Node, ab: String, at: Vector2, r: float) -> void:
	var p := SurvProj.new()
	p.kind = "stamp"
	p.ability = ab
	p.radius = r
	p.life = 0.75
	p.global_position = at
	host.add_child(p)


## A paperweight lobbed in an arc that shatters where it lands.
static func lob(host: Node, ab: String, from: Vector2, to: Vector2, r: float) -> void:
	var p := SurvProj.new()
	p.kind = "weight"
	p.ability = ab
	p.radius = r
	p.life = 0.55
	p.target = to
	p.start = from
	p.global_position = from
	host.add_child(p)


## A parcel that goes off almost at once where it lands.
static func bomb(host: Node, ab: String, at: Vector2, r: float) -> void:
	var p := SurvProj.new()
	p.kind = "mine"
	p.ability = ab
	p.radius = r
	p.life = 0.45
	p.global_position = at
	host.add_child(p)


static func puddle(host: Node, ab: String, at: Vector2, r: float, l: float) -> void:
	var p := SurvProj.new()
	p.kind = "puddle"
	p.ability = ab
	p.radius = r
	p.life = l
	p.global_position = at
	host.add_child(p)


static func mine(host: Node, ab: String, at: Vector2, r: float) -> void:
	var p := SurvProj.new()
	p.kind = "mine"
	p.ability = ab
	p.radius = r
	p.life = 8.0
	p.global_position = at
	host.add_child(p)


static func ring(host: Node, at: Vector2, r: float, c: Color) -> void:
	var p := SurvProj.new()
	p.kind = "ring"
	p.radius = r
	p.life = 0.35
	p.modulate = c
	p.global_position = at
	host.add_child(p)


static func flash(host: Node, at: Vector2, r: float) -> void:
	var p := SurvProj.new()
	p.kind = "flash"
	p.radius = r
	p.life = 0.25
	p.global_position = at
	host.add_child(p)


static func bolt(host: Node, a: Vector2, b: Vector2) -> void:
	var p := SurvProj.new()
	p.kind = "bolt"
	p.vel = b - a
	p.life = 0.16
	p.global_position = a
	host.add_child(p)


## Apply one hit of an ability to an enemy, with crit, slow and a number.
static func strike(e: Node, ab: String, src: Node) -> void:
	var tree := e.get_tree() if e else null
	var run := SurviveRun.get_run(tree)
	if run == null or not is_instance_valid(e) or int(e.get("hp")) <= 0:
		return
	var h := run.hit(ab)
	if ab == "gravy" and e.get("recover") != null:
		e.set("recover", maxf(float(e.get("recover")), 0.3))
	src.set("skill_dmg", int(h["dmg"]))
	e.call("take_hit", "skill", src)
	run.note_hit(e, int(h["dmg"]))
	# LEECH starter mod: a heart's worth back every 25 hits.
	if ab == SurvStarter.picked() and SurvStarter.mods(ab).has("leech"):
		_leech += 1
		if _leech >= 25:
			_leech = 0
			for ff in tree.get_nodes_in_group("players"):
				if ff is Fighter:
					(ff as Fighter).hp = mini((ff as Fighter).max_hp, (ff as Fighter).hp + 1)
	run.dealt[ab] = int(run.dealt.get(ab, 0)) + int(h["dmg"])
	if bool(h["crit"]):
		Juice.popup_number((e as Node2D).global_position + Vector2(0, -60), "CRIT %d" % int(h["dmg"]), UiKit.GOLD)
	if run.slow() > 0.0 and e.get("speed") != null:
		var base: float = e.get_meta("base_speed", float(e.get("speed")))
		e.set_meta("base_speed", base)
		e.set("speed", base * (1.0 - run.slow()))
		e.get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if is_instance_valid(e):
				e.set("speed", base)
		)


func _ready() -> void:
	z_index = 7 if kind not in ["puddle", "mine"] else 2
	if kind in ["flash", "bolt", "note", "ring", "beam"]:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = m
	if kind == "flash":
		Juice.pulse_shake(2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		if kind == "mine" or kind == "weight":
			_boom()
		queue_free()
		return
	match kind:
		"stamp":
			if life < 0.18 and not _slammed:
				_slammed = true
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is Node2D and int(e.get("hp")) > 0 and absf((e as Node2D).global_position.x - global_position.x) < radius and absf((e as Node2D).global_position.y - global_position.y) < radius * 0.5:
						SurvProj.strike(e, ability, self)
				Juice.pulse_shake(4.0)
				Juice.popup_number(global_position + Vector2(0, -40), "DENIED", Color(1.0, 0.3, 0.3))
				Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.6, -4.0)
		"weight":
			var k := 1.0 - life / 0.55
			global_position = start.lerp(target, k) + Vector2(0, -sin(k * PI) * 60.0)
		"badge", "blade":
			if kind == "badge" and life < 0.75 and owner_f and is_instance_valid(owner_f):
				# Coming home.
				var home := owner_f.global_position + Vector2(0, -30)
				vel = vel.move_toward((home - global_position).normalized() * 380.0, 1400.0 * delta)
				if global_position.distance_to(home) < 14.0:
					queue_free()
					return
				if fmod(life, 0.25) < delta:
					_hits.clear()
			if kind == "blade":
				var cam := get_viewport().get_camera_2d()
				if cam:
					var c := cam.get_screen_center_position()
					var half := get_viewport().get_visible_rect().size * 0.5 / cam.zoom
					if absf(global_position.x - c.x) > half.x - 12.0:
						vel.x = -signf(global_position.x - c.x) * absf(vel.x)
					if global_position.y < c.y - 40.0 or global_position.y > c.y + half.y - 20.0:
						vel.y = -signf(global_position.y - c.y - 30.0) * absf(vel.y)
				if fmod(_t, 0.5) < delta:
					_hits.clear()
			global_position += vel * delta
			for e in get_tree().get_nodes_in_group("enemies"):
				if not (e is Node2D) or _hits.has(e.get_instance_id()) or int(e.get("hp")) <= 0:
					continue
				var cc := (e as Node2D).global_position + Vector2(0, -26)
				if cc.distance_to(global_position) < 20.0:
					_hits[e.get_instance_id()] = true
					SurvProj.strike(e, ability, self)
		"invoice", "staple", "note", "cart", "bullet":
			global_position += vel * delta
			for e in get_tree().get_nodes_in_group("enemies"):
				if not (e is Node2D) or _hits.has(e.get_instance_id()) or int(e.get("hp")) <= 0:
					continue
				var c := (e as Node2D).global_position + Vector2(0, -26)
				var reach := 26.0 if kind == "note" else (30.0 if kind == "cart" else 16.0)
				if absf(c.x - global_position.x) < reach and absf(c.y - global_position.y) < 30.0:
					_hits[e.get_instance_id()] = true
					SurvProj.strike(e, ability, self)
					pierce -= 1
					if pierce <= 0:
						queue_free()
						return
		"puddle":
			_tick -= delta
			if _tick <= 0.0:
				_tick = 0.4
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is Node2D and absf((e as Node2D).global_position.x - global_position.x) < radius and absf((e as Node2D).global_position.y - global_position.y) < radius * 0.45:
						SurvProj.strike(e, ability, self)
		"mine":
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and int(e.get("hp")) > 0 and (e as Node2D).global_position.distance_to(global_position) < 22.0:
					_boom()
					queue_free()
					return
	queue_redraw()


func _boom() -> void:
	SurvProj.ring(get_parent(), global_position, radius, Color(1.0, 0.5, 0.2))
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and (e as Node2D).global_position.distance_to(global_position) < radius:
			SurvProj.strike(e, ability, self)
	Mixer.play_sfx("res://assets/audio/sfx/shotgun.ogg" if ResourceLoader.exists("res://assets/audio/sfx/shotgun.ogg") else "res://assets/audio/hit_heavy.wav", 0.7, -8.0)
	Juice.pulse_shake(3.0)


func _draw() -> void:
	match kind:
		"badge":
			draw_set_transform(Vector2.ZERO, _t * 16.0, Vector2.ONE)
			draw_rect(Rect2(Vector2(-6, -4), Vector2(12, 8)), Color(0.95, 0.95, 0.92))
			draw_rect(Rect2(Vector2(-6, -4), Vector2(12, 3)), Color(0.85, 0.2, 0.2))
			draw_line(Vector2(-4, 1), Vector2(3, 1), Color(0.3, 0.3, 0.35), 1.0)
		"blade":
			draw_set_transform(Vector2.ZERO, _t * 20.0, Vector2.ONE)
			for i in 8:
				var a := float(i) * TAU / 8.0
				draw_colored_polygon(PackedVector2Array([Vector2.from_angle(a) * 4.0, Vector2.from_angle(a + 0.25) * 10.0, Vector2.from_angle(a + 0.5) * 4.0]), Color(0.78, 0.8, 0.86))
			draw_circle(Vector2.ZERO, 4.5, Color(0.4, 0.42, 0.48))
			draw_circle(Vector2.ZERO, 1.5, Color(0.1, 0.1, 0.12))
		"beam":
			var k := life / 0.3
			draw_line(Vector2.ZERO, vel, Color(1.0, 0.35, 0.3, 0.8 * k), 9.0 * k)
			draw_line(Vector2.ZERO, vel, Color(1.0, 0.95, 0.9, k), 3.0 * k)
			for i in 6:
				var q := vel * randf()
				draw_rect(Rect2(q + Vector2(randf_range(-4, 4), randf_range(-6, 6)), Vector2(3, 2)), Color(1, 1, 1, 0.8 * k))
		"stamp":
			var drop := clampf((life - 0.18) / 0.57, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, radius * (1.0 - drop * 0.6), Color(0, 0, 0, 0.35))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var y := -drop * 120.0 - 16.0
			if life < 0.18:
				y = -16.0
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.3, 0.3, life / 0.18), 3.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(Vector2(-18, y), Vector2(36, 8)), Color(0.85, 0.15, 0.15))
			draw_rect(Rect2(Vector2(-12, y - 8), Vector2(24, 8)), Color(0.15, 0.14, 0.18))
			draw_rect(Rect2(Vector2(-4, y - 18), Vector2(8, 10)), Color(0.55, 0.36, 0.2))
			draw_circle(Vector2(0, y - 22), 6.0, Color(0.6, 0.4, 0.22))
		"weight":
			draw_circle(Vector2.ZERO, 6.0, Color(0.6, 0.85, 1.0, 0.85))
			draw_circle(Vector2(0, 1), 3.0, Color(0.8, 0.4, 0.95))
			draw_circle(Vector2(-2, -2), 1.5, Color(1, 1, 1))
		"invoice":
			draw_set_transform(Vector2.ZERO, _t * 14.0, Vector2.ONE)
			draw_rect(Rect2(Vector2(-4, -5), Vector2(8, 10)), Color(0.97, 0.96, 0.9))
			draw_line(Vector2(-3, -2), Vector2(3, -2), Color(0.6, 0.6, 0.65), 0.7)
			draw_line(Vector2(-3, 1), Vector2(2, 1), Color(0.6, 0.6, 0.65), 0.7)
			draw_rect(Rect2(Vector2(1, 2), Vector2(2, 2)), Color(0.85, 0.15, 0.15))
		"cart":
			var f := signf(vel.x)
			draw_rect(Rect2(Vector2(-14, -22), Vector2(28, 14)), Color(0.62, 0.65, 0.72))
			for x in [-10.0, -4.0, 2.0, 8.0]:
				draw_line(Vector2(x, -21), Vector2(x, -9), Color(0.4, 0.42, 0.48), 1.0)
			draw_line(Vector2(-14 * f, -22), Vector2(-19 * f, -28), Color(0.62, 0.65, 0.72), 2.0)
			draw_circle(Vector2(-9, -4), 3.0, Color(0.12, 0.12, 0.14))
			draw_circle(Vector2(9, -4), 3.0, Color(0.12, 0.12, 0.14))
			for k in 3:
				draw_line(Vector2(-f * (18.0 + 6.0 * k), -14 + k * 4), Vector2(-f * (26.0 + 8.0 * k), -14 + k * 4), Color(1, 1, 1, 0.4 - 0.1 * k), 1.0)
		"staple":
			var d := vel.normalized()
			draw_line(-d * 3.0, d * 3.0, Color(0.85, 0.87, 0.92), 1.0)
		"bullet":
			# A street round: hot tracer with a short smear behind it.
			var d := vel.normalized()
			draw_line(-d * 12.0, Vector2.ZERO, Color(1.0, 0.75, 0.3, 0.45), 2.0)
			draw_line(-d * 4.0, d * 2.0, Color(1.0, 0.95, 0.7), 2.0)
		"swipe":
			var k := clampf(life / 0.2, 0.0, 1.0)
			var a0 := vel.angle()
			draw_arc(Vector2.ZERO, radius, a0 - 1.1, a0 + 1.1, 18, Color(1.0, 1.0, 1.0, 0.75 * k), 4.0)
			draw_arc(Vector2.ZERO, radius * 0.82, a0 - 0.9, a0 + 0.9, 14, Color(1.0, 0.85, 0.5, 0.45 * k), 2.0)
		"note":
			var y := sin(_t * 14.0) * 4.0
			for k in 3:
				var x := -float(k) * 9.0
				draw_circle(Vector2(x, y + float(k)), 2.4, Color(0.6, 0.85, 1.0, 0.9 - float(k) * 0.25))
				draw_line(Vector2(x + 2, y + float(k)), Vector2(x + 2, y + float(k) - 8), Color(0.6, 0.85, 1.0, 0.8 - float(k) * 0.25), 1.0)
			draw_arc(Vector2.ZERO, 10.0, -0.8, 0.8, 8, Color(0.5, 0.8, 1.0, 0.35), 2.0)
		"puddle":
			var a := clampf(life, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
			if ability == "gravy":
				draw_circle(Vector2.ZERO, radius, Color(0.55, 0.3, 0.12, 0.6 * a))
			draw_circle(Vector2.ZERO, radius, Color(0.32, 0.18, 0.08, 0.55 * a))
			draw_circle(Vector2(-radius * 0.2, -radius * 0.1), radius * 0.6, Color(0.45, 0.27, 0.12, 0.5 * a))
			for k in 4:
				var ph := _t * 2.0 + float(k) * 1.7
				draw_arc(Vector2(cos(ph) * radius * 0.5, sin(ph) * radius * 0.4), 2.0 + fmod(_t * 6.0 + float(k), 4.0), 0, TAU, 10, Color(0.9, 0.85, 0.8, 0.4 * a), 1.0)
			draw_set_transform(Vector2(0, -6 - fmod(_t * 18.0, 14.0)), 0.0, Vector2.ONE)
			draw_circle(Vector2(sin(_t * 3.0) * 4.0, 0), 2.5, Color(1, 1, 1, 0.12 * a))
		"mine":
			var blink := fmod(_t, 0.8) < 0.15
			draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 7)), Color(0.85, 0.2, 0.25))
			draw_rect(Rect2(Vector2(-4, -4), Vector2(3, 2)), Color(1.0, 0.9, 0.3))
			draw_circle(Vector2(3, -6), 1.2, Color(1.0, 0.3, 0.3) if blink else Color(0.4, 0.1, 0.1))
		"ring":
			var k := 1.0 - life / 0.35
			draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * k), 0, TAU, 48, Color(1, 1, 1, 0.9 * (1.0 - k)), 4.0 * (1.0 - k) + 1.0)
		"flash":
			var k2 := life / 0.25
			draw_circle(Vector2.ZERO, radius * (1.2 - k2 * 0.4), Color(1.0, 1.0, 0.95, 0.35 * k2))
			draw_circle(Vector2.ZERO, radius * 0.3, Color(1, 1, 1, 0.8 * k2))
		"bolt":
			var pts := PackedVector2Array([Vector2.ZERO])
			var n := 6
			var rng := RandomNumberGenerator.new()
			rng.seed = int(_t * 60.0) + get_instance_id()
			for i in range(1, n):
				var p := vel * float(i) / float(n)
				pts.append(p + vel.orthogonal().normalized() * rng.randf_range(-7.0, 7.0))
			pts.append(vel)
			draw_polyline(pts, Color(0.75, 0.85, 1.0, 0.9), 2.0)
			draw_polyline(pts, Color(1, 1, 1, 1), 0.8)
