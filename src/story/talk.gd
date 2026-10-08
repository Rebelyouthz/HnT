class_name Talk
extends CanvasLayer

## Dialogue. Father and Son lines pop as comic bubbles over whoever is
## speaking (SpeechBubble, in the world). If the speaker is not on screen
## (solo run, or off-camera) the bubble docks in the corner with their
## portrait, like a radio line. Narration ("who": "") is a caption box.
## JUMP: finish the line, then next. Lines also move on by themselves after
## a reading pause, so a fight never waits on a conversation. PAUSE skips.

signal closed
## Emitted as each line appears (index into the played lines, the row), so a
## film can stage action on cue.
signal line(index: int, row: Dictionary)

var _lines: Array = []
var _i := 0
var _open := false
var _ui: Control
var _cap: PanelContainer
var _cap_who: Label
var _cap_body: Label
var _dock: PanelContainer
var _dock_pic: TextureRect
var _dock_who: Label
var _dock_body: Label
var _bubble: SpeechBubble
var _wait := 0.0
var _typing := false
var _chars := 0.0
var _type_label: Label


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = PixelStage.attach_canvas(self)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_caption()
	_build_dock()


func _build_caption() -> void:
	_cap = PanelContainer.new()
	var st := UiKit.frame(Palette.EDGE, 0.25)
	st.bg_color = Color(0.02, 0.025, 0.04, 0.9)
	_cap.add_theme_stylebox_override("panel", st)
	_cap.position = Vector2(200, 588)
	_cap.size = Vector2(880, 96)
	_cap.visible = false
	_ui.add_child(_cap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_cap.add_child(col)
	_cap_who = Label.new()
	UiKit.apply_label(_cap_who, 13, Palette.EDGE)
	col.add_child(_cap_who)
	_cap_body = Label.new()
	_cap_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cap_body.custom_minimum_size = Vector2(850, 0)
	_cap_body.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_cap_body, 20, Palette.TEXT)
	col.add_child(_cap_body)


func _build_dock() -> void:
	_dock = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.98, 0.97, 0.93)
	st.border_color = Color(0.05, 0.05, 0.08)
	st.set_border_width_all(3)
	st.set_corner_radius_all(16)
	st.content_margin_left = 10
	st.content_margin_right = 16
	st.content_margin_top = 8
	st.content_margin_bottom = 10
	st.shadow_color = Color(0, 0, 0, 0.4)
	st.shadow_size = 6
	_dock.add_theme_stylebox_override("panel", st)
	_dock.visible = false
	_ui.add_child(_dock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_dock.add_child(row)
	_dock_pic = UiKit.portrait(null, Vector2(72, 72))
	row.add_child(_dock_pic)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	_dock_who = Label.new()
	_dock_who.add_theme_font_override("font", UiKit.title_font())
	_dock_who.add_theme_font_size_override("font_size", 15)
	col.add_child(_dock_who)
	_dock_body = Label.new()
	_dock_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock_body.custom_minimum_size = Vector2(380, 0)
	_dock_body.add_theme_font_size_override("font_size", 17)
	_dock_body.add_theme_color_override("font_color", Color(0.06, 0.06, 0.09))
	col.add_child(_dock_body)


func play(lines: Array, force := false) -> void:
	lines = _present(lines)
	if lines.is_empty():
		return
	if _open and not force:
		return
	_clear_line()
	_lines = lines.duplicate()
	_i = 0
	_open = true
	_paint()


## Solo nights: the hero who stayed home does not chime in from nowhere.
func _present(lines: Array) -> Array:
	if not is_inside_tree():
		return lines
	var have := {}
	for n in get_tree().get_nodes_in_group("players"):
		have[str(n.get("role"))] = true
	if have.is_empty():
		return lines
	var out: Array = []
	for l in lines:
		var who := str((l as Dictionary).get("who", "")) if l is Dictionary else ""
		if (who == "son" or who == "father") and not have.has(who):
			continue
		out.append(l)
	return out


func busy() -> bool:
	return _open


static func accent(who: String) -> Color:
	match who:
		"father":
			return Palette.BRICK
		"son":
			return Palette.LEMON
		"benny":
			return Color(0.95, 0.55, 0.22)
		"rico":
			return Color(0.45, 0.78, 0.42)
		"collector":
			return Color(0.75, 0.2, 0.25)
	return Palette.EDGE


## The actor saying the line, if it is in the level and on screen.
func _speaker(who: String) -> Node2D:
	if who == "":
		return null
	for n in get_tree().get_nodes_in_group("talkers"):
		if n is Node2D and str(n.get_meta("who", "")) == who:
			return n as Node2D
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D and str(n.get("role")) == who and (n as Node2D).is_visible_in_tree():
			if n.has_meta("film"):
				return n as Node2D
			var cam := get_viewport().get_camera_2d()
			if cam == null:
				return n as Node2D
			var half := get_viewport().get_visible_rect().size * 0.5 / cam.zoom
			var d := (n as Node2D).global_position - cam.get_screen_center_position()
			if absf(d.x) < half.x - 20.0 and absf(d.y) < half.y + 40.0:
				return n as Node2D
	return null


func _paint() -> void:
	_clear_line()
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
	var text := str(d.get("text", ""))
	line.emit(_i, d)
	var actor := _speaker(who)
	if actor != null:
		_bubble = SpeechBubble.make(_ui, actor, StoryBook.who_name(who), text, accent(who))
		_wait = _bubble.reading_time()
	elif who == "father" or who == "son" or StoryBook.all().get("crew", {}).has(who):
		_show_dock(who, text)
	else:
		_show_caption(text)


func _show_dock(who: String, text: String) -> void:
	_dock_pic.texture = SpriteBook.bust(who) if SpriteBook.has_who(who) else CrewNPC.bust(who)
	_dock_who.text = StoryBook.who_name(who).to_upper()
	_dock_who.add_theme_color_override("font_color", accent(who).darkened(0.35))
	_dock_body.text = text
	_dock.size = Vector2.ZERO
	_dock.visible = true
	# Father docks left, Son right, so a back-and-forth reads like a call.
	var sz := _dock.get_combined_minimum_size()
	_dock.position = Vector2(40, 560 - sz.y) if who == "father" else Vector2(1240 - sz.x, 560 - sz.y)
	_start_typing(_dock_body)
	UiKit.pop_in(_dock)
	_wait = 1.4 + float(text.length()) * 0.045


func _show_caption(text: String) -> void:
	_cap_who.text = "THE STREET"
	_cap_body.text = text
	_cap.visible = true
	_start_typing(_cap_body)
	_cap.modulate.a = 0.0
	var tw := _cap.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_cap, "modulate:a", 1.0, 0.15)
	_wait = 1.6 + float(text.length()) * 0.045


func _start_typing(lab: Label) -> void:
	_type_label = lab
	_chars = 0.0
	_typing = true
	lab.visible_characters = 0


func _typed() -> bool:
	if _bubble != null and is_instance_valid(_bubble):
		return _bubble.is_typed()
	return not _typing


func _finish_typing() -> void:
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.finish_typing()
	if _type_label != null:
		_type_label.visible_characters = -1
	_typing = false


func _process(delta: float) -> void:
	if not _open:
		return
	if _typing and _type_label != null:
		_chars += delta * SpeechBubble.CPS
		var n := int(_chars)
		_type_label.visible_characters = n
		if n >= _type_label.text.length():
			_typing = false
			_type_label.visible_characters = -1
	if _typed():
		_wait -= delta
		if _wait <= 0.0:
			_next()


func _next() -> void:
	_i += 1
	_paint()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("p1_jump") or event.is_action_pressed("p2_jump") or event.is_action_pressed("ui_accept"):
		if not _typed():
			_finish_typing()
		else:
			_next()
		get_viewport().set_input_as_handled()


func _clear_line() -> void:
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.pop_out()
	_bubble = null
	_typing = false
	_type_label = null
	if _cap:
		_cap.visible = false
	if _dock:
		_dock.visible = false


func _close() -> void:
	_clear_line()
	_open = false
	_lines.clear()
	closed.emit()
