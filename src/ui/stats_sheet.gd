extends Control

## ADVANCED STATISTICS: every lifetime counter the Family Profile keeps, laid
## out like a post-season report. Tiles for the headline numbers, glowing
## bars (scaled to the section's best) for the breakdowns.

signal closed

const SECTIONS := [
	{
		"title": "GLOBAL PERFORMANCE",
		"accent": "gold",
		"tiles": [
			["Runs", "runs"], ["Maps Filed", "@maps"], ["High Score", "high_score"],
			["Account Lv", "account_level"], ["Best Streak", "streak_best"], ["Solo Clears", "solo_clears"],
			["City Clears", "city_clears"], ["Remote Clears", "remote_clears"], ["Versus Wins", "vs_wins"],
		],
	},
	{
		"title": "COMBAT ANALYSIS",
		"accent": "brick",
		"bars": [
			["Light hits", "lights"], ["Heavy hits", "heavies"], ["SNAPs", "snaps"],
			["Dual SNAPs", "dual_snaps"], ["Parries", "parries"], ["Perfect parries", "perfect_parries"],
			["Clashes", "clashes"], ["Stomps", "stomps"], ["Smash kills", "smash_kills"],
			["Revenges", "revenges"], ["Catches", "catches"], ["Combo banks", "combo_banks"],
		],
	},
	{
		"title": "PARKOUR & TRAVERSAL",
		"accent": "ready",
		"bars": [
			["Towers climbed", "towers_climbed"], ["Summit meals", "summit_meals"], ["Tricks", "tricks"],
			["Perfect tricks", "perfect_tricks"], ["Wall kicks", "wallkicks"], ["Grinds", "grinds"],
			["Pole swings", "poles"], ["Slides", "slides"], ["Dives", "dives"],
			["Awnings", "awnings"], ["Bounces", "bounces"], ["Hood hops", "hoods"],
		],
	},
	{
		"title": "ARSENAL & SUITS",
		"accent": "brick",
		"tiles": [
			["Suit Parts", "@suit_parts"], ["Weapons Found", "@weapons"], ["Mastered", "@mastered"],
			["Weapon Kills", "@weapon_kills"], ["Home Runs", "home_runs"], ["Decapitations", "decaps"],
			["Burned", "burn_kills"], ["Weapons Broken", "weapon_breaks"], ["Gadget Hits", "gadget_hits"],
			["Shards Found", "shards_found"], ["Gear Combines", "gear_combines"], ["Hero Levels", "@hero_levels"],
		],
	},
	{
		"title": "HUNTS & BOSSES",
		"accent": "lemon",
		"tiles": [
			["Raven kills", "raven_kills"], ["Family Plan", "family_plan_kills"], ["Skinwalkers", "skinwalkers_filed"],
			["Unmasks", "unmasks"], ["Filed Alive", "file_alives"], ["Legendary Takes", "legendary_takes"],
			["Survivor Hours", "survive_clears"], ["Annex Clears", "annex_clears"], ["Heat Peak", "heat_peak"],
		],
	},
	{
		"title": "RESOURCES & PROGRESSION",
		"accent": "gold",
		"tiles": [
			["Gold", "gold"], ["Gems", "gems"], ["Rep", "rep"],
			["Lifetime Pts", "lifetime_points"], ["Secrets", "secrets_found"], ["Polaroids", "polaroids"],
			["Gear Upgrades", "gear_upgrades"], ["Dojo Masters", "dojo_masters"], ["Patrols", "patrols"],
		],
	},
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.EDGE, 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -520
	card.offset_right = 520
	card.offset_top = -330
	card.offset_bottom = 330
	add_child(card)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	card.add_child(outer)
	var head := HBoxContainer.new()
	var t := UiKit.title("ADVANCED STATISTICS", 30, Palette.EDGE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := UiKit.button("CLOSE", Vector2(120, 40))
	close.pressed.connect(func() -> void:
		closed.emit()
	)
	head.add_child(close)
	outer.add_child(head)
	var sub := Label.new()
	sub.text = "%s  &  %s  ·  PATIENT FILE  ·  %s" % [FamilyProfile.son_name(), FamilyProfile.father_name(), _playtime_line()]
	UiKit.apply_label(sub, 13, Palette.MUTED)
	outer.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	sc.add_child(col)
	for sec: Dictionary in SECTIONS:
		col.add_child(_section(sec))
	UiKit.pop_in(card)


func _playtime_line() -> String:
	var maps: Array = FamilyProfile.data.get("maps_filed", [])
	return "%d / 14 ACTS FILED" % maps.size()


static func grouped(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _value(key: String) -> int:
	if key == "@maps":
		return (FamilyProfile.data.get("maps_filed", []) as Array).size()
	if key == "@suit_parts":
		return (FamilyProfile.data.get("suit_parts", []) as Array).size()
	if key == "@hero_levels":
		return Heroes.level("son") + Heroes.level("father")
	if key == "@weapons":
		return (FamilyProfile.data.get("weapons_found", []) as Array).size()
	if key == "@mastered" or key == "@weapon_kills":
		var n := 0
		var d: Dictionary = FamilyProfile.data.get("weapon_kills", {})
		for k in d:
			n += (1 if int(d[k]) >= Arsenal.MASTERY_KILLS else 0) if key == "@mastered" else int(d[k])
		return n
	var v: Variant = FamilyProfile.data.get(key, 0)
	if v is int or v is float:
		return int(v)
	return 0


func _accent(id: String) -> Color:
	match id:
		"brick":
			return Palette.BRICK
		"ready":
			return Palette.READY
		"lemon":
			return Palette.LEMON
	return Palette.EDGE


func _section(sec: Dictionary) -> Control:
	var accent := _accent(str(sec.get("accent", "gold")))
	var box := PanelContainer.new()
	var st := UiKit.panel(Color(0.045, 0.05, 0.078, 0.9), Color(accent.r, accent.g, accent.b, 0.55))
	st.content_margin_left = 14
	st.content_margin_right = 14
	box.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	box.add_child(col)
	col.add_child(UiKit.title(str(sec["title"]), 18, accent))
	if sec.has("tiles"):
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 8)
		for pair: Array in sec["tiles"]:
			var tile := UiKit.stat_tile(str(pair[0]), grouped(_value(str(pair[1]))), accent, 300.0)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(tile)
		col.add_child(grid)
	if sec.has("bars"):
		var best := 1
		for pair: Array in sec["bars"]:
			best = maxi(best, _value(str(pair[1])))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 6)
		for pair: Array in sec["bars"]:
			var n := _value(str(pair[1]))
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 8)
			var lab := Label.new()
			lab.text = str(pair[0]).to_upper()
			lab.custom_minimum_size = Vector2(150, 0)
			UiKit.apply_label(lab, 13, Palette.TEXT)
			row.add_child(lab)
			var bar := UiKit.glow_bar(float(n) / float(best), accent, Vector2(220, 10))
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(bar)
			var num := Label.new()
			num.text = grouped(n)
			num.custom_minimum_size = Vector2(56, 0)
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			UiKit.apply_label(num, 16, accent)
			row.add_child(num)
			grid.add_child(row)
		col.add_child(grid)
	return box
