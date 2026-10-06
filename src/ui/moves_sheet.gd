extends Control

## MOVES: build your own fighting style.
##   LOADOUT    every move slot, cycle the learned strikes that fit it
##   LIBRARY    every strike: learn it (gold), see weight, slots, type
##   COMBO LAB  make up to six combos: 2-4 inputs + a finisher + effect
##   STYLES     three saved loadouts per hero
##   ELEMENTS   element arts (unlock, level 1-5, evolve), grabs, team attacks

signal closed
signal need_refresh

var role := "son"
var _page := "loadout"
var _steps: Array = []
var _fin := 0
var _fx := 0
var _focus_key := ""


func _ready() -> void:
	_paint()


func _paint() -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.BRICK, 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -610
	card.offset_right = 610
	card.offset_top = -345
	card.offset_bottom = 345
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var t := UiKit.title("MOVES", 30, Palette.BRICK)
	t.custom_minimum_size = Vector2(150, 0)
	head.add_child(t)
	for r in ["son", "father"]:
		var rb := _btn((FamilyProfile.son_name() if r == "son" else FamilyProfile.father_name()).to_upper(), Vector2(120, 36), "role_" + r, r == role)
		rb.pressed.connect(func() -> void:
			role = r
			_steps.clear()
			_focus_key = "role_" + r
			_paint()
		)
		head.add_child(rb)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	for pair in [["loadout", "LOADOUT"], ["library", "LIBRARY"], ["lab", "COMBO LAB"], ["styles", "STYLES"], ["elements", "ELEMENTS"]]:
		var b := _btn(pair[1], Vector2(130, 36), "page_" + pair[0], pair[0] == _page)
		b.pressed.connect(func() -> void:
			_page = pair[0]
			_focus_key = "page_" + pair[0]
			_paint()
		)
		head.add_child(b)
	var close := _btn("CLOSE", Vector2(100, 36), "close", false)
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	col.add_child(head)
	var sub := Label.new()
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(1160, 0)
	UiKit.apply_label(sub, 13, Palette.MUTED)
	col.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	sc.add_child(body)
	match _page:
		"loadout":
			sub.text = "Put any learned strike in any slot it fits. Heavier moves hit harder but come out slower and leave you open longer. GOLD %d" % int(FamilyProfile.data.get("gold", 0))
			_loadout(body)
		"library":
			sub.text = "Every strike this hero can learn. Learn with gold here, or in a dojo lesson. GOLD %d" % int(FamilyProfile.data.get("gold", 0))
			_library(body)
		"lab":
			sub.text = "Make your own combo: tap 2-4 inputs, pick the finisher and what it does to them. It fires like any dojo combo (timing ring, PERFECT)."
			_lab(body)
		"elements":
			sub.text = "LIGHT + HEAVY together fires an element art (the stick picks which) and costs CHI: hits and kills fill the ring under your feet. Next to a thug the same buttons GRAB. When the gold TEAM ring is full, hold HEAVY and tap SPECIAL.  GOLD %d  ·  GEMS %d" % [int(FamilyProfile.data.get("gold", 0)), int(FamilyProfile.data.get("gems", 0))]
			_elements(body)
		_:
			sub.text = "Save the current loadout as a style and switch any time: a boxer, a kicker, a brawler."
			_styles(body)
	UiKit.pop_in(card)
	var want := _focus_key
	get_tree().process_frame.connect(func() -> void:
		for b in _all_buttons(self):
			if str(b.get_meta("key", "")) == want and not b.disabled:
				b.grab_focus()
				return
		if is_instance_valid(close):
			close.grab_focus()
	, CONNECT_ONE_SHOT)


func _all_buttons(n: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out


func _btn(txt: String, sz: Vector2, key: String, on: bool) -> Button:
	var b := UiKit.button(txt, sz)
	b.add_theme_font_size_override("font_size", 12)
	b.set_meta("key", key)
	if on:
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	return b


func _icon(clip: String, sz := Vector2(64, 64)) -> TextureRect:
	var ic := UiKit.portrait(SpriteBook.move_icon(role, clip), sz)
	ic.custom_minimum_size = sz
	return ic


func _row_panel(col: Color) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.06, 0.07, 0.12), col))
	Bevel.dress(p, false, 0.6)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	return [p, h]


func _loadout(body: VBoxContainer) -> void:
	var lo := Moves.loadout(role)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for slot: String in Moves.SLOTS:
		var id := str(lo[slot])
		var r := Moves.row(id)
		var pr := _row_panel(Palette.BRICK if id != str(Moves.DEFAULT[slot]) else Palette.MUTED)
		var p: PanelContainer = pr[0]
		var h: HBoxContainer = pr[1]
		p.custom_minimum_size = Vector2(570, 84)
		h.add_child(_icon(id))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sl := Label.new()
		sl.text = str(Moves.SLOT_NAME[slot])
		UiKit.apply_label(sl, 11, Palette.MUTED)
		v.add_child(sl)
		var nm := Label.new()
		nm.text = str(r.get("title", id))
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 18, Palette.TEXT)
		v.add_child(nm)
		var mul := Moves.dmg_mul(slot, id)
		var stat := UiKit.rich("", 300, 12, Palette.TEXT)
		stat.text = "DMG [color=%s]x%.2f[/color]  ·  WEIGHT  %s" % [UiKit.UP_COL if mul >= 1.0 else UiKit.DOWN_COL, mul, "■".repeat(int(round(float(r.get("weight", 0.4)) * 5.0))) + "□".repeat(5 - int(round(float(r.get("weight", 0.4)) * 5.0)))]
		v.add_child(stat)
		h.add_child(v)
		for step in [-1, 1]:
			var b := _btn("◀" if step < 0 else "▶", Vector2(44, 44), "%s_%d" % [slot, step], false)
			b.pressed.connect(func() -> void:
				Moves.cycle(role, slot, step)
				Juice.play("res://assets/audio/ui_click.wav")
				_focus_key = "%s_%d" % [slot, step]
				_paint()
			)
			h.add_child(b)
		grid.add_child(p)


## MOVE PREVIEW: the hero performs whatever move is highlighted.
var _pv_anim: AnimatedSprite2D
var _pv_name: Label


func _preview_box(parent: Control) -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel(Color(0.03, 0.04, 0.08), Palette.EDGE))
	box.custom_minimum_size = Vector2(360, 470)
	parent.add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	_pv_name = Label.new()
	_pv_name.text = "HIGHLIGHT A MOVE"
	_pv_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pv_name.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_pv_name, 18, UiKit.GOLD)
	v.add_child(_pv_name)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(340, 420)
	v.add_child(stage)
	_pv_anim = SpriteBook.make_anim(role)
	SpriteBook.grow(_pv_anim, 5.2)
	_pv_anim.position = Vector2(170, 400) + _pv_anim.position
	_pv_anim.texture_filter = SpriteBook.UI_FILTER
	stage.add_child(_pv_anim)
	_pv_anim.animation_finished.connect(func() -> void:
		if is_instance_valid(_pv_anim):
			get_tree().create_timer(0.35).timeout.connect(func() -> void:
				if is_instance_valid(_pv_anim):
					_pv_anim.play(_pv_anim.animation)
			)
	)


func _show_move(id: String, title: String) -> void:
	if _pv_anim == null or not is_instance_valid(_pv_anim):
		return
	var clip := id if _pv_anim.sprite_frames.has_animation(id) else ("heavy" if _pv_anim.sprite_frames.has_animation("heavy") else "idle")
	_pv_anim.sprite_frames.set_animation_loop(clip, false)
	_pv_anim.stop()
	_pv_anim.play(clip)
	_pv_name.text = title


func _library(body: VBoxContainer) -> void:
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	body.add_child(split)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	split.add_child(grid)
	_preview_box(split)
	for r: Dictionary in Moves.for_role(role):
		var id := str(r["id"])
		var have := Moves.learned(role, id)
		var pr := _row_panel(Palette.READY if have else Palette.MUTED)
		var p: PanelContainer = pr[0]
		var h: HBoxContainer = pr[1]
		p.custom_minimum_size = Vector2(380, 92)
		var mtitle := str(r["title"])
		p.focus_mode = Control.FOCUS_ALL
		p.mouse_entered.connect(func() -> void: _show_move(id, mtitle))
		p.focus_entered.connect(func() -> void: _show_move(id, mtitle))
		var ic := _icon(id)
		if not have:
			ic.modulate = Color(0.35, 0.35, 0.4)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = str(r["title"])
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 15, Palette.TEXT if have else Palette.MUTED)
		v.add_child(nm)
		var tl := Label.new()
		tl.text = "%s  ·  %s" % [str(r["type"]).to_upper(), " / ".join(PackedStringArray((r["slots"] as Array).map(func(x): return str(x).to_upper())))]
		UiKit.apply_label(tl, 11, Palette.MUTED)
		v.add_child(tl)
		if have:
			var ok := Label.new()
			ok.text = "LEARNED"
			UiKit.apply_label(ok, 12, Palette.READY)
			v.add_child(ok)
		else:
			var lesson := str(r.get("lesson", ""))
			var b := _btn("LEARN %dG" % int(r["gold"]) if int(r["gold"]) > 0 else "DOJO LESSON", Vector2(150, 30), "learn_" + id, false)
			b.disabled = int(r["gold"]) <= 0 or int(FamilyProfile.data.get("gold", 0)) < int(r["gold"])
			if lesson != "":
				b.tooltip_text = "Also taught by the dojo lesson."
			b.focus_entered.connect(func() -> void: _show_move(id, mtitle))
			b.pressed.connect(func() -> void:
				if Moves.learn(role, id):
					Juice.play("res://assets/audio/claim.wav")
					need_refresh.emit()
					_focus_key = "learn_" + id
					_paint()
					UiKit.fx_after(self, "learn_" + id, Palette.EDGE, "LEARNED  ·  " + str(r["title"]), true)
			)
			v.add_child(b)
		h.add_child(v)
		grid.add_child(p)


const DIR_NAME := {"N": "L + H", "F": "FWD + L + H", "U": "UP + L + H", "D": "DOWN + L + H", "B": "BACK + L + H"}
const ART_CLIP := {"fireball": "cross", "lightning_dash": "superman_punch", "wind_kick": "air_spin_kick", "ice_slide": "slide",
	"fire_palm": "heavy", "thunder_clap": "hammer", "magma_uppercut": "uppercut", "quake_stomp": "boot_kick"}


func _section(body: VBoxContainer, txt: String, col: Color) -> void:
	var l := UiKit.title(txt, 18, col)
	body.add_child(l)


func _elements(body: VBoxContainer) -> void:
	_section(body, "ELEMENT ARTS", Palette.LEMON)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for r: Dictionary in Elements.arts(role):
		var id := str(r["id"])
		var lv := Elements.level(id)
		var c := Elements.color(str(r["elem"]))
		var pr := _row_panel(c if lv > 0 else Palette.MUTED)
		var p: PanelContainer = pr[0]
		var h: HBoxContainer = pr[1]
		p.custom_minimum_size = Vector2(570, 118)
		var ic := _icon(str(ART_CLIP.get(id, "heavy")), Vector2(76, 76))
		ic.modulate = c.lerp(Color.WHITE, 0.55) if lv > 0 else Color(0.35, 0.35, 0.4)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 2)
		var nm := Label.new()
		nm.text = "%s   %s" % [Elements.title(id), ("LV %d / %d%s" % [lv, Elements.MAX_LV, "  ·  EVOLVED" if Elements.evolved(id) else ""]) if lv > 0 else "LOCKED"]
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 15, c if lv > 0 else Palette.MUTED)
		v.add_child(nm)
		var io := Label.new()
		io.text = "%s  ·  %s  ·  CHI %d  ·  DMG %d" % [DIR_NAME[str(r["dir"])], str(r["elem"]).to_upper(), int(Elements.cost(id)), Elements.dmg(id)]
		UiKit.apply_label(io, 11, Palette.TEXT)
		v.add_child(io)
		var d := Label.new()
		d.text = str(r["evo_desc"]) if Elements.evolved(id) else str(r["desc"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(300, 0)
		UiKit.apply_label(d, 11, Palette.MUTED)
		v.add_child(d)
		h.add_child(v)
		var price := Elements.next_price(id)
		var bt := ""
		var can := false
		if Elements.can_evolve(id):
			bt = "EVOLVE %d GEMS" % Elements.EVOLVE_GEMS
			can = int(FamilyProfile.data.get("gems", 0)) >= Elements.EVOLVE_GEMS
		elif price >= 0:
			bt = ("UNLOCK %dG" if lv == 0 else "LEVEL UP %dG") % price
			can = int(FamilyProfile.data.get("gold", 0)) >= price
		else:
			bt = "MAXED"
		var b := _btn(bt, Vector2(150, 34), "art_" + id, false)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = not can
		var act := func() -> void:
			var ok := Elements.evolve(id) if Elements.can_evolve(id) else Elements.buy(id)
			if ok:
				Juice.play("res://assets/audio/claim.wav")
				need_refresh.emit()
				_focus_key = "art_" + id
				_paint()
				UiKit.fx_after(self, "art_" + id, Color(0.7, 0.5, 1.0), "%s  LV %d" % [Elements.title(id), Elements.level(id)], Elements.level(id) >= 5)
		# Evolving spends gems: hold to confirm.
		if Elements.can_evolve(id):
			UiKit.hold_confirm(b, act)
		else:
			b.pressed.connect(act)
		h.add_child(b)
		grid.add_child(p)
	_section(body, "GRABS  ·  L + H NEXT TO A THUG", Palette.EDGE)
	var gg := GridContainer.new()
	gg.columns = 3
	gg.add_theme_constant_override("h_separation", 10)
	body.add_child(gg)
	for g: Dictionary in Elements.grabs(role):
		var pr := _row_panel(Palette.EDGE)
		var p: PanelContainer = pr[0]
		var h: HBoxContainer = pr[1]
		p.custom_minimum_size = Vector2(376, 84)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = "%s   %s" % [str(g["title"]), DIR_NAME[str(g["dir"])]]
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 14, Palette.EDGE)
		v.add_child(nm)
		var d := Label.new()
		d.text = "%s  DMG %d" % [str(g["desc"]), int(g["dmg"])]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(340, 0)
		UiKit.apply_label(d, 11, Palette.MUTED)
		v.add_child(d)
		h.add_child(v)
		gg.add_child(p)
	_section(body, "DAD + SON TEAM ATTACKS  ·  TEAM RING FULL: HOLD H + SPECIAL", UiKit.GOLD)
	var tg := GridContainer.new()
	tg.columns = 3
	tg.add_theme_constant_override("h_separation", 10)
	body.add_child(tg)
	var tdir := {"daddy_launch": "NEUTRAL", "tag_slam": "FORWARD", "family_double": "UP / DOWN"}
	for t: Dictionary in Elements.team():
		var pr := _row_panel(UiKit.GOLD)
		var p: PanelContainer = pr[0]
		var h: HBoxContainer = pr[1]
		p.custom_minimum_size = Vector2(376, 84)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = "%s   %s" % [str(t["title"]), str(tdir.get(str(t["id"]), ""))]
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 14, UiKit.GOLD)
		v.add_child(nm)
		var d := Label.new()
		d.text = "%s  DMG %d" % [str(t["desc"]), int(t["dmg"])]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(340, 0)
		UiKit.apply_label(d, 11, Palette.MUTED)
		v.add_child(d)
		h.add_child(v)
		tg.add_child(p)


func _lab(body: VBoxContainer) -> void:
	var fins := Moves.finishers(role)
	if fins.is_empty():
		fins = ["heavy"]
	_fin = clampi(_fin, 0, fins.size() - 1)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	var lab := Label.new()
	lab.text = "INPUTS:"
	UiKit.apply_label(lab, 14, Palette.TEXT)
	top.add_child(lab)
	for tok: String in Moves.TOKENS:
		var b := _btn(ComboBook.step_label(tok, false), Vector2(84, 36), "tok_" + tok, false)
		b.disabled = _steps.size() >= 4
		b.pressed.connect(func() -> void:
			_steps.append(tok)
			_focus_key = "tok_" + tok
			_paint()
		)
		top.add_child(b)
	body.add_child(top)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	var seq := Label.new()
	seq.text = "LINE:  " + ("  ›  ".join(PackedStringArray(_steps.map(func(x): return ComboBook.step_label(str(x), false)))) if not _steps.is_empty() else "(tap inputs)")
	seq.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(seq, 20, Palette.LEMON)
	seq.custom_minimum_size = Vector2(520, 0)
	line.add_child(seq)
	var clr := _btn("CLEAR", Vector2(110, 36), "clear", false)
	clr.pressed.connect(func() -> void:
		_steps.clear()
		_focus_key = "clear"
		_paint()
	)
	line.add_child(clr)
	body.add_child(line)
	var fin_row := _row_panel(Palette.BRICK)
	var fp: PanelContainer = fin_row[0]
	var fh: HBoxContainer = fin_row[1]
	fh.add_child(_icon(str(fins[_fin]), Vector2(72, 72)))
	var fv := VBoxContainer.new()
	var fl := Label.new()
	fl.text = "FINISHER: %s" % str(Moves.row(str(fins[_fin])).get("title", fins[_fin]))
	fl.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(fl, 17, Palette.TEXT)
	fv.add_child(fl)
	var xl := Label.new()
	xl.text = "EFFECT: %s" % str(Moves.FX[_fx]).to_upper()
	UiKit.apply_label(xl, 14, Palette.LEMON)
	fv.add_child(xl)
	fh.add_child(fv)
	for pair in [["fin", "FINISHER ▶"], ["fx", "EFFECT ▶"]]:
		var b := _btn(pair[1], Vector2(150, 40), pair[0], false)
		b.pressed.connect(func() -> void:
			if pair[0] == "fin":
				_fin = (_fin + 1) % fins.size()
			else:
				_fx = (_fx + 1) % Moves.FX.size()
			_focus_key = pair[0]
			_paint()
		)
		fh.add_child(b)
	body.add_child(fp)
	var why := Moves.check(role, _steps)
	var save := _btn("SAVE COMBO" if why == "" else why, Vector2(260, 44), "save", false)
	save.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	save.disabled = why != "" or Moves.customs(role).size() >= Moves.MAX_CUSTOM
	save.pressed.connect(func() -> void:
		var title := "%s %s" % [["STREET", "NIGHT", "DOCK", "ALLEY", "RIOT", "LAST"][randi() % 6], ["LINE", "RUSH", "SPECIAL", "SERMON", "INVOICE", "LESSON"][randi() % 6]]
		var err := Moves.add_custom(role, title, _steps, str(fins[_fin]), str(Moves.FX[_fx]))
		if err == "":
			Juice.unlock_logo(title, "Your own combo. It fires in a fight now.", "COMBO LAB")
			_steps.clear()
		_focus_key = "save"
		_paint()
	)
	body.add_child(save)
	var mine := Label.new()
	mine.text = "YOUR COMBOS  %d/%d" % [Moves.customs(role).size(), Moves.MAX_CUSTOM]
	UiKit.apply_label(mine, 14, Palette.TEXT)
	body.add_child(mine)
	for c: Dictionary in Moves.customs(role):
		var pr := _row_panel(Palette.LEMON)
		var h: HBoxContainer = pr[1]
		h.add_child(_icon(str(c["clip"]), Vector2(48, 48)))
		var l := UiKit.rich("[color=#ffd75e]%s[/color]  %s  ›  %s  ·  DMG %d  ·  %s" % [str(c["title"]), ComboBook.steps_label(c, false), str(Moves.row(str(c["clip"])).get("title", "")), int(c["dmg"]), str(c["fx"]).to_upper()], 860, 13, Palette.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var del := _btn("DELETE", Vector2(110, 32), "del_" + str(c["id"]), false)
		var cid := str(c["id"])
		del.pressed.connect(func() -> void:
			Moves.remove_custom(role, cid)
			_paint()
		)
		h.add_child(del)
		body.add_child(pr[0])


func _styles(body: VBoxContainer) -> void:
	var st := Moves.styles(role)
	for i in 3:
		var s: Dictionary = st[i]
		var pr := _row_panel(Palette.LEMON if not s.is_empty() else Palette.MUTED)
		var h: HBoxContainer = pr[1]
		(pr[0] as PanelContainer).custom_minimum_size = Vector2(1140, 90)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = "STYLE %d  ·  %s" % [i + 1, str(s.get("title", "EMPTY"))]
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 18, Palette.TEXT)
		v.add_child(nm)
		if not s.is_empty():
			var parts: Array[String] = []
			for slot in Moves.SLOTS:
				parts.append("%s %s" % [slot, str(Moves.row(str((s["loadout"] as Dictionary).get(slot, ""))).get("title", ""))])
			v.add_child(UiKit.rich(" · ".join(parts), 860, 11, Palette.MUTED))
		h.add_child(v)
		var sv := _btn("SAVE HERE", Vector2(140, 40), "sv_%d" % i, false)
		var idx := i
		sv.pressed.connect(func() -> void:
			Moves.save_style(role, idx, ["BOXER", "KICKER", "BRAWLER"][idx])
			Juice.play("res://assets/audio/claim.wav")
			_focus_key = "sv_%d" % idx
			_paint()
		)
		h.add_child(sv)
		var ld := _btn("USE", Vector2(110, 40), "ld_%d" % i, false)
		ld.disabled = s.is_empty()
		ld.pressed.connect(func() -> void:
			if Moves.load_style(role, idx):
				Juice.shout(str(s.get("title", "STYLE")))
				_focus_key = "ld_%d" % idx
				_paint()
		)
		h.add_child(ld)
		body.add_child(pr[0])
