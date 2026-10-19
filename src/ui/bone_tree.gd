extends Control

## The BONE YARD tree in the dojo, dressed like the BUILD trees (the dim
## room, the gold frame, pixel title, vines and leaves, pixel-art node icons)
## but growing the other way: the root at the bottom, three moves a row going
## up, the three supers on top in bigger nodes. Nodes are rounded squares.
## HOLD the button on a lit node to fill it from the bottom and pay the FIGHT
## TOKENS; bought moves are drilled 3 times on the dojo dummy before they
## work outside. When two owned moves answer the same grab, pick the active one.

signal closed

const COL_X := [250.0, 450.0, 650.0]
const ROW_Y := [626.0, 548.0, 470.0, 392.0, 314.0, 236.0, 140.0]
const SMALL := 62.0
const BIG := 86.0
const HOLD_S := 1.1
const BLOOD := Color(0.86, 0.16, 0.12)

var _nodes := {}        # id -> Button
var _focus_id := ""
var _hold := 0.0
var _holding := ""
var _vines: BoneVines
var _tok: Label
var _i_icon: TextureRect
var _i_title: Label
var _i_who: Label
var _i_line: Label
var _i_input: Label
var _i_state: Label
var _i_btns: HBoxContainer
var _t := 0.0


static func icon_of(id: String) -> Texture2D:
	var t := IconBook.tex("brutal_" + id)
	return t if t != null else SpriteBook.icon("dojo")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(PixelStage.DESIGN)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.97)
	dim.position = Vector2(-40, -40)
	dim.size = Vector2(PixelStage.DESIGN) + Vector2(80, 80)
	add_child(dim)
	if ResourceLoader.exists("res://assets/ui/clinic_room.png"):
		var room := TextureRect.new()
		room.texture = load("res://assets/ui/clinic_room.png")
		room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		room.texture_filter = SpriteBook.UI_FILTER
		room.position = Vector2(-16, -8)
		room.size = Vector2(1296, 736)
		room.modulate = Color(0.34, 0.24, 0.26)
		room.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(room)
	var well := TextureRect.new()
	well.texture = LightRig.radial_tex()
	well.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	well.position = Vector2(60, 60)
	well.size = Vector2(780, 660)
	well.modulate = Color(0.0, 0.0, 0.02, 0.8)
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(well)
	var frame := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.border_color = UiKit.RIM
	fs.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", fs)
	frame.position = Vector2(8, 8)
	frame.size = Vector2(1264, 704)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var title := UiKit.title("BONE YARD", 54, BLOOD)
	title.position = Vector2(150, 14)
	title.size = Vector2(600, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	for x in [214.0, 622.0]:
		var orn := ColorRect.new()
		orn.color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.7)
		orn.position = Vector2(x, 46)
		orn.size = Vector2(64, 3)
		orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(orn)
	var sub := Label.new()
	sub.text = "GROWS UPWARD  ·  HOLD TO BUY  ·  DRILL 3x ON THE MAT"
	sub.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(sub, 12, Palette.MUTED)
	sub.position = Vector2(150, 78)
	sub.size = Vector2(600, 18)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	var dojo := UiKit.portrait(SpriteBook.icon("dojo"), Vector2(56, 56))
	dojo.position = Vector2(24, 18)
	add_child(dojo)
	_tok = Label.new()
	_tok.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_tok, 15, UiKit.GOLD)
	_tok.position = Vector2(960, 34)
	_tok.size = Vector2(290, 20)
	_tok.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_tok)
	_vines = BoneVines.new()
	_vines.size = Vector2(PixelStage.DESIGN)
	_vines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vines)
	for r in BrutalBook.all():
		_add_node(r)
	_build_info()
	var close := UiKit.button("CLOSE", Vector2(150, 40))
	close.position = Vector2(1100, 660)
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


func _pos(r: Dictionary) -> Vector2:
	return Vector2(COL_X[int(r["col"])], ROW_Y[mini(int(r["row"]), ROW_Y.size() - 1)])


func _add_node(r: Dictionary) -> void:
	var id := str(r["id"])
	var big := bool(r.get("big", false))
	var s := BIG if big else SMALL
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(s, s)
	b.size = Vector2(s, s)
	b.position = _pos(r) - Vector2(s, s) * 0.5
	b.clip_contents = true
	b.set_meta("key", "bone_" + id)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.55)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(s, 0)
	fill.position = Vector2(0, s)
	b.add_child(fill)
	var pic := TextureRect.new()
	pic.name = "Art"
	pic.texture = icon_of(id)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 32 texels at whole multiples: crisp pixel art like every other tree.
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ps := IconBook.SIZE_M if big else IconBook.SIZE_S
	pic.size = Vector2(ps, ps)
	pic.position = Vector2(s, s) * 0.5 - pic.size * 0.5
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var cap := Label.new()
	cap.name = "Cap"
	cap.text = str(r["title"])
	cap.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(cap, 11, Palette.TEXT)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.size = Vector2(190, 14)
	cap.position = _pos(r) + Vector2(-95, s * 0.5 + 1)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)
	b.set_meta("cap", cap)
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


## Rounded-square frames in the BUILD trees' colours, by state.
func _dress(b: Button, id: String) -> void:
	var st := _state(id)
	var big := bool(BrutalBook.row(id).get("big", false))
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(18 if big else 14)
	box.set_border_width_all(4)
	box.bg_color = Color(0.05, 0.06, 0.1, 0.96)
	box.anti_aliasing = false
	match st:
		"owned":
			box.border_color = UiKit.GOLD
			box.bg_color = Color(0.32, 0.12, 0.08)
			box.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.5)
			box.shadow_size = 8
		"can":
			box.border_color = UiKit.GOLD
			box.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.75)
			box.shadow_size = 16
		"poor":
			box.border_color = UiKit.RIM
		_:
			box.border_color = Color(0.3, 0.28, 0.3)
	if big and st != "owned":
		box.border_color = box.border_color.lerp(BLOOD, 0.5)
	var hover := box.duplicate() as StyleBoxFlat
	hover.border_color = Color.WHITE.lerp(UiKit.GOLD, 0.4)
	hover.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.8)
	hover.shadow_size = 18
	var foc := hover.duplicate() as StyleBoxFlat
	foc.shadow_size = 6
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", foc)
	b.add_theme_stylebox_override("pressed", hover)
	var pic: TextureRect = b.get_node("Art")
	var cap: Label = b.get_meta("cap")
	match st:
		"owned":
			pic.modulate = Color.WHITE
			cap.add_theme_color_override("font_color", UiKit.GOLD)
		"can":
			pic.modulate = Color.WHITE
			cap.add_theme_color_override("font_color", Palette.TEXT)
		"poor":
			pic.modulate = Color(0.75, 0.75, 0.8)
			cap.add_theme_color_override("font_color", Palette.TEXT)
		_:
			pic.modulate = Color(0.35, 0.35, 0.4)
			cap.add_theme_color_override("font_color", Palette.MUTED)


## owned | can (buy now) | poor (unlocked, short of tokens) | locked
func _state(id: String) -> String:
	if BrutalBook.owned(id):
		return "owned"
	var why := BrutalBook.blocker(id)
	if why == "":
		return "can"
	return "poor" if why.begins_with("NEED") else "locked"


func _draw_node(b: Button, id: String) -> void:
	var s := b.size
	var c := s * 0.5
	if _holding == id and _hold > 0.0:
		b.draw_arc(c, s.x * 0.45, -PI * 0.5, -PI * 0.5 + TAU * _hold, 32, Color.WHITE, 3.0)
	if BrutalBook.owned(id) and not FamilyProfile.dojo_trained("b_" + id):
		b.draw_rect(Rect2(Vector2(s.x - 16, 2), Vector2(14, 14)), BLOOD)
		b.draw_string(UiKit.pixel_font(), Vector2(s.x - 12, 14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	elif BrutalBook.owned(id) and BrutalBook.benched(id):
		b.draw_rect(Rect2(Vector2(0, s.y - 16), Vector2(s.x, 16)), Color(0, 0, 0, 0.75))
		b.draw_string(UiKit.pixel_font(), Vector2(6, s.y - 4), "BENCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Palette.MUTED)
	elif _state(id) == "locked":
		# A small pixel padlock in the corner.
		var p := Vector2(s.x - 16, 4)
		b.draw_rect(Rect2(p + Vector2(0, 5), Vector2(12, 8)), Color(0.78, 0.78, 0.84))
		b.draw_rect(Rect2(p + Vector2(2, 0), Vector2(2, 6)), Color(0.78, 0.78, 0.84))
		b.draw_rect(Rect2(p + Vector2(8, 0), Vector2(2, 6)), Color(0.78, 0.78, 0.84))
		b.draw_rect(Rect2(p + Vector2(2, 0), Vector2(8, 2)), Color(0.78, 0.78, 0.84))
		b.draw_rect(Rect2(p + Vector2(5, 8), Vector2(2, 3)), Color(0.2, 0.2, 0.26))


func _build_info() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Color(0.07, 0.05, 0.08, 0.96), UiKit.RIM))
	card.position = Vector2(860, 110)
	card.custom_minimum_size = Vector2(390, 530)
	add_child(card)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	card.add_child(info)
	_i_icon = TextureRect.new()
	_i_icon.custom_minimum_size = Vector2(128, 128)
	_i_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_i_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_i_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_i_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info.add_child(_i_icon)
	_i_title = Label.new()
	_i_title.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_i_title, 18, UiKit.GOLD)
	_i_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_i_title)
	_i_who = Label.new()
	_i_who.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_i_who, 11, Palette.MUTED)
	_i_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_i_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_who.custom_minimum_size = Vector2(370, 0)
	info.add_child(_i_who)
	_i_line = Label.new()
	_i_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_line.custom_minimum_size = Vector2(370, 0)
	UiKit.apply_label(_i_line, 13, Palette.TEXT)
	info.add_child(_i_line)
	_i_input = Label.new()
	_i_input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_input.custom_minimum_size = Vector2(370, 0)
	_i_input.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_i_input, 12, Color(0.6, 0.85, 1.0))
	info.add_child(_i_input)
	_i_state = Label.new()
	_i_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_i_state.custom_minimum_size = Vector2(370, 0)
	_i_state.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_i_state, 13, UiKit.GOLD)
	info.add_child(_i_state)
	_i_btns = HBoxContainer.new()
	_i_btns.add_theme_constant_override("separation", 10)
	info.add_child(_i_btns)
	var how := Label.new()
	how.text = "IN A FIGHT: beat a thug under half health and GRAB him (LIGHT + HEAVY); the stick picks the move. SUPERS: fill FURY, then BLOCK + SHOOT (LB + RB)."
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(370, 0)
	UiKit.apply_label(how, 11, Palette.MUTED)
	info.add_child(how)


func _show(id: String) -> void:
	var r := BrutalBook.row(id)
	_i_icon.texture = icon_of(id)
	_i_title.text = str(r.get("title", id))
	var map := str(r.get("map", ""))
	var map_t := str(BoneYard.map(map).get("title", map.replace("_", " ").to_upper()))
	_i_who.text = "%s  ·  %s" % ["THE FATHER" if str(r.get("hero", "")) == "father" else "THE SON", "SUPER" if bool(r.get("big", false)) else "ROW %d" % (int(r.get("row", 0)) + 1)]
	if map != "":
		_i_who.text += "  ·  " + map_t
	_i_line.text = str(r.get("line", ""))
	_i_input.text = "HOW: " + str(r.get("input", ""))
	for c in _i_btns.get_children():
		c.queue_free()
	if BrutalBook.owned(id):
		if not FamilyProfile.dojo_trained("b_" + id):
			var tr: Dictionary = FamilyProfile.data.get("dojo_train", {})
			_i_state.text = "BOUGHT  ·  DRILL ON THE DOJO DUMMY %d/%d" % [int(tr.get("b_" + id, 0)), FamilyProfile.TRAIN_REPS]
			_i_state.add_theme_color_override("font_color", BLOOD)
			var go := UiKit.button("TRAIN ON MAT", Vector2(190, 36))
			go.pressed.connect(_train.bind(str(r.get("hero", "father"))))
			_i_btns.add_child(go)
		else:
			_i_state.text = "LEARNED  ·  WORKS IN THE STREET"
			_i_state.add_theme_color_override("font_color", Palette.READY)
		if not BrutalBook.rivals(id).is_empty():
			if BrutalBook.benched(id):
				_i_state.text += "\nON THE BENCH: another move answers this grab."
				var act := UiKit.button("MAKE ACTIVE", Vector2(190, 36))
				act.pressed.connect(func() -> void:
					BrutalBook.make_active(id)
					Juice.play("res://assets/audio/ui_click.wav")
					_refresh()
					_show(id)
				)
				_i_btns.add_child(act)
			else:
				_i_state.text += "\nACTIVE on this grab (%d on the bench)." % BrutalBook.rivals(id).size()
		return
	var why := BrutalBook.blocker(id)
	if why == "":
		_i_state.text = "HOLD A / ENTER TO UNLOCK  ·  %d FIGHT TOKEN%s" % [int(r.get("cost", 1)), "" if int(r.get("cost", 1)) == 1 else "S"]
		_i_state.add_theme_color_override("font_color", UiKit.GOLD)
	else:
		_i_state.text = why
		_i_state.add_theme_color_override("font_color", Color(0.95, 0.25, 0.22) if why.begins_with("NEED") else Palette.MUTED)


func _press(id: String) -> void:
	var why := BrutalBook.blocker(id)
	if why != "":
		if why != "OWNED":
			var b: Button = _nodes[id]
			var x0 := b.position.x
			var tw := b.create_tween()
			for k in 3:
				tw.tween_property(b, "position:x", x0 + 5.0, 0.03)
				tw.tween_property(b, "position:x", x0 - 5.0, 0.03)
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
			var before := _hold
			_hold = minf(1.0, _hold + delta / HOLD_S)
			if int(_hold * 8.0) != int(before * 8.0):
				Mixer.play_sfx("res://assets/audio/hit_light.wav", 0.8 + _hold * 0.8, -12.0)
			if _hold >= 1.0:
				_buy(id)
		elif _holding == "" and _hold > 0.0 and id == _focus_id:
			_hold = maxf(0.0, _hold - delta * 3.0)
		var lv := _hold if (id == _holding or (id == _focus_id and _holding == "")) else 0.0
		# Filled in whole 4-px steps, like a pixel meter.
		var h := floorf(b.size.y * lv / 4.0) * 4.0
		fill.size = Vector2(b.size.x, h)
		fill.position = Vector2(0, b.size.y - h)
		b.queue_redraw()
	_vines.t = _t
	_vines.queue_redraw()


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
	_tok.text = "FIGHT TOKENS %d" % BrutalBook.tokens()
	var links: Array = []
	for r in BrutalBook.all():
		var id := str(r["id"])
		_dress(_nodes[id], id)
		for n in r.get("needs", []):
			if _nodes.has(str(n)):
				links.append([_pos(BrutalBook.row(str(n))), _pos(r), BrutalBook.owned(id) and BrutalBook.owned(str(n)), BrutalBook.owned(str(n))])
	_vines.links = links
	_vines.root = _pos(BrutalBook.row("arm_breaker"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


## The BUILD trees' vines turned upside down: a trunk out of the floor into
## the root, then a vine with leaves up from each move to the ones it opens.
## Lit gold where both ends are owned; a red pulse where the next is buyable.
class BoneVines extends Control:
	var links: Array = []
	var root := Vector2.ZERO
	var t := 0.0

	func _draw() -> void:
		var bark := Color(0.33, 0.22, 0.12)
		var bark_lit := Color(0.5, 0.36, 0.2)
		var leaf := Color(0.42, 0.12, 0.1)
		if root != Vector2.ZERO:
			draw_line(root + Vector2(0, 30), Vector2(root.x, 708), bark, 12.0)
			draw_line(root + Vector2(-3, 30), Vector2(root.x - 3, 708), bark_lit, 3.0)
		for l: Array in links:
			var a: Vector2 = l[0]
			var b: Vector2 = l[1]
			var lit: bool = l[2]
			var open: bool = l[3]
			var mid := Vector2(a.x, (a.y + b.y) * 0.5)
			var pts := PackedVector2Array()
			for i in 13:
				var k := float(i) / 12.0
				pts.append(a.lerp(mid, k).lerp(mid.lerp(b, k), k))
			draw_polyline(pts, bark, 7.0)
			var top := Color(0.9, 0.7, 0.3, 0.85) if lit else (Color(0.9, 0.25, 0.2, 0.45 + 0.35 * sin(t * 4.0)) if open else bark_lit)
			draw_polyline(pts, top, 2.0)
			for i in [3, 7, 10]:
				var p: Vector2 = pts[i]
				var side := 7.0 if i % 2 == 0 else -7.0
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(side, -4), p + Vector2(side * 1.6, 1), p + Vector2(side, 4)]), leaf)
