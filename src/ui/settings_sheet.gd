extends Control

## OPTIONS, made like a console menu: a chunky framed card over a blurred
## backdrop, four tabs (AUDIO / VIDEO / GAME / CONTROLS, switch with Q/E or
## the shoulder buttons), rows you walk with up/down and change with
## left/right: segmented pixel meters for volumes and strengths, < VALUE >
## pickers, ON/OFF pills. Everything saves and applies at once. RESET GAME
## asks twice and writes a backup first.

signal need_refresh
signal closed

const TABS := ["AUDIO", "VIDEO", "GAME", "CONTROLS"]

var _tab := 0
var _card: PanelContainer
var _list: VBoxContainer
var _tab_btns: Array[Button] = []
var _hint: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Gfx.blur_backdrop(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_card = PanelContainer.new()
	var cs := preload("res://src/ui/clinic_featured.gd").card_style(true)
	cs.set_border_width_all(7)
	cs.content_margin_left = 30
	cs.content_margin_right = 30
	cs.content_margin_top = 18
	cs.content_margin_bottom = 18
	_card.add_theme_stylebox_override("panel", cs)
	_card.position = Vector2(150, 50)
	_card.custom_minimum_size = Vector2(980, 620)
	_card.size = Vector2(980, 620)
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	col.add_child(head)
	var t := UiKit.title("OPTIONS", 40, UiKit.GOLD)
	UiKit.title_icon(t, "head_options")
	head.add_child(t)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.alignment = BoxContainer.ALIGNMENT_END
	head.add_child(tabs)
	for i in TABS.size():
		var b := UiKit.button(TABS[i], Vector2(150, 46))
		b.add_theme_font_override("font", UiKit.title_font())
		b.focus_mode = Control.FOCUS_NONE
		var idx := i
		b.pressed.connect(func() -> void: _show(idx))
		tabs.add_child(b)
		_tab_btns.append(b)
	var rule := ColorRect.new()
	rule.color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.5)
	rule.custom_minimum_size = Vector2(0, 3)
	col.add_child(rule)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 430)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	col.add_child(foot)
	_hint = Label.new()
	_hint.text = "UP/DOWN  pick    LEFT/RIGHT  change    Q / E  tabs    B / ESC  back"
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_hint, 13, Palette.MUTED)
	foot.add_child(_hint)
	var back := UiKit.button("BACK", Vector2(170, 48))
	back.add_theme_font_override("font", UiKit.title_font())
	back.pressed.connect(_close)
	foot.add_child(back)
	UiKit.pop_in(_card)
	_show(0)


func _show(i: int) -> void:
	_tab = posmod(i, TABS.size())
	for k in _tab_btns.size():
		var b := _tab_btns[k]
		b.modulate = Color.WHITE if k == _tab else Color(0.6, 0.6, 0.66)
		b.scale = Vector2.ONE
	for c in _list.get_children():
		c.queue_free()
	match TABS[_tab]:
		"AUDIO":
			_meter("MASTER", func() -> float: return float(FamilyProfile.data.get("vol_master", 1.0)), func(v: float) -> void: _vol("vol_master", v))
			_meter("MUSIC", func() -> float: return float(FamilyProfile.data.get("vol_music", 0.72)), func(v: float) -> void: _vol("vol_music", v))
			_meter("SOUND EFFECTS", func() -> float: return float(FamilyProfile.data.get("vol_sfx", 1.0)), func(v: float) -> void: _vol("vol_sfx", v))
			_meter("VOICES", func() -> float: return float(FamilyProfile.data.get("vol_vo", 1.0)), func(v: float) -> void: _vol("vol_vo", v))
		"VIDEO":
			_pick("QUALITY", Gfx.QUALITY, func() -> int: return Gfx.quality(), func(v: int) -> void: _quality(v))
			_pick("DISPLAY", Gfx.MODES, func() -> int: return int(Gfx.get_v("mode")), func(v: int) -> void: Gfx.set_v("mode", v))
			var res_names: Array = []
			for r: Vector2i in Gfx.RESOLUTIONS:
				res_names.append("%d x %d" % [r.x, r.y])
			_pick("RESOLUTION", res_names, func() -> int: return int(Gfx.get_v("res")), func(v: int) -> void: Gfx.set_v("res", v))
			_toggle("VSYNC", func() -> bool: return bool(Gfx.get_v("vsync")), func(v: bool) -> void: Gfx.set_v("vsync", v))
			_pick("ANTI-ALIASING", Gfx.AA, func() -> int: return int(Gfx.get_v("aa")), func(v: int) -> void: Gfx.set_v("aa", v))
			_pick("FPS CAP", ["UNLIMITED", "30", "60", "120", "144"], func() -> int: return [0, 30, 60, 120, 144].find(int(Gfx.get_v("fps_cap"))), func(v: int) -> void: Gfx.set_v("fps_cap", [0, 30, 60, 120, 144][v]))
			_meter("BLOOM", func() -> float: return float(Gfx.get_v("bloom")), func(v: float) -> void: Gfx.set_v("bloom", v))
			_meter("MENU BLUR", func() -> float: return float(Gfx.get_v("blur")), func(v: float) -> void: Gfx.set_v("blur", v))
			_meter("BRIGHTNESS", func() -> float: return float(Gfx.get_v("bright")), func(v: float) -> void: Gfx.set_v("bright", v))
			_meter("CRT SCANLINES", func() -> float: return float(Gfx.get_v("crt")), func(v: float) -> void: Gfx.set_v("crt", v))
		"GAME":
			_meter("SCREEN SHAKE", func() -> float: return float(Gfx.get_v("shake")), func(v: float) -> void: Gfx.set_v("shake", v))
			_toggle("LESS GORE", func() -> bool: return FamilyProfile.less_gore(), func(v: bool) -> void: _flag("less_gore", v))
			_toggle("SKIP STORY FILMS", func() -> bool: return bool(FamilyProfile.data.get("skip_films", false)), func(v: bool) -> void: _flag("skip_films", v))
			_toggle("SPEECH BUBBLES AUTO", func() -> bool: return bool(FamilyProfile.data.get("talk_auto", false)), func(v: bool) -> void: _flag("talk_auto", v))
			_action("RESET GAME PROGRESS", "Start completely over on a clean save (options kept)", _confirm_reset, Palette.BRICK)
		"CONTROLS":
			for line in PadRouter.map_lines():
				var l := Label.new()
				l.text = str(line)
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.custom_minimum_size = Vector2(900, 0)
				l.add_theme_font_override("font", UiKit.pixel_font())
				UiKit.apply_label(l, 15, Palette.TEXT)
				_list.add_child(l)
	_focus_first.call_deferred()


func _focus_first() -> void:
	for c in _list.get_children():
		if c is Button:
			(c as Button).grab_focus()
			return


# --- Rows --------------------------------------------------------------------

func _row(title: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(900, 44)
	b.focus_mode = Control.FOCUS_ALL
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.06, 0.08, 0.15, 0.85)
	n.set_corner_radius_all(4)
	var f := n.duplicate() as StyleBoxFlat
	f.bg_color = Color(0.14, 0.17, 0.3, 0.95)
	f.border_color = UiKit.GOLD
	f.set_border_width_all(3)
	for s in ["normal", "disabled"]:
		b.add_theme_stylebox_override(s, n)
	for s in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(s, f)
	var l := Label.new()
	l.text = title
	l.position = Vector2(18, 8)
	l.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(l, 20, Palette.TEXT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.focus_entered.connect(func() -> void: Juice.play("res://assets/audio/chrome_ui.wav"))
	_list.add_child(b)
	return b


func _arrow_input(b: Button, step: Callable) -> void:
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e.is_action_pressed("ui_left") or e.is_action_pressed("p1_left"):
			step.call(-1)
			b.accept_event()
		elif e.is_action_pressed("ui_right") or e.is_action_pressed("p1_right"):
			step.call(1)
			b.accept_event()
	)


## Ten chunky segments; click a segment, or left/right in tenths.
func _meter(title: String, getter: Callable, setter: Callable) -> void:
	var b := _row(title)
	var bar := Control.new()
	bar.position = Vector2(470, 8)
	bar.size = Vector2(400, 28)
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_child(bar)
	var pct := Label.new()
	pct.position = Vector2(400, 8)
	pct.size = Vector2(60, 28)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(pct, 16, UiKit.GOLD)
	pct.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pct)
	var redraw := func() -> void:
		pct.text = "%d%%" % int(round(float(getter.call()) * 100.0))
		bar.queue_redraw()
	bar.draw.connect(func() -> void:
		var v: float = getter.call()
		for i in 10:
			var x := float(i) * 38.0
			bar.draw_rect(Rect2(x, 2, 34, 24), Color(0, 0, 0.02))
			var on: bool = float(i) < round(v * 10.0)
			var c: Color = UiKit.GOLD.lerp(Color(1.0, 0.95, 0.6), float(i) / 10.0) if on else Color(0.16, 0.18, 0.26)
			bar.draw_rect(Rect2(x + 3, 5, 28, 15), c)
			bar.draw_rect(Rect2(x + 3, 20, 28, 3), c.darkened(0.45))
	)
	bar.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			setter.call(clampf(ceilf(mb.position.x / 38.0) / 10.0, 0.0, 1.0))
			Juice.play("res://assets/audio/ui_click.wav")
			redraw.call()
	)
	_arrow_input(b, func(d: int) -> void:
		setter.call(clampf(snappedf(float(getter.call()) + 0.1 * float(d), 0.1), 0.0, 1.0))
		Juice.play("res://assets/audio/ui_click.wav")
		redraw.call()
	)
	redraw.call()


func _pick(title: String, values: Array, getter: Callable, setter: Callable) -> void:
	var b := _row(title)
	var l := Label.new()
	l.position = Vector2(520, 8)
	l.size = Vector2(300, 28)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(l, 20, UiKit.GOLD)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	var redraw := func() -> void:
		l.text = "<   %s   >" % str(values[clampi(int(getter.call()), 0, values.size() - 1)])
	var step := func(d: int) -> void:
		setter.call(posmod(int(getter.call()) + d, values.size()))
		Juice.play("res://assets/audio/ui_click.wav")
		redraw.call()
	_arrow_input(b, step)
	b.pressed.connect(func() -> void: step.call(1))
	redraw.call()


func _toggle(title: String, getter: Callable, setter: Callable) -> void:
	var b := _row(title)
	var pill := Label.new()
	pill.position = Vector2(620, 6)
	pill.size = Vector2(120, 32)
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_theme_font_override("font", UiKit.title_font())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pill)
	var redraw := func() -> void:
		var on: bool = getter.call()
		pill.text = "ON" if on else "OFF"
		var st := UiKit.panel(Color(0.18, 0.5, 0.26) if on else Color(0.22, 0.12, 0.14), UiKit.GOLD if on else Palette.MUTED)
		pill.add_theme_stylebox_override("normal", st)
		UiKit.apply_label(pill, 18, Palette.TEXT)
	var flip := func(_d: int = 0) -> void:
		setter.call(not bool(getter.call()))
		Juice.play("res://assets/audio/ui_click.wav")
		redraw.call()
	_arrow_input(b, flip)
	b.pressed.connect(func() -> void: flip.call())
	redraw.call()


func _action(title: String, sub: String, cb: Callable, col: Color) -> void:
	var b := _row(title)
	(b.get_child(0) as Label).add_theme_color_override("font_color", col.lightened(0.3))
	var l := Label.new()
	l.text = sub
	l.position = Vector2(400, 12)
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 14, Palette.MUTED)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.pressed.connect(cb)


func _vol(key: String, v: float) -> void:
	FamilyProfile.data[key] = v
	FamilyProfile.save()
	Mixer.apply_volumes()


func _flag(key: String, v: bool) -> void:
	FamilyProfile.data[key] = v
	FamilyProfile.save()


## Presets nudge the strengths too.
func _quality(v: int) -> void:
	Gfx.set_v("quality", v)
	Gfx.set_v("bloom", [0.0, 0.3, 0.45, 0.6][v])
	Gfx.set_v("aa", [0, 1, 1, 3][v])
	_show(_tab)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_pause"):
		_close()
	elif _key(event, KEY_Q) or _joy(event, JOY_BUTTON_LEFT_SHOULDER):
		_show(_tab - 1)
	elif _key(event, KEY_E) or _joy(event, JOY_BUTTON_RIGHT_SHOULDER):
		_show(_tab + 1)
	else:
		return
	get_viewport().set_input_as_handled()


func _key(e: InputEvent, k: Key) -> bool:
	return e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo and (e as InputEventKey).keycode == k


func _joy(e: InputEvent, b: JoyButton) -> bool:
	return e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed and (e as InputEventJoypadButton).button_index == b


func _close() -> void:
	Juice.play("res://assets/audio/ui_click.wav")
	closed.emit()
	queue_free()


func _confirm_reset() -> void:
	var wrap := ColorRect.new()
	wrap.color = Color(0, 0, 0.02, 0.85)
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.size = Vector2(1280, 720)
	add_child(wrap)
	var card := PanelContainer.new()
	var cs := preload("res://src/ui/clinic_featured.gd").card_style(true)
	cs.border_color = Palette.BRICK
	cs.shadow_color = Color(Palette.BRICK.r, Palette.BRICK.g, Palette.BRICK.b, 0.5)
	cs.content_margin_left = 30
	cs.content_margin_right = 30
	cs.content_margin_top = 20
	cs.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", cs)
	card.position = Vector2(340, 220)
	card.custom_minimum_size = Vector2(600, 0)
	wrap.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	var h := UiKit.title("RESET THE WHOLE GAME?", 30, Palette.BRICK)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var b := Label.new()
	b.text = Copy.RESET_BLURB
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(540, 0)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(b, 15, Palette.TEXT)
	col.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var yes := UiKit.button("YES, WIPE IT", Vector2(230, 50))
	yes.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, UiKit.GOLD))
	yes.pressed.connect(func() -> void:
		FamilyProfile.reset_progress()
		Juice.unlock_logo("WIPED", "Clean save. Restarting the night...")
		var t := get_tree().create_timer(1.2, true, false, true)
		t.timeout.connect(FamilyProfile.restart_clean)
	)
	var no := UiKit.button("NO, KEEP IT", Vector2(230, 50))
	no.pressed.connect(wrap.queue_free)
	row.add_child(no)
	row.add_child(yes)
	col.add_child(row)
	no.grab_focus()
