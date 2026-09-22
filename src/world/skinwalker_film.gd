extends Node2D

## Authored chill film. Human/animal first. Then the slip. Pause does not skip.

enum Beat { WAIT, WRONG, CALL, SLIP, TEAR, NAME, HURT, DONE }

var _beat: Beat = Beat.WAIT
var _t := 0.0
var _left := false
var _sky: ColorRect
var _tubes: Array[ColorRect] = []
var _patient: Node2D
var _dog: Node2D
var _true: Node2D
var _gape: Polygon2D
var _eye_l: ColorRect
var _eye_r: ColorRect
var _invoice: ColorRect
var _ghost: ColorRect
var _caption: Label
var _who: Label
var _hint: Label
var _dad: ColorRect
var _son: ColorRect
var _number: Label
var _slip_juiced := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("skinwalker_film")
	_build_room()
	_build_cast()
	_build_hud()
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	Mixer.stop_music()
	Juice.play("res://assets/audio/sfx_phase.wav" if ResourceLoader.exists("res://assets/audio/sfx_phase.wav") else "res://assets/audio/sting_intro.wav")
	_say("", "WAITING ROOM. FLUORESCENT FOREVER. SOMEONE IS ALREADY SITTING.")
	_hint.text = Copy.WATCH_SLIP
	Juice.unlock_logo("NUMBER 87", "There is no 87. That's the bit. Until it sits down.", "FILM")


func _build_room() -> void:
	_sky = ColorRect.new()
	_sky.color = Color(0.14, 0.145, 0.13)
	_sky.position = Vector2.ZERO
	_sky.size = Vector2(1280, 720)
	add_child(_sky)
	var wall := ColorRect.new()
	wall.color = Color(0.18, 0.19, 0.17)
	wall.position = Vector2(0, 80)
	wall.size = Vector2(1280, 40)
	add_child(wall)
	for i in 6:
		var tube := ColorRect.new()
		tube.color = Color(0.86, 0.88, 0.72, 0.55)
		tube.position = Vector2(70.0 + i * 200.0, 88)
		tube.size = Vector2(160, 8)
		add_child(tube)
		_tubes.append(tube)
	var floor_r := ColorRect.new()
	floor_r.color = Color(0.22, 0.22, 0.2)
	floor_r.position = Vector2(0, 520)
	floor_r.size = Vector2(1280, 200)
	add_child(floor_r)
	var wet := ColorRect.new()
	wet.color = Color(0.16, 0.17, 0.16, 0.45)
	wet.position = Vector2(0, 500)
	wet.size = Vector2(1280, 24)
	add_child(wet)
	for i in 5:
		var seat := ColorRect.new()
		seat.color = Color(0.28, 0.28, 0.26)
		seat.position = Vector2(160.0 + i * 180.0, 478)
		seat.size = Vector2(70, 28)
		add_child(seat)
		var back := ColorRect.new()
		back.color = Color(0.32, 0.32, 0.3)
		back.position = Vector2(168.0 + i * 180.0, 456)
		back.size = Vector2(54, 22)
		add_child(back)
	var plaque := Label.new()
	plaque.position = Vector2(80, 176)
	plaque.text = "DON'T SIT. SITTING IS HOW THEY WIN."
	UiKit.apply_label(plaque, 14, Palette.MUTED)
	add_child(plaque)
	_number = Label.new()
	_number.position = Vector2(80, 140)
	_number.text = "NOW SERVING  ·  88"
	UiKit.apply_label(_number, 22, Palette.EDGE)
	add_child(_number)
	var mag := ColorRect.new()
	mag.color = Color(0.55, 0.18, 0.16)
	mag.position = Vector2(430, 492)
	mag.size = Vector2(36, 28)
	mag.rotation = 0.18
	add_child(mag)
	var mag_l := Label.new()
	mag_l.position = Vector2(2, 6)
	mag_l.text = "1994"
	UiKit.apply_label(mag_l, 10, Palette.TEXT)
	mag.add_child(mag_l)
	_invoice = ColorRect.new()
	_invoice.color = Color(0.86, 0.82, 0.7, 0.0)
	_invoice.position = Vector2(820, 120)
	_invoice.size = Vector2(360, 220)
	add_child(_invoice)
	var inv_l := Label.new()
	inv_l.position = Vector2(16, 16)
	inv_l.size = Vector2(328, 188)
	inv_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_l.text = "PAST DUE\nFAMILY THERAPY × 12\nNOBODY SAT DOWN\nTHE WAITING LIST TORE\nTHEY CAN HURT NOW"
	UiKit.apply_label(inv_l, 16, Color(0.18, 0.12, 0.1))
	_invoice.add_child(inv_l)
	_ghost = ColorRect.new()
	_ghost.color = Color(0.92, 0.9, 0.82, 0.0)
	_ghost.position = Vector2(560, 280)
	_ghost.size = Vector2(28, 90)
	add_child(_ghost)


func _build_cast() -> void:
	_patient = Node2D.new()
	_patient.position = Vector2(724, 456)
	add_child(_patient)
	var torso := ColorRect.new()
	torso.color = Color(0.42, 0.4, 0.38)
	torso.position = Vector2(-14, -36)
	torso.size = Vector2(28, 40)
	_patient.add_child(torso)
	var head := ColorRect.new()
	head.color = Color(0.78, 0.7, 0.62)
	head.position = Vector2(-10, -58)
	head.size = Vector2(20, 22)
	_patient.add_child(head)
	_dog = Node2D.new()
	_dog.position = Vector2(640, 500)
	add_child(_dog)
	var body := ColorRect.new()
	body.color = Color(0.3, 0.24, 0.18)
	body.position = Vector2(-22, -12)
	body.size = Vector2(48, 18)
	_dog.add_child(body)
	var snout := ColorRect.new()
	snout.color = Color(0.34, 0.26, 0.18)
	snout.position = Vector2(18, -16)
	snout.size = Vector2(18, 12)
	_dog.add_child(snout)
	_eye_l = ColorRect.new()
	_eye_l.color = Color(0.82, 0.78, 0.2)
	_eye_l.position = Vector2(22, -14)
	_eye_l.size = Vector2(5, 4)
	_dog.add_child(_eye_l)
	_true = Node2D.new()
	_true.position = Vector2(640, 430)
	_true.visible = false
	_true.modulate.a = 0.0
	add_child(_true)
	var pale := ColorRect.new()
	pale.color = Color(0.92, 0.88, 0.8)
	pale.position = Vector2(-10, -70)
	pale.size = Vector2(18, 78)
	_true.add_child(pale)
	var skull := ColorRect.new()
	skull.color = Color(0.94, 0.9, 0.84)
	skull.position = Vector2(-14, -108)
	skull.size = Vector2(26, 38)
	_true.add_child(skull)
	_eye_r = ColorRect.new()
	_eye_r.color = Color(0.98, 0.9, 0.1)
	_eye_r.position = Vector2(-8, -98)
	_eye_r.size = Vector2(8, 10)
	_true.add_child(_eye_r)
	var eye2 := ColorRect.new()
	eye2.color = Color(0.95, 0.86, 0.08)
	eye2.position = Vector2(4, -100)
	eye2.size = Vector2(10, 12)
	_true.add_child(eye2)
	_gape = Polygon2D.new()
	_gape.color = Color(0.16, 0.04, 0.05)
	_gape.polygon = PackedVector2Array([
		Vector2(-10, -72), Vector2(12, -74), Vector2(8, -38), Vector2(-8, -36)
	])
	_true.add_child(_gape)
	_dad = ColorRect.new()
	_dad.color = Palette.BRICK
	_dad.size = Vector2(22, 52)
	_dad.position = Vector2(220, 470)
	add_child(_dad)
	_son = ColorRect.new()
	_son.color = Palette.LEMON
	_son.size = Vector2(18, 44)
	_son.position = Vector2(252, 478)
	add_child(_son)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 55
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var letter_t := ColorRect.new()
	letter_t.color = Color(0, 0, 0, 1)
	letter_t.position = Vector2(0, 0)
	letter_t.size = Vector2(1280, 78)
	layer.add_child(letter_t)
	var letter_b := ColorRect.new()
	letter_b.color = Color(0, 0, 0, 1)
	letter_b.position = Vector2(0, 642)
	letter_b.size = Vector2(1280, 78)
	layer.add_child(letter_b)
	_who = Label.new()
	_who.position = Vector2(80, 500)
	_who.size = Vector2(1120, 24)
	UiKit.apply_label(_who, 14, Palette.EDGE)
	layer.add_child(_who)
	_caption = Label.new()
	_caption.position = Vector2(80, 528)
	_caption.size = Vector2(1120, 90)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_caption, 22, Palette.TEXT)
	layer.add_child(_caption)
	_hint = Label.new()
	_hint.position = Vector2(40, 24)
	UiKit.apply_label(_hint, 14, Palette.MUTED)
	layer.add_child(_hint)


func _say(who: String, text: String) -> void:
	_who.text = StoryBook.who_name(who) if who != "" else "THE STREET"
	_who.add_theme_color_override("font_color", Palette.BRICK if who == "father" else (Palette.LEMON if who == "son" else Palette.EDGE))
	_caption.text = text
	_caption.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.18)


func _process(delta: float) -> void:
	_t += delta
	_flicker()
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		Juice.shout("WATCH THE SLIP")
		return
	if Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("p2_light") or Input.is_action_just_pressed("p2_jump"):
		_advance()
		return
	match _beat:
		Beat.WAIT:
			_dog.position.x = 640.0 + sin(_t * 0.8) * 2.0
			_patient.position.y = 456.0 + sin(_t * 0.5) * 0.6
			if _t > 3.4:
				_go(Beat.WRONG)
		Beat.WRONG:
			_dog.rotation = sin(_t * 3.2) * 0.12
			_dog.position.y = 500.0 - absf(sin(_t * 2.1)) * 10.0
			_eye_l.size = Vector2(5, 4 + absf(sin(_t * 5.0)) * 3.0)
			_patient.rotation = sin(_t * 1.6) * 0.05
			_patient.position.y = 456.0 - absf(sin(_t * 4.4)) * 6.0
			if _t > 3.1:
				_go(Beat.CALL)
		Beat.CALL:
			if _t < 0.05:
				Juice.whistle(_dog.global_position)
			elif _t > 1.1 and _t < 1.2:
				Juice.help_call(_dog.global_position)
			_dog.position.x = lerpf(_dog.position.x, 680.0, 0.04)
			if _t > 3.0:
				_go(Beat.SLIP)
		Beat.SLIP:
			_run_slip(delta)
			if _t > 4.2:
				_go(Beat.TEAR)
		Beat.TEAR:
			_invoice.color.a = minf(0.92, _invoice.color.a + delta * 0.7)
			_ghost.color.a = 0.18 + 0.18 * sin(_t * 8.0)
			_ghost.position.x = 560.0 + sin(_t * 11.0) * 40.0
			_true.modulate.a = 0.55 + 0.45 * absf(sin(_t * 6.0))
			if _t > 3.6:
				_go(Beat.NAME)
		Beat.NAME:
			_true.modulate.a = 1.0
			_gape.scale = Vector2(1.0, 1.0 + absf(sin(_t * 2.2)) * 0.35)
			if _t > 3.8:
				_go(Beat.HURT)
		Beat.HURT:
			_true.position.x = lerpf(_true.position.x, 420.0, 0.06)
			_dad.position.x = lerpf(_dad.position.x, 300.0, 0.08)
			_son.position.x = lerpf(_son.position.x, 332.0, 0.08)
			if _t > 2.6:
				_leave()
		_:
			pass


func _run_slip(delta: float) -> void:
	_patient.modulate.a = maxf(0.0, _patient.modulate.a - delta * 0.8)
	_dog.scale.y = maxf(0.2, _dog.scale.y - delta * 0.5)
	_dog.scale.x = minf(1.4, _dog.scale.x + delta * 0.3)
	_true.visible = true
	_true.modulate.a = minf(1.0, _true.modulate.a + delta * 0.55)
	_true.position.y = lerpf(_true.position.y, 500.0, 0.06)
	_gape.scale.y = 1.0 + _t * 0.18
	_eye_r.size = Vector2(8 + _t * 2.0, 10 + _t)
	if int(_t * 10.0) % 7 == 0:
		_true.modulate.a = 0.15 if _true.modulate.a > 0.5 else 1.0
	if not _slip_juiced:
		_slip_juiced = true
		Juice.gape(_true.global_position)
		Juice.yellow_stare(_true.global_position)
		Juice.slip(_true.global_position)
		Juice.named_slowmo()
		Juice.pulse_shake(8.0)


func _flicker() -> void:
	var pulse := 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.008)
	if _beat == Beat.SLIP or _beat == Beat.TEAR:
		pulse = 0.35 + 0.65 * randf()
	_sky.color = Color(0.14 * pulse, 0.145 * pulse, 0.13 * pulse)
	for tube in _tubes:
		tube.color.a = 0.25 + 0.55 * pulse
	if _beat >= Beat.WRONG:
		_number.text = "NOW SERVING  ·  87" if int(Time.get_ticks_msec() / 400) % 2 == 0 else "NOW SERVING  ·  —"


func _go(next: Beat) -> void:
	_beat = next
	_t = 0.0
	match next:
		Beat.WRONG:
			_say("son", "Is that a skinwalker?")
			Juice.play("res://assets/audio/sfx_crawl.wav" if ResourceLoader.exists("res://assets/audio/sfx_crawl.wav") else "res://assets/audio/dash.wav")
		Beat.CALL:
			_say("", "A WHISTLE. THEN A HELP THAT IS NOT A PERSON YOU KNOW. IT WAS ALREADY IN THE HOUSE.")
		Beat.SLIP:
			_say("", "THE FORM DOES NOT HOLD. PALE. THIN. THE MOUTH LEARNS TOO WIDE.")
			Mixer.set_tension(true)
		Beat.TEAR:
			_say("", "THEY WERE NOT ALWAYS THIS VISIBLE. THE SKIPPED SESSION TORE THE WAITING LIST. THEY PHASE IN. THEY CAN HURT.")
			Juice.phase_flicker(_true)
		Beat.NAME:
			_say("father", "THAT is a skinwalker.")
			VoBank.dad_skinwalker()
			Juice.shout(Copy.THAT_WALKER)
		Beat.HURT:
			_say("son", "I asked a hundred times. Those photos were trash. This one isn't.")
			VoBank.son_skinwalker()
			_hint.text = "FILE IT. THE STREET STILL WANTS A CONVERSATION."
		_:
			pass


func _advance() -> void:
	match _beat:
		Beat.WAIT:
			_go(Beat.WRONG)
		Beat.WRONG:
			_go(Beat.CALL)
		Beat.CALL:
			_go(Beat.SLIP)
		Beat.SLIP:
			_go(Beat.TEAR)
		Beat.TEAR:
			_go(Beat.NAME)
		Beat.NAME:
			_go(Beat.HURT)
		Beat.HURT:
			_leave()
		_:
			pass


func _leave() -> void:
	if _left:
		return
	_left = true
	_beat = Beat.DONE
	App.film_kind = ""
	if has_node("/root/NetSession") and NetSession.active() and NetSession.is_host():
		NetSession.broadcast_begin("waiting_room", App.begin_extra())
		return
	App.enter_map("waiting_room")
