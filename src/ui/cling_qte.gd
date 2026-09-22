class_name ClingQte
extends CanvasLayer

## Tomb Raider 2013 circle: ring shrinks onto the button. Red until the cling window, then green.

signal resolved(ok: bool)

var window := 0.2
var prompt := "CLING"
var fail_shout := "FELL"
var _t := 0.0
var _life := 1.15
var _done := false
var _ring: Control
var _hint: Label


func _ready() -> void:
	add_to_group("cling")
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.22)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_ring = Control.new()
	_ring.set_anchors_preset(Control.PRESET_CENTER)
	_ring.offset_left = -90
	_ring.offset_top = -90
	_ring.offset_right = 90
	_ring.offset_bottom = 90
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring)
	_ring.draw.connect(_draw_ring)
	_hint = Label.new()
	_hint.position = Vector2(440, 430)
	_hint.size = Vector2(400, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_hint, 18, Palette.LEMON)
	_hint.text = "%s  ·  LIGHT / JUMP" % prompt
	add_child(_hint)
	Juice.play("res://assets/audio/cling.wav")


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_ring.queue_redraw()
	var u := clampf(_t / _life, 0.0, 1.0)
	var in_win := _in_window(u)
	_hint.add_theme_color_override("font_color", Palette.READY if in_win else Palette.BADGE)
	if _pressed():
		_finish(in_win)
		return
	if u >= 1.0:
		_finish(false)


func _in_window(u: float) -> bool:
	var center := 0.62
	var half := window / _life
	return absf(u - center) <= half


func _pressed() -> bool:
	return Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p1_jump") \
		or Input.is_action_just_pressed("p2_light") or Input.is_action_just_pressed("p2_jump")


func _draw_ring() -> void:
	var u := clampf(_t / _life, 0.0, 1.0)
	var r := lerpf(84.0, 16.0, u)
	var in_win := _in_window(u)
	var col := Palette.READY if in_win else Palette.BADGE
	_ring.draw_arc(Vector2(90, 90), r, 0.0, TAU, 48, col, 6.0, true)
	_ring.draw_arc(Vector2(90, 90), 22.0, 0.0, TAU, 32, Palette.EDGE, 3.0, true)
	_ring.draw_arc(Vector2(90, 90), 28.0, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.35), 2.0, true)
	_ring.draw_circle(Vector2(90, 90), 10.0, Palette.LEMON if in_win else Palette.MUTED)


func _finish(ok: bool) -> void:
	if _done:
		return
	_done = true
	if ok:
		Juice.shout("CLING")
		Juice.pulse_shake(3.0)
		Juice.play("res://assets/audio/cling_ok.wav")
	else:
		Juice.shout(fail_shout)
		Juice.pulse_shake(7.0)
		Juice.play("res://assets/audio/cling_fail.wav")
	resolved.emit(ok)
	queue_free()
