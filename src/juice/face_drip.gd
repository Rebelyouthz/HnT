class_name FaceDrip
extends Node2D

## Blood from the face after a blow to the head: a thin run from the nose
## and the corner of the mouth that keeps dripping onto the street for a
## few seconds, and a spray of spit and blood off the lips on a hard hit.
## One per thug; more head hits make it run longer and heavier.

var victim: Node2D
var anim: AnimatedSprite2D
var _left := 0.0
var _drop_t := 0.0
var _heavy := 0.0
var _drops: Array = []   # [pos, vel, life, size, color]
var _run := 0.0          # length of the trickle from nose to chin (px)
var _side := 1.0


static func bleed(who: Node2D, art: AnimatedSprite2D, dir: float, power: float) -> void:
	if who == null or art == null or FamilyProfile.less_gore():
		return
	var host := who.get_parent()
	if host == null:
		return
	var d: FaceDrip = who.get_meta("face_drip") if who.has_meta("face_drip") else null
	if d == null or not is_instance_valid(d):
		d = FaceDrip.new()
		d.victim = who
		d.anim = art
		d.z_index = 30
		host.add_child(d)
		who.set_meta("face_drip", d)
	d._left = minf(6.0, d._left + 1.6 + 2.4 * power)
	d._heavy = minf(1.0, d._heavy + 0.25 + 0.4 * power)
	d._side = -dir
	if power >= 0.55:
		d._spit(dir, power)


## Where nose and mouth are on screen right now.
func _mouth() -> Vector2:
	if anim == null or not is_instance_valid(anim):
		return victim.global_position + Vector2(0, -70)
	var h := BloodSim.head_of(anim)
	return anim.to_global(Vector2(h.x + h.z * 0.35 * _side, h.y + h.z * 0.55))


func _spit(dir: float, power: float) -> void:
	var at := _mouth()
	for i in int(6 + 10 * power):
		var spit := randf() < 0.35
		var v := Vector2(dir * randf_range(60.0, 220.0) * (0.6 + power), randf_range(-160.0, -30.0))
		var c := Color(0.92, 0.88, 0.86, 0.85) if spit else Color(0.62, 0.03, 0.04, 0.95)
		_drops.append([at, v, randf_range(0.4, 0.9), randf_range(0.8, 2.0), c])


func _process(delta: float) -> void:
	if victim == null or not is_instance_valid(victim) or victim.is_queued_for_deletion():
		if _drops.is_empty():
			queue_free()
			return
	else:
		_left -= delta
		if _left > 0.0:
			_run = minf(10.0 + 8.0 * _heavy, _run + delta * 14.0)
			_drop_t -= delta
			if _drop_t <= 0.0:
				_drop_t = randf_range(0.18, 0.45) / (0.6 + _heavy)
				var at := _mouth() + Vector2(randf_range(-1.5, 1.5), _run * 0.6)
				_drops.append([at, Vector2(randf_range(-8.0, 8.0), 20.0), 1.2, randf_range(0.9, 1.7), Color(0.55, 0.02, 0.03, 0.95)])
		else:
			_run = maxf(0.0, _run - delta * 6.0)
	var floor_y := victim.global_position.y if victim != null and is_instance_valid(victim) else 9999.0
	for d in _drops:
		d[1].y += 520.0 * delta
		d[0] += d[1] * delta
		d[2] -= delta
		if d[0].y >= floor_y:
			d[0].y = floor_y
			d[1] = Vector2.ZERO
	_drops = _drops.filter(func(d: Array) -> bool: return d[2] > 0.0)
	queue_redraw()


func _draw() -> void:
	if _run > 0.5 and victim != null and is_instance_valid(victim):
		var m := to_local(_mouth())
		draw_line(m, m + Vector2(0.6, _run), Color(0.5, 0.02, 0.03, 0.9), 1.4)
		draw_line(m + Vector2(-2.0, 2.0), m + Vector2(-1.6, 2.0 + _run * 0.7), Color(0.45, 0.02, 0.03, 0.8), 1.0)
	for d in _drops:
		var c: Color = d[4]
		c.a *= clampf(d[2] * 2.0, 0.0, 1.0)
		draw_circle(to_local(d[0]), d[3], c)
