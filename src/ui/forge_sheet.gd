extends Control

## THE FORGE (Ember's anvil in the hideout yard, also on the hub's clinic
## page). Two tabs: FORGE (recipes: gold + materials -> a gear piece with
## stats or a tempered weapon, made on the anvil with three timed hammer
## strikes) and SMELT (spare gear copies -> iron, leather, cloth, cores).
## The materials bar along the top counts up as things melt.

signal closed
signal need_refresh

const EMBER_LINES := [
	"Bring me junk, I'll bring you armor. That's the whole business model.",
	"Hit when it glows. Not before. Not after. Glows.",
	"Three good strikes and it comes out rarer. Two bad ones and it comes out... educational.",
	"Clamp King had me welding wheel boots for two years. This is way more fun.",
]

var _tab := "forge"
var _body: VBoxContainer
var _mats: HBoxContainer
var _quip: Label
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Color(0.09, 0.06, 0.05, 0.98), Color(0.95, 0.5, 0.2)))
	# Under the hideout's BACK button, clear of the purse row.
	card.position = Vector2(150, 104)
	card.size = Vector2(980, 600)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	# Header: anvil, title, Ember with a line.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.add_child(IconBook.rect("forge_anvil", IconBook.SIZE_M))
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiKit.title("THE FORGE", 30, Color(1.0, 0.62, 0.25)))
	_quip = Label.new()
	_quip.text = "EMBER  ·  \"%s\"" % EMBER_LINES[randi() % EMBER_LINES.size()]
	_quip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quip.custom_minimum_size = Vector2(620, 0)
	UiKit.apply_label(_quip, 13, Palette.MUTED)
	tv.add_child(_quip)
	head.add_child(tv)
	var face := SpriteBook.bust("ember") if SpriteBook.has_who("ember") else CrewNPC.bust("ember")
	if face != null:
		var p := UiKit.portrait(face, Vector2(84, 84))
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(p)
	col.add_child(head)
	_mats = HBoxContainer.new()
	_mats.add_theme_constant_override("separation", 18)
	col.add_child(_mats)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	for t in [["forge", "FORGE  ·  MAKE"], ["smelt", "SMELT  ·  MELT DOWN"]]:
		var b := UiKit.button(str(t[1]), Vector2(240, 40))
		b.set_meta("key", "forge_tab_" + str(t[0]))
		var id := str(t[0])
		b.pressed.connect(func() -> void:
			_tab = id
			_fill()
		)
		tabs.add_child(b)
	var close := UiKit.button("CLOSE", Vector2(130, 40))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	tabs.add_child(close)
	col.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(960, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_body)
	Juice.rewards.register("gold", _mats)
	_fill()
	Guides.show(self, "forge", 0.4)


func _refresh_mats() -> void:
	for c in _mats.get_children():
		c.queue_free()
	var g := HBoxContainer.new()
	g.add_child(IconBook.rect("cur_gold", IconBook.SIZE_S))
	var gl := Label.new()
	gl.text = str(int(FamilyProfile.data.get("gold", 0)) - Juice.rewards.pending("gold"))
	UiKit.apply_label(gl, 18, Color(1.0, 0.85, 0.35))
	g.add_child(gl)
	_mats.add_child(g)
	for m in ForgeBook.MATS:
		var h := HBoxContainer.new()
		h.add_child(IconBook.rect("part_" + str(m), IconBook.SIZE_S))
		var l := Label.new()
		l.text = "%s %d" % [str(ForgeBook.MAT_NAME[m]), ForgeBook.have(str(m))]
		UiKit.apply_label(l, 15, Palette.TEXT)
		h.add_child(l)
		_mats.add_child(h)


func _fill() -> void:
	_refresh_mats()
	for c in _body.get_children():
		c.queue_free()
	if _tab == "forge":
		for r in ForgeBook.recipes():
			_body.add_child(_recipe_row(r as Dictionary))
	else:
		var list := ForgeBook.smeltable()
		if list.is_empty():
			var l := Label.new()
			l.text = "Nothing spare to melt. Only extra copies go in the furnace: buy, find or combine gear and the spares show up here. The SALVAGE BENCH by the door hands out scrap once a night."
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(900, 0)
			UiKit.apply_label(l, 15, Palette.MUTED)
			_body.add_child(l)
		for pair in list:
			_body.add_child(_smelt_row(str(pair[0]), int(pair[1])))


func _cost_box(gold: int, mats: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	if gold > 0:
		h.add_child(IconBook.rect("cur_gold", 26))
		var gl := Label.new()
		gl.text = str(gold)
		UiKit.apply_label(gl, 14, Color(1.0, 0.85, 0.35) if int(FamilyProfile.data.get("gold", 0)) >= gold else Color(1.0, 0.35, 0.3))
		h.add_child(gl)
	for k in mats.keys():
		h.add_child(IconBook.rect("part_" + str(k), 26))
		var l := Label.new()
		l.text = "%d/%d" % [ForgeBook.have(str(k)), int(mats[k])]
		UiKit.apply_label(l, 14, Palette.TEXT if ForgeBook.have(str(k)) >= int(mats[k]) else Color(1.0, 0.35, 0.3))
		h.add_child(l)
	return h


func _recipe_row(r: Dictionary) -> Control:
	var id := str(r.get("id", ""))
	var weapon := str(r.get("kind", "")) == "weapon"
	var rar := Rarity.normalize(str(WeaponBook.spec(id).get("rarity", "common")) if weapon else str(GearBook.item(id).get("rarity", "common")))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rar), Rarity.color(rar)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	p.add_child(row)
	row.add_child(IconBook.rect(ForgeBook.icon_of(r), IconBook.SIZE_M))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s" % [ForgeBook.title_of(r), "WEAPON" if weapon else Rarity.label(rar)]
	UiKit.apply_label(t, 17, Rarity.color(rar))
	v.add_child(t)
	var s := Label.new()
	if weapon:
		var lv := Arsenal.level(id) if Arsenal.found(id) else 0
		s.text = ("NEW IN THE ARMORY" if lv == 0 else "LEVEL %d  ▸  %d" % [lv, mini(Arsenal.MAX_LV, lv + 1)]) + "  ·  hits harder, lasts longer"
		UiKit.apply_label(s, 13, Color(0.55, 1.0, 0.5))
	else:
		var gi := GearBook.item(id)
		s.text = "%s  ·  %s  ·  %s" % [str(gi.get("slot", "")).to_upper(), "FATHER" if str(gi.get("role", "")) == "father" else ("SON" if str(gi.get("role", "")) == "son" else "BOTH"), ForgeBook.stat_line(id)]
		UiKit.apply_label(s, 13, Color(0.55, 1.0, 0.5))
	v.add_child(s)
	v.add_child(_cost_box(int(r.get("gold", 0)), r.get("mats", {})))
	row.add_child(v)
	var why := ForgeBook.can_forge(r)
	var b := UiKit.button("FORGE" if why == "" else why, Vector2(170, 44))
	b.set_meta("key", "forge_" + id)
	b.disabled = why != ""
	b.pressed.connect(func() -> void: _start_forge(id))
	row.add_child(b)
	return p


func _smelt_row(id: String, t: int) -> Control:
	var gi := GearBook.item(id)
	var rar := Rarity.ORDER[clampi(t, 0, 4)]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rar), Rarity.color(rar)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	p.add_child(row)
	row.add_child(IconBook.rect(IconBook.for_gear(id), IconBook.SIZE_M))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tl := Label.new()
	tl.text = "%s  ·  %s  ·  SPARE x%d" % [str(gi.get("title", id)).to_upper(), Rarity.label(rar), int(GearInv.counts(id)[t])]
	UiKit.apply_label(tl, 16, Rarity.color(rar))
	v.add_child(tl)
	var y := HBoxContainer.new()
	y.add_theme_constant_override("separation", 8)
	var gl := Label.new()
	gl.text = "MELTS INTO"
	UiKit.apply_label(gl, 13, Palette.MUTED)
	y.add_child(gl)
	var got := ForgeBook.smelt_yield(id, t)
	for k in got.keys():
		y.add_child(IconBook.rect("part_" + str(k), 26))
		var l := Label.new()
		l.text = "+%d" % int(got[k])
		UiKit.apply_label(l, 14, Color(0.55, 1.0, 0.5))
		y.add_child(l)
	v.add_child(y)
	row.add_child(v)
	var b := UiKit.button("SMELT", Vector2(150, 44))
	b.set_meta("key", "smelt_%s_%d" % [id, t])
	b.pressed.connect(func() -> void: _do_smelt(id, t, b))
	row.add_child(b)
	return p


func _do_smelt(id: String, t: int, from: Control) -> void:
	if _busy:
		return
	var got := ForgeBook.smelt(id, t)
	if got.is_empty():
		return
	Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", 0.7, -4.0)
	Juice.pulse_shake(2.0)
	Juice.rewards.upgrade(from, Color(1.0, 0.55, 0.2), "MELTED", false)
	var bits: PackedStringArray = []
	for k in got.keys():
		bits.append("+%d %s" % [int(got[k]), str(ForgeBook.MAT_NAME.get(k, k))])
	Juice.rewards.reveal("forge_smelt", "SMELTED", Color(1.0, 0.55, 0.2), "  ".join(bits), 1.2)
	_quip.text = "EMBER  ·  \"Melted. That hoodie had a good run.\""
	need_refresh.emit()
	_fill()


func _start_forge(id: String) -> void:
	if _busy:
		return
	_busy = true
	var anvil := ForgeAnvil.new()
	anvil.title = ForgeBook.title_of(ForgeBook.recipe(id))
	add_child(anvil)
	anvil.done.connect(func(q: int) -> void:
		_busy = false
		var out := ForgeBook.forge(id, q)
		if out.is_empty():
			return
		var rar := str(out.get("rarity", "common"))
		var grade: String = ["ROUGH", "SOLID", "STRONG", "MASTERWORK"][clampi(q, 0, 3)]
		Juice.rewards.reveal(str(out["icon"]), "%s  ·  %s" % [str(out["title"]), grade], Rarity.color(rar), str(out.get("line", "")), 1.8)
		Rarity.juice(rar, str(out["title"]))
		_quip.text = "EMBER  ·  \"%s\"" % ["It holds. Mostly.", "Clean work.", "Ooh. That one sings.", "MASTERWORK. Frame it. Then hit people with it."][clampi(q, 0, 3)]
		need_refresh.emit()
		_fill()
	)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_pause"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
