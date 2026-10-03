class_name BloodSim
extends Node2D

## Blood that behaves like a liquid. Every hit throws real drops from where
## it landed (face, mouth, gut, legs, a bullet's exit) along the blow: they
## fly under gravity, stretch with speed, and splat on the street at the
## victim's depth - round when they fall slow, long streaks with a crown of
## specks when they come in fast. Splats stay. Bodies that stop moving leak
## a pool that spreads and shines. Big hits can spray the camera glass.
## Wounds on the bodies themselves are the wound shader (wound()).

const G := 980.0
const MAX_DROPS := 360
const MAX_STAINS := 520
const MAX_POOLS := 22
const FRESH := Color(0.66, 0.04, 0.06)
const DARK := Color(0.36, 0.01, 0.03)
const SNAP := 0.5

var _drops: Array[Dictionary] = []
var _stains: Array[Dictionary] = []
var _pools: Array[Dictionary] = []
var _stain_layer: Node2D
var _pool_layer: Node2D
var _screen: Control
var _screen_blobs: Array[Dictionary] = []
## Solid gore: meat chunks, teeth, bone splinters. They fly, tumble, land,
## smear a stain and lie on the street with the bodies.
var _gibs: Array[Dictionary] = []
const MAX_GIBS := 90


func _ready() -> void:
	add_to_group("blood_sim")
	z_index = 9
	_stain_layer = Node2D.new()
	_stain_layer.z_index = 2
	_stain_layer.z_as_relative = false
	_stain_layer.draw.connect(_draw_stains)
	_pool_layer = Node2D.new()
	_pool_layer.z_index = 2
	_pool_layer.z_as_relative = false
	_pool_layer.draw.connect(_draw_pools)
	# Siblings so the floor layers draw under the actors, not over them.
	get_parent().call_deferred("add_child", _pool_layer)
	get_parent().call_deferred("add_child", _stain_layer)
	var layer := CanvasLayer.new()
	layer.layer = 14
	add_child(layer)
	_screen = Control.new()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.draw.connect(_draw_screen)
	layer.add_child(_screen)


# --- Public API ------------------------------------------------------------

## Old call sites: a hit of `kind` at an actor standing at `at` (feet).
func spray(at: Vector2, kind: String, dir: float) -> void:
	if FamilyProfile.less_gore():
		return
	var p := profile(kind)
	burst(at + Vector2(dir * 4.0, float(p["h"])), at.y, dir, p)


## A hit that knows where it landed. zone: head | mouth | gut | low | up |
## bullet | blade | crush. power 0..1. wound 0..1 (how hurt they already
## are: a bloodied face bleeds more).
func hit(victim: Node2D, zone: String, dir: float, power: float, wound_lv: float = 0.0) -> void:
	if FamilyProfile.less_gore() or victim == null:
		return
	var feet := victim.global_position
	var p := zone_profile(zone, power, wound_lv)
	if int(p["n"]) <= 0:
		return
	burst(feet + Vector2(dir * float(p.get("dx", 4.0)), float(p["h"])), feet.y, dir, p)
	if zone == "bullet":
		# Exit wound: a fast fan behind the target.
		var exit := {"n": 10 + int(6.0 * power), "speed": 360.0, "spread": 0.22, "rise": 0.05, "size": 0.8, "h": p["h"], "mist": true}
		burst(feet + Vector2(dir * 10.0, float(p["h"])), feet.y, dir, exit)


func pump(at: Vector2, dir: float) -> void:
	if FamilyProfile.less_gore():
		return
	for i in 4:
		var t := 0.001 + float(i) * 0.09
		get_tree().create_timer(t, true, false, true).timeout.connect(func() -> void:
			if is_inside_tree():
				burst(at + Vector2(dir * (4.0 + float(i) * 2.0), -30.0 + float(i) * 3.0), at.y, dir,
					{"n": 7, "speed": 230.0 - float(i) * 30.0, "spread": 0.35, "rise": 0.5, "size": 1.3, "h": -30})
		)


func pulse(at: Vector2) -> void:
	if FamilyProfile.less_gore():
		return
	for d in [-1.0, 1.0]:
		burst(at + Vector2(0, -34), at.y, d, {"n": 6, "speed": 150.0, "spread": 0.6, "rise": 0.6, "size": 1.1, "h": -34})


## A body down at `at`: drips, then a pool that keeps spreading.
func run_pool(at: Vector2, dir: float) -> void:
	if FamilyProfile.less_gore():
		return
	pool(at + Vector2(dir * 8.0, 2.0), 14.0)
	burst(at + Vector2(0, -6), at.y, dir, {"n": 5, "speed": 60.0, "spread": 0.9, "rise": 0.3, "size": 1.2, "h": -6})


func pool(at: Vector2, size: float) -> void:
	if FamilyProfile.less_gore():
		return
	if _pools.size() >= MAX_POOLS:
		_pools.pop_front()
	_pools.append({"p": at, "r": 1.5, "target": size * randf_range(0.85, 1.2), "seed": randf() * 100.0,
		"rate": randf_range(2.2, 3.4), "tint": _biome()})


## Splash the camera: blobs on the glass on `side` (-1 left, 1 right) that
## run down and fade. amount 0..1.
func screen(side: float, amount: float) -> void:
	if FamilyProfile.less_gore() or _screen == null:
		return
	var vs := _screen.get_viewport_rect().size
	var n := 2 + int(amount * 4.0)
	for i in n:
		var x := vs.x * (0.5 + side * randf_range(0.18, 0.46))
		var y := vs.y * randf_range(0.12, 0.72)
		var r := vs.y * randf_range(0.012, 0.03) * (0.6 + amount)
		var drops := []
		for k in randi_range(2, 6):
			var a := randf() * TAU
			drops.append([Vector2(cos(a), sin(a) * 0.8) * r * randf_range(0.9, 1.9), r * randf_range(0.12, 0.35)])
		_screen_blobs.append({"p": Vector2(x, y), "r": r, "life": 2.6 + randf() * 0.8, "age": 0.0,
			"run": randf_range(0.0, r * 3.0), "drops": drops, "tint": _biome()})
	_screen.queue_redraw()


## Wounds on a sprite: blood in the face and on the clothes that builds up
## with damage (0..1).
static func wound(anim: CanvasItem, level: float, splat: float, side: float) -> void:
	if anim == null or FamilyProfile.less_gore():
		return
	var mat := _wound_mat(anim)
	mat.set_shader_parameter("wound", clampf(level, 0.0, 1.0))
	mat.set_shader_parameter("splat", clampf(splat, 0.0, 1.0))
	mat.set_shader_parameter("side", side)


static func _wound_mat(anim: CanvasItem) -> ShaderMaterial:
	var mat := anim.material as ShaderMaterial
	if mat == null or mat.shader != preload("res://src/shaders/wound.gdshader"):
		mat = ShaderMaterial.new()
		mat.shader = preload("res://src/shaders/wound.gdshader")
		mat.set_shader_parameter("seed", randf() * 50.0)
		mat.set_shader_parameter("head", head_of(anim))
		mat.set_shader_parameter("holes", PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
		anim.material = mat
		# The face moves between frames: keep the wound on it.
		if anim is AnimatedSprite2D:
			var a := anim as AnimatedSprite2D
			var follow := func() -> void:
				if is_instance_valid(a) and a.material is ShaderMaterial:
					(a.material as ShaderMaterial).set_shader_parameter("head", head_of(a))
			a.frame_changed.connect(follow)
			a.animation_changed.connect(follow)
	return mat


## A bullet hole at a local sprite texel (it bleeds down the clothes).
static func add_hole(anim: CanvasItem, local: Vector2) -> void:
	if anim == null or FamilyProfile.less_gore():
		return
	var mat := _wound_mat(anim)
	var nv: Variant = mat.get_shader_parameter("hole_n")
	var n: int = int(nv) if nv != null else 0
	var hv: Variant = mat.get_shader_parameter("holes")
	var holes := PackedVector2Array(hv) if hv is PackedVector2Array or hv is Array else PackedVector2Array()
	while holes.size() < 6:
		holes.append(Vector2.ZERO)
	holes[n % 6] = local
	mat.set_shader_parameter("holes", holes)
	mat.set_shader_parameter("hole_n", mini(n + 1, 6))


static var _heads := {}


## Head position (centre x, centre y, radius) in the sprite's local texels
## for the frame on screen; measured once per frame from its silhouette.
static func head_of(anim: CanvasItem) -> Vector3:
	var a := anim as AnimatedSprite2D
	if a == null or a.sprite_frames == null or not a.sprite_frames.has_animation(a.animation):
		return Vector3(0, -60, 14)
	return head_of_tex(a.sprite_frames.get_frame_texture(a.animation, a.frame))


static func head_of_tex(tex: Texture2D) -> Vector3:
	if tex == null:
		return Vector3(0, -60, 14)
	var key := tex.get_instance_id()
	if _heads.has(key):
		return _heads[key]
	var out := Vector3(0, -60, 14)
	var img := tex.get_image()
	if img != null:
		var w := img.get_width()
		var h := img.get_height()
		var top := -1
		var bottom := -1
		for y in range(0, h, 2):
			for x in range(0, w, 2):
				if img.get_pixel(x, y).a > 0.5:
					if top < 0:
						top = y
					bottom = y
					break
		if top >= 0:
			var body := float(bottom - top)
			var cx := 0.0
			var cnt := 0.0
			var hy := top + int(body * 0.1)
			for x in w:
				if img.get_pixel(x, hy).a > 0.5:
					cx += float(x)
					cnt += 1.0
			cx = cx / cnt if cnt > 0.0 else float(w) * 0.5
			# get_image() of an AtlasTexture is only its region: shift by the
			# margin and centre on the full (padded) frame the sprite draws.
			var off := Vector2.ZERO
			var full := Vector2(w, h)
			if tex is AtlasTexture:
				off = (tex as AtlasTexture).margin.position
				full = tex.get_size()
			out = Vector3(cx + off.x - full.x * 0.5, float(top) + off.y + body * 0.1 - full.y * 0.5, maxf(10.0, body * 0.08))
	_heads[key] = out
	return out


## Spray parameters per hit kind (the old string API).
static func profile(kind: String) -> Dictionary:
	match kind:
		"light", "jab", "cross":
			return {"n": 4, "speed": 150.0, "spread": 0.4, "rise": 0.35, "size": 0.8, "h": -52}
		"snap", "finish", "web-slam":
			return {"n": 26, "speed": 300.0, "spread": 0.45, "rise": 0.45, "size": 1.4, "h": -44}
		"heavy", "dive", "launcher", "special":
			return {"n": 14, "speed": 250.0, "spread": 0.4, "rise": 0.4, "size": 1.2, "h": -48}
		"blade":
			return {"n": 16, "speed": 280.0, "spread": 0.25, "rise": 0.25, "size": 1.0, "h": -40, "streak": true}
		"uppercut", "air-upper":
			return {"n": 14, "speed": 260.0, "spread": 0.3, "rise": 1.4, "size": 1.1, "h": -54}
		"roundhouse", "air-mix", "clash", "revenge":
			return {"n": 16, "speed": 270.0, "spread": 0.5, "rise": 0.45, "size": 1.2, "h": -52}
		"bam", "gut-punch":
			return {"n": 12, "speed": 200.0, "spread": 0.35, "rise": 0.2, "size": 1.1, "h": -46}
		"slide":
			return {"n": 7, "speed": 160.0, "spread": 0.5, "rise": 0.25, "size": 0.9, "h": -10}
		"stomp1":
			return {"n": 10, "speed": 170.0, "spread": 1.2, "rise": 0.8, "size": 1.1, "h": -6}
		"stomp2":
			return {"n": 16, "speed": 220.0, "spread": 1.3, "rise": 0.8, "size": 1.3, "h": -6}
		"stomp3":
			return {"n": 28, "speed": 300.0, "spread": 1.5, "rise": 0.9, "size": 1.5, "h": -6}
		"throw", "barrel", "manhole", "geyser", "smash":
			return {"n": 14, "speed": 240.0, "spread": 0.6, "rise": 0.5, "size": 1.2, "h": -36}
	return {"n": 8, "speed": 200.0, "spread": 0.5, "rise": 0.4, "size": 1.0, "h": -44}


static func zone_profile(zone: String, power: float, wound_lv: float) -> Dictionary:
	var more := 1.0 + wound_lv * 1.2
	var w := clampf(power, 0.0, 1.0)
	match zone:
		"head":
			return {"n": int((3.0 + 12.0 * w) * more), "speed": 150.0 + 170.0 * w, "spread": 0.35, "rise": 0.35, "size": 0.8 + 0.6 * w, "h": -54}
		"mouth", "gut":
			# Coughed out forward and down.
			return {"n": int((2.0 + 8.0 * w) * more), "speed": 110.0 + 90.0 * w, "spread": 0.4, "rise": -0.05, "size": 0.9 + 0.4 * w, "h": -50, "dx": 6.0}
		"low":
			return {"n": int((3.0 + 6.0 * w) * more), "speed": 140.0 + 80.0 * w, "spread": 0.45, "rise": 0.2, "size": 0.9, "h": -10}
		"up":
			return {"n": int((5.0 + 12.0 * w) * more), "speed": 200.0 + 140.0 * w, "spread": 0.3, "rise": 1.6, "size": 1.0 + 0.4 * w, "h": -54}
		"bullet":
			return {"n": 4, "speed": 120.0, "spread": 0.5, "rise": 0.2, "size": 0.7, "h": -40, "dx": -2.0}
		"blade":
			return {"n": int(10.0 + 10.0 * w), "speed": 260.0, "spread": 0.22, "rise": 0.3, "size": 1.0, "h": -40, "streak": true}
		"crush":
			return {"n": int(18.0 + 14.0 * w), "speed": 260.0, "spread": 1.4, "rise": 0.8, "size": 1.4, "h": -8}
	return {"n": int(6.0 * more), "speed": 200.0, "spread": 0.5, "rise": 0.4, "size": 1.0, "h": -44}


# --- Simulation ------------------------------------------------------------

func burst(from: Vector2, floor_y: float, dir: float, p: Dictionary) -> void:
	var n := int(p.get("n", 8))
	var speed := float(p.get("speed", 200.0))
	var spread := float(p.get("spread", 0.5))
	var rise := float(p.get("rise", 0.4))
	var size := float(p.get("size", 1.0))
	var mist := bool(p.get("mist", false))
	var tint := _biome()
	for i in n:
		if _drops.size() >= MAX_DROPS:
			_drops.pop_front()
		var ang := randf_range(-spread, spread) - rise * randf_range(0.5, 1.0)
		var v := Vector2(cos(ang) * dir, sin(ang)) * speed * randf_range(0.45, 1.15)
		# Thrown from a wound, not a point.
		var o := Vector2(randf_range(-2.0, 2.0), randf_range(-3.0, 3.0))
		var s := size * randf_range(0.5, 1.4) * (0.6 if mist else 1.0)
		_drops.append({
			"p": from + o, "v": v, "s": s,
			# Depth: drops land a little in front of / behind the body.
			"floor": clampf(floor_y + randf_range(-5.0, 8.0), 428.0, 640.0),
			"c": tint.lerp(DARK, randf() * 0.45),
			"streak": bool(p.get("streak", false))
		})


## Brutal kills. kind: "kill" (a few chunks and teeth), "overkill" (the body
## comes apart: chunks, teeth, bone, a fountain from the neck and the
## camera glass painted), "teeth" (a jaw shot: teeth and a spit of blood),
## "crack" (bone splinters on a breaking blow).
func gore(at: Vector2, dir: float, kind: String) -> void:
	if FamilyProfile.less_gore():
		return
	var floor_y := at.y
	var head := at + Vector2(0, -58)
	match kind:
		"overkill":
			_throw_gibs(head, floor_y, dir, 12, "chunk", 340.0)
			_throw_gibs(head, floor_y, dir, 7, "tooth", 300.0)
			_throw_gibs(at + Vector2(0, -36), floor_y, dir, 3, "bone", 280.0)
			burst(head, floor_y, dir, {"n": 46, "speed": 420.0, "spread": 1.1, "rise": 0.9, "size": 1.6, "streak": true})
			burst(head, floor_y, -dir, {"n": 18, "speed": 260.0, "spread": 0.9, "rise": 0.8, "size": 1.2})
			for k in 5:
				get_tree().create_timer(0.12 * float(k + 1)).timeout.connect(func() -> void:
					if is_instance_valid(self):
						burst(head + Vector2(0, 6), floor_y, dir * 0.4, {"n": 10, "speed": 300.0, "spread": 0.35, "rise": 1.35, "size": 1.3, "streak": true})
				)
			pool(Vector2(at.x + dir * 10.0, floor_y + 2.0), 26.0)
			screen(dir, 1.0)
		"kill":
			_throw_gibs(head, floor_y, dir, 4, "chunk", 260.0)
			_throw_gibs(head, floor_y, dir, 2, "tooth", 240.0)
		"teeth":
			_throw_gibs(head + Vector2(dir * 6.0, 8), floor_y, dir, randi_range(1, 3), "tooth", 220.0)
			burst(head + Vector2(dir * 6.0, 8), floor_y, dir, {"n": 8, "speed": 220.0, "spread": 0.5, "rise": 0.4, "size": 1.0})
		"crack":
			_throw_gibs(at + Vector2(0, -34), floor_y, dir, randi_range(1, 2), "bone", 200.0)


func _throw_gibs(from: Vector2, floor_y: float, dir: float, n: int, kind: String, speed: float) -> void:
	for i in n:
		if _gibs.size() >= MAX_GIBS:
			_gibs.pop_front()
		var ang := randf_range(-0.9, 0.3) - 0.6
		var v := Vector2(cos(ang) * dir * randf_range(0.3, 1.1), sin(ang)) * speed * randf_range(0.5, 1.1)
		var sz := 1.0
		match kind:
			"chunk":
				sz = randf_range(1.6, 3.4)
			"tooth":
				sz = randf_range(0.8, 1.1)
			"bone":
				sz = randf_range(2.0, 3.2)
		_gibs.append({"p": from + Vector2(randf_range(-4, 4), randf_range(-4, 4)), "v": v, "kind": kind, "s": sz,
			"rot": randf() * TAU, "spin": randf_range(-14.0, 14.0), "floor": clampf(floor_y + randf_range(-6.0, 10.0), 428.0, 640.0),
			"down": false, "seed": randi() % 997})


func _process(delta: float) -> void:
	var landed := false
	for g in _gibs:
		if bool(g["down"]):
			continue
		var gv: Vector2 = g["v"]
		gv.y += G * delta
		g["v"] = gv
		var gp: Vector2 = (g["p"] as Vector2) + gv * delta
		g["rot"] = float(g["rot"]) + float(g["spin"]) * delta
		if gv.y > 0.0 and gp.y >= float(g["floor"]):
			gp.y = float(g["floor"])
			if gv.y > 160.0:
				# Bounce once, a little smear where it hit.
				g["v"] = Vector2(gv.x * 0.45, -gv.y * 0.28)
				g["spin"] = float(g["spin"]) * 0.5
				if str(g["kind"]) == "chunk":
					_splat(gp, gv, float(g["s"]) * 0.9, DARK.lerp(FRESH, 0.4))
			else:
				g["down"] = true
				if str(g["kind"]) == "chunk":
					_splat(gp, gv, float(g["s"]) * 1.2, DARK)
			landed = true
		g["p"] = gp
	var i := 0
	while i < _drops.size():
		var d: Dictionary = _drops[i]
		var v: Vector2 = d["v"]
		v.y += G * delta
		v.x *= 1.0 - 0.6 * delta
		d["v"] = v
		var p: Vector2 = (d["p"] as Vector2) + v * delta
		d["p"] = p
		if v.y > 0.0 and p.y >= float(d["floor"]):
			_splat(Vector2(p.x, float(d["floor"])), v, float(d["s"]), d["c"])
			_drops.remove_at(i)
			landed = true
			continue
		i += 1
	queue_redraw()
	if landed and _stain_layer.is_inside_tree():
		_stain_layer.queue_redraw()
	var grow := false
	for pl in _pools:
		if float(pl["r"]) < float(pl["target"]):
			pl["r"] = minf(float(pl["target"]), float(pl["r"]) + float(pl["rate"]) * delta)
			grow = true
	if grow and _pool_layer.is_inside_tree():
		_pool_layer.queue_redraw()
	if not _screen_blobs.is_empty():
		var j := 0
		while j < _screen_blobs.size():
			var b: Dictionary = _screen_blobs[j]
			b["age"] = float(b["age"]) + delta
			if float(b["age"]) >= float(b["life"]):
				_screen_blobs.remove_at(j)
				continue
			j += 1
		_screen.queue_redraw()


## A drop meets the street: slow ones leave round spots, fast ones a long
## streak in the travel direction with a crown of specks.
func _splat(at: Vector2, v: Vector2, s: float, c: Color) -> void:
	var spd := absf(v.x)
	var len := clampf(spd / 90.0, 0.0, 4.0)
	if _stains.size() >= MAX_STAINS:
		_stains.pop_front()
	_stains.append({"p": at, "rx": (1.2 + len) * s, "ry": maxf(0.6, 0.75 * s), "c": c, "dx": signf(v.x)})
	if s > 1.0 and spd > 120.0:
		for k in randi_range(1, 3):
			if _stains.size() >= MAX_STAINS:
				_stains.pop_front()
			var off := Vector2(signf(v.x) * randf_range(3.0, 4.0 + len * 3.0), randf_range(-1.5, 1.5))
			_stains.append({"p": at + off, "rx": randf_range(0.4, 0.8), "ry": 0.5, "c": c, "dx": 0.0})


func _biome() -> Color:
	var act := get_tree().get_first_node_in_group("run_act") if is_inside_tree() else null
	if act is RunAct:
		match (act as RunAct).map_id:
			"ledger_dive":
				return Color(0.18, 0.45, 0.42)
			"raven_grid":
				return Color(0.85, 0.2, 0.55)
			"neon_exchange":
				return Color(0.75, 0.1, 0.35)
	return FRESH


static func _snap(v: Vector2) -> Vector2:
	return (v / SNAP).round() * SNAP


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	for g in _gibs:
		var gp := _snap(g["p"] as Vector2)
		var s: float = g["s"]
		var r: float = g["rot"]
		match str(g["kind"]):
			"chunk":
				# A ragged lump: dark meat, a wet highlight, a pale fat edge.
				var pts := PackedVector2Array()
				var sd: int = g["seed"]
				for k in 6:
					var a := r + TAU * float(k) / 6.0
					var rr := s * (0.65 + 0.35 * float((sd >> k) & 1))
					pts.append(gp + Vector2(cos(a), sin(a) * 0.8) * rr)
				draw_colored_polygon(pts, Color(0.42, 0.03, 0.05))
				draw_rect(Rect2(gp + Vector2(-s * 0.3, -s * 0.4), Vector2(s * 0.5, s * 0.35)), Color(0.75, 0.12, 0.12))
				draw_rect(Rect2(gp + Vector2(s * 0.2, s * 0.1), Vector2(0.5, 0.5)), Color(0.95, 0.8, 0.7, 0.8))
			"tooth":
				draw_rect(Rect2(gp - Vector2(s * 0.4, s * 0.6), Vector2(s * 0.8, s * 1.2)), Color(0.96, 0.94, 0.86))
				draw_rect(Rect2(gp + Vector2(-s * 0.4, s * 0.3), Vector2(s * 0.8, 0.5)), Color(0.7, 0.1, 0.1))
			"bone":
				var dv := Vector2(cos(r), sin(r)) * s
				draw_line(gp - dv, gp + dv, Color(0.92, 0.88, 0.78), 1.1)
				draw_rect(Rect2(gp + dv - Vector2(0.6, 0.6), Vector2(1.2, 1.2)), Color(0.98, 0.95, 0.88))
	for d in _drops:
		var p := _snap(d["p"] as Vector2)
		var v: Vector2 = d["v"]
		var s: float = d["s"]
		var c: Color = d["c"]
		var tail := v * (0.018 if bool(d["streak"]) else 0.01)
		if tail.length() > 1.0:
			draw_line(p - tail, p, Color(c.r, c.g, c.b, 0.75), maxf(0.5, s * 0.7))
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), c)
		# A wet glint on the bigger drops.
		if s > 1.2:
			draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(0.5, 0.5)), Color(1.0, 0.55, 0.5, 0.7))


func _draw_stains() -> void:
	for st in _stains:
		var p := _snap(st["p"] as Vector2)
		var rx: float = st["rx"]
		var ry: float = st["ry"]
		var c: Color = st["c"]
		var dx: float = st["dx"]
		var base := Color(c.r * 0.8, c.g * 0.6, c.b * 0.6, 0.9)
		# Pixel ellipse: stacked rows; a streak leans the way it slid.
		var rows := maxi(1, int(round(ry * 2.0 / SNAP)))
		for r in rows:
			var fy := (float(r) + 0.5) / float(rows) * 2.0 - 1.0
			var half := rx * sqrt(maxf(0.0, 1.0 - fy * fy))
			var x0 := p.x - half + half * 0.35 * dx
			_stain_layer.draw_rect(Rect2(Vector2(snappedf(x0, SNAP), p.y + fy * ry - SNAP * 0.5), Vector2(maxf(SNAP, snappedf(half * 2.0, SNAP)), SNAP)), base)
		if rx > 1.5:
			_stain_layer.draw_rect(Rect2(p + Vector2(-SNAP, -ry * 0.4), Vector2(SNAP, SNAP)), Color(0.9, 0.25, 0.22, 0.45))


func _draw_pools() -> void:
	for pl in _pools:
		var p := _snap(pl["p"] as Vector2)
		var r: float = pl["r"]
		var seed: float = pl["seed"]
		var tint: Color = pl["tint"]
		var pts := PackedVector2Array()
		for k in 18:
			var a := TAU * float(k) / 18.0
			var wob := 0.8 + 0.25 * sin(a * 3.0 + seed) + 0.12 * sin(a * 7.0 + seed * 2.0)
			pts.append(p + Vector2(cos(a) * r * wob, sin(a) * r * 0.32 * wob))
		_pool_layer.draw_colored_polygon(pts, Color(tint.r * 0.55, tint.g * 0.35, tint.b * 0.35, 0.95))
		var inner := PackedVector2Array()
		for q in pts:
			inner.append(p + (q - p) * 0.72)
		_pool_layer.draw_colored_polygon(inner, Color(tint.r * 0.8, tint.g * 0.5, tint.b * 0.5, 0.95))
		# Wet shine: a thin light line on the far edge.
		_pool_layer.draw_line(p + Vector2(-r * 0.45, -r * 0.18), p + Vector2(r * 0.1, -r * 0.22), Color(1.0, 0.6, 0.55, 0.5), 0.7)


func _draw_screen() -> void:
	# Drawn on a 2 px grid (6 screen px on 1080p) so the glass splatter is
	# pixel art like everything else.
	var cell := 2.0
	for b in _screen_blobs:
		var age: float = b["age"]
		var life: float = b["life"]
		var a := clampf(1.0 - (age - life * 0.55) / (life * 0.45), 0.0, 1.0)
		var p: Vector2 = b["p"]
		var r: float = b["r"]
		var tint: Color = b["tint"]
		var c := Color(tint.r * 0.7, tint.g * 0.35, tint.b * 0.35, 0.86 * a)
		var hi := Color(minf(1.0, tint.r * 1.3), tint.g * 0.6, tint.b * 0.6, 0.86 * a)
		var run := minf(float(b["run"]), age * r * 1.2)
		var circles := [[p, r]]
		for d: Array in b["drops"]:
			circles.append([p + (d[0] as Vector2), float(d[1])])
		if run > 0.0:
			for k in int(run / cell) + 1:
				circles.append([p + Vector2(0, float(k) * cell), r * 0.28])
		var lo := p - Vector2(r * 2.2, r * 2.2)
		var hi_c := p + Vector2(r * 2.2, r * 2.2 + run)
		var y := snappedf(lo.y, cell)
		while y < hi_c.y:
			var x := snappedf(lo.x, cell)
			while x < hi_c.x:
				var q := Vector2(x + cell * 0.5, y + cell * 0.5)
				for ci: Array in circles:
					var cr: float = ci[1]
					var dd := q.distance_to(ci[0] as Vector2)
					if dd <= cr:
						# Lit rim on the upper left of each blob.
						var lit := dd > cr - cell * 1.2 and (q - (ci[0] as Vector2)).dot(Vector2(-0.7, -0.7)) > 0.0
						_screen.draw_rect(Rect2(x, y, cell, cell), hi if lit else c)
						break
				x += cell
			y += cell
