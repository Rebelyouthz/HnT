class_name UiKit
extends Object

static func panel(bg: Color = Palette.PANEL, border: Color = Palette.EDGE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


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
	b.add_theme_stylebox_override("normal", panel(Palette.PANEL_2, Palette.EDGE))
	b.add_theme_stylebox_override("hover", panel(Palette.BRICK, Palette.LEMON))
	b.add_theme_stylebox_override("pressed", panel(Palette.BRICK, Palette.LEMON))
	b.add_theme_stylebox_override("focus", panel(Palette.PANEL_2, Palette.LEMON))
	b.add_theme_stylebox_override("disabled", panel(Palette.PANEL, Palette.LOCK))
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
