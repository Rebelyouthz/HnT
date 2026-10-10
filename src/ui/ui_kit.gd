class_name UiKit
extends Object

## Menu look (Timmie's reference boards): deep navy cards with a thin
## antique-gold rim that lights up bright gold with a glow when selected,
## chunky gold pixel titles (Pixelify Sans) with a dark brown outline,
## pixel caps on buttons and tabs (Pixelify Sans 600), Rajdhani for body text.

const NAVY := Color(0.043, 0.066, 0.13, 0.94)
const NAVY_HI := Color(0.07, 0.1, 0.19, 0.97)
const RIM := Color(0.6, 0.45, 0.22)
const GOLD := Color(0.98, 0.78, 0.3)
const INK := Color(0.16, 0.09, 0.03)

static var _title_font: Font
static var _pixel_font: Font


static func title_font() -> Font:
	if _title_font == null:
		var base := load("res://assets/fonts/PixelifySans.ttf") as FontFile
		var v := FontVariation.new()
		v.base_font = base
		v.variation_opentype = {"wght": 700}
		v.spacing_glyph = 1
		_title_font = v
	return _title_font


## Pixel caps for buttons, tabs and card names.
static func pixel_font() -> Font:
	if _pixel_font == null:
		var v := FontVariation.new()
		v.base_font = load("res://assets/fonts/PixelifySans.ttf") as FontFile
		v.variation_opentype = {"wght": 600}
		v.spacing_glyph = 1
		_pixel_font = v
	return _pixel_font


static func panel(bg: Color = Palette.PANEL, border: Color = Palette.EDGE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	# The old flat greys read as navy glass now; accents keep their colour
	# but the default gold edge becomes the antique rim.
	s.bg_color = NAVY if bg == Palette.PANEL or bg == Palette.PANEL_2 else bg
	s.border_color = RIM if border == Palette.EDGE else border
	# Chunky and cosy: thick rim, rounded pixel corners, and a solid dark
	# base under every box (hard drop) so panels and buttons read as 3D blocks.
	s.set_border_width_all(3)
	s.set_corner_radius_all(5)
	s.shadow_color = Color(0.0, 0.0, 0.02, 0.85)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 5)
	s.anti_aliasing = true
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


## Framed card: near-black glass, lit rim, wide accent glow (reference look).
static func frame(accent: Color = Palette.EDGE, glow: float = 0.34) -> StyleBoxFlat:
	var s := panel(NAVY, accent)
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
	lab.add_theme_color_override("font_color", GOLD if color == Palette.EDGE else color)
	lab.add_theme_color_override("font_outline_color", INK)
	lab.add_theme_constant_override("outline_size", 5 if size < 22 else 8)
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


const UP_COL := "#5dff8a"
const DOWN_COL := "#ff5a4a"


## Stat text for cards: gains (+12%, +3) in green, costs (-10%, -2) in red.
const BASE_COL := "#d6d8e0"


## "old -> new" for a stat: the old value in a plain light grey, the new one
## green when it is better, red when worse (lower_better for cooldowns etc).
## `fmt` formats both numbers, e.g. "%.2f", "%d", "%d%%".
static func delta_bb(old: float, new: float, fmt := "%.2f", lower_better := false) -> String:
	var a := fmt % old
	var b := fmt % new
	if absf(new - old) < 0.0001:
		return "[color=%s]%s[/color]" % [BASE_COL, a]
	var better := (new < old) if lower_better else (new > old)
	return "[color=%s]%s[/color] [color=#8a8c98]›[/color] [color=%s]%s[/color]" % [BASE_COL, a, UP_COL if better else DOWN_COL, b]


static func stat_bbcode(text: String) -> String:
	if "[color" in text:
		return text
	var re := RegEx.new()
	re.compile("([+\\-\u2212]\\d+(?:\\.\\d+)?%?)")
	var out := ""
	var last := 0
	for m in re.search_all(text):
		out += text.substr(last, m.get_start() - last)
		var tok := m.get_string()
		out += "[color=%s]%s[/color]" % [UP_COL if tok.begins_with("+") else DOWN_COL, tok]
		last = m.get_end()
	return out + text.substr(last)


## A centred, outlined rich label for card text with coloured stats.
static func rich(text: String, w: float, size: int, color: Color, font: Font = null) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(w, 0)
	r.size = Vector2(w, 0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font != null:
		r.add_theme_font_override("normal_font", font)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	r.add_theme_constant_override("outline_size", 4)
	r.text = "[center]" + stat_bbcode(text) + "[/center]"
	return r


## Pad support: give focus to the first usable button under `root` (after
## layout), unless something inside it already has focus.
static func focus_first(root: Node) -> void:
	if root == null:
		return
	root.get_tree().process_frame.connect(func() -> void:
		if not is_instance_valid(root) or not root.is_inside_tree():
			return
		var vp := root.get_viewport()
		var cur := vp.gui_get_focus_owner() if vp else null
		if cur != null and root.is_ancestor_of(cur):
			return
		var b := _first_focusable(root)
		if b:
			b.grab_focus()
			return
		# Nothing to press yet (a fresh save): park focus on the page's
		# scroll box so a pad can still scroll it and back out.
		var sc := root.find_children("*", "ScrollContainer", true, false)
		if not sc.is_empty():
			var box := sc[0] as ScrollContainer
			box.focus_mode = Control.FOCUS_ALL
			box.grab_focus()
	, CONNECT_ONE_SHOT)


static func _first_focusable(n: Node) -> Control:
	for c in n.get_children():
		if c is Control and not (c as Control).is_visible_in_tree():
			continue
		if c is BaseButton and not (c as BaseButton).disabled and (c as Control).focus_mode != Control.FOCUS_NONE:
			return c
		var deep := _first_focusable(c)
		if deep:
			return deep
	return null


static func apply_label(lab: Label, size: int = 16, color: Color = Palette.TEXT) -> void:
	lab.add_theme_font_size_override("font_size", size)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lab.add_theme_constant_override("outline_size", 4)


static func button(text: String, min_size: Vector2 = Vector2(120, 44)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_override("font", pixel_font())
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Palette.TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Palette.MUTED)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	b.add_theme_constant_override("outline_size", 3)
	# 3D block buttons: face + rim on a solid base; hover lights the rim gold,
	# press sinks the face onto the base (text drops with it).
	var normal := panel(NAVY, RIM)
	normal.border_width_top = 3
	normal.border_width_bottom = 4
	var hover := panel(NAVY_HI, GOLD)
	hover.border_width_bottom = 4
	var pressed := panel(Color(0.2, 0.14, 0.06, 0.98), GOLD)
	pressed.shadow_offset = Vector2(0, 1)
	pressed.content_margin_top += 4
	pressed.content_margin_bottom -= 2
	var focus := hover.duplicate() as StyleBoxFlat
	focus.shadow_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.45)
	focus.shadow_size = 9
	focus.shadow_offset = Vector2(0, 3)
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
	Bevel.dress(b)
	press_feel(b)
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


## Currency readout like the reference: a small pixel icon, the name in
## pixel caps, the number - no box.
static func pill(title: String, value: String, accent: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := PixelIcon.new()
	icon.kind = title.to_lower()
	icon.custom_minimum_size = Vector2(IconBook.SIZE_S, IconBook.SIZE_S)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var t := Label.new()
	t.text = title.to_upper()
	t.add_theme_font_override("font", title_font())
	apply_label(t, 22, Palette.TEXT)
	t.add_theme_constant_override("outline_size", 6)
	t.add_theme_color_override("font_outline_color", INK)
	row.add_child(t)
	var v := Label.new()
	v.text = value
	v.name = "Value"
	v.add_theme_font_override("font", title_font())
	apply_label(v, 22, Palette.TEXT)
	v.add_theme_constant_override("outline_size", 6)
	v.add_theme_color_override("font_outline_color", INK)
	row.add_child(v)
	return row


## Upgrade juice on the control tagged `key` (meta "key") under `root`
## once a repaint has rebuilt it (next frame).
static func fx_after(root: Node, key: String, col: Color = GOLD, text := "", big := false) -> void:
	var tree := root.get_tree()
	tree.process_frame.connect(func() -> void:
		var top: Node = root if is_instance_valid(root) and root.is_inside_tree() else tree.root
		for c in (top.find_children("*", "Control", true, false) if key != "" else []):
			if str(c.get_meta("key", "")) == key and (c as Control).is_visible_in_tree():
				Juice.upgrade_fx(c as Control, col, text, big)
				return
		# Gone in the repaint: juice in the middle of the screen instead.
		Juice.upgrade_fx(null, col, text, big)
	, CONNECT_ONE_SHOT)


static func pulse_ready(b: Control) -> void:
	b.pivot_offset = b.custom_minimum_size * 0.5
	var tw := b.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(b, "scale", Vector2(1.07, 1.07), 0.42)
	tw.tween_property(b, "scale", Vector2.ONE, 0.42)


## Press feel for any button: it sinks and squashes while held, springs
## back on release, lifts a hair on hover.
const PENTA := [1.0, 1.122, 1.26, 1.498, 1.682, 2.0]


## Hold-to-confirm for big spends: the first press arms the button (it reads
## HOLD... and fills), keeping it down 0.6 s confirms. A tap does nothing.
static func hold_confirm(b: Button, on_confirm: Callable) -> void:
	var label := b.text
	var fill := ColorRect.new()
	fill.color = Color(1.0, 0.85, 0.3, 0.35)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(0, 0)
	b.add_child(fill)
	var tw_ref := [null]
	b.button_down.connect(func() -> void:
		b.text = "HOLD..."
		fill.size = Vector2(0, b.size.y)
		var tw := b.create_tween()
		tw_ref[0] = tw
		tw.tween_property(fill, "size:x", b.size.x, 0.6)
		tw.tween_callback(func() -> void:
			fill.size = Vector2.ZERO
			b.text = label
			on_confirm.call()
		)
	)
	b.button_up.connect(func() -> void:
		if tw_ref[0] != null and (tw_ref[0] as Tween).is_valid():
			(tw_ref[0] as Tween).kill()
		fill.size = Vector2.ZERO
		if is_instance_valid(b):
			b.text = label
	)


static func press_feel(b: BaseButton) -> void:
	b.resized.connect(func() -> void:
		b.pivot_offset = b.size * 0.5
	)
	b.button_down.connect(func() -> void:
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.95, 0.92), 0.05)
		b.modulate = Color(0.85, 0.85, 0.9)
	)
	b.button_up.connect(func() -> void:
		var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2(1.06, 1.06), 0.06)
		tw.tween_property(b, "scale", Vector2.ONE, 0.12)
		b.modulate = Color.WHITE
	)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.create_tween().tween_property(b, "scale", Vector2(1.03, 1.03), 0.08)
	)
	# Moving through a menu plays a little tune: each button's height picks
	# a note of a pentatonic scale.
	b.focus_entered.connect(func() -> void:
		if b.is_inside_tree() and not b.disabled:
			var step := int(absf(b.global_position.y + b.global_position.x * 0.25) / 36.0) % PENTA.size()
			Mixer.play_sfx("res://assets/audio/ui_click.wav", PENTA[step], -17.0)
	)
	b.mouse_exited.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08)
	)


## A burst for big moments (LEVEL UP text, rarity reveals): a shockwave ring
## and sparks flying out from `at` over a control layer.
static func blast(host: Control, at: Vector2, col: Color = Color(1.0, 0.85, 0.3), r := 260.0) -> void:
	if host == null:
		return
	var ring := Control.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = at
	ring.z_index = 50
	host.add_child(ring)
	var k := [0.0]
	var sparks: Array = []
	for i in 26:
		var a := TAU * float(i) / 26.0 + randf_range(-0.1, 0.1)
		sparks.append([Vector2.from_angle(a), randf_range(0.6, 1.0), randf_range(2.0, 5.0)])
	ring.draw.connect(func() -> void:
		var t: float = k[0]
		var rr := r * (1.0 - pow(1.0 - t, 3.0))
		ring.draw_arc(Vector2.ZERO, rr, 0, TAU, 64, Color(col.r, col.g, col.b, 0.8 * (1.0 - t)), 10.0 * (1.0 - t) + 2.0)
		ring.draw_arc(Vector2.ZERO, rr * 0.7, 0, TAU, 48, Color(1, 1, 1, 0.5 * (1.0 - t)), 3.0)
		for sp: Array in sparks:
			var p: Vector2 = sp[0] * rr * float(sp[1]) * 1.15
			ring.draw_line(p, p + sp[0] * 18.0 * (1.0 - t), Color(1, 0.95, 0.7, 1.0 - t), float(sp[2]) * (1.0 - t) + 1.0)
		if t < 0.25:
			ring.draw_circle(Vector2.ZERO, r * 0.35 * (1.0 - t * 4.0), Color(1, 1, 1, 0.4 * (1.0 - t * 4.0)))
	)
	var tw := ring.create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v: float) -> void:
		k[0] = v
		ring.queue_redraw()
	, 0.0, 1.0, 0.7)
	tw.tween_callback(ring.queue_free)


static func pop_in(n: Control) -> void:
	Bevel.dress(n, false, 0.7)
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


## Dark, readable text on a bright (READY green / gold) button.
## A lit "ready" button (claim / buy / go) that stays lit in every state:
## focus gets a white rim instead of falling back to the dark plate.
static func ready_style(b: Control) -> void:
	b.add_theme_stylebox_override("normal", panel(Palette.READY, Palette.LEMON))
	b.add_theme_stylebox_override("hover", panel(Palette.READY.lightened(0.12), Palette.LEMON))
	b.add_theme_stylebox_override("pressed", panel(Palette.READY.darkened(0.15), Palette.LEMON))
	b.add_theme_stylebox_override("focus", panel(Palette.READY.lightened(0.12), Color(1, 1, 1)))
	dark_text(b)


static func dark_text(b: Control) -> void:
	var c := Color(0.05, 0.12, 0.06)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, c)
	b.add_theme_color_override("font_outline_color", Color(0.75, 1.0, 0.75, 0.5))


## A header Label with its pixel icon in front (room made with spaces, so
## no layout has to change).
static func title_icon(lab: Label, icon_name: String) -> Label:
	var tex := IconBook.tex(icon_name)
	if tex == null or lab == null:
		return lab
	var fs := lab.get_theme_font_size("font_size")
	var font := lab.get_theme_font("font")
	var h := float(fs) * 1.15
	var sw := maxf(1.0, font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) if font else float(fs) * 0.3
	var n := int(ceil((h + float(fs) * 0.35) / sw))
	lab.text = " ".repeat(n) + lab.text
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(h, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_child(tr)
	# Keep it at the start of the text, vertically centred, as the label resizes.
	var place := func() -> void:
		if not is_instance_valid(tr):
			return
		var tw := font.get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if font else lab.size.x
		var x0 := 0.0
		if lab.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			x0 = (lab.size.x - tw) * 0.5
		elif lab.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			x0 = lab.size.x - tw
		tr.position = Vector2(x0, (lab.size.y - h) * 0.5)
	lab.resized.connect(place)
	place.call_deferred()
	return lab
