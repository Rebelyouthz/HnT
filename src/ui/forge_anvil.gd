class_name ForgeAnvil
extends Control

## The anvil: three hammer strikes. A glowing marker swings across the hot
## bar, faster each strike; press (LIGHT, A, SPACE, ENTER or click) while it
## is inside the white-hot zone. Every strike clangs and throws sparks;
## each one in the zone adds a quality point (0..3).

signal done(quality: int)

var title := ""
var _t := 0.0
var _speed := 1.4
var _pos := 0.0
var _dir := 1.0
var _strikes := 0
var _good := 0
var _zone_c := 0.5
var _zone_w := 0.16
var _flash := 0.0
var _last := ""
var _wait := 0.0
var _results: Array[bool] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Take focus off the FORGE button so ENTER strikes instead of re-pressing it.
	focus_mode = Control.FOCUS_ALL
	grab_focus.call_deferred()
	_new_zone()


func _new_zone() -> void:
	_zone_c = randf_range(0.25, 0.75)
	_zone_w = 0.18 - 0.03 * float(_strikes)


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 3.0)
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0 and _strikes >= 3:
			done.emit(_good)
			queue_free()
		queue_redraw()
		return
	_pos += _dir * _speed * delta
	if _pos > 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos < 0.0:
		_pos = 0.0
		_dir = 1.0
	queue_redraw()


func _strike() -> void:
	if _wait > 0.0 or _strikes >= 3:
		return
	var hit := absf(_pos - _zone_c) <= _zone_w * 0.5
	_strikes += 1
	if hit:
		_good += 1
	_results.append(hit)
	_last = "GLOWING!" if hit else "COLD..."
	_flash = 1.0
	Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", 1.2 if hit else 0.8, -2.0 if hit else -6.0)
	Juice.pulse_shake(4.0 if hit else 1.5)
	_speed += 0.55
	_new_zone()
	_wait = 0.9 if _strikes >= 3 else 0.25


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_strike()
		accept_event()


func _input(event: InputEvent) -> void:
	for a in ["ui_accept", "p1_light", "p2_light", "p1_jump"]:
		if InputMap.has_action(a) and event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			_strike()
			return


func _draw() -> void:
	var vp := Vector2(1280, 720)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.01, 0.0, 0.78))
	var f := UiKit.title_font()
	var mid := Vector2(640, 300)
	draw_string(f, mid + Vector2(-300, -120), "ON THE ANVIL  ·  %s" % title, HORIZONTAL_ALIGNMENT_CENTER, 600, 26, Color(1.0, 0.7, 0.3))
	draw_string(f, mid + Vector2(-300, -84), "STRIKE WHEN IT GLOWS  ·  %d / 3" % mini(_strikes + 1, 3), HORIZONTAL_ALIGNMENT_CENTER, 600, 18, Palette.TEXT)
	# The bar: dark iron, an orange heat wash, the white-hot zone.
	var bar := Rect2(mid + Vector2(-260, -18), Vector2(520, 36))
	draw_rect(bar.grow(4), Color(0.05, 0.03, 0.02))
	for i in 26:
		var k := float(i) / 25.0
		var heat := 1.0 - absf(k - _zone_c) * 2.2
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * float(i) / 26.0, 0), Vector2(bar.size.x / 26.0 + 1.0, bar.size.y)), Color(0.35 + 0.6 * maxf(0.0, heat), 0.12 + 0.35 * maxf(0.0, heat), 0.04))
	var zx := bar.position.x + bar.size.x * (_zone_c - _zone_w * 0.5)
	var pulse := 0.75 + 0.25 * sin(_t * 12.0)
	draw_rect(Rect2(Vector2(zx, bar.position.y - 4), Vector2(bar.size.x * _zone_w, bar.size.y + 8)), Color(1.0, 0.95, 0.7, 0.85 * pulse))
	# The hammer marker.
	var mx := bar.position.x + bar.size.x * _pos
	draw_rect(Rect2(Vector2(mx - 4, bar.position.y - 16), Vector2(8, bar.size.y + 32)), Color(0.85, 0.88, 0.95))
	draw_rect(Rect2(Vector2(mx - 12, bar.position.y - 26), Vector2(24, 12)), Color(0.55, 0.58, 0.66))
	# Strike pips and the last call.
	for i in 3:
		var c := Color(0.25, 0.2, 0.18)
		if i < _results.size():
			c = Color(1.0, 0.75, 0.25) if _results[i] else Color(0.4, 0.4, 0.45)
		draw_circle(mid + Vector2(-40 + 40 * i, 60), 10, c)
	if _last != "" and _flash > 0.0:
		var col := Color(1.0, 0.9, 0.4, _flash) if _last == "GLOWING!" else Color(0.6, 0.7, 0.9, _flash)
		draw_string(f, mid + Vector2(-300, 110), _last, HORIZONTAL_ALIGNMENT_CENTER, 600, 34, col)
		# Sparks fly off the strike.
		for s in 14:
			var a := TAU * float(s) / 14.0 + _t
			var r := 30.0 + 90.0 * (1.0 - _flash)
			draw_circle(Vector2(mx, bar.position.y) + Vector2(cos(a), sin(a) * 0.6) * r, 2.0, Color(1.0, 0.7, 0.2, _flash))
	draw_string(UiKit.pixel_font(), mid + Vector2(-300, 170), "PRESS A", HORIZONTAL_ALIGNMENT_CENTER, 600, 12, Palette.MUTED)
