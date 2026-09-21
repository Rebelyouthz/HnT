class_name Talk
extends CanvasLayer

var _lines: Array = []
var _i := 0
var _who: Label
var _body: Label
var _panel: PanelContainer
var _open := false


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	_panel.position = Vector2(180, 520)
	_panel.size = Vector2(920, 150)
	_panel.visible = false
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)
	_who = Label.new()
	UiKit.apply_label(_who, 13, Palette.EDGE)
	col.add_child(_who)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(880, 0)
	UiKit.apply_label(_body, 20, Palette.TEXT)
	col.add_child(_body)
	var hint := Label.new()
	hint.text = "LIGHT / JUMP  ·  NEXT     PAUSE  ·  SHUT UP"
	UiKit.apply_label(hint, 12, Palette.MUTED)
	col.add_child(hint)


func play(lines: Array) -> void:
	if lines.is_empty() or _open:
		return
	_lines = lines.duplicate()
	_i = 0
	_open = true
	_panel.visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.pivot_offset = _panel.size * 0.5
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.16)
	_paint()


func busy() -> bool:
	return _open


func _paint() -> void:
	if _i >= _lines.size():
		_close()
		return
	var row: Variant = _lines[_i]
	if typeof(row) != TYPE_DICTIONARY:
		_i += 1
		_paint()
		return
	var d: Dictionary = row
	var who := str(d.get("who", ""))
	_who.text = StoryBook.who_name(who)
	_who.add_theme_color_override("font_color", Palette.BRICK if who == "father" else (Palette.LEMON if who == "son" else Palette.EDGE))
	_body.text = str(d.get("text", ""))
	Juice.play("res://assets/audio/ui_click.wav")


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("p1_light") or event.is_action_pressed("p1_jump") or event.is_action_pressed("p2_light") or event.is_action_pressed("p2_jump"):
		_i += 1
		_paint()
		get_viewport().set_input_as_handled()


func _close() -> void:
	_open = false
	_panel.visible = false
	_lines.clear()
