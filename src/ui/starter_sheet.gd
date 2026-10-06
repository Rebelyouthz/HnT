extends Control

## STARTER WEAPON for the coping hour: every starter as a pixel tile in its
## rarity frame (locked ones dark with the challenge that opens them). The
## focused one shows big with its numbers: LEVEL UP (S-COINS, damage grey ->
## green), MERGE copies into the next rarity (hold), two MOD slots from six
## mods, and PICK to walk in with it. CHALLENGES list on the right.

signal closed

const ACCENT := Color(1.0, 0.7, 0.3)

var _sel := ""
var _focus_key := ""
var _wallet: Label
var _wallet_icon: Control
var _detail: VBoxContainer


func _ready() -> void:
	Guides.show(self, "starter")
	_sel = SurvStarter.picked() if SurvStarter.picked() != "" else "invoice_toss"
	_paint()


func _coins() -> int:
	return int(FamilyProfile.data.get("tokens", 0))


func _icon(id: String) -> String:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
	if d is Dictionary:
		for a: Dictionary in (d as Dictionary).get("abilities", []):
			if str(a.get("id", "")) == id:
				return str(a.get("icon", "bolt"))
	return "bolt"


func _name(id: String) -> String:
	for e: Array in Discover.catalog("ability"):
		if str(e[0]) == id:
			return str(e[1])
	return id.to_upper()


func _paint() -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(ACCENT, 0.4))
	card.position = Vector2(30, 24)
	card.size = Vector2(1220, 672)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var t := UiKit.title("STARTER WEAPON", 28, ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_wallet_icon = IconBook.rect("cur_scoin", IconBook.SIZE_S)
	head.add_child(_wallet_icon)
	Juice.rewards.register("tokens", _wallet_icon)
	_wallet = Label.new()
	_wallet.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_wallet, 22, Palette.TEXT)
	_wallet.custom_minimum_size = Vector2(80, 0)
	_wallet.text = str(_coins() - Juice.rewards.pending("tokens"))
	head.add_child(_wallet)
	var close := _btn("CLOSE", Vector2(110, 44), "close")
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	col.add_child(head)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(780, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	left.add_child(grid)
	for id: String in SurvStarter.LIST:
		grid.add_child(_tile(id))
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	left.add_child(_detail)
	_show(_sel)
	body.add_child(_challenges())
	UiKit.pop_in(card)
	var want := _focus_key if _focus_key != "" else "st_" + _sel
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and not (b as Button).disabled:
				(b as Button).grab_focus()
				return
		close.grab_focus()
	, CONNECT_ONE_SHOT)


func _tile(id: String) -> Button:
	var open := SurvStarter.unlocked(id)
	var rar := SurvStarter.rarity(id)
	var rc := Rarity.color(rar) if open else Color(0.28, 0.29, 0.33)
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 138)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "st_" + id)
	var sb := UiKit.panel(Rarity.fill(rar) if open else Color(0.04, 0.04, 0.06), rc)
	sb.set_border_width_all(3)
	var hi := sb.duplicate() as StyleBoxFlat
	hi.border_color = Color.WHITE.lerp(rc, 0.4)
	hi.shadow_color = Color(rc.r, rc.g, rc.b, 0.7)
	hi.shadow_size = 12
	b.add_theme_stylebox_override("normal", sb)
	for s in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(s, hi)
	var ic := IconBook.rect(_icon(id), IconBook.SIZE_M)
	ic.position = Vector2(43, 10)
	if not open:
		ic.modulate = Color(0, 0, 0.02, 0.85)
	b.add_child(ic)
	if not open:
		var lk := IconBook.rect("cur_lock", IconBook.SIZE_S)
		lk.position = Vector2(54, 22)
		b.add_child(lk)
	var nm := Label.new()
	nm.text = _name(id) if open else "LOCKED"
	nm.clip_text = true
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(3, 78)
	nm.size = Vector2(144, 14)
	nm.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(nm, 9, rc.lerp(Color.WHITE, 0.35) if open else Palette.MUTED)
	b.add_child(nm)
	var lv := Label.new()
	lv.text = ("LV %d  ·  x%d" % [SurvStarter.level(id), SurvStarter.copies(id)]) if open else "CHALLENGE"
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.position = Vector2(3, 96)
	lv.size = Vector2(144, 14)
	lv.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(lv, 10, Palette.TEXT if open else Palette.MUTED)
	b.add_child(lv)
	if id == SurvStarter.picked():
		var pk := Label.new()
		pk.text = "PICKED"
		pk.position = Vector2(6, 4)
		pk.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(pk, 9, Palette.READY)
		b.add_child(pk)
	if open and SurvStarter.can_merge(id):
		var dot := UiKit.new_dot()
		dot.position = Vector2(138, -4)
		b.add_child(dot)
	b.focus_entered.connect(func() -> void: _show(id))
	b.mouse_entered.connect(func() -> void: _show(id))
	b.pressed.connect(func() -> void:
		if not open:
			Juice.rewards.deny(b)
			return
		SurvStarter.pick(id)
		_sel = id
		_focus_key = "st_" + id
		_paint()
		UiKit.fx_after(self, "st_" + id, Rarity.color(rar), "PICKED", false))
	return b


func _show(id: String) -> void:
	_sel = id
	if _detail == null:
		return
	for c in _detail.get_children():
		c.queue_free()
	var open := SurvStarter.unlocked(id)
	var rar := SurvStarter.rarity(id)
	var rc := Rarity.color(rar)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.07), rc if open else Palette.MUTED))
	_detail.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	row.add_child(IconBook.rect(_icon(id), IconBook.SIZE_L))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var nm := Label.new()
	nm.text = "%s  ·  %s" % [_name(id), Rarity.label(rar)] if open else _name(id)
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 17, rc.lerp(Color.WHITE, 0.3))
	info.add_child(nm)
	if not open:
		var need := str(SurvStarter.LIST[id])
		var c: Dictionary = SurvChallenges.LIST.get(need, {})
		info.add_child(UiKit.rich("LOCKED  ·  challenge [color=#ffd75e]%s[/color]: %s" % [str(c.get("title", need)), str(c.get("line", ""))], 520, 13, Palette.TEXT))
		return
	# Damage now -> after a level, grey then green.
	var lv := SurvStarter.level(id)
	var r := int(SurvStarter.w(id).get("rar", 0))
	var now := (1.0 + 0.08 * float(lv - 1)) * (1.0 + 0.15 * float(r))
	var nxt := (1.0 + 0.08 * float(lv)) * (1.0 + 0.15 * float(r))
	var mrg := (1.0 + 0.08 * float(lv - 1)) * (1.0 + 0.15 * float(mini(4, r + 1)))
	var lines := UiKit.rich("", 520, 13, Palette.TEXT)
	lines.text = "DAMAGE  %s  (LEVEL)    ·    %s  (MERGE)\nCOPIES %d / %d  ·  MODS %d / %d" % [UiKit.delta_bb(now, nxt, "x%.2f"), UiKit.delta_bb(now, mrg if r < 4 else now, "x%.2f"), SurvStarter.copies(id), SurvStarter.MERGE_COPIES, SurvStarter.mods(id).size(), SurvStarter.MOD_SLOTS]
	info.add_child(lines)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	info.add_child(btns)
	var lb := _btn(("LV UP  %d" % SurvStarter.lv_price(id)) if lv < SurvStarter.MAX_LV else "MAX LEVEL", Vector2(160, 38), "lv")
	lb.disabled = lv >= SurvStarter.MAX_LV
	lb.pressed.connect(func() -> void:
		var price := SurvStarter.lv_price(id)
		if not SurvStarter.level_up(id):
			Juice.rewards.deny(lb)
			return
		_spend(price, lb)
		_focus_key = "lv"
		_paint()
		UiKit.fx_after(self, "st_" + id, rc, "LV %d" % SurvStarter.level(id), SurvStarter.level(id) >= SurvStarter.MAX_LV))
	btns.add_child(lb)
	var mb := _btn("MERGE x%d" % SurvStarter.MERGE_COPIES, Vector2(150, 38), "merge")
	mb.disabled = not SurvStarter.can_merge(id)
	UiKit.hold_confirm(mb, func() -> void:
		if SurvStarter.merge(id):
			var nr := SurvStarter.rarity(id)
			Rarity.juice(nr, _name(id))
			Juice.rewards.reveal(_icon(id), "MERGED  ·  %s" % Rarity.label(nr), Rarity.color(nr), _name(id))
			_paint())
	btns.add_child(mb)
	# Mods.
	var mods := HFlowContainer.new()
	mods.add_theme_constant_override("h_separation", 6)
	mods.add_theme_constant_override("v_separation", 6)
	_detail.add_child(mods)
	for m: String in SurvStarter.MODS:
		var spec: Dictionary = SurvStarter.MODS[m]
		var on := SurvStarter.mods(id).has(m)
		var full := SurvStarter.mods(id).size() >= SurvStarter.MOD_SLOTS
		var mbt := _btn(("ON  " if on else "") + str(spec["title"]) + ("" if on else "  %d" % int(spec["price"])), Vector2(184, 32), "mod_" + m)
		var mi := IconBook.rect(str({"heavy": "t_dmg", "rapid": "t_cd", "wide": "t_area", "twin": "meta_amount", "leech": "t_vamp", "crit": "t_crit"}.get(m, "bolt")), 24)
		mi.position = Vector2(6, 4)
		mbt.add_child(mi)
		mbt.tooltip_text = str(spec["line"])
		if on:
			mbt.add_theme_color_override("font_color", Palette.READY)
		mbt.disabled = not on and full
		mbt.pressed.connect(func() -> void:
			if on:
				SurvStarter.drop_mod(id, m)
				RewardFly.snd("part_off")
				_focus_key = "mod_" + m
				_paint()
				return
			var price := int(spec["price"])
			if not SurvStarter.buy_mod(id, m):
				Juice.rewards.deny(mbt)
				return
			_spend(price, mbt)
			RewardFly.snd("part_click")
			_focus_key = "mod_" + m
			_paint()
			UiKit.fx_after(self, "mod_" + m, ACCENT, str(spec["title"]), false))
		mods.add_child(mbt)


func _challenges() -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.08), Color(0.3, 0.32, 0.4)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var t := Label.new()
	t.text = "CHALLENGES"
	t.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(t, 16, UiKit.GOLD)
	v.add_child(t)
	for id: String in SurvChallenges.LIST:
		var c: Dictionary = SurvChallenges.LIST[id]
		var done := SurvChallenges.done(id)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		var ic := IconBook.rect("node_crown" if done else "cur_lock", 28)
		h.add_child(ic)
		var best := SurvChallenges.best(str(c["stat"]))
		var txt := "[color=%s]%s[/color]  %s  [color=#8a8c98]%d/%d[/color]" % ["#7dffa0" if done else "#ffd75e", str(c["title"]), str(c["line"]), mini(best, int(c["goal"])), int(c["goal"])]
		var rl := UiKit.rich("", 330, 10, Palette.TEXT)
		rl.text = txt
		h.add_child(rl)
		v.add_child(h)
	return p


func _spend(n: int, to: Control) -> void:
	var tex := IconBook.tex("cur_scoin_s")
	var from := RewardFly.vp_of(_wallet_icon)
	var dest := RewardFly.vp_of(to)
	for k in clampi(n / 15, 3, 10):
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = from
		Juice.rewards.add_child(s)
		var bend := Vector2(randf_range(-50, 50), randf_range(-30, 30))
		var tw := s.create_tween()
		tw.tween_interval(0.035 * float(k))
		tw.tween_method(func(tt: float) -> void:
			var mid := (from + dest) * 0.5 + bend
			s.position = from.lerp(mid, tt).lerp(mid.lerp(dest, tt), tt).round()
		, 0.0, 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			RewardFly.snd("coin_tick", 1.2 + 0.08 * float(k), -6.0)
			s.queue_free())


func _btn(txt: String, sz: Vector2, key: String) -> Button:
	var b := UiKit.button(txt, sz)
	b.add_theme_font_size_override("font_size", 11)
	b.set_meta("key", key)
	return b
