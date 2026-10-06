extends Control

## SURVIVOR CODEX: everything about the coping hours in one place. Every
## ability (locked ones say which SURVIVOR tree node opens them), every
## evolution recipe (ability at LV 7 + partner item), the ultimate you take
## in (pick here), and your records.

signal closed

var _page := "entries"
var _cat := "enemy"
var _want := ""
const DODGE := {
	"charge": "A red lane fills: step to another depth (up/down) before it does.",
	"slam": "A red ring where it lands: run out of the circle or jump.",
	"volley": "Fans of paper at three depths: walk between them.",
	"rain": "Red markers fall in order: keep moving, never stand on one.",
	"summon": "Calls two thugs from the edges: clear them or keep the boss between.",
	"lane_wave": "A shockwave along its lane: change depth, the second follows you.",
	"grab": "Flashes white, then lunges: roll or jump, it can't be blocked.",
	"spin": "Light hits bounce: back off, then hit it hard when it stops (OPEN).",
}
var _book: Dictionary = {}


func _ready() -> void:
	Guides.show(self, "codex")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
	_book = parsed if parsed is Dictionary else {}
	_paint()


func _row(kind: String, id: String) -> Dictionary:
	for r: Dictionary in _book.get(kind, []):
		if str(r.get("id", "")) == id:
			return r
	return {}


func _paint() -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Color(1.0, 0.56, 0.12), 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -600
	card.offset_right = 600
	card.offset_top = -340
	card.offset_bottom = 340
	add_child(card)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	card.add_child(outer)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var t := UiKit.title("CODEX", 30, Color(1.0, 0.56, 0.12))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var first: Button = null
	for pair in [["entries", "ENTRIES"], ["bestiary", "BESTIARY"], ["abilities", "ABILITIES"], ["evolutions", "EVOLUTIONS"], ["ultimate", "ULTIMATE"], ["records", "RECORDS"]]:
		var b := UiKit.button(pair[1], Vector2(112, 36))
		b.add_theme_font_size_override("font_size", 11)
		if pair[0] == _page:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
			first = b
		b.pressed.connect(func() -> void:
			_page = pair[0]
			Juice.play("res://assets/audio/ui_click.wav")
			_paint()
		)
		head.add_child(b)
	var close := UiKit.button("CLOSE", Vector2(96, 36))
	close.pressed.connect(func() -> void:
		closed.emit()
	)
	head.add_child(close)
	outer.add_child(head)
	var sub := Label.new()
	sub.text = "S-COINS %d  ·  spend them in BUILD › SURVIVOR and HEROES › META › SURVIVOR" % int(FamilyProfile.data.get("tokens", 0))
	UiKit.apply_label(sub, 13, Palette.MUTED)
	outer.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	match _page:
		"entries":
			_entries_page(outer, grid, sub)
		"bestiary":
			var bparsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/bosses.json"))
			var bosses: Dictionary = bparsed if bparsed is Dictionary else {}
			var kb: Dictionary = FamilyProfile.data.get("kills_by", {})
			var tries: int = 0
			for k in FamilyProfile.data:
				if str(k).begins_with("boss_tries_"):
					tries += int(FamilyProfile.data[k])
			for bt in ["Shift Lead", "Collector Gant", "Clamp King", "Lot Hydra"]:
				var spec := BossBrain.spec_for(bt)
				var lines: Array[String] = []
				var st: Array = spec.get("stages", [])
				for i in st.size():
					for mv in st[i]:
						var nm := str((spec.get("names", {}) as Dictionary).get(mv, str(mv).to_upper()))
						lines.append("[color=#ffd75e]%s[/color] (%d%%) %s" % [nm, [100, 75, 50, 25][i], str(DODGE.get(mv, ""))])
				var seen := int(kb.get(bt, 0)) > 0
				var e := _entry("", bt.to_upper() + ("  ·  FILED x%d" % int(kb.get(bt, 0)) if seen else ""), "BOSS PATTERNS  ·  every pattern ends OPEN: +50% damage", "", true, Palette.BRICK)
				var rt := UiKit.rich("\n".join(lines), 440, 11, Palette.TEXT)
				((e.get_child(0) as PanelContainer).get_child(0) as HBoxContainer).get_child(1).add_child(rt)
				var face := SpriteBook.face(_who(bt))
				if face:
					var ic := ((e.get_child(0) as PanelContainer).get_child(0) as HBoxContainer).get_child(0) as TextureRect
					ic.texture = face
				grid.add_child(e)
			var titles: Array = kb.keys()
			titles.sort_custom(func(a, b) -> bool: return int(kb[a]) > int(kb[b]))
			for tt in titles:
				if str(tt) in ["Shift Lead", "Collector Gant", "Clamp King", "Lot Hydra"]:
					continue
				var e2 := _entry("", str(tt).to_upper(), "FILED x%d" % int(kb[tt]), "Thug on the night streets.", true, Palette.EDGE)
				var f2 := SpriteBook.face(_who(str(tt)))
				if f2:
					(((e2.get_child(0) as PanelContainer).get_child(0) as HBoxContainer).get_child(0) as TextureRect).texture = f2
				grid.add_child(e2)
			sub.text = "Bosses fell you %d times so far. Read the patterns, then go back stronger." % tries
		"abilities":
			for r: Dictionary in _book.get("abilities", []):
				var unlock := str(r.get("unlock", ""))
				var open := unlock == "" or Trees.has(unlock)
				var line := str(r.get("blurb", ""))
				if not open:
					line = "LOCKED  ·  SURVIVOR tree: %s" % str(Trees.node("survivor", unlock).get("name", unlock))
				var every := ("EVERY %.1fs" % float(r.get("cd", 1.0))) if float(r.get("cd", 1.0)) > 0.0 else "ALWAYS ON"
				grid.add_child(_entry(str(r.get("icon", "")), str(r.get("name", "")), "DMG %d (+%d/LV)  ·  %s" % [int(r.get("dmg", 0)), int(r.get("per", 0)), every], line, open, Color(1.0, 0.8, 0.3)))
		"evolutions":
			var seen: Array = FamilyProfile.data.get("evolutions_seen", [])
			for e: Dictionary in _book.get("evolutions", []):
				var ab := _row("abilities", str(e.get("ability", "")))
				var it := _row("items", str(e.get("item", "")))
				var got := seen.has(str(e.get("ability", "")))
				var recipe := "%s LV 7  +  %s" % [str(ab.get("name", "")), str(it.get("name", ""))]
				grid.add_child(_entry("evolve", str(e.get("name", "")) if got else "???", recipe, str(e.get("blurb", "")) if got else ("Needs the EVOLUTION node first." if not Trees.has("s_evolve") else "Not evolved yet."), got, Color(1.0, 0.56, 0.12)))
		"ultimate":
			var cur := str(FamilyProfile.data.get("surv_ult", "copay_crash"))
			for u: Dictionary in _book.get("ultimates", []):
				var uid := str(u.get("id", ""))
				var unl := str(u.get("unlock", ""))
				var open := unl == "" or Trees.has(unl)
				var w := _entry(str(u.get("icon", "")), str(u.get("name", "")) + ("  ·  EQUIPPED" if uid == cur else ""), "Kills charge it. SPECIAL fires it.", str(u.get("blurb", "")) if open else "LOCKED  ·  SURVIVOR tree: %s" % str(Trees.node("survivor", unl).get("name", unl)), open, Color(0.6, 0.85, 1.0))
				if open and uid != cur:
					var pick := UiKit.button("EQUIP", Vector2(120, 32))
					pick.pressed.connect(func() -> void:
						FamilyProfile.data["surv_ult"] = uid
						FamilyProfile.save()
						Juice.play("res://assets/audio/claim.wav")
						_paint()
					)
					w.add_child(pick)
				grid.add_child(w)
		_:
			for pair in [["BEST KILLS", "surv_best_kills"], ["BEST LEVEL", "surv_best_level"], ["LONGEST HOUR (s)", "surv_best_time"], ["HOURS CLEARED", "survive_clears"], ["S-COINS EARNED", "tokens_total"], ["EVOLUTIONS FOUND", "@evo"]]:
				var v := int(FamilyProfile.data.get(pair[1], 0)) if pair[1] != "@evo" else (FamilyProfile.data.get("evolutions_seen", []) as Array).size()
				var tile := UiKit.stat_tile(str(pair[0]), str(v), Color(1.0, 0.56, 0.12), 520.0)
				grid.add_child(tile)
	UiKit.pop_in(card)
	var f := first
	var want := _want
	get_tree().process_frame.connect(func() -> void:
		if want != "":
			for c in find_children("*", "Button", true, false):
				if str(c.get_meta("key", "")) == want:
					(c as Button).grab_focus()
					return
		if is_instance_valid(f):
			f.grab_focus()
	, CONNECT_ONE_SHOT)


func _entry(icon: String, title: String, stat: String, line: String, open: bool, col: Color) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(540, 96)
	Bevel.dress(p, false, 0.7)
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.06, 0.07, 0.12), col if open else Palette.MUTED))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	var ic := UiKit.portrait(SurviveIcons.tex(icon), Vector2(64, 64))
	ic.custom_minimum_size = Vector2(64, 64)
	if not open:
		ic.modulate = Color(0.1, 0.1, 0.14)
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n := Label.new()
	n.text = title
	n.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(n, 17, col if open else Palette.MUTED)
	v.add_child(n)
	var st := Label.new()
	st.text = stat
	UiKit.apply_label(st, 11, Palette.MUTED)
	v.add_child(st)
	var l := Label.new()
	l.text = line
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(440, 0)
	UiKit.apply_label(l, 12, Palette.TEXT)
	v.add_child(l)
	h.add_child(v)
	# The EQUIP button (ultimate page) goes in this column.
	h.move_child(v, 1)
	var wrap := HBoxContainer.new()
	wrap.add_child(p)
	return wrap



## Everything filed so far by category: met things show their picture and
## a CLAIM button for their reward; the rest stay dark "???" plates.
func _entries_page(outer: VBoxContainer, grid: GridContainer, sub: Label) -> void:
	sub.text = "FILED %d / %d  ·  every 10 claimed pays 3 gems  ·  meet new things to fill the book" % [Discover.filed(), Discover.total()]
	grid.columns = 6
	# Category tabs with their own red dots.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	outer.add_child(tabs)
	outer.move_child(tabs, 2)
	for c: String in Discover.CATS:
		var n_new := 0
		var n_seen := 0
		for e: Array in Discover.catalog(c):
			var st := Discover.state(c, str(e[0]))
			if st > 0:
				n_seen += 1
			if st == 1:
				n_new += 1
		var b := UiKit.button("%s %d/%d" % [Discover.CAT_NAME[c], n_seen, Discover.catalog(c).size()], Vector2(134, 34))
		b.add_theme_font_size_override("font_size", 10)
		b.set_meta("key", "cat_" + c)
		if c == _cat:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		if n_new > 0:
			var dot := UiKit.new_dot()
			dot.position = Vector2(124, -4)
			b.add_child(dot)
		b.pressed.connect(func() -> void:
			_cat = c
			_want = "cat_" + c
			_paint())
		tabs.add_child(b)
	var all := UiKit.button("CLAIM ALL", Vector2(118, 34))
	all.add_theme_font_size_override("font_size", 11)
	all.disabled = Discover.unclaimed() == 0
	all.pressed.connect(func() -> void:
		var g := 0
		var gm := 0
		for c2: String in Discover.CATS:
			for e2: Array in Discover.catalog(c2):
				var pay := Discover.claim(c2, str(e2[0]))
				g += int(pay.get("gold", 0))
				gm += int(pay.get("gems", 0))
		if g > 0:
			Juice.give("gold", g, RewardFly.vp_of(all))
		if gm > 0:
			Juice.give("gems", gm, RewardFly.vp_of(all) + Vector2(0, -10))
		Juice.upgrade_fx(all, Color(1.0, 0.56, 0.12), "CLAIMED", true)
		_paint())
	tabs.add_child(all)
	for e: Array in Discover.catalog(_cat):
		grid.add_child(_entry_tile(_cat, str(e[0]), str(e[1])))


func _entry_tile(cat: String, id: String, title: String) -> Control:
	var st := Discover.state(cat, id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 150)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "ent_%s_%s" % [cat, id])
	var col := Color(1.0, 0.56, 0.12) if st == 1 else (Palette.EDGE if st == 2 else Color(0.25, 0.26, 0.3))
	var sb := UiKit.panel(Color(0.05, 0.06, 0.1), col)
	sb.set_border_width_all(2 if st != 1 else 3)
	var hi := sb.duplicate() as StyleBoxFlat
	hi.border_color = UiKit.GOLD
	hi.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.5)
	hi.shadow_size = 8
	for s2 in ["normal", "disabled"]:
		b.add_theme_stylebox_override(s2, sb)
	for s3 in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(s3, hi)
	# Picture: the thug's face for thugs and bosses, the icon for the rest.
	var pic: TextureRect
	var face: Texture2D = SpriteBook.face(_who(id)) if cat in ["enemy", "boss"] else null
	if face:
		pic = TextureRect.new()
		pic.texture = face
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = SpriteBook.UI_FILTER
		pic.size = Vector2(72, 72)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		pic = IconBook.rect(Discover.icon_for(cat, id), IconBook.SIZE_M)
	pic.position = Vector2(93, 10) - Vector2(pic.size.x * 0.5, 0)
	if st == 0:
		pic.modulate = Color(0, 0, 0.02, 0.85)
	b.add_child(pic)
	var nm := Label.new()
	nm.text = title if st > 0 else "???"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.position = Vector2(4, 88)
	nm.size = Vector2(178, 16)
	nm.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(nm, 10, Palette.TEXT if st > 0 else Palette.MUTED)
	b.add_child(nm)
	var pay: Dictionary = Discover.REWARD.get(cat, {})
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.position = Vector2(4, 112)
	foot.size = Vector2(178, 26)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(foot)
	if st == 1:
		var cl := Label.new()
		cl.text = "CLAIM"
		cl.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(cl, 13, Color(1.0, 0.56, 0.12))
		foot.add_child(cl)
		for k in ["gold", "gems"]:
			if int(pay.get(k, 0)) > 0:
				foot.add_child(IconBook.rect("cur_gold_s" if k == "gold" else "cur_gem_s", 22))
				var v := Label.new()
				v.text = str(pay[k])
				v.add_theme_font_override("font", UiKit.pixel_font())
				UiKit.apply_label(v, 11, Palette.TEXT)
				foot.add_child(v)
		var dot := UiKit.new_dot()
		dot.position = Vector2(170, 4)
		b.add_child(dot)
		UiKit.pulse_ready(b)
	elif st == 2:
		var fl := Label.new()
		fl.text = "FILED"
		fl.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(fl, 11, Palette.READY)
		foot.add_child(fl)
	b.pressed.connect(func() -> void:
		if Discover.state(cat, id) != 1:
			Juice.rewards.deny(b)
			return
		var got := Discover.claim(cat, id)
		var at := RewardFly.vp_of(b)
		if int(got.get("gold", 0)) > 0:
			Juice.give("gold", int(got["gold"]), at)
		if int(got.get("gems", 0)) > 0:
			Juice.give("gems", int(got["gems"]), at + Vector2(0, -10))
		Juice.upgrade_fx(b, Color(1.0, 0.56, 0.12), "FILED", got.has("milestone"))
		if got.has("milestone"):
			Juice.rewards.reveal("node_school", "CODEX  ·  %d FILED" % int(got["milestone"]), Color(1.0, 0.56, 0.12), "+3 GEMS milestone bonus")
		_want = "ent_%s_%s" % [cat, id]
		_paint())
	return b


## Sprite folder for a thug title ("Collector Gant" -> gant).
func _who(title: String) -> String:
	var m := {"Collector Gant": "gant", "Lot Hydra": "lot_hydra", "Clamp King": "clamp_king", "Shift Lead": "shift_lead", "Bag Snatch": "bag_snatch", "Mohawk Bo": "mohawk", "Repo Goon": "repo_goon", "Roof Runner": "roof_runner", "Bailiff": "bailiff", "Coping Imp": "coping_imp", "Beat Cop": "cop"}
	return str(m.get(title, title.to_lower().replace(" ", "_")))
