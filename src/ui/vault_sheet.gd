extends Control

## CARD VAULT: 9 (or 12 with BIGGER HAND) cards lie face down, backs up -
## Father and Son back to back in the rain. DRAW pays the current price
## (gold, then more gold, then gems, then card tokens, then both) and a light
## runs round the table like a roulette ball, slowing until it settles on one.
## That card lifts, its edges light up in its rarity colour, it flips and
## flies to the middle: a new vault card, or the next level of one you own.
## Owned vault cards come up at level-ups in story runs and survivor hours.

signal closed

const BACK := "res://assets/sprites/vault/card_back.png"
const CW := 116.0
const CH := 168.0

var _grid: Control
var _backs: Array[Control] = []
var _draw_btn: Button
var _price: Label
var _next: Label
var _purse: Label
var _coll: VBoxContainer
var _busy := false
var _stage: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
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
	outer.add_theme_constant_override("separation", 8)
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
	_grid.custom_minimum_size = Vector2(4 * CW + 3 * 16 + 20, 3 * CH + 2 * 14 + 20)
	body.add_child(_grid)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	_draw_btn = UiKit.button("DRAW", Vector2(420, 64))
	_draw_btn.add_theme_font_override("font", UiKit.title_font())
	_draw_btn.add_theme_font_size_override("font_size", 30)
	_draw_btn.pressed.connect(_draw)
	right.add_child(_draw_btn)
	_price = Label.new()
	UiKit.apply_label(_price, 15, Palette.TEXT)
	right.add_child(_price)
	_next = Label.new()
	_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next.custom_minimum_size = Vector2(420, 0)
	UiKit.apply_label(_next, 12, Palette.MUTED)
	right.add_child(_next)
	right.add_child(UiKit.title("COLLECTION", 16, Palette.LEMON))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(420, 300)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	_coll = VBoxContainer.new()
	_coll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coll.add_theme_constant_override("separation", 4)
	sc.add_child(_coll)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_lay_backs()
	_refresh()
	_draw_btn.grab_focus()
	UiKit.pop_in(card)


func _lay_backs() -> void:
	for b in _backs:
		b.queue_free()
	_backs.clear()
	var n := VaultCards.hand_size()
	var cols := 4 if n == 12 else 3
	var x0 := (_grid.custom_minimum_size.x - (float(cols) * CW + float(cols - 1) * 16.0)) * 0.5
	for i in n:
		var b := _back()
		b.position = Vector2(x0 + float(i % cols) * (CW + 16.0), 10.0 + float(i / cols) * (CH + 14.0))
		_grid.add_child(b)
		_backs.append(b)
		# Dealt in, one after another.
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


func _refresh() -> void:
	_purse.text = "GOLD %d   GEMS %d   TOKENS %d   " % [int(FamilyProfile.data.get("gold", 0)), int(FamilyProfile.data.get("gems", 0)), VaultCards.tokens()]
	_price.text = "DRAW  ·  " + VaultCards.price_text()
	var s := VaultCards.step()
	var nxt: Array[String] = []
	for k in range(1, 4):
		nxt.append(VaultCards.price_text(VaultCards.LADDER[mini(s + k, VaultCards.LADDER.size() - 1)]))
	_next.text = "Then: %s.  Each draw costs more; every night out takes the price down two steps. Tokens guarantee RARE or better, gems UNCOMMON or better.  Odds: common 44 · uncommon 28 · rare 17 · epic 8.5 · legendary 2.5" % ", ".join(nxt)
	_draw_btn.disabled = _busy or not VaultCards.can_pay()
	_draw_btn.text = "DRAW" if VaultCards.can_pay() else "CAN'T AFFORD"
	for c in _coll.get_children():
		c.queue_free()
	var own := VaultCards.owned()
	var ids: Array = own.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return Rarity.rank(str(VaultCards.card(a).get("rarity", "common"))) > Rarity.rank(str(VaultCards.card(b).get("rarity", "common"))))
	if ids.is_empty():
		var e := Label.new()
		e.text = "Nothing yet. Draw a card: it joins your level-ups in every run."
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(e, 13, Palette.MUTED)
		_coll.add_child(e)
	for id: String in ids:
		var c := VaultCards.card(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var rar := str(c.get("rarity", "common"))
		var nm := Label.new()
		nm.text = str(c.get("name", id))
		nm.custom_minimum_size = Vector2(210, 0)
		UiKit.apply_label(nm, 13, Rarity.color(rar))
		row.add_child(nm)
		var pips := Label.new()
		var lv := VaultCards.level(id)
		pips.text = "■".repeat(lv) + "□".repeat(VaultCards.MAX_LV - lv)
		UiKit.apply_label(pips, 13, UiKit.GOLD)
		row.add_child(pips)
		var tg := Label.new()
		tg.text = str(c.get("tag", ""))
		UiKit.apply_label(tg, 11, Palette.MUTED)
		row.add_child(tg)
		_coll.add_child(row)


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
	# The light runs round the table, slowing down, like a roulette ball.
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
	# Lift, rarity glow, flip.
	_light(b, col, 1.0)
	var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "position:y", b.position.y - 18.0, 0.2)
	tw.parallel().tween_property(b, "scale", Vector2(1.12, 1.12), 0.2)
	tw.tween_interval(0.25)
	tw.tween_property(b, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _show_face(b, got, col))


func _show_face(b: Control, got: Dictionary, col: Color) -> void:
	var id := str(got["id"])
	var info := VaultCards.as_row(id)
	info["level"] = int(got.get("lv", 1))
	var face := PixelCard.new()
	face.info = info
	face.face_up = true
	_grid.add_child(face)
	var k := CW / PixelCard.W
	face.scale = Vector2(k * 0.02, k * 1.12)
	face.position = b.position
	b.visible = false
	var rar := str(got.get("rarity", "common"))
	Rarity.juice(rar, str(got.get("name", "")))
	Juice.play("res://assets/audio/card.wav")
	var mid := _stage.size * 0.5
	# The middle of the screen, in the grid's own coordinates.
	var mid_g := _grid.get_global_transform().affine_inverse() * (_stage.get_global_transform() * mid)
	var center := mid_g - Vector2(PixelCard.W, PixelCard.H) * 0.5
	var tw := face.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(face, "scale:x", k * 1.12, 0.12)
	tw.tween_interval(0.2)
	tw.tween_property(face, "position", center, 0.35).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(face, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func() -> void:
		UiKit.blast(_stage, mid, col, 320.0)
		Juice.pulse_shake(5.0)
		var tag := UiKit.title("NEW CARD!" if bool(got.get("new", false)) else "LV %d  ›  %d" % [int(got["lv"]) - 1, int(got["lv"])], 34, col)
		tag.position = Vector2(0, mid.y + PixelCard.H * 0.5 + 6)
		tag.size = Vector2(_stage.size.x, 44)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		tag.add_theme_constant_override("outline_size", 8)
		_stage.add_child(tag)
		tag.pivot_offset = Vector2(mid.x, 22)
		tag.scale = Vector2(1.6, 1.6)
		tag.create_tween().set_trans(Tween.TRANS_BACK).tween_property(tag, "scale", Vector2.ONE, 0.25)
		var out := create_tween()
		out.tween_interval(1.6)
		out.tween_property(face, "modulate:a", 0.0, 0.25)
		out.parallel().tween_property(tag, "modulate:a", 0.0, 0.25)
		out.tween_callback(func() -> void:
			face.queue_free()
			tag.queue_free()
			# A fresh card is dealt into the empty spot.
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
	)
