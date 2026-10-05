extends Control

## GEAR: a paperdoll. The fighter stands in the middle in what he wears (his
## hero suit drawn live), the slots sit around him (hat, clothes, shoes, the
## suit and three lucky charms). Pick a slot and the pieces for it list on
## the right with a picture, the name in its rarity colour and every stat as
## a change against what is worn now: green up, red down.

signal need_refresh

var _role := "son"
var _slot := "clothes"
var _root: Control
var _list: VBoxContainer

const SLOT_POS := {
	"hat": Vector2(40, 96), "clothes": Vector2(40, 214), "shoes": Vector2(40, 332),
	"suit": Vector2(392, 96), "charm": Vector2(392, 214),
}
const STAT_NAMES := {"hp": "HP", "dmg": "DMG", "steam": "STEAM", "speed": "SPD"}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_paint()


func _paint() -> void:
	for c in _root.get_children():
		c.queue_free()
	var title := UiKit.title("GEAR", 44, Palette.EDGE)
	title.position = Vector2(20, 0)
	_root.add_child(title)
	var roles := HBoxContainer.new()
	roles.position = Vector2(160, 8)
	roles.add_theme_constant_override("separation", 8)
	for pair in [["son", "THE SON"], ["father", "THE FATHER"]]:
		var b := UiKit.button(pair[1], Vector2(160, 38))
		if _role == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			_role = pair[0]
			Juice.play("res://assets/audio/ui_click.wav")
			_paint()
		)
		roles.add_child(b)
	_root.add_child(roles)
	_paperdoll()
	_items_panel()
	_totals_row()
	# Pad: land on the slot being dressed (or the first piece).
	var keep := _slot
	get_tree().process_frame.connect(func() -> void:
		for c in _root.get_children():
			if c is Button and c.has_meta("slot") and str(c.get_meta("slot")) == keep:
				(c as Button).grab_focus()
				return
	, CONNECT_ONE_SHOT)


# --- left: the fighter and his slots -----------------------------------------

func _paperdoll() -> void:
	var frame := Panel.new()
	frame.position = Vector2(20, 60)
	frame.size = Vector2(500, 420)
	frame.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.1, 0.92), UiKit.RIM))
	_root.add_child(frame)
	var glow := TextureRect.new()
	glow.texture = LightRig.radial_tex()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.position = Vector2(150, 90)
	glow.size = Vector2(240, 360)
	glow.modulate = Color(1.0, 0.85, 0.5, 0.35)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(glow)
	var stage := Node2D.new()
	stage.position = Vector2(270, 436)
	_root.add_child(stage)
	if SpriteBook.has_who(_role):
		var a := SpriteBook.make_anim(_role)
		a.scale *= 4.4
		a.position *= 4.4
		a.texture_filter = SpriteBook.UI_FILTER
		stage.add_child(a)
		Suits.dress(a, _role)
		a.play("idle")
	var suit := Suits.worn(_role)
	var srow: Dictionary = Suits.LIST.get(suit, {})
	var cap := Label.new()
	cap.text = str(srow.get("title", "STREET CLOTHES"))
	cap.position = Vector2(140, 444)
	cap.size = Vector2(260, 24)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(cap, 14, Rarity.color(str(srow.get("rarity", "common"))))
	_root.add_child(cap)
	for slot in ["hat", "clothes", "shoes", "suit", "charm"]:
		_root.add_child(_slot_box(slot))


func _slot_box(slot: String) -> Control:
	var b := Button.new()
	b.set_meta("slot", slot)
	b.focus_mode = Control.FOCUS_ALL
	b.position = SLOT_POS[slot]
	b.custom_minimum_size = Vector2(108, 100)
	b.size = Vector2(108, 100)
	var col := Palette.MUTED
	var item := {}
	var label := slot.to_upper()
	if slot in ["hat", "clothes", "shoes"]:
		item = GearBook.item(FamilyProfile.equipped_id(_role, slot))
		if not item.is_empty():
			col = Rarity.color(Rarity.normalize(str(item.get("rarity", "common"))))
	elif slot == "suit" and Suits.LIST.has(Suits.worn(_role)):
		col = Rarity.color(str(Suits.LIST[Suits.worn(_role)]["rarity"]))
	elif slot == "charm":
		label = "CHARMS %d/%d" % [Charms.worn().size(), Charms.MAX_WORN]
		if not Charms.worn().is_empty():
			col = UiKit.GOLD
	var on := _slot == slot
	b.add_theme_stylebox_override("normal", UiKit.panel(Color(0.08, 0.09, 0.16), UiKit.GOLD if on else col))
	for st in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(st, UiKit.panel(Color(0.1, 0.12, 0.2), UiKit.GOLD))
	var pic: Control
	if slot == "suit":
		pic = _suit_pic(Suits.worn(_role), Vector2(64, 64))
	else:
		var gi := GearIcon.new()
		gi.slot = slot
		gi.empty = item.is_empty() and slot != "charm"
		if slot == "charm":
			gi.tint = UiKit.GOLD if not Charms.worn().is_empty() else Color(0.4, 0.4, 0.45)
		else:
			var t: Array = item.get("tint", [0.6, 0.6, 0.65])
			gi.tint = Color(float(t[0]), float(t[1]), float(t[2]))
		pic = gi
	pic.position = Vector2(22, 8)
	pic.size = Vector2(64, 64)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var l := Label.new()
	l.text = label
	l.position = Vector2(0, 74)
	l.size = Vector2(108, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_label(l, 12, UiKit.GOLD if on else Palette.TEXT)
	b.add_child(l)
	b.pressed.connect(func() -> void:
		_slot = slot
		Juice.play("res://assets/audio/ui_click.wav")
		_paint()
	)
	return b


## The fighter's own bust in a suit (the real shader), for the suit slot.
func _suit_pic(id: String, sz: Vector2) -> Control:
	var tr := TextureRect.new()
	tr.texture = SpriteBook.bust(_role)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = SpriteBook.UI_FILTER
	tr.custom_minimum_size = sz
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if id != "" and Suits.LIST.has(id) and tr.texture != null:
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/shaders/wound.gdshader")
		m.set_shader_parameter("suit", int(Suits.LIST[id]["code"]))
		m.set_shader_parameter("head", BloodSim.head_of_tex(tr.texture))
		tr.material = m
	return tr


# --- right: what fits the picked slot ----------------------------------------

func _items_panel() -> void:
	var frame := Panel.new()
	frame.position = Vector2(536, 60)
	frame.size = Vector2(700, 420)
	frame.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.1, 0.92), UiKit.RIM))
	_root.add_child(frame)
	var sc := ScrollContainer.new()
	sc.position = Vector2(546, 70)
	sc.size = Vector2(680, 400)
	_root.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	sc.add_child(_list)
	match _slot:
		"suit":
			_list.add_child(_suit_card(""))
			for id: String in Suits.LIST.keys():
				_list.add_child(_suit_card(id))
		"charm":
			for id: String in Charms.LIST.keys():
				_list.add_child(_charm_card(id))
		_:
			for item in GearBook.for_slot(_slot, _role):
				_list.add_child(_gear_card(item))


func _card(accent: Color) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.07, 0.08, 0.14), accent))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	return [p, h]


## Stat changes against what is worn: "HP 4 (+2)" green, "SPD 0 (-8)" red.
func _delta_row(new_st: Dictionary, old_st: Dictionary) -> RichTextLabel:
	var parts: Array[String] = []
	for k: String in STAT_NAMES.keys():
		var n := int(new_st.get(k, 0))
		var d := n - int(old_st.get(k, 0))
		var tag := "%s %d" % [STAT_NAMES[k], n]
		if d > 0:
			tag += " [color=%s](+%d)[/color]" % [UiKit.UP_COL, d]
		elif d < 0:
			tag += " [color=%s](%d)[/color]" % [UiKit.DOWN_COL, d]
		parts.append(tag)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(380, 0)
	r.add_theme_font_size_override("normal_font_size", 13)
	r.text = "   ".join(parts)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _item_stats(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {}
	var st: Dictionary = item.get("stats", {})
	var lvl := FamilyProfile.gear_level(str(item.get("id", "")))
	var out := {}
	for k in STAT_NAMES.keys():
		out[k] = int(st.get(k, 0)) + lvl
	return out


func _gear_card(item: Dictionary) -> Control:
	var id := str(item.get("id", ""))
	var rarity := Rarity.normalize(str(item.get("rarity", "common")))
	var owned := FamilyProfile.owns_gear(id)
	var wearing := FamilyProfile.equipped_id(_role, _slot) == id
	var pair := _card(UiKit.GOLD if wearing else Rarity.color(rarity))
	var h: HBoxContainer = pair[1]
	var gi := GearIcon.new()
	gi.slot = _slot
	var t: Array = item.get("tint", [0.6, 0.6, 0.65])
	gi.tint = Color(float(t[0]), float(t[1]), float(t[2]))
	gi.custom_minimum_size = Vector2(72, 64)
	h.add_child(gi)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Label.new()
	var lvl := FamilyProfile.gear_level(id)
	nm.text = "%s%s" % [str(item.get("title", "")), ("  +%d" % lvl) if lvl > 0 else ""]
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 18, Rarity.color(rarity))
	v.add_child(nm)
	var tag := Label.new()
	tag.text = Rarity.label(rarity) + ("  ·  WEARING" if wearing else "")
	UiKit.apply_label(tag, 11, Palette.MUTED)
	v.add_child(tag)
	v.add_child(_delta_row(_item_stats(item), _item_stats(GearBook.item(FamilyProfile.equipped_id(_role, _slot)))))
	var bl := Label.new()
	bl.text = str(item.get("blurb", ""))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(380, 0)
	UiKit.apply_label(bl, 12, Palette.TEXT)
	v.add_child(bl)
	h.add_child(v)
	var btns := VBoxContainer.new()
	btns.custom_minimum_size = Vector2(150, 0)
	if wearing:
		var on := UiKit.button(Copy.WEARING, Vector2(150, 36))
		on.disabled = true
		btns.add_child(on)
	elif owned:
		var wear := UiKit.button(Copy.WEAR, Vector2(150, 36))
		wear.pressed.connect(func() -> void:
			if FamilyProfile.wear_slot(_role, _slot, id):
				Rarity.juice(rarity, str(item.get("title", "")))
				need_refresh.emit()
				_paint()
		)
		btns.add_child(wear)
	else:
		var cost := int(item.get("gold", 0))
		var buy := UiKit.button("%d GOLD" % cost if cost > 0 else "CLAIM", Vector2(150, 36))
		var need_gold := int(FamilyProfile.data.get("gold", 0)) < cost
		var need_rep := int(FamilyProfile.data.get("rep", 0)) < int(item.get("rep", 0))
		buy.disabled = need_gold or need_rep
		if need_rep:
			buy.text = "NEED %d REP" % int(item.get("rep", 0))
		elif need_gold:
			buy.text = "NEED %d GOLD" % cost
		buy.pressed.connect(func() -> void:
			if FamilyProfile.try_buy_gear(id):
				Rarity.juice(rarity, str(item.get("title", "")))
				need_refresh.emit()
				_paint()
		)
		btns.add_child(buy)
	if owned and lvl < 3:
		var up_cost := int(item.get("upgrade", 20)) * (lvl + 1)
		var up := UiKit.button("UPGRADE  %dG" % up_cost, Vector2(150, 32))
		up.disabled = int(FamilyProfile.data.get("gold", 0)) < up_cost
		up.pressed.connect(func() -> void:
			if FamilyProfile.try_upgrade_gear(id):
				Rarity.juice(rarity, str(item.get("title", "")))
				need_refresh.emit()
				_paint()
		)
		btns.add_child(up)
	h.add_child(btns)
	return pair[0]


func _suit_card(id: String) -> Control:
	var row: Dictionary = Suits.LIST.get(id, {"title": "STREET CLOTHES", "rarity": "common", "blurb": "Just you. No cape, no cowl.", "how": "", "stats": {}})
	var have := id == "" or Suits.owned(id)
	var worn := Suits.worn(_role) == id
	var r := str(row["rarity"])
	var pair := _card(UiKit.GOLD if worn else (Rarity.color(r) if have else Palette.MUTED))
	var h: HBoxContainer = pair[1]
	var pic := _suit_pic(id, Vector2(72, 72))
	if not have:
		pic.modulate = Color(0.12, 0.12, 0.16)
	h.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Label.new()
	nm.text = str(row["title"]) if have else "??? " + str(row["title"])
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 18, Rarity.color(r) if have else Palette.MUTED)
	v.add_child(nm)
	v.add_child(_delta_row(row.get("stats", {}), Suits.stats(_role)))
	var bl := Label.new()
	bl.text = (str(row["blurb"]) + ("\n" + str(row.get("perk", "")) if str(row.get("perk", "")) != "" else "")) if have else "LOCKED  ·  " + str(row["how"]) + "\n" + str(row.get("perk", ""))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(380, 0)
	UiKit.apply_label(bl, 12, Palette.TEXT if have else Palette.BRICK)
	v.add_child(bl)
	h.add_child(v)
	var btn := UiKit.button("WEARING" if worn else ("WEAR" if have else "LOCKED"), Vector2(150, 40))
	btn.disabled = worn or not have
	btn.pressed.connect(func() -> void:
		Suits.wear(_role, id)
		Juice.play("res://assets/audio/claim.wav")
		need_refresh.emit()
		_paint()
	)
	h.add_child(btn)
	return pair[0]


func _charm_card(id: String) -> Control:
	var row: Dictionary = Charms.LIST[id]
	var has := Charms.owned().has(id)
	var on := Charms.has(id)
	var r := str(row["rarity"])
	var pair := _card(UiKit.GOLD if on else (Rarity.color(r) if has else Palette.MUTED))
	var h: HBoxContainer = pair[1]
	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/loot/charm.png")
	icon.custom_minimum_size = Vector2(56, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not has:
		icon.modulate = Color(0.12, 0.12, 0.16)
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Label.new()
	nm.text = str(row["title"]) if has else "???"
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 18, Rarity.color(r) if has else Palette.MUTED)
	v.add_child(nm)
	v.add_child(UiKit.rich(str(row["blurb"]) if has else "Not found yet. Bosses carry them.", 400, 13, Palette.TEXT))
	h.add_child(v)
	var btn := UiKit.button("TAKE OFF" if on else "WEAR", Vector2(150, 40))
	btn.disabled = not has or (not on and Charms.worn().size() >= Charms.MAX_WORN)
	btn.pressed.connect(func() -> void:
		Charms.toggle(id)
		Juice.play("res://assets/audio/ui_click.wav")
		_paint()
	)
	h.add_child(btn)
	return pair[0]


# --- bottom: what it all adds up to ------------------------------------------

func _totals_row() -> void:
	var bonus := FamilyProfile.gear_stat_bonus(_role)
	var row := HBoxContainer.new()
	row.position = Vector2(20, 490)
	row.add_theme_constant_override("separation", 26)
	_root.add_child(row)
	var t := Label.new()
	t.text = "TOTAL FROM GEAR"
	UiKit.apply_label(t, 14, Palette.MUTED)
	row.add_child(t)
	for k: String in STAT_NAMES.keys():
		var v := int(bonus.get(k, 0))
		var l := Label.new()
		l.text = "%s %s%d" % [STAT_NAMES[k], "+" if v >= 0 else "", v]
		l.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(l, 18, Color(0.36, 1.0, 0.54) if v > 0 else (Color(1.0, 0.35, 0.29) if v < 0 else Palette.TEXT))
		row.add_child(l)
