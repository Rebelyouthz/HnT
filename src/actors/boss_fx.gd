class_name BossFx
extends Node2D

## What a boss pattern draws in the world: red danger zones that fill up as
## the blow comes (band / circle / marker), falling things, boss projectiles
## and shockwaves. Damage is dealt here so every zone hits exactly when it
## finishes filling, never before.

var kind := "band"           # band, circle, drop, shot, wave, ring
var rect := Rect2()          # band: world rect
var radius := 40.0           # circle / drop / ring
var fill_t := 0.8            # seconds until it strikes
var dmg_kind := "crush"
var boss: Node2D
var vel := Vector2.ZERO
var look := "paper"
var lane_y := 480.0
var _t := 0.0
var _struck := false
var _hit: Array[Node] = []
var _life := 0.0


static func zone_band(host: Node, r: Rect2, secs: float, by: Node2D, dk := "crush") -> BossFx:
	var f := BossFx.new()
	f.kind = "band"
	f.rect = r
	f.fill_t = secs
	f.boss = by
	f.dmg_kind = dk
	f.z_index = -1
	host.add_child(f)
	return f


static func zone_circle(host: Node, at: Vector2, r: float, secs: float, by: Node2D, dk := "crush") -> BossFx:
	var f := BossFx.new()
	f.kind = "circle"
	f.global_position = at
	f.radius = r
	f.fill_t = secs
	f.boss = by
	f.dmg_kind = dk
	f.z_index = -1
	host.add_child(f)
	return f


static func drop(host: Node, at: Vector2, secs: float, by: Node2D, look_: String) -> BossFx:
	var f := BossFx.new()
	f.kind = "drop"
	f.global_position = at
	f.radius = 30.0
	f.fill_t = secs
	f.boss = by
	f.look = look_
	f.dmg_kind = "heavy"
	f.z_index = 3
	host.add_child(f)
	return f


static func shot(host: Node, at: Vector2, v: Vector2, by: Node2D, look_: String, ly: float) -> BossFx:
	var f := BossFx.new()
	f.kind = "shot"
	f.global_position = at
	f.vel = v
	f.boss = by
	f.look = look_
	f.lane_y = ly
	f.dmg_kind = "heavy"
	f.fill_t = 0.0
	f.z_index = 4
	host.add_child(f)
	return f


static func wave(host: Node, at: Vector2, dir: float, by: Node2D) -> BossFx:
	var f := BossFx.new()
	f.kind = "wave"
	f.global_position = at
	f.vel = Vector2(dir * 300.0, 0)
	f.lane_y = at.y
	f.boss = by
	f.dmg_kind = "crush"
	f.z_index = 2
	host.add_child(f)
	return f


func _process(delta: float) -> void:
	_t += delta
	match kind:
		"band", "circle":
			if not _struck and _t >= fill_t:
				_struck = true
				_strike()
			if _t >= fill_t + 0.18:
				queue_free()
		"drop":
			if not _struck and _t >= fill_t:
				_struck = true
				_strike()
				Juice.pulse_shake(4.0)
				Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", randf_range(0.7, 0.9), -6.0)
				var blood := get_tree().get_first_node_in_group("blood_sim")
				if blood and blood.has_method("dust"):
					blood.dust(global_position)
			if _t >= fill_t + 0.5:
				queue_free()
		"shot":
			global_position += vel * delta
			_life += delta
			_touch(18.0, 22.0)
			if _life > 3.0:
				queue_free()
		"wave":
			global_position += vel * delta
			_life += delta
			_touch(24.0, 18.0)
			if _life > 2.4:
				queue_free()
	queue_redraw()


func _players() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			out.append(n)
	return out


func _strike() -> void:
	for f: Fighter in _players():
		var p := f.global_position
		var inside := false
		if kind == "band":
			inside = rect.grow(4.0).has_point(p) and f.hop >= -24.0
		else:
			var d := (p - global_position) / Vector2(radius, radius * 0.42)
			inside = d.length() <= 1.0 and f.hop >= -30.0
		if inside:
			f.take_hit(dmg_kind, boss if is_instance_valid(boss) else self)


func _touch(rx: float, ry: float) -> void:
	for f: Fighter in _players():
		if f in _hit:
			continue
		var p := f.global_position
		var y_ref := lane_y if kind == "shot" else global_position.y
		if absf(p.x - global_position.x) < rx and absf(p.y - y_ref) < ry and f.hop >= -26.0:
			_hit.append(f)
			f.take_hit(dmg_kind, boss if is_instance_valid(boss) else self)
			if kind == "shot":
				queue_free()


func _draw() -> void:
	var k := clampf(_t / maxf(0.01, fill_t), 0.0, 1.0)
	var flash := 0.5 + 0.5 * sin(_t * 26.0)
	match kind:
		"band":
			var r := Rect2(rect.position - global_position, rect.size).abs()
			draw_rect(r, Color(0.9, 0.05, 0.04, 0.10 + 0.08 * flash))
			# The charge fills the lane from the boss's side outwards.
			var dir := 1.0
			if boss != null and is_instance_valid(boss):
				dir = 1.0 if boss.global_position.x - global_position.x < r.get_center().x else -1.0
			var fw := r.size.x * k
			var fr := Rect2(r.position if dir > 0.0 else Vector2(r.end.x - fw, r.position.y), Vector2(fw, r.size.y))
			draw_rect(fr, Color(1.0, 0.18, 0.08, 0.24))
			# Chevrons racing along the lane in the charge direction.
			var cy := r.get_center().y
			var h := minf(r.size.y * 0.32, 14.0)
			var step := 34.0
			var off := fmod(_t * 160.0, step)
			var x := 0.0
			while x < r.size.x + step:
				var px := r.position.x + (x + off if dir > 0.0 else r.size.x - x - off)
				if px > r.position.x + 6.0 and px < r.end.x - 6.0:
					var a := 0.35 + 0.45 * flash
					draw_polyline(PackedVector2Array([Vector2(px - dir * 8.0, cy - h), Vector2(px, cy), Vector2(px - dir * 8.0, cy + h)]), Color(1.0, 0.75, 0.55, a), 2.5)
				x += step
			# Corner brackets instead of a flat box outline.
			var c := Color(1.0, 0.3, 0.18, 0.95)
			var L := 12.0
			for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
				var sx := 1.0 if corner.x <= r.get_center().x else -1.0
				var sy := 1.0 if corner.y <= r.get_center().y else -1.0
				draw_line(corner, corner + Vector2(L * sx, 0), c, 2.0)
				draw_line(corner, corner + Vector2(0, L * sy), c, 2.0)
			draw_rect(r, Color(1.0, 0.25, 0.15, 0.35), false, 1.0)
			if _struck:
				draw_rect(r, Color(1, 0.9, 0.7, 0.6))
		"circle":
			_ellipse(radius, Color(1.0, 0.1, 0.08, 0.12 + 0.1 * flash), true)
			_ellipse(radius * k, Color(1.0, 0.25, 0.1, 0.3), true)
			_ellipse(radius, Color(1.0, 0.3, 0.15, 0.9), false)
			if _struck:
				_ellipse(radius * 1.15, Color(1, 0.9, 0.7, 0.7), true)
		"drop":
			if not _struck:
				_ellipse(radius * (0.4 + 0.6 * k), Color(0, 0, 0, 0.45), true)
				_ellipse(radius, Color(1.0, 0.25, 0.1, 0.8 * flash), false)
				var y := -320.0 * (1.0 - k * k)
				_thing(Vector2(0, y))
			else:
				_thing(Vector2.ZERO)
				_ellipse(radius * 1.2 * clampf((_t - fill_t) * 6.0, 0, 1), Color(0.9, 0.85, 0.75, 0.5 * (1.0 - clampf((_t - fill_t) * 2.0, 0, 1))), true)
		"shot":
			var sy := lane_y - global_position.y
			_ellipse_at(Vector2(0, sy), 8.0, Color(0, 0, 0, 0.35))
			_thing(Vector2.ZERO, 0.55)
		"wave":
			for i in 4:
				var off := Vector2(-signf(vel.x) * float(i) * 10.0, 0)
				draw_line(off + Vector2(0, -8 - 10 * (3 - i)), off + Vector2(0, 6), Color(1.0, 0.75, 0.45, 0.9 - 0.2 * float(i)), 3.0)
			_ellipse_at(Vector2.ZERO, 26.0, Color(1.0, 0.6, 0.3, 0.35))


func _ellipse(r: float, c: Color, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.42))
	if filled:
		draw_colored_polygon(pts, c)
	else:
		pts.append(pts[0])
		draw_polyline(pts, c, 1.5)


func _ellipse_at(at: Vector2, r: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		pts.append(at + Vector2(cos(a) * r, sin(a) * r * 0.42))
	draw_colored_polygon(pts, c)


## The falling things and projectiles, drawn per boss flavour.
func _thing(at: Vector2, s: float = 1.0) -> void:
	var spin := _t * 9.0
	match look:
		"invoice", "paper", "ticket":
			var col := Color(0.95, 0.93, 0.85) if look != "ticket" else Color(1.0, 0.85, 0.3)
			var tr := Transform2D(spin, at)
			var pts := PackedVector2Array([Vector2(-7, -9), Vector2(7, -9), Vector2(7, 9), Vector2(-7, 9)])
			draw_colored_polygon(tr * pts, col)
			draw_line(tr * Vector2(-4, -4), tr * Vector2(4, -4), Color(0.8, 0.1, 0.1), 1.0)
			draw_line(tr * Vector2(-4, 0), tr * Vector2(4, 0), Color(0.3, 0.3, 0.35), 1.0)
		"boot":
			draw_rect(Rect2(at + Vector2(-16, -26) * s, Vector2(32, 26) * s), Color(0.95, 0.75, 0.1))
			draw_rect(Rect2(at + Vector2(-10, -20) * s, Vector2(20, 14) * s), Color(0.12, 0.12, 0.14))
			draw_circle(at + Vector2(0, -13) * s, 4.0 * s, Color(0.95, 0.75, 0.1))
		"safe":
			draw_rect(Rect2(at + Vector2(-20, -36) * s, Vector2(40, 36) * s), Color(0.22, 0.24, 0.28))
			draw_rect(Rect2(at + Vector2(-20, -36) * s, Vector2(40, 36) * s), Color(0.05, 0.05, 0.06), false, 2.0)
			draw_circle(at + Vector2(4, -18) * s, 6.0 * s, Color(0.75, 0.7, 0.5))
		_:
			draw_rect(Rect2(at + Vector2(-18, -30) * s, Vector2(36, 30) * s), Color(0.55, 0.38, 0.2))
			draw_line(at + Vector2(-18, -30) * s, at + Vector2(18, 0) * s, Color(0.3, 0.2, 0.1), 2.0)
