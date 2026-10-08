extends Control

## SURVIVOR GEAR, a paperdoll: the Kid stands lit in the middle of the bench
## with his four worn slots around him (cap by the head, jacket at the
## chest, shoes at the feet, necklace at the neck, charm and ring at the
## hands), each joined to the body by a
## line. Under him the worn totals as stat icons. On the right every piece
## you own as a pixel tile in its rarity frame; focus one to see its stats
## against what is worn (green up, red down), press it to WEAR. LV UP
## (S-COINS) and FUSE x3 sit under the details; a GEAR BOX tears open into a
## reveal. Every buy, level and fuse gets the reward-grow juice.

signal closed

const ACCENT := Color(0.4, 1.0, 0.7)
## Slot tile positions in the doll panel, and where on the body each joins.
const SLOT_AT := {"cap": Vector2(24, 26), "jacket": Vector2(24, 170), "shoes": Vector2(24, 314), "neck": Vector2(356, 26), "charm": Vector2(356, 170), "ring": Vector2(356, 314)}
const BODY_AT := {"cap": Vector2(232, 152), "jacket": Vector2(232, 228), "shoes": Vector2(240, 396), "neck": Vector2(236, 194), "charm": Vector2(262, 288), "ring": Vector2(212, 292)}
const STAT_ICON := {
	"dmg": "t_dmg", "area": "t_area", "cd": "t_cd", "speed": "t_speed", "hp": "t_hp", "pickup": "t_pickup",
	"luck": "t_luck", "armor": "t_armor", "crit": "t_crit", "regen": "t_regen", "xp": "t_xp", "proj": "meta_amount",
}

var _focus_key := ""
var _sel := -1
var _detail: VBoxContainer
var _wallet: Label
var _wallet_icon: Control
var _slot_tiles := {}
var _doll: Control


func _ready() -> void:
	Guides.show(self, "sgear")
	_paint()


func _coins() -> int:
	return int(FamilyProfile.data.get("tokens", 0))


func _paint() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_slot_tiles.clear()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Color(0.3, 0.9, 0.6), 0.4))
	card.position = Vector2(30, 24)
	card.size = Vector2(1220, 672)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(_header())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	body.add_child(_doll_panel())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 360)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var a := SurvGear.inv()
	if a.is_empty():
		var e := Label.new()
		e.text = "No gear yet. Survive past 2:00, open elite chests, or buy a GEAR BOX."
		UiKit.apply_label(e, 14, Palette.MUTED)
		grid.add_child(e)
	for i in a.size():
		grid.add_child(_inv_tile(i, a[i]))
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	_detail.custom_minimum_size = Vector2(0, 190)
	right.add_child(_detail)
	if _sel < 0 or _sel >= a.size():
		_sel = 0 if not a.is_empty() else -1
	_show_detail(_sel)
	UiKit.pop_in(card)
	var want := _focus_key
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and want != "" and not (b as Button).disabled:
				(b as Button).grab_focus()
				return
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")).begins_with("inv_"):
				(b as Button).grab_focus()
				return
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == "close":
				(b as Button).grab_focus()
	, CONNECT_ONE_SHOT)


func _header() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var t := UiKit.title("SURVIVOR GEAR", 28, Color(0.4, 1.0, 0.7))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_wallet_icon = IconBook.rect("cur_scoin", IconBook.SIZE_S)
	head.add_child(_wallet_icon)
	Juice.rewards.register("tokens", _wallet_icon)
	if not Juice.rewards.landed.is_connected(_on_landed):
		Juice.rewards.landed.connect(_on_landed)
	_wallet = Label.new()
	_wallet.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_wallet, 22, Palette.TEXT)
	_wallet.custom_minimum_size = Vector2(80, 0)
	head.add_child(_wallet)
	_refresh_wallet()
	var box := _btn("GEAR BOX", Vector2(230, 48), "box")
	var bi := IconBook.rect("gear_box", IconBook.SIZE_S)
	bi.position = Vector2(6, 3)
	box.add_child(bi)
	var price := HBoxContainer.new()
	price.position = Vector2(160, 13)
	price.add_child(IconBook.rect("cur_scoin_s", 22))
	var pl := Label.new()
	pl.text = str(SurvGear.BOX_PRICE)
	pl.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(pl, 13, ACCENT)
	price.add_child(pl)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(price)
	box.pressed.connect(func() -> void: _open_box(box))
	head.add_child(box)
	var close := _btn("CLOSE", Vector2(110, 48), "close")
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	return head


func _doll_panel() -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(500, 0)
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.035, 0.05, 0.06), Color(0.2, 0.45, 0.35)))
	_doll = p
	var lines := DollLines.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow := TextureRect.new()
	glow.texture = LightRig.radial_tex()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.position = Vector2(90, 90)
	glow.size = Vector2(280, 380)
	glow.modulate = Color(0.45, 1.0, 0.75, 0.3)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(glow)
	var stage := Node2D.new()
	stage.position = Vector2(230, 412)
	p.add_child(stage)
	if SpriteBook.has_who("son"):
		var a := SpriteBook.make_anim("son")
		a.scale *= 6.6
		a.position *= 6.6
		a.texture_filter = SpriteBook.UI_FILTER
		stage.add_child(a)
		a.play("idle")
	var w := SurvGear.worn()
	# Worn on the body: the cap on his head, the charm in his hand.
	if w.has("cap"):
		var cp := SurvGear.piece(int(w["cap"]))
		if not cp.is_empty():
			var hat := IconBook.rect(IconBook.for_gear(str(cp["id"])), IconBook.SIZE_M)
			hat.position = Vector2(203, 121)
			p.add_child(hat)
	if w.has("charm"):
		var ch := SurvGear.piece(int(w["charm"]))
		if not ch.is_empty():
			var ci := IconBook.rect(IconBook.for_gear(str(ch["id"])), IconBook.SIZE_S)
			ci.position = Vector2(240, 290)
			p.add_child(ci)
	if w.has("neck"):
		var nk := SurvGear.piece(int(w["neck"]))
		if not nk.is_empty():
			var ni := IconBook.rect(IconBook.for_gear(str(nk["id"])), IconBook.SIZE_S * 0.75)
			ni.position = Vector2(220, 180)
			p.add_child(ni)
	p.add_child(lines)
	var lit := {}
	for slot: String in SurvGear.SLOTS:
		var idx := int(w.get(slot, -1))
		var piece := SurvGear.piece(idx) if w.has(slot) else {}
		var tile := _slot_tile(slot, piece)
		tile.position = SLOT_AT[slot]
		p.add_child(tile)
		_slot_tiles[slot] = tile
		lit[slot] = Rarity.color(SurvGear.rarity_of(piece)) if not piece.is_empty() else Color(0.3, 0.32, 0.36)
	lines.lit = lit
	# Worn totals as stat icons under the doll.
	var tot := HFlowContainer.new()
	tot.position = Vector2(12, 470)
	tot.size = Vector2(476, 80)
	tot.add_theme_constant_override("h_separation", 10)
	tot.add_theme_constant_override("v_separation", 4)
	tot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tot)
	var any := false
	for k: String in SurvGear.STAT_NAME:
		var v := SurvGear.stat(k)
		if v <= 0.0:
			continue
		any = true
		tot.add_child(_stat_chip(k, v, Palette.READY))
	if not any:
		var nl := Label.new()
		nl.text = "WEAR SOMETHING. THE HOUR IS COLD."
		UiKit.apply_label(nl, 12, Palette.MUTED)
		tot.add_child(nl)
	return p


func _stat_chip(k: String, v: float, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(IconBook.rect(str(STAT_ICON.get(k, "node_score")), IconBook.SIZE_S * 0.75))
	var l := Label.new()
	l.text = ("%+d" % int(round(v))) if k == "hp" else ("%+d%%" % int(round(v * 100.0)))
	if k == "proj":
		l.text = "%+.1f" % v
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 12, col)
	h.add_child(l)
	return h


## A stat with its icon: what is worn now in grey, what this piece gives in
## green (better) or red (worse).
func _delta_chip(k: String, was: float, now: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(IconBook.rect(str(STAT_ICON.get(k, "node_score")), IconBook.SIZE_S * 0.75))
	var fmt := "%+d" if k == "hp" else ("%+.1f" if k == "proj" else "%+d%%")
	var mul := 1.0 if k in ["hp", "proj"] else 100.0
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.scroll_active = false
	l.add_theme_font_override("normal_font", UiKit.pixel_font())
	l.add_theme_font_size_override("normal_font_size", 12)
	l.text = UiKit.delta_bb(was * mul, now * mul, fmt)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	return h


func _slot_tile(slot: String, p: Dictionary) -> Control:
	var rar := SurvGear.rarity_of(p) if not p.is_empty() else "common"
	var rc := Rarity.color(rar) if not p.is_empty() else Color(0.35, 0.37, 0.42)
	var t := Panel.new()
	t.size = Vector2(120, 120)
	t.custom_minimum_size = t.size
	var sb := UiKit.panel(Rarity.fill(rar) if not p.is_empty() else Color(0.05, 0.05, 0.08), rc)
	sb.set_border_width_all(3)
	if not p.is_empty():
		sb.shadow_color = Color(rc.r, rc.g, rc.b, 0.45)
		sb.shadow_size = 8
	t.add_theme_stylebox_override("panel", sb)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := IconBook.rect(IconBook.for_gear(str(p["id"])) if not p.is_empty() else "slot_" + slot, IconBook.SIZE_M)
	ic.position = Vector2(28, 14)
	t.add_child(ic)
	var nm := Label.new()
	nm.text = SurvGear.SLOT_NAME[slot] if p.is_empty() else "LV %d" % int(p.get("lv", 1))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(0, 86)
	nm.size = Vector2(120, 16)
	nm.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(nm, 11, rc.lerp(Color.WHITE, 0.3) if not p.is_empty() else Palette.MUTED)
	t.add_child(nm)
	if not p.is_empty():
		var sl := Label.new()
		sl.text = SurvGear.SLOT_NAME[slot]
		sl.position = Vector2(6, 2)
		sl.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(sl, 9, Palette.MUTED)
		t.add_child(sl)
	return t


func _inv_tile(i: int, p: Dictionary) -> Button:
	var rar := SurvGear.rarity_of(p)
	var rc := Rarity.color(rar)
	var slot := str(SurvGear.LIST[str(p["id"])]["slot"])
	var worn := int(SurvGear.worn().get(slot, -1)) == i
	var b := Button.new()
	b.custom_minimum_size = Vector2(124, 124)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "inv_%d" % i)
	var sb := UiKit.panel(Rarity.fill(rar), rc)
	sb.set_border_width_all(3)
	var hi := sb.duplicate() as StyleBoxFlat
	hi.border_color = Color.WHITE.lerp(rc, 0.4)
	hi.shadow_color = Color(rc.r, rc.g, rc.b, 0.75)
	hi.shadow_size = 12
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hi)
	b.add_theme_stylebox_override("focus", hi)
	b.add_theme_stylebox_override("pressed", hi)
	var ic := IconBook.rect(IconBook.for_gear(str(p["id"])), IconBook.SIZE_M)
	ic.position = Vector2(30, 12)
	b.add_child(ic)
	var nm := Label.new()
	nm.text = str(SurvGear.LIST[str(p["id"])]["name"])
	nm.clip_text = true
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(3, 80)
	nm.size = Vector2(118, 14)
	nm.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(nm, 9, rc.lerp(Color.WHITE, 0.35))
	b.add_child(nm)
	var lv := Label.new()
	lv.text = "LV %d" % int(p.get("lv", 1))
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.position = Vector2(3, 96)
	lv.size = Vector2(118, 14)
	lv.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(lv, 10, Palette.TEXT)
	b.add_child(lv)
	if worn:
		var badge := Label.new()
		badge.text = "WORN"
		badge.position = Vector2(6, 4)
		badge.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(badge, 9, Palette.READY)
		b.add_child(badge)
	if SurvGear.can_fuse(i):
		var fz := Label.new()
		fz.text = "x3"
		fz.position = Vector2(96, 4)
		fz.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(fz, 10, UiKit.GOLD)
		b.add_child(fz)
	b.focus_entered.connect(func() -> void: _show_detail(i))
	b.mouse_entered.connect(func() -> void: _show_detail(i))
	b.pressed.connect(func() -> void:
		if worn:
			Juice.rewards.deny(b)
			return
		_wear(i, slot, rc))
	return b


func _wear(i: int, slot: String, rc: Color) -> void:
	SurvGear.wear(i)
	_focus_key = "inv_%d" % i
	_sel = i
	_paint()
	var tile: Control = _slot_tiles.get(slot)
	if tile:
		get_tree().process_frame.connect(func() -> void:
			if is_instance_valid(tile):
				Juice.upgrade_fx(tile, rc, "WORN", false)
		, CONNECT_ONE_SHOT)


func _show_detail(i: int) -> void:
	_sel = i
	if _detail == null:
		return
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	if i < 0:
		return
	var p := SurvGear.piece(i)
	if p.is_empty():
		return
	var rar := SurvGear.rarity_of(p)
	var rc := Rarity.color(rar)
	var slot := str(SurvGear.LIST[str(p["id"])]["slot"])
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.07), rc))
	_detail.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var big := IconBook.rect(IconBook.for_gear(str(p["id"])), IconBook.SIZE_L)
	row.add_child(big)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var nm := Label.new()
	nm.text = "%s  ·  LV %d" % [str(SurvGear.LIST[str(p["id"])]["name"]), int(p.get("lv", 1))]
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 17, rc.lerp(Color.WHITE, 0.3))
	info.add_child(nm)
	var rl := Label.new()
	rl.text = "%s  ·  %s" % [Rarity.label(rar), SurvGear.SLOT_NAME[slot]]
	rl.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(rl, 11, rc)
	info.add_child(rl)
	# Stats against what is worn in that slot.
	var w := SurvGear.worn()
	var worn_here := int(w.get(slot, -1)) == i
	var cur := SurvGear.piece(int(w.get(slot, -1))) if w.has(slot) and not worn_here else {}
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 12)
	info.add_child(chips)
	var keys: Array = (SurvGear.LIST[str(p["id"])]["stats"] as Dictionary).keys()
	if not cur.is_empty():
		for k in (SurvGear.LIST[str(cur["id"])]["stats"] as Dictionary).keys():
			if not keys.has(k):
				keys.append(k)
	for k: String in keys:
		var v := SurvGear.value(p, k)
		var was := SurvGear.value(cur, k) if not cur.is_empty() else (0.0 if not worn_here else v)
		chips.add_child(_delta_chip(k, was, v))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	info.add_child(btns)
	var wb := _btn("WORN" if worn_here else "WEAR", Vector2(120, 40), "wear")
	wb.disabled = worn_here
	wb.pressed.connect(func() -> void: _wear(i, slot, rc))
	btns.add_child(wb)
	var lvl := int(p.get("lv", 1))
	var price := SurvGear.lv_price(p)
	var lb := _btn(("LV UP  %d" % price) if lvl < SurvGear.MAX_LV else "MAX LEVEL", Vector2(170, 40), "lv")
	lb.disabled = lvl >= SurvGear.MAX_LV
	lb.pressed.connect(func() -> void:
		if _coins() < price or not SurvGear.level_up(i):
			Juice.rewards.deny(lb)
			return
		_spend(price, lb)
		_focus_key = "inv_%d" % i
		_paint()
		_juice_tile(i, rc, "LV %d" % (lvl + 1), lvl + 1 >= SurvGear.MAX_LV)
	)
	btns.add_child(lb)
	var fb := _btn("FUSE x3", Vector2(150, 40), "fuse")
	fb.disabled = not SurvGear.can_fuse(i)
	UiKit.hold_confirm(fb, func() -> void:
		var next: String = SurvGear.RARITY[mini(4, int(p.get("rar", 0)) + 1)]
		if SurvGear.fuse(i):
			Rarity.juice(next, "FUSED")
			Juice.rewards.reveal(IconBook.for_gear(str(p["id"])), "FUSED  ·  %s" % Rarity.label(next), Rarity.color(next), str(SurvGear.LIST[str(p["id"])]["name"]))
			_focus_key = "box"
			_paint()
	)
	btns.add_child(fb)


func _juice_tile(i: int, col: Color, text: String, big: bool) -> void:
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == "inv_%d" % i:
				Juice.upgrade_fx(b as Control, col, text, big)
				return
	, CONNECT_ONE_SHOT)


func _open_box(box: Button) -> void:
	if _coins() < SurvGear.BOX_PRICE:
		Juice.rewards.deny(box)
		return
	var p := SurvGear.buy_box()
	if p.is_empty():
		Juice.rewards.deny(box)
		return
	_spend(SurvGear.BOX_PRICE, box)
	Juice.play("res://assets/audio/chest.wav")
	var rar := SurvGear.rarity_of(p)
	Rarity.juice(rar, str(SurvGear.LIST[str(p["id"])]["name"]))
	Juice.rewards.reveal(IconBook.for_gear(str(p["id"])), str(SurvGear.LIST[str(p["id"])]["name"]), Rarity.color(rar), "%s  ·  %s" % [Rarity.label(rar), SurvGear.line(p)])
	_focus_key = "box"
	_sel = SurvGear.inv().size() - 1
	_paint()


## S-COINS leave the wallet for what was bought.
func _spend(n: int, to: Control) -> void:
	var tex := IconBook.tex("cur_scoin_s")
	var from := RewardFly.vp_of(_wallet_icon)
	var dest := RewardFly.vp_of(to)
	for k in clampi(n / 10, 3, 10):
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = from
		Juice.rewards.add_child(s)
		var bend := Vector2(randf_range(-50, 50), randf_range(-30, 30))
		var tw := s.create_tween()
		tw.tween_interval(0.035 * float(k))
		tw.tween_method(func(t: float) -> void:
			var mid := (from + dest) * 0.5 + bend
			s.position = from.lerp(mid, t).lerp(mid.lerp(dest, t), t).round()
		, 0.0, 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			RewardFly.snd("coin_tick", 1.2 + 0.08 * float(k), -6.0)
			s.queue_free())
	_refresh_wallet()


func _on_landed(_k: String) -> void:
	_refresh_wallet()


func _refresh_wallet() -> void:
	if _wallet and is_instance_valid(_wallet):
		_wallet.text = str(_coins() - Juice.rewards.pending("tokens"))


func _btn(txt: String, sz: Vector2, key: String) -> Button:
	var b := UiKit.button(txt, sz)
	b.add_theme_font_size_override("font_size", 12)
	b.set_meta("key", key)
	return b


## Lines from each slot tile to its place on the body, lit in the worn
## piece's rarity colour, with a pulsing dot on the body.
class DollLines extends Control:
	var lit := {}
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for slot: String in lit:
			var c: Color = lit[slot]
			var at: Vector2 = SLOT_AT[slot]
			var b: Vector2 = BODY_AT[slot]
			var a := Vector2(at.x + (120.0 if at.x < b.x else 0.0), at.y + 60.0)
			var mid := Vector2((a.x + b.x) * 0.5, a.y)
			draw_polyline(PackedVector2Array([a, mid, Vector2(mid.x, b.y), b]), Color(c.r, c.g, c.b, 0.55), 2.0)
			var pulse := 3.0 + 1.5 * sin(_t * 4.0)
			draw_circle(b, pulse + 2.0, Color(c.r, c.g, c.b, 0.25))
			draw_circle(b, 3.0, c)
