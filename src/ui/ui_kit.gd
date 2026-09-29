class_name UiKit
extends Object

## Menu look: dark glass panels with a thin lit rim and a soft outer glow in
## the accent colour, Cinzel titles, Rajdhani numbers and body text.

static var _title_font: Font


static func title_font() -> Font:
	if _title_font == null:
		var base := load("res://assets/fonts/Cinzel.ttf") as FontFile
		var v := FontVariation.new()
		v.base_font = base
		v.variation_opentype = {"wght": 700}
		v.spacing_glyph = 1
		_title_font = v
	return _title_font


static func panel(bg: Color = Palette.PANEL, border: Color = Palette.EDGE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	s.shadow_color = Color(border.r, border.g, border.b, 0.18)
	s.shadow_size = 5
	s.anti_aliasing = true
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


## Framed card: near-black glass, lit rim, wide accent glow (reference look).
static func frame(accent: Color = Palette.EDGE, glow: float = 0.34) -> StyleBoxFlat:
	var s := panel(Color(0.035, 0.04, 0.062, 0.95), accent)
	s.shadow_color = Color(accent.r, accent.g, accent.b, glow)
	s.shadow_size = 12
	s.border_width_top = 2
	s.border_width_bottom = 3
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func title(text: String, size: int = 28, color: Color = Palette.EDGE) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_override("font", title_font())
	lab.add_theme_font_size_override("font_size", size)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 4 if size < 22 else 6)
	# Only big headers glow; on small titles the halo smears the serifs.
	if size >= 22:
		lab.add_theme_color_override("font_shadow_color", Color(color.r, color.g, color.b, 0.3))
		lab.add_theme_constant_override("shadow_offset_x", 0)
		lab.add_theme_constant_override("shadow_offset_y", 0)
		lab.add_theme_constant_override("shadow_outline_size", 10)
	return lab


## Glowing progress bar (fill carries the accent, track stays dark glass).
static func glow_bar(ratio: float, accent: Color, size: Vector2 = Vector2(220, 10)) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = size
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = clampf(ratio, 0.0, 1.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.025, 0.04, 0.9)
	bg.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.set_corner_radius_all(3)
	fill.shadow_color = Color(accent.r, accent.g, accent.b, 0.55)
	fill.shadow_size = 6
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Stat tile: small caps label over a big number, lit rim in the accent.
static func stat_tile(label: String, value: String, accent: Color = Palette.EDGE, min_w: float = 120.0) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(min_w, 0)
	var st := panel(Color(0.05, 0.058, 0.09, 0.92), Color(accent.r, accent.g, accent.b, 0.7))
	st.shadow_size = 3
	box.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	var t := Label.new()
	t.text = label.to_upper()
	apply_label(t, 11, Color(accent.r, accent.g, accent.b, 0.95))
	var v := Label.new()
	v.text = value
	v.name = "Value"
	apply_label(v, 24, Palette.TEXT)
	col.add_child(t)
	col.add_child(v)
	box.add_child(col)
	return box


## Integers stored in JSON come back as floats; always print them whole.
static func num(v: Variant) -> String:
	if v is float and is_equal_approx(float(v), roundf(float(v))):
		return str(int(v))
	return str(v)


static func apply_label(lab: Label, size: int = 16, color: Color = Palette.TEXT) -> void:
	lab.add_theme_font_size_override("font_size", size)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lab.add_theme_constant_override("outline_size", 4)


static func button(text: String, min_size: Vector2 = Vector2(120, 44)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Palette.TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Palette.MUTED)
	var normal := panel(Color(0.07, 0.075, 0.11, 0.96), Palette.EDGE)
	var hover := panel(Color(0.2, 0.12, 0.08, 0.98), Palette.LEMON)
	hover.shadow_color = Color(Palette.LEMON.r, Palette.LEMON.g, Palette.LEMON.b, 0.45)
	hover.shadow_size = 10
	var pressed := panel(Palette.BRICK, Palette.LEMON)
	pressed.shadow_size = 12
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Palette.LEMON
	focus.shadow_color = Color(Palette.LEMON.r, Palette.LEMON.g, Palette.LEMON.b, 0.35)
	focus.shadow_size = 8
	var off := panel(Color(0.06, 0.06, 0.08, 0.9), Palette.LOCK)
	off.shadow_size = 0
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", off)
	b.resized.connect(func() -> void:
		b.pivot_offset = b.size * 0.5
	)
	b.pressed.connect(func() -> void:
		var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2(1.05, 1.05), 0.07)
		tw.tween_property(b, "scale", Vector2.ONE, 0.1)
	)
	return b


static func bang() -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Palette.BADGE
	s.set_corner_radius_all(11)
	s.set_border_width_all(1)
	s.border_color = Palette.TEXT
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = "!"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_label(l, 16, Color.WHITE)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func chrome() -> StyleBoxFlat:
	var s := panel(Color(0.16, 0.14, 0.1), Palette.EDGE)
	s.shadow_color = Color(0.79, 0.64, 0.15, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.border_width_left = 3
	s.border_width_right = 3
	s.border_width_top = 3
	s.border_width_bottom = 3
	return s


static func surface_dot(id: String) -> ColorRect:
	var d := new_dot()
	d.visible = FamilyProfile.is_unseen(id) or FamilyProfile.has_menu_alert()
	return d


static func new_dot() -> ColorRect:
	var d := ColorRect.new()
	d.color = Palette.BADGE
	d.custom_minimum_size = Vector2(12, 12)
	d.size = Vector2(12, 12)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


static func pill(title: String, value: String, accent: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", panel(Palette.PANEL_2, accent))
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	var t := Label.new()
	t.text = title
	apply_label(t, 12, accent)
	var v := Label.new()
	v.text = value
	v.name = "Value"
	apply_label(v, 18, Palette.TEXT)
	inner.add_child(t)
	inner.add_child(v)
	box.add_child(inner)
	row.add_child(box)
	return row


static func pulse_ready(b: Control) -> void:
	b.pivot_offset = b.custom_minimum_size * 0.5
	var tw := b.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(b, "scale", Vector2(1.07, 1.07), 0.42)
	tw.tween_property(b, "scale", Vector2.ONE, 0.42)


static func pop_in(n: Control) -> void:
	if n.size == Vector2.ZERO:
		n.pivot_offset = Vector2(
			absf(n.offset_right - n.offset_left) * 0.5,
			absf(n.offset_bottom - n.offset_top) * 0.5
		)
	else:
		n.pivot_offset = n.size * 0.5
	n.scale = Vector2(0.88, 0.88)
	var tw := n.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE, 0.2)


static func portrait(tex: Texture2D, size: Vector2 = Vector2(48, 48)) -> TextureRect:
	var pic := TextureRect.new()
	pic.custom_minimum_size = size
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = SpriteBook.UI_FILTER
	if tex:
		pic.texture = tex
	return pic
