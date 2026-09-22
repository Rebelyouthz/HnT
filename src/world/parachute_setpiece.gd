extends Node2D

## Campaign parachute setpiece. Wellness shuttle fails like the van. Lands Sleet Hour.

enum Phase { BOARD, FAIL, FALL, CLOUD, SLAP, LAND }

var _phase: Phase = Phase.BOARD
var _t := 0.0
var _fp := false
var _slapped := false
var _craft: Node2D
var _rotor: Polygon2D
var _son: ColorRect
var _dad: ColorRect
var _ground: ColorRect
var _cloud: ColorRect
var _vignette: ColorRect
var _caption: Label
var _hint: Label
var _wind: Label
var _alt: Label
var _vy := 28.0
var _debris: Array[Node2D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("parachute_fall")
	_sky()
	_ground = ColorRect.new()
	_ground.color = Color(0.62, 0.7, 0.74)
	_ground.position = Vector2(0, 980)
	_ground.size = Vector2(1280, 420)
	add_child(_ground)
	_cloud = ColorRect.new()
	_cloud.color = Color(0.92, 0.94, 0.96, 0.0)
	_cloud.position = Vector2(0, 200)
	_cloud.size = Vector2(1280, 200)
	add_child(_cloud)
	_craft = Node2D.new()
	_craft.position = Vector2(520, 260)
	add_child(_craft)
	var body := Polygon2D.new()
	body.color = Color(0.72, 0.78, 0.42)
	body.polygon = PackedVector2Array([
		Vector2(-90, -18), Vector2(110, -10), Vector2(96, 28), Vector2(-80, 22)
	])
	_craft.add_child(body)
	var stripe := Polygon2D.new()
	stripe.color = Palette.LEMON
	stripe.polygon = PackedVector2Array([
		Vector2(-40, -8), Vector2(70, -4), Vector2(66, 4), Vector2(-36, 0)
	])
	_craft.add_child(stripe)
	_rotor = Polygon2D.new()
	_rotor.color = Color(0.2, 0.22, 0.18, 0.75)
	_rotor.polygon = PackedVector2Array([
		Vector2(-130, -8), Vector2(150, -8), Vector2(150, 4), Vector2(-130, 4)
	])
	_rotor.position = Vector2(8, -24)
	_craft.add_child(_rotor)
	_dad = ColorRect.new()
	_dad.color = Palette.BRICK
	_dad.size = Vector2(22, 48)
	_dad.position = Vector2(-24, -8)
	_craft.add_child(_dad)
	_son = ColorRect.new()
	_son.color = Palette.LEMON
	_son.size = Vector2(18, 40)
	_son.position = Vector2(10, -2)
	_craft.add_child(_son)
	_snow()
	var layer := CanvasLayer.new()
	layer.layer = 55
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_vignette = ColorRect.new()
	_vignette.color = Color(0.02, 0.04, 0.08, 0.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_vignette)
	_caption = Label.new()
	_caption.position = Vector2(80, 500)
	_caption.size = Vector2(1120, 90)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_caption, 22, Palette.TEXT)
	layer.add_child(_caption)
	_hint = Label.new()
	_hint.position = Vector2(80, 620)
	_hint.size = Vector2(1120, 40)
	UiKit.apply_label(_hint, 14, Palette.MUTED)
	layer.add_child(_hint)
	_wind = Label.new()
	_wind.position = Vector2(40, 24)
	UiKit.apply_label(_wind, 16, Palette.LEMON)
	layer.add_child(_wind)
	_alt = Label.new()
	_alt.position = Vector2(40, 52)
	UiKit.apply_label(_alt, 14, Palette.EDGE)
	layer.add_child(_alt)
	Mixer.play_music("res://assets/audio/music_fall.wav")
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	_caption.text = "WELLNESS SHUTTLE. THE RETREAT THEY BILLED. NOBODY SAT ON THE HAY."
	_hint.text = "SPECIAL  ·  FIRST PERSON     LIGHT  ·  HOLD ON     PAUSE DOES NOT SKIP"
	Juice.unlock_logo("WELLNESS SHUTTLE", "They billed a retreat. The weather packed a personality.", "PARACHUTE")
	VoBank.summit_dad()


func _sky() -> void:
	var bands := [
		[Color(0.16, 0.32, 0.52), 0.0],
		[Color(0.22, 0.46, 0.7), 160.0],
		[Color(0.38, 0.58, 0.78), 320.0],
		[Color(0.62, 0.74, 0.86), 500.0]
	]
	for row in bands:
		var r := ColorRect.new()
		r.color = row[0]
		r.position = Vector2(0, row[1])
		r.size = Vector2(1280, 220)
		add_child(r)


func _snow() -> void:
	var p := GPUParticles2D.new()
	p.position = Vector2(640, -20)
	p.z_index = 8
	p.amount = 48
	p.lifetime = 2.4
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(700, 8, 1)
	mat.direction = Vector3(0.15, 1, 0)
	mat.spread = 8.0
	mat.gravity = Vector3(0, 80, 0)
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 90.0
	mat.color = Color(0.92, 0.95, 0.98, 0.55)
	p.process_material = mat
	add_child(p)


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_rotor):
		_rotor.rotation += (18.0 if _phase == Phase.BOARD else 2.4) * delta
	var meters := maxi(4, int(140.0 - _altitude_spent()))
	_alt.text = "ALTITUDE  ·  %d m  ·  HELL IS BELOW" % meters
	_wind.text = "WIND  ·  %d m/s  ·  %s" % [int(16 + _vy * 0.45), "FIRST PERSON" if _fp else "THIRD"]
	if Input.is_action_just_pressed("p1_special") or Input.is_action_just_pressed("p2_special"):
		_fp = not _fp
		_vignette.color.a = 0.55 if _fp else 0.0
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		Juice.shout("WATCH THE FALL")
	match _phase:
		Phase.BOARD:
			_craft.position.x += 48.0 * delta
			_craft.position.y += sin(_t * 3.2) * 0.45
			if _t > 2.6:
				_phase = Phase.FAIL
				_t = 0.0
				_caption.text = "SOMETHING GOES WRONG. LIKE THE VAN. THE ROTOR LEARNS A PERSONALITY."
				Juice.pulse_shake(10.0)
				Juice.play("res://assets/audio/boom.wav")
				Juice.boom(_craft.global_position)
				VoBank.father_nooo()
				_spawn_debris()
		Phase.FAIL:
			_craft.rotation += 1.1 * delta
			_craft.position.y += 90.0 * delta
			Juice.add_trauma(0.1)
			if _t > 1.9:
				_phase = Phase.FALL
				_t = 0.0
				_caption.text = "JUMP. THE GROUND IS A LONG WAY DOWN. THAT'S THE POINT."
				_dad.reparent(self)
				_son.reparent(self)
				_dad.position = Vector2(600, 180)
				_son.position = Vector2(660, 196)
				_craft.visible = false
				Juice.play("res://assets/audio/wind.wav")
				Juice.named_slowmo()
		Phase.FALL:
			_vy = minf(_vy + 22.0 * delta, 110.0)
			_dad.position.y += _vy * delta * 0.35
			_son.position.y += _vy * delta * 0.35
			_dad.rotation = sin(_t * 2.2) * 0.15
			_son.rotation = sin(_t * 2.4 + 0.4) * 0.18
			_ground.position.y = maxf(360.0, 980.0 - _t * 52.0)
			_apply_fp()
			if _t > 5.6:
				_phase = Phase.CLOUD
				_t = 0.0
				_caption.text = "A CLOUD. WHITE. QUIET. HELL IS STILL UNDER IT."
		Phase.CLOUD:
			_cloud.color.a = minf(0.92, _cloud.color.a + delta * 0.7)
			_dad.position.y += 24.0 * delta
			_son.position.y += 24.0 * delta
			_apply_fp()
			if _t > 1.7:
				_cloud.color.a = maxf(0.0, _cloud.color.a - delta)
				_phase = Phase.SLAP
				_t = 0.0
				_caption.text = "MID-AIR. A HAND. RESPECT. CLING WHEN IT TURNS GREEN."
				_spawn_slap()
		Phase.SLAP:
			_apply_fp()
		Phase.LAND:
			_vignette.color.a = lerpf(_vignette.color.a, 0.0, 0.12)
			_ground.position.y = lerpf(_ground.position.y, 400.0, 0.16)
			_dad.visible = true
			_son.visible = true
			_dad.position = _dad.position.lerp(Vector2(560, 470), 0.12)
			_son.position = _son.position.lerp(Vector2(620, 478), 0.12)
			_dad.rotation = lerpf(_dad.rotation, 0.0, 0.2)
			_son.rotation = lerpf(_son.rotation, 0.0, 0.2)
			if _t > 1.8:
				_go_sleet()


func _altitude_spent() -> float:
	match _phase:
		Phase.BOARD:
			return 2.0
		Phase.FAIL:
			return 8.0 + _t * 6.0
		Phase.FALL:
			return 22.0 + _t * 16.0
		Phase.CLOUD:
			return 112.0 + _t * 8.0
		_:
			return 136.0


func _apply_fp() -> void:
	var hide := _fp
	_dad.visible = not hide
	_son.visible = not hide
	for d in _debris:
		if is_instance_valid(d):
			d.visible = not hide


func _spawn_debris() -> void:
	for i in 7:
		var bits := ColorRect.new()
		bits.color = Color(0.55, 0.6, 0.32) if i % 2 == 0 else Color(0.25, 0.22, 0.18)
		bits.size = Vector2(8 + i * 2, 6)
		bits.position = _craft.position + Vector2(randf_range(-40.0, 50.0), randf_range(-12.0, 18.0))
		bits.set_meta("spin", randf_range(-3.0, 3.0))
		bits.set_meta("vy", randf_range(40.0, 90.0))
		add_child(bits)
		_debris.append(bits)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	for d in _debris:
		if not is_instance_valid(d):
			continue
		d.position.y += float(d.get_meta("vy", 60.0)) * delta
		d.rotation += float(d.get_meta("spin", 1.0)) * delta


func _spawn_slap() -> void:
	var qte := ClingQte.new()
	qte.window = 0.16 if App.difficulty == "finals" else 0.22
	if FamilyProfile.has_cbt("cling_callus"):
		qte.window += 0.05
	qte.prompt = "HAND SLAP  ·  RESPECT"
	qte.fail_shout = "MISSED"
	add_child(qte)
	var ok: bool = await qte.resolved
	_slapped = ok
	if ok:
		Juice.unlock_logo("RESPECT", "A slap at 140 meters. That's the love language.", "MID-AIR")
		VoBank.summit_son()
		Juice.pulse_shake(4.0)
	else:
		Juice.toast("challenge", "MISSED THE HAND", "You still land. Pride is optional. The ice is not.")
	_phase = Phase.LAND
	_t = 0.0
	_caption.text = "SLEET HOUR. A SURVIVOR HOUR. DON'T SIT. THE ICE IS A WAITING ROOM WITH WEATHER."
	_hint.text = "HOLDING THE LAKE. THE RETREAT FROZE ON PURPOSE."
	Mixer.play_music("res://assets/audio/music_street.wav")


func _go_sleet() -> void:
	App.film_kind = ""
	App.enter_map("sleet_hour")
