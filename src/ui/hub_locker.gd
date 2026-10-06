extends Control

## GEAR: a paperdoll. The fighter stands in the middle in what he wears (his
## hero suit parts drawn live), the slots sit around him (hat, clothes,
## shoes and charms on the left; the suit's MASK, TOP and BOTTOM on the right,
## mixable, with the set bonus under them). Pick a slot and the pieces for it list on
## the right with a picture, the name in its rarity colour and every stat as
## a change against what is worn now: green up, red down.

signal need_refresh

var _role := "son"
var _slot := "top"
var _root: Control
var _list: VBoxContainer

const SLOT_POS := {
	"hat": Vector2(36, 70), "clothes": Vector2(36, 164), "shoes": Vector2(36, 258), "charm": Vector2(36, 352),
	"mask": Vector2(396, 70), "top": Vector2(396, 164), "bottom": Vector2(396, 258),
}
const SLOT_SIZE := Vector2(108, 88)
const STAT_NAMES := {"hp": "HP", "dmg": "DMG", "steam": "STEAM", "speed": "SPD"}


func _ready() -> void:
	if Engine.has_meta("locker_slot"):
		_slot = str(Engine.get_meta("locker_slot"))
		Engine.remove_meta("locker_slot")
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
		if Suits.worn_part(_role, "top") == "bat" or Suits.worn_part(_role, "mask") == "bat":
			var cape := CapeFx.new()
			cape.anim = a
			cape.draw_cape = Suits.worn_part(_role, "top") == "bat"
			cape.draw_ears = Suits.worn_part(_role, "mask") == "bat"
			stage.add_child(cape)
		stage.add_child(a)
		Suits.dress(a, _role)
		a.play("idle")
	var suit := Suits.full_set(_role)
	var srow: Dictionary = Suits.LIST.get(suit, {})
	var mixed := suit == "" and (Suits.worn_part(_role, "mask") + Suits.worn_part(_role, "top") + Suits.worn_part(_role, "bottom")) != ""
	var cap := Label.new()
	cap.text = ("FULL " + str(srow["title"])) if suit != "" else ("MIX & MATCH" if mixed else "STREET CLOTHES")
	cap.position = Vector2(140, 444)
	cap.size = Vector2(260, 24)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(cap, 14, Rarity.color(str(srow.get("rarity", "common"))))
	_root.add_child(cap)
	for slot in SLOT_POS.keys():
		_root.add_child(_slot_box(slot))
	_root.add_child(_set_box())


## Under the suit slots: which set the parts add up to.
func _set_box() -> Control:
	var full := Suits.full_set(_role)
	var p := Panel.new()
	p.position = Vector2(396, 352)
	p.size = SLOT_SIZE
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.08, 0.09, 0.16), UiKit.GOLD if full != "" else Palette.MUTED))
	var best := ""
	var n := 0
	for id: String in Suits.LIST.keys():
		var c := 0
		for part in Suits.PARTS:
			if Suits.worn_part(_role, part) == id:
				c += 1
		if c > n:
			n = c
			best = id
	var t := Label.new()
	t.text = "SET"
	t.position = Vector2(0, 6)
	t.size = Vector2(SLOT_SIZE.x, 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(t, 12, Palette.MUTED)
	p.add_child(t)
	var big := Label.new()
	big.text = "%s %d/3" % [str(Suits.LIST[best]["title"]), n] if best != "" else "NONE"
	big.position = Vector2(0, 28)
	big.size = Vector2(SLOT_SIZE.x, 24)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(big, 16, UiKit.GOLD if full != "" else Palette.TEXT)
	p.add_child(big)
	var pips := Label.new()
	pips.text = ("■ ".repeat(n) + "□ ".repeat(3 - n)).strip_edges()
	pips.position = Vector2(0, 56)
	pips.size = Vector2(SLOT_SIZE.x, 20)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(pips, 14, Rarity.color(str(Suits.LIST[best]["rarity"])) if best != "" else Palette.MUTED)
	p.add_child(pips)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _slot_box(slot: String) -> Control:
	var b := Button.new()
	b.set_meta("slot", slot)
	b.focus_mode = Control.FOCUS_ALL
	Bevel.dress(b)
	UiKit.press_feel(b)
	b.position = SLOT_POS[slot]
	b.custom_minimum_size = SLOT_SIZE
	b.size = SLOT_SIZE
	var col := Palette.MUTED
	var item := {}
	var label := slot.to_upper()
	if slot in ["hat", "clothes", "shoes"]:
		item = GearBook.item(FamilyProfile.equipped_id(_role, slot))
		if not item.is_empty():
			col = Rarity.color(Rarity.normalize(str(item.get("rarity", "common"))))
	elif slot in Suits.PARTS:
		var sid := Suits.worn_part(_role, slot)
		label = Suits.PART_NAMES[slot]
		if Suits.LIST.has(sid):
			col = Rarity.color(str(Suits.LIST[sid]["rarity"]))
	elif slot == "charm":
		label = "CHARMS %d/%d" % [Charms.worn().size(), Charms.MAX_WORN]
		if not Charms.worn().is_empty():
			col = UiKit.GOLD
	var on := _slot == slot
	b.add_theme_stylebox_override("normal", UiKit.panel(Color(0.08, 0.09, 0.16), UiKit.GOLD if on else col))
	for st in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(st, UiKit.panel(Color(0.1, 0.12, 0.2), UiKit.GOLD))
	var pic: Control
	if slot in Suits.PARTS:
		pic = _part_pic(Suits.worn_part(_role, slot), slot, Vector2(56, 56))
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
	pic.position = Vector2(26, 6)
	pic.size = Vector2(56, 56)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var l := Label.new()
	l.text = label
	l.position = Vector2(0, 64)
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


## The fighter wearing just one suit part (the real shader on the idle
## frame, as in game), framed on what the part covers: the head for a mask,
## the torso for a top, the whole body for a bottom.
func _part_pic(id: String, part: String, sz: Vector2) -> Control:
	var box := Control.new()
	box.custom_minimum_size = sz
	box.size = sz
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := _body_tex()
	if tex == null:
		return box
	var h := BloodSim.head_of_tex(tex)
	var r := h.z
	var focus := {"mask": [0.7, 4.6], "top": [3.6, 8.5], "bottom": [5.0, 13.5]}.get(part, [5.0, 13.5]) as Array
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = SpriteBook.UI_FILTER
	var k := sz.y / (r * float(focus[1]))
	spr.scale = Vector2(k, k)
	spr.position = sz * 0.5 - Vector2(h.x, h.y + r * float(focus[0])) * k
	if id != "" and Suits.LIST.has(id):
		var c := Suits.code_of(id)
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/shaders/wound.gdshader")
		m.set_shader_parameter("suit_head", c if part == "mask" else 0)
		m.set_shader_parameter("suit_body", c if part == "top" else 0)
		m.set_shader_parameter("suit_legs", c if part == "bottom" else 0)
		m.set_shader_parameter("head", h)
		spr.material = m
	box.add_child(spr)
	return box


var _body_cache := {}


func _body_tex() -> Texture2D:
	if not _body_cache.has(_role) and SpriteBook.has_who(_role):
		var a := SpriteBook.make_anim(_role)
		if a.sprite_frames.has_animation("idle"):
			_body_cache[_role] = a.sprite_frames.get_frame_texture("idle", 0)
		a.free()
	return _body_cache.get(_role) as Texture2D


## The fighter's own bust in a whole suit (the real shader).
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
		"mask", "top", "bottom":
			_set_strip()
			_list.add_child(_part_card("", _slot))
			for id: String in Suits.LIST.keys():
				_list.add_child(_part_card(id, _slot))
		"charm":
			for id: String in Charms.LIST.keys():
				_list.add_child(_charm_card(id))
		_:
			for item in GearBook.for_slot(_slot, _role):
				_list.add_child(_gear_card(item))


func _card(accent: Color) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.07, 0.08, 0.14), accent))
	Bevel.dress(p, false, 0.7)
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
	var gid := str(item.get("id", ""))
	var lvl := FamilyProfile.gear_level(gid)
	var mul := GearInv.stat_mul(gid)
	var out := {}
	for k in STAT_NAMES.keys():
		var base := int(st.get(k, 0))
		out[k] = int(round(float(base) * mul)) + (lvl if base >= 0 else 0)
	return out


func _gear_card(item: Dictionary) -> Control:
	var id := str(item.get("id", ""))
	var owned := FamilyProfile.owns_gear(id)
	# The best copy owned decides the rarity shown (and worn).
	var rarity := GearInv.tier_name(id) if owned else Rarity.normalize(str(item.get("rarity", "common")))
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
	var copies := ""
	if owned:
		var cs := GearInv.counts(id)
		var parts: Array[String] = []
		for ti in 5:
			if int(cs[ti]) > 0:
				parts.append("%d× %s" % [int(cs[ti]), Rarity.ORDER[ti].to_upper()])
		copies = "  ·  " + "  ".join(parts) + "  ·  LV CAP %d" % GearInv.level_cap(id)
	tag.text = Rarity.label(rarity) + copies + ("  ·  WEARING" if wearing else "")
	UiKit.apply_label(tag, 11, Palette.MUTED)
	v.add_child(tag)
	v.add_child(_delta_row(_item_stats(item), _item_stats(GearBook.item(FamilyProfile.equipped_id(_role, _slot)))))
	var bl := Label.new()
	bl.text = str(item.get("blurb", ""))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(330, 0)
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
		var cost := FamilyProfile.gear_price(id)
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
				UiKit.fx_after(self, "", Rarity.color(rarity), "GOT IT", false)
		)
		btns.add_child(buy)
	if owned:
		# Three alike -> one rarer. Copies come from loot or the counter.
		var ct := GearInv.combinable(id)
		if ct >= 0:
			var short: String = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGEND"][ct + 1]
			var cb := UiKit.button("3× → %s" % short, Vector2(150, 32))
			cb.tooltip_text = "Combine three alike into one %s." % Rarity.ORDER[ct + 1]
			cb.add_theme_color_override("font_color", Rarity.color(Rarity.ORDER[ct + 1]))
			cb.pressed.connect(func() -> void:
				if GearInv.combine(id):
					need_refresh.emit()
					_paint()
					var nr: String = Rarity.ORDER[ct + 1]
					Juice.rewards.reveal(IconBook.for_glyph("shield"), "COMBINED  ·  %s" % Rarity.label(nr), Rarity.color(nr), str(item.get("title", "")))
			)
			btns.add_child(cb)
		var cp := FamilyProfile.gear_price(id)
		var copy := UiKit.button("+COPY  %dG" % cp, Vector2(150, 30))
		copy.disabled = int(FamilyProfile.data.get("gold", 0)) < cp
		copy.pressed.connect(func() -> void:
			if FamilyProfile.try_buy_gear(id):
				need_refresh.emit()
				_paint()
		)
		btns.add_child(copy)
	if owned and lvl < GearInv.level_cap(id):
		var up_cost := int(item.get("upgrade", 20)) * (lvl + 1)
		var up := UiKit.button("UPGRADE  %dG" % up_cost, Vector2(150, 32))
		up.disabled = int(FamilyProfile.data.get("gold", 0)) < up_cost
		up.pressed.connect(func() -> void:
			if FamilyProfile.try_upgrade_gear(id):
				Rarity.juice(rarity, str(item.get("title", "")))
				need_refresh.emit()
				_paint()
				UiKit.fx_after(self, "", Rarity.color(rarity), "LV %d" % (lvl + 1), false)
		)
		btns.add_child(up)
	h.add_child(btns)
	return pair[0]


## Over the part list: one press to put on every suit you own in full.
func _set_strip() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var t := Label.new()
	t.text = "FULL SET:"
	UiKit.apply_label(t, 13, Palette.MUTED)
	row.add_child(t)
	var any := false
	for id: String in Suits.LIST.keys():
		var all := true
		for part in Suits.PARTS:
			all = all and Suits.owned_part(id, part)
		if not all:
			continue
		any = true
		var b := UiKit.button(str(Suits.LIST[id]["title"]), Vector2(120, 32))
		b.disabled = Suits.full_set(_role) == id
		b.pressed.connect(func() -> void:
			Suits.wear(_role, id)
			Rarity.juice(str(Suits.LIST[id]["rarity"]), str(Suits.LIST[id]["title"]))
			need_refresh.emit()
			_paint()
		)
		row.add_child(b)
	if not any:
		var n := Label.new()
		n.text = "collect all three parts of a suit for its set bonus"
		UiKit.apply_label(n, 12, Palette.MUTED)
		row.add_child(n)
	_list.add_child(row)


func _part_card(id: String, part: String) -> Control:
	var suit: Dictionary = Suits.LIST.get(id, {})
	var row: Dictionary = Suits.part_row(id, part) if id != "" else {"title": "NO " + str(Suits.PART_NAMES[part]), "perk": "Street clothes. No perk.", "how": "", "stats": {}}
	var have := id == "" or Suits.owned_part(id, part)
	var worn := Suits.worn_part(_role, part) == id
	var r := str(suit.get("rarity", "common"))
	var pair := _card(UiKit.GOLD if worn else (Rarity.color(r) if have else Palette.MUTED))
	var h: HBoxContainer = pair[1]
	var pic := _part_pic(id, part, Vector2(72, 72))
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	if id != "":
		var tag := Label.new()
		var c := 0
		for p in Suits.PARTS:
			if p == part or Suits.worn_part(_role, p) == id:
				c += 1
		tag.text = "%s  ·  %s SUIT  ·  SET %d/3 IF WORN" % [Rarity.label(r), str(suit["title"]), c]
		UiKit.apply_label(tag, 11, Palette.MUTED)
		v.add_child(tag)
	var cur: Dictionary = Suits.part_row(Suits.worn_part(_role, part), part).get("stats", {})
	v.add_child(_delta_row(row.get("stats", {}), cur))
	var perk := "[color=#ffd75e]PERK[/color]  " + str(row.get("perk", ""))
	if not have:
		perk = "[color=%s]LOCKED  ·  %s[/color]\n%s" % [UiKit.DOWN_COL, str(row.get("how", "")), perk]
	if id != "":
		perk += "\n[color=#9aa3c7]SET  ·  %s[/color]" % str(suit.get("set", ""))
	var pr := UiKit.rich(perk, 400, 12, Palette.TEXT)
	pr.text = pr.text.trim_prefix("[center]").trim_suffix("[/center]")
	v.add_child(pr)
	h.add_child(v)
	var btn := UiKit.button("WEARING" if worn else ("WEAR" if have else "LOCKED"), Vector2(150, 40))
	btn.disabled = worn or not have
	btn.pressed.connect(func() -> void:
		Suits.wear_part(_role, part, id)
		if id != "" and Suits.full_set(_role) == id:
			Juice.unlock_logo(str(suit["title"]) + " SET", str(suit.get("set", "")), "FULL SUIT BONUS")
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
	var full := Suits.full_set(_role)
	if full != "":
		var sb := UiKit.rich("[color=#ffd75e]SET BONUS[/color]  " + str(Suits.LIST[full]["set"]), 700, 13, Palette.TEXT)
		sb.position = Vector2(20, 520)
		_root.add_child(sb)
