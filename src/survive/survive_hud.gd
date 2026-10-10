class_name SurviveHud
extends CanvasLayer

## The coping hour's readout: the clock (big, top centre), kills, the level
## and XP bar along the bottom, owned abilities with their level pips and
## the four item slots.

var _clock: Label
var _kills: Label
var _lv: Label
var _icons: HBoxContainer
var _items: HBoxContainer
var _dirty := true
var _ult: ColorRect
var _ult_lab: Label
var _t := 0.0


func _ready() -> void:
	layer = 18
	var root := PixelStage.attach_canvas(self)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# XP across the top like the genre's own HUDs: a long framed bar with the
	# level badge on its left end (drawn in _paint_xp).
	_xp = Control.new()
	_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp.position = Vector2(400, 8)
	_xp.size = Vector2(870, 22)
	root.add_child(_xp)
	_xp.draw.connect(_paint_xp)
	_clock = Label.new()
	_clock.position = Vector2(0, 34)
	_clock.size = Vector2(1280, 40)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock.pivot_offset = Vector2(640, 20)
	_clock.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_clock, 30, Palette.LEMON)
	_clock.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_clock.add_theme_constant_override("outline_size", 6)
	root.add_child(_clock)
	_kills = Label.new()
	_kills.position = Vector2(0, 70)
	_kills.size = Vector2(1280, 20)
	_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_kills, 13, Palette.TEXT)
	_kills.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_kills.add_theme_constant_override("outline_size", 4)
	root.add_child(_kills)
	_lv = Label.new()
	_lv.visible = false
	root.add_child(_lv)
	_icons = HBoxContainer.new()
	_icons.position = Vector2(240, 660)
	_icons.add_theme_constant_override("separation", 6)
	root.add_child(_icons)
	_items = HBoxContainer.new()
	_items.position = Vector2(860, 660)
	_items.add_theme_constant_override("separation", 6)
	root.add_child(_items)
	# ULTIMATE: kills charge it; SPECIAL fires it when the bar is full.
	var ubg := ColorRect.new()
	ubg.color = Color(0, 0, 0, 0.6)
	ubg.position = Vector2(560, 94)
	ubg.size = Vector2(160, 6)
	root.add_child(ubg)
	_ult = ColorRect.new()
	_ult.color = Color(1.0, 0.56, 0.12)
	_ult.position = ubg.position
	_ult.size = Vector2(0, 6)
	root.add_child(_ult)
	_ult_lab = Label.new()
	_ult_lab.position = Vector2(440, 100)
	_ult_lab.size = Vector2(400, 18)
	_ult_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_ult_lab, 11, Color(1.0, 0.7, 0.35))
	_ult_lab.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_ult_lab.add_theme_constant_override("outline_size", 4)
	root.add_child(_ult_lab)


var _xp: Control
var _xp_shown := 0.0
var _xp_flash := 0.0
var _last_lv := -1
var _last_sec := -1


func _process(_d: float) -> void:
	var run := SurviveRun.get_run(get_tree())
	var horde := get_tree().get_first_node_in_group("horde")
	_t += _d
	if horde:
		var left := int(horde.left())
		_clock.text = "%d:%02d" % [left / 60, left % 60]
		_clock.add_theme_color_override("font_color", Palette.BRICK if left < 30 else Palette.LEMON)
		# The last ten seconds tick with a thump.
		if left != _last_sec:
			_last_sec = left
			if left <= 10 and left > 0:
				_clock.scale = Vector2(1.3, 1.3)
				create_tween().tween_property(_clock, "scale", Vector2.ONE, 0.25)
		_kills.text = "%d KILLS   ·   %d S-COINS" % [int(horde.kills), run.coins if run else 0]
	if run == null:
		return
	if not run.changed.is_connected(_mark):
		run.changed.connect(_mark)
	# Two heroes: the Father's plate takes the top right, so the bar ends
	# before it.
	var duo := get_tree().get_nodes_in_group("players").size() > 1
	_xp.size.x = 480.0 if duo else 870.0
	var k := clampf(run.ult_charge / SurviveRun.ULT_NEED, 0.0, 1.0)
	_ult.size.x = 160.0 * k
	var uname := str(run.row("ultimates", run.ult).get("name", "ULTIMATE"))
	if k >= 1.0:
		_ult.color = Color(1.0, 0.56, 0.12).lerp(Color.WHITE, 0.5 + 0.5 * sin(_t * 10.0))
		_ult_lab.text = "%s READY  ·  SPECIAL" % uname
	else:
		_ult.color = Color(1.0, 0.56, 0.12)
		_ult_lab.text = uname
	var goal := clampf(float(run.xp) / float(maxi(1, run.need())), 0.0, 1.0)
	if run.level != _last_lv:
		if _last_lv != -1:
			_xp_flash = 1.0
			_xp_shown = 0.0
		_last_lv = run.level
	_xp_shown = lerpf(_xp_shown, goal, 1.0 - exp(-12.0 * _d))
	_xp_flash = maxf(0.0, _xp_flash - _d * 1.6)
	_xp.queue_redraw()
	if _dirty:
		_dirty = false
		_rebuild(run)


func _paint_xp() -> void:
	var run := SurviveRun.get_run(get_tree())
	if run == null:
		return
	var w := _xp.size.x
	var h := _xp.size.y
	var badge := 58.0
	var bar := Rect2(badge - 4.0, 4, w - badge + 4.0, h - 8.0)
	# Frame: ink shadow, gold rim, dark well.
	_xp.draw_rect(Rect2(bar.position + Vector2(0, 3), bar.size), Color(0, 0, 0, 0.45))
	_xp.draw_rect(bar.grow(2), UiKit.INK)
	_xp.draw_rect(bar.grow(1), UiKit.RIM)
	_xp.draw_rect(bar, Color(0.02, 0.04, 0.05, 0.92))
	var fill := Rect2(bar.position, Vector2(bar.size.x * _xp_shown, bar.size.y))
	if fill.size.x > 0.5:
		var lo := Color(0.18, 0.75, 0.45)
		var hi := Color(0.55, 1.0, 0.7)
		_xp.draw_rect(fill, lo)
		_xp.draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.45)), hi)
		_xp.draw_rect(Rect2(fill.position + Vector2(0, 1), Vector2(fill.size.x, 1)), Color(1, 1, 1, 0.45))
		# A glint that runs along the fill.
		var gx := fmod(_t * 220.0, maxf(fill.size.x + 60.0, 1.0)) - 30.0
		if gx > 0.0 and gx < fill.size.x - 6.0:
			_xp.draw_rect(Rect2(fill.position + Vector2(gx, 0), Vector2(6, fill.size.y)), Color(1, 1, 1, 0.22))
		# Leading edge.
		_xp.draw_rect(Rect2(Vector2(fill.end.x - 2.0, fill.position.y), Vector2(2, fill.size.y)), Color(0.85, 1.0, 0.9))
	# Tick marks every tenth.
	for i in range(1, 10):
		var x := bar.position.x + bar.size.x * float(i) / 10.0
		_xp.draw_line(Vector2(x, bar.position.y + 1), Vector2(x, bar.end.y - 1), Color(0, 0, 0, 0.35), 1.0)
	if _xp_flash > 0.0:
		_xp.draw_rect(bar.grow(2), Color(1, 1, 0.8, _xp_flash * 0.8))
	# Level badge: a chunky gold plate.
	var b := Rect2(0, 0, badge, h)
	_xp.draw_rect(Rect2(b.position + Vector2(0, 3), b.size), Color(0, 0, 0, 0.5))
	_xp.draw_rect(b, UiKit.INK)
	_xp.draw_rect(b.grow(-2), UiKit.GOLD.darkened(0.25))
	_xp.draw_rect(Rect2(b.position + Vector2(2, 2), Vector2(badge - 4.0, h * 0.42)), UiKit.GOLD)
	var font := UiKit.title_font()
	var txt := "LV %d" % run.level
	var fs := 14
	var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var at := Vector2((badge - sz.x) * 0.5, h * 0.5 + sz.y * 0.32)
	_xp.draw_string_outline(font, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, UiKit.INK)
	_xp.draw_string(font, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.98, 0.9) if _xp_flash <= 0.0 else Color(1, 1, 1))


func _mark() -> void:
	_dirty = true


func _slot(tex: Texture2D, frame: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0, 0, 0, 0.6), frame))
	p.custom_minimum_size = Vector2(40, 40)
	var pic := UiKit.portrait(tex, Vector2(32, 32))
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(pic)
	return p


func _rebuild(run: SurviveRun) -> void:
	for c in _icons.get_children():
		c.queue_free()
	for c in _items.get_children():
		c.queue_free()
	for id in run.abilities:
		var r := run.row("abilities", str(id))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		v.add_child(_slot(SurviveIcons.tex(str(r.get("icon", ""))), Color(0.5, 0.85, 1.0)))
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 1)
		for k in SurviveRun.MAX_LV:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(5, 3)
			pip.color = Color(0.5, 0.85, 1.0) if k < int(run.abilities[id]) else Color(1, 1, 1, 0.15)
			pips.add_child(pip)
		v.add_child(pips)
		_icons.add_child(v)
	for i in SurviveRun.MAX_ITEMS:
		if i < run.items.size():
			var it: Dictionary = run.items[i]
			_items.add_child(_slot(SurviveIcons.tex(str(it.get("icon", ""))), Color(1.0, 0.8, 0.3)))
		else:
			_items.add_child(_slot(null, Color(1, 1, 1, 0.2)))
