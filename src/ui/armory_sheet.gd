extends Control

## ARMORY: every weapon on the street - its art, what it does, how many
## you have put down with it and how far to MASTERY. Weapons never held
## show as a dark silhouette with where to look.

signal closed

const MELEE_ORDER := ["knife", "pipe", "board", "chain", "crowbar", "baseball_bat", "machete", "sledgehammer", "clipboard", "stapler", "invoice_star"]
const GUN_ORDER := ["pistol", "revolver", "nailgun", "smg", "shotgun", "flare_gun", "ray"]
const WHERE := {
	"baseball_bat": "Dock Street, near the start.", "machete": "Dock Street and the Intake Lot.",
	"sledgehammer": "The Intake Lot gate, and City Hall.", "revolver": "The Intake Lot, and the Waiting Room.",
	"flare_gun": "Dock Street mid-way, and the Invoice Pier.", "invoice_star": "A secret.",
}

var _grid: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.BRICK, 0.4))
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
	var t := UiKit.title("ARMORY", 32, Palette.BRICK)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := UiKit.button("CLOSE", Vector2(120, 40))
	close.pressed.connect(func() -> void:
		closed.emit()
	)
	head.add_child(close)
	outer.add_child(head)
	var total := 0
	var have := 0
	var mastered := 0
	for id in MELEE_ORDER + GUN_ORDER:
		if WeaponBook.spec(id).is_empty():
			continue
		total += 1
		if Arsenal.found(id):
			have += 1
		if Arsenal.mastered(id):
			mastered += 1
	var sub := UiKit.rich("FOUND [color=#ffd75e]%d/%d[/color]   ·   MASTERED [color=#ffd75e]%d[/color]   ·   %d kills with any weapon %s" % [have, total, mastered, Arsenal.MASTERY_KILLS, "= +15% damage with it, for good"], 1100, 14, Palette.MUTED)
	outer.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	for pair in [["MELEE", MELEE_ORDER], ["GUNS", GUN_ORDER]]:
		col.add_child(UiKit.title(str(pair[0]), 18, Palette.EDGE))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		for id: String in pair[1]:
			if not WeaponBook.spec(id).is_empty():
				grid.add_child(_tile(id))
		col.add_child(grid)
	UiKit.pop_in(card)
	FamilyProfile.mark_seen("armory")
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(close):
			close.grab_focus()
	, CONNECT_ONE_SHOT)


func _art(id: String) -> Texture2D:
	for dir in ["held", "guns"]:
		var p := "res://assets/sprites/%s/%s.png" % [dir, id]
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _tile(id: String) -> Control:
	var spec := WeaponBook.spec(id)
	var have := Arsenal.found(id)
	var rarity := Rarity.normalize(str(spec.get("rarity", "common")))
	var col := Rarity.color(rarity)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(370, 138)
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.06, 0.07, 0.12), UiKit.GOLD if Arsenal.mastered(id) else (col if have else Palette.MUTED)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var art := TextureRect.new()
	art.texture = _art(id)
	art.custom_minimum_size = Vector2(120, 52)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not have:
		art.modulate = Color(0.05, 0.05, 0.08)
	top.add_child(art)
	var names := VBoxContainer.new()
	var nm := Label.new()
	nm.text = str(spec.get("title", id)).to_upper() if have else "???"
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 17, col if have else Palette.MUTED)
	names.add_child(nm)
	var tag := Label.new()
	var gun := spec.has("gun")
	tag.text = "%s  ·  %s" % [Rarity.label(rarity), ("GUN  ·  " + str(spec.get("caliber", "")).to_upper()) if gun else "MELEE"]
	UiKit.apply_label(tag, 10, Palette.MUTED)
	names.add_child(tag)
	top.add_child(names)
	v.add_child(top)
	var line := ""
	if have:
		if gun:
			line = "DMG %d%s  ·  MAG %d  ·  %.1f/s" % [int(spec.get("dmg", 0)), (" x%d" % int(spec.get("pellets", 1))) if int(spec.get("pellets", 1)) > 1 else "", int(spec.get("mag", 0)), 1.0 / maxf(0.05, float(spec.get("rate", 0.3)))]
		else:
			line = "%s  ·  LASTS %d HITS" % [str(spec.get("hit", "heavy")).to_upper() + " HITS", Arsenal.uses(id)]
		if str(spec.get("blurb", "")) != "":
			line += "\n" + str(spec["blurb"])
	else:
		line = "NOT FOUND  ·  " + str(WHERE.get(id, "Somewhere on the street."))
	var info := UiKit.rich(line, 350, 12, Palette.TEXT)
	info.text = UiKit.stat_bbcode(line)
	v.add_child(info)
	var k := Arsenal.kills(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var bar := UiKit.glow_bar(clampf(float(k) / float(Arsenal.MASTERY_KILLS), 0.0, 1.0), UiKit.GOLD if Arsenal.mastered(id) else col, Vector2(220, 8))
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var kl := Label.new()
	kl.text = ("★ MASTERED  %d" % k) if Arsenal.mastered(id) else "%d/%d KILLS" % [k, Arsenal.MASTERY_KILLS]
	UiKit.apply_label(kl, 12, UiKit.GOLD if Arsenal.mastered(id) else Palette.TEXT)
	row.add_child(kl)
	v.add_child(row)
	return p
