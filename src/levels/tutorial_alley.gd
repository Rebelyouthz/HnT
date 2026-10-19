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
## Per player, what the lesson started from (knives on the belt, the
## weapon in hand), so either player can finish it in co-op.
var _base: Dictionary = {}
var _counted_strike := -1
var _wrong_t := 0.0
var _bag: TrainingDummy
var _bag2: TrainingDummy
var _coach: Node2D
var _coach_anim: AnimatedSprite2D
var _lookouts: Array[Punk] = []
var _panel: PanelContainer
var _step_lab: Label
var _key_lab: RichTextLabel
var _tick_lab: Label

## One lesson each ("gate": how far right you may walk before it is done,
## BAG_X + 60 when not given): the button it teaches ("btn": what the player presses,
## read from Fighter.last_btn when the blow lands, so a mashed or comboed
## press still counts), how many it needs, the coach's lines and which bag.
const LESSONS := [
	{"id": "walk", "gate": BAG_X - 90.0, "title": "WALK TO THE BAG", "pad": "LEFT STICK  ·  HOLD RT TO RUN", "key": "A / D / W / S  ·  HOLD SHIFT TO RUN", "need": 1,
		"lines": [["father", "Basement's too small. Out back. Walk to the bag."]]},
	{"id": "right", "title": "RIGHT HAND", "pad": "PRESS X  ·  ON THE BAG", "key": "PRESS J  ·  ON THE BAG", "btn": ["X"], "need": 3,
		"lines": [["father", "Right hand first. X. Three on the bag."]]},
	{"id": "left", "title": "LEFT HAND", "pad": "PRESS Y  ·  ON THE BAG", "key": "PRESS K  ·  ON THE BAG", "btn": ["Y"], "need": 3,
		"lines": [["father", "Now the left. Y. Three."]]},
	{"id": "power", "title": "POWER PUNCH", "pad": "HOLD Y UNTIL YOU GLOW, LET GO", "key": "HOLD K UNTIL YOU GLOW, LET GO", "btn": ["HOLD Y"], "need": 1,
		"lines": [["son", "Can I just hit it really hard?"], ["father", "Hold Y. Wait for it. Let go."]]},
	{"id": "kick", "title": "KICKS", "pad": "HOLD LT (BIG LEFT TRIGGER) + X OR Y", "key": "HOLD U + J OR K", "btn": ["LT+X", "LT+Y"], "need": 2,
		"lines": [["father", "Legs are longer than arms. Hold LT and press X or Y."]]},
	{"id": "guard", "title": "GUARD", "pad": "HOLD LB (TOP LEFT) WHEN THE BAG SWINGS", "key": "HOLD Q WHEN THE BAG SWINGS", "need": 2,
		"lines": [["father", "Now it swings back. Hold your guard up when it comes."]]},
	{"id": "jump", "title": "JUMP", "pad": "A", "key": "SPACE", "need": 1,
		"lines": [["father", "Feet off the ground. Hop."]]},
	{"id": "throw", "title": "THROW", "pad": "NEXT TO THE BAG  ·  PRESS X + Y TOGETHER", "key": "NEXT TO THE BAG  ·  PRESS J + K TOGETHER", "btn": ["X+Y"], "need": 2,
		"lines": [["father", "Close up, both hands at once. X and Y together. Grab it and throw it. Twice."], ["son", "It's a bag, Dad. It won't learn anything."]]},
	{"id": "pickup", "title": "PICK UP THE PIPE", "pad": "STAND ON IT  ·  X + Y TOGETHER", "key": "STAND ON IT  ·  J + K TOGETHER", "need": 1,
		"lines": [["son", "There's a pipe."], ["father", "Stand on it, both hands. Pick it up. Don't lick it."]]},
	{"id": "pipe", "gate": BAG2_X + 60.0, "title": "HIT WITH THE PIPE", "pad": "PIPE IN HAND:  X = SIDE SWING   ·   Y = OVERHEAD SLAM   ·   X X Y = CRUSH", "key": "J SWING  ·  K SLAM  ·  J J K = CRUSH", "btn": ["X", "Y"], "need": 3,
		"lines": [["father", "Second bag. Pipe in your hands now: X swings it from the side, Y brings it down on top. X, X, Y is a crush. Three."]]},
	{"id": "toss", "gate": BAG2_X + 60.0, "title": "THROW THE PIPE", "pad": "HOLD LB + LT + RB + RT", "key": "HOLD I + U + O + SHIFT", "need": 1,
		"lines": [["father", "Now throw it. All four shoulders. A thrown pipe is a short conversation."]]},
	{"id": "knife", "gate": BAG2_X + 60.0, "title": "THROW A KNIFE", "pad": "HANDS EMPTY  ·  HOLD LB + LT + RB + RT", "key": "HANDS EMPTY  ·  HOLD I + U + O + SHIFT", "need": 1,
		"lines": [["father", "Knives on your belt. Same grip, all four. Throw one."]]},
	{"id": "lookouts", "gate": END_X, "title": "BEAT THE LOOKOUTS", "pad": "X + Y UP CLOSE THROWS  ·  DOWN + Y ON THE MAN ON THE FLOOR", "key": "J + K UP CLOSE THROWS  ·  S + K ON A MAN DOWN", "need": 2,
		"lines": [["", "TWO OF GANT'S LOOKOUTS. THEY HEARD THE NOISE."], ["father", "Real ones. X and Y together up close: grab him, put him down. Down and Y while he's on the floor. Go."]]},
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
	# A lesson, not a run: no level-ups or card draws in the alley.
	levels = false
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
	_panel.position = Vector2(370, 74)
	_panel.custom_minimum_size = Vector2(540, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_panel.add_child(col)
	_step_lab = Label.new()
	_step_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_step_lab, 20, Palette.LEMON)
	col.add_child(_step_lab)
	_key_lab = PadText.label("", 520, 15)
	col.add_child(_key_lab)
	_tick_lab = Label.new()
	_tick_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_tick_lab, 18, Color(0.5, 1.0, 0.55))
	col.add_child(_tick_lab)
	_panel.visible = false


## The lesson running now ({} between lessons and after the last).
func lesson() -> Dictionary:
	return LESSONS[_step] if _step >= 0 and _step < LESSONS.size() else {}


func lesson_id() -> String:
	return str(lesson().get("id", ""))


func _paint_panel() -> void:
	var l := lesson()
	if l.is_empty():
		_panel.visible = false
		return
	_panel.visible = true
	_step_lab.text = "LESSON %d / %d  ·  %s" % [_step + 1, LESSONS.size(), str(l["title"])]
	var pad := PadRouter.pad_prompts()
	if pad:
		PadText.set_text(_key_lab, str(l["pad"]))
	else:
		_key_lab.text = "[center]%s[/center]" % str(l["key"])
	var need := int(l.get("need", 1))
	var dots := ""
	for i in need:
		dots += ("●" if i < _count else "○") + " "
	_tick_lab.text = "%s  %d / %d%s" % [dots.strip_edges(), _count, need, "  ✅" if _count >= need else ""]


func _begin(i: int) -> void:
	_step = i
	_count = 0
	_counted_strike = -1
	if i >= LESSONS.size():
		_panel.visible = false
		_gate = map_w
		return
	var l: Dictionary = LESSONS[i]
	var id := str(l["id"])
	# The lesson card IS the objective here: the objectives card would sit
	# right behind it, so it stays folded away for the whole alley.
	var mh := get_tree().get_first_node_in_group("mission_hud")
	if mh is CanvasLayer:
		(mh as CanvasLayer).visible = false
	_gate = float(l.get("gate", BAG_X + 60.0))
	_paint_panel()
	Juice.play("res://assets/audio/card.wav")
	var lines: Array = []
	for row in l["lines"]:
		lines.append({"who": str(row[0]), "text": str(row[1])})
	if _talk:
		_talk.play(lines, true)
	_bag.mode = "spar" if id == "guard" else "still"
	match id:
		"pickup":
			_drop_pipe()
		"pipe":
			_coach_to(BAG2_X - 170.0)
		"knife":
			_base.clear()
			for f in _fighters():
				f.knives = maxi(f.knives, 2)
				_base[f.get_instance_id()] = f.knives
		"toss":
			_base.clear()
			for f in _fighters():
				_base[f.get_instance_id()] = f.pickup
		"lookouts":
			_spawn_lookouts()
			_coach_to(BAG2_X + 80.0)


## One more of what the lesson asks: 1/3, 2/3, 3/3 ✅ over the hero and in
## the panel, a rising tick; the last one finishes the lesson.
func _tick() -> void:
	var l := lesson()
	if l.is_empty():
		return
	var need := int(l.get("need", 1))
	if _count >= need:
		return
	_count += 1
	_paint_panel()
	var f := _hero()
	var at := (f.global_position if f else Vector2(BAG_X, 480)) + Vector2(0, -110)
	var done := _count >= need
	Juice.popup_number(at, "%d / %d%s" % [_count, need, "  ✅" if done else ""], Color(0.45, 1.0, 0.5) if done else Color(0.85, 1.0, 0.75))
	Mixer.play_sfx("res://assets/audio/sfx/parry_ring.ogg", 0.9 + 0.12 * float(_count), -8.0)
	if done:
		_done_step()


## The blow landed but with another button: say which one the lesson wants.
func _wrong(btn: String) -> void:
	if _clock_t() - _wrong_t < 1.2:
		return
	_wrong_t = _clock_t()
	var l := lesson()
	var pad := PadRouter.pad_prompts()
	var want := str(l["pad"] if pad else l["key"]).split("  ·  ")[0]
	var f := _hero()
	var at := (f.global_position if f else Vector2(BAG_X, 480)) + Vector2(0, -130)
	Juice.popup_number(at, "THAT WAS %s  ·  %s" % [btn, want], Color(1.0, 0.65, 0.3))


func _clock_t() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


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
	var next := _step + 1
	_step = -2
	get_tree().create_timer(0.9).timeout.connect(func() -> void: _begin(next))


## The pipe broke (or was thrown) before its lesson was done: drop another
## by the first bag so the lesson can always be finished.
func _spare_pipe(team: Array[Fighter]) -> void:
	for f in team:
		if f.pickup in Fighter.SWING_HELD:
			return
	if not get_tree().get_nodes_in_group("weapon_pickups").is_empty():
		return
	_drop_pipe()
	Juice.popup_number(Vector2(PIPE_X, 420.0), "ANOTHER PIPE", Palette.LEMON)


func _fighters() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			out.append(n as Fighter)
	return out


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


var _throw_t := -9.0


func _on_struck(_kind: String, bag: TrainingDummy) -> void:
	var l := lesson()
	if l.is_empty() or not l.has("btn"):
		return
	# Whoever actually hit the bag (co-op: player 2's blows are his own).
	var f: Fighter = bag.last_from as Fighter if bag.last_from is Fighter else _hero()
	if f == null:
		return
	var want_bag := _bag2 if str(l["id"]) == "pipe" else _bag
	if bag != want_bag:
		return
	# The throw lesson counts the heave itself (no strike id on a throw).
	if str(l["id"]) == "throw":
		if _kind == "throw" and _clock_t() - _throw_t > 0.5:
			_throw_t = _clock_t()
			_tick()
		elif _kind != "throw" and str(f.last_btn) != "X+Y":
			# (The first hand of a chord can land before the grab starts:
			# that is the throw being pressed, not a wrong button.)
			_wrong(str(f.last_btn))
		return
	# One count per blow, whatever it hit along the way.
	var sid := int(f.get("_strike_id"))
	if sid == _counted_strike:
		return
	var btn := str(f.last_btn)
	if str(l["id"]) == "pipe" and f.pickup == "":
		return
	if btn in (l["btn"] as Array):
		_counted_strike = sid
		_tick()
	else:
		_wrong(btn)


func _on_guarded() -> void:
	if lesson_id() == "guard":
		_tick()


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
	var team := _fighters()
	if team.is_empty():
		return
	# A player who dropped in after the alley opened still counts his guards.
	for f in team:
		if not f.guarded.is_connected(_on_guarded):
			f.guarded.connect(_on_guarded)
	match lesson_id():
		"walk":
			for f in team:
				if f.global_position.x >= BAG_X - 140.0:
					_tick()
		"jump":
			for f in team:
				if f.hop < -24.0:
					_tick()
		"pickup":
			for f in team:
				if f.pickup != "":
					_tick()
		"pipe":
			_spare_pipe(team)
		"toss":
			# Anyone who has held a weapon this lesson and now has empty hands
			# threw it; a pipe that broke on the way gets a spare.
			_spare_pipe(team)
			for f in team:
				var id := f.get_instance_id()
				if f.pickup != "":
					_base[id] = f.pickup
				elif str(_base.get(id, "")) != "":
					_tick()
		"knife":
			for f in team:
				if f.knives < int(_base.get(f.get_instance_id(), 0)):
					_tick()
		"lookouts":
			var down := 0
			for p in _lookouts:
				if not is_instance_valid(p) or p.is_queued_for_deletion() or p.hp <= 0:
					down += 1
			# One tick a frame, never a loop: a third body can't hang it.
			if _count < down:
				_tick()
		_:
			if _step >= LESSONS.size() and Party.all_past(END_X - 120.0):
				_start_film2()


## Tests and replays: every lesson ticked off at once.
func skip_training() -> void:
	_begin(LESSONS.size())
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
