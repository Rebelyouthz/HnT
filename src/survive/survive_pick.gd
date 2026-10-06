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
		_offers = run.offers(4 if Trees.has("s_four") else 3)
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
			_offers = run.offers(4 if Trees.has("s_four") else 3)
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
			r = {"name": "LIMIT BREAK", "blurb": "Nothing left to learn: +5% damage to everything, stacking.", "icon": "i_coin"}
			lv_text = "LIMIT BREAK  %d" % (run.limit_breaks + 1)
	# What it is (PASSIVE / AUTOWEAPON / COMPANION / ACTIVE) and its rarity.
	var kd := "PASSIVE"
	var rar := str(r.get("rarity", ""))
	match kind:
		"ability":
			var aid := str(o["id"])
			kd = "COMPANION" if (aid.contains("drone") or aid.contains("dog") or aid.contains("intern") or aid.contains("cart") or aid.contains("pet")) else ("MANUALWEAPON" if r.has("manual") else "AUTOWEAPON")
			if rar == "":
				rar = "rare"
		"evolve":
			kd = "AUTOWEAPON"
			rar = "legendary"
		"trait":
			if rar == "":
				rar = "uncommon"
		"item":
			kd = "ACTIVE" if r.has("active") else "PASSIVE"
	if rar == "":
		rar = "common"
	rar = Rarity.normalize(rar)
	var rc := Rarity.color(rar)
	# The survivor card is its own object: a steel ID badge sprite
	# (tools/card_art.py) with the rarity's enamel header. The hit box stays
	# put; the badge inside rises and glows when focused.
	var b := Button.new()
	b.custom_minimum_size = Vector2(320, 326)
	b.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for st_name in ["normal", "hover", "focus", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st_name, empty)
	var body := Control.new()
	body.name = "Body"
	body.size = Vector2(320, 326)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_child(body)
	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.texture = load("res://assets/sprites/cards/glow_surv.png")
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.position = Vector2(-16, -16)
	glow.size = Vector2(352, 358)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = add
	glow.modulate = Color(rc.r * 1.8, rc.g * 1.8, rc.b * 1.8, 1.0)
	glow.visible = false
	body.add_child(glow)
	var frame := TextureRect.new()
	frame.texture = load("res://assets/sprites/cards/surv_%s.png" % rar)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.size = Vector2(320, 326)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(frame)
	var kinfo: Array = PixelCard.KINDS[kd]
	var kic := IconBook.rect(IconBook.for_glyph(str(kinfo[1])), 24)
	kic.position = Vector2(14, 14)
	body.add_child(kic)
	body.add_child(_lab(str(kinfo[0]), Vector2(40, 16), 100, 10, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	body.add_child(_lab(Rarity.label(rar), Vector2(196, 16), 110, 10, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
	var icn := str(r.get("icon", ""))
	var ic := IconBook.rect(icn if IconBook.has(icn) else "node_score", IconBook.SIZE_M)
	ic.position = Vector2(128, 74)
	ic.name = "Art"
	body.add_child(ic)
	var n2 := _lab(str(r.get("name", "?")), Vector2(20, 172), 280, 18, col.lerp(Color.WHITE, 0.2), HORIZONTAL_ALIGNMENT_CENTER, true)
	body.add_child(n2)
	body.add_child(_lab(lv_text, Vector2(20, 198), 280, 11, col, HORIZONTAL_ALIGNMENT_CENTER))
	var bl := UiKit.rich(str(r.get("blurb", "")), 268, 12, Palette.TEXT)
	bl.position = Vector2(26, 218)
	if kind == "trait":
		# Total now -> total with this stack, white then green.
		var re := RegEx.new()
		re.compile("([+-]?\\d+(?:\\.\\d+)?)%")
		var m := re.search(str(r.get("blurb", "")))
		if m:
			var per := float(m.get_string(1))
			var have := run.trait_n(str(o["id"]))
			var tl := UiKit.rich("", 268, 12, Palette.TEXT)
			tl.text = "[center]TOTAL  %s[/center]" % UiKit.delta_bb(per * float(have), per * float(have + 1), "%+d%%")
			tl.position = Vector2(26, 262)
			tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(tl)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(bl)
	if kind == "ability":
		var lv := int(run.abilities.get(str(o["id"]), 0))
		var dmg := float(r.get("dmg", 0)) + float(r.get("per", 0)) * float(maxi(0, lv))
		var cd := float(r.get("cd", 1.0))
		var when := ("EVERY %.1fs" % cd) if cd > 0.05 else "ALWAYS ON"
		var txt := "DMG [color=%s]%d[/color]  ·  %s" % [UiKit.BASE_COL, int(dmg), when]
		if lv > 0:
			txt = "DMG %s  ·  %s" % [UiKit.delta_bb(dmg - float(r.get("per", 0)), dmg, "%d"), when]
		var st := UiKit.rich("", 268, 11, col)
		st.text = "[center]" + txt + "[/center]"
		st.position = Vector2(26, 262)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(st)
		if lv > 0:
			for k in SurviveRun.MAX_LV:
				var pip := ColorRect.new()
				pip.size = Vector2(20, 6)
				pip.position = Vector2(160.0 - float(SurviveRun.MAX_LV) * 12.0 + float(k) * 24.0, 282)
				pip.color = col if k < lv else (Color(1, 1, 1, 0.9) if k == lv else Color(1, 1, 1, 0.12))
				pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
				body.add_child(pip)
	b.focus_entered.connect(func() -> void: _lift(b, true))
	b.focus_exited.connect(func() -> void: _lift(b, false))
	b.mouse_entered.connect(func() -> void: b.grab_focus())
	UiKit.press_feel(b)
	b.pressed.connect(_pick.bind(o))
	return b


func _lab(t: String, pos: Vector2, w: float, fs: int, c: Color, align: HorizontalAlignment, title := false) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(w, 0)
	l.horizontal_alignment = align
	l.clip_text = true
	l.add_theme_font_override("font", UiKit.title_font() if title else UiKit.pixel_font())
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", UiKit.INK)
	l.add_theme_constant_override("outline_size", 5 if title else 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Focused badge rises and glows in its rarity colour; the art bobs.
func _lift(b: Button, on: bool) -> void:
	var body: Control = b.get_node_or_null("Body")
	if body == null:
		return
	var tw := body.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "position:y", -20.0 if on else 0.0, 0.16)
	var g: Control = body.get_node_or_null("Glow")
	if g:
		g.visible = on
		if on:
			var gt := g.create_tween().set_loops()
			gt.tween_property(g, "modulate:a", 0.55, 0.35)
			gt.tween_property(g, "modulate:a", 1.0, 0.35)
			g.set_meta("tw", gt)
		elif g.has_meta("tw"):
			(g.get_meta("tw") as Tween).kill()
	body.modulate = Color.WHITE if on else Color(0.82, 0.82, 0.88)
	if on:
		Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.4, -14.0)


func _pick(o: Dictionary) -> void:
	if _banish and mode == "level":
		_banish = false
		run.banishes -= 1
		run.banned.append(str(o.get("id", "")))
		_offers = run.offers(4 if Trees.has("s_four") else 3)
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
