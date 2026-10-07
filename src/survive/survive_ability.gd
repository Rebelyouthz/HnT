class_name SurviveAbility
extends Node2D

## One auto-firing ability on one fighter (data/survive.json abilities). It
## reads its level and every stat off SurviveRun each shot, so traits and
## items apply at once.

var id := "invoice_toss"
var skill_dmg := 6
var _cd := 0.4
var _t := 0.0
var _orbit: Array[Node2D] = []
var _hit_cd: Dictionary = {}


func _run() -> SurviveRun:
	return SurviveRun.get_run(get_tree())


func _f() -> Fighter:
	return get_parent() as Fighter


func _process(delta: float) -> void:
	var run := _run()
	var f := _f()
	if run == null or f == null or f.downed:
		return
	_t += delta
	var r := run.row("abilities", id)
	if bool(r.get("manual", false)):
		_tick_reticle(f)
	if id == "clipboards" or id == "bag":
		_tick_orbit(run, r, delta)
		return
	_cd -= delta
	if _cd > 0.0:
		return
	# Manual weapons fire on SHOOT with no gun in hand: NAIL DRIVER while
	# held, PAPERWEIGHT on each tap.
	# Twin-stick: the right stick (or the mouse) aims them, and pushing the
	# stick all the way out or holding the left mouse button fires too.
	if bool(r.get("manual", false)):
		if Arsenal.is_gun(str(f.get("pickup"))):
			return
		var twin := PadRouter.rstick(f.prefix).length() > 0.75 or (PadRouter.mouse_live(f.prefix) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		var want: bool = twin or (f.call("_pressed", "shoot") if id == "nail_driver" else f.call("_just", "shoot"))
		if not want:
			return
	_cd = float(r.get("cd", 1.5)) * run.cd_mul() * (0.65 if run.evolved.has(id) else 1.0) * SurvStarter.cd_mul(id)
	_fire(run, r, f)


## Aim direction from the right stick, else the mouse, else zero (facing).
func _aim(f: Fighter, at: Vector2) -> Vector2:
	var rs := PadRouter.rstick(f.prefix)
	if rs.length() > 0.3:
		return rs.normalized()
	if PadRouter.mouse_live(f.prefix):
		var d := get_global_mouse_position() - at
		if d.length() > 12.0:
			return d.normalized()
	return Vector2.ZERO


## How far a lob goes: to the mouse, or further the harder the stick is pushed.
func _reach(f: Fighter, at: Vector2) -> float:
	var rs := PadRouter.rstick(f.prefix)
	if rs.length() > 0.3:
		return lerpf(70.0, 230.0, clampf(rs.length(), 0.0, 1.0))
	return clampf((get_global_mouse_position() - at).length(), 60.0, 260.0)


var _ret: Node2D


## A small crosshair where the manual weapon is pointed.
func _tick_reticle(f: Fighter) -> void:
	var at := f.global_position + Vector2(0, -30)
	var aim := _aim(f, at)
	if _ret == null:
		_ret = Node2D.new()
		_ret.top_level = true
		_ret.z_index = 40
		_ret.draw.connect(func() -> void:
			var c := Color(1.0, 0.85, 0.3, 0.85)
			_ret.draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, c, 2.0)
			for k in 4:
				var d := Vector2.from_angle(float(k) * PI * 0.5)
				_ret.draw_line(d * 5.0, d * 13.0, c, 2.0)
		)
		add_child(_ret)
	_ret.visible = aim != Vector2.ZERO
	if _ret.visible:
		var dist := _reach(f, at) if id == "paperweight" else 120.0
		_ret.global_position = at + aim * dist
		_ret.queue_redraw()


func _nearest(from: Vector2, max_d := 420.0, skip: Array = []) -> Node2D:
	var best: Node2D = null
	var bd := max_d
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D) or e in skip or int(e.get("hp")) <= 0:
			continue
		var d := (e as Node2D).global_position.distance_to(from)
		if d < bd:
			bd = d
			best = e as Node2D
	return best


func _host() -> Node:
	return get_tree().current_scene


func _fire(run: SurviveRun, r: Dictionary, f: Fighter) -> void:
	var at := f.global_position + Vector2(0, -30)
	var area := float(r.get("area", 40)) * run.area_mul() * SurvStarter.area_mul(id)
	match id:
		"invoice_toss":
			var n := run.proj_count(id)
			var t := _nearest(at)
			var base := (t.global_position + Vector2(0, -24) - at).angle() if t else (0.0 if f.facing > 0 else PI)
			for i in n:
				var a := base + (float(i) - float(n - 1) * 0.5) * 0.22
				SurvProj.shoot(_host(), "invoice", id, at, Vector2.from_angle(a) * 360.0, 1)
			Mixer.play_sfx("res://assets/audio/whoosh_light.wav", randf_range(1.4, 1.7), -16.0)
		"stapler":
			var n := run.proj_count(id)
			var face := 0.0 if f.facing > 0 else PI
			for i in n:
				var a := face + (float(i) - float(n - 1) * 0.5) * 0.14
				SurvProj.shoot(_host(), "staple", id, at, Vector2.from_angle(a) * 520.0, 1)
			Mixer.play_sfx("res://assets/audio/sfx/nailgun.ogg" if ResourceLoader.exists("res://assets/audio/sfx/nailgun.ogg") else "res://assets/audio/ui_click.wav", 1.6, -12.0)
		"coffee":
			var t := _nearest(at, 260.0)
			var p := t.global_position if t else f.global_position + Vector2(float(f.facing) * 40.0, 0)
			SurvProj.puddle(_host(), id, p, area, float(r.get("life", 3.0)))
		"late_fee":
			var chain := int(r.get("chain", 2)) + int(r.get("chain_per", 1)) * (int(run.abilities.get(id, 1)) - 1)
			var hit: Array = []
			var from := at
			for i in chain:
				var t := _nearest(from, 260.0, hit)
				if t == null:
					break
				hit.append(t)
				SurvProj.bolt(_host(), from, t.global_position + Vector2(0, -26))
				SurvProj.strike(t, id, self)
				from = t.global_position + Vector2(0, -26)
			if not hit.is_empty():
				Mixer.play_sfx("res://assets/audio/sfx/ray.ogg" if ResourceLoader.exists("res://assets/audio/sfx/ray.ogg") else "res://assets/audio/zap.wav", 1.8, -10.0)
		"dad_joke":
			SurvProj.ring(_host(), f.global_position, area, Color(1.0, 0.85, 0.4))
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and (e as Node2D).global_position.distance_to(f.global_position) < area:
					SurvProj.strike(e, id, self)
					e.set("recover", maxf(float(e.get("recover")), 0.5))
			Juice.pulse_shake(4.0)
			Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.7, -6.0)
		"hold_music":
			var face := 1.0 if f.facing > 0 else -1.0
			SurvProj.shoot(_host(), "note", id, at, Vector2(face * 300.0, 0), 99)
		"magnet_mines":
			for i in run.proj_count(id):
				SurvProj.mine(_host(), id, f.global_position + Vector2(randf_range(-50, 50), randf_range(-14, 14)), area)
		"photo_flash":
			SurvProj.flash(_host(), f.global_position + Vector2(0, -30), area)
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and (e as Node2D).global_position.distance_to(f.global_position) < area:
					SurvProj.strike(e, id, self)
					e.set("recover", maxf(float(e.get("recover")), float(r.get("stun", 0.9))))
			Mixer.play_sfx("res://assets/audio/card.wav", 1.5, -6.0)
		"cart":
			var n := 1 + (2 if run.evolved.has(id) else 0)
			for i in n:
				var dir := (1.0 if f.facing > 0 else -1.0) * (1.0 if i % 2 == 0 else -1.0)
				SurvProj.shoot(_host(), "cart", id, f.global_position + Vector2(-dir * 60.0, randf_range(-20, 20)), Vector2(dir * 300.0, 0), 99)
			Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", 1.4, -12.0)
		"hydrant":
			SurvProj.ring(_host(), f.global_position, area, Color(0.45, 0.75, 1.0))
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and (e as Node2D).global_position.distance_to(f.global_position) < area:
					SurvProj.strike(e, id, self)
					var away := ((e as Node2D).global_position - f.global_position).normalized()
					(e as Node2D).global_position += away * 46.0
			Mixer.play_sfx("res://assets/audio/whoosh.wav" if ResourceLoader.exists("res://assets/audio/whoosh.wav") else "res://assets/audio/sfx/throw_whoosh.ogg", 0.6, -8.0)
		"mailbomb":
			for i in run.proj_count(id):
				var t := _nearest(at, 380.0)
				var p := (t.global_position if t else f.global_position + Vector2(float(f.facing) * 120.0, 0)) + Vector2(randf_range(-30, 30), randf_range(-10, 10))
				SurvProj.bomb(_host(), id, p, area)
		"sprinkler":
			var n := run.proj_count(id) * (2 if run.evolved.has(id) else 1)
			for i in n:
				var a := TAU * float(i) / float(n) + _t
				SurvProj.shoot(_host(), "staple", id, at, Vector2.from_angle(a) * 420.0, 1)
		"name_badge":
			for i in run.proj_count(id):
				var t := _nearest(at)
				var a := (t.global_position + Vector2(0, -24) - at).angle() if t else (0.0 if f.facing > 0 else PI)
				SurvProj.shoot(_host(), "badge", id, at, Vector2.from_angle(a + (float(i) - float(run.proj_count(id) - 1) * 0.5) * 0.5) * 330.0, 99, f)
			Mixer.play_sfx("res://assets/audio/whoosh_light.wav", 1.2, -12.0)
		"shredder":
			for i in run.proj_count(id):
				var a := randf() * TAU
				SurvProj.shoot(_host(), "blade", id, at, Vector2.from_angle(a) * 260.0, 9999, f)
			Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", 1.8, -12.0)
		"fax_beam":
			var dir := Vector2(1.0 if f.facing > 0 else -1.0, 0)
			var t := _nearest(at, area)
			if t:
				dir = (t.global_position + Vector2(0, -24) - at).normalized()
			SurvProj.beam(_host(), id, at, dir * area)
			for e in get_tree().get_nodes_in_group("enemies"):
				if not (e is Node2D) or int(e.get("hp")) <= 0:
					continue
				var c := (e as Node2D).global_position + Vector2(0, -24) - at
				var along := c.dot(dir)
				if along > 0.0 and along < area and absf(c.cross(dir)) < 16.0:
					SurvProj.strike(e, id, self)
			Mixer.play_sfx("res://assets/audio/sfx/ray.ogg" if ResourceLoader.exists("res://assets/audio/sfx/ray.ogg") else "res://assets/audio/zap.wav", 0.9, -8.0)
		"rubber_stamp":
			var hit: Array = []
			for i in run.proj_count(id):
				var t := _nearest(f.global_position, 360.0, hit)
				if t == null:
					break
				hit.append(t)
				SurvProj.stamp(_host(), id, t.global_position + Vector2(randf_range(-6, 6), 0), area)
		"nail_driver":
			var aim := _aim(f, at)
			var face := aim.angle() if aim != Vector2.ZERO else (0.0 if f.facing > 0 else PI)
			var n := run.proj_count(id)
			for i in n:
				var a := face + (float(i) - float(n - 1) * 0.5) * 0.1 + randf_range(-0.05, 0.05)
				SurvProj.shoot(_host(), "staple", id, at, Vector2.from_angle(a) * 620.0, 1 + int(run.abilities.get(id, 1)) / 3)
			Mixer.play_sfx("res://assets/audio/sfx/nailgun.ogg" if ResourceLoader.exists("res://assets/audio/sfx/nailgun.ogg") else "res://assets/audio/ui_click.wav", randf_range(1.5, 1.8), -14.0)
		"paperweight":
			var aim := _aim(f, at)
			var p := f.global_position + Vector2(float(f.facing) * 110.0, 0)
			if aim != Vector2.ZERO:
				p = f.global_position + aim * _reach(f, at)
			else:
				var t := _nearest(p, 120.0)
				if t:
					p = t.global_position
			SurvProj.lob(_host(), id, at, p, area)
			Mixer.play_sfx("res://assets/audio/whoosh_light.wav", 0.8, -10.0)
		"audit":
			var chain := int(r.get("chain", 5)) + int(r.get("chain_per", 1)) * (int(run.abilities.get(id, 1)) - 1) + (99 if run.evolved.has(id) else 0)
			var hit: Array = []
			var from := at
			for i in chain:
				var t := _nearest(from, 320.0, hit)
				if t == null:
					break
				hit.append(t)
				SurvProj.bolt(_host(), from, t.global_position + Vector2(0, -26))
				SurvProj.strike(t, id, self)
				from = t.global_position + Vector2(0, -26)
		"gravy":
			# Under the biggest crowd: the enemy with the most others near it.
			var best: Node2D = null
			var bn := -1
			for e in get_tree().get_nodes_in_group("enemies"):
				if not (e is Node2D):
					continue
				var c := 0
				for o in get_tree().get_nodes_in_group("enemies"):
					if o is Node2D and (o as Node2D).global_position.distance_to((e as Node2D).global_position) < 70.0:
						c += 1
				if c > bn and (e as Node2D).global_position.distance_to(f.global_position) < 420.0:
					bn = c
					best = e
			var gp := best.global_position if best else f.global_position
			SurvProj.puddle(_host(), id, gp, area, float(r.get("life", 4.0)))
			if run.evolved.has(id):
				for ff in get_tree().get_nodes_in_group("players"):
					if ff is Fighter:
						(ff as Fighter).hp = mini((ff as Fighter).max_hp, (ff as Fighter).hp + 2)
		"drip":
			if not has_node("DripRing"):
				var ring := Node2D.new()
				ring.name = "DripRing"
				ring.z_index = -1
				ring.draw.connect(func() -> void:
					var ar := float(_run().row("abilities", id).get("area", 54)) * _run().area_mul() if _run() else 54.0
					ring.draw_arc(Vector2(0, -6), ar, 0, TAU, 40, Color(0.5, 0.85, 1.0, 0.35), 1.5)
					for k in 8:
						var aa := _t * 0.8 + float(k) * TAU / 8.0
						ring.draw_circle(Vector2(cos(aa), sin(aa) * 0.4) * ar + Vector2(0, -6), 1.6, Color(0.6, 0.9, 1.0, 0.7))
				)
				add_child(ring)
			(get_node("DripRing") as Node2D).queue_redraw()
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and (e as Node2D).global_position.distance_to(f.global_position) < area:
					SurvProj.strike(e, id, self)


## Clipboards: n boards circling the fighter, each slaps what it touches
## (per-enemy cooldown so they don't shred in one frame).
func _tick_orbit(run: SurviveRun, r: Dictionary, delta: float) -> void:
	var n := run.proj_count(id)
	while _orbit.size() < n:
		var b := Node2D.new()
		b.z_index = 6
		var is_bag := id == "bag"
		b.draw.connect(func() -> void:
			if is_bag:
				b.draw_line(Vector2.ZERO, -b.position, Color(0.85, 0.75, 0.3, 0.6), 1.0)
				b.draw_circle(Vector2(0, 2), 8.0, Color(0.16, 0.17, 0.2))
				b.draw_rect(Rect2(Vector2(-3, -8), Vector2(6, 4)), Color(0.25, 0.26, 0.3))
				b.draw_circle(Vector2(-3, 0), 1.5, Color(0.4, 0.42, 0.48))
				return
			b.draw_rect(Rect2(Vector2(-5, -7), Vector2(10, 14)), Color(0.55, 0.36, 0.2))
			b.draw_rect(Rect2(Vector2(-4, -5), Vector2(8, 11)), Color(0.95, 0.94, 0.88))
			b.draw_rect(Rect2(Vector2(-2, -8), Vector2(4, 3)), Color(0.7, 0.72, 0.78))
			for y in [-2.0, 1.0, 4.0]:
				b.draw_line(Vector2(-3, y), Vector2(3, y), Color(0.4, 0.4, 0.45), 0.6)
		)
		add_child(b)
		_orbit.append(b)
	var rad := float(r.get("area", 44)) * run.area_mul()
	for i in _orbit.size():
		var spin := 3.2 if id != "bag" else 1.8
		var a := _t * spin + float(i) * TAU / float(_orbit.size())
		var b := _orbit[i]
		b.visible = i < n
		b.position = Vector2(cos(a) * rad, -30.0 + sin(a) * rad * 0.45)
		b.rotation = a if id != "bag" else 0.0
		if id == "bag":
			b.queue_redraw()
	for k in _hit_cd.keys():
		_hit_cd[k] = float(_hit_cd[k]) - delta
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D) or int(e.get("hp")) <= 0:
			continue
		var key := e.get_instance_id()
		if float(_hit_cd.get(key, 0.0)) > 0.0:
			continue
		for b in _orbit:
			if b.visible and b.global_position.distance_to((e as Node2D).global_position + Vector2(0, -26)) < (24.0 if id == "bag" else 18.0):
				SurvProj.strike(e, id, self)
				_hit_cd[key] = 0.5
				break
