class_name CouchCamera
extends Camera2D

## 1.5x: the street band (y 430-520) fills ~38% of the frame and bodies read
## at ~200 px on 1080p, one sprite texel per screen pixel.
const ZOOM := 1.5

var targets: Array[Node2D] = []
## Top-down survivor field: follow on both axes inside the arena, wider.
var field := false
var _look := 0.0
var _nag_cd := 0.0
var cinematic := Vector2.ZERO
var cinematic_on := false
## Zoom punch for big moves: extra zoom that swells and settles, leaning the
## frame toward where it happened.
var _pz := 0.0
var _pz_t := 0.0
var _pz_len := 0.0
var _pz_at := Vector2.ZERO
## A body the frame drifts after (the last kill of a fight) and for how long.
var _body: Node2D
var _body_t := 0.0


static func punch(tree: SceneTree, amount: float, secs: float, at: Vector2) -> void:
	if tree == null:
		return
	var c := tree.get_first_node_in_group("couch_cam") as CouchCamera
	if c == null:
		return
	if c._pz_t > 0.0 and amount < c._pz:
		return
	c._pz = amount
	c._pz_t = secs
	c._pz_len = maxf(0.05, secs)
	c._pz_at = at


## The last kill: the frame leans after the falling body until it lands.
static func follow_body(tree: SceneTree, body: Node2D, secs: float) -> void:
	var c := tree.get_first_node_in_group("couch_cam") as CouchCamera if tree else null
	if c == null or body == null:
		return
	c._body = body
	c._body_t = secs
	punch(tree, 0.12, secs, body.global_position)


func _punch_env(delta: float) -> float:
	if _pz_t <= 0.0:
		return 0.0
	_pz_t -= delta
	var p := 1.0 - clampf(_pz_t / _pz_len, 0.0, 1.0)
	# Snap in over the first fifth, ease back out over the rest.
	return clampf(p * 5.0, 0.0, 1.0) * (1.0 - smoothstep(0.2, 1.0, p))


func _ready() -> void:
	enabled = true
	zoom = Vector2(ZOOM, ZOOM)
	make_current()
	add_to_group("couch_cam")
	position_smoothing_enabled = false
	process_physics_priority = -40
	limit_top = 0
	if not field:
		limit_bottom = 720
	limit_left = 0
	# The level sets limit_right (map_w) before adding the camera; only fall
	# back when nobody did (it used to overwrite it, so the frame ran past
	# the end of the painted ground into black).
	if limit_right > 100000:
		limit_right = 3200
	ignore_rotation = true


func _physics_process(delta: float) -> void:
	var env := _punch_env(delta)
	zoom = Vector2.ONE * (SurviveField.ZOOM if field else ZOOM) * (1.0 + _pz * env)
	if _nag_cd > 0.0:
		_nag_cd -= delta
	if cinematic_on:
		var t := 1.0 - exp(-10.0 * delta)
		global_position = global_position.lerp(cinematic, t)
		offset = Juice.shake_offset()
		return
	var living: Array[Node2D] = []
	for t in targets:
		if is_instance_valid(t):
			living.append(t)
	if living.is_empty():
		offset = Juice.shake_offset()
		return
	var mid := Vector2.ZERO
	var face_sum := 0.0
	for t in living:
		mid += t.global_position
		if t is Fighter:
			face_sum += float((t as Fighter).facing)
	mid /= float(living.size())
	var look_target := (30.0 if field else 90.0) * clampf(face_sum / float(living.size()), -1.0, 1.0)
	var look_t := 1.0 - exp(-6.0 * delta)
	_look = lerpf(_look, look_target, look_t)
	mid.x += _look
	if living.size() == 2:
		_leash(living)
	var follow := 1.0 - exp(-8.0 * delta)
	var desired := mid
	var half := get_viewport_rect().size * 0.5 / zoom
	desired.x = clampf(desired.x, limit_left + half.x, limit_right - half.x)
	# Frame the feet a little below centre: street fights keep the kerb near
	# the bottom edge, roof runs (y 248) still get headroom.
	if field:
		desired.y = clampf(desired.y - 24.0, limit_top + half.y, limit_bottom - half.y)
	else:
		desired.y = clampf(desired.y - 30.0, 190.0, 425.0)
	if env > 0.0:
		desired = desired.lerp(_pz_at, 0.35 * env)
	if _body_t > 0.0:
		_body_t -= delta
		if is_instance_valid(_body):
			_pz_at = _body.global_position
			var bp := _body.global_position + Vector2(0, -20)
			bp.x = clampf(bp.x, limit_left + half.x, limit_right - half.x)
			bp.y = clampf(bp.y, limit_top + half.y, limit_bottom - half.y) if field else clampf(bp.y, 190.0, 425.0)
			desired = desired.lerp(bp, 0.55 * clampf(_body_t * 2.0, 0.0, 1.0))
		else:
			_body_t = 0.0
	# Vertical lerp ~0.12 toward the pair so roofs and street share one frame.
	var y_t := 1.0 - exp((-8.0 if field else -7.5) * delta)
	global_position.x = roundf(lerpf(global_position.x, desired.x, follow))
	global_position.y = roundf(lerpf(global_position.y, desired.y, y_t))
	offset = Juice.shake_offset()


func _leash(living: Array[Node2D]) -> void:
	if field:
		return
	var dist := absf(living[0].global_position.x - living[1].global_position.x)
	var max_sep := get_viewport_rect().size.x / zoom.x * 0.7
	if dist <= max_sep:
		return
	var left := living[0] if living[0].global_position.x < living[1].global_position.x else living[1]
	var right := living[1] if left == living[0] else living[0]
	var center := (left.global_position.x + right.global_position.x) * 0.5
	var cap := max_sep * 0.5
	if right.global_position.x > center + cap:
		right.global_position.x = center + cap
	if left.global_position.x < center - cap:
		left.global_position.x = center - cap
	if _nag_cd <= 0.0:
		_nag_cd = 2.2
		var laggard: Node2D = left
		if living[0] is Fighter and living[1] is Fighter:
			var a: Fighter = living[0]
			var b: Fighter = living[1]
			laggard = a if a.global_position.x < b.global_position.x else b
			var leader: Fighter = b if laggard == a else a
			if leader.plane == "roof" and (laggard as Fighter).plane != "roof":
				Juice.shout(Copy.come_on(FamilyProfile.father_name(), FamilyProfile.son_name(), "son"))
			else:
				var who := "father" if (laggard as Fighter).role == "father" else "son"
				Juice.shout(Copy.come_on(FamilyProfile.father_name(), FamilyProfile.son_name(), who))
