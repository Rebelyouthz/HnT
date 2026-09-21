extends Node2D

## Mortal Kombat-style Father vs Son. Best of three. Same kits. Couch camera.

var _son: Fighter
var _dad: Fighter
var _wins := {"son": 0, "father": 0}
var _round := 1
var _lock := false
var _cam: CouchCamera
var _hud: CanvasLayer
var _round_lab: Label
var _score: Label
var map_w := 1400.0


func _ready() -> void:
	add_to_group("versus_arena")
	add_to_group("dock_world")
	App.versus = true
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.08, 0.05, 0.08), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "versus")
	NightStreet.wet_floor(self, map_w)
	NightStreet.tenement(self, Rect2(40, 40, 280, 240), Color(0.18, 0.08, 0.1))
	NightStreet.tenement(self, Rect2(1080, 40, 280, 240), Color(0.1, 0.08, 0.16))
	Blockout.solid(self, Rect2(520, 248, 360, 22), true)
	Blockout.poly(self, Rect2(520, 248, 360, 22), Color(0.28, 0.16, 0.18), 2)
	fire_escape_local(560.0)
	NightStreet.bounds(self, map_w)
	NightStreet.neon(self, Vector2(480, 120), "VERSUS  ·  BEST OF THREE")
	NightStreet.plaque(self, Vector2(80, 160), "GROUNDED  /  YOU'RE FIRED", Palette.MUTED, 14)
	NightStreet.rain(self, 700.0)
	var rig := LightRig.new()
	rig.preset = "neon_exchange"
	add_child(rig)
	add_child(BloodSim.new())
	Mixer.play_music("res://assets/audio/music_vs.wav")
	_son = Party.make_son(Vector2(360, 490))
	_dad = Party.make_father(Vector2(980, 490))
	_son.vs_mode = true
	_dad.vs_mode = true
	_son.facing = 1
	_dad.facing = -1
	add_child(_son)
	add_child(_dad)
	_son.died.connect(func() -> void:
		_ko("father")
	)
	_dad.died.connect(func() -> void:
		_ko("son")
	)
	_cam = CouchCamera.new()
	_cam.limit_right = int(map_w)
	_cam.targets = [_son, _dad]
	add_child(_cam)
	_hud = CanvasLayer.new()
	_hud.layer = 22
	add_child(_hud)
	_round_lab = Label.new()
	_round_lab.position = Vector2(400, 16)
	_round_lab.size = Vector2(480, 36)
	_round_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_round_lab, 22, Palette.LEMON)
	_hud.add_child(_round_lab)
	_score = Label.new()
	_score.position = Vector2(400, 52)
	_score.size = Vector2(480, 28)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_score, 16, Palette.EDGE)
	_hud.add_child(_score)
	var hint := Label.new()
	hint.position = Vector2(40, 668)
	hint.size = Vector2(1200, 40)
	hint.text = PadRouter.p1_prompt() + "  ·  " + PadRouter.p2_prompt() + "  ·  PAUSE EXITS"
	UiKit.apply_label(hint, 13, Palette.MUTED)
	_hud.add_child(hint)
	_clash()
	_paint()


func fire_escape_local(at_x: float) -> void:
	var fe := FireEscape.new()
	fe.configure(at_x, 248.0, 500.0)
	add_child(fe)


func _process(_delta: float) -> void:
	_paint()
	if Input.is_action_just_pressed("p1_pause"):
		App.versus = false
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		App.back_to_hub("run")


func _paint() -> void:
	_round_lab.text = "ROUND %d" % _round
	_score.text = "%s  %d   ·   %d  %s" % [
		FamilyProfile.son_name(), _wins["son"], _wins["father"], FamilyProfile.father_name()
	]


func _clash() -> void:
	Juice.unlock_logo("ROUND %d" % _round, "Portrait clash. Banter. Then the invoice.")
	Juice.play("res://assets/audio/sting_boss.wav")
	Juice.toast("challenge", "FIGHT", "Best of three. Finishers are mandatory manners.")
	if _round == 1:
		var talk := Talk.new()
		add_child(talk)
		talk.play([
			{"who": "son", "text": "If I win, you do the dishes. If dishes exist."},
			{"who": "father", "text": "If I win, you're grounded. That's the finisher."}
		])


func _ko(winner: String) -> void:
	if _lock:
		return
	_lock = true
	_wins[winner] = int(_wins[winner]) + 1
	var line := Copy.GROUNDED if winner == "father" else Copy.FIRED
	Juice.shout(line)
	Juice.freeze_frames(10)
	Juice.pulse_shake(12.0)
	Juice.play("res://assets/audio/finish.wav")
	Juice.toast("achievement", line, "%s takes round %d." % [StoryBook.who_name(winner), _round])
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if int(_wins["son"]) >= 2 or int(_wins["father"]) >= 2:
			_end(winner)
		else:
			_round += 1
			_reset()
	)


func _reset() -> void:
	_lock = false
	for f in [_son, _dad]:
		if f == null or not is_instance_valid(f):
			continue
		f.downed = false
		f.hp = f.max_hp
		f.bleed = 0.0
		f.invuln = 40
		f.steam = Fighter.STEAM_MAX
		f.plane = "street"
		f.downed_changed.emit()
	_son.global_position = Vector2(360, 490)
	_dad.global_position = Vector2(980, 490)
	_clash()


func _end(winner: String) -> void:
	FamilyProfile.mark_vs()
	Juice.unlock_logo("THERAPY MATCH", "%s filed the other one." % StoryBook.who_name(winner))
	get_tree().paused = true
	var layer := CanvasLayer.new()
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(dim)
	var t := Label.new()
	t.position = Vector2(200, 220)
	t.size = Vector2(880, 60)
	t.text = "WINNER  ·  %s" % StoryBook.who_name(winner)
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.apply_label(t, 36, Palette.LEMON if winner == "son" else Palette.BRICK)
	layer.add_child(t)
	var b := UiKit.button("BACK TO THE CLINIC", Vector2(280, 48))
	b.position = Vector2(500, 360)
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(func() -> void:
		get_tree().paused = false
		App.versus = false
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		App.back_to_hub("awards")
	)
	layer.add_child(b)
	b.grab_focus()
