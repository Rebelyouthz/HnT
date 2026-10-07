class_name TrickCall
extends Node2D

## ROOF TRICKS. Running at a roof edge calls a trick over the hero's head:
## a right-stick direction plus shoulder buttons (R1 / R2 / L1 / L2; on
## keyboard the numpad or arrows plus O / SHIFT / I / U).
##   HOLD     the combo while you run at the edge (the badge turns green)
##   RELEASE  it right as you leave the roof: the gap between takeoff and
##            release grades the trick - PERFECT, GOOD, OK or MISSED
##   LAND     the landing the badge asks for (e.g. ROLL: both sticks down
##            and forward) has to be held as the feet touch down, or the
##            hero stumbles.
## Tricks pay FLOW, story XP and a burst of speed; the ROOFTOPS hero level
## unlocks harder ones and widens the timing window a little.

const CALL_DIST := 230.0
const PERFECT := 0.07
const GOOD := 0.14
const OK := 0.24
## A release this long after takeoff is too late to count.
const LATE := 0.32

## dir: right stick relative to facing (F forward, B back, U up, D down).
const TRICKS := [
	{"id": "kong", "name": "KONG SPIN", "dir": "F", "btn": ["R1"], "land": "roll", "lv": 1, "spin": "spin", "pts": 10},
	{"id": "backflip", "name": "BACKFLIP", "dir": "U", "btn": ["L1"], "land": "knee", "lv": 1, "spin": "back", "pts": 10},
	{"id": "dive", "name": "FRONT DIVE", "dir": "D", "btn": ["R2"], "land": "roll", "lv": 2, "spin": "front", "pts": 12},
	{"id": "cat", "name": "CAT TWIST", "dir": "B", "btn": ["L2"], "land": "stick", "lv": 3, "spin": "twist", "pts": 12},
	{"id": "cork", "name": "CORKSCREW", "dir": "UF", "btn": ["R1", "R2"], "land": "roll", "lv": 4, "spin": "cork", "pts": 16},
	{"id": "tornado", "name": "TORNADO", "dir": "UB", "btn": ["L1", "R1"], "land": "knee", "lv": 6, "spin": "double", "pts": 20},
	{"id": "superman", "name": "SUPERMAN", "dir": "F", "btn": ["L2", "R2"], "land": "slide", "lv": 8, "spin": "super", "pts": 22},
	{"id": "dbl_cork", "name": "DOUBLE CORK", "dir": "DF", "btn": ["L1", "R1", "R2"], "land": "roll", "lv": 11, "spin": "dcork", "pts": 30},
]
## l / r: left and right stick at touchdown ("" = let go).
const LANDS := {
	"roll": {"name": "ROLL", "l": "DF", "r": "DF"},
	"knee": {"name": "KNEE DROP", "l": "D", "r": "D"},
	"stick": {"name": "STICK IT", "l": "", "r": ""},
	"slide": {"name": "SLIDE OUT", "l": "DF", "r": "F"},
}
const DIR_NAME := {"F": "FWD", "B": "BACK", "U": "UP", "D": "DOWN", "UF": "UP-FWD", "DF": "DOWN-FWD", "UB": "UP-BACK", "DB": "DOWN-BACK"}
const ACT := {"R1": "shoot", "L1": "block", "R2": "dash", "L2": "throw"}
const KEY := {"R1": "O", "L1": "I", "R2": "SHIFT", "L2": "U"}

## A trick was graded (perfect / good / ok / miss) - gates wait on this.
signal graded(f: Fighter, grade: String)

## Per hero: state and the trick in play.
var _st: Dictionary = {}
var _told := false


static func find(tree: SceneTree) -> TrickCall:
	return tree.get_first_node_in_group("trick_call") as TrickCall


## The stick + shoulder combo for one of the gate tricks (data/parkour.json):
## fixed per trick id, more buttons the higher its tier.
static func combo_for(id: String, tier: int) -> Dictionary:
	var dirs := ["F", "U", "D", "UF", "DF", "B", "UB"]
	var btns := ["R1", "L1", "R2", "L2"]
	var h := absi(hash(id))
	var n := 1 if tier <= 1 else (2 if tier <= 3 else 3)
	var b: Array = []
	for i in n:
		var pick: String = btns[(h / (i + 1) + i * 3) % btns.size()]
		if not b.has(pick):
			b.append(pick)
	var lands := ["roll", "knee", "slide", "roll"]
	return {"dir": dirs[h % dirs.size()], "btn": b, "land": "stick" if tier == 0 else lands[h % lands.size()]}


## A gate ahead calls its trick on this hero (the gate decides takeoff).
func call_gate(f: Fighter, gate: Node2D, row: Dictionary) -> void:
	var r := _row(f)
	if str(r["s"]) == "air" or (r.get("gate") == gate and str(r["s"]) != "idle"):
		return
	var c := combo_for(str(row.get("id", "jump")), int(row.get("tier", 0)))
	r["trick"] = {"id": str(row.get("id", "jump")), "name": str(row.get("title", "JUMP")), "dir": c["dir"], "btn": c["btn"], "land": c["land"], "pts": int(row.get("points", 8)), "spin": ""}
	r["gate"] = gate
	r["rel"] = -9.0
	_to(f, r, "call")


## The hero reached the gate: takeoff. Returns the grade when it is known
## now (never held: "skip"; let go a moment early: graded), else "" and the
## grade arrives on `graded` when the combo is let go.
func gate_takeoff(f: Fighter, gate: Node2D, row: Dictionary) -> String:
	var r := _row(f)
	if r.get("gate") != gate:
		call_gate(f, gate, row)
	if str(r["s"]) == "air":
		return "miss"
	var s := str(r["s"])
	var early := float(r["rel"]) > 0.0 and _now() - float(r["rel"]) < OK
	if s != "armed" and not early:
		r["gate"] = null
		_to(f, r, "idle")
		# Never tried: no trick, no penalty - just running past.
		return "skip"
	r["t0"] = _now()
	r["air"] = 0.0
	r["graded"] = false
	f.trick_hold = false
	_to(f, r, "air")
	if early:
		_grade(f, r, float(r["rel"]) - _now())
		return str(r.get("grade", "miss"))
	return ""


static func place(host: Node) -> TrickCall:
	var t := TrickCall.new()
	t.z_index = 30
	host.add_child(t)
	return t


func _physics_process(delta: float) -> void:
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			_tick(n as Fighter, delta)
	queue_redraw()
	if _hud:
		_hud.queue_redraw()


func _row(f: Fighter) -> Dictionary:
	var k := f.get_instance_id()
	if not _st.has(k):
		_st[k] = {"s": "idle", "trick": {}, "t0": 0.0, "rel": -9.0, "air": 0.0, "f": f}
	return _st[k]


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _tick(f: Fighter, delta: float) -> void:
	var r := _row(f)
	var s := str(r["s"])
	var gate: Variant = r.get("gate")
	if gate != null and not is_instance_valid(gate):
		r["gate"] = null
		gate = null
	if gate != null and s != "air":
		# A gate's call: hold until the gate says takeoff; drop it if passed.
		var gx := (gate as Node2D).global_position.x - f.global_position.x
		if absf(gx) > 320.0 or signf(gx) != float(f.facing) and absf(gx) > 50.0:
			r["gate"] = null
			_to(f, r, "idle")
			return
		_hold_step(f, r, s)
		return
	match s:
		"idle", "call", "armed":
			if f.plane != "roof" or not f.is_on_floor():
				if s == "armed" and f.plane == "roof":
					_takeoff(f, r)
				elif s == "call" and f.plane == "roof" and float(r["rel"]) > 0.0 and _now() - float(r["rel"]) < OK:
					_takeoff(f, r)
				else:
					_to(f, r, "idle")
				return
			var edge := _edge_ahead(f)
			if edge < 0.0:
				_to(f, r, "idle")
				return
			if s == "idle":
				r["trick"] = _pick(f, edge)
				r["rel"] = -9.0
				_to(f, r, "call")
				if not _told and not bool(FamilyProfile.data.get("trick_told", false)):
					_told = true
					FamilyProfile.data["trick_told"] = true
					Juice.toast("achievement", "ROOF TRICKS", "Hold the stick + shoulder combo over your head, let go right as you leave the roof, then hold the landing.", "cur_xp")
			_hold_step(f, r, str(r["s"]))
		"air":
			r["air"] = float(r["air"]) + delta
			f.parkour_lock = maxf(f.parkour_lock, 0.1)
			if not bool(r.get("graded", false)):
				var gone := not _held(f, r["trick"])
				if gone:
					_grade(f, r, _now() - float(r["t0"]))
				elif _now() - float(r["t0"]) > LATE:
					_grade(f, r, 99.0)
				return
			var down := (f.plane == "roof" and f.is_on_floor()) or (f.plane == "street" and f.hop >= -1.0)
			if (down and float(r["air"]) > 0.15) or float(r["air"]) > 3.0:
				_land(f, r)


func _hold_step(f: Fighter, r: Dictionary, s: String) -> void:
	var held := _held(f, r["trick"])
	if held:
		f.parkour_lock = maxf(f.parkour_lock, 0.12)
		f.trick_hold = true
		if s == "call":
			Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.6, -12.0)
		r["rel"] = -9.0
		_to(f, r, "armed")
	elif s == "armed":
		# Let go before the takeoff: counts only if the feet leave right now.
		r["rel"] = _now()
		f.trick_hold = false
		_to(f, r, "call")
	else:
		f.trick_hold = false
		# Lining up the stick: keep punches and dashes out of it.
		if _rstick(f).length() > 0.5:
			f.parkour_lock = maxf(f.parkour_lock, 0.1)
		if float(r["rel"]) > 0.0 and _now() - float(r["rel"]) > OK:
			r["rel"] = -9.0


func _to(f: Fighter, r: Dictionary, s: String) -> void:
	r["s"] = s
	if s == "idle":
		f.trick_hold = false


## Feet left the roof while the combo was held (or just let go).
func _takeoff(f: Fighter, r: Dictionary) -> void:
	r["t0"] = _now()
	r["air"] = 0.0
	r["graded"] = false
	# Walked off the edge: the hero kicks off it anyway.
	if f.velocity.y > -100.0:
		f.velocity.y = Fighter.JUMP * 0.95 * Meta.jump_mul()
		KitSfx.hit(f.role, "jump")
	f.trick_hold = false
	_to(f, r, "air")
	if float(r["rel"]) > 0.0:
		# Released a moment before the feet left: early.
		_grade(f, r, float(r["rel"]) - _now())


func _grade(f: Fighter, r: Dictionary, dt: float) -> void:
	r["graded"] = true
	var w := Heroes.trick_window_mul(f.role)
	var a := absf(dt)
	var g := "miss"
	if a <= PERFECT * w:
		g = "perfect"
	elif a <= GOOD * w:
		g = "good"
	elif a <= OK * w:
		g = "ok"
	r["grade"] = g
	var tr: Dictionary = r["trick"]
	graded.emit(f, g)
	if r.get("gate") != null:
		# The gate plays the move and pays for it; only the landing is ours.
		r["pts"] = 0
		if g == "miss":
			r["trick"] = {}
		return
	if g == "miss":
		Juice.popup_number(f.global_position + Vector2(0, -120), "TOO LATE" if dt > 0.0 else "TOO EARLY", Color(1.0, 0.35, 0.3))
		Mixer.play_sfx("res://assets/audio/ui_click.wav", 0.6, -8.0)
		r["trick"] = {}
		return
	var mul: float = {"perfect": 2.0, "good": 1.4, "ok": 1.0}[g]
	var pts := int(round(float(tr["pts"]) * mul))
	r["pts"] = pts
	var col: Color = {"perfect": UiKit.GOLD, "good": Color(0.45, 1.0, 0.55), "ok": Color(1.0, 0.9, 0.4)}[g]
	Juice.popup_number(f.global_position + Vector2(0, -132), "%s  %s" % [str(tr["name"]), g.to_upper()], col)
	if g == "perfect":
		Juice.named_slowmo()
		Juice.hitstop(3)
		Mixer.play_sfx("res://assets/audio/trick_perfect.wav", 1.0, -4.0)
	else:
		Mixer.play_sfx("res://assets/audio/whoosh_light.wav", 1.1, -6.0)
	_spin(f, str(tr["spin"]), g == "perfect")
	FamilyProfile.mark_trick()


const ANIM := {"spin": "aerial", "back": "back_flip", "front": "front_flip", "twist": "side_flip", "cork": "cork", "double": "gainer", "super": "dive_roll", "dcork": "cork"}


## The body turns in the air (TrickMove); afterimages trail it.
func _spin(f: Fighter, kind: String, perfect := false) -> void:
	TrickMove.play(f, str(ANIM.get(kind, "aerial")), perfect)
	if kind == "double" or kind == "dcork":
		get_tree().create_timer(0.32).timeout.connect(func() -> void:
			if is_instance_valid(f):
				TrickMove.play(f, str(ANIM.get(kind, "aerial")), perfect))
	for i in 7:
		get_tree().create_timer(0.05 * float(i + 1)).timeout.connect(func() -> void: _ghost(f))


func _ghost(f: Fighter) -> void:
	if not is_instance_valid(f) or f.visual == null:
		return
	var a := f.get("_anim") as AnimatedSprite2D
	if a == null or a.sprite_frames == null:
		return
	var s := Sprite2D.new()
	s.texture = a.sprite_frames.get_frame_texture(a.animation, a.frame)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.global_transform = a.global_transform
	s.offset = a.offset
	s.centered = a.centered
	s.flip_h = a.flip_h
	s.modulate = Color(0.45, 0.9, 1.0, 0.5)
	s.top_level = true
	s.z_index = 2
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.28)
	tw.tween_callback(s.queue_free)


func _land(f: Fighter, r: Dictionary) -> void:
	var tr: Dictionary = r["trick"]
	_to(f, r, "idle")
	if tr.is_empty():
		r["gate"] = null
		return
	var art := f.get("_anim") as Node2D
	var spinning := art != null and absf(wrapf(art.rotation, -PI, PI)) > 1.2
	var ld: Dictionary = LANDS[str(tr["land"])]
	var ok := TimingRing.autoplay or not spinning and _dir_ok(_rel(f, f._stick()), str(ld["l"])) and _dir_ok(_rel(f, _rstick(f)), str(ld["r"]))
	r["gate"] = null
	var pts := int(r.get("pts", 0))
	if not ok:
		f.stumble()
		Juice.popup_number(f.global_position + Vector2(0, -100), "BAD LANDING", Color(1.0, 0.4, 0.3))
		pts = pts / 2
	else:
		pts += 6
		f.trick_boost = 1.18 if str(r.get("grade", "")) == "perfect" else 1.12
		f.trick_t = 1.6
		Juice.land_puff(f.global_position)
		Juice.popup_number(f.global_position + Vector2(0, -100), "%s  CLEAN  +%d FLOW" % [str(ld["name"]), pts], Color(0.55, 0.95, 1.0))
		Mixer.play_sfx("res://assets/audio/cling.wav", 1.2, -8.0)
		if str(tr["land"]) == "roll" or str(tr["land"]) == "slide":
			f.slide_frames = 10
			f.sliding = true
	Trees.add_flow(pts)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_xp") and SurviveRun.get_run(get_tree()) == null:
		rs.add_xp(maxi(1, pts / 2))
	FamilyProfile.data["tricks_landed"] = int(FamilyProfile.data.get("tricks_landed", 0)) + (1 if ok else 0)


## ---- input -----------------------------------------------------------------

## Right stick, or numpad / arrow keys on keyboard (arrows only when the
## second player is not on the arrows).
func _rstick(f: Fighter) -> Vector2:
	var v := PadRouter.rstick(f.prefix)
	if v != Vector2.ZERO or str(f.prefix) != "p1_":
		return v
	var k := Vector2.ZERO
	var solo := get_tree().get_nodes_in_group("players").size() <= 1
	if Input.is_physical_key_pressed(KEY_KP_4) or Input.is_physical_key_pressed(KEY_KP_7) or Input.is_physical_key_pressed(KEY_KP_1) or (solo and Input.is_physical_key_pressed(KEY_LEFT)):
		k.x -= 1.0
	if Input.is_physical_key_pressed(KEY_KP_6) or Input.is_physical_key_pressed(KEY_KP_9) or Input.is_physical_key_pressed(KEY_KP_3) or (solo and Input.is_physical_key_pressed(KEY_RIGHT)):
		k.x += 1.0
	if Input.is_physical_key_pressed(KEY_KP_8) or Input.is_physical_key_pressed(KEY_KP_7) or Input.is_physical_key_pressed(KEY_KP_9) or (solo and Input.is_physical_key_pressed(KEY_UP)):
		k.y -= 1.0
	if Input.is_physical_key_pressed(KEY_KP_2) or Input.is_physical_key_pressed(KEY_KP_1) or Input.is_physical_key_pressed(KEY_KP_3) or (solo and Input.is_physical_key_pressed(KEY_DOWN)):
		k.y += 1.0
	return k.normalized()


## Stick vector turned so +x is the way the hero faces.
func _rel(f: Fighter, v: Vector2) -> Vector2:
	return Vector2(v.x * float(f.facing), v.y)


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


func _dir_ok(v: Vector2, code: String) -> bool:
	if code == "":
		return v.length() < 0.35
	if v.length() < 0.55:
		return false
	return absf(angle_difference(v.angle(), dir_vec(code).angle())) < 0.55


func _held(f: Fighter, tr: Dictionary) -> bool:
	if tr.is_empty():
		return false
	if TimingRing.autoplay:
		# Demo: hold up to the edge, let go on the takeoff frame.
		return str(_row(f)["s"]) != "air"
	if not _dir_ok(_rel(f, _rstick(f)), str(tr["dir"])):
		return false
	for b in tr["btn"]:
		if not f._pressed(str(ACT[str(b)])):
			return false
	return true


## ---- edges -------------------------------------------------------------------

## Distance to the roof edge the hero is running at, or -1.
func _edge_ahead(f: Fighter) -> float:
	if absf(f.velocity.x) < 60.0 or signf(f.velocity.x) != float(f.facing):
		return -1.0
	var p := f.global_position
	for n in get_tree().get_nodes_in_group("roof_solids"):
		if not n.has_meta("rect"):
			continue
		var rc: Rect2 = n.get_meta("rect")
		if p.x < rc.position.x - 2.0 or p.x > rc.end.x + 2.0 or absf(p.y - rc.position.y) > 8.0:
			continue
		var d := (rc.end.x - p.x) if f.facing > 0 else (p.x - rc.position.x)
		if d >= 0.0 and d <= CALL_DIST:
			return d
	return -1.0


## The same edge always calls the same trick (from those the ROOFTOPS level
## has unlocked); deeper levels open the harder ones.
func _pick(f: Fighter, _edge: float) -> Dictionary:
	var lv := Heroes.level(f.role, "parkour")
	var pool: Array = []
	for t: Dictionary in TRICKS:
		if int(t["lv"]) <= lv:
			pool.append(t)
	var ex := int(round(f.global_position.x / 64.0)) * 7 + int(f.global_position.y)
	return pool[absi(ex) % pool.size()]


## ---- the badge over the hero ------------------------------------------------

var _hud: Control


func _ready() -> void:
	add_to_group("trick_call")
	var cl := CanvasLayer.new()
	cl.layer = 6
	add_child(cl)
	# Same 1280x720 design space as the run HUD.
	var root := PixelStage.attach_canvas(cl)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud = Control.new()
	_hud.size = root.size
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hud)
	_hud.draw.connect(_draw_hud)


## Over the hero: a small arrow so you know the call is yours.
func _draw() -> void:
	for k in _st.keys():
		var r: Dictionary = _st[k]
		var f: Fighter = r["f"]
		if not is_instance_valid(f) or (r["trick"] as Dictionary).is_empty() or str(r["s"]) == "idle":
			continue
		var at := to_local(f.global_position + Vector2(0, -122))
		var col := Color(0.45, 1.0, 0.55) if str(r["s"]) == "armed" else Color(1.0, 0.85, 0.3)
		var bob := sin(Time.get_ticks_msec() / 120.0) * 2.0
		draw_colored_polygon(PackedVector2Array([at + Vector2(-7, -8 + bob), at + Vector2(7, -8 + bob), at + Vector2(0, 2 + bob)]), col)


## The combo, big and low on the screen (P1 left of centre, P2 right).
func _draw_hud() -> void:
	if _hud == null:
		return
	var font: Font = UiKit.title_font()
	var vs := _hud.size
	for k in _st.keys():
		var r: Dictionary = _st[k]
		var f: Fighter = r["f"]
		if not is_instance_valid(f):
			continue
		var s := str(r["s"])
		var tr: Dictionary = r["trick"]
		if tr.is_empty() or s == "idle":
			continue
		var kb := PadRouter.device_of(f.prefix) < 0
		var two := get_tree().get_nodes_in_group("players").size() > 1
		var cx := vs.x * (0.5 if not two else (0.32 if str(f.prefix) == "p1_" else 0.68))
		var at := Vector2(cx, vs.y - 122.0)
		if s == "air":
			if not bool(r.get("graded", false)):
				_chip(at, "LET GO!", Color(1.0, 0.85, 0.3), font, 26)
				continue
			var ld: Dictionary = LANDS[str(tr["land"])]
			_chip(at, "LAND: %s" % str(ld["name"]), Color(0.55, 0.95, 1.0), font, 22)
			_stick_glyph(at + Vector2(-30, 34), dir_vec(str(ld["l"])) * Vector2(float(f.facing), 1.0), Color(0.55, 0.95, 1.0), "L-STICK" if not kb else "MOVE")
			_stick_glyph(at + Vector2(30, 34), dir_vec(str(ld["r"])) * Vector2(float(f.facing), 1.0), Color(0.55, 0.95, 1.0), "R-STICK" if not kb else "NUM")
			continue
		var armed := s == "armed"
		var col := Color(0.45, 1.0, 0.55) if armed else Color(1.0, 0.85, 0.3)
		_chip(at, str(tr["name"]) + ("   LET GO ON TAKEOFF" if armed else "   HOLD"), col, font, 22)
		var parts: Array = tr["btn"]
		var widths: Array = []
		var w := 40.0
		for b in parts:
			var lab := str(KEY[str(b)]) if kb else str(b)
			var bw := maxf(40.0, font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 14.0)
			widths.append(bw)
			w += bw + 22.0
		var x := at.x - w * 0.5
		_stick_glyph(Vector2(x + 16.0, at.y + 34.0), dir_vec(str(tr["dir"])) * Vector2(float(f.facing), 1.0), col, "NUM" if kb else "R-STICK")
		x += 40.0
		for i in parts.size():
			var b := str(parts[i])
			var lab := str(KEY[b]) if kb else b
			var bw: float = widths[i]
			_hud.draw_string(font, Vector2(x, at.y + 40.0), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
			x += 16.0
			var on := f._pressed(str(ACT[b]))
			var rc := Rect2(x, at.y + 22.0, bw, 26.0)
			_hud.draw_rect(rc, Color(0.05, 0.06, 0.1, 0.92))
			_hud.draw_rect(rc, col if on else Color(0.65, 0.65, 0.75), false, 2.0)
			_hud.draw_string(font, Vector2(x + 7.0, at.y + 41.0), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col if on else Color.WHITE)
			x += bw + 6.0


func _chip(at: Vector2, text: String, col: Color, font: Font, size: int) -> void:
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var rc := Rect2(at.x - sz.x * 0.5 - 8.0, at.y - sz.y, sz.x + 16.0, sz.y + 6.0)
	_hud.draw_rect(rc, Color(0.03, 0.04, 0.08, 0.85))
	_hud.draw_rect(rc, col, false, 2.0)
	_hud.draw_string_outline(font, Vector2(rc.position.x + 8.0, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0))
	_hud.draw_string(font, Vector2(rc.position.x + 8.0, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _stick_glyph(c: Vector2, d: Vector2, col: Color, tag: String) -> void:
	_hud.draw_circle(c, 16.0, Color(0.05, 0.06, 0.1, 0.9))
	_hud.draw_arc(c, 16.0, 0.0, TAU, 28, col, 2.5)
	if d == Vector2.ZERO:
		_hud.draw_circle(c, 4.0, col)
	else:
		_hud.draw_line(c, c + d * 11.0, col, 3.0)
		_hud.draw_circle(c + d * 11.0, 5.0, col)
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	_hud.draw_string(f, c + Vector2(-w * 0.5, 30), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.9))
