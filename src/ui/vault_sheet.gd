extends Control

## CARD VAULT. Face-down cards lie on the table - Father and Son on a rooftop
## at sunset. DRAW pays the current price and a light runs round the table
## like a roulette ball until it settles; that card lifts, glows in its
## rarity colour, flips and comes right up to the glass (rays behind it, a
## shadow under it, its reflection on the table), then drops into YOUR CARDS
## under the DRAW button. Every card there is the real in-game card: click
## one to bring it close, MERGE two of the same rarity into the next, and
## EVOLVE two legendaries into their stronger mixed card. SYNERGIES lists the
## pairs that open a synergy card.

signal closed

const BACK := "res://assets/sprites/vault/card_back.png"
const CW := 104.0
const CH := 150.0
const MINI := 0.28
## How big a card is when it is held up to the glass.
const BIG := 1.05

var _grid: Control
var _backs: Array[Control] = []
var _draw_btn: Button
var _price: Label
var _next: Label
var _purse: Label
var _coll: GridContainer
var _extra: HBoxContainer
var _busy := false
var _stage: Control
var _coll_box: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -610
	card.offset_right = 610
	card.offset_top = -340
	card.offset_bottom = 340
	add_child(card)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	card.add_child(outer)
	var head := HBoxContainer.new()
	var t := UiKit.title("CARD VAULT", 30, Palette.LEMON)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.title_icon(t, "cur_card_token")
	head.add_child(t)
	_purse = Label.new()
	UiKit.apply_label(_purse, 15, UiKit.GOLD)
	head.add_child(_purse)
	var close := UiKit.button("CLOSE", Vector2(120, 40))
	close.pressed.connect(func() -> void:
		if not _busy:
			closed.emit()
	)
	head.add_child(close)
	outer.add_child(head)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	_grid = Control.new()
	_grid.custom_minimum_size = Vector2(4 * CW + 3 * 14 + 16, 3 * CH + 2 * 12 + 20)
	body.add_child(_grid)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	right.add_child(top)
	_draw_btn = UiKit.button("DRAW", Vector2(260, 60))
	_draw_btn.add_theme_font_override("font", UiKit.title_font())
	_draw_btn.add_theme_font_size_override("font_size", 30)
	_draw_btn.pressed.connect(_draw)
	top.add_child(_draw_btn)
	var pv := VBoxContainer.new()
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(pv)
	_price = Label.new()
	UiKit.apply_label(_price, 15, Palette.TEXT)
	pv.add_child(_price)
	_next = Label.new()
	_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_next, 11, Palette.MUTED)
	pv.add_child(_next)
	_extra = HBoxContainer.new()
	_extra.add_theme_constant_override("separation", 8)
	right.add_child(_extra)
	right.add_child(UiKit.title("YOUR CARDS", 16, Palette.LEMON))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(560, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	_coll_box = sc
	_coll = GridContainer.new()
	_coll.columns = 6
	_coll.add_theme_constant_override("h_separation", 8)
	_coll.add_theme_constant_override("v_separation", 8)
	sc.add_child(_coll)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_lay_backs()
	_refresh()
	_draw_btn.grab_focus()
	UiKit.pop_in(card)


# --- the table ---------------------------------------------------------------

func _lay_backs() -> void:
	for b in _backs:
		b.queue_free()
	_backs.clear()
	var n := VaultCards.hand_size()
	var cols := 4 if n == 12 else 3
	var x0 := (_grid.custom_minimum_size.x - (float(cols) * CW + float(cols - 1) * 14.0)) * 0.5
	for i in n:
		var b := _back()
		b.position = Vector2(x0 + float(i % cols) * (CW + 14.0), 10.0 + float(i / cols) * (CH + 12.0))
		_grid.add_child(b)
		_backs.append(b)
		b.modulate.a = 0.0
		var y := b.position.y
		b.position.y -= 30.0
		var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.04 * float(i))
		tw.tween_property(b, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(b, "position:y", y, 0.25)


func _back() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(CW, CH)
	holder.size = Vector2(CW, CH)
	holder.pivot_offset = Vector2(CW, CH) * 0.5
	var glow := Panel.new()
	glow.name = "Glow"
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(0, 0, 0, 0)
	gs.border_color = Color(1, 0.85, 0.3, 0.0)
	gs.set_border_width_all(4)
	gs.shadow_color = Color(1, 0.85, 0.3, 0.0)
	gs.shadow_size = 14
	glow.add_theme_stylebox_override("panel", gs)
	glow.position = Vector2(-4, -4)
	glow.size = Vector2(CW + 8, CH + 8)
	holder.add_child(glow)
	var pic := TextureRect.new()
	pic.texture = load(BACK) if ResourceLoader.exists(BACK) else null
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.size = Vector2(CW, CH)
	holder.add_child(pic)
	return holder


func _light(b: Control, col: Color, a: float) -> void:
	var g := b.get_node("Glow") as Panel
	var sb := g.get_theme_stylebox("panel") as StyleBoxFlat
	sb.border_color = Color(col.r, col.g, col.b, a)
	sb.shadow_color = Color(col.r, col.g, col.b, a * 0.7)


# --- your cards --------------------------------------------------------------

func _refresh() -> void:
	_purse.text = "GOLD %d   GEMS %d   TOKENS %d   " % [int(FamilyProfile.data.get("gold", 0)), int(FamilyProfile.data.get("gems", 0)), VaultCards.tokens()]
	_price.text = "DRAW  ·  " + VaultCards.price_text()
	var s := VaultCards.step()
	var nxt: Array[String] = []
	for k in range(1, 4):
		nxt.append(VaultCards.price_text(VaultCards.LADDER[mini(s + k, VaultCards.LADDER.size() - 1)]))
	_next.text = "Then %s. Price drops two steps every night out. Tokens: RARE or better. Two alike MERGE up a rarity; two LEGENDARY can EVOLVE." % ", ".join(nxt)
	_draw_btn.disabled = _busy or not VaultCards.can_pay()
	_draw_btn.text = "DRAW" if VaultCards.can_pay() else "CAN'T AFFORD"
	for c in _extra.get_children():
		c.queue_free()
	var syn := UiKit.button("SYNERGIES", Vector2(150, 32))
	syn.add_theme_font_size_override("font_size", 12)
	syn.pressed.connect(_show_synergies)
	_extra.add_child(syn)
	for eid: String in VaultCards.evolutions_ready():
		var eb := UiKit.button("EVOLVE  ·  %s" % str(VaultCards.card(eid).get("name", eid)), Vector2(280, 32))
		eb.add_theme_font_size_override("font_size", 12)
		eb.add_theme_color_override("font_color", Rarity.color("legendary"))
		eb.pressed.connect(func() -> void: _evolve(eid))
		_extra.add_child(eb)
		UiKit.pulse_ready(eb)
	for c in _coll.get_children():
		c.queue_free()
	var ids: Array = []
	for id: String in VaultCards.inv().keys():
		if VaultCards.level(id) > 0:
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool: return VaultCards.level(a) > VaultCards.level(b))
	if ids.is_empty():
		var e := Label.new()
		e.text = "No cards yet. Draw one: it joins your level-ups in every run."
		UiKit.apply_label(e, 13, Palette.MUTED)
		_coll.add_child(e)
	for id: String in ids:
		_coll.add_child(_mini(id))


## A small copy of the real card, a count badge, MERGE when two match.
func _mini(id: String) -> Control:
	var holder := Button.new()
	holder.flat = true
	holder.custom_minimum_size = Vector2(PixelCard.W, PixelCard.H) * MINI
	for st in ["normal", "hover", "pressed", "focus"]:
		holder.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var face := PixelCard.new()
	face.info = VaultCards.as_row(id)
	face.face_up = true
	face.scale = Vector2(MINI, MINI)
	var home := Vector2(PixelCard.W, PixelCard.H) * (MINI - 1.0) * 0.5
	face.position = home
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(face)
	var total := 0
	for n in VaultCards.counts(id):
		total += int(n)
	var merge := false
	for t in 4:
		if VaultCards.can_merge(id, t):
			merge = true
	var badge := Label.new()
	badge.text = ("x%d" % total) + ("  MERGE!" if merge else "")
	badge.position = Vector2(2, PixelCard.H * MINI - 16)
	UiKit.apply_label(badge, 11, Palette.READY if merge else Color.WHITE)
	badge.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	badge.add_theme_constant_override("outline_size", 4)
	holder.add_child(badge)
	holder.mouse_entered.connect(func() -> void:
		holder.create_tween().tween_property(face, "position:y", home.y - 6.0, 0.1))
	holder.mouse_exited.connect(func() -> void:
		holder.create_tween().tween_property(face, "position:y", home.y, 0.1))
	holder.pressed.connect(func() -> void: _inspect(id))
	return holder


# --- draw --------------------------------------------------------------------

func _draw() -> void:
	if _busy or not VaultCards.can_pay():
		return
	_busy = true
	_draw_btn.disabled = true
	var got := VaultCards.draw()
	if got.is_empty():
		_busy = false
		_refresh()
		return
	Mixer.play_sfx("res://assets/audio/cash.wav" if ResourceLoader.exists("res://assets/audio/cash.wav") else "res://assets/audio/ui_click.wav")
	var target := randi() % _backs.size()
	var col := Rarity.color(str(got.get("rarity", "common")))
	var hops := 18 + randi() % 6
	var order: Array = []
	var cur := randi() % _backs.size()
	for i in hops - 1:
		order.append(cur)
		cur = (cur + 1 + randi() % 3) % _backs.size()
	order.append(target)
	var tw := create_tween()
	var wait := 0.04
	for i in order.size():
		var idx: int = order[i]
		tw.tween_callback(func() -> void:
			for b in _backs:
				_light(b, Color(1, 0.9, 0.4), 0.0)
				b.scale = Vector2.ONE
			_light(_backs[idx], Color(1, 0.9, 0.4), 0.9)
			_backs[idx].scale = Vector2(1.06, 1.06)
			Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.2 + 0.4 * float(i) / float(order.size()), -10.0)
		)
		tw.tween_interval(wait)
		wait *= 1.13
	tw.tween_callback(func() -> void: _reveal(_backs[target], got, col))


func _reveal(b: Control, got: Dictionary, col: Color) -> void:
	_light(b, col, 1.0)
	var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "position:y", b.position.y - 18.0, 0.2)
	tw.parallel().tween_property(b, "scale", Vector2(1.12, 1.12), 0.2)
	tw.tween_interval(0.25)
	tw.tween_property(b, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _show_face(b, got, col))


## The drawn card comes right up to the glass: rays turning behind it, a soft
## shadow under it and its reflection on the dark table, then it drops into
## YOUR CARDS.
func _show_face(b: Control, got: Dictionary, col: Color) -> void:
	var id := str(got["id"])
	var info := VaultCards.as_row(id)
	info["rarity"] = str(got.get("rarity", "common"))
	b.visible = false
	var mid := _stage.size * 0.5 + Vector2(0, -30)
	# PixelCard scales around its centre: place it by where its middle goes.
	var center := mid - Vector2(PixelCard.W, PixelCard.H) * 0.5
	var from := _stage.get_global_transform().affine_inverse() * b.get_global_rect().get_center() - Vector2(PixelCard.W, PixelCard.H) * 0.5
	var rig := _showcase(info, col, mid)
	var face: PixelCard = rig["face"]
	var refl: PixelCard = rig["refl"]
	var k := CW / PixelCard.W
	face.position = from
	face.scale = Vector2(0.02, k * 1.12)
	refl.modulate.a = 0.0
	Rarity.juice(str(got.get("rarity", "common")), str(got.get("name", "")))
	Juice.play("res://assets/audio/card.wav")
	var tw := face.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(face, "scale:x", k * 1.12, 0.12)
	tw.tween_interval(0.15)
	tw.tween_property(face, "position", center, 0.4).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(face, "scale", Vector2(BIG, BIG), 0.4).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(refl, "modulate:a", 0.22, 0.4)
	tw.tween_callback(func() -> void:
		UiKit.blast(_stage, mid, col, 360.0)
		Juice.pulse_shake(5.0)
		Juice.play("res://assets/audio/levelup.wav" if ResourceLoader.exists("res://assets/audio/levelup.wav") else "res://assets/audio/chest.wav")
	)
	var line := "NEW CARD!" if bool(got.get("new", false)) else "+1 COPY  ·  %s" % str(got.get("rarity", "")).to_upper()
	if bool(got.get("merge", false)):
		line += "  ·  READY TO MERGE"
	var tag := UiKit.title(line, 30, col)
	tag.size = Vector2(_stage.size.x, 40)
	tag.position = Vector2(0, mid.y + PixelCard.H * BIG * 0.5 + 30.0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tag.add_theme_constant_override("outline_size", 8)
	tag.modulate.a = 0.0
	_stage.add_child(tag)
	tw.tween_property(tag, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.5)
	# Into YOUR CARDS.
	var dest := _stage.get_global_transform().affine_inverse() * (_coll_box.get_global_rect().position + Vector2(PixelCard.W, PixelCard.H) * MINI * 0.5) - Vector2(PixelCard.W, PixelCard.H) * 0.5
	tw.tween_property(tag, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(rig["back"], "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(refl, "modulate:a", 0.0, 0.2)
	tw.tween_property(face, "position", dest, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(face, "scale", Vector2(MINI, MINI), 0.35)
	tw.tween_callback(func() -> void:
		Juice.play("res://assets/audio/cling.wav")
		(rig["root"] as Node).queue_free()
		tag.queue_free()
		b.visible = true
		b.scale = Vector2.ONE
		_light(b, col, 0.0)
		b.position.y += 18.0
		b.modulate.a = 0.0
		b.create_tween().tween_property(b, "modulate:a", 1.0, 0.2)
		_busy = false
		_refresh()
		_draw_btn.grab_focus()
	)


## A card on show: dim back, turning rays, a shadow and a mirrored copy.
func _showcase(info: Dictionary, col: Color, mid: Vector2) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(root)
	var back := Control.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)
	var t0 := Time.get_ticks_msec()
	back.draw.connect(func() -> void:
		back.draw_rect(Rect2(Vector2.ZERO, back.size), Color(0, 0, 0.02, 0.6))
		var tt := float(Time.get_ticks_msec() - t0) / 1000.0
		for i in 16:
			var a := tt * 0.5 + float(i) * TAU / 16.0
			back.draw_colored_polygon(PackedVector2Array([mid, mid + Vector2(cos(a - 0.07), sin(a - 0.07)) * 520.0, mid + Vector2(cos(a + 0.07), sin(a + 0.07)) * 520.0]), Color(col.r, col.g, col.b, 0.13))
		back.draw_circle(mid, 230.0, Color(col.r, col.g, col.b, 0.08))
		# Soft shadow where the card would sit on the table.
		back.draw_set_transform(mid + Vector2(0, PixelCard.H * BIG * 0.5 + 10.0), 0.0, Vector2(1.0, 0.18))
		back.draw_circle(Vector2.ZERO, PixelCard.W * 0.6, Color(0, 0, 0, 0.55))
		back.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	)
	var spin := back.create_tween().set_loops()
	spin.tween_callback(back.queue_redraw).set_delay(0.03)
	var refl := PixelCard.new()
	refl.info = info
	refl.face_up = true
	refl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refl.scale = Vector2(BIG, -0.4)
	refl.position = mid + Vector2(0, PixelCard.H * BIG * 0.5 + PixelCard.H * 0.2 + 6.0) - Vector2(PixelCard.W, PixelCard.H) * 0.5
	root.add_child(refl)
	var face := PixelCard.new()
	face.info = info
	face.face_up = true
	face.lit = true
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(face)
	return {"root": root, "back": back, "face": face, "refl": refl}


# --- inspect / merge / evolve / synergies -------------------------------------

func _inspect(id: String) -> void:
	if _busy:
		return
	var info := VaultCards.as_row(id)
	var col := Rarity.color(str(info.get("rarity", "common")))
	var mid := _stage.size * 0.5 + Vector2(-150, -40)
	var rig := _showcase(info, col, mid)
	var root: Control = rig["root"]
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var face: PixelCard = rig["face"]
	face.position = mid - Vector2(PixelCard.W, PixelCard.H) * 0.5
	face.scale = Vector2(0.6, 0.6)
	face.create_tween().set_trans(Tween.TRANS_BACK).tween_property(face, "scale", Vector2(BIG, BIG), 0.25)
	Juice.play("res://assets/audio/card.wav")
	var panel := VBoxContainer.new()
	panel.position = Vector2(mid.x + PixelCard.W * 0.75, mid.y - 150)
	panel.custom_minimum_size = Vector2(320, 0)
	panel.add_theme_constant_override("separation", 8)
	root.add_child(panel)
	panel.add_child(UiKit.title(str(info.get("name", id)), 24, col))
	var copies := Label.new()
	var parts: Array[String] = []
	var c := VaultCards.counts(id)
	for t in 5:
		if int(c[t]) > 0:
			parts.append("%d× %s" % [int(c[t]), Rarity.ORDER[t].to_upper()])
	copies.text = "COPIES  ·  " + "  ".join(parts)
	copies.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(copies, 13, Palette.TEXT)
	panel.add_child(copies)
	var bl := Label.new()
	bl.text = str(info.get("blurb", ""))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(bl, 14, Palette.TEXT)
	panel.add_child(bl)
	for t in 4:
		if VaultCards.can_merge(id, t):
			var mb := UiKit.button("MERGE 2× %s  ›  %s" % [Rarity.ORDER[t].to_upper(), Rarity.ORDER[t + 1].to_upper()], Vector2(320, 44))
			mb.add_theme_color_override("font_color", Rarity.color(Rarity.ORDER[t + 1]))
			var tier := t
			mb.pressed.connect(func() -> void:
				var nt := VaultCards.merge(id, tier)
				if nt >= 0:
					root.queue_free()
					_merge_fx(id, nt)
			)
			panel.add_child(mb)
			UiKit.pulse_ready(mb)
	var close := UiKit.button("BACK", Vector2(320, 40))
	close.pressed.connect(func() -> void:
		root.queue_free()
		_refresh()
	)
	panel.add_child(close)
	close.grab_focus()


func _merge_fx(id: String, tier: int) -> void:
	var info := VaultCards.as_row(id)
	var col := Rarity.color(Rarity.ORDER[tier])
	var mid := _stage.size * 0.5 + Vector2(0, -30)
	var rig := _showcase(info, col, mid)
	var face: PixelCard = rig["face"]
	face.position = mid - Vector2(PixelCard.W, PixelCard.H) * 0.5
	face.scale = Vector2(BIG, BIG)
	face.modulate = Color(3, 3, 3)
	Rarity.juice(Rarity.ORDER[tier], str(info.get("name", "")))
	UiKit.blast(_stage, mid, col, 400.0)
	Juice.pulse_shake(6.0)
	Juice.play("res://assets/audio/levelup.wav" if ResourceLoader.exists("res://assets/audio/levelup.wav") else "res://assets/audio/chest.wav")
	var tag := UiKit.title("MERGED  ·  %s" % Rarity.ORDER[tier].to_upper(), 32, col)
	tag.size = Vector2(_stage.size.x, 40)
	tag.position = Vector2(0, mid.y + PixelCard.H * BIG * 0.5 + 30.0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tag.add_theme_constant_override("outline_size", 8)
	_stage.add_child(tag)
	var tw := face.create_tween()
	tw.tween_property(face, "modulate", Color.WHITE, 0.35)
	tw.tween_interval(1.3)
	tw.tween_callback(func() -> void:
		(rig["root"] as Node).queue_free()
		tag.queue_free()
		_refresh()
	)


func _evolve(eid: String) -> void:
	if _busy or not VaultCards.evolve(eid):
		return
	_busy = true
	var info := VaultCards.as_row(eid)
	var mid := _stage.size * 0.5 + Vector2(0, -30)
	# The two parents slide together and flash into one.
	var parents: Array = VaultCards.card(eid).get("needs", [])
	var cards: Array = []
	for i in parents.size():
		var p := PixelCard.new()
		p.info = VaultCards.as_row(str(parents[i]))
		p.info["rarity"] = "legendary"
		p.scale = Vector2(0.8, 0.8)
		p.position = mid + Vector2(-260.0 if i == 0 else 260.0, 0) - Vector2(PixelCard.W, PixelCard.H) * 0.5
		_stage.add_child(p)
		cards.append(p)
		p.create_tween().tween_property(p, "position:x", mid.x - PixelCard.W * 0.5, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	Juice.play("res://assets/audio/whoosh_light.wav" if ResourceLoader.exists("res://assets/audio/whoosh_light.wav") else "res://assets/audio/card.wav")
	get_tree().create_timer(0.62).timeout.connect(func() -> void:
		for p in cards:
			(p as Node).queue_free()
		_merge_fx(eid, 4)
		Juice.unlock_logo(str(info.get("name", "EVOLVED")), "Two legendaries fused into one.", "EVOLUTION", IconBook.tex("cur_card_token"))
		_busy = false
	)


func _show_synergies() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var box := VBoxContainer.new()
	box.position = Vector2(_stage.size.x * 0.5 - 330, 90)
	box.custom_minimum_size = Vector2(660, 0)
	box.add_theme_constant_override("separation", 10)
	root.add_child(box)
	box.add_child(UiKit.title("SYNERGIES  &  EVOLUTIONS", 26, Palette.LEMON))
	var note := Label.new()
	note.text = "Own both halves of a synergy and its card can come out of the vault (CARD SYNERGY node). Two LEGENDARY parents evolve into one mixed card (CARD EVOLUTION node)."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(note, 12, Palette.MUTED)
	box.add_child(note)
	for c: Dictionary in VaultCards.book():
		var kind := str(c.get("kind", ""))
		if kind != "synergy" and kind != "evolution":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var nm := Label.new()
		nm.text = ("SYNERGY  " if kind == "synergy" else "EVOLVE  ") + str(c["name"])
		nm.custom_minimum_size = Vector2(300, 0)
		UiKit.apply_label(nm, 14, Rarity.color("epic") if kind == "synergy" else Rarity.color("legendary"))
		row.add_child(nm)
		var parts: Array[String] = []
		for n in c.get("needs", []):
			var lv := VaultCards.level(str(n))
			var ok := lv > 0 if kind == "synergy" else lv >= 5
			parts.append("[color=%s]%s %s[/color]" % [UiKit.UP_COL if ok else UiKit.DOWN_COL, "✔" if ok else "✘", str(VaultCards.card(str(n)).get("name", n))])
		var rt := UiKit.rich("  +  ".join(parts), 340, 13, Palette.TEXT)
		row.add_child(rt)
		box.add_child(row)
	var back := UiKit.button("BACK", Vector2(200, 40))
	back.pressed.connect(root.queue_free)
	box.add_child(back)
	back.grab_focus()
