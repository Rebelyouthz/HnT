extends Node2D

## A Father or Son puppet for staged films (tower, cutscenes): the real
## sprite sheet with poses driven by code - climb reach, slip, sit on an
## edge, dive, hang from a wire or ladder. role / hop let Talk put speech
## bubbles over the head.

var role := "father"
var hop := 0.0
var anim: AnimatedSprite2D
var _reach := false
var _t := 0.0
var _mode := "idle"
var _move: Tween


func build() -> void:
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * 14.0, sin(a) * 3.2))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.4)
	sh.position = Vector2(0, 2)
	sh.name = "Shadow"
	add_child(sh)
	if SpriteBook.has_who(role):
		anim = SpriteBook.make_anim(role)
		add_child(anim)


func _frame(clip: String, frac: float) -> void:
	if anim == null or not anim.sprite_frames.has_animation(clip):
		return
	anim.play(clip)
	anim.pause()
	var n := anim.sprite_frames.get_frame_count(clip)
	anim.frame = clampi(int(round(frac * float(n - 1))), 0, n - 1)


func _shadow(on: bool) -> void:
	var s := get_node_or_null("Shadow") as Node2D
	if s:
		s.visible = on


## On the wall: arms up (jump take-off pose), back to camera-ish.
func reach(on: bool) -> void:
	_mode = "climb"
	_shadow(false)
	_reach = on
	_frame("jump", 0.12)


func climb_to(p: Vector2, dur: float) -> void:
	_mode = "climb"
	_shadow(false)
	_frame("jump", 0.12)
	_stop()
	_move = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move.tween_property(self, "position", p, dur)
	# Pull-up: a little squash at the top of each move.
	var sq := create_tween()
	sq.tween_property(self, "scale", Vector2(1.05, 0.95), dur * 0.4)
	sq.tween_property(self, "scale", Vector2.ONE, dur * 0.6)


func slip(p: Vector2) -> void:
	_frame("hurt", 0.3)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position", p, 0.25)
	Juice.play("res://assets/audio/stumble.wav")
	Juice.pulse_shake(5.0)


func _stop() -> void:
	if _move and _move.is_valid():
		_move.kill()


## Sit on an edge: the real torso with one leg laid over the ledge and the
## shin hanging (assets/sprites/<role>/sit_*.png, cut by tools/sit_pose.py),
## the far leg a shade darker behind it. p is the edge (where the knees
## bend); face is the side the legs dangle over. The shins swing.
var _sit: Node2D
var _knees: Array[Node2D] = []


func sit_at(p: Vector2, face: int = 1) -> void:
	_stop()
	_mode = "sit"
	position = p
	rotation = 0.0
	_shadow(false)
	var meta_path := "res://assets/sprites/%s/sit.json" % role
	if not FileAccess.file_exists(meta_path):
		if anim:
			anim.play("idle")
			anim.speed_scale = 0.6
			anim.position.y += 9.0
		return
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if anim:
		anim.visible = false
	if _sit:
		_sit.queue_free()
	_knees.clear()
	_sit = Node2D.new()
	var k := SpriteBook.DRAW_SCALE * SpriteBook.FIGHTER_SCALE
	_sit.scale = Vector2(k * float(face), k)
	add_child(_sit)
	var hip: Array = m["hip"]
	var th: Array = m["thigh"]
	var st: Array = m["shin_top"]
	# Origin = the knee at the edge; the hip sits a thigh's length back.
	var hip_x := -(float(th[0]) - 6.0)
	for far in [true, false]:
		var shade := Color(0.55, 0.55, 0.62) if far else Color.WHITE
		var off := Vector2(-4, -2) if far else Vector2.ZERO
		var thigh := _part("sit_thigh", shade)
		thigh.position = Vector2(hip_x - 6.0, -float(th[1]) * 0.5) + off
		_sit.add_child(thigh)
		var knee := Node2D.new()
		knee.position = Vector2(-2.0, 0.0) + off
		var shin := _part("sit_shin", shade)
		shin.position = Vector2(-float(st[0]), -2.0)
		knee.add_child(shin)
		_sit.add_child(knee)
		_knees.append(knee)
		if far:
			# The torso goes between the far and the near leg.
			var torso := _part("sit_torso", Color.WHITE)
			torso.position = Vector2(hip_x - float(hip[0]), -float(hip[1]))
			_sit.add_child(torso)


func _part(name: String, shade: Color) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://assets/sprites/%s/%s.png" % [role, name])
	sp.centered = false
	sp.texture_filter = SpriteBook.world_filter()
	sp.modulate = shade
	return sp


func _swing(_delta: float) -> void:
	var amp := 0.32 if role == "son" else 0.14
	var spd := 3.2 if role == "son" else 1.7
	for i in _knees.size():
		_knees[i].rotation = sin(_t * spd + float(i) * 1.9) * amp


func stand_at(p: Vector2) -> void:
	_stop()
	if _sit:
		_sit.queue_free()
		_sit = null
		_knees.clear()
	if anim:
		anim.visible = true
	_mode = "idle"
	position = p
	rotation = 0.0
	scale = Vector2.ONE
	_shadow(true)
	if anim:
		anim.speed_scale = 1.0
		anim.rotation = 0.0
		anim.position = Vector2(0, 4.0 - float(anim.sprite_frames.get_frame_texture("idle", 0).get_height()) * SpriteBook.DRAW_SCALE * 0.5)
		anim.play("idle")


func dive_pose() -> void:
	_mode = "dive"
	_shadow(false)
	if anim and anim.sprite_frames.has_animation("dive"):
		_frame("dive", 0.5)
	else:
		_frame("jump", 0.5)
	create_tween().tween_property(self, "rotation", 1.2, 0.6)


func hang_pose() -> void:
	_mode = "hang"
	_shadow(false)
	_frame("jump", 0.12)


func _process(delta: float) -> void:
	_t += delta
	if _sit and _mode != "sit":
		# Any other pose stands him back up.
		_sit.queue_free()
		_sit = null
		_knees.clear()
		if anim:
			anim.visible = true
	if _mode == "sit":
		_swing(delta)
	if anim == null:
		return
	match _mode:
		"climb":
			# Alternate arm reach: flip the sprite every half second.
			anim.flip_h = fmod(_t, 0.9) < 0.45
		"hang":
			anim.rotation = 0.08 * sin(_t * 6.0)
