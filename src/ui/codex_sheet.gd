extends Control

## SURVIVOR CODEX: everything about the coping hours in one place. Every
## ability (locked ones say which SURVIVOR tree node opens them), every
## evolution recipe (ability at LV 7 + partner item), the ultimate you take
## in (pick here), and your records.

signal closed

var _page := "bestiary"
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
	for pair in [["bestiary", "BESTIARY"], ["abilities", "ABILITIES"], ["evolutions", "EVOLUTIONS"], ["ultimate", "ULTIMATE"], ["records", "RECORDS"]]:
		var b := UiKit.button(pair[1], Vector2(122, 36))
		b.add_theme_font_size_override("font_size", 12)
		if pair[0] == _page:
			b.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
			first = b
		b.pressed.connect(func() -> void:
			_page = pair[0]
			Juice.play("res://assets/audio/ui_click.wav")
			_paint()
		)
		head.add_child(b)
	var close := UiKit.button("CLOSE", Vector2(110, 36))
	close.pressed.connect(func() -> void:
		closed.emit()
	)
	head.add_child(close)
	outer.add_child(head)
	var sub := Label.new()
	sub.text = "TOKENS %d  ·  spend them in BUILD › SURVIVOR and HEROES › META › SURVIVOR" % int(FamilyProfile.data.get("tokens", 0))
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
			for pair in [["BEST KILLS", "surv_best_kills"], ["BEST LEVEL", "surv_best_level"], ["LONGEST HOUR (s)", "surv_best_time"], ["HOURS CLEARED", "survive_clears"], ["TOKENS EARNED", "tokens_total"], ["EVOLUTIONS FOUND", "@evo"]]:
				var v := int(FamilyProfile.data.get(pair[1], 0)) if pair[1] != "@evo" else (FamilyProfile.data.get("evolutions_seen", []) as Array).size()
				var tile := UiKit.stat_tile(str(pair[0]), str(v), Color(1.0, 0.56, 0.12), 520.0)
				grid.add_child(tile)
	UiKit.pop_in(card)
	var f := first
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(f):
			f.grab_focus()
	, CONNECT_ONE_SHOT)


func _entry(icon: String, title: String, stat: String, line: String, open: bool, col: Color) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(540, 96)
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



## Sprite folder for a thug title ("Collector Gant" -> gant).
func _who(title: String) -> String:
	var m := {"Collector Gant": "gant", "Lot Hydra": "lot_hydra", "Clamp King": "clamp_king", "Shift Lead": "shift_lead", "Bag Snatch": "bag_snatch", "Mohawk Bo": "mohawk", "Repo Goon": "repo_goon", "Roof Runner": "roof_runner", "Bailiff": "bailiff", "Coping Imp": "coping_imp", "Beat Cop": "cop"}
	return str(m.get(title, title.to_lower().replace(" ", "_")))
