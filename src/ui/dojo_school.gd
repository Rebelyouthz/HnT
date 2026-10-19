class_name DojoSchool
extends CanvasLayer

## The dojo TUTORIAL: one lesson at a time on the mat, from walking to the
## Dad + Son team attack. Each lesson shows the buttons (pad or keyboard,
## whichever was used last), checks what the hero actually did on the dummy,
## ticks off with a sting and moves on. First clear of a lesson pays gold;
## clearing them all pays a bonus. Progress is kept (FamilyProfile "school").

signal finished

const LESSONS := [
	{"id": "walk", "title": "WALK", "pad": "LEFT STICK", "key": "A / D", "line": "Walk back and forth on the mat.", "need": 1},
	{"id": "jump", "title": "JUMP", "pad": "A", "key": "SPACE", "line": "Jump. Hold it for a higher one.", "need": 2},
	{"id": "light", "title": "RIGHT HAND", "pad": "X  X  X", "key": "J  J  J", "line": "X is the right hand: straight, hook, body shot. Down + X goes to the body.", "need": 3},
	{"id": "heavy", "title": "LEFT HAND", "pad": "Y  Y  Y", "key": "K  K  K", "line": "Y is the left hand: jab, hook, uppercut. Forward + Y is the big hook, hold Y for the power punch.", "need": 2},
	{"id": "upper", "req": "uppercut", "title": "UPPERCUT", "pad": "Y, THEN UP  or  RS UP", "key": "J OR K, THEN W", "line": "Hit first, then push up straight after: the blow turns into the launcher on the spot (or flick the right stick up).", "need": 1},
	{"id": "low", "title": "LOW SLIDE", "pad": "DOWN + RT", "key": "S + SHIFT", "line": "Down and dash: slide in under the guard.", "need": 1},
	{"id": "air", "title": "JUMP KICK", "pad": "A, then X or Y", "key": "SPACE, then J or K", "line": "Jump and strike in the air.", "need": 1},
	{"id": "rs_jab", "req": "pad", "title": "RIGHT STICK CROSS", "pad": "R-STICK  flick ▶", "key": "-", "line": "Flick the right stick toward the dummy and let go: a cross. The stick's path is the punch, and the stick has its own moves (MOVES > STICK).", "need": 2},
	{"id": "rs_hook", "req": "pad", "title": "RIGHT STICK HOOK", "pad": "R-STICK  quarter circle ▲ ▶", "key": "-", "line": "Swing the right stick in a quarter circle that ends toward the dummy: a hook to the jaw.", "need": 2},
	{"id": "sh_body", "title": "GUARD STRIKES", "pad": "HOLD LB + X  /  LB + Y", "key": "HOLD I + J  /  I + K", "line": "Hold guard and press X: a short elbow (the Kid: a superman punch). Hold guard and press Y: a headbutt (the Kid: a flying knee).", "need": 2},
	{"id": "sh_hook", "title": "RUNNING STRIKES", "pad": "HOLD RT + X  /  RT + Y", "key": "HOLD SHIFT + J  /  SHIFT + K", "line": "Hold run and press X: a spinning backfist. Hold run and press Y: a roundhouse kick.", "need": 2},
	{"id": "kick", "title": "KICKS", "pad": "HOLD LT + X  /  LT + Y", "key": "HOLD U + J  /  U + K", "line": "LT is the kick trigger. Hold it and press X: a front kick. Hold it and press Y: a high kick.", "need": 2},
	{"id": "throw", "title": "THROW", "pad": "X + Y TOGETHER", "key": "J + K TOGETHER", "line": "Up close, both hands at once: grab and throw.", "need": 1},
	{"id": "block", "title": "BLOCK", "pad": "LB + STICK HEIGHT", "key": "I + W / S", "line": "The dummy swings now. Hold block and point the stick at the height over its head.", "need": 2, "spar": true},
	{"id": "combo", "req": "later", "title": "COMBO", "pad": "SEE THE BOARD", "key": "SEE THE BOARD", "line": "Land any combo from the board. Press as the ring on your body closes.", "need": 1},
	{"id": "art", "req": "later", "title": "ELEMENT ART", "pad": "X + Y", "key": "J + K", "line": "Both attack buttons together, away from the dummy. Your CHI ring is full for this lesson.", "need": 1, "chi": true},
	{"id": "grab", "req": "later", "title": "GRAB", "pad": "X + Y  (CLOSE)", "key": "J + K  (CLOSE)", "line": "The same buttons right next to the dummy: a grab.", "need": 1},
	{"id": "team", "req": "later", "title": "TEAM ATTACK", "pad": "HOLD Y, TAP B", "key": "HOLD K, TAP L", "line": "The gold TEAM ring is full: hold heavy and tap special. Your partner comes running.", "need": 1, "team": true},
]
const GOLD_EACH := 40
const GOLD_ALL := 300

## The lessons for this visit: the basics you own, then one TRAIN lesson
## for every move bought in the dojo and not yet drilled (3 clean reps on
## the dummy and it works in the street).
var _lessons: Array = []
var hero: Fighter
var dummy: TrainingDummy
var _i := 0
var _n := 0
var _last_x := 0.0
var _walked := 0.0
var _was_air := false
var _was_block := false
var _base := {}
var _done_t := 0.0
var _panel: PanelContainer
var _title: Label
var _btns: Label
var _line: Label
var _prog: Label
var _pips: HBoxContainer


func bind(h: Fighter, d: TrainingDummy) -> void:
	hero = h
	dummy = d
	if dummy:
		dummy.struck.connect(_on_struck)
	if hero:
		hero.combo_landed.connect(func(id: String, _p: bool) -> void:
			_tick("combo")
			# A bought combo trains by landing the whole chain.
			if _i < _lessons.size() and str(_lessons[_i].get("train", "")) == id:
				_on_struck(id)
		)


func _ready() -> void:
	layer = 40
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.frame(Palette.LEMON, 0.35))
	_panel.custom_minimum_size = Vector2(380, 0)
	PixelStage.attach_canvas(self).add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_panel.add_child(v)
	var top := HBoxContainer.new()
	_prog = Label.new()
	UiKit.apply_label(_prog, 12, Palette.MUTED)
	top.add_child(_prog)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	_pips = HBoxContainer.new()
	_pips.add_theme_constant_override("separation", 3)
	top.add_child(_pips)
	v.add_child(top)
	_title = UiKit.title("", 20, Palette.LEMON)
	v.add_child(_title)
	_btns = Label.new()
	_btns.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_btns, 15, UiKit.GOLD)
	v.add_child(_btns)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(360, 0)
	UiKit.apply_label(_line, 12, Palette.TEXT)
	v.add_child(_line)
	_lessons = []
	for L in LESSONS:
		if _have(str(L.get("req", ""))):
			_lessons.append(L)
	var table: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dojo.json"))
	for id in FamilyProfile.dojo_pending():
		var row := {}
		if id.begins_with("b_"):
			row = BrutalBook.row(id.substr(2))
		elif table is Array:
			for r in table:
				if str(r.get("id", "")) == id:
					row = r
		var inp := str(row.get("input", "SEE THE MOVE CARD"))
		_lessons.append({"id": "train_" + id, "train": id, "title": "TRAIN  ·  " + str(row.get("title", id.to_upper())), "pad": inp, "key": inp, "line": "%s  New move: land it 3 times on the dummy and it works in the street." % str(row.get("line", "")), "need": FamilyProfile.TRAIN_REPS})
	var done: Array = FamilyProfile.data.get("school", [])
	_i = _lessons.size() - 1
	for k in _lessons.size():
		if not done.has(str(_lessons[k]["id"])):
			_i = k
			break
	_start()


func _have(req: String) -> bool:
	match req:
		"":
			return true
		"pad":
			return PadRouter.pad_prompts()
		"later":
			return int(FamilyProfile.data.get("runs", 0)) >= 3
	return FamilyProfile.dojo_learned(req)


func _start() -> void:
	_n = 0
	_walked = 0.0
	_done_t = 0.0
	if hero:
		_last_x = hero.global_position.x
	var L: Dictionary = _lessons[_i]
	_base = {"arts": int(FamilyProfile.data.get("arts_used", 0)), "grabs": int(FamilyProfile.data.get("grabs_landed", 0)), "team": int(FamilyProfile.data.get("team_attacks", 0))}
	if dummy:
		dummy.mode = "spar" if L.get("spar", false) else "still"
	if hero and L.get("chi", false):
		hero.chi = Elements.CHI_MAX
	if hero and L.get("team", false):
		hero.team = Elements.TEAM_MAX
	_paint()
	UiKit.pop_in(_panel)
	_panel.reset_size()
	# Left column under the player plate: above the fighter's head, clear
	# of the style chart on the right and the drill buttons below.
	_panel.position = Vector2(16.0, 150.0)


## If the fighter jumps up under the card anyway, it turns see-through.
func _fade_over_hero(delta: float) -> void:
	if _panel == null or hero == null or not is_instance_valid(hero):
		return
	var k := float(PixelStage.DESIGN.x) / float(PixelStage.LOGICAL.x)
	var feet := hero.get_viewport().get_canvas_transform() * hero.global_position * k
	var body := Rect2(feet - Vector2(40, 190), Vector2(80, 196))
	var over := Rect2(_panel.position, _panel.size).intersects(body)
	_panel.modulate.a = move_toward(_panel.modulate.a, 0.2 if over else 1.0, delta * 5.0)


func _paint() -> void:
	var L: Dictionary = _lessons[_i]
	_prog.text = "TUTORIAL  ·  LESSON %d / %d" % [_i + 1, _lessons.size()]
	_title.text = str(L["title"])
	_btns.text = str(L["pad"]) if PadRouter.pad_prompts() else str(L["key"])
	_line.text = "%s   (%d / %d)" % [str(L["line"]), mini(_n, int(L["need"])), int(L["need"])]
	for c in _pips.get_children():
		c.queue_free()
	var done: Array = FamilyProfile.data.get("school", [])
	for k in _lessons.size():
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.color = Palette.READY if done.has(str(_lessons[k]["id"])) else (Palette.LEMON if k == _i else Color(0.2, 0.22, 0.3))
		_pips.add_child(pip)


## Dummy hit kinds -> dojo move ids.
const KIND_TO_MOVE := {"air-mix": "air_mix", "stomp1": "stomp_finish", "stomp2": "stomp_finish", "stomp3": "stomp_finish", "throw": "grab_slam", "air-upper": "uppercut"}


func _on_struck(kind: String) -> void:
	if _i < _lessons.size() and _lessons[_i].has("train"):
		var want := str(_lessons[_i]["train"])
		if str(KIND_TO_MOVE.get(kind, kind)) == want:
			var ready := FamilyProfile.dojo_rep(want)
			_tick(str(_lessons[_i]["id"]))
			if ready:
				Juice.move_banner("MOVE LEARNED  ·  STREET READY", str(_lessons[_i]["title"]).replace("TRAIN  ·  ", ""), "fist")
				# A stick strike asks where it goes once the banner has had its moment.
				if StickBook.FROM_DOJO.has(want):
					var who := str(hero.get("role")) if hero else "son"
					get_tree().create_timer(1.8).timeout.connect(func() -> void: EquipPrompt.ask(who, str(StickBook.FROM_DOJO[want])))
		return
	if hero and str(hero.get("_last_kind")) in ["light", "cross_rs"] and kind in ["light", "jab", "cross", "cross_rs"]:
		_tick("rs_jab")
	match kind:
		"light", "jab", "cross", "gut-punch", "body_r":
			_tick("light")
		"heavy", "roundhouse", "launcher", "punch_l", "hook_l", "upper_l", "body_l":
			if kind == "roundhouse" and hero and float(hero.get("_sh_t")) > 0.0:
				_tick("sh_hook")
			else:
				_tick("heavy")
		"uppercut", "air-upper":
			_tick("upper")
			if kind == "air-upper":
				_tick("air")
		"slide":
			_tick("low")
		"jump-kick", "air-spin", "dive", "air-mix":
			_tick("air")
		"throw":
			_tick("throw")
		"front_kick", "high_kick", "low_kick":
			_tick("kick")
		"hook", "hook_r":
			_tick("rs_hook")
		"spin_backfist", "turn_punch":
			if hero and float(hero.get("_sh_t")) > 0.0:
				_tick("sh_hook")
		"elbow", "headbutt", "superman_punch", "flying_knee":
			_tick("sh_body")


func _tick(id: String) -> void:
	if _done_t > 0.0 or str(_lessons[_i]["id"]) != id:
		return
	_n += 1
	Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.3, -6.0)
	if _n >= int(_lessons[_i]["need"]):
		_pass()
	else:
		_paint()


func _pass() -> void:
	var id := str(_lessons[_i]["id"])
	var done: Array = FamilyProfile.data.get("school", [])
	if not done.has(id):
		done.append(id)
		FamilyProfile.data["school"] = done
	# Gold once per lesson ever (replaying the tutorial pays nothing).
	var paid: Array = FamilyProfile.data.get("school_paid", [])
	var first := not paid.has(id)
	if first:
		paid.append(id)
		FamilyProfile.data["school_paid"] = paid
		FamilyProfile.add_gold(GOLD_EACH)
	_n = int(_lessons[_i]["need"])
	_paint()
	_done_t = 1.1
	Mixer.play_sfx("res://assets/audio/sfx/perfect_sting.ogg", 1.0, -3.0)
	Juice.popup_number(hero.global_position + Vector2(0, -110) if hero else Vector2(640, 300), "LESSON CLEAR" + ("  +%dG" % GOLD_EACH if first else ""), Palette.READY)
	UiKit.blast(_panel, _panel.size * 0.5, Palette.READY, 160.0)


func _process(delta: float) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	_fade_over_hero(delta)
	if _done_t > 0.0:
		_done_t -= delta
		if _done_t <= 0.0:
			if _i + 1 >= _lessons.size():
				_graduate()
				return
			_i += 1
			_start()
		return
	var id := str(_lessons[_i]["id"])
	match id:
		"walk":
			_walked += absf(hero.global_position.x - _last_x)
			_last_x = hero.global_position.x
			if _walked > 180.0:
				_tick("walk")
		"jump":
			var air := hero.hop < -24.0
			if air and not _was_air:
				_tick("jump")
			_was_air = air
		"block":
			var blk := hero.counter_t > 0.3
			if blk and not _was_block:
				_tick("block")
			_was_block = blk
		"art":
			if int(FamilyProfile.data.get("arts_used", 0)) > int(_base["arts"]):
				_tick("art")
			elif hero.chi < 20.0 and hero.art_lock <= 0.0:
				hero.chi = Elements.CHI_MAX
		"grab", "throw":
			if int(FamilyProfile.data.get("grabs_landed", 0)) > int(_base["grabs"]):
				_tick(id)
		"team":
			if int(FamilyProfile.data.get("team_attacks", 0)) > int(_base["team"]):
				_tick("team")
			elif hero.team < Elements.TEAM_MAX and hero.art_lock <= 0.0:
				hero.team = Elements.TEAM_MAX


func _graduate() -> void:
	var paid := bool(FamilyProfile.data.get("school_graduated", false))
	if not paid:
		FamilyProfile.data["school_graduated"] = true
		FamilyProfile.add_gold(GOLD_ALL)
	if dummy:
		dummy.mode = "still"
	_title.text = "GRADUATED"
	_btns.text = "+%dG" % GOLD_ALL if not paid else "ALL _lessons DONE"
	_line.text = "Every move in the book. The board on the right still drills combos; leave with BACK."
	Juice.shout("BLACK BELT. ALLEGEDLY.")
	Mixer.play_sfx("res://assets/audio/level_up.wav", 1.0, -2.0)
	hero = null
	finished.emit()
