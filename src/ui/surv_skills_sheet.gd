extends Control

## ACTIVE SKILLS (survivor lobby). The two slots up top (SKILL 1 = LB / Q,
## SKILL 2 = LT / E) and every active below as a tile. Focus a tile to see
## it big with its cooldown and power; UNLOCK / LEVEL UP with S-COINS and
## put it in slot 1 or 2. Everything else in a run is a level-up card (see
## SURVIVOR CARDS).

signal closed

const ACCENT := Color(0.45, 1.0, 0.6)

var _sel := ""
var _wallet: Label
var _detail: VBoxContainer
var _slot_tiles: Array = []
var _focus_key := ""


func _ready() -> void:
	_sel = str(SurvActives.slots()[0]) if not SurvActives.slots().is_empty() else "frag"
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
	card.add_theme_stylebox_override("panel", UiKit.frame(ACCENT, 0.4))
	card.position = Vector2(30, 24)
	card.size = Vector2(1220, 672)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var t := UiKit.title("ACTIVE SKILLS", 28, ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var wi := IconBook.rect("cur_scoin", IconBook.SIZE_S)
	head.add_child(wi)
	Juice.rewards.register("tokens", wi)
	_wallet = Label.new()
	_wallet.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_wallet, 22, Palette.TEXT)
	_wallet.custom_minimum_size = Vector2(80, 0)
	_wallet.text = str(_coins() - Juice.rewards.pending("tokens"))
	head.add_child(_wallet)
	var close := UiKit.button("CLOSE", Vector2(110, 44))
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	col.add_child(head)
	var tip := Label.new()
	tip.text = "Two skills ride with you into the hour. Everything else comes from level-up cards."
	UiKit.apply_label(tip, 14, Color(0.7, 0.72, 0.78))
	col.add_child(tip)
	# The two slots.
	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 16)
	col.add_child(slots_row)
	var sl := SurvActives.slots()
	for i in 2:
		slots_row.add_child(_slot(i, str(sl[i]) if i < sl.size() else ""))
	# Every skill.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for id: String in SurvActives.ORDER:
		grid.add_child(_tile(id))
	_detail = VBoxContainer.new()
	_detail.custom_minimum_size = Vector2(420, 0)
	_detail.add_theme_constant_override("separation", 8)
	body.add_child(_detail)
	_show(_sel)
	UiKit.pop_in(card)
	var want := _focus_key if _focus_key != "" else "sk_" + _sel
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and not (b as Button).disabled:
				(b as Button).grab_focus()
				return
		close.grab_focus()
	, CONNECT_ONE_SHOT)


func _slot(i: int, id: String) -> Control:
	var box := PanelContainer.new()
	var sb := UiKit.panel(Color(0.03, 0.05, 0.06), ACCENT)
	sb.set_border_width_all(3)
	box.add_theme_stylebox_override("panel", sb)
	box.custom_minimum_size = Vector2(380, 84)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var key := Label.new()
	key.text = "SKILL %d\n%s" % [i + 1, "LB  ·  Q" if i == 0 else "LT  ·  E"]
	UiKit.apply_label(key, 14, Palette.LEMON)
	key.custom_minimum_size = Vector2(90, 0)
	row.add_child(key)
	if id != "":
		var ic := IconBook.rect(str(SurvActives.LIST[id]["icon"]), IconBook.SIZE_M)
		row.add_child(ic)
		var nm := Label.new()
		nm.text = "%s\nLV %d  ·  %.1fs" % [str(SurvActives.LIST[id]["name"]), SurvActives.level(id), SurvActives.cooldown(id)]
		nm.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(nm, 16, Palette.TEXT)
		row.add_child(nm)
	_slot_tiles.append(box)
	return box


func _tile(id: String) -> Button:
	var own := SurvActives.owned(id)
	var on := SurvActives.slots().has(id)
	var rc := ACCENT if on else (Color(0.6, 0.65, 0.75) if own else Color(0.28, 0.29, 0.33))
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 132)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "sk_" + id)
	var sb := UiKit.panel(Color(0.05, 0.07, 0.09) if own else Color(0.03, 0.03, 0.05), rc)
	sb.set_border_width_all(3)
	var hi := sb.duplicate() as StyleBoxFlat
	hi.border_color = Color.WHITE.lerp(rc, 0.4)
	hi.shadow_color = Color(rc.r, rc.g, rc.b, 0.7)
	hi.shadow_size = 12
	b.add_theme_stylebox_override("normal", sb)
	for s in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(s, hi)
	var ic := IconBook.rect(str(SurvActives.LIST[id]["icon"]), IconBook.SIZE_M)
	ic.position = Vector2(53, 10)
	if not own:
		ic.modulate = Color(0.25, 0.25, 0.3, 0.9)
	b.add_child(ic)
	var nm := Label.new()
	nm.text = str(SurvActives.LIST[id]["name"])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	UiKit.apply_label(nm, 13, Palette.TEXT if own else Color(0.6, 0.6, 0.65))
	nm.position = Vector2(4, 78)
	nm.size = Vector2(162, 18)
	b.add_child(nm)
	var sub := Label.new()
	sub.text = ("SLOT %d" % (SurvActives.slots().find(id) + 1)) if on else ("LV %d" % SurvActives.level(id) if own else "%d S-COINS" % SurvActives.unlock_cost(id))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(sub, 12, ACCENT if on else (Palette.LEMON if not own else Color(0.75, 0.78, 0.85)))
	sub.position = Vector2(4, 100)
	sub.size = Vector2(162, 18)
	b.add_child(sub)
	b.focus_entered.connect(func() -> void:
		_sel = id
		_show(id))
	b.mouse_entered.connect(func() -> void:
		_sel = id
		_show(id))
	b.pressed.connect(func() -> void: _main_action(id, b))
	return b


func _show(id: String) -> void:
	if _detail == null:
		return
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	var spec: Dictionary = SurvActives.LIST[id]
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_detail.add_child(top)
	top.add_child(IconBook.rect(str(spec["icon"]), IconBook.SIZE_L))
	var tl := VBoxContainer.new()
	top.add_child(tl)
	var nm := UiKit.title(str(spec["name"]), 24, ACCENT)
	tl.add_child(nm)
	var lv := SurvActives.level(id)
	var st := Label.new()
	st.text = ("LEVEL %d / %d" % [lv, SurvActives.MAX_LV]) if lv > 0 else "LOCKED"
	UiKit.apply_label(st, 16, Palette.LEMON)
	tl.add_child(st)
	var bl := Label.new()
	bl.text = str(spec["blurb"])
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(400, 0)
	UiKit.apply_label(bl, 15, Palette.TEXT)
	_detail.add_child(bl)
	# Numbers: now -> next level (white now, green next).
	var lines := RichTextLabel.new()
	lines.bbcode_enabled = true
	lines.fit_content = true
	lines.scroll_active = false
	lines.custom_minimum_size = Vector2(400, 60)
	lines.add_theme_font_size_override("normal_font_size", 15)
	var cd := SurvActives.cooldown(id)
	var pw := SurvActives.power(id)
	var t := "COOLDOWN  [color=#ffffff]%.1fs[/color]" % cd
	var t2 := "POWER  [color=#ffffff]%d%%[/color]" % int(round(pw * 100.0))
	if lv > 0 and lv < SurvActives.MAX_LV:
		t += "  →  [color=#7dff8a]%.1fs[/color]" % (cd * 0.92)
		t2 += "  →  [color=#7dff8a]%d%%[/color]" % int(round((pw + 0.15) * 100.0))
	lines.text = t + "\n" + t2
	_detail.add_child(lines)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	_detail.add_child(acts)
	if lv <= 0:
		var u := UiKit.button("UNLOCK  ·  %d" % SurvActives.unlock_cost(id), Vector2(240, 48))
		u.set_meta("key", "unlock_" + id)
		u.disabled = _coins() < SurvActives.unlock_cost(id)
		u.pressed.connect(func() -> void: _main_action(id, u))
		acts.add_child(u)
		return
	if lv < SurvActives.MAX_LV:
		var up := UiKit.button("LEVEL UP  ·  %d" % SurvActives.level_cost(id), Vector2(220, 48))
		up.set_meta("key", "lvl_" + id)
		up.disabled = _coins() < SurvActives.level_cost(id)
		up.pressed.connect(func() -> void:
			if SurvActives.level_up(id):
				_focus_key = "lvl_" + id
				_paint()
				UiKit.fx_after(self, "sk_" + id, ACCENT, "LV %d" % SurvActives.level(id), SurvActives.level(id) >= SurvActives.MAX_LV)
			else:
				Juice.rewards.deny(up))
		acts.add_child(up)
	for i in 2:
		var e := UiKit.button("TO SLOT %d" % (i + 1), Vector2(130, 48))
		e.set_meta("key", "slot%d_%s" % [i, id])
		e.disabled = SurvActives.slots().size() > i and str(SurvActives.slots()[i]) == id
		var slot_i := i
		e.pressed.connect(func() -> void: _equip(slot_i, id))
		acts.add_child(e)


## A on a tile: locked -> unlock; owned and not slotted -> slot 1 (or the
## free one); slotted -> nothing (use the buttons on the right).
func _main_action(id: String, from: Control) -> void:
	if not SurvActives.owned(id):
		if SurvActives.unlock(id):
			Juice.rewards.reveal(str(SurvActives.LIST[id]["icon"]), str(SurvActives.LIST[id]["name"]), ACCENT, "NEW ACTIVE SKILL", 1.0)
			_focus_key = "sk_" + id
			_paint()
		else:
			Juice.rewards.deny(from)
		return
	if SurvActives.slots().has(id):
		return
	_equip(0, id)


func _equip(slot: int, id: String) -> void:
	SurvActives.equip(slot, id)
	_focus_key = "sk_" + id
	_paint()
	var to: Control = _slot_tiles[slot] if slot < _slot_tiles.size() else null
	Juice.rewards.equip(str(SurvActives.LIST[id]["icon"]), "SKILL %d  ·  %s" % [slot + 1, str(SurvActives.LIST[id]["name"])], ACCENT, to)
