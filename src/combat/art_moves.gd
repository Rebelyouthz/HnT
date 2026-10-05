class_name ArtMoves
extends Node2D

## Element arts, Tekken-style grabs and Dad + Son team attacks for one
## fighter (a child of the Fighter; runs just before it each physics frame).
##   LIGHT + HEAVY together, a thug in arm's reach -> GRAB (neutral / fwd / back)
##   LIGHT + HEAVY together otherwise            -> ELEMENT ART (stick: N F U D)
##   hold HEAVY, tap SPECIAL with TEAM full      -> TEAM ATTACK (stick: N F U/D)
## Arts cost CHI (hits and kills fill it), the team meter fills from kills
## only, so a team attack comes "now and then". The body runs on existing
## clips (charge pose, release strike) plus drawn effects; the camera zooms
## in on the release and on the killing blow.

const GRAB_REACH := 48.0
const GRAB_DEPTH := 22.0
const ZOOM_ART := 0.08
const ZOOM_TEAM := 0.16

var f: Fighter
var _light_age := 99
var _seq := ""
var _id := ""
var _t := 0.0
var _len := 0.0
var _beats := {}
var _row: Dictionary = {}
var _orb: ArtFx
var _victim: Punk
var _vstart := Vector2.ZERO
var _partner: Node2D
var _phantom: Node2D
var _p_anim: AnimatedSprite2D
var _p_from := Vector2.ZERO
var _p_base_y := 0.0
var _anchor := Vector2.ZERO
var _dir := 1
var _target: Punk
var _hit_once := {}
var _first_contact := false
var _ready_pulse := 0.0
var _team_told := false


static func attach(fighter: Fighter) -> ArtMoves:
	var a := ArtMoves.new()
	a.f = fighter
	a.name = "ArtMoves"
	fighter.add_child(a)
	return a


func _ready() -> void:
	process_physics_priority = f.process_physics_priority - 1
	z_index = -1


## One hit from any art: damage through the combo path (so points, gore and
## the finisher logic all apply), then the element's status.
static func strike(by: Fighter, e: Punk, dmg: int, fx: String, elem: String) -> void:
	if by == null or e == null or not is_instance_valid(e) or e.hp <= 0:
		return
	e.guarding = false
	e.telegraph = 0.0
	var od := by.combo_dmg
	var ofx := by.combo_fx
	by.combo_dmg = dmg
	by.combo_fx = fx
	by.art_hit = true
	e.take_hit("combo", by)
	by.art_hit = false
	by.combo_dmg = od
	by.combo_fx = ofx
	var host := e.get_parent()
	var c := Elements.color(elem)
	if host != null and elem != "":
		ArtFx.spawn(host, e.global_position + Vector2(0, -34), "burst", c, 26.0, 0.25)
	if e.hp <= 0 or not is_instance_valid(e):
		return
	match elem:
		"fire":
			e.ignite(3.0, by.role)
		"ice":
			e.snared = maxf(e.snared, 2.6)
			if e.visual:
				e.visual.modulate = Color(0.55, 0.85, 1.3)
				var tw := e.create_tween()
				tw.tween_interval(2.4)
				tw.tween_property(e.visual, "modulate", Color.WHITE, 0.3)
		"storm":
			e.recover = maxf(e.recover, 1.1)
			Juice.sparks(e.global_position + Vector2(0, -40))
		"earth":
			e.recover = maxf(e.recover, 1.3)


func _physics_process(delta: float) -> void:
	if f == null or not is_instance_valid(f):
		return
	if f._pressed("light"):
		_light_age = 0 if f._just("light") else _light_age + 1
	else:
		_light_age = 99
	_ready_pulse += delta
	queue_redraw()
	if _seq != "":
		_t += delta
		match _seq:
			"art":
				_run_art()
			"grab":
				_run_grab()
			"team":
				_run_team()
		if _seq != "" and (_t >= _len or f.downed):
			_end()
		return
	if f.team >= Elements.TEAM_MAX and not _team_told:
		_team_told = true
		Juice.popup_number(f.global_position + Vector2(0, -104), "TEAM READY · HOLD H + SPECIAL", UiKit.GOLD)
	if not _can_start():
		return
	if f._just("special") and f._pressed("heavy") and f.team >= Elements.TEAM_MAX:
		_start_team()
		return
	var lh := (f._just("light") and f._pressed("heavy") and f.charge_frames <= 8) \
		or (f._just("heavy") and f._pressed("light") and _light_age <= 6)
	if lh:
		_start_lh()


func _can_start() -> bool:
	return f.plane == "street" and f.hop > -4.0 and not f.downed and f.knock_t <= 0.0 \
		and not f.puppeted and f.van_seat == "" and f.art_lock <= 0.0 and f.parkour_lock <= 0.0 \
		and f.web_anchor == null and not f.snap_ready and f._combo_t <= 0.0 and f.roll_t <= 0.0


func _stick_dir() -> String:
	var s := f._stick()
	if s.y < -0.5:
		return "U"
	if s.y > 0.5:
		return "D"
	if s.x * float(f.facing) > 0.5:
		return "F"
	if s.x * float(f.facing) < -0.5:
		return "B"
	return "N"


func _nearest(reach: float, depth: float, ahead_only := false) -> Punk:
	var best: Punk = null
	var bd := reach
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var e: Punk = n
		if e.hp <= 0 or e.flung:
			continue
		var dx := e.global_position.x - f.global_position.x
		if ahead_only and dx * float(f.facing) < -8.0:
			continue
		if absf(e.global_position.y - f.global_position.y) > depth:
			continue
		if absf(dx) < bd:
			bd = absf(dx)
			best = e
	return best


func _begin(seq: String, length: float) -> void:
	f._cancel_strike()
	f.charge_frames = 0
	f.string_n = 0
	f.art_lock = length + 0.05
	f.art_vx = 0.0
	f.invuln = maxi(f.invuln, int(length * 60.0) + 6)
	_seq = seq
	_t = 0.0
	_len = length
	_beats.clear()
	_hit_once.clear()
	_first_contact = false
	_dir = f.facing
	_anchor = f.global_position


func _beat(at: float) -> bool:
	if _t >= at and not _beats.has(at):
		_beats[at] = true
		return true
	return false


func _end() -> void:
	if _orb and is_instance_valid(_orb):
		_orb.queue_free()
	_orb = null
	if _victim and is_instance_valid(_victim):
		_release_victim()
	_victim = null
	_free_partner()
	f.art_lock = 0.0
	f.art_vx = 0.0
	f.visual.position.y = 0.0
	f.visual.rotation = 0.0
	f.anim_atk = ""
	f._atk_t = 0.0
	_seq = ""


# --- body helpers -------------------------------------------------------

func _pose(actor_anim: AnimatedSprite2D, clip: String, frame := -1) -> String:
	if actor_anim == null or actor_anim.sprite_frames == null:
		return clip
	var c := clip
	if not actor_anim.sprite_frames.has_animation(c):
		for alt in ["heavy", "cross", "jab", "idle"]:
			if actor_anim.sprite_frames.has_animation(alt):
				c = alt
				break
	if actor_anim.animation != c:
		actor_anim.play(c)
	if frame >= 0:
		actor_anim.pause()
		actor_anim.frame = clampi(frame, 0, actor_anim.sprite_frames.get_frame_count(c) - 1)
	return c


func _me(clip: String, frame := -1) -> void:
	var c := _pose(f._anim, clip, frame)
	f.anim_atk = c
	f._atk_t = 0.3


func _restart(actor_anim: AnimatedSprite2D, clip: String) -> void:
	if actor_anim == null:
		return
	var c := _pose(actor_anim, clip)
	actor_anim.stop()
	actor_anim.play(c)


func _hand() -> Vector2:
	return f.global_position + Vector2(16.0 * float(_dir), -36.0 if f.role == "son" else -38.0)


func _zoom(amount: float, secs: float, at: Vector2) -> void:
	CouchCamera.punch(get_tree(), amount, secs, at)


# --- element arts ---------------------------------------------------------

## Fire one move straight away (captures, the dojo demo, tests).
func perform(kind: String, id: String) -> void:
	_end()
	match kind:
		"art":
			f.chi = Elements.CHI_MAX
			var r := Elements.art(id)
			var s := Elements._store()
			if not Elements.owned(id):
				s[id] = 1
				FamilyProfile.data["arts"] = s
			_start_art(r)
		"grab":
			var e := _nearest(140.0, 60.0)
			if e != null:
				e.global_position = f.global_position + Vector2(30.0 * float(f.facing), 0)
				for g: Dictionary in Elements.grabs(f.role):
					if str(g["id"]) == id:
						_start_grab(e, str(g["dir"]))
		"team":
			f.team = Elements.TEAM_MAX
			_start_team(id)

func _start_lh() -> void:
	var d := _stick_dir()
	var near := _nearest(GRAB_REACH, GRAB_DEPTH)
	if near != null and d != "U" and d != "D" and not (near is ActBoss) and near.vehicle == "":
		_start_grab(near, d)
		return
	var r := Elements.art_for(f.role, "N" if d == "B" else d)
	if r.is_empty():
		return
	_start_art(r)


func _start_art(r: Dictionary) -> void:
	var id := str(r["id"])
	if not Elements.owned(id):
		Juice.popup_number(f.global_position + Vector2(0, -96), "%s · LEARN IT IN THE DOJO" % str(r["title"]), Palette.MUTED)
		return
	var cost := Elements.cost(id)
	if f.chi < cost:
		Juice.popup_number(f.global_position + Vector2(0, -96), "NOT ENOUGH CHI", Palette.MUTED)
		Mixer.play_sfx("res://assets/audio/sfx/whiff_punch.ogg", 0.7, -8.0)
		return
	f.chi -= cost
	_row = r
	_id = id
	var charge := 0.3 if f.role == "son" else 0.36
	_begin("art", charge + 0.42)
	_row["charge"] = charge
	_orb = ArtFx.spawn(f.get_parent(), _hand(), "orb", Elements.color(str(r["elem"])), 2.0, 99.0)
	_orb.hold = true
	Mixer.play_sfx("res://assets/audio/heat_up.wav", 1.15, -4.0)
	Juice.popup_number(f.global_position + Vector2(0, -100), Elements.title(id), Elements.color(str(r["elem"])))


func _run_art() -> void:
	var charge := float(_row.get("charge", 0.3))
	var elem := str(_row["elem"])
	var col := Elements.color(elem)
	var evo := Elements.evolved(_id)
	if _t < charge:
		# Both hands at the gut, the ball growing between them.
		_me("block_mid", 99)
		if _orb:
			_orb.global_position = _hand()
			_orb.size = lerpf(2.0, 9.0 if not evo else 12.0, _t / charge)
		f.visual.position.y = -1.5 * sin(_t * 60.0)
		return
	f.visual.position.y = 0.0
	if _beat(charge):
		if _orb:
			_orb.queue_free()
			_orb = null
		_zoom(ZOOM_ART * (1.6 if evo else 1.0), 0.32, _hand())
		Juice.pulse_shake(4.0)
		_release(_id, elem, col, evo)
	if _seq == "art" and f.art_vx != 0.0 and _t > charge + 0.22:
		f.art_vx = 0.0


func _release(id: String, elem: String, col: Color, evo: bool) -> void:
	var host := f.get_parent()
	var dmg := Elements.dmg(id)
	var at := f.global_position
	match id:
		"fireball":
			_restart(f._anim, "cross")
			f.anim_atk = f._anim.animation
			var s := _shot("ball", elem, 420.0, 12.0 if not evo else 16.0, dmg, "knockdown")
			s.pierce = evo
			s.trail_fire = evo
			Mixer.play_sfx("res://assets/audio/sfx/flare_gun.ogg", 0.8, -3.0)
		"lightning_dash":
			_restart(f._anim, "superman_punch")
			f.anim_atk = f._anim.animation
			var from := at
			var dist := 210.0
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk:
					var e: Punk = n
					var dx := (e.global_position.x - at.x) * float(_dir)
					if dx > -10.0 and dx < dist + 20.0 and absf(e.global_position.y - at.y) < 28.0:
						strike(f, e, dmg, "stun", "storm")
			f.global_position.x += float(_dir) * dist
			ArtFx.bolt(host, from + Vector2(0, -36), f.global_position + Vector2(0, -36), col, 0.35)
			if evo:
				_chain(f.global_position, 3, dmg / 2)
			Mixer.play_sfx("res://assets/audio/zap.wav", 1.0, -2.0)
		"wind_kick":
			_restart(f._anim, "air_spin_kick" if f._anim.sprite_frames.has_animation("air_spin_kick") else "roundhouse")
			f.anim_atk = f._anim.animation
			var s := _shot("tornado", elem, 140.0 if not evo else 90.0, 26.0, dmg, "launch")
			s.life = 1.0 if not evo else 2.2
			s.pierce = true
			s.rehit = 0.0 if not evo else 0.4
			s.pull = evo
			s.h = 0.0
			Mixer.play_sfx("res://assets/audio/wind.wav", 1.2, -2.0)
		"ice_slide":
			_restart(f._anim, "slide")
			f.anim_atk = f._anim.animation
			f.art_vx = float(_dir) * 560.0
			ArtFx.spawn(host, at, "streak", col, float(_dir) * 160.0, 1.6, _dir)
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk:
					var e: Punk = n
					var dx := (e.global_position.x - at.x) * float(_dir)
					if dx > -10.0 and dx < 170.0 and absf(e.global_position.y - at.y) < 26.0:
						strike(f, e, dmg, "", "ice")
						if evo:
							_shatter_later(e, dmg)
			Mixer.play_sfx("res://assets/audio/sfx/glass_break.ogg", 1.3, -6.0)
		"fire_palm":
			_restart(f._anim, "heavy")
			f.anim_atk = f._anim.animation
			var reach := 120.0 if not evo else 180.0
			ArtFx.spawn(host, _hand(), "cone", col, reach, 0.45, _dir)
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk:
					var e: Punk = n
					var dx := (e.global_position.x - at.x) * float(_dir)
					if dx > -6.0 and dx < reach and absf(e.global_position.y - at.y) < 30.0 + dx * 0.15:
						strike(f, e, dmg, "fling", "fire")
			Mixer.play_sfx("res://assets/audio/boom.wav", 1.2, -4.0)
		"thunder_clap":
			_restart(f._anim, "hammer")
			f.anim_atk = f._anim.animation
			var waves := 1 if not evo else 3
			for i in waves:
				var s := _shot("wave", elem, 430.0, 18.0 + 6.0 * float(i), dmg, "stun")
				s.pierce = true
				s.h = 0.0
				s.global_position.x -= float(_dir) * 30.0 * float(i)
			ArtFx.spawn(host, at + Vector2(14.0 * float(_dir), -40), "burst", col, 40.0, 0.3)
			Mixer.play_sfx("res://assets/audio/slap.wav", 0.6, 0.0)
			Mixer.play_sfx("res://assets/audio/zap.wav", 0.8, -4.0)
		"magma_uppercut":
			_restart(f._anim, "uppercut")
			f.anim_atk = f._anim.animation
			var spots: Array[float] = [28.0]
			if evo:
				spots = [28.0, 90.0, -56.0]
			for sx in spots:
				var px := at.x + sx * float(_dir)
				ArtFx.spawn(host, Vector2(px, at.y), "pillar", col, 140.0, 0.7)
				ArtFx.spawn(host, Vector2(px, at.y), "cracks", col, 40.0, 1.2)
				for n in get_tree().get_nodes_in_group("enemies"):
					if n is Punk:
						var e: Punk = n
						if absf(e.global_position.x - px) < 40.0 and absf(e.global_position.y - at.y) < 26.0:
							strike(f, e, dmg, "launch", "fire")
			Juice.pulse_shake(8.0)
			Mixer.play_sfx("res://assets/audio/geyser.wav", 0.9, -2.0)
		"quake_stomp":
			_restart(f._anim, "boot_kick")
			f.anim_atk = f._anim.animation
			var rad := 130.0
			ArtFx.spawn(host, at, "ring", col, rad, 0.5)
			ArtFx.spawn(host, at, "cracks", col, 70.0, 1.4)
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk:
					var e: Punk = n
					if absf(e.global_position.x - at.x) < rad and absf(e.global_position.y - at.y) < 40.0:
						strike(f, e, dmg, "knockdown", "earth")
						if evo:
							_spike_later(e, dmg / 2)
			Juice.pulse_shake(12.0)
			Juice.hitstop(5)
			Mixer.play_sfx("res://assets/audio/stomp3.wav", 0.8, 0.0)
	FamilyProfile.data["arts_used"] = int(FamilyProfile.data.get("arts_used", 0)) + 1
	VoBank.line(f.role, "combo", 0.5)


func _shot(style: String, elem: String, spd: float, rad: float, dmg: int, fx: String) -> ElementShot:
	var s := ElementShot.new()
	s.by = f
	s.style = style
	s.elem = elem
	s.dir = _dir
	s.speed = spd
	s.r = rad
	s.dmg = dmg
	s.fx = fx
	s.global_position = f.global_position + Vector2(22.0 * float(_dir), 1.0)
	f.get_parent().add_child(s)
	return s


func _chain(from: Vector2, n: int, dmg: int) -> void:
	var done := {}
	var p := from
	for i in n:
		var best: Punk = null
		var bd := 220.0
		for m in get_tree().get_nodes_in_group("enemies"):
			if m is Punk and (m as Punk).hp > 0 and not done.has(m.get_instance_id()):
				var d := (m as Punk).global_position.distance_to(p)
				if d < bd:
					bd = d
					best = m
		if best == null:
			return
		done[best.get_instance_id()] = true
		ArtFx.bolt(f.get_parent(), p + Vector2(0, -36), best.global_position + Vector2(0, -36), Elements.color("storm"), 0.3)
		strike(f, best, dmg, "stun", "storm")
		p = best.global_position


func _shatter_later(e: Punk, dmg: int) -> void:
	var host := f.get_parent()
	var me := f
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if not is_instance_valid(e) or not is_instance_valid(me):
			return
		var at := e.global_position
		ArtFx.spawn(host, at + Vector2(0, -30), "burst", Elements.color("ice"), 50.0, 0.4)
		ArtFx.spawn(host, at, "ring", Elements.color("ice"), 80.0, 0.4)
		Mixer.play_sfx("res://assets/audio/sfx/glass_break.ogg", 0.9, -3.0)
		for n in host.get_tree().get_nodes_in_group("enemies"):
			if n is Punk and (n as Punk).global_position.distance_to(at) < 80.0:
				ArtMoves.strike(me, n, dmg / 2, "", "ice")
	)


func _spike_later(e: Punk, dmg: int) -> void:
	var host := f.get_parent()
	var me := f
	get_tree().create_timer(0.3).timeout.connect(func() -> void:
		if not is_instance_valid(e) or not is_instance_valid(me) or e.hp <= 0:
			return
		ArtFx.spawn(host, e.global_position, "pillar", Elements.color("earth"), 70.0, 0.4)
		ArtMoves.strike(me, e, dmg, "launch", "earth")
	)


# --- grabs ------------------------------------------------------------------

## Keyframes [t, x (toward facing), height, rotation (toward facing)] for the
## held thug; "slam" is when he lands, "clips" the hero's strikes in order.
const GRAB_SHAPES := {
	"monkey_flip": {"len": 0.9, "slam": 0.72, "fx": "fling", "clips": [[0.0, "duck"], [0.18, "backflip_kick"]],
		"keys": [[0.0, 26, 0, 0.0], [0.2, 20, -12, -0.4], [0.45, 0, -78, -3.14], [0.66, -40, -14, -4.6], [0.72, -48, 0, -4.71]], "hop": 0.0},
	"ddt": {"len": 0.82, "slam": 0.62, "fx": "knockdown", "clips": [[0.0, "cartwheel_kick"]],
		"keys": [[0.0, 26, 0, 0.0], [0.28, 22, -44, -0.7], [0.5, 24, -34, -2.6], [0.62, 26, 0, -3.14]], "hop": 30.0},
	"frankensteiner": {"len": 0.86, "slam": 0.66, "fx": "knockdown", "clips": [[0.0, "jump_roundhouse"]],
		"keys": [[0.0, 26, 0, 0.0], [0.22, 18, -52, 0.5], [0.46, -6, -64, 3.14], [0.66, -38, 0, 3.6]], "hop": 44.0},
	"giant_swing": {"len": 1.3, "slam": 1.08, "fx": "fling", "spin": true, "clips": [[0.0, "spin_backfist"], [0.36, "spin_backfist"], [0.72, "spin_backfist"], [1.0, "heavy"]],
		"keys": [[0.0, 26, 0, 0.0]], "hop": 0.0},
	"suplex": {"len": 0.96, "slam": 0.74, "fx": "knockdown", "clips": [[0.0, "clinch_knee"], [0.3, "heavy"]],
		"keys": [[0.0, 24, 0, 0.0], [0.3, 22, -22, 0.0], [0.55, 0, -84, -1.9], [0.72, -34, -6, -3.14], [0.74, -36, 0, -3.14]], "hop": 10.0},
	"headlock_knees": {"len": 1.1, "slam": 0.92, "fx": "fling", "knees": [0.2, 0.48, 0.76], "clips": [[0.0, "clinch_knee"], [0.28, "clinch_knee"], [0.56, "clinch_knee"], [0.86, "shoulder_charge"]],
		"keys": [[0.0, 22, 0, 0.18], [0.86, 22, 0, 0.18], [0.92, 40, 0, 0.0]], "hop": 0.0},
}


func _start_grab(e: Punk, d: String) -> void:
	var g := Elements.grab_for(f.role, d)
	if g.is_empty() or not GRAB_SHAPES.has(str(g["id"])):
		return
	_row = g
	_id = str(g["id"])
	if e.global_position.x != f.global_position.x:
		f.facing = 1 if e.global_position.x > f.global_position.x else -1
		f.visual.scale.x = float(f.facing)
	var shape: Dictionary = GRAB_SHAPES[_id]
	_begin("grab", float(shape["len"]))
	_victim = e
	_vstart = e.global_position
	e.set_physics_process(false)
	e.velocity = Vector2.ZERO
	e.telegraph = 0.0
	e.guarding = false
	e.atk_height = ""
	if e._anim and e._anim.sprite_frames.has_animation("hurt"):
		e._anim.play("hurt")
	Mixer.play_sfx("res://assets/audio/grab.wav", 1.0, -2.0)
	Juice.popup_number(f.global_position + Vector2(0, -100), str(g["title"]), UiKit.GOLD)
	_zoom(0.06, 0.4, f.global_position + Vector2(0, -40))


func _run_grab() -> void:
	var shape: Dictionary = GRAB_SHAPES[_id]
	var e := _victim
	if e == null or not is_instance_valid(e):
		_end()
		return
	for c: Array in shape["clips"]:
		if _beat(float(c[0])):
			_restart(f._anim, str(c[1]))
			f.anim_atk = f._anim.animation
	f._atk_t = 0.3
	var hop := float(shape.get("hop", 0.0))
	if hop > 0.0:
		f.visual.position.y = -hop * sin(PI * clampf(_t / float(shape["slam"]), 0.0, 1.0))
	var slam := float(shape["slam"])
	if _t < slam:
		var x := 0.0
		var h := 0.0
		var rot := 0.0
		if shape.get("spin", false):
			var ang := (_t / slam) * TAU * 3.0
			x = cos(ang) * 46.0
			h = -18.0 - 6.0 * sin(ang * 0.5)
			rot = ang * 0.15
			e.global_position.y = f.global_position.y + sin(ang) * 10.0
			e.z_index = 1 if sin(ang) > 0.0 else -1
			# Bowl over anyone in the swing.
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk and n != e and not _hit_once.has(n.get_instance_id()):
					var o: Punk = n
					if o.global_position.distance_to(e.global_position) < 34.0:
						_hit_once[o.get_instance_id()] = true
						strike(f, o, 10, "knockdown", "")
		else:
			var keys: Array = shape["keys"]
			var k0: Array = keys[0]
			var k1: Array = keys[keys.size() - 1]
			for i in keys.size() - 1:
				if _t >= float(keys[i][0]) and _t <= float(keys[i + 1][0]):
					k0 = keys[i]
					k1 = keys[i + 1]
					break
			var span := maxf(0.001, float(k1[0]) - float(k0[0]))
			var u := clampf((_t - float(k0[0])) / span, 0.0, 1.0)
			u = u * u * (3.0 - 2.0 * u)
			x = lerpf(float(k0[1]), float(k1[1]), u)
			h = lerpf(float(k0[2]), float(k1[2]), u)
			rot = lerpf(float(k0[3]), float(k1[3]), u)
			e.global_position.y = f.global_position.y + 1.0
		e.global_position.x = f.global_position.x + x * float(_dir)
		if e.visual:
			e.visual.position.y = h
			e.visual.rotation = rot * float(_dir)
		for kt in shape.get("knees", []):
			if _beat(float(kt)):
				strike(f, e, 6, "", "")
				Juice.hitstop(3)
				Mixer.play_sfx("res://assets/audio/sfx/hit_knee.ogg", 1.0, -2.0)
		return
	if _beat(slam):
		var dmg := int(_row.get("dmg", 30))
		var fx := str(shape["fx"])
		if shape.get("spin", false):
			e.global_position.x = f.global_position.x + 30.0 * float(_dir)
		_release_victim()
		var at := e.global_position
		var host := f.get_parent()
		ArtFx.spawn(host, at, "ring", Color(0.9, 0.85, 0.75), 70.0, 0.35)
		ArtFx.spawn(host, at, "cracks", Color(0.6, 0.5, 0.4), 34.0, 1.0)
		Juice.land_puff(at)
		Juice.pulse_shake(9.0)
		Juice.hitstop(7)
		Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", 0.9, 0.0)
		Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", 1.0, -3.0)
		strike(f, e, dmg, fx, "")
		if not is_instance_valid(e) or e.hp <= 0:
			Juice.kill_cam(at)
			_zoom(0.12, 0.5, at + Vector2(0, -30))
		FamilyProfile.data["grabs_landed"] = int(FamilyProfile.data.get("grabs_landed", 0)) + 1
		_victim = null


func _release_victim() -> void:
	var e := _victim
	if e == null or not is_instance_valid(e):
		return
	e.set_physics_process(true)
	e.z_index = 0
	if e.visual:
		e.visual.position.y = 0.0
		e.visual.rotation = 0.0


# --- team attacks -------------------------------------------------------------

func _start_team(force := "") -> void:
	var d := _stick_dir()
	var id := "daddy_launch"
	if d == "F":
		id = "tag_slam"
	elif d == "U" or d == "D":
		id = "family_double"
	if force != "":
		id = force
	_id = id
	for r: Dictionary in Elements.team():
		if str(r["id"]) == id:
			_row = r
	var lens := {"daddy_launch": 1.25, "tag_slam": 1.35, "family_double": 1.3}
	_begin("team", float(lens[id]))
	f.team = 0.0
	_team_told = false
	_target = _nearest(260.0, 40.0, true)
	_bring_partner()
	Juice.shout(str(_row.get("title", "TEAM")))
	Mixer.play_sfx("res://assets/audio/dual_snap.wav", 1.0, 0.0)
	Juice.named_slowmo()
	_zoom(ZOOM_TEAM, float(lens[id]), f.global_position + Vector2(40.0 * float(_dir), -40))
	FamilyProfile.data["team_attacks"] = int(FamilyProfile.data.get("team_attacks", 0)) + 1


func _other_role() -> String:
	return "father" if f.role == "son" else "son"


func _bring_partner() -> void:
	_partner = null
	_p_anim = null
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and n != f and (n as Fighter).role == _other_role() and not (n as Fighter).downed:
			_partner = n
			break
	if _partner != null:
		var pf := _partner as Fighter
		pf.puppeted = true
		pf._cancel_strike()
		_p_anim = pf._anim
		_p_from = pf.global_position
		return
	# Solo: the other hero runs in for the move, then off again.
	if not SpriteBook.has_who(_other_role()):
		return
	_phantom = Node2D.new()
	_phantom.global_position = f.global_position + Vector2(-260.0 * float(_dir), 0)
	f.get_parent().add_child(_phantom)
	_p_anim = SpriteBook.make_anim(_other_role())
	SpriteBook.grow(_p_anim, SpriteBook.FIGHTER_SCALE * (SpriteBook.FATHER_K if _other_role() == "father" else 1.0))
	_phantom.add_child(_p_anim)
	Suits.dress(_p_anim, _other_role())
	_p_base_y = _p_anim.position.y
	_partner = _phantom
	_p_from = _phantom.global_position


func _free_partner() -> void:
	if _partner is Fighter:
		var pf := _partner as Fighter
		pf.puppeted = false
		pf.snap_pos = Vector2.ZERO
		pf.snap_hop = 0.0
		pf.visual.position.y = 0.0
	if _phantom and is_instance_valid(_phantom):
		var ph := _phantom
		var tw := ph.create_tween()
		tw.tween_property(ph, "modulate:a", 0.0, 0.25)
		tw.tween_callback(ph.queue_free)
	_phantom = null
	_partner = null
	_p_anim = null


## Put an actor (role) at a spot with a height and a clip.
func _put(role: String, pos: Vector2, h: float, face: int) -> void:
	if role == f.role:
		f.global_position = pos
		f.visual.position.y = h
		f.facing = face
		f.visual.scale.x = float(face)
		return
	if _partner == null:
		return
	if _partner is Fighter:
		var pf := _partner as Fighter
		pf.snap_pos = pos
		pf.snap_hop = h
		pf.global_position = pos
		pf.visual.position.y = h
		pf.facing = face
		pf.visual.scale.x = float(face)
	else:
		_partner.global_position = pos
		if _p_anim:
			_p_anim.position.y = _p_base_y + h
			_p_anim.scale.x = absf(_p_anim.scale.x) * float(face)


func _clip(role: String, clip: String, restart := false, frame := -1) -> void:
	if role == f.role:
		if restart:
			_restart(f._anim, clip)
			f.anim_atk = f._anim.animation
		else:
			_me(clip, frame)
		f._atk_t = 0.3
		return
	if _p_anim == null:
		return
	if restart:
		_restart(_p_anim, clip)
	else:
		_pose(_p_anim, clip, frame)


func _ease(a: Vector2, b: Vector2, t0: float, t1: float) -> Vector2:
	var u := clampf((_t - t0) / maxf(0.001, t1 - t0), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	return a.lerp(b, u)


func _team_hit(e: Punk, dmg: int, fx: String, elem: String) -> void:
	if e == null or not is_instance_valid(e) or _hit_once.has(e.get_instance_id()):
		return
	_hit_once[e.get_instance_id()] = true
	var at := e.global_position
	strike(f, e, dmg, fx, elem)
	if not _first_contact:
		_first_contact = true
		Juice.hitstop(8)
		Juice.pulse_shake(10.0)
		_zoom(0.2, 0.45, at + Vector2(0, -40))
	if not is_instance_valid(e) or e.hp <= 0:
		Juice.kill_cam(at)


func _run_team() -> void:
	var dirv := float(_dir)
	var base := _anchor
	var dmg := int(_row.get("dmg", 40))
	match _id:
		"daddy_launch":
			var dad_at := base + Vector2(-34.0 * dirv, 0)
			# Dad cups his hands, the kid runs up them and is thrown feet first.
			_put("father", _ease(_p_from if f.role == "son" else base, dad_at, 0.0, 0.2), 0.0, _dir)
			_clip("father", "duck" if _t < 0.36 else "uppercut", _beat(0.36))
			if _t < 0.36:
				var from := base if f.role == "son" else _p_from
				_put("son", _ease(from, dad_at + Vector2(-6.0 * dirv, 0), 0.0, 0.34), -26.0 * clampf((_t - 0.18) / 0.16, 0.0, 1.0), _dir)
				_clip("son", "jump", false, 2)
			elif _t < 0.86:
				var sp := _ease(dad_at, dad_at + Vector2(300.0 * dirv, 0), 0.38, 0.84)
				_put("son", sp, -34.0, _dir)
				_clip("son", "dropkick", _beat(0.38))
				for n in get_tree().get_nodes_in_group("enemies"):
					if n is Punk and absf((n as Punk).global_position.x - sp.x) < 34.0 and absf((n as Punk).global_position.y - sp.y) < 30.0:
						_team_hit(n, dmg, "fling", "")
			else:
				var land := dad_at + Vector2(300.0 * dirv, 0)
				_put("son", land, -34.0 * (1.0 - clampf((_t - 0.86) / 0.12, 0.0, 1.0)), _dir)
				_clip("son", "idle")
				if _beat(0.98):
					Juice.land_puff(land)
		"tag_slam":
			var tgt := _target
			var tp := base + Vector2(70.0 * dirv, 0)
			if tgt != null and is_instance_valid(tgt):
				tp = tgt.global_position
				if _t < 0.05:
					tgt.set_physics_process(false)
					tgt.telegraph = 0.0
			var son_at := tp + Vector2(-40.0 * dirv, 0)
			var dad_at := tp + Vector2(46.0 * dirv, 0)
			_put("son", _ease(base if f.role == "son" else _p_from, son_at, 0.0, 0.2), 0.0, _dir)
			var dad_from := base if f.role == "father" else _p_from
			if _t < 0.42:
				_put("father", _ease(dad_from, dad_at, 0.0, 0.22), 0.0, -_dir)
				_clip("father", "idle")
			elif _t < 0.62:
				_put("father", _ease(dad_at, Vector2(tp.x + 8.0 * dirv, tp.y), 0.42, 0.6), -120.0 * sin(PI * 0.5 * clampf((_t - 0.42) / 0.2, 0.0, 1.0)), -_dir)
				_clip("father", "jump", false, 3)
			else:
				var u := clampf((_t - 0.62) / 0.14, 0.0, 1.0)
				_put("father", Vector2(tp.x + 8.0 * dirv, tp.y), -120.0 * (1.0 - u), -_dir)
				_clip("father", "hammer", _beat(0.62))
			_clip("son", "idle" if _t < 0.22 or _t > 0.5 else "sweep", _beat(0.22))
			if tgt != null and is_instance_valid(tgt) and tgt.visual:
				if _t >= 0.22 and _t < 0.76:
					var up := clampf((_t - 0.22) / 0.3, 0.0, 1.0)
					var down := clampf((_t - 0.62) / 0.14, 0.0, 1.0)
					tgt.visual.position.y = -110.0 * sin(PI * 0.5 * up) * (1.0 - down)
					tgt.visual.rotation = float(_dir) * (_t - 0.22) * 9.0
				if _beat(0.76):
					tgt.visual.position.y = 0.0
					tgt.visual.rotation = 0.0
					tgt.set_physics_process(true)
					var at := tgt.global_position
					var host := f.get_parent()
					ArtFx.spawn(host, at, "ring", UiKit.GOLD, 120.0, 0.5)
					ArtFx.spawn(host, at, "cracks", Color(1.0, 0.7, 0.3), 60.0, 1.4)
					Juice.land_puff(at)
					Mixer.play_sfx("res://assets/audio/stomp3.wav", 0.8, 0.0)
					Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", 0.9, 0.0)
					_team_hit(tgt, dmg, "crush", "")
					for n in get_tree().get_nodes_in_group("enemies"):
						if n is Punk and n != tgt and (n as Punk).global_position.distance_to(at) < 100.0:
							strike(f, n, 12, "knockdown", "earth")
			elif _beat(0.76):
				ArtFx.spawn(f.get_parent(), tp, "ring", UiKit.GOLD, 120.0, 0.5)
				for n in get_tree().get_nodes_in_group("enemies"):
					if n is Punk and (n as Punk).global_position.distance_to(tp) < 110.0:
						_team_hit(n, dmg / 2, "knockdown", "earth")
		"family_double":
			var son_at := base + Vector2(0, 6)
			var dad_at := base + Vector2(-16.0 * dirv, -6)
			_put("son", _ease(base if f.role == "son" else _p_from, son_at, 0.0, 0.2), 0.0, _dir)
			_put("father", _ease(base if f.role == "father" else _p_from, dad_at, 0.0, 0.2), 0.0, _dir)
			var orb_at := base + Vector2(30.0 * dirv, -38)
			if _t < 0.68:
				_clip("son", "block_mid", false, 99)
				_clip("father", "block_mid", false, 99)
				if _t > 0.2:
					if _orb == null:
						_orb = ArtFx.spawn(f.get_parent(), orb_at, "orb", Elements.color("fire"), 4.0, 99.0)
						_orb.hold = true
						Mixer.play_sfx("res://assets/audio/heat_up.wav", 0.8, 0.0)
					_orb.global_position = orb_at
					_orb.size = lerpf(4.0, 22.0, (_t - 0.2) / 0.48)
			elif _beat(0.68):
				if _orb:
					_orb.queue_free()
					_orb = null
				_clip("son", "cross", true)
				_clip("father", "heavy", true)
				var s := _shot("ball", "fire", 620.0, 24.0, dmg, "fling")
				s.pierce = true
				s.trail_fire = true
				s.life = 1.4
				s.global_position = base + Vector2(30.0 * dirv, 1)
				ArtFx.spawn(f.get_parent(), orb_at, "burst", Elements.color("fire"), 70.0, 0.4)
				Juice.pulse_shake(12.0)
				Juice.hitstop(6)
				Mixer.play_sfx("res://assets/audio/boom.wav", 0.8, 0.0)
	if _partner is Fighter:
		(_partner as Fighter)._atk_t = 0.3


# --- meters under the feet ------------------------------------------------------

func _draw() -> void:
	if f == null or (f.chi <= 0.0 and f.team <= 0.0):
		return
	var col := Elements.color(str(Elements.art_for(f.role, "N").get("elem", "fire")))
	var frac := clampf(f.chi / Elements.CHI_MAX, 0.0, 1.0)
	var cost_n := Elements.cost(str(Elements.art_for(f.role, "N").get("id", "")))
	var ready := f.chi >= cost_n
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.3))
	draw_arc(Vector2.ZERO, 24.0, PI * 0.15, PI * 0.85, 24, Color(0, 0, 0, 0.45), 4.0)
	if frac > 0.0:
		var pulse := 0.75 + 0.25 * sin(_ready_pulse * 8.0) if ready else 0.6
		draw_arc(Vector2.ZERO, 24.0, PI * 0.85 - PI * 0.7 * frac, PI * 0.85, 24, Color(col.r, col.g, col.b, pulse), 3.0)
	var tf := clampf(f.team / Elements.TEAM_MAX, 0.0, 1.0)
	if tf > 0.0:
		var gold := UiKit.GOLD
		var a := 0.5 if tf < 1.0 else 0.7 + 0.3 * sin(_ready_pulse * 10.0)
		draw_arc(Vector2.ZERO, 29.0, PI * 0.85 - PI * 0.7 * tf, PI * 0.85, 24, Color(gold.r, gold.g, gold.b, a), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
