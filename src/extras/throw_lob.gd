class_name ThrowLob
extends Node2D

## Throwables (SHOOT + up on the stick, story streets): lobbed in an arc from
## the hand, they spin, bounce once and go off where they land.
##   GRENADE    the old receipt with a timer: a blast that files a crowd
##   MOLOTOV    a burning bottle: sets everyone near alight and leaves a
##              patch of fire on the street
##   FLASHBANG  a white-out: everyone close stands stunned for 2.5 s
##   BRICK      cheap and honest: one thug, very hard
##   TEARGAS    a cloud that keeps thugs choking (slow, small damage)

const KINDS := {
	"grenade": {"title": "GRENADE", "icon": "cur_chest", "col": Color(0.55, 0.65, 0.3)},
	"molotov": {"title": "MOLOTOV", "icon": "card_molotov_lob", "col": Color(1.0, 0.55, 0.15)},
	"flashbang": {"title": "FLASHBANG", "icon": "card_air_horn", "col": Color(0.95, 0.95, 1.0)},
	"brick": {"title": "BRICK", "icon": "gear_box", "col": Color(0.72, 0.36, 0.25)},
	"teargas": {"title": "TEARGAS", "icon": "card_smoke_bomb", "col": Color(0.7, 0.85, 0.55)},
}

var kind := "grenade"
var by: Fighter
var from := Vector2.ZERO
var to := Vector2.ZERO
var _t := 0.0
var _dur := 0.55
var _spin := 0.0
var _landed := false
var _cloud := 0.0


## Throws `k` from fighter `f`.
static func lob(f: Fighter, k: String) -> void:
	var n := ThrowLob.new()
	n.kind = k
	n.by = f
	n.from = f.global_position + Vector2(float(f.facing) * 18.0, 0)
	var dist := 230.0 if k != "brick" else 190.0
	# Aim at the nearest thug ahead if one is in range.
	var best := 9999.0
	for e in f.get_tree().get_nodes_in_group("enemies"):
		if e is Punk and (e as Punk).hp > 0:
			var d := (e as Punk).global_position - f.global_position
			if signf(d.x) == float(f.facing) and absf(d.x) < 300.0 and absf(d.y) < 60.0 and d.length() < best:
				best = d.length()
				n.to = (e as Punk).global_position
	if best >= 9999.0:
		n.to = f.global_position + Vector2(float(f.facing) * dist, 0)
	n._dur = clampf(n.from.distance_to(n.to) / 420.0, 0.3, 0.7)
	n.z_index = 4
	f.get_parent().add_child(n)
	Mixer.play_sfx("res://assets/audio/ui/whoosh.wav", 1.1, -4.0)


func _process(delta: float) -> void:
	if _landed:
		if kind == "teargas":
			_gas(delta)
		queue_redraw()
		return
	_t += delta
	_spin += delta * 14.0
	var k := clampf(_t / _dur, 0.0, 1.0)
	global_position = from.lerp(to, k)
	queue_redraw()
	if k >= 1.0:
		_land()


func _arc_y() -> float:
	var k := clampf(_t / _dur, 0.0, 1.0)
	return -4.0 * 46.0 * k * (1.0 - k) - 34.0 * (1.0 - k)


func _land() -> void:
	_landed = true
	var at := global_position
	match kind:
		"grenade":
			_hurt(90.0, "finish")
			Juice.boom(at)
			Juice.kill_burst(at + Vector2(0, -20), "finish")
			Juice.shout("BOUNDARY")
			Juice.pulse_shake(8.0)
			ArtFx.spawn(get_parent(), at, "ring", Color(1.0, 0.7, 0.3), 110.0, 0.35)
			queue_free()
		"molotov":
			_hurt(70.0, "heavy")
			for e in _near(80.0):
				(e as Punk).ignite(4.0, by.role if by else "son")
			FireFx.ground(get_parent(), at, 4.0)
			FireFx.ground(get_parent(), at + Vector2(-28, 4), 3.2)
			FireFx.ground(get_parent(), at + Vector2(26, -3), 3.6)
			Mixer.play_sfx("res://assets/audio/sfx/glass_break.ogg", 1.1, -2.0)
			Juice.pulse_shake(4.0)
			queue_free()
		"flashbang":
			for e in _near(170.0):
				var p := e as Punk
				p.recover = maxf(p.recover, 2.5)
				p.telegraph = 0.0
				Juice.popup_number(p.global_position + Vector2(0, -100), "STUNNED", Color(0.9, 0.95, 1.0))
			if BrawlMore.me != null and is_instance_valid(BrawlMore.me):
				BrawlMore.me.impact(1.0)
			ArtFx.spawn(get_parent(), at, "ring", Color(1, 1, 1), 170.0, 0.3)
			Mixer.play_sfx("res://assets/audio/boom.wav", 1.7, -4.0)
			Juice.shout("FLASHBANG")
			queue_free()
		"brick":
			var hit := false
			for e in _near(46.0):
				(e as Punk).take_hit("throw", by)
				hit = true
				break
			Mixer.play_sfx("res://assets/audio/hit_heavy.wav" if hit else "res://assets/audio/block.wav", 0.8, -2.0)
			if hit:
				Juice.hitstop(4)
				Juice.popup_number(at + Vector2(0, -90), "BRICKED", Color(0.9, 0.5, 0.35))
			queue_free()
		"teargas":
			_cloud = 4.0
			Mixer.play_sfx("res://assets/audio/sfx/smoke_puff.ogg", 0.7, -2.0)


func _gas(delta: float) -> void:
	_cloud -= delta
	if _cloud <= 0.0:
		queue_free()
		return
	if fmod(_cloud, 0.6) < delta:
		for e in _near(95.0):
			var p := e as Punk
			p.recover = maxf(p.recover, 0.5)
			if randf() < 0.5:
				p.take_hit("skill", by)


func _near(r: float) -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Punk and (e as Punk).hp > 0:
			var d := (e as Punk).global_position - global_position
			if Vector2(d.x, d.y * 2.0).length() < r:
				out.append(e)
	return out


func _hurt(r: float, k: String) -> void:
	for e in _near(r):
		(e as Punk).take_hit(k, by)


func _draw() -> void:
	var col: Color = KINDS[kind]["col"]
	if _landed:
		if kind == "teargas":
			var a := clampf(_cloud / 4.0, 0.0, 1.0)
			for i in 9:
				var ang := float(i) * TAU / 9.0 + _cloud * 0.6
				var p := Vector2.from_angle(ang) * Vector2(60, 22) * (0.6 + 0.4 * sin(_cloud * 2.0 + float(i)))
				draw_circle(p + Vector2(0, -16), 26.0, Color(col.r, col.g, col.b, 0.28 * a))
		return
	# Shadow on the street, then the spinning throwable up in its arc.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, _arc_y()), _spin, Vector2.ONE)
	match kind:
		"molotov":
			draw_rect(Rect2(-3, -7, 6, 12), Color(0.3, 0.55, 0.3))
			draw_rect(Rect2(-1.5, -12, 3, 5), Color(0.9, 0.85, 0.7))
			draw_circle(Vector2(0, -13), 3.0 + sin(_t * 30.0), Color(1.0, 0.6, 0.15))
		"flashbang":
			draw_rect(Rect2(-3, -6, 6, 12), Color(0.75, 0.78, 0.85))
			draw_rect(Rect2(-3, -2, 6, 2), Color(0.3, 0.32, 0.4))
		"brick":
			draw_rect(Rect2(-7, -4, 14, 8), col)
			draw_rect(Rect2(-7, -4, 14, 2), col.lightened(0.25))
		"teargas":
			draw_rect(Rect2(-3, -7, 6, 14), Color(0.45, 0.5, 0.3))
			draw_circle(Vector2(0, -8), 3.0, Color(0.85, 0.9, 0.7, 0.6))
		_:
			draw_circle(Vector2.ZERO, 5.0, Color(0.35, 0.42, 0.22))
			draw_rect(Rect2(-1, -8, 2, 3), Color(0.7, 0.7, 0.72))
