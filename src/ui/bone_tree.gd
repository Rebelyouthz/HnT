extends Control

## The BONE YARD tree in the dojo: grows from the bottom up (1 root, 2, 3,
## 3, then the 3 big supers on top). Each move has its own icon; HOLD the
## button on a node to fill it from the bottom and pay the FIGHT TOKENS.
## Bought moves are drilled 3 times on the dojo dummy before they work in
## the street. When two owned moves answer the same grab, pick the active one.

signal closed

const ROW_Y := [604.0, 492.0, 380.0, 268.0, 156.0]
const COL_X := [190.0, 380.0, 570.0]
const SMALL := 84.0
const BIG := 116.0
const HOLD_S := 1.1
const BLOOD := Color(0.86, 0.14, 0.12)

var _nodes := {}        # id -> Button
var _focus_id := ""
var _hold := 0.0
var _holding := ""
var _lines: Control
var _tok: Label
var _info: VBoxContainer
var _i_icon: TextureRect
var _i_title: Label
var _i_who: Label
var _i_line: Label
var _i_input: Label
var _i_state: Label
var _i_btns: HBoxContainer
var _t := 0.0


static func icon_of(id: String) -> Texture2D:
	var p := "res://assets/ui/brutal/%s.png" % id
	return load(p) if ResourceLoader.exists(p) else SpriteBook.icon("dojo")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(PixelStage.DESIGN)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.015, 0.96)
	dim.position = Vector2(-40, -40)
	dim.size = Vector2(PixelStage.DESIGN) + Vector2(80, 80)
	add_child(dim)
	var h := Label.new()
	h.text = "BONE YARD"
	UiKit.apply_label(h, 30, BLOOD)
	h.position = Vector2(48, 22)
	add_child(h)
	var sub := Label.new()
	sub.text = "Extreme finishers. The tree grows upwards: buy a move, then drill it 3 times on the dummy."
	UiKit.apply_label(sub, 13, Palette.MUTED)
	sub.position = Vector2(50, 64)
	add_child(sub)
	_tok = Label.new()
	UiKit.apply_label(_tok, 20, UiKit.GOLD)
	_tok.position = Vector2(930, 26)
	add_child(_tok)
	_lines = Control.new()
	_lines.size = Vector2(PixelStage.DESIGN)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.draw.connect(_draw_lines)
	add_child(_lines)
	for r in BrutalBook.all():
		_add_node(r)
	_build_info()
	var how := Label.new()
	how.text = "IN A FIGHT: beat a thug under half health, GRAB him (LIGHT + HEAVY). The stick picks the move: none, FORWARD or BACK.   SUPERS: fill FURY with kills, then BLOCK + SHOOT (LB + RB)."
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.size = Vector2(700, 40)
	how.position = Vector2(48, 676)
	UiKit.apply_label(how, 11, Palette.TEXT)
	add_child(how)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.position = Vector2(1092, 650)
	close.pressed.connect(_close)
	add_child(close)
	_refresh()
	var first: Button = _nodes.get(_first_open(), _nodes["arm_breaker"])
	first.grab_focus()
	first.set_meta("key", "bone_first")
	Guide.play(self, "boneyard_tree", [
		{"key": "bone_first", "who": "father", "voice": true, "text": "Hold A (or ENTER, or the mouse) on a lit node. It fills from the bottom, and when it is full the move is yours."},
		{"who": "son", "voice": true, "text": "Then the mat: three clean reps on the dojo dummy and it works in the street. A red ! means not drilled yet."},
	], 0.5)


func _first_open() -> String:
	for r in BrutalBook.all():
		if BrutalBook.blocker(str(r["id"])) == "":
			return str(r["id"])
	return "arm_breaker"


func _add_node(r: Dictionary) -> void:
	var id := str(r["id"])
	var big := bool(r.get("big", false))
	var s := BIG if big else SMALL
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(s, s)
	b.size = Vector2(s, s)
	b.position = Vector2(COL_X[int(r["col"])], ROW_Y[int(r["row"])]) - Vector2(s, s) * 0.5
	var clear := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, clear)
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = icon_of(id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = Color(1.0, 0.82, 0.3, 0.5)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(s, 0)
	fill.position = Vector2(0, s)
	b.add_child(fill)
	var cap := Label.new()
	cap.name = "Cap"
	cap.text = str(r["title"])
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.size = Vector2(170, 18)
	cap.position = Vector2(s * 0.5 - 85, s + 2)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_label(cap, 11, Palette.TEXT)
	b.add_child(cap)
	b.draw.connect(_draw_node.bind(b, id))
	b.focus_entered.connect(func() -> void:
		_focus_id = id
		_show(id)
	)
	b.mouse_entered.connect(b.grab_focus)
	b.button_down.connect(_press.bind(id))
	b.button_up.connect(_release.bind(id))
	add_child(b)
	_nodes[id] = b


func _draw_node(b: Button, id: String) -> void:
	var s := b.size
	var c := s * 0.5
	var own := BrutalBook.owned(id)
	if b.has_focus():
		var a := 0.55 + 0.35 * sin(_t * 6.0)
		b.draw_rect(Rect2(Vector2(-5, -5), s + Vector2(10, 10)), Color(1, 0.85, 0.35, a), false, 3.0)
	if _holding == id and _hold > 0.0:
		b.draw_arc(c, s.x * 0.62, -PI * 0.5, -PI * 0.5 + TAU * _hold, 40, UiKit.GOLD, 4.0)
	if own and not FamilyProfile.dojo_trained("b_" + id):
		b.draw_circle(Vector2(s.x - 6, 6), 9, BLOOD)
		b.draw_string(UiKit.pixel_font(), Vector2(s.x - 10, 11), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	elif own and BrutalBook.benched(id):
		b.draw_rect(Rect2(Vector2(0, s.y - 16), Vector2(s.x, 16)), Color(0, 0, 0, 0.7))
		b.draw_string(UiKit.pixel_font(), Vector2(6, s.y - 4), "BENCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Palette.MUTED)
	elif not own:
		var why := BrutalBook.blocker(id)
		if why != "" and not why.begins_with("NEED"):
			# Padlock.
			b.draw_rect(Rect2(c + Vector2(-9, -2), Vector2(18, 14)), Color(0.85, 0.85, 0.9))
			b.draw_arc(c + Vector2(0, -2), 6, PI, TAU, 12, Color(0.85, 0.85, 0.9), 3.0)


func _draw_lines() -> void:
	for r in BrutalBook.all():
		var id := str(r["id"])
		var b: Button = _nodes[id]
		var to := b.position + b.size * 0.5
		for n in r.get("needs", []):
			var pb: Button = _nodes.get(str(n))
			if pb == null:
				continue
			var from := pb.position + pb.size * 0.5
			var col := Color(0.25, 0.22, 0.26)
			var w := 3.0
			if BrutalBook.owned(id) and BrutalBook.owned(str(n)):
				col = UiKit.GOLD
				w = 5.0
			elif BrutalBook.owned(str(n)):
				col = Color(0.9, 0.86, 0.8, 0.55 + 0.25 * sin(_t * 4.0))
			_lines.draw_line(from + Vector2(0, -pb.size.y * 0.5), to + Vector2(0, b.size.y * 0.5 + 20), col, w)


func _build_info() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Color(0.08, 0.03, 0.04, 0.96), BLOOD))
	card.position = Vector2(760, 90)
	card.custom_minimum_size = Vector2(470, 540)
	add_child(card)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 10)
	card.add_child(_info)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_i_icon = TextureRect.new()
	_i_icon.custom_minimum_size = Vector2(110, 110)
	_i_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_i_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(_i_icon)
	var tv := VBoxContainer.new()
	_i_title = Label.new()
	_i_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_title.custom_minimum_size = Vector2(320, 0)
	UiKit.apply_label(_i_title, 22, Palette.TEXT)
	tv.add_child(_i_title)
	_i_who = Label.new()
	UiKit.apply_label(_i_who, 13, UiKit.GOLD)
	tv.add_child(_i_who)
	top.add_child(tv)
	_info.add_child(top)
	_i_line = Label.new()
	_i_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_line.custom_minimum_size = Vector2(440, 0)
	UiKit.apply_label(_i_line, 14, Palette.TEXT)
	_info.add_child(_i_line)
	_i_input = Label.new()
	_i_input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_input.custom_minimum_size = Vector2(440, 0)
	UiKit.apply_label(_i_input, 13, Color(0.6, 0.85, 1.0))
	_info.add_child(_i_input)
	_i_state = Label.new()
	_i_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_state.custom_minimum_size = Vector2(440, 0)
	UiKit.apply_label(_i_state, 15, UiKit.GOLD)
	_info.add_child(_i_state)
	_i_btns = HBoxContainer.new()
	_i_btns.add_theme_constant_override("separation", 10)
	_info.add_child(_i_btns)


func _show(id: String) -> void:
	var r := BrutalBook.row(id)
	_i_icon.texture = icon_of(id)
	_i_title.text = str(r.get("title", id))
	var map := str(r.get("map", ""))
	_i_who.text = "%s  ·  %s" % ["THE FATHER" if str(r.get("hero", "")) == "father" else "THE SON", "SUPER" if bool(r.get("big", false)) else "ROW %d" % (int(r.get("row", 0)) + 1)]
	if map != "":
		_i_who.text += "  ·  TOKENS FROM " + map.replace("_", " ").to_upper()
	_i_line.text = str(r.get("line", ""))
	_i_input.text = "HOW:  " + str(r.get("input", ""))
	for c in _i_btns.get_children():
		c.queue_free()
	if BrutalBook.owned(id):
		if not FamilyProfile.dojo_trained("b_" + id):
			var tr: Dictionary = FamilyProfile.data.get("dojo_train", {})
			_i_state.text = "BOUGHT  ·  DRILL IT ON THE DOJO DUMMY %d/%d" % [int(tr.get("b_" + id, 0)), FamilyProfile.TRAIN_REPS]
			_i_state.add_theme_color_override("font_color", BLOOD)
			var go := UiKit.button("TRAIN ON MAT", Vector2(200, 40))
			go.pressed.connect(_train.bind(str(r.get("hero", "father"))))
			_i_btns.add_child(go)
		else:
			_i_state.text = "LEARNED  ·  WORKS IN THE STREET"
			_i_state.add_theme_color_override("font_color", Palette.READY)
		if not BrutalBook.rivals(id).is_empty():
			if BrutalBook.benched(id):
				_i_state.text += "\nON THE BENCH: another move answers this grab."
				var act := UiKit.button("MAKE ACTIVE", Vector2(200, 40))
				act.pressed.connect(func() -> void:
					BrutalBook.make_active(id)
					Mixer.play_sfx("res://assets/audio/sfx/menu_confirm.ogg" if ResourceLoader.exists("res://assets/audio/sfx/menu_confirm.ogg") else "res://assets/audio/grab.wav", 1.2, -6.0)
					_refresh()
					_show(id)
				)
				_i_btns.add_child(act)
			else:
				_i_state.text += "\nACTIVE on this grab (%d on the bench)." % BrutalBook.rivals(id).size()
		return
	var why := BrutalBook.blocker(id)
	if why == "":
		_i_state.text = "HOLD  A / ENTER  TO UNLOCK  ·  %d FIGHT TOKEN%s" % [int(r.get("cost", 1)), "" if int(r.get("cost", 1)) == 1 else "S"]
		_i_state.add_theme_color_override("font_color", UiKit.GOLD)
	else:
		_i_state.text = why
		_i_state.add_theme_color_override("font_color", Palette.MUTED)


func _press(id: String) -> void:
	var why := BrutalBook.blocker(id)
	if why != "":
		if why != "OWNED":
			var b: Button = _nodes[id]
			var x0 := b.position.x
			var tw := b.create_tween()
			for k in 3:
				tw.tween_property(b, "position:x", x0 + 6.0, 0.03)
				tw.tween_property(b, "position:x", x0 - 6.0, 0.03)
			tw.tween_property(b, "position:x", x0, 0.03)
			Mixer.play_sfx("res://assets/audio/sfx/whiff_punch.ogg", 0.7, -8.0)
		return
	_holding = id
	_hold = 0.0


func _release(id: String) -> void:
	if _holding == id:
		_holding = ""


func _process(delta: float) -> void:
	_t += delta
	for id in _nodes:
		var b: Button = _nodes[id]
		var fill: ColorRect = b.get_node("Fill")
		if id == _holding:
			_hold = minf(1.0, _hold + delta / HOLD_S)
			if int(_hold * 10.0) != int((_hold - delta / HOLD_S) * 10.0):
				Mixer.play_sfx("res://assets/audio/hit_light.wav", 0.8 + _hold * 0.8, -12.0)
			if _hold >= 1.0:
				_buy(id)
		elif _holding == "" and _hold > 0.0 and id == _focus_id:
			_hold = maxf(0.0, _hold - delta * 3.0)
		var lv := _hold if (id == _holding or (id == _focus_id and _holding == "")) else 0.0
		fill.size = Vector2(b.size.x, b.size.y * lv)
		fill.position = Vector2(0, b.size.y * (1.0 - lv))
		b.queue_redraw()
	_lines.queue_redraw()


func _buy(id: String) -> void:
	_holding = ""
	_hold = 0.0
	if not BrutalBook.unlock(id):
		return
	var r := BrutalBook.row(id)
	var b: Button = _nodes[id]
	UiKit.blast(self, b.position + b.size * 0.5, BLOOD, 320.0)
	Juice.pulse_shake(6.0)
	Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", 1.0, 0.0)
	Juice.unlock_logo(str(r.get("title", id)), "Drill it 3 times on the dojo dummy and it works in the street.", "BONE YARD  ·  UNLOCKED", icon_of(id))
	_refresh()
	_show(id)


func _train(who: String) -> void:
	App.set_meta("dojo_role", who)
	_close()
	App.enter_map("dojo_practice")


func _refresh() -> void:
	_tok.text = "FIGHT TOKENS  %d" % BrutalBook.tokens()
	for id in _nodes:
		var b: Button = _nodes[id]
		var art: TextureRect = b.get_node("Art")
		var cap: Label = b.get_node("Cap")
		if BrutalBook.owned(id):
			art.modulate = Color.WHITE
			cap.add_theme_color_override("font_color", UiKit.GOLD)
		elif BrutalBook.blocker(id) == "":
			art.modulate = Color(0.85, 0.85, 0.85)
			cap.add_theme_color_override("font_color", Palette.TEXT)
		else:
			art.modulate = Color(0.28, 0.26, 0.3)
			cap.add_theme_color_override("font_color", Palette.MUTED)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
