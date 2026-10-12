class_name BrutalRun
extends Node2D

## One BONE YARD move playing out: the hero's clips on their beats, the
## victim's body posed key by key (distance in front, height, tip, neck
## twist, knees folding), and the events that sell it: bone cracks, blood,
## five pressure-point flashes, a heart held up in a fist, the head coming
## off. Ends in the kill (on the dojo dummy: the show, then a rep).
##   keys:   [t, ahead_px, height, tip, twist, knees]  (tip/twist: + = away)
##   clips:  [t, "clip|fallback|..."]
##   events: [t, kind, arg]

const SEQ := {
	"arm_breaker": {"len": 1.3, "kill": 1.2, "zone": "gut",
		"clips": [[0.0, "clinch_knee|cross"], [0.45, "elbow|heavy"], [0.9, "heavy"]],
		"keys": [[0.0, 26, 0, 0.0, 0.0, 1.0], [0.45, 24, 0, 0.15, 0.2, 1.0], [0.55, 24, 0, -0.25, -0.4, 0.92], [1.2, 30, 0, 0.1, 0.0, 0.95]],
		"events": [[0.5, "crack", "ARM"], [0.52, "blood", 0.5], [0.55, "scream", ""]]},
	"knee_snap": {"len": 1.1, "kill": 0.8, "zone": "low",
		"clips": [[0.0, "front_kick|boot_kick|side_kick"], [0.6, "hammer|heavy"]],
		"keys": [[0.0, 30, 0, 0.0, 0.0, 1.0], [0.25, 30, 0, 0.0, 0.0, 1.0], [0.32, 28, 10, -0.2, 0.3, 0.78], [0.6, 26, 12, -0.15, 0.2, 0.75], [0.9, 28, 14, 0.5, 0.0, 0.75]],
		"events": [[0.3, "crack", "KNEE"], [0.32, "blood", 0.4], [0.35, "scream", ""], [0.75, "crack", "SKULL"]]},
	"neck_crack": {"len": 1.0, "kill": 0.9, "zone": "gut",
		"clips": [[0.0, "jab"], [0.4, "snap|cross"]],
		"keys": [[0.0, 22, 0, 0.0, 0.0, 1.0], [0.4, 16, 0, 0.0, 0.0, 1.0], [0.48, 16, 0, 0.05, 0.7, 1.0], [0.6, 16, 0, 0.1, 0.65, 1.0], [0.95, 24, 2, 1.4, 0.3, 1.0]],
		"events": [[0.46, "crack", "NECK"]]},
	"death_touch": {"len": 1.7, "kill": 1.6, "zone": "gut",
		"clips": [[0.0, "jab"], [0.15, "jab"], [0.3, "cross"], [0.45, "jab"], [0.6, "cross"]],
		"keys": [[0.0, 24, 0, 0.0, 0.0, 1.0], [0.75, 24, 0, 0.0, 0.0, 1.0], [1.0, 40, 0, -0.08, 0.0, 1.0], [1.25, 56, 0, 0.1, 0.0, 1.0], [1.5, 70, 0, -0.15, 0.0, 1.0], [1.65, 74, 4, 1.2, 0.0, 1.0]],
		"events": [[0.1, "point", Vector2(0, -60)], [0.25, "point", Vector2(5, -52)], [0.4, "point", Vector2(-4, -48)], [0.55, "point", Vector2(3, -40)], [0.7, "point", Vector2(0, -56)], [0.8, "say", "THREE STEPS"], [1.55, "say", "HEART STOPPED"]]},
	"eye_gouge": {"len": 1.5, "kill": 1.0, "zone": "up",
		"clips": [[0.0, "jab"], [0.25, "cross"], [0.9, "flying_knee|front_kick"]],
		"keys": [[0.0, 22, 0, 0.0, 0.0, 1.0], [0.3, 20, 0, -0.3, 0.0, 1.0], [0.5, 26, 0, 0.25, 0.2, 1.0], [0.7, 34, 0, -0.2, -0.2, 1.0], [0.95, 26, -6, 0.6, 0.0, 1.0], [1.3, 32, 0, 1.4, 0.0, 1.0]],
		"events": [[0.28, "eyes", ""], [0.3, "scream", ""], [0.5, "say", "BLIND"], [0.95, "crack", "JAW"]]},
	"pipe_javelin": {"len": 1.2, "kill": 0.35, "zone": "gut",
		"clips": [[0.0, "heavy"]],
		"keys": [[0.0, 30, 0, 0.0, 0.0, 1.0], [0.3, 30, 0, 0.0, 0.0, 1.0], [0.5, 90, 0, 0.2, 0.0, 1.0], [1.1, 96, 0, 0.2, 0.0, 1.0]],
		"events": [[0.3, "pin", ""], [0.32, "blood", 0.9]]},
	"heart_punch": {"len": 1.4, "kill": 1.05, "zone": "gut",
		"clips": [[0.0, "cross|heavy"], [0.55, "jab"]],
		"keys": [[0.0, 26, 0, 0.0, 0.0, 1.0], [0.3, 24, 0, -0.35, 0.0, 0.95], [0.9, 24, 0, -0.3, 0.0, 0.95], [1.3, 30, 6, 0.9, 0.0, 1.0]],
		"events": [[0.3, "crack", "RIBS"], [0.31, "blood", 1.0], [0.32, "heart", ""], [0.33, "slowmo", 0.6]]},
	"spine_rip": {"len": 1.2, "kill": 0.36, "zone": "up", "decap": true,
		"clips": [[0.0, "duck"], [0.2, "uppercut"]],
		"keys": [[0.0, 22, 0, 0.0, 0.0, 1.0], [0.3, 22, -20, 0.0, 0.0, 1.0], [0.4, 22, -30, 0.2, 0.0, 1.0]],
		"events": [[0.3, "slowmo", 0.5], [0.34, "crack", "SPINE"], [0.36, "blood", 1.0]]},
	"back_breaker": {"len": 1.6, "kill": 1.05, "zone": "low",
		"clips": [[0.0, "clinch_knee"], [0.3, "heavy"], [0.95, "clinch_knee"]],
		"keys": [[0.0, 24, 0, 0.0, 0.0, 1.0], [0.4, 6, -70, 1.57, 0.0, 1.0], [0.8, 8, -74, 1.57, 0.0, 1.0], [0.95, 14, -22, 1.57, 0.0, 1.0], [1.0, 14, -18, 1.95, 0.0, 1.0], [1.4, 22, 0, 1.6, 0.0, 1.0]],
		"events": [[0.97, "crack", "BACK"], [0.98, "blood", 0.7]]},
	"two_way": {"len": 2.6, "kill": 1.75, "zone": "blade", "decap": true,
		"clips": [[0.0, "sweep|side_kick"], [0.7, "side_kick"], [1.3, "jab"], [1.6, "roundhouse|side_kick"]],
		"keys": [[0.0, 30, 0, 0.0, 0.0, 1.0], [0.25, 30, 10, -0.2, 0.3, 0.78], [0.7, 30, 10, -0.2, 0.3, 0.78], [0.8, 30, 10, 0.1, 0.8, 0.78], [1.7, 30, 10, 0.1, 0.8, 0.78]],
		"events": [[0.25, "crack", "LEG"], [0.27, "scream", ""], [0.8, "crack", "NECK"], [1.0, "say", "HOLD"], [1.6, "slowmo", 0.45], [1.74, "blood", 1.0]]},
	"skull_crusher": {"len": 1.8, "kill": 0.88, "zone": "blast", "decap": true,
		"clips": [[0.0, "clinch_knee"], [0.8, "hammer|heavy"]],
		"keys": [[0.0, 24, 0, 0.0, 0.0, 1.0], [0.8, 22, 0, 0.0, 0.0, 1.0], [0.85, 22, 0, 0.0, 0.0, 0.9]],
		"events": [[0.5, "slowmo", 0.5], [0.85, "crack", "SKULL"], [0.86, "blood", 1.0], [0.87, "gore", ""]]},
	"flamingo_reaper": {"len": 2.2, "kill": 1.25, "zone": "blade", "decap": true,
		"clips": [[0.0, "side_kick"], [0.3, "side_kick"], [0.6, "side_kick"], [1.05, "jump_roundhouse|roundhouse"]],
		"keys": [[0.0, 30, 0, 0.0, 0.0, 1.0], [0.15, 32, 0, 0.3, 0.2, 1.0], [0.45, 38, 0, 0.2, -0.1, 0.96], [0.75, 46, -4, 0.35, 0.3, 1.0], [1.2, 48, -6, 0.2, 0.1, 1.0]],
		"events": [[0.15, "crack", "HEAD"], [0.45, "crack", "RIBS"], [0.75, "crack", "HEAD"], [1.05, "slowmo", 0.45], [1.24, "blood", 1.0]]},
}

## The hero's own clip for the move (Sorceress, one take for the whole
## timeline); without it the "clips" beats stitch it from stock moves.
const OWN := {"arm_breaker": "b_grab_break", "heart_punch": "b_heart_punch", "back_breaker": "b_back_breaker",
	"skull_crusher": "b_skull_clap", "eye_gouge": "b_eye_gouge", "neck_crack": "b_neck_twist",
	"death_touch": "b_death_touch", "flamingo_reaper": "b_flamingo"}
## Victim reaction clips (tools/hf_react.py) per move.
const REACT := {"knee_snap": "r_knee", "two_way": "r_knee", "eye_gouge": "r_blind", "death_touch": "r_heart", "heart_punch": "r_heart"}

var f: Fighter
var e: Punk
var _react := false
var _own := false
var id := ""
var _seq: Dictionary
var _t := 0.0
var _done := {}
var _dir := 1
var _sy := 1.0
var _heart: Polygon2D
var _pipe: Line2D
var _killed := false


static func start(by: Fighter, victim: Punk, move: String) -> BrutalRun:
	if not SEQ.has(move) or by == null or victim == null:
		return null
	var r := BrutalRun.new()
	r.f = by
	r.e = victim
	r.id = move
	by.get_parent().add_child(r)
	return r


func _ready() -> void:
	_seq = SEQ[id]
	_dir = 1 if e.global_position.x >= f.global_position.x else -1
	f.facing = _dir
	f.visual.scale.x = float(_dir)
	f._cancel_strike()
	f.art_lock = float(_seq["len"]) + 0.05
	f.invuln = maxi(f.invuln, int(float(_seq["len"]) * 60.0) + 10)
	e.set_physics_process(false)
	e.velocity = Vector2.ZERO
	e.telegraph = 0.0
	e.guarding = false
	e.z_index = -1
	_sy = e.visual.scale.y
	_own = OWN.has(id) and f._anim != null and f._anim.sprite_frames.has_animation(str(OWN[id]))
	# The thug's own reaction clip when he has one (knee folding, blinded,
	# heart stopping), else his hurt clip.
	var react := str(REACT.get(id, "hurt"))
	if e._anim and e._anim.sprite_frames.has_animation(react):
		e._anim.play(react)
		_react = react != "hurt"
	elif e._anim and e._anim.sprite_frames.has_animation("hurt"):
		e._anim.play("hurt")
	var r := BrutalBook.row(id)
	Juice.popup_number(f.global_position + Vector2(0, -112), str(r.get("title", id)), Color(1.0, 0.25, 0.2))
	Mixer.play_sfx("res://assets/audio/grab.wav", 0.9, -1.0)
	CouchCamera.punch(get_tree(), 0.1, float(_seq["len"]), f.global_position + Vector2(float(_dir) * 14.0, -40))


func _beat(at: float) -> bool:
	if _t >= at and not _done.has(at):
		_done[at] = true
		return true
	return false


func _physics_process(delta: float) -> void:
	if f == null or not is_instance_valid(f):
		queue_free()
		return
	_t += delta
	if _own:
		if _beat(0.0001):
			_clip(str(OWN[id]))
	else:
		for c: Array in _seq["clips"]:
			if _beat(float(c[0]) + 0.0001):
				_clip(str(c[1]))
	f._atk_t = 0.3
	if not _killed and e != null and is_instance_valid(e):
		_pose()
	for ev: Array in _seq["events"]:
		if _beat(float(ev[0])):
			_event(str(ev[1]), ev[2])
	if not _killed and _t >= float(_seq["kill"]):
		_kill()
	if _heart != null and is_instance_valid(_heart):
		_heart.global_position = f.global_position + Vector2(float(_dir) * 30.0, -44.0 - 10.0 * minf(1.0, (_t - 0.32) * 2.0))
	if _t >= float(_seq["len"]):
		_finish()


func _clip(spec: String) -> void:
	if f._anim == null:
		return
	for c in spec.split("|"):
		if f._anim.sprite_frames.has_animation(c):
			f._anim.stop()
			f._anim.play(c)
			f.anim_atk = c
			return


func _pose() -> void:
	var keys: Array = _seq["keys"]
	var k0: Array = keys[0]
	var k1: Array = keys[keys.size() - 1]
	for i in keys.size() - 1:
		if _t >= float(keys[i][0]) and _t <= float(keys[i + 1][0]):
			k0 = keys[i]
			k1 = keys[i + 1]
			break
	var u := 1.0 if _t >= float(k1[0]) else clampf((_t - float(k0[0])) / maxf(0.001, float(k1[0]) - float(k0[0])), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var v := []
	for j in range(1, 6):
		v.append(lerpf(float(k0[j]), float(k1[j]), u))
	e.global_position = Vector2(f.global_position.x + float(v[0]) * float(_dir), f.global_position.y + 1.0)
	e.visual.position.y = float(v[1])
	e.visual.rotation = float(v[2]) * float(_dir)
	e.visual.skew = float(v[3]) * float(_dir)
	e.visual.scale.y = _sy * float(v[4])


func _event(kind: String, arg: Variant) -> void:
	var host := get_parent()
	var at := e.global_position + Vector2(0, -50) if e != null and is_instance_valid(e) else f.global_position
	var blood := get_tree().get_first_node_in_group("blood_sim")
	match kind:
		"crack":
			Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", randf_range(0.85, 1.1), 0.0)
			Juice.hitstop(5)
			Juice.pulse_shake(6.0)
			Juice.popup_number(at + Vector2(0, -24), "%s  CRACK" % str(arg), Color(1, 0.92, 0.8))
			if blood:
				blood.spray(at, "clash", float(_dir))
		"blood":
			if blood and e != null and is_instance_valid(e):
				blood.hit(e, "gut", float(_dir), float(arg), 1.0)
				if float(arg) >= 0.9:
					blood.pump(e.global_position, float(_dir))
					blood.screen(float(_dir), 0.6)
		"scream":
			Juice.popup_number(at + Vector2(randf_range(-10, 10), -40), ["AAARGH", "NNGH!", "MY ARM", "NO NO NO"].pick_random() if id == "arm_breaker" else ["AAARGH", "NNGH!", "AAAH"].pick_random(), Color(1, 0.6, 0.5))
		"say":
			Juice.popup_number(at + Vector2(0, -64), str(arg), Color(1, 0.3, 0.25))
		"point":
			var p: Vector2 = arg
			ArtFx.spawn(host, e.global_position + Vector2(p.x * float(_dir), p.y), "burst", Color(1, 1, 1), 9.0, 0.18)
			Mixer.play_sfx("res://assets/audio/hit_light.wav", 1.6, -6.0)
		"eyes":
			if e != null and is_instance_valid(e):
				FaceDrip.bleed(e, e._anim, float(_dir), 1.0)
				FaceDrip.bleed(e, e._anim, -float(_dir), 1.0)
		"slowmo":
			Juice.set_world_scale(float(arg))
			get_tree().create_timer(0.55, true, false, true).timeout.connect(func() -> void: Juice.set_world_scale(1.0))
		"heart":
			_heart = Polygon2D.new()
			_heart.polygon = PackedVector2Array([Vector2(0, 5), Vector2(-5, 0), Vector2(-4, -4), Vector2(-1, -5), Vector2(0, -3), Vector2(1, -5), Vector2(4, -4), Vector2(5, 0)])
			_heart.color = Color(0.62, 0.04, 0.06)
			_heart.z_index = 40
			host.add_child(_heart)
			if blood:
				blood.spray(e.global_position + Vector2(-float(_dir) * 6.0, -50), "clash", -float(_dir))
			Juice.shout("HEART PUNCH")
		"pin":
			f.pickup = ""
			_pipe = Line2D.new()
			_pipe.points = PackedVector2Array([Vector2(-26, 0), Vector2(26, 0)])
			_pipe.width = 3.0
			_pipe.default_color = Color(0.45, 0.32, 0.2)
			_pipe.z_index = 30
			if e != null and is_instance_valid(e):
				e.add_child(_pipe)
				_pipe.position = Vector2(0, -46)
		"gore":
			if blood and blood.has_method("gore"):
				blood.gore(e.global_position if e != null and is_instance_valid(e) else at, float(_dir), "overkill")


func _kill() -> void:
	_killed = true
	if e == null or not is_instance_valid(e):
		return
	e.visual.position.y = 0.0
	e.visual.skew = 0.0
	e.visual.scale.y = _sy
	e.z_index = 0
	if e is TrainingDummy:
		# The dummy takes the show and stands back up: a rep on the mat.
		e.visual.rotation = 0.0
		e.set_physics_process(true)
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("gore") and bool(_seq.get("decap", false)):
			blood.gore(e.global_position + Vector2(0, -60), float(_dir), "kill")
		# The dojo school counts the rep (TRAIN lesson for "b_<id>").
		(e as TrainingDummy).struck.emit("b_" + id)
		return
	e.set_physics_process(true)
	e.visual.rotation = 0.0
	e.set_meta("brutal_zone", str(_seq.get("zone", "gut")))
	if bool(_seq.get("decap", false)):
		e.set_meta("brutal_decap", true)
	e.hp = 1
	e.guarding = false
	e.take_hit("finish", f)
	FamilyProfile.data["brutal_kills"] = int(FamilyProfile.data.get("brutal_kills", 0)) + 1
	BoneYard.note_brutal(id)
	if not bool(BrutalBook.row(id).get("big", false)):
		f.fury = minf(Fighter.FURY_MAX, f.fury + 10.0)
	Juice.kill_cam(e.global_position if is_instance_valid(e) else f.global_position)


func _finish() -> void:
	if not _killed:
		_kill()
	if _heart != null and is_instance_valid(_heart):
		var tw := _heart.create_tween()
		tw.tween_property(_heart, "modulate:a", 0.0, 0.4)
		tw.tween_callback(_heart.queue_free)
	if f != null and is_instance_valid(f):
		f.art_lock = 0.0
		f.anim_atk = ""
		f._atk_t = 0.0
	queue_free()
