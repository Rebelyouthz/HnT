extends VBoxContainer

## The clinic's front page (reference board): seven big picture cards, four
## on top and three under, each a chunky double-framed tile that is mostly
## picture with the name in pixel caps. Unbuilt rooms wear a padlock. A card
## press emits pick(id); the page shows the detail popup.

signal pick(id: String)

const FEATURED := ["pawn_shop", "radio_tower", "blood_fridge", "dojo", "workshop", "wardrobe_cage", "trophy_cabinet"]
const CARD := Vector2(236, 168)

var _names := {}


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 16)
	var list: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	if list is Array:
		for b: Variant in list:
			if b is Dictionary:
				_names[str((b as Dictionary)["id"])] = str((b as Dictionary)["name"])
	for row_ids: Array in [FEATURED.slice(0, 4), FEATURED.slice(4)]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 18)
		for id: String in row_ids:
			row.add_child(_card(id))
		add_child(row)


## Wide menu art made for the cards (assets/ui/cards/<id>.png); the Dojo
## card shows the Father in his guard like the reference. Falls back to the
## building icon.
static func card_art(id: String) -> Texture2D:
	if id == "dojo":
		var sf := SpriteBook.frames("father")
		if sf.has_animation("jab"):
			var info := SpriteBook.clip_info("father", "jab")
			var fr := sf.get_frame_texture("jab", maxi(0, int(info.get("hit", 0))))
			# Drop the empty cell margin so he fills the card.
			if fr is AtlasTexture:
				var tight := AtlasTexture.new()
				tight.atlas = (fr as AtlasTexture).atlas
				tight.region = (fr as AtlasTexture).region
				return tight
			return fr
	var p := "res://assets/ui/cards/%s.png" % id
	# The radio card art is a bare antenna; the hub icon (tower, dish, moon)
	# reads far better on the card.
	if id != "radio_tower" and ResourceLoader.exists(p):
		return load(p) as Texture2D
	return SpriteBook.icon(id)


static func card_name(id: String, fallback: String) -> String:
	match id:
		"blood_fridge":
			return "FRIDGE"
		"wardrobe_cage":
			return "LOCKER"
		"trophy_cabinet":
			return "AWARDS"
		"pawn_shop":
			return "PAWN SHOP"
		"radio_tower":
			return "RADIO TOWER"
		"dojo":
			return "DOJO"
	return fallback.to_upper()


## Chunky double frame: dark outer rim, gold inner line, navy face, a solid
## base under it (3D) and a warm glow when lit.
static func card_style(lit: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.075, 0.15, 0.96)
	s.border_color = UiKit.GOLD if lit else Color(0.42, 0.3, 0.14)
	s.set_border_width_all(5)
	s.set_corner_radius_all(7)
	s.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.5) if lit else Color(0, 0, 0.02, 0.9)
	s.shadow_size = 14 if lit else 1
	s.shadow_offset = Vector2(0, 2) if lit else Vector2(0, 6)
	s.anti_aliasing = true
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 8
	return s


func _card(id: String) -> Control:
	var lvl := FamilyProfile.building_level(id)
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.focus_mode = Control.FOCUS_ALL
	var normal := card_style(false)
	var lit := card_style(true)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("focus", lit)
	var pressed := lit.duplicate() as StyleBoxFlat
	pressed.shadow_offset = Vector2(0, 0)
	b.add_theme_stylebox_override("pressed", pressed)
	b.pressed.connect(func() -> void:
		Juice.play("res://assets/audio/ui_click.wav")
		pick.emit(id)
	)
	# Inner gold hairline (the second frame of the double rim).
	var inner := Panel.new()
	var ist := StyleBoxFlat.new()
	ist.bg_color = Color(0, 0, 0, 0)
	ist.border_color = Color(0.85, 0.66, 0.3, 0.55)
	ist.set_border_width_all(2)
	ist.set_corner_radius_all(4)
	inner.add_theme_stylebox_override("panel", ist)
	inner.position = Vector2(7, 7)
	inner.size = CARD - Vector2(14, 14)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)
	var pic := TextureRect.new()
	pic.texture = card_art(id)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = SpriteBook.UI_FILTER
	pic.position = Vector2(14, 10)
	pic.size = Vector2(CARD.x - 28, 112)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	if lvl <= 0:
		pic.modulate = Color(0.7, 0.7, 0.78)
		var lock := PixelIcon.new()
		lock.kind = "lock"
		lock.size = Vector2(40, 40)
		lock.position = Vector2(CARD.x * 0.5 - 20, 78)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lock)
	else:
		var lv := Label.new()
		lv.text = "LV %d" % lvl
		lv.position = Vector2(16, 12)
		lv.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(lv, 13, UiKit.GOLD)
		lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lv)
	var name_l := Label.new()
	name_l.text = card_name(id, str(_names.get(id, id)))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.position = Vector2(0, CARD.y - 44)
	name_l.size = Vector2(CARD.x, 30)
	name_l.add_theme_font_override("font", UiKit.title_font())
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.add_theme_color_override("font_color", Palette.TEXT)
	name_l.add_theme_color_override("font_outline_color", UiKit.INK)
	name_l.add_theme_constant_override("outline_size", 6)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(name_l)
	if FamilyProfile.is_unseen("build_%s" % id):
		var dot := UiKit.new_dot()
		dot.position = Vector2(CARD.x - 22, 10)
		b.add_child(dot)
	return b
