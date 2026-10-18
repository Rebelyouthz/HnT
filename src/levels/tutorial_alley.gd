extends RunAct

## BACK ALLEY · TRAINING. The night Benny and Rico were taken, behind the
## clinic: the father teaches the son to fight before Dock Street. One
## lesson at a time, each held behind an invisible line until it is done:
## walk, jab, heavy, guard, jump, pick up a pipe, hit with it, throw it,
## throw a knife from the belt, then two of Gant's lookouts for real.
## The hero who is not played stands in as the coach (a talker on the set),
## so the lines always have a mouth. Lesson text is not voiced.
## Done: the closing talk (intro film2) on the street, then Dock Street.

const BAG_X := 640.0
const BAG2_X := 1360.0
const PIPE_X := BAG_X - 110.0
const END_X := 2200.0

var _film2 := false
var _step := -1
var _gate := 0.0
var _count := 0
var _knives0 := 0
var _bag: TrainingDummy
var _bag2: TrainingDummy
var _coach: Node2D
var _coach_anim: AnimatedSprite2D
var _lookouts: Array[Punk] = []
var _panel: PanelContainer
var _step_lab: Label
var _key_lab: Label

## [title, pad keys, keyboard keys, coach lines, gate x while it runs]
var _lessons := [
	["WALK TO THE BAG", "LEFT STICK  ·  HOLD R2 TO RUN", "A / D / W / S  ·  HOLD SHIFT TO RUN",
		[["father", "Basement's too small. Out back. Walk to the bag."]], BAG_X - 90.0],
	["RIGHT HAND  ×3", "X  ·  RIGHT HAND", "J  /  LEFT MOUSE",
		[["father", "Jab. Fast and small. Three of them."]], BAG_X + 60.0],
	["LEFT HAND  ×2", "Y  ·  LEFT HAND  ·  HOLD FOR POWER", "K  /  MIDDLE MOUSE",
		[["son", "Can I just hit it really hard?"], ["father", "That's a heavy. Plant your feet. Two."]], BAG_X + 60.0],
	["GUARD  ×2", "HOLD L1  ·  STICK UP / DOWN PICKS THE HEIGHT", "HOLD Q  ·  W / S PICKS THE HEIGHT",
		[["father", "Now it swings back. Guard up and read the height."]], BAG_X + 60.0],
	["JUMP", "A", "SPACE",
		[["father", "Feet off the ground. Hop."]], BAG_X + 60.0],
	["PICK UP THE PIPE", "STAND ON IT  ·  X + Y TOGETHER", "STAND ON IT  ·  J + K TOGETHER",
		[["son", "There's a pipe."], ["father", "Stand on it, both hands. Pick it up. Don't lick it."]], BAG_X + 60.0],
	["HIT THE BAG WITH IT  ×2", "X", "J",
		[["father", "Second bag. Swing it. Twice."]], BAG2_X + 60.0],
	["THROW THE PIPE", "HOLD ALL FOUR  ·  L1 + L2 + R1 + R2", "HOLD I + U + O + SHIFT",
		[["father", "Now throw it. A thrown pipe is a short conversation."]], BAG2_X + 60.0],
	["THROW A KNIFE", "HANDS EMPTY  ·  HOLD L1 + L2 + R1 + R2", "HANDS EMPTY  ·  HOLD I + U + O + SHIFT",
		[["father", "Knives on your belt. Same grip, all four. Throw one."]], BAG2_X + 60.0],
	["BEAT THE LOOKOUTS", "EVERYTHING YOU JUST LEARNED", "EVERYTHING YOU JUST LEARNED",
		[["", "TWO OF GANT'S LOOKOUTS. THEY HEARD THE NOISE."], ["father", "Real ones. Everything you just learned. Go."]], END_X],
]


func _configure() -> void:
	map_id = "tutorial_alley"
	map_w = 2400.0
	spawn_at = Vector2(180, 490)
	goal_x = 99999.0
	light_preset = "dock_street"
	toast_title = "BACK ALLEY · TRAINING"
	toast_body = "The night they took Benny and Rico. Ten minutes to learn to fight."
	win_mode = "boss"
	music = "res://assets/audio/music_street.wav"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "tutorial")
	NightStreet.wet_floor(self, map_w, true)
	NightStreet.pixel_dock(self, map_w, false)
	NightStreet.bounds(self, map_w)
	NightStreet.rain(self, 900.0)
	for x in [420.0, 1000.0, 1620.0, 2140.0]:
		AmbientProp.lamp(self, Vector2(x, 500.0), 3)
	_bag = _make_bag(BAG_X)
	_bag2 = _make_bag(BAG2_X)
	_build_panel()


func _make_bag(x: float) -> TrainingDummy:
	var d := TrainingDummy.new()
	d.home = "street"
	d.global_position = Vector2(x, 492)
	add_child(d)
	d.struck.connect(_on_struck.bind(d))
	return d


## No toys, thugs, carts or bounties in the lesson.
func _place_parkour() -> void:
	pass


func _place_rescue() -> void:
	pass


## The hero nobody plays stands at the side as the coach.
func _place_coach() -> void:
	var have := {}
	for n in get_tree().get_nodes_in_group("players"):
		have[str(n.get("role"))] = true
	var who := "son" if have.has("father") else "father"
	if have.has(who) or not SpriteBook.has_who(who):
		return
	_coach = Node2D.new()
	_coach.add_to_group("talkers")
	_coach.set_meta("who", who)
	_coach.position = Vector2(BAG_X - 170.0, 462.0)
	add_child(_coach)
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var ang := TAU * float(i) / 16.0
		pts.append(Vector2(cos(ang) * 16.0, sin(ang) * 3.5))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.42)
	sh.position = Vector2(0, 3)
	_coach.add_child(sh)
	_coach_anim = SpriteBook.make_anim(who)
	SpriteBook.grow(_coach_anim, SpriteBook.FIGHTER_SCALE * SpriteBook.hero_k(who))
	_coach.add_child(_coach_anim)
	_coach_anim.play("idle")


## Coach walks over to the next station (walk clip, then idle).
func _coach_to(x: float) -> void:
	if _coach == null:
		return
	var dx := x - _coach.position.x
	if absf(dx) < 8.0:
		return
	_coach_anim.flip_h = dx < 0.0
	if _coach_anim.sprite_frames.has_animation("walk"):
		_coach_anim.play("walk")
	var tw := create_tween()
	tw.tween_property(_coach, "position:x", x, absf(dx) / 90.0)
	tw.tween_callback(func() -> void:
		_coach_anim.flip_h = false
		_coach_anim.play("idle")
	)


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var ui := PixelStage.attach_canvas(layer)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	_panel.position = Vector2(390, 196)
	_panel.custom_minimum_size = Vector2(500, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_panel.add_child(col)
	_step_lab = Label.new()
	_step_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_step_lab, 20, Palette.LEMON)
	col.add_child(_step_lab)
	_key_lab = Label.new()
	_key_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_key_lab, 15, Palette.TEXT)
	col.add_child(_key_lab)
	_panel.visible = false


func _paint_panel() -> void:
	if _step < 0 or _step >= _lessons.size():
		_panel.visible = false
		return
	var l: Array = _lessons[_step]
	_panel.visible = true
	_step_lab.text = "LESSON %d / %d  ·  %s" % [_step + 1, _lessons.size(), str(l[0])]
	var pad := not Input.get_connected_joypads().is_empty()
	_key_lab.text = str(l[1] if pad else l[2])


func _begin(i: int) -> void:
	_step = i
	_count = 0
	if i >= _lessons.size():
		_panel.visible = false
		_gate = map_w
		return
	var l: Array = _lessons[i]
	_gate = float(l[4])
	_paint_panel()
	Juice.play("res://assets/audio/card.wav")
	var lines: Array = []
	for row in l[3]:
		lines.append({"who": str(row[0]), "text": str(row[1])})
	if _talk:
		_talk.play(lines, true)
	match i:
		5:
			_drop_pipe()
		3:
			_bag.mode = "spar"
		4:
			_bag.mode = "still"
		6:
			_coach_to(BAG2_X - 170.0)
		8:
			var f := _hero()
			if f:
				f.knives = maxi(f.knives, 2)
				_knives0 = f.knives
		9:
			_spawn_lookouts()
			_coach_to(BAG2_X + 80.0)


## The pipe lies right by the first bag when its lesson starts, a bobbing
## arrow over it until it is in your hands.
func _drop_pipe() -> void:
	var pipe := WeaponPickup.new()
	pipe.kind = "pipe"
	var f := _hero()
	var y := 500.0 if f == null else clampf(f.global_position.y + 4.0, 470.0, 530.0)
	pipe.global_position = Vector2(PIPE_X, y)
	add_child(pipe)
	var arrow := Node2D.new()
	arrow.z_index = 30
	arrow.position = Vector2(0, -34)
	pipe.add_child(arrow)
	var tri := Polygon2D.new()
	tri.polygon = PackedVector2Array([Vector2(-9, -7), Vector2(9, -7), Vector2(0, 6)])
	tri.color = Palette.LEMON
	arrow.add_child(tri)
	var rim := Line2D.new()
	rim.points = PackedVector2Array([Vector2(-9, -7), Vector2(9, -7), Vector2(0, 6), Vector2(-9, -7)])
	rim.width = 2.0
	rim.default_color = Color(0, 0, 0, 0.85)
	arrow.add_child(rim)
	var tw := arrow.create_tween().set_loops()
	tw.tween_property(arrow, "position:y", -44.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(arrow, "position:y", -34.0, 0.4).set_trans(Tween.TRANS_SINE)


func _done_step() -> void:
	Juice.shout("GOOD")
	Mixer.play_sfx("res://assets/audio/sfx/parry_ring.ogg", 1.2, -6.0)
	var next := _step + 1
	_step = -2
	get_tree().create_timer(0.6).timeout.connect(func() -> void: _begin(next))


func _hero() -> Fighter:
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			return n as Fighter
	return null


func _ready() -> void:
	super._ready()
	_place_coach()
	for f in [_son, _dad]:
		if f:
			f.guarded.connect(_on_guarded)
			# The lesson hands out the pipe; nobody walks in armed.
			f.pickup = ""
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if _step == -1:
			_begin(0)
	)


func _on_struck(kind: String, bag: TrainingDummy) -> void:
	var f := _hero()
	match _step:
		1:
			if bag == _bag and kind in ["light", "gut-punch", "body_r"]:
				_count += 1
				if _count >= 3:
					_done_step()
		2:
			if bag == _bag and kind in ["heavy", "launcher", "uppercut", "turn_punch", "punch_l", "hook_l", "upper_l", "body_l"]:
				_count += 1
				if _count >= 2:
					_done_step()
		6:
			if bag == _bag2 and f and f.pickup != "":
				_count += 1
				if _count >= 2:
					_done_step()


func _on_guarded() -> void:
	if _step == 3:
		_count += 1
		if _count >= 2:
			_done_step()


func _spawn_lookouts() -> void:
	# One of Gant's bag snatchers and the clipboard punk: the guy in the
	# beanie is a real lookout who fights, not a stand-in on the mat.
	for row in [[END_X - 260.0, "Bag Snatch"], [END_X - 140.0, "Clipboard Punk"]]:
		var x: float = row[0]
		var p := Party.spawn_row(self, {
			"title": row[1], "x": x, "y": 495, "home": "street", "hp": 30, "pmin": BAG2_X + 140.0, "pmax": END_X
		}, 1.0)
		if p:
			_lookouts.append(p)


func _process(delta: float) -> void:
	super._process(delta)
	if _film2 or _state.failed or _state.cleared:
		return
	# The line you may not cross until the lesson is done.
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D and (n as Node2D).global_position.x > _gate:
			(n as Node2D).global_position.x = _gate
	var f := _hero()
	if f == null:
		return
	match _step:
		0:
			if f.global_position.x >= BAG_X - 140.0:
				_done_step()
		4:
			if f.hop < -24.0:
				_done_step()
		5:
			if f.pickup != "":
				_done_step()
		7:
			if f.pickup == "":
				_done_step()
		8:
			if f.knives < _knives0:
				_done_step()
		9:
			var alive := 0
			for p in _lookouts:
				if is_instance_valid(p) and not p.is_queued_for_deletion() and p.hp > 0:
					alive += 1
			if alive == 0:
				_begin(_lessons.size())
		_:
			if _step >= _lessons.size() and Party.all_past(END_X - 120.0):
				_start_film2()


## Tests and replays: every lesson ticked off at once.
func skip_training() -> void:
	_begin(_lessons.size())
	_start_film2()


## The closing talk plays on the street itself, then Dock Street.
func _start_film2() -> void:
	if _film2:
		return
	_film2 = true
	_panel.visible = false
	var lines: Variant = StoryBook.all().get("intro", {}).get("film2", [])
	if typeof(lines) != TYPE_ARRAY or (lines as Array).is_empty() or _talk == null:
		_finish_intro()
		return
	Juice.play("res://assets/audio/sting_intro.wav")
	_talk.closed.connect(_finish_intro, CONNECT_ONE_SHOT)
	_talk.play(lines as Array, true)


func _finish_intro() -> void:
	get_tree().paused = false
	FamilyProfile.mark_intro()
	App.enter_map("dock_street")
