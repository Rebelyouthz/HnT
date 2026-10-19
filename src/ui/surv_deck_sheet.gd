extends Control

## SURVIVOR CARDS: the hour's own deck (SurvDeck), its own menu next to the
## story's vault. Tabs: WEAPONS / TRAITS / ITEMS. Every card is a tile in its
## rarity frame with its stars; locked DECK cards are dark until a pack gives
## one. Focus a card for the big view (what it does, copies to the next
## star, what a star gives). OPEN PACK (S-COINS) reveals three cards one by
## one, centre stage, each flying into its tile. BENCH keeps a card out of
## your level-ups (up to six).

signal closed

const ACCENT := Color(0.45, 1.0, 0.6)
const TABS := [["abilities", "WEAPONS"], ["traits", "TRAITS"], ["items", "ITEMS"]]

var _tab := "abilities"
var _sel := ""
var _wallet: Label
var _detail: VBoxContainer
var _focus_key := ""
var _busy := false


func _ready() -> void:
	_paint()


func _coins() -> int:
	return int(FamilyProfile.data.get("tokens", 0))


func _paint() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(ACCENT, 0.4))
	card.position = Vector2(30, 20)
	card.size = Vector2(1220, 680)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var t := UiKit.title("SURVIVOR CARDS", 28, ACCENT)
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
	var pack := UiKit.button("OPEN PACK  ·  %d" % SurvDeck.pack_cost(), Vector2(250, 44))
	pack.set_meta("key", "pack")
	pack.disabled = _coins() < SurvDeck.pack_cost() or _busy
	pack.pressed.connect(func() -> void: _open_pack(pack))
	head.add_child(pack)
	var close := UiKit.button("CLOSE", Vector2(110, 44))
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	col.add_child(head)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	col.add_child(tabs)
	for tb: Array in TABS:
		var b := UiKit.button(str(tb[1]), Vector2(150, 38))
		b.set_meta("key", "tab_" + str(tb[0]))
		b.modulate = Color.WHITE if _tab == str(tb[0]) else Color(0.6, 0.62, 0.7)
		var k := str(tb[0])
		b.pressed.connect(func() -> void:
			_tab = k
			_sel = ""
			_focus_key = "tab_" + k
			_paint())
		tabs.add_child(b)
	var bench := Label.new()
	bench.text = "   BENCH %d / %d   ·   DECK cards show up once you own one   ·   stars: +6%% power, +12%% offer chance each" % [SurvDeck.bench_count(), SurvDeck.MAX_BENCH]
	UiKit.apply_label(bench, 13, Color(0.7, 0.72, 0.78))
	tabs.add_child(bench)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(770, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(grid)
	var first := ""
	for c: Dictionary in SurvDeck.cards():
		if str(c["kind"]) != _tab:
			continue
		if first == "":
			first = str(c["id"])
		grid.add_child(_tile(c))
	if _sel == "":
		_sel = first
	_detail = VBoxContainer.new()
	_detail.custom_minimum_size = Vector2(400, 0)
	_detail.add_theme_constant_override("separation", 8)
	body.add_child(_detail)
	_show(_sel)
	UiKit.pop_in(card)
	var want := _focus_key if _focus_key != "" else "dk_" + _sel
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and not (b as Button).disabled:
				(b as Button).grab_focus()
				return
		close.grab_focus()
	, CONNECT_ONE_SHOT)


func _rar_color(c: Dictionary) -> Color:
	return Rarity.color(str(c["rarity"]))


func _tile(c: Dictionary) -> Button:
	var id := str(c["id"])
	var own := SurvDeck.owned(id)
	var rc := _rar_color(c) if own else Color(0.28, 0.29, 0.33)
	var b := Button.new()
	b.custom_minimum_size = Vector2(122, 150)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "dk_" + id)
	var sb := UiKit.panel(Color(0.05, 0.06, 0.09) if own else Color(0.025, 0.025, 0.04), rc)
	sb.set_border_width_all(3)
	var hi := sb.duplicate() as StyleBoxFlat
	hi.border_color = Color.WHITE.lerp(rc, 0.4)
	hi.shadow_color = Color(rc.r, rc.g, rc.b, 0.7)
	hi.shadow_size = 12
	b.add_theme_stylebox_override("normal", sb)
	for s in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(s, hi)
	var ic := IconBook.rect(str(c["icon"]), IconBook.SIZE_M)
	ic.position = Vector2(29, 14)
	if not own:
		ic.modulate = Color(0, 0, 0.02, 0.9)
	elif SurvDeck.benched(id):
		ic.modulate = Color(0.45, 0.45, 0.5, 0.7)
	b.add_child(ic)
	if not own:
		var lk := IconBook.rect("cur_lock", IconBook.SIZE_S)
		lk.position = Vector2(40, 24)
		b.add_child(lk)
	var nm := Label.new()
	nm.text = str(c["name"]) if own else "???"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	UiKit.apply_label(nm, 11, Palette.TEXT if own else Color(0.5, 0.5, 0.55))
	nm.position = Vector2(3, 84)
	nm.size = Vector2(116, 16)
	b.add_child(nm)
	var stars := Label.new()
	stars.text = ("★".repeat(SurvDeck.stars(id)) + "☆".repeat(5 - SurvDeck.stars(id))) if own else ""
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(stars, 13, Palette.LEMON)
	stars.position = Vector2(3, 102)
	stars.size = Vector2(116, 18)
	b.add_child(stars)
	var tag := Label.new()
	tag.text = "BENCHED" if SurvDeck.benched(id) else ("DECK" if bool(c["deck"]) else str(c["rarity"]).to_upper())
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(tag, 10, Color(1.0, 0.45, 0.4) if SurvDeck.benched(id) else rc)
	tag.position = Vector2(3, 124)
	tag.size = Vector2(116, 16)
	b.add_child(tag)
	b.focus_entered.connect(func() -> void:
		_sel = id
		_show(id))
	b.mouse_entered.connect(func() -> void:
		_sel = id
		_show(id))
	b.pressed.connect(func() -> void: _toggle(id, b))
	return b


func _show(id: String) -> void:
	if _detail == null or id == "":
		return
	for ch in _detail.get_children():
		_detail.remove_child(ch)
		ch.queue_free()
	var c := SurvDeck.card(id)
	var own := SurvDeck.owned(id)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_detail.add_child(top)
	var big := IconBook.rect(str(c["icon"]), IconBook.SIZE_L)
	if not own:
		big.modulate = Color(0, 0, 0.02, 0.9)
	top.add_child(big)
	var tl := VBoxContainer.new()
	top.add_child(tl)
	tl.add_child(UiKit.title(str(c["name"]) if own else "LOCKED CARD", 22, _rar_color(c) if own else Color(0.6, 0.6, 0.65)))
	var kind := {"abilities": ("MANUAL WEAPON" if bool(c["manual"]) else "AUTO WEAPON"), "traits": "PASSIVE", "items": "ITEM"}
	var k := Label.new()
	k.text = "%s  ·  %s%s" % [str(kind.get(str(c["kind"]), "")), str(c["rarity"]).to_upper(), "  ·  DECK ONLY" if bool(c["deck"]) else ""]
	UiKit.apply_label(k, 13, Palette.LEMON)
	tl.add_child(k)
	var bl := Label.new()
	bl.text = str(c["blurb"]) if own else "Only from SURVIVOR PACKS. Once you own it, it can show up in your level-ups."
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(390, 0)
	UiKit.apply_label(bl, 15, Palette.TEXT)
	_detail.add_child(bl)
	if own:
		var st := RichTextLabel.new()
		st.bbcode_enabled = true
		st.fit_content = true
		st.scroll_active = false
		st.custom_minimum_size = Vector2(390, 70)
		st.add_theme_font_size_override("normal_font_size", 15)
		var s := SurvDeck.stars(id)
		var nx := SurvDeck.next_at(id)
		var txt := "STARS  [color=#ffd75a]%s[/color]   COPIES %d" % ["★".repeat(s), SurvDeck.copies(id)]
		if nx > 0:
			txt += "  (next star at %d)" % nx
		txt += "\nPOWER  [color=#ffffff]%d%%[/color]   OFFERED  [color=#ffffff]x%.2f[/color]" % [int(round(SurvDeck.power(id) * 100.0)), SurvDeck.weight(id)]
		if nx > 0:
			txt += "\nNEXT STAR  [color=#7dff8a]%d%%  ·  x%.2f[/color]" % [int(round((SurvDeck.power(id) + 0.06) * 100.0)), SurvDeck.weight(id) + 0.12]
		st.text = txt
		_detail.add_child(st)
		var bb := UiKit.button("UNBENCH" if SurvDeck.benched(id) else "BENCH  (keep out of level-ups)", Vector2(330, 46))
		bb.set_meta("key", "bench_" + id)
		bb.pressed.connect(func() -> void: _toggle(id, bb))
		_detail.add_child(bb)


func _toggle(id: String, from: Control) -> void:
	if not SurvDeck.owned(id):
		Juice.rewards.deny(from)
		return
	if not SurvDeck.toggle_bench(id):
		Juice.claim_burst(Vector2(320, 180), "BENCH IS FULL (%d)" % SurvDeck.MAX_BENCH, 0, 0)
		return
	_focus_key = "dk_" + id
	_paint()
	UiKit.fx_after(self, "dk_" + id, Color(1.0, 0.45, 0.4) if SurvDeck.benched(id) else ACCENT, "BENCHED" if SurvDeck.benched(id) else "BACK IN THE DECK", false)


## Three cards, one after another: centre stage big, then into their tile.
func _open_pack(btn: Control) -> void:
	if _busy:
		return
	var got := SurvDeck.open_pack()
	if got.is_empty():
		Juice.rewards.deny(btn)
		return
	_busy = true
	RewardFly.snd("reward_pop", 0.8, -2.0)
	_focus_key = "pack"
	_paint()
	var i := 0
	for id: String in got:
		var c := SurvDeck.card(id)
		var fresh := SurvDeck.copies(id) == 1 or (not bool(c["deck"]) and SurvDeck.copies(id) == 2)
		var line := ("NEW CARD" if fresh and bool(c["deck"]) else "COPY  ·  %d" % SurvDeck.copies(id)) + "  ·  " + "★".repeat(SurvDeck.stars(id))
		var delay := 1.25 * float(i)
		get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			if str(c["kind"]) != _tab:
				_tab = str(c["kind"])
				_sel = id
				_focus_key = "dk_" + id
				_paint()
			var tile: Control = null
			for b in find_children("*", "Button", true, false):
				if str(b.get_meta("key", "")) == "dk_" + id:
					tile = b
			Juice.rewards.reveal(str(c["icon"]), str(c["name"]), _rar_color(c), line, 0.55, tile))
		i += 1
	get_tree().create_timer(1.25 * float(got.size()) + 0.6, true, false, true).timeout.connect(func() -> void:
		_busy = false
		if is_inside_tree():
			_sel = str(got[got.size() - 1])
			_focus_key = "dk_" + _sel
			_paint())
