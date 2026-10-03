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
	if id == "clipboards":
		_tick_orbit(run, r, delta)
		return
	_cd -= delta
	if _cd > 0.0:
		return
	_cd = float(r.get("cd", 1.5)) * run.cd_mul()
	_fire(run, r, f)


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
	var area := float(r.get("area", 40)) * run.area_mul()
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
		b.draw.connect(func() -> void:
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
		var a := _t * 3.2 + float(i) * TAU / float(_orbit.size())
		var b := _orbit[i]
		b.visible = i < n
		b.position = Vector2(cos(a) * rad, -30.0 + sin(a) * rad * 0.45)
		b.rotation = a
	for k in _hit_cd.keys():
		_hit_cd[k] = float(_hit_cd[k]) - delta
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D) or int(e.get("hp")) <= 0:
			continue
		var key := e.get_instance_id()
		if float(_hit_cd.get(key, 0.0)) > 0.0:
			continue
		for b in _orbit:
			if b.visible and b.global_position.distance_to((e as Node2D).global_position + Vector2(0, -26)) < 18.0:
				SurvProj.strike(e, id, self)
				_hit_cd[key] = 0.5
				break
