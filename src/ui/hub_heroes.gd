extends Control

## HEROES: the Son and the Father as characters to grow. Left, both heroes:
## level (gold, capped by rarity), rarity (grey -> orange, with character
## shards at the cap), what it adds. Right, META: permanent BODY and PARKOUR
## upgrades for gold and gems (parkour ranks also need lifetime tricks).

signal need_refresh

var _root: Control
var _branch := "body"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_paint()


func _paint(keep: String = "") -> void:
	for c in _root.get_children():
		c.queue_free()
	var title := UiKit.title("HEROES", 44, Palette.EDGE)
	title.position = Vector2(20, 0)
	_root.add_child(title)
	var col := VBoxContainer.new()
	col.position = Vector2(20, 60)
	col.add_theme_constant_override("separation", 10)
	_root.add_child(col)
	for role in Heroes.ROLES:
		col.add_child(_hero_card(role))
	_meta_panel()
	FamilyProfile.mark_seen("heroes")
	get_tree().process_frame.connect(func() -> void:
		var want := keep
		for b in _all_buttons(_root):
			if want != "" and b.has_meta("key") and str(b.get_meta("key")) == want and not b.disabled:
				b.grab_focus()
				return
		UiKit.focus_first(_root)
	, CONNECT_ONE_SHOT)


func _all_buttons(n: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out


func _hero_card(role: String) -> Control:
	var rn := Heroes.rarity_name(role)
	var rc := Rarity.color(rn)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(556, 206)
	p.size = Vector2(556, 206)
	p.clip_contents = true
	var st := UiKit.panel(Rarity.fill(rn), rc)
	st.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var face := UiKit.portrait(SpriteBook.bust(role), Vector2(100, 140))
	face.custom_minimum_size = Vector2(100, 140)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)
	var nm := Label.new()
	nm.text = "%s  ·  %s" % [(FamilyProfile.son_name() if role == "son" else FamilyProfile.father_name()).to_upper(), rn.to_upper()]
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 20, rc)
	v.add_child(nm)
	var lv := Heroes.level(role)
	var cap := Heroes.cap(role)
	var lr := HBoxContainer.new()
	lr.add_theme_constant_override("separation", 8)
	var ll := Label.new()
	ll.text = "LV %d / %d" % [lv, cap]
	UiKit.apply_label(ll, 15, Palette.TEXT)
	ll.custom_minimum_size = Vector2(110, 0)
	lr.add_child(ll)
	var bar := UiKit.glow_bar(float(lv) / float(cap), rc, Vector2(240, 10))
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lr.add_child(bar)
	v.add_child(lr)
	var c := Heroes.rank_cost(role)
	var need := int(c.get("shards", 0))
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 8)
	var shard_icon := TextureRect.new()
	shard_icon.texture = load("res://assets/sprites/loot/shard_%s.png" % role)
	shard_icon.custom_minimum_size = Vector2(16, 22)
	shard_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shard_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sr.add_child(shard_icon)
	var sl := Label.new()
	sl.text = ("SHARDS %d / %d" % [Heroes.shards(role), need]) if not c.is_empty() else "SHARDS %d  ·  MAX RARITY" % Heroes.shards(role)
	sl.custom_minimum_size = Vector2(150, 0)
	UiKit.apply_label(sl, 13, Palette.TEXT)
	sr.add_child(sl)
	if not c.is_empty():
		var sb := UiKit.glow_bar(clampf(float(Heroes.shards(role)) / float(maxi(1, need)), 0.0, 1.0), Rarity.color(Rarity.ORDER[Heroes.rarity(role) + 1]), Vector2(180, 8))
		sb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sr.add_child(sb)
	v.add_child(sr)
	v.add_child(UiKit.rich("HP [color=%s]+%d[/color]   DMG [color=%s]x%.2f[/color]   SPD [color=%s]+%d[/color]   POWER %d" % [UiKit.UP_COL, Heroes.hp_bonus(role), UiKit.UP_COL, Heroes.dmg_mul(role), UiKit.UP_COL, int(Heroes.speed_bonus(role)), Heroes.power(role)], 400, 13, Palette.TEXT))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	var up := UiKit.button("LEVEL UP  %dG" % Heroes.level_cost(role) if lv < cap else "LEVEL CAP", Vector2(170, 40))
	up.set_meta("key", "lv_" + role)
	up.disabled = not Heroes.can_level(role)
	up.pressed.connect(func() -> void:
		if Heroes.try_level(role):
			Juice.play("res://assets/audio/claim.wav")
			Juice.shout("LEVEL %d" % Heroes.level(role))
			Juice.claim_burst(up.get_global_rect().get_center(), "LV %d" % Heroes.level(role), 0, 0)
			need_refresh.emit()
			_paint("lv_" + role)
	)
	btns.add_child(up)
	var rk_text := "MAX"
	if not c.is_empty():
		rk_text = "%s  %dS %dG" % [Rarity.ORDER[Heroes.rarity(role) + 1].to_upper(), need, int(c["gold"])]
	var rk := UiKit.button(rk_text, Vector2(220, 40))
	rk.set_meta("key", "rk_" + role)
	rk.disabled = not Heroes.can_rank(role)
	if not c.is_empty():
		rk.add_theme_color_override("font_color", Rarity.color(Rarity.ORDER[Heroes.rarity(role) + 1]))
	rk.tooltip_text = "Reach LV %d, then spend shards to raise rarity (+5 level cap)." % cap
	rk.pressed.connect(func() -> void:
		if Heroes.try_rank(role):
			need_refresh.emit()
			_paint("rk_" + role)
	)
	btns.add_child(rk)
	v.add_child(btns)
	return p


func _meta_panel() -> void:
	var frame := Panel.new()
	frame.position = Vector2(596, 60)
	frame.size = Vector2(640, 422)
	frame.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.1, 0.92), UiKit.RIM))
	_root.add_child(frame)
	var head := HBoxContainer.new()
	head.position = Vector2(610, 68)
	head.add_theme_constant_override("separation", 8)
	_root.add_child(head)
	var t := UiKit.title("META", 24, Palette.EDGE)
	head.add_child(t)
	for pair in [["body", "BRAWL"], ["survivor", "SURVIVOR"], ["parkour", "PARKOUR"]]:
		var b := UiKit.button(pair[1], Vector2(124, 34))
		b.set_meta("key", "br_" + pair[0])
		if _branch == pair[0]:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		b.pressed.connect(func() -> void:
			_branch = pair[0]
			Juice.play("res://assets/audio/ui_click.wav")
			_paint("br_" + pair[0])
		)
		head.add_child(b)
	var tl := Label.new()
	var cur := str(Meta.BRANCH_CUR.get(_branch, "gold"))
	tl.text = "  %s %d" % [cur.to_upper(), int(FamilyProfile.data.get(cur, 0))]
	UiKit.apply_label(tl, 13, Palette.MUTED)
	head.add_child(tl)
	var sc := ScrollContainer.new()
	sc.position = Vector2(606, 112)
	sc.size = Vector2(620, 362)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	sc.add_child(list)
	for id: String in Meta.LIST.keys():
		if str(Meta.LIST[id]["branch"]) == _branch:
			list.add_child(_meta_row(id))


func _meta_row(id: String) -> Control:
	var row: Dictionary = Meta.LIST[id]
	var r := Meta.rank(id)
	var mx := Meta.max_rank(id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.07, 0.08, 0.14), UiKit.GOLD if r >= mx else Palette.MUTED))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Label.new()
	nm.text = "%s   %s" % [str(row["title"]), "■".repeat(r) + "□".repeat(mx - r)]
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 16, UiKit.GOLD if r > 0 else Palette.TEXT)
	v.add_child(nm)
	var ln := Label.new()
	ln.text = str(row["line"])
	ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ln.custom_minimum_size = Vector2(380, 0)
	UiKit.apply_label(ln, 12, Palette.MUTED)
	v.add_child(ln)
	h.add_child(v)
	var why := Meta.blocker(id)
	var c := Meta.cost(id)
	var txt := "MAXED"
	if r < mx:
		var unit: String = {"gold": "G", "tokens": " TOK", "flow": " FLOW"}.get(str(c["cur"]), "")
		txt = "%d%s%s" % [int(c["price"]), unit, ("  %d GEMS" % int(c["gems"])) if int(c["gems"]) > 0 else ""]
	var b := UiKit.button(txt, Vector2(170, 40))
	b.set_meta("key", "meta_" + id)
	b.disabled = why != ""
	b.pressed.connect(func() -> void:
		if Meta.try_buy(id):
			Juice.play("res://assets/audio/claim.wav")
			Juice.shout(str(row["title"]))
			need_refresh.emit()
			_paint("meta_" + id)
	)
	h.add_child(b)
	return p
