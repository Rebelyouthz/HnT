class_name SpeechBubble
extends Node2D

## Comic speech bubble over a speaker's head. It lives in the dialogue UI
## layer (design space 1280x720, so the night CanvasModulate never tints it
## and text stays a fixed readable size) and tracks the actor's head through
## the camera every frame. White balloon, ink outline, a tail pointing at the
## mouth, the speaker's name on a coloured tab, text typed out.

signal typed

const HEAD := 44.0
const MAX_W := 340.0
const CPS := 52.0

var target: Node2D
var _panel: PanelContainer
var _body: Label
var _tag: Label
var _tail: Polygon2D
var _tail_ink: Polygon2D
var _box: Control
var _chars := 0.0
var _total := 0
var _done := false


static func make(host: Control, speaker: Node2D, name_text: String, text: String, accent: Color) -> SpeechBubble:
	var b := SpeechBubble.new()
	b.target = speaker
	host.add_child(b)
	b._build(name_text, text, accent)
	return b


func _build(name_text: String, text: String, accent: Color) -> void:
	z_index = 60
	_box = Control.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_panel = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.98, 0.97, 0.93)
	st.border_color = Color(0.05, 0.05, 0.08)
	st.set_border_width_all(3)
	st.set_corner_radius_all(14)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 9
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 4
	st.shadow_offset = Vector2(3, 4)
	st.anti_aliasing = true
	_panel.add_theme_stylebox_override("panel", st)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_panel)
	_body = Label.new()
	_body.text = text
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Short lines get a snug balloon, long ones wrap at MAX_W.
	var w := clampf(float(text.length()) * 9.0, 110.0, MAX_W)
	_body.custom_minimum_size = Vector2(w, 0)
	_body.add_theme_font_size_override("font_size", 17)
	_body.add_theme_color_override("font_color", Color(0.06, 0.06, 0.09))
	_body.visible_characters = 0
	_panel.add_child(_body)
	_total = text.length()
	_tag = Label.new()
	_tag.text = " %s " % name_text.to_upper()
	_tag.add_theme_font_override("font", UiKit.title_font())
	_tag.add_theme_font_size_override("font_size", 12)
	_tag.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
	var tag_bg := StyleBoxFlat.new()
	tag_bg.bg_color = accent
	tag_bg.border_color = Color(0.05, 0.05, 0.08)
	tag_bg.set_border_width_all(2)
	tag_bg.set_corner_radius_all(4)
	tag_bg.content_margin_left = 4
	tag_bg.content_margin_right = 4
	_tag.add_theme_stylebox_override("normal", tag_bg)
	_box.add_child(_tag)
	_tail_ink = Polygon2D.new()
	_tail_ink.color = Color(0.05, 0.05, 0.08)
	add_child(_tail_ink)
	_tail = Polygon2D.new()
	_tail.color = Color(0.98, 0.97, 0.93)
	add_child(_tail)
	_layout.call_deferred()
	_follow()
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.16)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.1)


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var sz := _panel.get_combined_minimum_size()
	# Balloon sits above the anchor, centred, with room for the tail.
	_panel.size = sz
	_panel.position = Vector2(-sz.x * 0.5, -sz.y - 16.0)
	_tag.position = Vector2(_panel.position.x + 12.0, _panel.position.y - 14.0)
	var base_y := _panel.position.y + sz.y
	_tail.polygon = PackedVector2Array([Vector2(-9, base_y - 3), Vector2(7, base_y - 3), Vector2(-4, base_y + 13)])
	_tail_ink.polygon = PackedVector2Array([Vector2(-12, base_y - 1), Vector2(10, base_y - 1), Vector2(-5, base_y + 17)])


## World head point -> viewport (640x360 logical) -> design space (x2),
## clamped so a balloon never leaves the screen.
func _follow() -> void:
	if target == null or not is_instance_valid(target):
		return
	var hop := 0.0
	var v: Variant = target.get("hop")
	if v is float:
		hop = minf(0.0, float(v))
	var head := target.global_position + Vector2(0, -HEAD + hop)
	var p := target.get_viewport().get_canvas_transform() * head
	var k := float(PixelStage.DESIGN.x) / float(PixelStage.LOGICAL.x)
	var d := p * k
	var half := 0.0
	if is_instance_valid(_panel):
		half = _panel.size.x * 0.5
	d.x = clampf(d.x, half + 12.0, float(PixelStage.DESIGN.x) - half - 12.0)
	d.y = clampf(d.y, 150.0, float(PixelStage.DESIGN.y) - 20.0)
	position = d.round()


func _process(delta: float) -> void:
	_follow()
	if _done:
		return
	_chars += delta * CPS
	var n := mini(_total, int(_chars))
	if n != _body.visible_characters:
		_body.visible_characters = n
		if n % 3 == 0:
			Mixer.play_sfx("res://assets/audio/ui_click.wav", randf_range(1.5, 1.8), -18.0)
	if n >= _total:
		_done = true
		typed.emit()


func is_typed() -> bool:
	return _done


func finish_typing() -> void:
	_chars = float(_total)
	_body.visible_characters = -1
	if not _done:
		_done = true
		typed.emit()


func reading_time() -> float:
	return 1.4 + float(_total) * 0.045


func pop_out() -> void:
	set_process(false)
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.parallel().tween_property(self, "scale", Vector2(0.85, 0.85), 0.1)
	tw.tween_callback(queue_free)
