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


static func shoot(host: Node, k: String, ab: String, at: Vector2, v: Vector2, pierce_n: int) -> void:
	var p := SurvProj.new()
	p.kind = k
	p.ability = ab
	p.vel = v
	p.pierce = pierce_n
	p.life = 1.6 if k != "note" else 2.2
	if k == "cart":
		p.life = 3.0
	p.global_position = at
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
	if kind in ["flash", "bolt", "note", "ring"]:
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
		if kind == "mine":
			_boom()
		queue_free()
		return
	match kind:
		"invoice", "staple", "note", "cart":
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
