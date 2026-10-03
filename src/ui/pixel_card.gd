class_name PixelCard
extends Control

## A level-up card made like a physical object: a thick bevelled frame in
## the rarity's metal (steel, jade, cobalt, amethyst, gold) with light on the
## top-left edges and shade on the bottom-right, a recessed socket at the top
## where the card-type emblem sits, an art slot sunk into the face with the
## big icon inside it, the name on a plate, rarity gems, stat meters and the
## rule text. Legendary gets a shine that sweeps across. `face_up` false
## draws the card back. Everything is drawn on a 2 px grid.

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
	"AIR": "boot", "COOP": "heart", "BLEED": "drop", "SNAP": "bolt", "REVIVE": "cross", "SHOT": "star",
	"STEAM": "drop", "GOLD": "gold", "BLOCK": "shield", "PARRY": "shield", "THROW": "fist", "HEAVY": "fist",
	"LIGHT": "fist", "STOMP": "boot", "HEAT": "eye", "PARKOUR": "boot", "COMBO": "bolt", "RULE": "star",
}
const STAT_OF := {
	"AIR": ["MOBILITY", "DAMAGE"], "COOP": ["TEAM", "SUSTAIN"], "BLEED": ["DAMAGE", "TEMPO"], "SNAP": ["FINISH", "SUSTAIN"],
	"REVIVE": ["SUSTAIN", "TEAM"], "SHOT": ["RANGE", "DAMAGE"], "STEAM": ["TEMPO", "SUSTAIN"], "GOLD": ["LOOT", "LUCK"],
	"BLOCK": ["DEFENCE", "TEMPO"], "PARRY": ["DEFENCE", "FINISH"], "THROW": ["DAMAGE", "CONTROL"], "HEAVY": ["DAMAGE", "CONTROL"],
}

var info: Dictionary = {}
var face_up := true
var lit := false
var _t := 0.0
var _icon: PixelIcon
var _emblem: PixelIcon
var _labels: Array[Control] = []


func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	pivot_offset = Vector2(W, H) * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_face()
	_show_face(face_up)


func rarity() -> String:
	return Rarity.normalize(str(info.get("rarity", "common")))


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
	_emblem = PixelIcon.new()
	_emblem.kind = str(TYPE_ICON.get(tag(), "star"))
	_emblem.size = Vector2(34, 34)
	_emblem.position = Vector2(W * 0.5 - 17, 13)
	_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_emblem)
	_labels.append(_emblem)
	_icon = PixelIcon.new()
	_icon.kind = _glyph()
	_icon.size = Vector2(88, 88)
	_icon.position = Vector2(W * 0.5 - 44, 86)
	_icon.pivot_offset = Vector2(44, 44)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_labels.append(_icon)
	_label(str(info.get("name", "?")), Vector2(22, 210), W - 44, 22, Palette.TEXT if rarity() == "common" else p[1], true)
	_label(Rarity.label(rarity()) + "  ·  " + tag(), Vector2(22, 244), W - 44, 12, p[1])
	var stats := stat_rows()
	for i in stats.size():
		_label(str(stats[i][0]), Vector2(30, 280 + i * 22), 110, 12, Palette.TEXT).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label(str(info.get("blurb", "")), Vector2(26, 334), W - 52, 13, Color(0.86, 0.86, 0.82))


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
		_icon.scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 3.0))


# --- Drawing ---------------------------------------------------------------

func _px(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position.snapped(Vector2(2, 2)), r.size.snapped(Vector2(2, 2))), c)


## A raised bevel: light top/left, dark bottom/right, `t` px thick.
func _bevel(r: Rect2, face: Color, light: Color, dark: Color, t: float) -> void:
	_px(r, dark)
	_px(Rect2(r.position, Vector2(r.size.x - t, r.size.y - t)), light)
	_px(Rect2(r.position + Vector2(t, t), r.size - Vector2(t * 2, t * 2)), face)


## A sunk slot: dark top/left (inner shadow), light bottom/right lip.
func _socket(r: Rect2, inside: Color, p: Array, t: float) -> void:
	_px(r.grow(t), p[1])
	_px(Rect2(r.position - Vector2(t, t), r.size + Vector2(t, t)), p[2])
	_px(r, Color(0, 0, 0.02))
	_px(Rect2(r.position + Vector2(t, t), r.size - Vector2(t, t)), inside)


func _draw() -> void:
	var p := pal()
	var base: Color = p[0]
	var light: Color = p[1]
	var dark: Color = p[2]
	var deep: Color = p[3]
	# Drop shadow / thickness under the card (3D slab).
	_px(Rect2(6, 10, W, H), Color(0, 0, 0.02, 0.6))
	_px(Rect2(0, 6, W, H), dark.darkened(0.5))
	# Outer metal frame.
	_bevel(Rect2(0, 0, W, H), base, light, dark, 6)
	_px(Rect2(10, 10, W - 20, H - 20), UiKit.INK)
	if not face_up:
		_draw_back(p)
		return
	# Face plate.
	_bevel(Rect2(14, 14, W - 28, H - 28), deep, deep.lightened(0.18), Color(0, 0, 0.02), 4)
	# Rivets in the corners.
	for c in [Vector2(20, 20), Vector2(W - 26, 20), Vector2(20, H - 26), Vector2(W - 26, H - 26)]:
		_px(Rect2(c, Vector2(6, 6)), dark)
		_px(Rect2(c, Vector2(4, 4)), light)
	# Type emblem socket set into the top of the frame.
	_px(Rect2(W * 0.5 - 30, 0, 60, 8), base)
	_socket(Rect2(W * 0.5 - 22, 8, 44, 44), Color(0.05, 0.06, 0.1), p, 4)
	# Art slot: a deep hole with the icon sitting in it.
	var slot := Rect2(40, 66, W - 80, 128)
	_socket(slot, deep.darkened(0.4), p, 6)
	# Glow pooled in the slot behind the icon.
	var g := 0.35 + 0.15 * sin(_t * 2.5)
	for i in 6:
		var rr := 54.0 - float(i) * 8.0
		draw_circle(slot.get_center(), rr, Color(light.r, light.g, light.b, 0.05 * g * float(i + 1)))
	# Name plate.
	_bevel(Rect2(22, 204, W - 44, 38), dark, base, Color(0, 0, 0.02), 3)
	# Rarity gems.
	var n := Rarity.rank(rarity()) + 1
	for i in 5:
		var x := W * 0.5 - 50.0 + float(i) * 22.0
		_px(Rect2(x, 266, 14, 8), Color(0, 0, 0.02))
		_px(Rect2(x + 2, 268, 10, 4), light if i < n else Color(0.18, 0.18, 0.22))
	# Stat meters: segmented bars.
	var stats := stat_rows()
	for i in stats.size():
		var y := 282.0 + float(i) * 22.0
		var frac := float(stats[i][1])
		var segs := 10
		for s in segs:
			var x := 140.0 + float(s) * 13.0
			_px(Rect2(x, y, 11, 12), Color(0, 0, 0.02))
			if float(s) / float(segs) < frac:
				_px(Rect2(x + 2, y + 2, 7, 8), light if s % 2 == 0 else base)
	# Divider over the rule text.
	_px(Rect2(30, 328, W - 60, 2), dark)
	# Legendary / epic shine sweeping over the whole card.
	if rarity() == "legendary" or rarity() == "epic" or lit:
		var sweep := fmod(_t * (0.6 if rarity() == "legendary" else 0.35), 1.6) - 0.3
		var sx := sweep * (W + H)
		for k in 6:
			var off := float(k) * 6.0
			var pts := PackedVector2Array([Vector2(sx + off, 0), Vector2(sx + off + 6, 0), Vector2(sx + off + 6 - H * 0.6, H), Vector2(sx + off - H * 0.6, H)])
			draw_colored_polygon(pts, Color(1, 1, 0.9, 0.06 if k % 2 == 0 else 0.03))
	if lit:
		draw_rect(Rect2(-4, -4, W + 8, H + 8), Color(light.r, light.g, light.b, 0.5 + 0.3 * sin(_t * 6.0)), false, 4.0)


func _draw_back(p: Array) -> void:
	var base: Color = p[0]
	var dark: Color = p[2]
	_px(Rect2(14, 14, W - 28, H - 28), Color(0.07, 0.08, 0.14))
	# Diamond lattice.
	var step := 20.0
	var y := 14.0
	var row := 0
	while y < H - 20.0:
		var x := 14.0 + (step * 0.5 if row % 2 == 1 else 0.0)
		while x < W - 20.0:
			_px(Rect2(x + 8, y + 8, 4, 4), Color(dark.r, dark.g, dark.b, 0.9))
			x += step
		y += step * 0.5
		row += 1
	# The family crest socket in the middle.
	_socket(Rect2(W * 0.5 - 50, H * 0.5 - 50, 100, 100), Color(0.04, 0.05, 0.09), p, 6)
	draw_circle(Vector2(W * 0.5, H * 0.5), 32, Color(base.r, base.g, base.b, 0.9))
	draw_circle(Vector2(W * 0.5, H * 0.5), 24, Color(0.04, 0.05, 0.09))
	draw_string(UiKit.title_font(), Vector2(W * 0.5 - 22, H * 0.5 + 12), "H&T", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, base)
