extends CanvasLayer

## The coping hour's pick screen. Modes:
##   level  - three offers (new / level-up abilities, traits); REROLL x2, BANISH x1
##   item   - an elite's chest: one of three items
##   stash  - the Lost & Found well at the start: carry one kept item in
##   well   - clearing the hour: keep one of this run's items for later
## The game is paused while it is open.

signal closed

var run: SurviveRun
var mode := "level"
var item_rows: Array = []
var _root: Control
var _row: HBoxContainer
var _offers: Array = []
var _banish := false
var _info: Label

const RARITY_COL := {"common": Color(0.75, 0.78, 0.82), "uncommon": Color(0.4, 0.9, 0.5), "rare": Color(0.4, 0.7, 1.0), "epic": Color(0.8, 0.45, 1.0), "legendary": Color(1.0, 0.75, 0.25)}


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_root = PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.04, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var title: String = {"level": "LEVEL %d" % run.level, "item": "ELITE CHEST", "stash": "LOST & FOUND", "well": "THE WELL", "evolve": "EVOLUTION"}.get(mode, "PICK ONE")
	var sub: String = {"evolve": "LV 7 and its partner item: it grows into something worse.", "level": "Pick one. The rest goes back in the drawer.", "item": "The elite dropped something. Take one.", "stash": "Things you kept from other hours. Take one in with you.", "well": "Drop one item down the well: it waits for you in the next hour."}.get(mode, "")
	var t := UiKit.title(str(title), 44, Palette.LEMON)
	t.position = Vector2(0, 92)
	t.size = Vector2(1280, 56)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 8)
	_root.add_child(t)
	t.pivot_offset = Vector2(640, 28)
	t.scale = Vector2(1.8, 1.8)
	var ttw := t.create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ttw.tween_property(t, "scale", Vector2.ONE, 0.28)
	ttw.tween_callback(func() -> void:
		UiKit.blast(_root, Vector2(640, 120), Palette.LEMON if mode == "level" else Color(1.0, 0.56, 0.12), 280.0)
	)
	var s := Label.new()
	s.text = str(sub)
	s.position = Vector2(0, 150)
	s.size = Vector2(1280, 24)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(s, 15, Palette.MUTED)
	_root.add_child(s)
	_row = HBoxContainer.new()
	_row.position = Vector2(120, 196)
	_row.add_theme_constant_override("separation", 26)
	_root.add_child(_row)
	_info = Label.new()
	_info.position = Vector2(0, 580)
	_info.size = Vector2(1280, 24)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_info, 13, Palette.MUTED)
	_root.add_child(_info)
	if mode == "level":
		_offers = run.offers(3)
		var tools := HBoxContainer.new()
		tools.position = Vector2(430, 520)
		tools.add_theme_constant_override("separation", 20)
		_root.add_child(tools)
		var rr := UiKit.button("REROLL (%d)" % run.rerolls, Vector2(200, 44))
		rr.disabled = run.rerolls <= 0
		rr.pressed.connect(func() -> void:
			if run.rerolls <= 0:
				return
			run.rerolls -= 1
			rr.text = "REROLL (%d)" % run.rerolls
			rr.disabled = run.rerolls <= 0
			_offers = run.offers(3)
			_fill()
		)
		tools.add_child(rr)
		var bn := UiKit.button("BANISH (%d)" % run.banishes, Vector2(200, 44))
		bn.disabled = run.banishes <= 0
		bn.pressed.connect(func() -> void:
			_banish = not _banish
			_info.text = "Pick a card to banish it for the rest of the hour." if _banish else ""
		)
		tools.add_child(bn)
	elif mode == "evolve":
		for r in item_rows:
			_offers.append(r)
	else:
		for r in item_rows:
			_offers.append({"kind": "item", "id": str(r.get("id", "")), "row": r})
		if mode == "stash" or mode == "well":
			var skip := UiKit.button("NONE", Vector2(200, 44))
			skip.position = Vector2(540, 520)
			skip.pressed.connect(_close)
			_root.add_child(skip)
	_fill()
	Mixer.play_sfx("res://assets/audio/card.wav", 1.0, -3.0)


func _fill() -> void:
	for c in _row.get_children():
		c.queue_free()
	var first: Button = null
	for i in _offers.size():
		var b := _card(_offers[i])
		_row.add_child(b)
		if first == null:
			first = b
		# Deal the cards in: drop and settle, one after another.
		var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		b.modulate.a = 0.0
		b.pivot_offset = Vector2(160, 150)
		b.scale = Vector2(0.85, 0.85)
		tw.tween_interval(0.07 * i)
		tw.tween_property(b, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(b, "scale", Vector2.ONE, 0.22)
		b.focus_entered.connect(func() -> void:
			b.create_tween().tween_property(b, "scale", Vector2(1.04, 1.04), 0.08)
			Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.4, -14.0)
		)
		b.focus_exited.connect(func() -> void:
			b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08)
		)
	var n := _offers.size()
	_row.position.x = (1280.0 - (float(n) * 320.0 + float(maxi(0, n - 1)) * 26.0)) * 0.5
	if first:
		first.call_deferred("grab_focus")


func _card(o: Dictionary) -> Button:
	var kind := str(o.get("kind", ""))
	var r: Dictionary = {}
	var lv_text := ""
	var col := Palette.EDGE
	match kind:
		"ability":
			r = run.row("abilities", str(o["id"]))
			var cur := int(run.abilities.get(str(o["id"]), 0))
			lv_text = "NEW ABILITY" if cur == 0 else "LV %d  ›  %d" % [cur, cur + 1]
			col = Color(1.0, 0.8, 0.3) if cur == 0 else Color(0.5, 0.85, 1.0)
		"trait":
			r = run.row("traits", str(o["id"]))
			var n := run.trait_n(str(o["id"]))
			lv_text = "TRAIT  %d/%d" % [n + 1, int(r.get("max", 5))]
			col = Color(0.55, 1.0, 0.6)
		"item":
			r = o["row"]
			lv_text = str(r.get("rarity", "common")).to_upper() + " ITEM"
			col = RARITY_COL.get(str(r.get("rarity", "common")), Palette.EDGE)
		"evolve":
			r = o
			lv_text = "EVOLVE  ·  " + str(run.row("abilities", str(o["id"])).get("name", "")).to_upper()
			col = Color(1.0, 0.56, 0.12)
		_:
			r = {"name": "10 GOLD", "blurb": "Nothing left to learn. Have some money.", "icon": "i_coin"}
			lv_text = "CONSOLATION"
	var b := Button.new()
	b.custom_minimum_size = Vector2(320, 300)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL, col.darkened(0.3)))
	b.add_theme_stylebox_override("hover", UiKit.panel(Palette.PANEL, col))
	b.add_theme_stylebox_override("focus", UiKit.panel(Palette.PANEL, col))
	b.add_theme_stylebox_override("pressed", UiKit.panel(Palette.PANEL, col))
	var v := VBoxContainer.new()
	v.position = Vector2(16, 16)
	v.size = Vector2(288, 270)
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var tag := Label.new()
	tag.text = lv_text
	UiKit.apply_label(tag, 13, col)
	v.add_child(tag)
	var ic := UiKit.portrait(SurviveIcons.tex(str(r.get("icon", ""))), Vector2(96, 96))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(ic)
	var n2 := Label.new()
	n2.text = str(r.get("name", "?"))
	n2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n2.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(n2, 20, col.lerp(Color.WHITE, 0.15))
	v.add_child(n2)
	var bl := UiKit.rich(str(r.get("blurb", "")), 288, 13, Palette.TEXT)
	v.add_child(bl)
	if kind == "ability":
		var lv := int(run.abilities.get(str(o["id"]), 0))
		var dmg := float(r.get("dmg", 0)) + float(r.get("per", 0)) * float(maxi(0, lv))
		var txt := "DMG %d  ·  EVERY %.1fs" % [int(dmg), float(r.get("cd", 1.0))]
		if lv > 0:
			txt = "DMG %d › [color=%s]%d (+%d)[/color]  ·  EVERY %.1fs" % [int(dmg - float(r.get("per", 0))), UiKit.UP_COL, int(dmg), int(r.get("per", 0)), float(r.get("cd", 1.0))]
		var st := UiKit.rich("", 288, 12, col)
		st.text = "[center]" + txt + "[/center]"
		v.add_child(st)
	if kind == "ability" and int(run.abilities.get(str(o["id"]), 0)) > 0:
		var pips := HBoxContainer.new()
		pips.alignment = BoxContainer.ALIGNMENT_CENTER
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cur2 := int(run.abilities.get(str(o["id"]), 0))
		for k in SurviveRun.MAX_LV:
			var p := ColorRect.new()
			p.custom_minimum_size = Vector2(22, 8)
			p.color = col if k < cur2 else (Color(1, 1, 1, 0.9) if k == cur2 else Color(1, 1, 1, 0.12))
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(p)
		v.add_child(pips)
	Bevel.dress(b)
	UiKit.press_feel(b)
	b.pressed.connect(_pick.bind(o))
	return b


func _pick(o: Dictionary) -> void:
	if _banish and mode == "level":
		_banish = false
		run.banishes -= 1
		run.banned.append(str(o.get("id", "")))
		_offers = run.offers(3)
		_info.text = "Banished."
		_fill()
		return
	match mode:
		"well":
			run.keep(o["row"])
			Juice.toast("reward", "INTO THE WELL", "%s waits for you in the next hour." % str((o["row"] as Dictionary).get("name", "")))
		_:
			run.take(o)
	Mixer.play_sfx("res://assets/audio/ui_click.wav")
	_close()


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
