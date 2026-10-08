class_name Runner
extends Node2D

## The rooftop runner. Momentum first, like a real body: it takes a few
## strides to reach top speed, keeps it through vaults and rolls, and
## loses it on bad landings and bumps.
##
## LEFT STICK   right runs (left brakes), UP jumps, DOWN slides.
## Near a low box UP is a vault, near a hut / wall it is a wall-run up and
## a mantle - the move is read from what is in front of you.
## TRICKS       hold the RIGHT STICK in a direction plus any of R1 / R2 /
##              L1 / L2 while you run (the trick shows over your head).
##              Let go and push LEFT STICK UP together: you jump and do it.
##              Let go close to the edge / obstacle = PERFECT.
## LANDING      a big drop wants a ROLL: both sticks down-forward as you
##              touch down. A smaller jump wants both sticks forward. Hit
##              it in the last moment before the feet touch = PERFECT
##              (speed boost); miss it and you stumble.
## (Keyboard: WASD = left stick, numpad / arrows = right stick, O / SHIFT /
##  I / U = R1 / R2 / L1 / L2, SPACE also jumps.)

signal event(kind: String, text: String, color: Color, pts: int)

const TOP := 290.0
const BOOST := 365.0
const ACC := 560.0
const COAST := 210.0
const BRAKE := 950.0
const G := 1300.0
const JUMP_V := 430.0
const ROLL_DROP := 95.0
const HALF_W := 9.0
const RELEASE_WIN := 0.22

## dir: right stick in 8 directions (F forward, B back, U up, D down).
## spin: forward flips (+) / back flips (-) in turns; twist: a body twist.
const TRICKS := [
	{"id": "tuck", "lv": 1, "name": "TUCK JUMP", "dir": "U", "btn": [], "spin": 0.0, "twist": 0, "clip": "jump", "pts": 4},
	{"id": "kong", "lv": 1, "name": "KONG SPIN", "dir": "F", "btn": ["R1"], "spin": 1.0, "twist": 0, "clip": "dive", "pts": 10},
	{"id": "backflip", "lv": 1, "name": "BACKFLIP", "dir": "U", "btn": ["L1"], "spin": -1.0, "twist": 0, "clip": "jump", "pts": 10},
	{"id": "webster", "lv": 2, "name": "WEBSTER", "dir": "U", "btn": ["R1"], "spin": 1.0, "twist": 0, "clip": "jump", "pts": 11},
	{"id": "dive", "lv": 3, "name": "FRONT DIVE", "dir": "D", "btn": ["R2"], "spin": 1.0, "twist": 0, "clip": "dive", "pts": 12},
	{"id": "aerial", "lv": 4, "name": "AERIAL", "dir": "F", "btn": ["L1"], "spin": 1.0, "twist": 0, "clip": "cartwheel_kick", "pts": 12},
	{"id": "cat", "lv": 5, "name": "CAT TWIST", "dir": "B", "btn": ["L2"], "spin": 0.0, "twist": 1, "clip": "air_mix", "pts": 12},
	{"id": "gainer", "lv": 6, "name": "GAINER", "dir": "B", "btn": ["R2"], "spin": -1.0, "twist": 0, "clip": "jump", "pts": 14},
	{"id": "palm", "lv": 7, "name": "PALM SPIN", "dir": "D", "btn": ["L1"], "spin": 1.0, "twist": 1, "clip": "air_mix", "pts": 14},
	{"id": "cork", "lv": 8, "name": "CORKSCREW", "dir": "UF", "btn": ["R1", "R2"], "spin": 1.0, "twist": 1, "clip": "air_spin_kick", "pts": 18},
	{"id": "superman", "lv": 9, "name": "SUPERMAN", "dir": "F", "btn": ["L2", "R2"], "spin": 0.0, "twist": 0, "clip": "superman_punch", "pts": 20, "lay": true},
	{"id": "tornado", "lv": 11, "name": "TORNADO", "dir": "UB", "btn": ["L1", "R1"], "spin": -2.0, "twist": 0, "clip": "jump_roundhouse", "pts": 24},
	{"id": "dbl_cork", "lv": 13, "name": "DOUBLE CORK", "dir": "DF", "btn": ["L1", "R1", "R2"], "spin": 2.0, "twist": 2, "clip": "air_spin_kick", "pts": 32},
]
const BTN_ACT := {"R1": "shoot", "L1": "block", "R2": "dash", "L2": "throw"}

## Tricks a ROOFTOPS level opens up (for the level-up toast and lists).
static func tricks_at(lv: int) -> Array:
	var out: Array = []
	for t in TRICKS:
		if int(t.get("lv", 1)) == lv:
			out.append(t)
	return out


## Test / attract mode: reads the course and plays like a decent runner
## (PARKOUR_AUTO=1 in the environment).
## Test: the autopilot mistimes some jumps and skips some landings.
static var autopilot_sloppy := false
static var autopilot := false
var _ap: Dictionary = {}

var prefix := "p1_"
var role := "son"
var course: RoofCourse
var vx := 0.0
var vy := 0.0
var state := "run"   # run air vault climb slide roll stumble out caught won
var grounded := true
var facing := 1
var lives := 3
var boost_t := 0.0
var chain := 0
var style := 0
var tricks_done := 0
var perfects := 0

var pivot: Node2D
var anim: AnimatedSprite2D
var _anim_base := Vector2.ZERO
var _shadow: Polygon2D
var _up_prev := false
var _coyote := 0.0
var _air_top := 0.0
var _air_trick: Dictionary = {}
var _air_rot_left := 0.0
var _air_rot_rate := 0.0
var _air_twist := 0.0
var _air_grade := ""
var _land_need := "run"
var _pose_t := -1.0
var _now := 0.0
var _t_state := 0.0
var _move: Dictionary = {}
var _load: Dictionary = {}       # dir, btn, t
var _released: Dictionary = {}   # dir, btn, at
var _step_frame := -1
var _ghost_t := 0.0
var _slide_hold := false
## Build of this runner: ROOFTOPS level, parkour tree and parkour META.
var top := TOP
var boost := BOOST
var jump_v := JUMP_V
var win_k := 1.0     # wider timing windows
var boost_len := 1.3
var boost_add := 55.0
var air_k := 1.0
var hang_k := 1.0
var coyote_t := 0.07
var score_k := 1.0
var iron := 0        # 1 big drops never stagger, 2 every hard landing rolls
var ghost_trick := false
var park_lv := 99
var _untouch := 0.0


func _ready() -> void:
	add_to_group("runners")
	z_index = 2
	_shadow = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		pts.append(Vector2(cos(a) * 16.0, 3.0 + sin(a) * 4.5))
	_shadow.polygon = pts
	_shadow.color = Color(0, 0, 0, 0.38)
	_shadow.z_index = -1
	_shadow.top_level = true
	add_child(_shadow)
	pivot = Node2D.new()
	pivot.position = Vector2(0, -34)
	add_child(pivot)
	anim = SpriteBook.make_anim(role)
	SpriteBook.grow(anim, SpriteBook.FIGHTER_SCALE * (SpriteBook.FATHER_K if role == "father" else 1.0))
	anim.position += Vector2(0, 34)
	_anim_base = anim.position
	pivot.add_child(anim)
	Suits.dress(anim, role)
	Palettes.apply(anim, role)
	_play("idle")
	_build()


## Everything bought for the ROOFTOPS: level, PARKOUR tree, parkour META.
func _build() -> void:
	var lv := Heroes.level(role, "parkour")
	park_lv = 99 if autopilot else lv
	var spd := Meta.run_speed_mul() * (1.08 if Trees.has("p_speed") else 1.0) * (1.0 + 0.008 * float(lv - 1))
	top = TOP * spd + Heroes.speed_bonus(role) * 0.5
	boost = BOOST * spd + Heroes.speed_bonus(role) * 0.5
	jump_v = JUMP_V * Meta.jump_mul() * (1.06 if Trees.has("p_high") else 1.0)
	win_k = Heroes.trick_window_mul(role)
	boost_len = 1.3 * (1.5 if Trees.has("p_chain") else 1.0) * (1.0 + 0.25 * float(Meta.rank("flow_state")))
	boost_add = 55.0 * Meta.flow_mul()
	air_k = Meta.air_mul() * (1.5 if Trees.has("p_air_ctrl") else 1.0)
	hang_k = 0.55 if Trees.has("p_hang") else 1.0
	coyote_t = 0.07 * (2.0 if Trees.has("p_coyote") else 1.0)
	score_k = (2.0 if Trees.has("p_score") else 1.0) * (1.0 + 0.2 * float(Meta.rank("trick_value")))
	iron = maxi(Meta.rank("iron_ankles"), 1 if Trees.has("p_iron") else 0)
	ghost_trick = Trees.has("p_ghost")


# --- Input -------------------------------------------------------------------

func _ls() -> Vector2:
	if autopilot:
		return _ap.get("ls", Vector2(1, 0))
	return PadRouter.stick(prefix)


func _rs() -> Vector2:
	if autopilot:
		return _ap.get("rs", Vector2.ZERO)
	var v := PadRouter.rstick(prefix)
	if v != Vector2.ZERO or prefix != "p1_":
		return v
	var k := Vector2.ZERO
	var solo := get_tree().get_nodes_in_group("runners").size() <= 1
	if Input.is_physical_key_pressed(KEY_KP_4) or Input.is_physical_key_pressed(KEY_KP_7) or Input.is_physical_key_pressed(KEY_KP_1) or (solo and Input.is_physical_key_pressed(KEY_LEFT)):
		k.x -= 1.0
	if Input.is_physical_key_pressed(KEY_KP_6) or Input.is_physical_key_pressed(KEY_KP_9) or Input.is_physical_key_pressed(KEY_KP_3) or (solo and Input.is_physical_key_pressed(KEY_RIGHT)):
		k.x += 1.0
	if Input.is_physical_key_pressed(KEY_KP_8) or Input.is_physical_key_pressed(KEY_KP_7) or Input.is_physical_key_pressed(KEY_KP_9) or (solo and Input.is_physical_key_pressed(KEY_UP)):
		k.y -= 1.0
	if Input.is_physical_key_pressed(KEY_KP_2) or Input.is_physical_key_pressed(KEY_KP_1) or Input.is_physical_key_pressed(KEY_KP_3) or (solo and Input.is_physical_key_pressed(KEY_DOWN)):
		k.y += 1.0
	return k.normalized()


func _btns() -> Array:
	if autopilot:
		return _ap.get("btn", [])
	var out: Array = []
	for b in ["R1", "R2", "L1", "L2"]:
		if Input.is_action_pressed(StringName(prefix + str(BTN_ACT[b]))):
			out.append(b)
	return out


static func dir8(v: Vector2) -> String:
	if v.length() < 0.5:
		return ""
	var a := rad_to_deg(atan2(-v.y, v.x))
	var codes := ["F", "UF", "U", "UB", "B", "DB", "D", "DF"]
	var i := int(round(wrapf(a, 0.0, 360.0) / 45.0)) % 8
	return codes[i]


static func dir_ok(v: Vector2, code: String) -> bool:
	if code == "":
		return v.length() < 0.35
	return dir8(v) == code or (code.length() == 1 and dir8(v).contains(code) and v.length() > 0.5)


## The trick for this stick direction + buttons. Tricks above the ROOFTOPS
## level come out as a FREESTYLE (still a flip, fewer points) tagged with the
## level that unlocks them.
static func find_trick(dir: String, btn: Array, lv: int = 99) -> Dictionary:
	var want := btn.duplicate()
	want.sort()
	for t in TRICKS:
		var b: Array = (t["btn"] as Array).duplicate()
		b.sort()
		if str(t["dir"]) == dir and b == want:
			if int(t.get("lv", 1)) <= lv:
				return t
			var fr: Dictionary = (t as Dictionary).duplicate()
			fr["name"] = "FREESTYLE"
			fr["pts"] = 6 + 2 * btn.size()
			fr["locked"] = int(t.get("lv", 1))
			return fr
	if btn.is_empty():
		var nm := {"F": "LONG JUMP", "UF": "TIC TAC", "D": "DROP JUMP", "DF": "DIVE JUMP", "B": "LEAN BACK", "UB": "LAZY JUMP", "DB": "TUCK DROP"}.get(dir, "AIR") as String
		return {} if dir == "" else {"id": "air", "name": nm, "dir": dir, "btn": [], "spin": 0.0, "twist": 0, "clip": "jump", "pts": 3}
	var s := -1.0 if dir.contains("B") or dir == "U" else 1.0
	return {"id": "free", "name": "FREESTYLE", "dir": dir, "btn": btn, "spin": s, "twist": 1 if btn.size() > 1 else 0, "clip": "air_mix", "pts": 6 + 2 * btn.size()}


## The trick being held now, or the one let go of a moment ago.
func armed() -> Dictionary:
	if not _load.is_empty():
		return find_trick(str(_load.get("dir", "")), _load.get("btn", []), park_lv)
	if not _released.is_empty() and _now - float(_released["at"]) <= RELEASE_WIN * win_k:
		return find_trick(str(_released.get("dir", "")), _released.get("btn", []), park_lv)
	return {}


func loading() -> Dictionary:
	return _load


func _tick_load(delta: float) -> void:
	var rs := _rs()
	var bt := _btns()
	var holding := rs.length() > 0.5 or not bt.is_empty()
	if holding:
		if _load.is_empty():
			_load = {"dir": "", "btn": [], "t": 0.0}
		var d := dir8(rs)
		if d != "":
			_load["dir"] = d
		var lb: Array = _load["btn"]
		for b in bt:
			if not lb.has(b):
				lb.append(b)
		_load["t"] = float(_load["t"]) + delta
	elif not _load.is_empty():
		_released = {"dir": _load["dir"], "btn": _load["btn"], "at": _now}
		_load = {}


# --- Main loop -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if course == null:
		return
	_now += delta
	_t_state += delta
	boost_t = maxf(0.0, boost_t - delta)
	_untouch = maxf(0.0, _untouch - delta)
	if autopilot:
		_autopilot()
	var ls := _ls()
	var up_now := ls.y < -0.55 or (not autopilot and Input.is_action_pressed(StringName(prefix + "jump")))
	var up_edge := up_now and not _up_prev
	_up_prev = up_now
	var down_now := ls.y > 0.55 or (not autopilot and Input.is_action_pressed(StringName(prefix + "duck")))
	if state in ["run", "slide", "air", "roll"]:
		_tick_load(delta)
	match state:
		"run":
			_run(delta, ls, up_edge, down_now)
		"slide":
			_slide(delta, ls, up_edge, down_now)
		"roll":
			_roll(delta)
		"air":
			_air(delta, ls)
		"vault", "climb":
			_tick_move(delta)
		"fail":
			_tick_fail(delta)
		"stumble":
			vx = move_toward(vx, 0.0, 500.0 * delta)
			_ground_follow(delta)
			if _t_state > float(_move.get("t", 0.45)):
				_set_state("run")
		"out", "caught", "won":
			pass
	_visuals(delta)


func _set_state(s: String) -> void:
	state = s
	_t_state = 0.0


func _speed_cap() -> float:
	return boost if boost_t > 0.0 else top


func _accel(delta: float, ls: Vector2) -> void:
	if ls.x > 0.25:
		var cap := _speed_cap() * clampf(ls.x * 1.1, 0.4, 1.0)
		if vx < cap:
			# Real sprint curve: strong first strides, flattening near the top.
			var k := 1.0 - clampf(vx / cap, 0.0, 1.0) * 0.6
			vx = minf(cap, vx + ACC * k * delta)
		else:
			vx = move_toward(vx, cap, COAST * delta)
	elif ls.x < -0.25:
		vx = move_toward(vx, -60.0, BRAKE * delta)
	else:
		vx = move_toward(vx, 0.0, COAST * delta)


func _run(delta: float, ls: Vector2, up_edge: bool, down_now: bool) -> void:
	_accel(delta, ls)
	# Contextual: what is in front decides what UP means.
	if up_edge:
		if _try_vault() or _try_climb():
			return
		_jump(jump_v + vx * 0.12)
		return
	if down_now and vx > 110.0:
		_set_state("slide")
		_play("slide")
		Mixer.play_sfx("res://assets/audio/sfx/roll.ogg", 1.2, -8.0)
		return
	_walk(delta)


## Move along the roof; walls stop you, drops start a fall, ramps launch.
func _walk(delta: float) -> void:
	var feet := position.y
	var step := vx * delta
	if step > 0.0:
		var w := course.wall_ahead(position.x, feet, step + HALF_W + 2.0)
		if not w.is_empty() and float(w["top"]) < feet - 14.0:
			position.x = float(w["x"]) - HALF_W - 1.0
			if vx > 120.0:
				_stumble("BUMP", 0.4)
			vx = 0.0
			return
	position.x += step
	_hazards()
	if state != "run" and state != "slide":
		return
	var r := course.ramp_at(position.x)
	if not r.is_empty() and vx > 150.0:
		_jump(560.0 + vx * 0.2)
		event.emit("ramp", "RAMP", Color(1.0, 0.8, 0.4), 0)
		return
	_ground_follow(delta)


func _ground_follow(delta: float) -> void:
	var g := course.ground_at(position.x, HALF_W)
	if g == INF or g > position.y + 6.0:
		_coyote += delta
		if _coyote > coyote_t:
			_start_fall()
		return
	_coyote = 0.0
	position.y = g


func _start_fall() -> void:
	vy = 0.0
	_air_top = position.y
	_air_trick = {}
	_air_rot_left = 0.0
	_air_grade = ""
	_set_state("air")
	grounded = false
	_play("jump")


func _hazards() -> void:
	# Overhead pipes: standing tall into one is a head bonk.
	var br := course.bar_at(position.x)
	if not br.is_empty() and state == "run" and position.y > float(br["under"]) + 30.0:
		vx *= 0.25
		_stumble("HEAD BONK", 0.55)
		position.x = float(br["x0"]) - HALF_W - 2.0
		return
	for gd in course.guards:
		var g := gd as RoofGuard
		if g == null or g.down:
			continue
		if absf(g.position.x - position.x) < 16.0 and absf(g.position.y - position.y) < 20.0:
			if state == "slide":
				g.knock("slide")
				_score("SLIDE TACKLE", 8, Color(0.6, 1.0, 0.7))
			elif _untouch > 0.0:
				g.knock("slide")
				_score("GHOSTED", 6, Color(0.7, 0.9, 1.0))
			else:
				vx *= 0.15
				position.x = g.position.x - 24.0
				_stumble("BATON", 0.6)


# --- Contextual moves ------------------------------------------------------------

func _try_vault() -> bool:
	var feet := position.y
	var target := {}
	for bx in course.boxes:
		if str(bx["type"]) != "vault":
			continue
		var d := float(bx["x0"]) - position.x
		if d > -6.0 and d < 78.0 and float(bx["top"]) > feet - 44.0:
			target = {"x0": float(bx["x0"]), "x1": float(bx["x1"]), "top": float(bx["top"]), "name": "VAULT"}
			break
	if target.is_empty():
		for gd in course.guards:
			var g := gd as RoofGuard
			if g and not g.down:
				var d2 := g.position.x - position.x
				if d2 > -4.0 and d2 < 80.0 and absf(g.position.y - feet) < 20.0:
					target = {"x0": g.position.x - 14.0, "x1": g.position.x + 14.0, "top": feet - 58.0, "name": "KONG OVER", "guard": g}
					break
	if target.is_empty():
		return false
	var tr := armed()
	var grade := _grade_release(float(target["x0"]))
	var x1 := float(target["x1"]) + 34.0
	var speed := maxf(vx, 200.0)
	var dur := clampf((x1 - position.x) / speed, 0.26, 0.6)
	var land_y := course.ground_at(x1, HALF_W)
	if land_y == INF:
		land_y = feet
	_move = {"kind": "vault", "x0": position.x, "y0": feet, "x1": x1, "y1": land_y, "arc": maxf(feet - float(target["top"]) + 14.0, 22.0), "dur": dur, "trick": tr}
	_set_state("vault")
	vx = maxf(vx, 210.0) * 1.04
	var clip := "dive" if not tr.is_empty() and str(tr["clip"]) == "dive" else ("dive" if role == "son" else "jump")
	_play(str(tr["clip"]) if not tr.is_empty() and anim.sprite_frames.has_animation(str(tr["clip"])) else clip)
	if target.has("guard"):
		(target["guard"] as RoofGuard).knock("kong")
	var pts := 5 if not target.has("guard") else 10
	var name := str(target["name"])
	if not tr.is_empty():
		pts += int(tr["pts"])
		name = "%s %s" % [str(tr["name"]), name]
		_air_rot_left = float(tr["spin"]) * TAU
		_air_rot_rate = _air_rot_left / (dur * 0.85)
		_air_twist = float(tr.get("twist", 0))
		_released = {}
	_score(name, int(pts * _grade_mult(grade)), _grade_col(grade), grade)
	Mixer.play_sfx("res://assets/audio/sfx/whoosh_spin.ogg" if not tr.is_empty() else "res://assets/audio/whoosh_light.wav", randf_range(0.95, 1.1), -6.0)
	return true


func _try_climb() -> bool:
	var feet := position.y
	var w := course.wall_ahead(position.x, feet, 50.0)
	if w.is_empty():
		return false
	var h := feet - float(w["top"])
	if str(w["kind"]) == "vault" or h < 14.0:
		return false
	if h > 150.0 or vx < 50.0:
		return false
	var fx := float(w["x"])
	_move = {"kind": "climb", "x0": position.x, "y0": feet, "wall": fx, "top": float(w["top"]), "dur": (0.2 + h * 0.0024) * (1.0 if vx > 150.0 else 1.35), "v_in": vx}
	_set_state("climb")
	_play("jump")
	Mixer.play_sfx("res://assets/audio/sfx/wall_kick.ogg", randf_range(0.95, 1.05), -5.0)
	_score("WALL RUN", 4 + int(h / 20.0), Color(0.7, 0.85, 1.0))
	return true


func _tick_move(delta: float) -> void:
	var m := _move
	var dur := float(m.get("dur", 0.3))
	var k := clampf(_t_state / dur, 0.0, 1.0)
	if str(m["kind"]) == "vault":
		position.x = lerpf(float(m["x0"]), float(m["x1"]), k)
		position.y = lerpf(float(m["y0"]), float(m["y1"]), k) - sin(PI * k) * float(m["arc"])
		if _air_rot_left != 0.0:
			var dr := _air_rot_rate * delta
			if absf(dr) > absf(_air_rot_left):
				dr = _air_rot_left
			pivot.rotation += dr
			_air_rot_left -= dr
		if k >= 1.0:
			pivot.rotation = 0.0
			_air_rot_left = 0.0
			_set_state("run")
			_play("parkour_run")
			Mixer.play_sfx("res://assets/audio/sfx/land.ogg", randf_range(1.05, 1.2), -10.0)
	else:
		# Wall run up the face, then a mantle onto the top.
		var top := float(m["top"])
		var wall := float(m["wall"])
		if k < 0.72:
			var kk := k / 0.72
			position.x = lerpf(float(m["x0"]), wall - HALF_W, minf(1.0, kk * 2.0))
			position.y = lerpf(float(m["y0"]), top + 10.0, kk)
		else:
			var kk2 := (k - 0.72) / 0.28
			position.x = lerpf(wall - HALF_W, wall + 18.0, kk2)
			position.y = lerpf(top + 10.0, top, kk2)
			if anim.animation != "roll" and anim.sprite_frames.has_animation("land"):
				_play("land")
		if k >= 1.0:
			vx = maxf(float(m["v_in"]) * 0.6, 130.0)
			_set_state("run")
			_play("parkour_run")


func _slide(delta: float, ls: Vector2, up_edge: bool, down_now: bool) -> void:
	vx = move_toward(vx, 140.0, 140.0 * delta)
	var under := not course.bar_at(position.x).is_empty() or not course.bar_at(position.x + 30.0).is_empty()
	if up_edge and not under:
		_set_state("run")
		_jump(jump_v * 0.9)
		return
	if (_t_state > 0.65 and not down_now and not under) or vx < 60.0 and not under:
		_set_state("run")
		_play("parkour_run")
		return
	_walk(delta)


func _roll(delta: float) -> void:
	vx = move_toward(vx, _speed_cap() * 0.92, 120.0 * delta)
	_walk(delta)
	if _t_state > 0.42 and state == "roll":
		_set_state("run")
		_play("parkour_run")


func _stumble(text: String, t: float) -> void:
	_move = {"t": t}
	chain = 0
	_set_state("stumble")
	_play("hurt")
	pivot.rotation = 0.0
	Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", randf_range(0.95, 1.1), -6.0)
	event.emit("stumble", text, Color(1.0, 0.45, 0.35), 0)
	if autopilot:
		print("PK_STUMBLE ", text, " ", Engine.get_process_frames())


## EPIC FAIL, three ways down:
##   trip  catches a foot, flails, nearly eats it, keeps his feet (shortest)
##   face  pitches forward flat on his chest, pushes himself back up
##   back  feet fly out, lands on his back, rolls over and gets up
## Uses the fail_<kind> clip when the son has one, else a posed fall.
func _epic_fail(kind: String, text: String) -> void:
	chain = 0
	var dur: float = {"trip": 0.9, "face": 1.5, "back": 1.6}[kind]
	_move = {"t": dur, "kind": kind}
	_set_state("fail")
	pivot.rotation = 0.0
	vx *= 0.35 if kind == "trip" else 0.15
	var clip := "fail_" + kind
	if anim.sprite_frames.has_animation(clip):
		_play(clip)
		_move["clip"] = true
	else:
		_play("hurt" if kind == "trip" else ("knockdown" if anim.sprite_frames.has_animation("knockdown") else "hurt"))
		_move["clip"] = false
	Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", randf_range(0.8, 0.95), -2.0)
	Juice.land_puff(global_position)
	event.emit("epic", text, Color(1.0, 0.25, 0.25), 0)
	if autopilot:
		print("PK_EPIC ", kind, " ", Engine.get_process_frames())


## Posed fall when there is no clip: lean, hit the roof, lie, get up.
func _tick_fail(delta: float) -> void:
	vx = move_toward(vx, 0.0, 420.0 * delta)
	_ground_follow(delta)
	var t := _t_state
	var dur := float(_move.get("t", 1.2))
	var kind := str(_move.get("kind", "trip"))
	if not bool(_move.get("clip", false)):
		var k := clampf(t / 0.28, 0.0, 1.0)
		var up := clampf((t - (dur - 0.45)) / 0.45, 0.0, 1.0)
		match kind:
			"trip":
				pivot.rotation = sin(clampf(t / dur, 0.0, 1.0) * PI) * 0.55
			"face":
				pivot.rotation = lerpf(0.0, 1.45, ease(k, 0.4)) * (1.0 - ease(up, 2.0))
			"back":
				pivot.rotation = lerpf(0.0, -1.4, ease(k, 0.4)) * (1.0 - ease(up, 2.0))
		if kind != "trip" and t > 0.25 and t < dur - 0.45:
			pivot.rotation += sin(t * 30.0) * 0.02 * clampf(0.5 - (t - 0.25), 0.0, 0.5)
	if t >= dur:
		pivot.rotation = 0.0
		_set_state("run")
		_play("parkour_run")


# --- Jumping and tricks ------------------------------------------------------------

func _jump(v: float) -> void:
	var tr := armed()
	_air_trick = tr
	vy = -v
	_air_top = position.y
	_set_state("air")
	grounded = false
	_air_grade = _grade_release(_takeoff_x())
	if _air_grade == "bad":
		# Mistimed push: less pop, less speed.
		vy *= 0.88
		vx *= 0.85
		event.emit("bad", "BAD TIMING", _grade_col("bad"), 0)
		if autopilot:
			print("PK_BADT ", Engine.get_process_frames())
	elif _air_grade == "epic":
		vy *= 0.75
		vx *= 0.7
		event.emit("epic_take", "WAY OFF", _grade_col("epic"), 0)
	if not tr.is_empty():
		_released = {}
		var air_t := _predict_air(vx, vy)
		var turns := float(tr.get("spin", 0.0))
		_air_rot_left = turns * TAU
		_air_rot_rate = _air_rot_left / maxf(0.2, air_t * 0.8)
		_air_twist = float(tr.get("twist", 0))
		var clip := str(tr.get("clip", "jump"))
		_play(clip if anim.sprite_frames.has_animation(clip) else "jump")
		Mixer.play_sfx("res://assets/audio/sfx/whoosh_spin.ogg", randf_range(0.9, 1.1), -4.0)
		event.emit("trick_call", str(tr["name"]), Color(0.75, 0.9, 1.0), 0)
	else:
		_air_rot_left = 0.0
		_play("jump")
	Mixer.play_sfx("res://assets/audio/jump_%s.wav" % role if ResourceLoader.exists("res://assets/audio/jump_%s.wav" % role) else "res://assets/audio/jump.wav", randf_range(0.95, 1.05), -6.0)


## Where you should leave the ground: the roof edge, or the front of what
## you are jumping. INF when there is nothing to time against.
func _takeoff_x() -> float:
	var e := course.edge_ahead(position.x)
	if e != INF and e - position.x < 260.0:
		var next := course.ground_at(e + 30.0)
		if next == INF or absf(next - position.y) > 8.0:
			return e
	return INF


func _grade_release(target_x: float) -> String:
	if target_x == INF:
		return "flow"
	var d := target_x - position.x
	# Left the roof already (coyote jump) or jumped way before the edge.
	if d < -26.0 or d > 170.0:
		return "epic"
	if d < -4.0 or d > 90.0:
		return "bad"
	if d <= 24.0 * win_k:
		return "perfect"
	if d <= 48.0 * win_k:
		return "good"
	return "ok"


func _grade_mult(g: String) -> float:
	return {"perfect": 2.0, "good": 1.4, "ok": 1.0, "flow": 0.8, "bad": 0.4, "epic": 0.0}.get(g, 1.0)


func _grade_col(g: String) -> Color:
	return {"perfect": Color(1.0, 0.85, 0.3), "good": Color(0.55, 1.0, 0.6), "ok": Color(0.8, 0.85, 0.95), "bad": Color(1.0, 0.55, 0.3), "epic": Color(1.0, 0.25, 0.25)}.get(g, Color(0.7, 0.7, 0.75))


## Seconds until the feet would touch something, flying with this speed.
func _predict_air(svx: float, svy: float) -> float:
	var x := position.x
	var y := position.y
	var t := 0.0
	while t < 2.5:
		t += 1.0 / 60.0
		svy += G / 60.0
		x += svx / 60.0
		y += svy / 60.0
		if svy > 0.0:
			var g := course.ground_at(x, HALF_W)
			if g != INF and y >= g:
				return t
	return 1.2


func _air(delta: float, ls: Vector2) -> void:
	# A little air control, like leaning the body.
	if ls.x > 0.3:
		vx = move_toward(vx, _speed_cap(), 120.0 * air_k * delta)
	elif ls.x < -0.3:
		vx = move_toward(vx, 40.0, 260.0 * air_k * delta)
	var prev_y := position.y
	# The top of the arc hangs (HANG TIME floats it longer).
	var grav := G * (0.7 * hang_k if absf(vy) < 90.0 else 1.0)
	vy = minf(vy + grav * delta, 1500.0)
	_air_top = minf(_air_top, position.y)
	var step := vx * delta
	if step > 0.0:
		var w := course.wall_ahead(position.x, position.y, step + HALF_W + 2.0)
		if not w.is_empty():
			var top := float(w["top"])
			if top >= position.y - 48.0 and top < position.y and vy > -200.0:
				# Caught the ledge: pull up onto it.
				_move = {"kind": "climb", "x0": position.x, "y0": position.y, "wall": float(w["x"]), "top": top, "dur": 0.26, "v_in": maxf(vx, 160.0)}
				_air_rot_left = 0.0
				pivot.rotation = 0.0
				_set_state("climb")
				_play("jump")
				_score("LEDGE GRAB", 3, Color(0.7, 0.85, 1.0))
				return
			position.x = float(w["x"]) - HALF_W - 1.0
			vx = 0.0
			step = 0.0
	position.x += step
	position.y += vy * delta
	if _air_rot_left != 0.0:
		var dr := _air_rot_rate * delta
		if absf(dr) > absf(_air_rot_left):
			dr = _air_rot_left
		pivot.rotation += dr
		_air_rot_left -= dr
	if _air_twist > 0.0:
		anim.scale.x = absf(anim.scale.x) * (1.0 if fmod(_now * 9.0, 2.0) < 1.0 else -1.0)
	_land_need = "roll" if course.ground_at(position.x + vx * 0.15, HALF_W) - _air_top > ROLL_DROP else "run"
	_track_pose()
	if vy > 0.0:
		var g := course.ground_at(position.x, HALF_W)
		if g != INF and position.y >= g and prev_y <= g + 14.0:
			position.y = g
			_land(g - _air_top)
			return
	# Fell between the buildings.
	var b := course.building_at(position.x)
	var floor_y := float(b["y"]) if not b.is_empty() else course.ROOF_BASE + 260.0
	if position.y > floor_y + 380.0 or position.y > course.ROOF_BASE + 700.0:
		_set_state("out")
		event.emit("fall", "FELL", Color(1.0, 0.35, 0.3), 0)


func _pose_ok(need: String) -> bool:
	var ls := _ls()
	var rs := _rs()
	if need == "roll":
		return ls.x > 0.3 and ls.y > 0.3 and rs.x > 0.3 and rs.y > 0.3
	return ls.x > 0.45 and absf(ls.y) < 0.55 and rs.x > 0.45 and absf(rs.y) < 0.55


func _track_pose() -> void:
	if vy < 0.0:
		_pose_t = -1.0
		return
	if _pose_ok(_land_need):
		if _pose_t < 0.0:
			_pose_t = _now
	else:
		_pose_t = -1.0


func landing_need() -> String:
	return _land_need if state == "air" and vy > 0.0 else ""


func _land(drop: float) -> void:
	grounded = true
	anim.scale.x = absf(anim.scale.x)
	var bailed := absf(_air_rot_left) > 0.7
	pivot.rotation = 0.0
	_air_rot_left = 0.0
	_air_twist = 0.0
	var need := "roll" if drop > ROLL_DROP else "run"
	var trick := _air_trick
	_air_trick = {}
	if bailed:
		# Still mid-spin when the roof arrives: over the head or on the back.
		_epic_fail("face" if _air_rot_rate > 0.0 else "back", "BAIL")
		return
	if _air_grade == "epic" and drop > 20.0:
		_epic_fail("trip", "EPIC FAIL")
		return
	if drop < 28.0 and trick.is_empty():
		_set_state("run")
		_play("parkour_run")
		return
	var held := _pose_t >= 0.0 and _pose_ok(need)
	var lead := _now - _pose_t if held else 99.0
	var land_grade := "miss"
	if held:
		land_grade = "perfect" if lead <= 0.16 * win_k else "good"
	Juice.land_puff(global_position)
	if land_grade == "miss" and need == "roll" and iron >= 2:
		# IRON ANKLES II: the body rolls it out on its own.
		land_grade = "good"
	if land_grade == "miss":
		if need == "roll" and iron >= 1:
			vx *= 0.6
			_set_state("run")
			_play("parkour_run")
			event.emit("sloppy", "IRON ANKLES", Color(0.75, 0.8, 0.9), 0)
			return
		elif need == "roll" and drop > ROLL_DROP * 1.7:
			# A big drop with no roll: the legs fold.
			_epic_fail("face" if vx > 200.0 else "back", "EPIC FAIL")
			return
		if need == "roll":
			vx *= 0.22
			_stumble("HARD LANDING", 0.8)
			event.emit("hard", "", Color.WHITE, 0)
		else:
			# BAD landing: a stumble step and most of the speed gone.
			vx *= 0.55
			_stumble("BAD LANDING", 0.45)
			event.emit("bad", "", Color.WHITE, 0)
		if not trick.is_empty():
			_score(str(trick["name"]), int(float(trick["pts"]) * 0.5), Color(0.75, 0.75, 0.8), _air_grade)
		Mixer.play_sfx("res://assets/audio/sfx/land.ogg", 0.85, -2.0)
		return
	if need == "roll":
		_set_state("roll")
		_play("roll")
		Mixer.play_sfx("res://assets/audio/sfx/roll.ogg", randf_range(0.95, 1.05), -4.0)
	else:
		_set_state("run")
		_play("parkour_run")
		Mixer.play_sfx("res://assets/audio/sfx/land.ogg", randf_range(1.0, 1.15), -6.0)
	if land_grade == "perfect":
		boost_t = boost_len
		vx = maxf(vx, top) + boost_add
		if ghost_trick:
			_untouch = 0.5
		chain += 1
		perfects += 1
		event.emit("perfect_land", "PERFECT %s" % ("ROLL" if need == "roll" else "LANDING"), Color(1.0, 0.85, 0.3), 6 * chain)
		Mixer.play_sfx("res://assets/audio/sfx/perfect_sting.ogg", 1.0, -6.0)
	else:
		event.emit("good_land", "CLEAN " + ("ROLL" if need == "roll" else "LANDING"), Color(0.55, 1.0, 0.6), 3)
	if not trick.is_empty():
		var mult := _grade_mult(_air_grade) * (1.0 + 0.25 * float(chain))
		_score(str(trick["name"]), int(float(trick["pts"]) * mult), _grade_col(_air_grade), _air_grade)
		tricks_done += 1
		if _air_grade == "perfect":
			event.emit("trick_perfect", "", Color.WHITE, 0)


func _score(name: String, pts: int, col: Color, grade: String = "") -> void:
	pts = int(round(float(pts) * score_k))
	style += pts
	var txt := name if grade == "" or grade == "flow" else "%s  %s" % [grade.to_upper(), name]
	event.emit("score", txt, col, pts)


# --- Respawn / end -----------------------------------------------------------------

func respawn(at_x: float) -> void:
	position.x = at_x
	position.y = course.ground_at(at_x, HALF_W)
	vx = 0.0
	vy = 0.0
	pivot.rotation = 0.0
	anim.scale.x = absf(anim.scale.x)
	_air_rot_left = 0.0
	chain = 0
	_set_state("run")
	_play("idle")


func caught() -> void:
	_set_state("caught")
	vx = 0.0
	pivot.rotation = 0.0
	_play("knockdown" if anim.sprite_frames.has_animation("knockdown") else "hurt")


func win() -> void:
	_set_state("won")
	_play("jump")


# --- Visuals ------------------------------------------------------------------

func _play(clip: String) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if not anim.sprite_frames.has_animation(clip):
		clip = "jump" if anim.sprite_frames.has_animation("jump") else "idle"
	if anim.animation != clip:
		anim.play(clip)
		anim.speed_scale = 1.0


func _visuals(delta: float) -> void:
	if state == "run":
		if absf(vx) < 18.0:
			_play("idle")
		else:
			_play("parkour_run" if anim.sprite_frames.has_animation("parkour_run") else "walk")
			anim.speed_scale = SpriteBook.stride_rate(anim, anim.animation, vx)
			# Footsteps on the stride.
			var f := anim.frame
			var n := anim.sprite_frames.get_frame_count(anim.animation)
			if (f == 0 or f == n / 2) and f != _step_frame:
				Mixer.play_sfx("res://assets/audio/sfx/foot_%d.ogg" % (1 + randi() % 4), randf_range(0.95, 1.1), -16.0 + minf(6.0, vx / 60.0))
			_step_frame = f
		# Lean into the run.
		pivot.rotation = lerpf(pivot.rotation, clampf(vx / TOP, 0.0, 1.2) * 0.06, 1.0 - exp(-10.0 * delta))
	elif state == "slide" or state == "roll":
		pivot.rotation = lerpf(pivot.rotation, 0.0, 1.0 - exp(-14.0 * delta))
	# Shadow on the surface below.
	var g := course.ground_at(position.x, HALF_W) if course else INF
	_shadow.visible = g != INF and state != "out"
	if _shadow.visible:
		var hgt := clampf((g - position.y) / 200.0, 0.0, 1.0)
		_shadow.global_position = Vector2(global_position.x, g + global_position.y - position.y)
		_shadow.scale = Vector2.ONE * (1.0 - hgt * 0.6)
		_shadow.color.a = 0.38 - hgt * 0.25
	# Speed ghosts while boosting.
	_ghost_t -= delta
	if boost_t > 0.0 and _ghost_t <= 0.0 and anim.sprite_frames != null:
		_ghost_t = 0.05
		var s := Sprite2D.new()
		s.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
		s.global_transform = anim.global_transform
		s.centered = anim.centered
		s.offset = anim.offset
		s.flip_h = anim.flip_h
		s.modulate = Color(1.0, 0.75, 0.4, 0.45)
		s.z_index = 1
		get_parent().add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "modulate:a", 0.0, 0.25)
		tw.tween_callback(s.queue_free)


func _autopilot() -> void:
	var ls := Vector2(1, 0)
	var rs := Vector2.ZERO
	var btn: Array = []
	var x := position.x
	if state == "air":
		if vy > 0.0:
			var g := course.ground_at(x + vx * 0.1, HALF_W)
			if g != INF and g - position.y < 70.0 and not (autopilot_sloppy and int(position.x / 400.0) % 2 == 1):
				var pose := Vector2(0.75, 0.75) if _land_need == "roll" else Vector2(1, 0)
				ls = pose
				rs = pose
	elif state in ["run", "slide"]:
		var br := course.bar_ahead(x, 60.0 + vx * 0.12)
		var under := not course.bar_at(x).is_empty() or not course.bar_at(x + 30.0).is_empty()
		if not br.is_empty() or under:
			ls = Vector2(0.6, 0.8)
		var w := course.wall_ahead(x, position.y, 44.0)
		var vault_near := false
		for bx in course.boxes:
			var d := float(bx["x0"]) - x
			if str(bx["type"]) == "vault" and d > 0.0 and d < 40.0:
				vault_near = true
		for gd in course.guards:
			var gg := gd as RoofGuard
			if gg and not gg.down and gg.position.x - x > 0.0 and gg.position.x - x < 46.0:
				vault_near = true
		var edge := _takeoff_x()
		var d_edge := edge - x if edge != INF else INF
		# Load a trick on the way to an edge, let go right at it.
		if d_edge != INF and d_edge < 220.0 and d_edge > 16.0:
			var pick: Dictionary = TRICKS[int(abs(int(edge))) % TRICKS.size()]
			rs = Runner.dir_vec(str(pick["dir"]))
			btn = (pick["btn"] as Array).duplicate()
		var jump_at := 16.0
		if autopilot_sloppy and d_edge != INF and int(edge / 400.0) % 3 == 0:
			jump_at = 120.0 + float(int(edge) % 90)
		if vault_near or (not w.is_empty() and str(w["kind"]) != "vault") or (d_edge != INF and d_edge <= jump_at):
			if not _ap.get("up", false):
				ls = Vector2(1, -1).normalized()
				_ap["up"] = true
			else:
				_ap["up"] = false
		else:
			_ap["up"] = false
	_ap["ls"] = ls
	_ap["rs"] = rs
	_ap["btn"] = btn


static func dir_vec(code: String) -> Vector2:
	var v := Vector2.ZERO
	if code.contains("F"):
		v.x += 1.0
	if code.contains("B"):
		v.x -= 1.0
	if code.contains("U"):
		v.y -= 1.0
	if code.contains("D"):
		v.y += 1.0
	return v.normalized()
