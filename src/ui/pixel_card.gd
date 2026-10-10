class_name PixelCard
extends Control

## A level-up card made like a physical object: a thick bevelled frame in
## the rarity's metal (steel, jade, cobalt, amethyst, gold) with light on the
## top-left edges and shade on the bottom-right, a recessed socket at the top
## where the card-type emblem sits, an art slot sunk into the face with the
## big icon inside it, the name on a plate, rarity gems, stat meters and the
## rule text. Legendary gets a shine that sweeps across. `face_up` false
## draws the card back. The frame, back and glow are pixel-art sprites
## (tools/card_art.py, a texel is 2 design px); the art is the thing's own
## IconBook icon. A lit card glows round its frame in its rarity colour.

const W := 300.0
const H := 440.0
const PALETTES := {
	"common": [Color(0.52, 0.55, 0.6), Color(0.78, 0.8, 0.84), Color(0.26, 0.28, 0.32), Color(0.1, 0.11, 0.14)],
	"uncommon": [Color(0.24, 0.62, 0.36), Color(0.5, 0.88, 0.58), Color(0.1, 0.3, 0.16), Color(0.05, 0.12, 0.08)],
	"rare": [Color(0.24, 0.44, 0.88), Color(0.52, 0.72, 1.0), Color(0.1, 0.18, 0.44), Color(0.05, 0.07, 0.16)],
	"epic": [Color(0.6, 0.3, 0.84), Color(0.84, 0.6, 1.0), Color(0.3, 0.12, 0.44), Color(0.1, 0.05, 0.15)],
	"legendary": [Color(0.92, 0.66, 0.2), Color(1.0, 0.9, 0.5), Color(0.5, 0.3, 0.06), Color(0.16, 0.1, 0.03)],
}
const TYPE_ICON := {
	"AIR": "node_jump", "COOP": "node_group", "BLEED": "tag_bleed", "SNAP": "bolt", "REVIVE": "node_heal",
	"SHOT": "cur_ammo", "STEAM": "node_steam", "GOLD": "cur_gold", "BLOCK": "t_armor", "PARRY": "t_armor",
	"THROW": "cur_knife", "HEAVY": "t_dmg", "LIGHT": "t_dmg", "STOMP": "node_stomp", "HEAT": "tag_fire",
	"PARKOUR": "node_speed", "COMBO": "node_combo", "RULE": "node_score", "STRING": "node_chain",
	"WEB": "card_pendulum_politics", "WANTED": "card_cop_out", "DASH": "card_family_blitz", "BANK": "meta_fortune",
	"MAGNET": "t_pickup", "ORBIT": "card_orbit_form", "AURA": "t_area", "VACUUM": "card_vacuum_hour",
	"SCORE": "node_pinball", "BOSS": "node_crown", "FINISH": "node_stomp", "PATROL": "t_cd", "CHASE": "card_courier_policy",
	"FARM": "card_orchard_copay", "VAULT": "card_brine_lungs", "PROP": "card_oil_policy", "COUNTER": "card_clash_policy",
	"STREET": "node_slide", "TOWER": "card_escape_clause",
}
const STAT_OF := {
	"AIR": ["MOBILITY", "DAMAGE"], "COOP": ["TEAM", "SUSTAIN"], "BLEED": ["DAMAGE", "TEMPO"], "SNAP": ["FINISH", "SUSTAIN"],
	"REVIVE": ["SUSTAIN", "TEAM"], "SHOT": ["RANGE", "DAMAGE"], "STEAM": ["TEMPO", "SUSTAIN"], "GOLD": ["LOOT", "LUCK"],
	"BLOCK": ["DEFENCE", "TEMPO"], "PARRY": ["DEFENCE", "FINISH"], "THROW": ["DAMAGE", "CONTROL"], "HEAVY": ["DAMAGE", "CONTROL"],
}

## What kind of thing the card gives, shown on a badge with its own glyph.
const KINDS := {
	"PASSIVE": ["PASSIVE", "star", Color(0.62, 0.72, 0.86)],
	"ACTIVE": ["ACTIVE", "bolt", Color(1.0, 0.6, 0.2)],
	"COMPANION": ["COMPANION / PET", "heart", Color(0.45, 0.9, 0.55)],
	"AUTOWEAPON": ["AUTOWEAPON", "eye", Color(1.0, 0.36, 0.32)],
	"MANUALWEAPON": ["MANUAL WEAPON", "fist", Color(1.0, 0.85, 0.3)],
}

var info: Dictionary = {}
var face_up := true
var lit := false
var _t := 0.0
var _icon: TextureRect
var _emblem: TextureRect
var _glow: TextureRect
var _frame_tex: Texture2D
var _back_tex: Texture2D
var _labels: Array[Control] = []


func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	pivot_offset = Vector2(W, H) * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_frame_tex = load("res://assets/sprites/cards/story_%s.png" % rarity())
	_back_tex = load("res://assets/sprites/cards/back_%s.png" % rarity())
	_glow = TextureRect.new()
	_glow.texture = load("res://assets/sprites/cards/glow_story.png")
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.position = Vector2(-16, -16)
	_glow.size = Vector2(W + 32, H + 32)
	_glow.show_behind_parent = true
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	_glow.visible = false
	add_child(_glow)
	_build_face()
	_show_face(face_up)


func rarity() -> String:
	return Rarity.normalize(str(info.get("rarity", "common")))


func kind() -> String:
	var k := str(info.get("kind", "PASSIVE")).to_upper()
	return k if KINDS.has(k) else "PASSIVE"


func tag() -> String:
	return str(info.get("tag", "RULE")).to_upper()


func pal() -> Array:
	return PALETTES.get(rarity(), PALETTES["common"])


func set_face(up: bool) -> void:
	face_up = up
	_show_face(up)
	queue_redraw()


func _show_face(up: bool) -> void:
	for c in _labels:
		c.visible = up


func _label(text: String, pos: Vector2, w: float, fsize: int, col: Color, title_font := false) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.custom_minimum_size = Vector2(w, 0)
	l.size = Vector2(w, 0)
	l.text = text
	l.add_theme_font_override("font", UiKit.title_font() if title_font else UiKit.pixel_font())
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", UiKit.INK)
	l.add_theme_constant_override("outline_size", 6 if title_font else 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	_labels.append(l)
	# Theme overrides re-measure the label; pin the wrap width again.
	l.set_deferred("size", Vector2(w, 0))
	return l


func _build_face() -> void:
	var p := pal()
	_emblem = IconBook.rect(str(TYPE_ICON.get(tag(), "node_score")), IconBook.SIZE_S)
	_emblem.position = Vector2(W * 0.5, 32) - _emblem.size * 0.5
	add_child(_emblem)
	_labels.append(_emblem)
	_icon = IconBook.rect(IconBook.for_card(info), IconBook.SIZE_L)
	_icon.position = Vector2(86, 66)
	add_child(_icon)
	_labels.append(_icon)
	# The thing's own name gets its own colour: weapons hot orange, skills
	# cyan, the rest in their rarity colour (common ones in gold, not grey).
	_label(str(info.get("name", "?")), Vector2(22, 210), W - 44, 22, _name_col(p), true)
	_label(Rarity.label(rarity()) + "  ·  " + tag(), Vector2(22, 244), W - 44, 12, p[1])
	# Kind badge (top-left) and level (top-right).
	var kd: Array = KINDS[kind()]
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.03, 0.03, 0.06, 0.92)
	bs.border_color = kd[2]
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(3)
	bs.content_margin_left = 4
	bs.content_margin_right = 6
	badge.add_theme_stylebox_override("panel", bs)
	badge.position = Vector2(16, 58)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 3)
	var bi := PixelIcon.new()
	bi.kind = str(kd[1])
	bi.custom_minimum_size = Vector2(16, 16)
	bi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bh.add_child(bi)
	var bl2 := Label.new()
	bl2.text = str(kd[0])
	bl2.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(bl2, 10, kd[2])
	bh.add_child(bl2)
	badge.add_child(bh)
	add_child(badge)
	_labels.append(badge)
	if info.has("level"):
		var lv_now := int(info["level"])
		var lr := RichTextLabel.new()
		lr.bbcode_enabled = true
		lr.fit_content = true
		lr.scroll_active = false
		lr.autowrap_mode = TextServer.AUTOWRAP_OFF
		lr.position = Vector2(W - 150, 58)
		lr.size = Vector2(134, 20)
		lr.add_theme_font_override("normal_font", UiKit.pixel_font())
		lr.add_theme_font_size_override("normal_font_size", 11)
		lr.add_theme_color_override("font_outline_color", UiKit.INK)
		lr.add_theme_constant_override("outline_size", 4)
		lr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lt := ("LV " + UiKit.delta_bb(float(lv_now - 1), float(lv_now), "%d")) if bool(info.get("upgrade", false)) else "[color=%s]LV %d[/color]" % [UiKit.BASE_COL, lv_now]
		lr.text = "[right]%s[/right]" % lt
		add_child(lr)
		_labels.append(lr)
	var stats := stat_rows()
	for i in stats.size():
		_label(str(stats[i][0]), Vector2(32, 280 + i * 22), 110, 12, p[1].lerp(Color.WHITE, 0.25)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var bl := UiKit.rich(str(info.get("blurb", "")), W - 52, 13, Color(0.86, 0.86, 0.82), UiKit.pixel_font())
	bl.position = Vector2(26, 334)
	add_child(bl)
	_labels.append(bl)


func _name_col(p: Array) -> Color:
	var t := tag()
	if t in ["SHOT", "THROW"]:
		return Color(1.0, 0.58, 0.25)
	if t in ["AIR", "PARKOUR", "COMBO", "SNAP", "STEAM"]:
		return Color(0.45, 0.9, 1.0)
	if rarity() == "common":
		return UiKit.GOLD
	return p[1]


func _glyph() -> String:
	var t := (tag() + " " + str(info.get("id", ""))).to_lower()
	for pair in [["air", "boot"], ["steam", "drop"], ["gold", "gold"], ["gem", "gem"], ["snap", "bolt"], ["block", "shield"], ["parry", "shield"], ["heal", "heart"], ["revive", "cross"], ["coop", "heart"], ["bleed", "drop"], ["gun", "star"], ["shot", "star"], ["throw", "fist"], ["heavy", "fist"], ["light", "fist"]]:
		if str(pair[0]) in t:
			return str(pair[1])
	return "star"


## Two meters: from the card's own stats if it lists any, otherwise the
## card type's main strengths scaled by rarity.
func stat_rows() -> Array:
	var out: Array = []
	var st: Variant = info.get("stats", {})
	if st is Dictionary and not (st as Dictionary).is_empty():
		for k in (st as Dictionary).keys():
			var v := float(str((st as Dictionary)[k]).to_float())
			out.append([str(k).to_upper(), clampf(absf(v) / 50.0, 0.15, 1.0)])
			if out.size() >= 2:
				break
		return out
	var r := Rarity.rank(rarity())
	var names: Array = STAT_OF.get(tag(), ["POWER", "STYLE"])
	out.append([names[0], clampf(0.3 + 0.16 * float(r), 0.0, 1.0)])
	out.append([names[1], clampf(0.18 + 0.12 * float(r), 0.0, 1.0)])
	return out


func _process(delta: float) -> void:
	_t += delta
	if face_up and (rarity() == "legendary" or rarity() == "epic" or lit):
		queue_redraw()
	if _icon and face_up:
		# Bob on whole design pixels only (keeps the pixel grid).
		_icon.position.y = 66.0 + roundf(sin(_t * 3.0) * 2.0) * 2.0
	if _glow:
		_glow.visible = lit and face_up
		if lit:
			var gc: Color = pal()[1]
			var k := 1.6 + 0.6 * sin(_t * 5.0)
			_glow.modulate = Color(gc.r * k, gc.g * k, gc.b * k, 1.0)


# --- Drawing ---------------------------------------------------------------

func _px(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position.snapped(Vector2(2, 2)), r.size.snapped(Vector2(2, 2))), c)


func _draw() -> void:
	var p := pal()
	var light: Color = p[1]
	var base: Color = p[0]
	# Drop shadow / thickness under the card.
	_px(Rect2(6, 10, W, H), Color(0, 0, 0.02, 0.6))
	if not face_up:
		draw_texture_rect(_back_tex, Rect2(0, 0, W, H), false)
		return
	draw_texture_rect(_frame_tex, Rect2(0, 0, W, H), false)
	# Stat meters: segmented bars on the rule panel.
	var stats := stat_rows()
	# What you have in light grey; what this card adds in green (an upgrade
	# shows last level's share in grey and the new level's gain in green).
	var lvl := int(info.get("level", 1))
	var up := bool(info.get("upgrade", false)) and lvl > 1
	for i in stats.size():
		var y := 282.0 + float(i) * 22.0
		var frac := float(stats[i][1])
		var prev := frac * float(lvl - 1) / float(lvl) if up else 0.0
		var segs := 10
		for sgm in segs:
			var x := 140.0 + float(sgm) * 13.0
			var f := float(sgm) / float(segs)
			_px(Rect2(x, y, 11, 12), Color(0, 0, 0.02))
			if f < prev:
				_px(Rect2(x + 2, y + 2, 8, 8), Color(0.86, 0.87, 0.9) if sgm % 2 == 0 else Color(0.72, 0.73, 0.78))
			elif f < frac:
				var g := Color(0.36, 1.0, 0.52) if up else (light if sgm % 2 == 0 else base)
				_px(Rect2(x + 2, y + 2, 8, 8), g)
	# Legendary / epic shine sweeping over the whole card.
	if rarity() == "legendary" or rarity() == "epic" or lit:
		var sweep := fmod(_t * (0.6 if rarity() == "legendary" else 0.35), 1.6) - 0.3
		var sx := sweep * (W + H)
		for k in 6:
			var off := float(k) * 6.0
			var pts := PackedVector2Array([Vector2(sx + off, 0), Vector2(sx + off + 6, 0), Vector2(sx + off + 6 - H * 0.6, H), Vector2(sx + off - H * 0.6, H)])
			draw_colored_polygon(pts, Color(1, 1, 0.9, 0.06 if k % 2 == 0 else 0.03))
	if lit:
		# Sparks running round the frame.
		var per := 2.0 * (W + H)
		for k in 6:
			var d := fmod(_t * 160.0 + float(k) * per / 6.0, per)
			var q := Vector2.ZERO
			if d < W:
				q = Vector2(d, 2)
			elif d < W + H:
				q = Vector2(W - 4, d - W)
			elif d < 2.0 * W + H:
				q = Vector2(W - (d - W - H), H - 4)
			else:
				q = Vector2(2, H - (d - 2.0 * W - H))
			_px(Rect2(q.snapped(Vector2(2, 2)), Vector2(4, 4)), Color(light.r, light.g, light.b, 0.95))
			_px(Rect2(q.snapped(Vector2(2, 2)) + Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1))
