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
var _hit_cd := 0.0
## A living thug hauling this body off the street (WoundGait DRAG).
var dragger: Node2D
var drag_t := 0.0
var _drag_dir := 1.0
var _smear_cd := 0.0
var _bowled := {}


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


var _shadow: Node2D


## The body's shadow on the street: stays flat on the ground under it, as
## long as the body lies along it, smaller and fainter the higher it flies.
class GroundShadow extends Node2D:
	var body: DeathFall

	func _process(_d: float) -> void:
		if body == null or not is_instance_valid(body):
			queue_free()
			return
		global_position = Vector2(body.gx, body.gy + 1.0)
		modulate.a = body.modulate.a
		queue_redraw()

	func _draw() -> void:
		var a := absf(sin(body.rotation))
		var w := (a * body.H * 0.55 + (1.0 - a) * body.T * 0.7 + 6.0)
		var lift := clampf(body.zc - body._floor(), 0.0, 200.0)
		var k := clampf(1.0 - lift / 160.0, 0.25, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, w * k, Color(0, 0, 0, 0.32 * k))
		draw_circle(Vector2.ZERO, w * k * 0.62, Color(0, 0, 0, 0.18 * k))


func _ready() -> void:
	_shadow = GroundShadow.new()
	_shadow.body = self
	_shadow.top_level = true
	_shadow.z_index = -1
	add_child(_shadow)
	_place()


func _physics_process(delta: float) -> void:
	if settled:
		_drag(delta)
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
		_collide(delta)
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
		# Flat on the street: skid on friction, dust while it slides (a wet
		# street is slicker: the body slides further).
		var mu := 520.0 if is_inside_tree() and get_tree().get_first_node_in_group("wet_street") != null else 760.0
		vx = move_toward(vx, 0.0, mu * delta)
		gx += vx * delta
		_collide(delta)
		_dust_cd -= delta
		if absf(vx) > 70.0 and _dust_cd <= 0.0:
			_dust_cd = 0.08
			Juice.land_puff(Vector2(gx, gy))
		zc = _floor()
		if absf(vx) < 4.0:
			_settle()
	_place()


## A body in motion meets the street furniture: lamp posts and parked cars
## stop it dead and throw it back (a clang, sparks, the post shivers),
## crates and bins it smashes straight through, the screen edge is a wall,
## and a body flying fast bowls over the thugs still standing.
func _collide(delta: float) -> void:
	_hit_cd -= delta
	if absf(vx) < 60.0 or not is_inside_tree():
		return
	var tree := get_tree()
	var dir := signf(vx)
	var reach := T * 0.5 + 6.0
	if _hit_cd <= 0.0:
		for g in ["street_lamps", "slam_props"]:
			for n in tree.get_nodes_in_group(g):
				if not (n is Node2D):
					continue
				var o := n as Node2D
				var half := float(o.get_meta("half_w", 10.0))
				var dx := o.global_position.x - gx
				if absf(o.global_position.y - gy) < 30.0 and absf(dx) < half + reach and signf(dx) == dir and zc < (H if g == "street_lamps" else 50.0):
					_bang(o, g == "street_lamps")
					return
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			var halfw := get_viewport_rect().size.x * 0.5 / maxf(0.01, cam.zoom.x)
			var ex := gx - cam.get_screen_center_position().x
			if absf(ex) > halfw - 14.0 and signf(ex) == dir:
				_bang(null, false)
				return
	for n in tree.get_nodes_in_group("smashables"):
		if n is Node2D and (n as Node2D).global_position.distance_to(Vector2(gx, gy)) < 34.0 and not _bowled.has(n.get_instance_id()):
			_bowled[n.get_instance_id()] = true
			if n.has_method("take_hit"):
				n.take_hit("throw", self)
			vx *= 0.6
			Juice.hitstop(2)
	if absf(vx) < 220.0:
		return
	for n in tree.get_nodes_in_group("enemies"):
		if not (n is Punk) or _bowled.has(n.get_instance_id()):
			continue
		var q := n as Punk
		if q.hp <= 0 or q.flung or q is ActBoss:
			continue
		if absf(q.global_position.x - gx) < 26.0 and absf(q.global_position.y - gy) < 22.0 and zc < H:
			_bowled[q.get_instance_id()] = true
			q.hp = maxi(1, q.hp - 8)
			q.flung = true
			q.flung_dir = dir
			q.flung_t = 0.18
			q.flung_ground = false
			vx *= 0.55
			Juice.hitstop(3)
			Juice.kick(Vector2(dir, 0.2), 3.0)
			Juice.shout("BOWLED")
			Mixer.play_sfx("res://assets/audio/sfx/punch_heavy.ogg", randf_range(0.85, 1.0), -4.0)


## Hits something solid (or the screen edge, o = null).
func _bang(o: Node2D, lamp: bool) -> void:
	_hit_cd = 0.3
	var spd := absf(vx)
	vx = -vx * 0.35
	w = -w * 0.5 + signf(vx) * 3.0
	if _lying and spd > 160.0:
		# Knocked up off the obstacle.
		vz = spd * 0.35
		_ground = false
		_lying = false
	var at := Vector2(gx - signf(vx) * T * 0.4, gy - zc)
	Juice.pulse_shake(clampf(spd / 90.0, 2.0, 6.0))
	Juice.hitstop(3 if spd > 250.0 else 2)
	Juice.land_puff(Vector2(gx, gy))
	if o != null:
		Juice.sparks(at)
		Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", randf_range(0.85, 1.0), -3.0)
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("burst"):
			blood.burst(at, gy, -signf(vx), {"n": 8, "speed": 140.0, "spread": 0.8, "rise": 0.3, "size": 1.0})
		if lamp:
			# The post shivers from the blow.
			var tw := o.create_tween()
			var k := clampf(spd / 400.0, 0.3, 1.0) * 0.06
			tw.tween_property(o, "rotation", -signf(vx) * k, 0.06)
			tw.tween_property(o, "rotation", signf(vx) * k * 0.6, 0.1)
			tw.tween_property(o, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_BACK)
		elif o.is_in_group("parked_cars"):
			var tw2 := o.create_tween()
			tw2.tween_property(o, "position:x", o.position.x - signf(vx) * 2.0, 0.04)
			tw2.tween_property(o, "position:x", o.position.x, 0.12)
			Mixer.play_sfx("res://assets/audio/sfx/glass_break.ogg", 1.2, -10.0)
	else:
		Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", 0.8, -3.0)
	if spd > 300.0:
		Juice.shout("WALL SPLAT" if o == null else ("LAMP POST" if lamp else "PARKED"))


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
	# A wet street: the body lands in water - a splash and a slap.
	if is_inside_tree() and get_tree().get_first_node_in_group("wet_street") != null:
		GunFx.splash(get_parent(), at + Vector2(randf_range(-8.0, 8.0), 1.0))
		if spd > 160.0:
			GunFx.splash(get_parent(), at + Vector2(signf(rotation) * H * 0.3, 2.0))
		Mixer.play_sfx("res://assets/audio/sfx/step_wet_%d.ogg" % (randi() % 3 + 1), randf_range(0.6, 0.8), clampf(-16.0 + spd / 40.0, -16.0, -4.0))
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
	tw.tween_interval(DeathFall.stay_secs())
	tw.tween_property(self, "modulate:a", 0.0, 1.5)
	tw.tween_callback(queue_free)


func start_drag(by: Node2D, dir: float) -> void:
	dragger = by
	drag_t = randf_range(1.1, 1.6)
	_drag_dir = dir


## Hauled by the feet behind the dragger, smearing blood, then left.
func _drag(delta: float) -> void:
	if dragger == null:
		return
	if not is_instance_valid(dragger) or float(dragger.get("hp")) <= 0.0 or drag_t <= 0.0:
		dragger = null
		drag_t = 0.0
		_make_room()
		return
	drag_t -= delta
	var want := dragger.global_position.x - _drag_dir * (H * 0.55 + 10.0)
	gx = lerpf(gx, want, minf(1.0, delta * 6.0))
	gy = lerpf(gy, dragger.global_position.y, minf(1.0, delta * 4.0))
	# Feet first toward the dragger.
	rotation = lerpf(rotation, -_drag_dir * PI * 0.5, minf(1.0, delta * 5.0))
	_place()
	_smear_cd -= delta
	if _smear_cd <= 0.0:
		_smear_cd = 0.12
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("pool"):
			blood.pool(Vector2(gx, gy + 2.0), 3.0)


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



## OPTIONS > BODIES STAY: how long the dead lie on the street.
static func stay_secs() -> float:
	var base: float = [8.0, 18.0, 45.0][clampi(int(FamilyProfile.data.get("bodies_stay", 1)), 0, 2)]
	# A survivor hour kills dozens: bodies clear fast or the street is a heap.
	if Engine.get_main_loop() is SceneTree and SurviveRun.get_run(Engine.get_main_loop() as SceneTree) != null:
		return minf(base, 4.0)
	return base


## Old bodies make room: 12 on a story street, 5 in a survivor hour.
static func trim(tree: SceneTree) -> void:
	var cap := 5 if SurviveRun.get_run(tree) != null else 12
	var all := tree.get_nodes_in_group("corpses")
	var extra := all.size() - cap
	for i in maxi(0, extra):
		var first := all[i] as Node2D
		if first == null or first.has_meta("trimming"):
			continue
		first.set_meta("trimming", true)
		var ft := first.create_tween()
		ft.tween_property(first, "modulate:a", 0.0, 0.5)
		ft.tween_callback(first.queue_free)
