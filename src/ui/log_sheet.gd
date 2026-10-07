extends Control

## NIGHT LOG: the clinic's notes on the family, newest first, each with its
## stamp (intake, unlock, boss, reward, warning), next to the KILL TALLY - a
## wall of mugshots of everyone the family has put down, with the count
## under each face and a red WANTED tag on the most-hit - and the last
## nights at a glance.

signal closed

const WHO := {
	"Bag Snatch": "bag_snatch", "Repo Goon": "repo_goon", "Bailiff": "bailiff",
	"Roof Runner": "roof_runner", "Mohawk Bo": "mohawk", "Shift Lead": "shift_lead",
	"Collector Gant": "gant", "Valet": "valet", "Clamp King": "clamp_king",
	"Lot Hydra": "lot_hydra", "Coping Imp": "coping_imp", "Clipboard": "clipboard_flier",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -600
	card.offset_right = 600
	card.offset_top = -330
	card.offset_bottom = 330
	add_child(card)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	card.add_child(outer)
	var head := HBoxContainer.new()
	var t := UiKit.title("NIGHT LOG", 30, Palette.LEMON)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.title_icon(t, "head_log")
	head.add_child(t)
	var close := UiKit.button("CLOSE", Vector2(120, 40))
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	outer.add_child(head)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	outer.add_child(body)
	body.add_child(_entries())
	body.add_child(_tally())
	close.grab_focus()
	UiKit.pop_in(card)


func _entries() -> Control:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(560, 560)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	sc.add_child(col)
	var log: Array = FamilyProfile.data.get("log", [])
	if log.is_empty():
		var e := Label.new()
		e.text = Copy.EMPTY_LOG
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(e, 14, Palette.MUTED)
		col.add_child(e)
	var items := log.duplicate()
	items.reverse()
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL.lightened(0.04), Palette.EDGE.darkened(0.45)))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var ic := UiKit.portrait(IconBook.tex(_stamp(str(item.get("title", "")))), Vector2(40, 40))
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tl := Label.new()
		tl.text = str(item.get("title", "")).to_upper()
		UiKit.apply_label(tl, 14, UiKit.GOLD)
		v.add_child(tl)
		var bl := Label.new()
		bl.text = str(item.get("body", ""))
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(bl, 12, Palette.TEXT)
		v.add_child(bl)
		h.add_child(v)
		col.add_child(row)
	return sc


## The stamp a note gets, read off its title.
static func _stamp(title: String) -> String:
	var t := title.to_upper()
	if "INTAKE" in t or "FILE" in t:
		return "cur_title"
	if "UNLOCK" in t or "OPEN" in t or "NEW" in t:
		return "cur_key"
	if "BOSS" in t or "FILED" in t or "BOUNTY" in t:
		return "head_codex"
	if "GOLD" in t or "REWARD" in t or "CRATE" in t or "CHEST" in t:
		return "cur_chest"
	if "LEVEL" in t or "RANK" in t:
		return "cur_xp"
	if "DOWN" in t or "DIED" in t or "LOST" in t:
		return "cur_heart"
	return "head_log"


func _tally() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var kb: Dictionary = FamilyProfile.data.get("kills_by", {})
	var total := int(FamilyProfile.data.get("kills_total", 0))
	var h := UiKit.title("KILL TALLY  ·  %d" % total, 18, Palette.BRICK)
	col.add_child(h)
	var keys := kb.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(kb[a]) > int(kb[b]))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	var top := int(kb[keys[0]]) if not keys.is_empty() else 0
	for k in keys.slice(0, 15):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(100, 112)
		var most := int(kb[k]) == top
		cell.add_theme_stylebox_override("panel", UiKit.panel(Color(0.08, 0.06, 0.08), Palette.BRICK if most else Palette.EDGE.darkened(0.5)))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(v)
		var who := str(WHO.get(str(k), "cop" if "Cop" in str(k) or "Officer" in str(k) else "punk"))
		var pic := UiKit.portrait(SpriteBook.bust(who, 0.5) if SpriteBook.has_who(who) else IconBook.tex("cur_heart"), Vector2(84, 62))
		v.add_child(pic)
		var n := Label.new()
		n.text = str(k).to_upper()
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		n.custom_minimum_size = Vector2(92, 0)
		UiKit.apply_label(n, 9, Palette.TEXT)
		v.add_child(n)
		var c := Label.new()
		c.text = "x %d" % int(kb[k])
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiKit.apply_label(c, 13, Palette.BRICK if most else UiKit.GOLD)
		v.add_child(c)
		if most:
			var tag := Label.new()
			tag.text = "WANTED"
			UiKit.apply_label(tag, 9, Color.WHITE)
			tag.add_theme_color_override("font_outline_color", Palette.BRICK)
			tag.position = Vector2(4, 2)
			cell.add_child(tag)
			tag.top_level = false
		grid.add_child(cell)
	if keys.is_empty():
		var e := Label.new()
		e.text = "Nobody yet. The street is waiting."
		UiKit.apply_label(e, 13, Palette.MUTED)
		col.add_child(e)
	var hist: Array = FamilyProfile.data.get("run_history", [])
	if not hist.is_empty():
		col.add_child(UiKit.title("LAST NIGHTS", 16, Palette.LEMON))
		for hh: Dictionary in hist.slice(0, 5):
			var ok := bool(hh.get("ok", false))
			var l := Label.new()
			l.text = "%s  %s  ·  %d kills  ·  %d:%02d" % ["CLEARED" if ok else "DOWN", StageCard.title_of(str(hh.get("map", ""))), int(hh.get("kills", 0)), int(hh.get("secs", 0)) / 60, int(hh.get("secs", 0)) % 60]
			UiKit.apply_label(l, 12, Palette.READY if ok else Palette.BRICK)
			col.add_child(l)
	return col
