class_name GunFx
extends Node2D

## What a shot leaves behind: the muzzle flash (shape and size per gun),
## a puff of smoke, and the brass. Casings fly out of the ejection port,
## spin, bounce twice on the street with a clink and lie there.

var kind := "flash"
var weapon := "pistol"
var facing := 1
var _t := 0.0
var _life := 0.08
var _v := Vector2.ZERO
var _floor := 500.0
var _spin := 0.0
var _bounces := 0
var _seed := 0
var _frames := 0


static func flash(host: Node, at: Vector2, w: String, face: int) -> void:
	if host == null:
		return
	var f := GunFx.new()
	f.kind = "flash"
	f.weapon = w
	f.facing = face
	f._seed = randi()
	f._life = {"shotgun": 0.09, "smg": 0.035, "ray": 0.16, "nailgun": 0.05, "revolver": 0.08, "flare_gun": 0.12}.get(w, 0.05)
	f.global_position = at
	host.add_child(f)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 0.55 if w == "shotgun" or w == "revolver" else 0.35
	l.color = Color(1.0, 0.2, 0.2) if w == "ray" else (Color(1.0, 0.4, 0.2) if w == "flare_gun" else Color(1.0, 0.78, 0.45))
	l.energy = 2.2 if w == "shotgun" or w == "revolver" else 1.4
	# A real light: it washes the street and walls, and things cast shadows.
	l.texture_scale *= 2.2
	l.energy *= 1.3
	l.shadow_enabled = true
	l.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	l.shadow_color = Color(0, 0, 0, 0.55)
	f.set_meta("light", l)
	f.add_child(l)
	if w == "shotgun" or w == "pistol" or w == "revolver" or w == "flare_gun":
		var s := GunFx.new()
		s.kind = "smoke"
		s.facing = face
		s._life = 0.9 if w == "shotgun" or w == "flare_gun" else (0.7 if w == "revolver" else 0.5)
		s.global_position = at
		host.add_child(s)


## The empty magazine (or battery) drops out of the grip and clatters.
static func mag(host: Node, at: Vector2, w: String, face: int, floor_y: float) -> void:
	if host == null or w == "shotgun":
		return
	var c := GunFx.new()
	c.kind = "mag"
	c.weapon = w
	c.facing = face
	c._life = 12.0
	c._floor = floor_y + randf_range(-2.0, 4.0)
	c._v = Vector2(-float(face) * randf_range(10.0, 30.0), randf_range(-60.0, -20.0))
	c._spin = randf_range(-6.0, 6.0)
	c.global_position = at
	host.add_child(c)


## A round into the wet street: a ripple ring and a crown of droplets.
static func splash(host: Node, at: Vector2) -> void:
	if host == null:
		return
	var c := GunFx.new()
	c.kind = "splash"
	c._seed = randi()
	c._life = 0.4
	c.global_position = at
	c.z_index = 2
	host.add_child(c)


## A miss: sparks off the street or a wall, sometimes a ricochet whine.
static func ricochet(host: Node, at: Vector2, face: int) -> void:
	if host == null:
		return
	var c := GunFx.new()
	c.kind = "spark"
	c.facing = face
	c._seed = randi()
	c._life = 0.16
	c.global_position = at
	host.add_child(c)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 0.12
	l.color = Color(1.0, 0.8, 0.5)
	l.energy = 1.2
	c.add_child(l)
	if randf() < 0.6:
		var p := "res://assets/audio/sfx/ricochet.ogg"
		Mixer.play_sfx(p if ResourceLoader.exists(p) else "res://assets/audio/cling.wav", randf_range(0.85, 1.2), -9.0)


static func casing(host: Node, at: Vector2, w: String, face: int, floor_y: float) -> void:
	if host == null or w == "ray" or w == "nailgun":
		return
	var c := GunFx.new()
	c.kind = "casing"
	c.weapon = w
	c.facing = face
	c._life = 14.0
	c._floor = floor_y + randf_range(-3.0, 5.0)
	c._v = Vector2(-float(face) * randf_range(40.0, 90.0), randf_range(-170.0, -120.0))
	c._spin = randf_range(-18.0, 18.0)
	c.global_position = at
	host.add_child(c)


func _ready() -> void:
	# Drawn for the old body size: grow with the actors (flashes a bit more,
	# they should punch).
	scale = Vector2.ONE * SpriteBook.ACTOR_K * (1.6 if kind == "flash" else 1.2)
	z_index = 9 if kind != "casing" and kind != "mag" else 3
	if kind != "casing" and kind != "mag":
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		if kind == "flash":
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m


func _process(delta: float) -> void:
	_frames += 1
	_t += delta
	# A flash is always seen for at least three drawn frames, whatever the
	# frame rate.
	if (kind == "flash" or kind == "spark") and _frames <= 3:
		_t = minf(_t, _life * 0.6)
	if kind == "flash" and has_meta("light"):
		var lt := get_meta("light") as PointLight2D
		if is_instance_valid(lt):
			lt.energy *= 0.82 if weapon != "smg" else randf_range(0.6, 1.0)
	if kind == "casing" or kind == "mag":
		if _bounces < 3:
			_v.y += 900.0 * delta
			position += _v * delta
			rotation += _spin * delta
			if position.y >= _floor and _v.y > 0.0:
				position.y = _floor
				_bounces += 1
				_v = Vector2(_v.x * 0.5, -_v.y * 0.35)
				_spin *= 0.5
				if _bounces == 1 and kind == "mag":
					Mixer.play_sfx("res://assets/audio/sfx/mag_drop.ogg" if ResourceLoader.exists("res://assets/audio/sfx/mag_drop.ogg") else "res://assets/audio/block.wav", randf_range(0.9, 1.1), -10.0)
				elif _bounces == 1:
					Mixer.play_sfx("res://assets/audio/sfx/casing.ogg" if ResourceLoader.exists("res://assets/audio/sfx/casing.ogg") else "res://assets/audio/cling.wav", randf_range(1.1, 1.4), -14.0)
				if _bounces >= 3:
					rotation = round(rotation / PI) * PI
		if _t > _life - 1.0:
			modulate.a = clampf(_life - _t, 0.0, 1.0)
	if _t >= _life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var f := float(facing)
	match kind:
		"flash":
			var k := 1.0 - _t / _life
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed
			match weapon:
				"shotgun":
					# A wide ragged star and a cone of sparks.
					for i in 9:
						var a := rng.randf_range(-0.55, 0.55)
						var l := rng.randf_range(10.0, 24.0) * k
						draw_line(Vector2.ZERO, Vector2(cos(a) * f, sin(a)) * l, Color(1.0, 0.8, 0.4, 0.9 * k), 2.0)
					draw_circle(Vector2(4.0 * f, 0), 6.0 * k, Color(1.0, 0.95, 0.75, k))
				"smg":
					draw_circle(Vector2(2.0 * f, 0), 2.6 * k, Color(1.0, 0.9, 0.6, k))
					draw_line(Vector2.ZERO, Vector2(9.0 * f, 0), Color(1.0, 0.75, 0.4, 0.8 * k), 1.2)
				"nailgun":
					# Pneumatic: a pale puff, no fire.
					draw_circle(Vector2(3.0 * f, 0), 3.0 * (1.0 - k) + 1.0, Color(0.85, 0.9, 1.0, 0.5 * k))
				"revolver":
					# Big iron: a long tongue of fire and a side blast from the gap.
					draw_line(Vector2.ZERO, Vector2(18.0 * f, 0) * k, Color(1.0, 0.75, 0.35, k), 3.0)
					draw_line(Vector2.ZERO, Vector2(24.0 * f, 0) * k, Color(1.0, 0.95, 0.8, k), 1.2)
					for a in [-0.6, 0.6]:
						draw_line(Vector2(-8.0 * f, 0), Vector2(-8.0 * f, 0) + Vector2(0.3 * f, a * 1.4) * 9.0 * k, Color(1.0, 0.7, 0.35, 0.8 * k), 1.4)
					draw_circle(Vector2(3.0 * f, 0), 5.0 * k, Color(1.0, 0.96, 0.82, k))
				"flare_gun":
					draw_circle(Vector2(4.0 * f, 0), 7.0 * k, Color(1.0, 0.35, 0.12, 0.7 * k))
					draw_circle(Vector2(3.0 * f, 0), 4.0 * k, Color(1.0, 0.85, 0.5, k))
					for i in 6:
						var a3 := rng.randf_range(-0.8, 0.8)
						draw_line(Vector2.ZERO, Vector2(cos(a3) * f, sin(a3)) * rng.randf_range(6.0, 14.0) * k, Color(1.0, 0.55, 0.2, k), 1.2)
				"ray":
					for r in [9.0, 6.0, 3.0]:
						draw_arc(Vector2(2.0 * f, 0), r * (1.4 - k * 0.6), 0, TAU, 20, Color(1.0, 0.2, 0.25, 0.8 * k), 1.2)
					draw_circle(Vector2(2.0 * f, 0), 3.5 * k, Color(1.0, 0.85, 0.85, k))
				_:
					for a in [-0.35, 0.0, 0.35]:
						draw_line(Vector2.ZERO, Vector2(cos(a) * f, sin(a)) * (12.0 if a == 0.0 else 7.0) * k, Color(1.0, 0.82, 0.45, k), 1.6)
					draw_circle(Vector2(2.0 * f, 0), 3.6 * k, Color(1.0, 0.96, 0.8, k))
		"smoke":
			var k2 := _t / _life
			for i in 3:
				var c := Vector2((6.0 + 10.0 * k2 + float(i) * 3.0) * f, -6.0 * k2 - float(i) * 2.0)
				draw_circle(c, 2.0 + 5.0 * k2, Color(0.75, 0.75, 0.78, 0.22 * (1.0 - k2)))
		"mag":
			var dark := Color(0.12, 0.12, 0.14)
			var w2 := 2.0 if weapon == "smg" else 1.6
			var h2 := 5.0 if weapon == "smg" else 3.4
			draw_rect(Rect2(Vector2(-w2 * 0.5, -h2 * 0.5), Vector2(w2, h2)), dark)
			draw_rect(Rect2(Vector2(-w2 * 0.5, -h2 * 0.5), Vector2(w2, 0.6)), Color(0.4, 0.4, 0.45))
		"splash":
			var ks := _t / _life
			var rng3 := RandomNumberGenerator.new()
			rng3.seed = _seed
			draw_arc(Vector2.ZERO, 2.0 + 9.0 * ks, 0, TAU, 18, Color(0.75, 0.85, 1.0, 0.5 * (1.0 - ks)), 0.8)
			for i in 7:
				var vx := rng3.randf_range(-40.0, 40.0)
				var vy := rng3.randf_range(-90.0, -50.0)
				var tt := _t
				var p2 := Vector2(vx * tt, vy * tt + 260.0 * tt * tt)
				if p2.y < 1.0:
					draw_circle(p2, 0.8, Color(0.8, 0.9, 1.0, 0.85 * (1.0 - ks)))
		"spark":
			var k3 := 1.0 - _t / _life
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = _seed
			for i in 7:
				var a2 := rng2.randf_range(-PI, 0.0)
				var l2 := rng2.randf_range(3.0, 9.0) * (0.4 + 0.6 * (1.0 - k3))
				draw_line(Vector2.ZERO, Vector2(cos(a2), sin(a2)) * l2, Color(1.0, 0.85, 0.5, k3), 1.0)
			draw_circle(Vector2.ZERO, 1.5 * k3, Color(1, 1, 0.9, k3))
		"casing":
			var red := weapon == "shotgun"
			var col := Color(0.75, 0.15, 0.12) if red else Color(0.86, 0.66, 0.26)
			var len := 2.6 if red else 1.4
			draw_rect(Rect2(Vector2(-len * 0.5, -0.5), Vector2(len, 1.0)), col)
			if red:
				draw_rect(Rect2(Vector2(len * 0.5 - 0.8, -0.55), Vector2(0.8, 1.1)), Color(0.85, 0.7, 0.3))
