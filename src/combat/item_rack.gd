class_name ItemRack
extends Node

## Runs the ITEM cards of a night (data/cards.json "kind"): passives as
## multipliers, auto-weapons and companions on their own clocks, actives and
## the slingshot on SHOOT with empty hands. Levels come from RunState.card_lv.

static var dmg_k := 1.0
static var speed_k := 1.0
static var chi_k := 1.0
static var knife_pierce := false

var _lv := {}
var _t := {}
var _drone: Dictionary = {}
var _orbit: Dictionary = {}
var _cats: Dictionary = {}
var _active_cd := {}


func _ready() -> void:
	add_to_group("item_rack")
	dmg_k = 1.0
	speed_k = 1.0
	chi_k = 1.0
	knife_pierce = false


static func rack(tree: SceneTree) -> ItemRack:
	return tree.get_first_node_in_group("item_rack") as ItemRack


func lv(id: String) -> int:
	return int(_lv.get(id, 0))


## RunState.take_card calls this with the new level.
func on_card(id: String, level: int) -> void:
	_lv[id] = level
	match id:
		"protein_shake":
			dmg_k = 1.0 + 0.12 * float(level)
		"running_shoes":
			speed_k = 1.0 + 0.08 * float(level)
		"chi_battery":
			chi_k = 1.0 + 0.35 * float(level)
		"thick_hoodie":
			for f in _players():
				f.max_hp += 10
				f.hp = mini(f.max_hp, f.hp + 10)
		"knife_belt":
			knife_pierce = level >= 3
			for f in _players():
				f.knives_max += 3
				f.knives = mini(f.knives_max, f.knives + 3)


func _players() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			out.append(n)
	return out


func _nearest(f: Fighter, reach: float, depth := 40.0) -> Punk:
	var best: Punk = null
	var bd := reach
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and (n as Punk).hp > 0:
			var e: Punk = n
			if absf(e.global_position.y - f.global_position.y) > depth:
				continue
			var d := absf(e.global_position.x - f.global_position.x)
			if d < bd:
				bd = d
				best = e
	return best


func _clock(key: String, every: float, delta: float) -> bool:
	_t[key] = float(_t.get(key, every * 0.5)) - delta
	if float(_t[key]) <= 0.0:
		_t[key] = every
		return true
	return false


func _physics_process(delta: float) -> void:
	if _lv.is_empty():
		return
	for f in _players():
		var key := str(f.get_instance_id())
		var host := f.get_parent()
		# PAPERBOY DRONE
		var pd := lv("paper_drone")
		if pd > 0:
			var d: Buddy = _buddy(_drone, key + "p", f, "drone", Color(0.9, 0.9, 0.95))
			if _clock(key + "pd", [2.2, 1.8, 1.4][pd - 1], delta):
				var e := _nearest(f, 320.0)
				if e:
					for i in (2 if pd >= 3 else 1):
						var s := _shot(f, d.global_position + Vector2(0, 50), e, 6 + 2 * pd, "")
						s.global_position.y += float(i) * 6.0
		# REPO DRONE
		var rd := lv("repo_drone")
		if rd > 0:
			var d2: Buddy = _buddy(_drone, key + "r", f, "drone", Color(0.4, 0.8, 1.0))
			d2.offset = Vector2(26, -78)
			if _clock(key + "rd", [2.5, 2.0, 1.5][rd - 1], delta):
				var e := _nearest(f, 240.0)
				if e:
					ArtFx.bolt(host, d2.global_position, e.global_position + Vector2(0, -36), Elements.color("storm"), 0.25)
					ArtMoves.strike(f, e, 5, "stun", "storm")
					e.recover = maxf(e.recover, 0.6 + 0.3 * float(rd))
					Mixer.play_sfx("res://assets/audio/zap.wav", 1.4, -8.0)
					if rd >= 3:
						for n in get_tree().get_nodes_in_group("enemies"):
							if n is Punk and n != e and (n as Punk).global_position.distance_to(e.global_position) < 120.0:
								ArtFx.bolt(host, e.global_position + Vector2(0, -36), (n as Punk).global_position + Vector2(0, -36), Elements.color("storm"), 0.25)
								ArtMoves.strike(f, n, 4, "stun", "storm")
								break
		# STAPLER ORBIT
		var so := lv("stapler_orbit")
		if so > 0:
			_spin_orbit(f, key, so, delta)
		# MOLOTOV DAD
		var mo := lv("molotov_lob")
		if mo > 0 and _clock(key + "mo", [6.0, 5.0, 4.0][mo - 1], delta):
			var e := _nearest(f, 280.0)
			if e:
				Lob.throw(host, f, f.global_position + Vector2(0, -50), e.global_position, 40.0 + 12.0 * float(mo))
		# STRAY CAT
		var sc := lv("stray_cat")
		if sc > 0:
			for i in (2 if sc >= 3 else 1):
				var c: Buddy = _buddy(_cats, key + "c%d" % i, f, "cat", Color(0.08, 0.08, 0.1))
				c.offset = Vector2(-34.0 - 18.0 * float(i), 0)
				c.on_ground = true
				if c.task == "" and _clock(key + "cat%d" % i, [3.0, 2.2, 2.2][sc - 1], delta):
					var e := _nearest(f, 240.0)
					if e:
						c.pounce(e, 8 + 2 * sc)
		# PIGEON SQUAD
		var pg := lv("pigeon_squad")
		if pg > 0 and _clock(key + "pg", [6.0, 5.0, 4.0][pg - 1], delta):
			Flock.sweep(host, f, 4 + 3 * pg, 6 + 2 * pg)


func _buddy(store: Dictionary, key: String, f: Fighter, look: String, col: Color) -> Buddy:
	var b: Buddy = store.get(key)
	if b == null or not is_instance_valid(b):
		b = Buddy.new()
		b.owner_f = f
		b.look = look
		b.col = col
		b.offset = Vector2(-22, -74) if look == "drone" else Vector2(-34, 0)
		f.get_parent().add_child(b)
		b.global_position = f.global_position + b.offset
		store[key] = b
	return b


func _shot(f: Fighter, from: Vector2, e: Punk, dmg: int, elem: String) -> ElementShot:
	var s := ElementShot.new()
	s.by = f
	s.style = "ball"
	s.elem = elem
	s.dir = 1 if e.global_position.x > from.x else -1
	s.speed = 520.0
	s.r = 4.0
	s.h = from.y - e.global_position.y
	s.dmg = dmg
	s.fx = ""
	s.life = 0.9
	s.global_position = Vector2(from.x, e.global_position.y)
	f.get_parent().add_child(s)
	return s


func _spin_orbit(f: Fighter, key: String, so: int, delta: float) -> void:
	var o: Orbit = _orbit.get(key)
	if o == null or not is_instance_valid(o):
		o = Orbit.new()
		o.f = f
		f.add_child(o)
		_orbit[key] = o
	o.n = so
	o.radius = 34.0 + 6.0 * float(so)


## SHOOT with empty hands: an active item if one is ready, else the
## slingshot. Returns true when it used the press.
static func shoot(f: Fighter) -> bool:
	var r := rack(f.get_tree())
	if r == null:
		return false
	return r._use_active(f) or r._sling(f)


func _use_active(f: Fighter) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	var key := str(f.get_instance_id())
	var ah := lv("air_horn")
	if ah > 0 and now >= float(_active_cd.get(key + "ah", 0.0)):
		_active_cd[key + "ah"] = now + [14.0, 12.0, 10.0][ah - 1]
		ArtFx.spawn(f.get_parent(), f.global_position, "ring", UiKit.GOLD, 170.0, 0.45)
		ArtFx.spawn(f.get_parent(), f.global_position + Vector2(0, -50), "burst", UiKit.GOLD, 50.0, 0.3)
		Juice.shout("HONK")
		Juice.pulse_shake(5.0)
		Mixer.play_sfx("res://assets/audio/siren.wav", 1.6, -2.0)
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk and (n as Punk).global_position.distance_to(f.global_position) < 170.0:
				var e: Punk = n
				ArtMoves.strike(f, e, 2, "knockdown" if ah >= 3 else "stun", "")
				e.recover = maxf(e.recover, [1.2, 1.6, 2.0][ah - 1])
				e.telegraph = 0.0
		return true
	var sb := lv("smoke_bomb")
	if sb > 0 and now >= float(_active_cd.get(key + "sb", 0.0)):
		_active_cd[key + "sb"] = now + [18.0, 15.0, 12.0][sb - 1]
		f.invuln = maxi(f.invuln, 150)
		for i in 6:
			ArtFx.spawn(f.get_parent(), f.global_position + Vector2(randf_range(-40, 40), randf_range(-6, 6)), "ring", Color(0.7, 0.72, 0.75), 60.0 + 20.0 * randf(), 1.2 + 0.4 * randf())
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk:
				(n as Punk).telegraph = 0.0
				(n as Punk).recover = maxf((n as Punk).recover, 1.5)
		if sb >= 3:
			f.hp = mini(f.max_hp, f.hp + 8)
		Juice.shout("POOF")
		Mixer.play_sfx("res://assets/audio/sfx/smoke_puff.ogg", 1.0, -2.0)
		return true
	return false


func _sling(f: Fighter) -> bool:
	var sl := lv("slingshot")
	if sl <= 0 or f.attack_cd > 0:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var key := str(f.get_instance_id())
	if now < float(_active_cd.get(key + "sl", 0.0)):
		return true
	_active_cd[key + "sl"] = now + [0.7, 0.6, 0.45][sl - 1]
	var s := ElementShot.new()
	s.by = f
	s.style = "ball"
	s.elem = ""
	s.dir = f.facing
	s.speed = 640.0
	s.r = 3.0
	s.h = -40.0
	s.dmg = 7 + 2 * sl
	s.fx = ""
	s.life = 0.7
	s.global_position = f.global_position + Vector2(20.0 * float(f.facing), 1)
	f.get_parent().add_child(s)
	f.attack_cd = 10
	Mixer.play_sfx("res://assets/audio/sfx/whiff_punch.ogg", 1.8, -6.0)
	return true


# --- small drawn helpers -------------------------------------------------------

## A drone hovering by the shoulder, or a street cat that follows and pounces.
class Buddy extends Node2D:
	var owner_f: Fighter
	var look := "drone"
	var col := Color.WHITE
	var offset := Vector2.ZERO
	var on_ground := false
	var task := ""
	var _target: Punk
	var _dmg := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		scale = Vector2(1.7, 1.7)

	func pounce(e: Punk, dmg: int) -> void:
		task = "go"
		_target = e
		_dmg = dmg

	func _physics_process(delta: float) -> void:
		_t += delta
		if owner_f == null or not is_instance_valid(owner_f):
			queue_free()
			return
		if task == "go":
			if _target == null or not is_instance_valid(_target) or _target.hp <= 0:
				task = ""
			else:
				var to := _target.global_position
				global_position = global_position.move_toward(to, 460.0 * delta)
				if global_position.distance_to(to) < 14.0:
					ArtMoves.strike(owner_f, _target, _dmg, "", "")
					if is_instance_valid(_target) and _target.hp > 0:
						_target.staples = maxi(_target.staples, 2)
					Mixer.play_sfx("res://assets/audio/sfx/melee_knife.ogg", 1.6, -8.0)
					task = ""
		else:
			var want := owner_f.global_position + Vector2(offset.x * float(owner_f.facing), offset.y)
			if not on_ground:
				want.y += sin(_t * 4.0) * 3.0
			global_position = global_position.lerp(want, 1.0 - exp(-6.0 * delta))
		queue_redraw()

	func _draw() -> void:
		if look == "drone":
			draw_rect(Rect2(-8, -2, 16, 4), Color(0.18, 0.18, 0.2))
			draw_rect(Rect2(-3, -5, 6, 4), col)
			var spin := 6.0 * absf(sin(_t * 40.0))
			draw_line(Vector2(-12 - spin, -4), Vector2(-4 + spin, -4), Color(0.8, 0.8, 0.85, 0.7), 1.0)
			draw_line(Vector2(4 - spin, -4), Vector2(12 + spin, -4), Color(0.8, 0.8, 0.85, 0.7), 1.0)
			var blink := 1.0 if fmod(_t, 0.8) < 0.15 else 0.25
			draw_circle(Vector2(0, 2), 1.5, Color(1, 0.2, 0.2, blink))
			draw_set_transform(Vector2(0, 74.0 / 1.7), 0.0, Vector2(1.0, 0.3))
			draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.25))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var bob := absf(sin(_t * (14.0 if task == "go" else 5.0))) * 2.0
			var fx := -1.0 if (task == "go" and _target and is_instance_valid(_target) and _target.global_position.x < global_position.x) or (task == "" and owner_f.facing < 0) else 1.0
			draw_set_transform(Vector2(0, -bob), 0.0, Vector2(fx, 1.0))
			draw_colored_polygon(PackedVector2Array([Vector2(-9, -6), Vector2(6, -7), Vector2(9, -2), Vector2(8, 0), Vector2(-9, 0)]), col)
			draw_colored_polygon(PackedVector2Array([Vector2(6, -7), Vector2(12, -9), Vector2(13, -14), Vector2(10, -11), Vector2(8, -13), Vector2(7, -9)]), col)
			draw_line(Vector2(-9, -5), Vector2(-14, -12), col, 2.0)
			draw_circle(Vector2(10, -10), 0.9, Color(1.0, 0.85, 0.2))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Staplers circling the hero at chest height.
class Orbit extends Node2D:
	var f: Fighter
	var n := 1
	var radius := 40.0
	var _a := 0.0
	var _cd := {}

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		_a += delta * 4.2
		var now := Time.get_ticks_msec() / 1000.0
		for i in n:
			var p := _pos(i)
			var wp := global_position + p
			for m in get_tree().get_nodes_in_group("enemies"):
				if m is Punk and (m as Punk).hp > 0:
					var e: Punk = m
					if absf(e.global_position.y - global_position.y) > 24.0:
						continue
					if absf(e.global_position.x - wp.x) < 14.0:
						var id := e.get_instance_id()
						if now - float(_cd.get(id, -9.0)) > 0.5:
							_cd[id] = now
							ArtMoves.strike(f, e, 5 + n, "", "")
							if is_instance_valid(e) and e.hp > 0:
								e.staples = maxi(e.staples, 2)
		queue_redraw()

	func _pos(i: int) -> Vector2:
		var ang := _a + TAU * float(i) / float(n)
		return Vector2(cos(ang) * radius, -32.0 + sin(ang) * radius * 0.35)

	func _draw() -> void:
		for i in n:
			var p := _pos(i)
			draw_set_transform(p, _a * 2.0, Vector2.ONE)
			draw_rect(Rect2(-6, -2, 12, 4), Color(0.25, 0.25, 0.3))
			draw_rect(Rect2(-6, -3, 9, 1.5), Color(0.75, 0.78, 0.82))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A bottle on an arc that bursts into a fire on the street.
class Lob extends Node2D:
	var by: Fighter
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var radius := 40.0
	var _t := 0.0

	static func throw(host: Node, f: Fighter, a: Vector2, b: Vector2, r: float) -> void:
		var l := Lob.new()
		l.by = f
		l.from = a
		l.to = b
		l.radius = r
		host.add_child(l)

	func _ready() -> void:
		z_index = 6

	func _physics_process(delta: float) -> void:
		_t += delta / 0.6
		if _t >= 1.0:
			FireFx.ground(get_parent(), to, 2.5)
			ArtFx.spawn(get_parent(), to, "ring", Elements.color("fire"), radius * 1.6, 0.4)
			Mixer.play_sfx("res://assets/audio/sfx/glass_break.ogg", 1.1, -4.0)
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk and (n as Punk).global_position.distance_to(to) < radius and is_instance_valid(by):
					ArtMoves.strike(by, n, 8, "", "fire")
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var p := from.lerp(to, _t) + Vector2(0, -sin(PI * _t) * 90.0)
		draw_set_transform(p - global_position, _t * 12.0, Vector2.ONE)
		draw_rect(Rect2(-2, -6, 4, 10), Color(0.35, 0.55, 0.3))
		draw_circle(Vector2(0, -8), 2.5, Color(1.0, 0.6, 0.2))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A flock of pigeons that sweeps the lane from behind the hero.
class Flock extends Node2D:
	var by: Fighter
	var dmg := 6
	var count := 8
	var dir := 1
	var _x := 0.0
	var _hit := {}
	var _t := 0.0

	static func sweep(host: Node, f: Fighter, dmg_: int, n: int) -> void:
		var k := Flock.new()
		k.by = f
		k.dmg = dmg_
		k.count = n
		k.dir = f.facing
		k.global_position = f.global_position + Vector2(-320.0 * float(f.facing), 0)
		host.add_child(k)
		Mixer.play_sfx("res://assets/audio/sfx/batwing.ogg", 1.3, -4.0)

	func _ready() -> void:
		z_index = 7

	func _physics_process(delta: float) -> void:
		_t += delta
		global_position.x += float(dir) * 520.0 * delta
		if _t > 1.4 or by == null or not is_instance_valid(by):
			queue_free()
			return
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk and not _hit.has(n.get_instance_id()):
				var e: Punk = n
				if absf(e.global_position.x - global_position.x) < 30.0 and absf(e.global_position.y - global_position.y) < 40.0:
					_hit[e.get_instance_id()] = true
					ArtMoves.strike(by, e, dmg, "stun", "")
		queue_redraw()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in count:
			var o := Vector2(rng.randf_range(-40, 40), rng.randf_range(-70, -20))
			var flap := sin(_t * 26.0 + float(i)) * 4.0
			var c := Color(0.55, 0.57, 0.62)
			draw_colored_polygon(PackedVector2Array([o + Vector2(-5, 0), o + Vector2(5, 0), o + Vector2(0, 3)]), c)
			draw_line(o, o + Vector2(-6, -flap), c, 2.0)
			draw_line(o, o + Vector2(6, -flap), c, 2.0)
			draw_circle(o + Vector2(5.0 * float(dir), -1), 1.5, Color(0.4, 0.42, 0.48))
