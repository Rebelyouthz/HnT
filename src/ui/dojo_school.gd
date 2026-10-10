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
	{"id": "light", "title": "LIGHT PUNCHES", "pad": "X  X  X", "key": "J  J  J", "line": "Three lights in a row: jab, cross, hook.", "need": 3},
	{"id": "heavy", "title": "HEAVY", "pad": "Y", "key": "K", "line": "A heavy on the dummy. Hold it to charge.", "need": 2},
	{"id": "upper", "title": "UPPERCUT", "pad": "UP + Y", "key": "W + K", "line": "Up and heavy: the launcher.", "need": 1},
	{"id": "low", "title": "LOW SLIDE", "pad": "DOWN + RT", "key": "S + SHIFT", "line": "Down and dash: slide in under the guard.", "need": 1},
	{"id": "air", "title": "JUMP KICK", "pad": "A, then X or Y", "key": "SPACE, then J or K", "line": "Jump and strike in the air.", "need": 1},
	{"id": "throw", "title": "THROW", "pad": "LT", "key": "U", "line": "Up close: grab and throw.", "need": 1},
	{"id": "block", "title": "BLOCK", "pad": "LB + STICK HEIGHT", "key": "I + W / S", "line": "The dummy swings now. Hold block and point the stick at the height over its head.", "need": 2, "spar": true},
	{"id": "combo", "title": "COMBO", "pad": "SEE THE BOARD", "key": "SEE THE BOARD", "line": "Land any combo from the board. Press as the ring on your body closes.", "need": 1},
	{"id": "art", "title": "ELEMENT ART", "pad": "X + Y", "key": "J + K", "line": "Both attack buttons together, away from the dummy. Your CHI ring is full for this lesson.", "need": 1, "chi": true},
	{"id": "grab", "title": "GRAB", "pad": "X + Y  (CLOSE)", "key": "J + K  (CLOSE)", "line": "The same buttons right next to the dummy: a grab.", "need": 1},
	{"id": "team", "title": "TEAM ATTACK", "pad": "HOLD Y, TAP B", "key": "HOLD K, TAP L", "line": "The gold TEAM ring is full: hold heavy and tap special. Your partner comes running.", "need": 1, "team": true},
]
const GOLD_EACH := 40
const GOLD_ALL := 300

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
		hero.combo_landed.connect(func(_id: String, _p: bool) -> void: _tick("combo"))


func _ready() -> void:
	layer = 40
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.frame(Palette.LEMON, 0.35))
	_panel.custom_minimum_size = Vector2(440, 0)
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
	_line.custom_minimum_size = Vector2(420, 0)
	UiKit.apply_label(_line, 12, Palette.TEXT)
	v.add_child(_line)
	var done: Array = FamilyProfile.data.get("school", [])
	for k in LESSONS.size():
		if not done.has(str(LESSONS[k]["id"])):
			_i = k
			break
	_start()


func _start() -> void:
	_n = 0
	_walked = 0.0
	_done_t = 0.0
	if hero:
		_last_x = hero.global_position.x
	var L: Dictionary = LESSONS[_i]
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
	_panel.position = Vector2(420.0 - _panel.size.x * 0.5, 230.0)


func _paint() -> void:
	var L: Dictionary = LESSONS[_i]
	_prog.text = "TUTORIAL  ·  LESSON %d / %d" % [_i + 1, LESSONS.size()]
	_title.text = str(L["title"])
	_btns.text = str(L["pad"]) if PadRouter.last_kind == "pad" else str(L["key"])
	_line.text = "%s   (%d / %d)" % [str(L["line"]), mini(_n, int(L["need"])), int(L["need"])]
	for c in _pips.get_children():
		c.queue_free()
	var done: Array = FamilyProfile.data.get("school", [])
	for k in LESSONS.size():
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.color = Palette.READY if done.has(str(LESSONS[k]["id"])) else (Palette.LEMON if k == _i else Color(0.2, 0.22, 0.3))
		_pips.add_child(pip)


func _on_struck(kind: String) -> void:
	match kind:
		"light", "jab", "cross", "gut-punch":
			_tick("light")
		"heavy", "roundhouse", "launcher":
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


func _tick(id: String) -> void:
	if _done_t > 0.0 or str(LESSONS[_i]["id"]) != id:
		return
	_n += 1
	Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.3, -6.0)
	if _n >= int(LESSONS[_i]["need"]):
		_pass()
	else:
		_paint()


func _pass() -> void:
	var id := str(LESSONS[_i]["id"])
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
	_n = int(LESSONS[_i]["need"])
	_paint()
	_done_t = 1.1
	Mixer.play_sfx("res://assets/audio/sfx/perfect_sting.ogg", 1.0, -3.0)
	Juice.popup_number(hero.global_position + Vector2(0, -110) if hero else Vector2(640, 300), "LESSON CLEAR" + ("  +%dG" % GOLD_EACH if first else ""), Palette.READY)
	UiKit.blast(_panel, _panel.size * 0.5, Palette.READY, 160.0)


func _process(delta: float) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if _done_t > 0.0:
		_done_t -= delta
		if _done_t <= 0.0:
			if _i + 1 >= LESSONS.size():
				_graduate()
				return
			_i += 1
			_start()
		return
	var id := str(LESSONS[_i]["id"])
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
		"grab":
			if int(FamilyProfile.data.get("grabs_landed", 0)) > int(_base["grabs"]):
				_tick("grab")
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
	_btns.text = "+%dG" % GOLD_ALL if not paid else "ALL LESSONS DONE"
	_line.text = "Every move in the book. The board on the right still drills combos; leave with BACK."
	Juice.shout("BLACK BELT. ALLEGEDLY.")
	Mixer.play_sfx("res://assets/audio/level_up.wav", 1.0, -2.0)
	hero = null
	finished.emit()
