class_name SurviveHud
extends CanvasLayer

## The coping hour's readout: the clock (big, top centre), kills, the level
## and XP bar along the bottom, owned abilities with their level pips and
## the four item slots.

var _clock: Label
var _kills: Label
var _lv: Label
var _bar: ColorRect
var _bar_bg: ColorRect
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
	_clock = Label.new()
	_clock.position = Vector2(0, 166)
	_clock.size = Vector2(1280, 40)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_clock, 30, Palette.LEMON)
	_clock.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_clock.add_theme_constant_override("outline_size", 6)
	root.add_child(_clock)
	_kills = Label.new()
	_kills.position = Vector2(0, 202)
	_kills.size = Vector2(1280, 20)
	_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_kills, 13, Palette.TEXT)
	_kills.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_kills.add_theme_constant_override("outline_size", 4)
	root.add_child(_kills)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0, 0, 0, 0.6)
	_bar_bg.position = Vector2(240, 700)
	_bar_bg.size = Vector2(800, 10)
	root.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.color = Color(0.35, 1.0, 0.55)
	_bar.position = Vector2(240, 700)
	_bar.size = Vector2(0, 10)
	root.add_child(_bar)
	_lv = Label.new()
	_lv.position = Vector2(150, 692)
	_lv.size = Vector2(84, 24)
	_lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiKit.apply_label(_lv, 14, Color(0.5, 1.0, 0.6))
	root.add_child(_lv)
	_icons = HBoxContainer.new()
	_icons.position = Vector2(240, 650)
	_icons.add_theme_constant_override("separation", 6)
	root.add_child(_icons)
	_items = HBoxContainer.new()
	_items.position = Vector2(860, 650)
	_items.add_theme_constant_override("separation", 6)
	root.add_child(_items)
	# ULTIMATE: kills charge it; SPECIAL fires it when the bar is full.
	var ubg := ColorRect.new()
	ubg.color = Color(0, 0, 0, 0.6)
	ubg.position = Vector2(540, 228)
	ubg.size = Vector2(200, 8)
	root.add_child(ubg)
	_ult = ColorRect.new()
	_ult.color = Color(1.0, 0.56, 0.12)
	_ult.position = ubg.position
	_ult.size = Vector2(0, 8)
	root.add_child(_ult)
	_ult_lab = Label.new()
	_ult_lab.position = Vector2(440, 236)
	_ult_lab.size = Vector2(400, 18)
	_ult_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_ult_lab, 11, Color(1.0, 0.7, 0.35))
	_ult_lab.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_ult_lab.add_theme_constant_override("outline_size", 4)
	root.add_child(_ult_lab)


func _process(_d: float) -> void:
	var run := SurviveRun.get_run(get_tree())
	var horde := get_tree().get_first_node_in_group("horde")
	if horde:
		var left := int(horde.left())
		_clock.text = "%d:%02d" % [left / 60, left % 60]
		_clock.add_theme_color_override("font_color", Palette.BRICK if left < 30 else Palette.LEMON)
		_kills.text = "%d KILLS" % int(horde.kills)
	if run == null:
		return
	if not run.changed.is_connected(_mark):
		run.changed.connect(_mark)
	_lv.text = "LV %d" % run.level
	_t += _d
	var k := clampf(run.ult_charge / SurviveRun.ULT_NEED, 0.0, 1.0)
	_ult.size.x = 200.0 * k
	var uname := str(run.row("ultimates", run.ult).get("name", "ULTIMATE"))
	if k >= 1.0:
		_ult.color = Color(1.0, 0.56, 0.12).lerp(Color.WHITE, 0.5 + 0.5 * sin(_t * 10.0))
		_ult_lab.text = "%s READY  ·  SPECIAL" % uname
	else:
		_ult.color = Color(1.0, 0.56, 0.12)
		_ult_lab.text = uname
	_bar.size.x = 800.0 * clampf(float(run.xp) / float(maxi(1, run.need())), 0.0, 1.0)
	if _dirty:
		_dirty = false
		_rebuild(run)


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
