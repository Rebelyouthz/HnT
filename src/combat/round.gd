class_name Round
extends Node2D

## One fired projectile from a hand gun (see data/weapons.json "round"):
##   bullet  pistol / SMG: near-hitscan, a hair-thin warm streak you only
##           catch for a frame or two, like a real tracer-less round.
##   pellet  shotgun: a fan of tiny grey dots that thin out with distance;
##           close up they all land, far off only a few.
##   nail    nailgun: a visible steel nail, slower, drops a little, and stays
##           stuck in whatever it hits (bodies included).
##   flare   FLARE GUN: a slow, arcing ball of burning magnesium with a
##           smoke tail and a real light; sets whoever it hits on fire and
##           burns on the street where it lands.
##   orb     FINAL NOTICE: a slow, pulsing ball of red ink trailing shredded
##           invoice scraps; it goes through everyone in the lane.
## Hits are tested against enemies in the shooter's lane (|y| < LANE); the
## zone (head / chest / gut / legs) comes from where the shooter aimed.

const LANE := 24.0

var weapon := "pistol"
var round_kind := "bullet"
var vel := Vector2.ZERO
var dmg := 10
var zone := "chest"
var lane_y := 0.0
var owner_role := "son"
var shooter: Node2D
var range_left := 900.0
var dist := 0.0
var pierce := false
## Bodies a bullet can still go through (BIG IRON: one).
var pierce_left := 0
## Did the last body hit let the round out the far side (exit wound) or keep it?
var went_through := false
var _passes := 0
var _from := Vector2.ZERO
var _trail: Array[Vector2] = []
var _hit_ids: Dictionary = {}
var _t := 0.0
var _light: PointLight2D
var _scraps: Array[Dictionary] = []


func _ready() -> void:
	z_index = 9
	_from = global_position
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	if round_kind != "nail" and round_kind != "pellet":
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	if round_kind == "orb" or round_kind == "flare":
		_light = PointLight2D.new()
		_light.texture = LightRig.radial_tex()
		_light.texture_scale = 0.4 if round_kind == "orb" else 0.6
		_light.color = Color(1.0, 0.18, 0.2) if round_kind == "orb" else Color(1.0, 0.45, 0.25)
		_light.energy = 1.4
		add_child(_light)
	if round_kind == "flare":
		var smoke := CPUParticles2D.new()
		smoke.amount = 26
		smoke.lifetime = 0.7
		smoke.local_coords = false
		smoke.gravity = Vector2(0, -30)
		smoke.initial_velocity_min = 4.0
		smoke.initial_velocity_max = 14.0
		smoke.spread = 180.0
		smoke.scale_amount_min = 2.0
		smoke.scale_amount_max = 4.5
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.75, 0.4, 0.7))
		g.set_color(1, Color(0.5, 0.5, 0.55, 0.0))
		smoke.color_ramp = g
		smoke.z_index = -1
		add_child(smoke)


func _physics_process(delta: float) -> void:
	_t += delta
	if round_kind == "nail" or round_kind == "pellet" or round_kind == "flare":
		vel.y += {"nail": 140.0, "pellet": 60.0, "flare": 110.0}[round_kind] * delta
	var step := vel * delta
	var a := global_position
	var b := a + step
	_trail.append(a)
	if _trail.size() > (10 if round_kind == "orb" else 3):
		_trail.pop_front()
	if _test(a, b):
		return
	global_position = b
	dist += step.length()
	range_left -= step.length()
	if round_kind == "orb":
		if randf() < 0.6:
			_scraps.append({"p": global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), "v": Vector2(-vel.x * 0.05 + randf_range(-20, 20), randf_range(-30, 10)), "t": 0.6, "r": randf() * TAU})
		_light.energy = 1.2 + 0.4 * sin(_t * 18.0)
	elif round_kind == "flare":
		_light.energy = 1.6 + randf_range(-0.35, 0.35)
	for s in _scraps:
		s["t"] = float(s["t"]) - delta
		s["p"] = (s["p"] as Vector2) + (s["v"] as Vector2) * delta
		s["r"] = float(s["r"]) + delta * 8.0
	_scraps = _scraps.filter(func(s: Dictionary) -> bool: return float(s["t"]) > 0.0)
	if range_left <= 0.0:
		if round_kind == "nail":
			_stick_world(global_position)
		elif round_kind == "flare":
			FireFx.ground(get_parent(), Vector2(global_position.x, lane_y), 3.0)
		elif round_kind == "bullet" or round_kind == "pellet":
			# A miss hits the street or a wall: sparks and maybe a whine,
			# and the wet street throws up a splash where it comes down.
			if round_kind == "bullet" or randf() < 0.25:
				GunFx.ricochet(get_parent(), global_position, int(signf(vel.x)))
			if round_kind == "bullet" and randf() < 0.5:
				WallMark.mark(get_parent(), global_position, signf(vel.x), false)
			if randf() < (0.8 if round_kind == "bullet" else 0.3):
				GunFx.splash(get_parent(), Vector2(global_position.x + randf_range(-10.0, 10.0), lane_y + randf_range(-4.0, 4.0)))
		queue_free()
		return
	queue_redraw()


## Swept test against every enemy in the lane between a and b.
func _test(a: Vector2, b: Vector2) -> bool:
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk) or not is_instance_valid(n):
			continue
		var p := n as Punk
		if p.hp <= 0 or _hit_ids.has(p.get_instance_id()):
			continue
		if absf(p.global_position.y - lane_y) > LANE:
			continue
		var x := p.global_position.x
		var lo := minf(a.x, b.x) - 12.0
		var hi := maxf(a.x, b.x) + 12.0
		if x < lo or x > hi:
			continue
		# Pellets fan out: far away, a pellet may sail over or under.
		if round_kind == "pellet" and absf(global_position.y - _from.y) > 26.0:
			continue
		_hit_ids[p.get_instance_id()] = true
		went_through = pierce or pierce_left > 0 or (_passes < 2 and randf() < _through_chance())
		_land(p, Vector2(x - signf(vel.x) * 6.0, global_position.y))
		if pierce_left > 0:
			pierce_left -= 1
			continue
		if pierce:
			continue
		if went_through and round_kind != "orb":
			# What came out the back paints the wall behind him.
			WallMark.mark(get_parent(), Vector2(x + signf(vel.x) * randf_range(26.0, 60.0), global_position.y + randf_range(-5.0, 5.0)), signf(vel.x))
			# The exit: a wetter, lower tear than the entry.
			Mixer.play_sfx("res://assets/audio/sfx/bullet_flesh.ogg", randf_range(0.62, 0.75), -8.0)
		if went_through and dmg >= 3:
			# Clean through: out the far side, slower and weaker, and on to
			# whoever stands behind.
			_passes += 1
			dmg = int(round(float(dmg) * 0.55))
			vel *= 0.8
			continue
		queue_free()
		return true
	return false


## How likely a round leaves through the far side: a revolver almost always,
## a pistol about half the time, an SMG less, pellets only point blank;
## nails and flares stay in. Thin parts (head, legs) let more through.
func _through_chance() -> float:
	var c: float = {"revolver": 0.85, "pistol": 0.5, "smg": 0.35}.get(weapon, 0.0)
	if round_kind == "pellet":
		c = 0.3 if dist < 110.0 else 0.0
	if round_kind != "bullet" and round_kind != "pellet":
		return 0.0
	if zone == "head" or zone == "legs":
		c += 0.15
	elif zone == "gut":
		c -= 0.1
	return clampf(c, 0.0, 0.95)


func _land(p: Punk, at: Vector2) -> void:
	p.set_meta("shot_at", at)
	p.take_hit("gun", self)
	if round_kind != "orb" and ResourceLoader.exists("res://assets/audio/sfx/bullet_flesh.ogg"):
		Mixer.play_sfx("res://assets/audio/sfx/bullet_flesh.ogg", randf_range(0.9, 1.15), -5.0)
	if round_kind == "nail" and is_instance_valid(p):
		_stick_body(p, at)
	if round_kind == "orb":
		Juice.pulse_shake(3.0)
	if round_kind == "flare" and is_instance_valid(p):
		p.ignite(4.0, owner_role)
		Juice.impact(at, 0.6, int(signf(vel.x)))


func _stick_body(p: Punk, at: Vector2) -> void:
	var nail := Line2D.new()
	nail.width = 0.8
	nail.default_color = Color(0.75, 0.76, 0.8)
	var local := p.to_local(at)
	nail.points = PackedVector2Array([local, local + Vector2(-signf(vel.x) * 5.0, 0)])
	nail.z_index = 6
	p.add_child(nail)


func _stick_world(at: Vector2) -> void:
	var host := get_parent()
	if host == null:
		return
	var nail := Line2D.new()
	nail.width = 0.8
	nail.default_color = Color(0.7, 0.72, 0.76)
	nail.points = PackedVector2Array([at, at + Vector2(-signf(vel.x) * 5.0, 0)])
	nail.z_index = 2
	host.add_child(nail)
	var tw := nail.create_tween()
	tw.tween_interval(12.0)
	tw.tween_callback(nail.queue_free)


func _draw() -> void:
	var dir := vel.normalized()
	match round_kind:
		"bullet":
			# A thin hot streak, gone almost as soon as it is seen.
			var len := 16.0 if weapon == "pistol" else 11.0
			var al := 0.55 if weapon == "pistol" else 0.4
			draw_line(-dir * len, Vector2.ZERO, Color(1.0, 0.86, 0.6, al * 0.35), 1.2)
			draw_line(-dir * len * 0.5, Vector2.ZERO, Color(1.0, 0.95, 0.85, al), 0.5)
		"pellet":
			draw_rect(Rect2(Vector2(-0.4, -0.4), Vector2(0.8, 0.8)), Color(0.7, 0.7, 0.72, 0.85))
			draw_line(-dir * 5.0, Vector2.ZERO, Color(0.9, 0.9, 0.9, 0.18), 0.4)
		"nail":
			var ang := vel.angle()
			var tip := Vector2.ZERO
			var tail := -Vector2.from_angle(ang) * 6.0
			draw_line(tail, tip, Color(0.72, 0.74, 0.78), 0.9)
			draw_line(tail + Vector2.from_angle(ang + PI * 0.5) * 1.2, tail - Vector2.from_angle(ang + PI * 0.5) * 1.2, Color(0.82, 0.84, 0.88), 0.9)
			draw_line(-dir * 14.0, tail, Color(0.9, 0.95, 1.0, 0.12), 0.6)
		"flare":
			var fl := 1.0 + 0.25 * randf()
			draw_circle(Vector2.ZERO, 7.0 * fl, Color(1.0, 0.35, 0.1, 0.35))
			draw_circle(Vector2.ZERO, 4.0 * fl, Color(1.0, 0.7, 0.3, 0.9))
			draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.92, 1.0))
		"orb":
			for i in _trail.size():
				var k := float(i + 1) / float(_trail.size())
				draw_circle(to_local(_trail[i]), 2.5 + 2.5 * k, Color(0.9, 0.05, 0.08, 0.12 * k))
			var pulse := 1.0 + 0.18 * sin(_t * 22.0)
			draw_circle(Vector2.ZERO, 6.0 * pulse, Color(0.85, 0.05, 0.1, 0.55))
			draw_circle(Vector2.ZERO, 3.6 * pulse, Color(1.0, 0.35, 0.3, 0.9))
			draw_circle(Vector2(-1, -1), 1.4, Color(1.0, 0.92, 0.9, 1.0))
	for s in _scraps:
		var lp := to_local(s["p"] as Vector2)
		var r: float = s["r"]
		var c := Color(0.95, 0.93, 0.86, clampf(float(s["t"]) / 0.6, 0.0, 1.0))
		draw_line(lp - Vector2.from_angle(r) * 1.5, lp + Vector2.from_angle(r) * 1.5, c, 1.0)
