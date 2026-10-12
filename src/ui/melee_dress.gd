class_name MeleeDress
extends Node2D
## The melee mods drawn ON the weapon, in the weapon texture's own texels
## (child of a Sprite2D with centered = false, or of any node drawing the
## texture at its top-left): nails driven through the striking end, tape
## wound round the grip, lead bands near the head, saw teeth on the edge,
## a copper coil that spits sparks. grow[mod] (0..1) animates a mod on:
## nails drop in one by one, tape winds up the handle, bands slide down
## from the tip, teeth rise, the coil wraps. `ghost` previews a mod faintly.

signal tick(mod: String, i: int)

var kind := ""
var mods: Array = []
var ghost := ""
var grow := {}
var _prof: Dictionary = {}
var _last_tick := {}
static var _profiles: Dictionary = {}
static var _meta: Dictionary = {}


func setup(weapon: String, on: Array) -> void:
	kind = weapon
	mods = on.duplicate()
	_prof = profile(weapon)
	queue_redraw()


## Animate `mod` on from nothing (seconds).
func play_in(mod: String, secs := 0.9) -> void:
	if not mods.has(mod):
		mods.append(mod)
	grow[mod] = 0.0
	_last_tick[mod] = -1
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		grow[mod] = v
		var n := _steps(mod)
		var i := int(floor(v * float(n) - 0.35))
		if i > int(_last_tick.get(mod, -1)) and i < n:
			_last_tick[mod] = i
			tick.emit(mod, i)
		queue_redraw()
	, 0.0, 1.0, secs)


func play_out(mod: String, secs := 0.35) -> void:
	if not mods.has(mod):
		return
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		grow[mod] = v
		queue_redraw()
	, float(grow.get(mod, 1.0)), 0.0, secs)
	tw.tween_callback(func() -> void:
		mods.erase(mod)
		grow.erase(mod)
		queue_redraw())


func _process(_delta: float) -> void:
	# The coil's sparks flicker.
	if mods.has("live_wire") or ghost != "":
		queue_redraw()


static func held_meta(weapon: String) -> Dictionary:
	if _meta.is_empty():
		var all: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/held/held.json"))
		if all is Dictionary:
			_meta = all
	return _meta.get(weapon, {}) as Dictionary


## Per column of the weapon art: the top and bottom opaque texel, plus the
## grip and tip from held.json.
static func profile(weapon: String) -> Dictionary:
	if _profiles.has(weapon):
		return _profiles[weapon]
	var out := {"top": PackedInt32Array(), "bot": PackedInt32Array(), "w": 0, "h": 0, "grip": Vector2(8, 8), "tip": Vector2(40, 8)}
	var p := "res://assets/sprites/held/%s.png" % weapon
	if ResourceLoader.exists(p):
		var img := (load(p) as Texture2D).get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var w := img.get_width()
			var h := img.get_height()
			var top := PackedInt32Array()
			var bot := PackedInt32Array()
			top.resize(w)
			bot.resize(w)
			for x in w:
				top[x] = -1
				bot[x] = -1
				for y in h:
					if img.get_pixel(x, y).a > 0.4:
						if top[x] < 0:
							top[x] = y
						bot[x] = y
			out["top"] = top
			out["bot"] = bot
			out["w"] = w
			out["h"] = h
	var m := held_meta(weapon)
	if m.has("grip"):
		out["grip"] = Vector2(float(m["grip"][0]), float(m["grip"][1]))
	if m.has("tip"):
		out["tip"] = Vector2(float(m["tip"][0]), float(m["tip"][1]))
	_profiles[weapon] = out
	return out


func _edge(x: float) -> Vector2:
	var top: PackedInt32Array = _prof.get("top", PackedInt32Array())
	var bot: PackedInt32Array = _prof.get("bot", PackedInt32Array())
	var w := top.size()
	if w == 0:
		return Vector2(4, 12)
	var xi := clampi(int(round(x)), 0, w - 1)
	# Nearest column with art, so gaps in the sprite never throw a nail off.
	for r in 6:
		for s in [xi - r, xi + r]:
			if s >= 0 and s < w and top[s] >= 0:
				return Vector2(top[s], bot[s])
	return Vector2(4, 12)


func _along(f: float) -> float:
	var g: Vector2 = _prof["grip"]
	var t: Vector2 = _prof["tip"]
	return lerpf(g.x, t.x, f)


func _steps(mod: String) -> int:
	match mod:
		"nails":
			return _nail_count()
		"serrated":
			return 6
		"weighted":
			return 2
	return 4


func _nail_count() -> int:
	var g: Vector2 = _prof.get("grip", Vector2.ZERO)
	var t: Vector2 = _prof.get("tip", Vector2(40, 0))
	return clampi(int((t.x - g.x) / 14.0), 3, 7)


func _draw() -> void:
	if _prof.is_empty():
		return
	for m in mods:
		_draw_mod(str(m), float(grow.get(m, 1.0)), 1.0)
	if ghost != "" and not mods.has(ghost):
		# A preview breathes, so it never reads as fitted.
		_draw_mod(ghost, 1.0, 0.22 + 0.18 * sin(Time.get_ticks_msec() * 0.008))


func _draw_mod(m: String, p: float, a: float) -> void:
	match m:
		"nails":
			_nails(p, a)
		"tape_grip":
			_tape(p, a)
		"weighted":
			_weights(p, a)
		"serrated":
			_teeth(p, a)
		"live_wire":
			_coil(p, a)


func _nails(p: float, a: float) -> void:
	var n := _nail_count()
	var steel := Color(0.84, 0.86, 0.9, a)
	var dark := Color(0.36, 0.37, 0.43, a)
	var hole := Color(0.12, 0.08, 0.06, 0.85 * a)
	for i in n:
		var q := clampf(p * float(n) - float(i), 0.0, 1.0)
		if q <= 0.0:
			continue
		var x := _along(0.5 + 0.46 * float(i) / float(maxi(n - 1, 1)))
		var e := _edge(x)
		var up := i % 2 == 0
		var length := clampf((e.y - e.x) * 0.45 + 4.0, 5.0, 9.0)
		# Drops in from outside, then sits: a short overshoot on landing.
		var fall := (1.0 - ease(q, 0.4)) * 16.0
		var dir := -1.0 if up else 1.0
		var base := Vector2(x, e.x + 1.5) if up else Vector2(x, e.y - 0.5)
		base.y += dir * fall
		var point := base + Vector2(0.6 * dir, dir * length)
		var aa := a * minf(1.0, q * 3.0)
		draw_rect(Rect2(base - Vector2(1.5, 0.8), Vector2(3, 1.6)), Color(hole.r, hole.g, hole.b, hole.a * aa / maxf(a, 0.01)))
		draw_line(base, point, Color(dark.r, dark.g, dark.b, aa), 1.6)
		draw_line(base + Vector2(-0.5, 0), point + Vector2(-0.5, 0), Color(steel.r, steel.g, steel.b, aa), 0.8)
		draw_circle(point, 0.55, Color(1, 1, 1, aa))


func _tape(p: float, a: float) -> void:
	var g: Vector2 = _prof["grip"]
	var x0 := maxf(0.0, g.x - 8.0)
	var x1 := g.x + 14.0
	var end := lerpf(x0, x1, p)
	var x := x0
	var k := 0
	while x < end:
		var e := _edge(x + 1.0)
		var c := Color(0.22, 0.23, 0.27, a) if k % 2 == 0 else Color(0.34, 0.35, 0.4, a)
		var w := minf(3.0, end - x)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, e.x - 1.0), Vector2(x + w, e.x - 1.0), Vector2(x + w + 1.5, e.y + 1.0), Vector2(x + 1.5, e.y + 1.0)]), c)
		draw_line(Vector2(x, e.x - 1.0), Vector2(x + w, e.x - 1.0), Color(0.6, 0.62, 0.68, a * 0.8), 0.6)
		x += 3.0
		k += 1
	# The loose end flaps behind the last wrap while it winds.
	if p < 1.0 and p > 0.0:
		var e2 := _edge(end)
		draw_line(Vector2(end, e2.y + 1.0), Vector2(end + 3.0, e2.y + 5.0), Color(0.34, 0.35, 0.4, a), 2.0)


func _weights(p: float, a: float) -> void:
	for j in 2:
		var q := clampf(p * 2.0 - float(j), 0.0, 1.0)
		if q <= 0.0:
			continue
		var fx := 0.7 + 0.14 * float(j)
		var x := _along(fx) + (1.0 - ease(q, 0.3)) * 30.0
		var e := _edge(x)
		var aa := a * q
		var r := Rect2(Vector2(x - 2.5, e.x - 2.0), Vector2(5, e.y - e.x + 4.0))
		draw_rect(r, Color(0.2, 0.21, 0.26, aa))
		draw_rect(Rect2(r.position, Vector2(1.5, r.size.y)), Color(0.48, 0.5, 0.58, aa))
		draw_rect(r, Color(0.08, 0.07, 0.12, aa), false, 0.8)
		draw_circle(Vector2(x + 0.5, (e.x + e.y) * 0.5), 0.9, Color(0.86, 0.75, 0.36, aa))


func _teeth(p: float, a: float) -> void:
	var x0 := _along(0.42)
	var x1 := _along(0.97)
	var n := maxi(int((x1 - x0) / 3.5), 4)
	for i in n:
		var q := clampf(p * float(n) * 0.6 - float(i) * 0.6 + 0.6, 0.0, 1.0)
		if q <= 0.0:
			continue
		var x := lerpf(x0, x1, float(i) / float(n))
		var e := _edge(x + 1.5)
		var hgt := 3.2 * ease(q, 0.5)
		draw_colored_polygon(PackedVector2Array([Vector2(x, e.y), Vector2(x + 3.5, e.y), Vector2(x + 0.8, e.y + hgt)]), Color(0.78, 0.8, 0.86, a))
		draw_line(Vector2(x, e.y), Vector2(x + 0.8, e.y + hgt), Color(1, 1, 1, a * 0.7), 0.5)


func _coil(p: float, a: float) -> void:
	var x0 := _along(0.56)
	var x1 := _along(0.95)
	var steps := 48
	var copper := Color(0.86, 0.48, 0.2, a)
	var shine := Color(1.0, 0.78, 0.5, a)
	var prev := Vector2.ZERO
	for i in int(float(steps) * p) + 1:
		var t := float(i) / float(steps)
		var x := lerpf(x0, x1, t)
		var e := _edge(x)
		var mid := (e.x + e.y) * 0.5
		var half := (e.y - e.x) * 0.5 + 1.5
		var ph := t * TAU * 5.0
		var pt := Vector2(x, mid + sin(ph) * half)
		if i > 0:
			var front := cos(ph) > 0.0
			draw_line(prev, pt, copper if front else Color(0.5, 0.26, 0.1, a), 1.4 if front else 1.0)
			if front:
				draw_line(prev + Vector2(0, -0.4), pt + Vector2(0, -0.4), shine, 0.5)
		prev = pt
	if p >= 1.0:
		# Sparks jump off the coil now and then.
		var tm := Time.get_ticks_msec() / 60
		var rng := RandomNumberGenerator.new()
		rng.seed = tm
		if rng.randf() < 0.55:
			var x := rng.randf_range(x0, x1)
			var e := _edge(x)
			var s := Vector2(x, e.x - 1.0 if rng.randf() < 0.5 else e.y + 1.0)
			var d := Vector2(rng.randf_range(-3, 3), rng.randf_range(-4, 4))
			draw_line(s, s + d, Color(1.0, 0.95, 0.5, a), 0.9)
			draw_line(s + d, s + d + Vector2(d.y * 0.5, -d.x * 0.5), Color(0.6, 0.85, 1.0, a), 0.7)
