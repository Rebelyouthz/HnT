class_name DeathFall
extends Node2D

## A dead body that falls for real. The still of the last frame is a stiff
## rod (H long, T thick) with its centre of mass `zc` over the street:
##   in the air   it flies on a gravity arc, spinning, and bounces where it
##                hits the street (harder hits bounce higher, at most twice)
##   on its feet  it topples like a felled tree about the feet (an inverted
##                pendulum: slow to start, slamming at the end)
##   lying        it skids to a stop on the friction of the street, kicking
##                up dust, then rests flat and bleeds out
## Before the physics there can be a few scripted beats (knees buckling,
## stagger steps from rounds, a pirouette off a hook, clutching a cut).
##
## Which fall a death gets comes from pick(): the zone the blow landed in,
## the move, the weapon, the round, how hard - so a jab KO falls like a tree,
## a hook spins them round, a dropkick sends them skidding, an uppercut
## flips them, a sweep slams them on their back, a gut shot folds them over,
## a headshot drops them dead weight, a machete takes them to their knees.
## Settled bodies keep out of each other's way and lie under the living.

const G := 1250.0
const STYLES := ["crumple", "faceplant", "topple", "timber", "spin", "launch", "knockback", "sweep", "stagger", "headshot", "blown", "kneel", "legs", "blast", "homerun", "burn", "decap", "drawn"]

var gx := 0.0
var gy := 0.0
var zc := 0.0
var vx := 0.0
var vz := 0.0
var w := 0.0
var H := 96.0
var T := 16.0
var sag := 0.0
var face := 1
var bleed := 12.0
var settled := false
var art_root: Node2D
var _pre: Array = []
var _pre_t := 0.0
var _jolt_from := 0.0
var _pir := 0.0
var _ground := false
var _lying := false
var _bounces := 0
var _dust_cd := 0.0
var _life := 0.0


## The fall a death gets. zone: HitReact zone (head / gut / low / up / blade
## / crush / bullet / blast / homerun / burn); clip: the hero's move; held:
## the melee weapon; shot: Punk._shot (weapon, zone, dist) for a round.
static func pick(zone: String, kind: String, clip: String, held: String, power: float, shot: Dictionary) -> String:
	if zone in ["homerun", "blast", "burn", "crush"]:
		return zone
	if not shot.is_empty():
		var sz := str(shot.get("zone", "chest"))
		var sw := str(shot.get("weapon", "pistol"))
		var close := float(shot.get("dist", 999.0)) < 110.0
		if sw == "shotgun" and close:
			return "blown"
		if sz == "head":
			return "headshot"
		if sz == "legs":
			return "legs"
		if sz == "gut":
			return _any(["crumple", "faceplant", "drawn"])
		if sw == "revolver":
			return _any(["knockback", "stagger"])
		return _any(["stagger", "stagger", "crumple", "drawn"])
	match held:
		"baseball_bat", "pipe", "board", "crowbar", "chain":
			return _any(["knockback", "spin", "topple"])
		"knife", "machete", "stapler":
			return _any(["kneel", "kneel", "crumple"])
		"clipboard":
			return _any(["spin", "timber"])
	match zone:
		"up":
			return "launch"
		"low":
			return "sweep"
		"gut":
			if clip in ["dropkick", "shoulder_charge", "boot_kick", "side_kick"]:
				return "knockback"
			return _any(["faceplant", "crumple", "faceplant", "drawn"])
		"blade":
			return _any(["kneel", "crumple"])
		"bullet":
			return _any(["stagger", "crumple"])
	# Head blows: hooks and round kicks spin, big ones send them flying,
	# a clean straight one drops them stiff like a tree.
	if clip in ["hook", "roundhouse", "jump_roundhouse", "spin_backfist", "air_spin_kick", "elbow"]:
		return _any(["spin", "spin", "knockback"])
	if kind in ["finish", "snap", "combo", "special", "throw", "web-slam"] or clip in ["superman_punch", "dropkick", "side_kick", "boot_kick", "backflip_kick"]:
		return _any(["knockback", "knockback", "spin"])
	if clip in ["jab", "cross"] or kind == "light":
		return _any(["timber", "topple", "crumple"])
	if power >= 0.85:
		return _any(["knockback", "topple", "spin"])
	return _any(["topple", "timber", "crumple", "spin", "drawn"])


static func _any(a: Array) -> String:
	return str(a[randi() % a.size()])


## Sets the opening of `style`; dir is the way the blow travelled.
func setup(style: String, dir: float) -> void:
	var r := func(v: float) -> float: return v * randf_range(0.85, 1.15)
	match style:
		"crumple":
			_pre = [["sag", r.call(0.18), 0.3], ["hold", 0.06]]
			w = -dir * r.call(0.5)
			vx = dir * 12.0
		"faceplant":
			_pre = [["sag", 0.1, 0.14]]
			w = -dir * r.call(1.7)
		"topple":
			w = dir * r.call(1.4)
			vx = dir * r.call(70.0)
		"timber":
			w = dir * r.call(0.18)
		"spin":
			_pre = [["pirouette", r.call(0.34)]]
			vx = dir * r.call(60.0)
			w = dir * r.call(1.1)
		"launch":
			vz = r.call(440.0)
			vx = dir * r.call(80.0)
			w = dir * r.call(8.0)
		"knockback":
			vz = r.call(240.0)
			vx = dir * r.call(360.0)
			w = dir * r.call(3.2)
		"sweep":
			vz = r.call(170.0)
			vx = -dir * 25.0
			w = dir * r.call(8.5)
		"stagger":
			_pre = [["jolt", 0.09, dir * r.call(10.0)], ["jolt", 0.13, dir * r.call(7.0)], ["sag", 0.2, 0.32]]
			w = -dir * r.call(0.7)
		"headshot":
			_pre = [["sag", 0.05, 0.18]]
			w = dir * r.call(2.6)
			vx = dir * 30.0
		"blown":
			vz = r.call(210.0)
			vx = dir * r.call(430.0)
			w = dir * r.call(4.0)
		"kneel":
			_pre = [["sag", r.call(0.22), 0.42], ["clutch", r.call(0.5)]]
			w = -dir * r.call(0.45)
		"legs":
			_pre = [["sag", 0.08, 0.26]]
			w = -dir * r.call(2.2)
		"blast":
			vz = r.call(470.0)
			vx = dir * r.call(340.0)
			w = dir * r.call(12.0)
		"homerun":
			vz = r.call(560.0)
			vx = dir * r.call(420.0)
			w = dir * r.call(15.0)
		"decap":
			# Headless, the body stands a beat before the knees go.
			_pre = [["hold", r.call(0.4)], ["sag", 0.18, 0.3]]
			w = -dir * r.call(0.5)
			bleed = 24.0
		"burn":
			_pre = [["clutch", 0.6], ["sag", 0.3, 0.38]]
			w = -dir * 0.4
			bleed = 2.0
	if style in ["headshot", "stagger", "blown"]:
		bleed = 22.0


func _ready() -> void:
	_place()


func _physics_process(delta: float) -> void:
	if settled:
		return
	_life += delta
	if _life > 6.0:
		_settle()
		return
	if not _pre.is_empty():
		_beat(delta)
		_place()
		return
	var a := wrapf(rotation, -PI, PI)
	if not _ground or vz > 0.0:
		# Flight: a ballistic arc, spin slowly bleeding off in the air.
		vz -= G * delta
		zc += vz * delta
		gx += vx * delta
		rotation += w * delta
		w *= 1.0 - 0.25 * delta
		if zc <= _floor() and vz <= 0.0:
			_impact()
	elif not _lying:
		# Toppling about the feet: d is the lean off the nearest vertical.
		var v := 0.0 if absf(a) < PI * 0.5 else signf(a) * PI
		var d := a - v
		if absf(d) < 0.001:
			d = 0.001 * signf(w if w != 0.0 else 1.0)
		w += 1.5 * G / H * sin(d) * delta
		w *= 1.0 - 0.4 * delta
		# It falls about its feet: they stay planted, the middle swings over.
		var hh := H * 0.5 * (1.0 - sag)
		var foot := gx - sin(rotation) * hh
		var c0 := cos(rotation)
		rotation += w * delta
		vx = move_toward(vx, 0.0, 900.0 * delta)
		foot += vx * delta
		gx = foot + sin(rotation) * hh
		# Flat when it passes horizontal (cos changes sign) or reaches it.
		var c1 := cos(rotation)
		if signf(c0) != signf(c1) or absf(c1) < 0.03:
			_slam()
		zc = _floor()
	else:
		# Flat on the street: skid on friction, dust while it slides.
		vx = move_toward(vx, 0.0, 760.0 * delta)
		gx += vx * delta
		_dust_cd -= delta
		if absf(vx) > 70.0 and _dust_cd <= 0.0:
			_dust_cd = 0.08
			Juice.land_puff(Vector2(gx, gy))
		zc = _floor()
		if absf(vx) < 4.0:
			_settle()
	_place()


## Centre height when resting on the street at the current angle.
func _floor() -> float:
	var a := rotation
	return absf(cos(a)) * H * 0.5 * (1.0 - sag) + absf(sin(a)) * T * 0.5


func _place() -> void:
	position = Vector2(gx, gy - zc)
	if art_root != null:
		art_root.scale.y = 1.0 - sag


func _beat(delta: float) -> void:
	var b: Array = _pre[0]
	var secs: float = b[1]
	var t0 := _pre_t
	_pre_t += delta
	var k := clampf(_pre_t / maxf(secs, 0.001), 0.0, 1.0)
	match str(b[0]):
		"sag":
			if t0 == 0.0:
				_jolt_from = sag
			sag = lerpf(_jolt_from, float(b[2]), k * k)
		"jolt":
			# A round lands: the body is shoved back a step and shudders.
			if t0 == 0.0:
				_jolt_from = gx
				rotation = signf(float(b[2])) * 0.1
				var blood := get_tree().get_first_node_in_group("blood_sim")
				if blood and blood.has_method("burst"):
					blood.burst(Vector2(gx, gy - H * 0.6), gy, signf(float(b[2])), {"n": 6, "speed": 220.0, "spread": 0.3, "rise": 0.1, "size": 0.9, "streak": true})
			gx = _jolt_from + float(b[2]) * sin(k * PI * 0.5)
			rotation = lerpf(rotation, 0.0, 0.2)
		"pirouette":
			# Spun round by the blow: the body turns on the spot.
			if art_root != null:
				art_root.scale.x = float(face) * (1.0 if cos(k * TAU * 1.5) >= 0.0 else -1.0) * maxf(0.25, absf(cos(k * TAU * 1.5)))
			gx += vx * delta
		"clutch":
			rotation = sin(_pre_t * 14.0) * 0.04
		"hold":
			pass
	zc = _floor()
	if k >= 1.0:
		_pre.pop_front()
		_pre_t = 0.0
		if art_root != null:
			art_root.scale.x = float(face)


func _impact() -> void:
	var spd := -vz
	_bounces += 1
	_thud(spd)
	rotation = wrapf(rotation, -PI, PI)
	var a := rotation
	var v := 0.0 if absf(a) < PI * 0.5 else signf(a) * PI
	var upright := absf(a - v) < PI * 0.3
	if spd > 170.0 and _bounces < 3 and not upright:
		# Bounces off the street: a fraction of the speed back, spin knocked down.
		vz = spd * 0.3
		vx *= 0.7
		w *= 0.45
		zc = _floor() + 0.1
		return
	vz = 0.0
	_ground = true
	zc = _floor()
	if not upright:
		_lie()


## The top of a toppling body hits the street.
func _slam() -> void:
	_thud(absf(w) * H * 0.5)
	_lie()


func _lie() -> void:
	# Flat on the street: the nearer of the two horizontals.
	var side := signf(sin(rotation))
	if side == 0.0:
		side = 1.0
	rotation = side * PI * 0.5
	w = 0.0
	_lying = true
	_ground = true
	vx *= 0.8


func _thud(spd: float) -> void:
	if spd < 60.0:
		return
	var at := Vector2(gx, gy)
	Juice.land_puff(at)
	if spd > 140.0:
		Juice.land_puff(at + Vector2(signf(rotation) * H * 0.35, 0))
	Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", randf_range(0.85, 1.1) * (1.15 if spd < 200.0 else 0.95), clampf(-14.0 + spd / 40.0, -14.0, -2.0))
	if spd > 260.0:
		Juice.pulse_shake(clampf(spd / 180.0, 1.0, 4.0))


func _settle() -> void:
	if settled:
		return
	settled = true
	if not _lying:
		_lie()
	zc = _floor()
	_place()
	_make_room()
	var host := get_parent()
	if host != null:
		# Lying bodies go under the living.
		z_index = 0
		var first := -1
		for c in host.get_children():
			if c != self and (c.is_in_group("enemies") or c.is_in_group("players")):
				first = c.get_index() if first < 0 else mini(first, c.get_index())
		if first >= 0 and first < get_index():
			host.move_child(self, first)
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("pool"):
		blood.pool(Vector2(gx + signf(rotation) * H * 0.25, gy + 2.0), bleed)
	var tw := create_tween()
	tw.tween_interval(18.0)
	tw.tween_property(self, "modulate:a", 0.0, 1.5)
	tw.tween_callback(queue_free)


## A body never ends on top of another: it rolls a little up or down the
## street (or further along) until it lies clear.
func _make_room() -> void:
	var mid := gx
	for attempt in 4:
		var hit: DeathFall = null
		for n in get_tree().get_nodes_in_group("corpses"):
			if n == self or not (n is DeathFall) or not (n as DeathFall).settled:
				continue
			var o := n as DeathFall
			var om := o.gx
			if absf(om - mid) < (H + o.H) * 0.4 and absf(o.gy - gy) < 13.0:
				hit = o
				break
		if hit == null:
			return
		var step := 15.0 if gy >= hit.gy else -15.0
		if gy + step > Fighter.STREET_MAX + 10.0 or gy + step < Fighter.STREET_MIN - 10.0:
			step = -step
		if attempt >= 2:
			gx += signf(mid - hit.gx + 0.01) * H * 0.45
			mid = gx
		else:
			gy += step
	_place()
