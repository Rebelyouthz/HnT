class_name DojoBoard
extends CanvasLayer

## The dojo's wall chart, drawn over the practice mat. Left: every combo of
## the fighter's style with its buttons (pad or keyboard, whichever was used
## last) - locked ones show where to learn them, landed ones get a tick, a
## perfect landing a gold star. Bottom: the guard and roll drill. Right: the
## dummy's last damage, SPAR toggle and LEAVE.

signal leave
signal spar_toggled(on: bool)

var _who: Fighter
var _dummy: TrainingDummy
var _stage: Control
var _rows: Dictionary = {}
var _done: Dictionary = {}
var _guide: Label
var _dmg: Label
var _spar: Button
var _spar_on := false
var _pad := false


func bind(_act: Node, who: Fighter, dummy: TrainingDummy) -> void:
	_who = who
	_dummy = dummy
	if _who != null:
		_who.combo_landed.connect(_on_landed)


func _ready() -> void:
	layer = 6
	_stage = PixelStage.attach_canvas(self)
	_build.call_deferred()


func _build() -> void:
	var role := _who.role if _who != null else "son"
	var st := ComboBook.style(role)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Color(0.05, 0.04, 0.06, 0.86), UiKit.GOLD))
	card.position = Vector2(850, 112)
	card.custom_minimum_size = Vector2(420, 0)
	_stage.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	var head := Label.new()
	head.text = "%s STYLE  ·  %s" % [str(st.get("name", "STREET")), "THE SON" if role == "son" else "THE FATHER"]
	UiKit.apply_label(head, 17, UiKit.GOLD)
	head.add_theme_font_override("font", UiKit.title_font())
	col.add_child(head)
	var blurb := Label.new()
	blurb.text = str(st.get("blurb", ""))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(400, 0)
	UiKit.apply_label(blurb, 11, Palette.MUTED)
	col.add_child(blurb)
	for c: Dictionary in ComboBook.all_for(role):
		var row := _row(c)
		col.add_child(row)
	# Guard drill strip along the bottom.
	_guide = Label.new()
	_guide.position = Vector2(300, 668)
	_guide.size = Vector2(680, 40)
	_guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_guide, 13, Color(0.75, 0.88, 1.0))
	_stage.add_child(_guide)
	# Right column: damage readout, spar toggle, leave.
	_dmg = Label.new()
	_dmg.position = Vector2(14, 470)
	_dmg.size = Vector2(300, 60)
	_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiKit.apply_label(_dmg, 14, Palette.TEXT)
	_stage.add_child(_dmg)
	_spar = UiKit.button("SPAR: OFF", Vector2(200, 36))
	_spar.position = Vector2(14, 540)
	_spar.focus_mode = Control.FOCUS_NONE
	_spar.pressed.connect(_toggle_spar)
	_stage.add_child(_spar)
	var out := UiKit.button("◀  LEAVE DOJO", Vector2(200, 36))
	out.position = Vector2(14, 584)
	out.focus_mode = Control.FOCUS_NONE
	out.pressed.connect(func() -> void: leave.emit())
	_stage.add_child(out)
	_refresh_labels()


func _row(c: Dictionary) -> Control:
	var id := str(c["id"])
	var rarity := Rarity.normalize(str(c.get("rarity", "common")))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var name := Label.new()
	name.text = str(c.get("title", id))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.apply_label(name, 13, Rarity.color(rarity))
	top.add_child(name)
	var mark := Label.new()
	UiKit.apply_label(mark, 13, UiKit.GOLD)
	top.add_child(mark)
	var keys := Label.new()
	UiKit.apply_label(keys, 13, Palette.TEXT)
	v.add_child(keys)
	_rows[id] = {"combo": c, "panel": p, "mark": mark, "keys": keys}
	return p


func _refresh_labels() -> void:
	_pad = PadRouter.last_kind == "pad"
	for id: String in _rows:
		var r: Dictionary = _rows[id]
		var c: Dictionary = r["combo"]
		var learned := ComboBook.is_learned(c)
		var keys := r["keys"] as Label
		var mark := r["mark"] as Label
		if learned:
			keys.text = ComboBook.steps_label(c, _pad)
			keys.modulate = Color.WHITE
		else:
			keys.text = "LOCKED  ·  learn it at the dojo board in camp"
			keys.modulate = Color(1, 1, 1, 0.45)
		match str(_done.get(id, "")):
			"perfect":
				mark.text = "★ PERFECT"
			"good":
				mark.text = "✓ LANDED"
			_:
				mark.text = "" if learned else "🔒"
	if _pad:
		_guide.text = "BLOCK: hold LB  ·  stick ↑ HIGH  ·  neutral MID  ·  ↓ LOW      ROLL: LB + RT      GET-UP: X / Y on the floor      AIR: A then Y = spinning heel      L3: spar"
	else:
		_guide.text = "BLOCK: hold I  ·  W HIGH  ·  neutral MID  ·  S LOW      ROLL: I + SHIFT      GET-UP: J / K on the floor      AIR: SPACE then K = spinning heel      TAB: spar"


func _on_landed(id: String, perfect: bool) -> void:
	if not _rows.has(id):
		return
	if str(_done.get(id, "")) != "perfect":
		_done[id] = "perfect" if perfect else "good"
	var p := (_rows[id] as Dictionary)["panel"] as Control
	p.pivot_offset = p.size * 0.5
	var tw := p.create_tween()
	p.scale = Vector2(1.06, 1.06)
	tw.tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	_refresh_labels()


func _toggle_spar() -> void:
	_spar_on = not _spar_on
	_spar.text = "SPAR: ON" if _spar_on else "SPAR: OFF"
	spar_toggled.emit(_spar_on)
	Juice.shout("SPAR" if _spar_on else "STILL")


func _process(_delta: float) -> void:
	if _guide == null:
		return
	if (PadRouter.last_kind == "pad") != _pad:
		_refresh_labels()
	if _dummy != null and is_instance_valid(_dummy):
		_dmg.text = "LAST HIT  %d\nHITS  %d" % [_dummy.last_dmg, _dummy.hits]
	# Tab (or L3 on a pad, see _input) toggles spar without the mouse.
	if Input.is_key_pressed(KEY_TAB) and not _tab_held:
		_tab_held = true
		_toggle_spar()
	elif not Input.is_key_pressed(KEY_TAB):
		_tab_held = false


var _tab_held := false


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_LEFT_STICK:
		_toggle_spar()
