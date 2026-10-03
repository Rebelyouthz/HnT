class_name PixelCursor
extends CanvasLayer

## The game's own mouse pointer: a chunky gold-rimmed pixel arrow that
## squashes and darkens while the button is held, with a little ring popping
## out on every click. On a pad, the sticks fly the pointer around menus
## (right stick always, left stick when the game is paused or on a menu
## screen); A / Cross clicks where it points, B / Circle goes back.

const SPEED := 900.0
const DEAD := 0.22

static var _me: PixelCursor
var _up: ImageTexture
var _down: ImageTexture
var _ring_t := -1.0
var _ring_at := Vector2.ZERO
var _fx: Control
var _pad_t := 0.0


static func install(tree: SceneTree) -> void:
	if _me != null and is_instance_valid(_me):
		return
	_me = PixelCursor.new()
	_me.name = "PixelCursor"
	tree.root.call_deferred("add_child", _me)


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_up = ImageTexture.create_from_image(_arrow(false))
	_down = ImageTexture.create_from_image(_arrow(true))
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(_up, Input.CURSOR_ARROW, Vector2(2, 2))
		Input.set_custom_mouse_cursor(_up, Input.CURSOR_POINTING_HAND, Vector2(2, 2))
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.draw.connect(_draw_fx)
	add_child(_fx)


## 24x24 arrow, 2x2 texel blocks: dark outline, cream face, gold rim, a
## shadow side for depth. Pressed: shifted down a texel, darker face.
func _arrow(pressed: bool) -> Image:
	var rows := [
		"X...........",
		"XX..........",
		"XGX.........",
		"XWGX........",
		"XWWGX.......",
		"XWWWGX......",
		"XWWWWGX.....",
		"XWWWWWGX....",
		"XWWWWWWGX...",
		"XWWWWSSSSX..",
		"XWWXWSX.....",
		"XWX.XWSX....",
	]
	var img := Image.create(24, 26, false, Image.FORMAT_RGBA8)
	var face := Color(0.98, 0.93, 0.78) if not pressed else Color(0.82, 0.74, 0.55)
	var gold := Color(0.95, 0.72, 0.25)
	var shade := Color(0.55, 0.38, 0.14)
	var ink := Color(0.04, 0.03, 0.06)
	var oy := 2 if pressed else 0
	# Drop shadow first.
	if not pressed:
		for y in rows.size():
			for x in (rows[y] as String).length():
				if (rows[y] as String)[x] != ".":
					_block(img, x * 2 + 2, y * 2 + 2, Color(0, 0, 0.02, 0.45))
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			var c := Color(0, 0, 0, 0)
			match r[x]:
				"X":
					c = ink
				"W":
					c = face
				"G":
					c = gold
				"S":
					c = shade
			if c.a > 0.0:
				_block(img, x * 2, y * 2 + oy, c)
	return img


func _block(img: Image, x: int, y: int, c: Color) -> void:
	for dy in 2:
		for dx in 2:
			if x + dx < img.get_width() and y + dy < img.get_height():
				img.set_pixel(x + dx, y + dy, c)


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(_down if mb.pressed else _up, Input.CURSOR_ARROW, Vector2(2, 2))
		Input.set_custom_mouse_cursor(_down if mb.pressed else _up, Input.CURSOR_POINTING_HAND, Vector2(2, 2))
		if mb.pressed:
			_ring_t = 0.0
			_ring_at = mb.position
	var jb := event as InputEventJoypadButton
	if jb != null and jb.button_index == JOY_BUTTON_A and _pad_t > 0.0 and _menu_time():
		# The pad pointer is live: A clicks where it points.
		_click(jb.pressed)
		get_viewport().set_input_as_handled()


func _menu_time() -> bool:
	var tree := get_tree()
	if tree.paused:
		return true
	var cs := tree.current_scene
	if cs == null:
		return false
	return cs is Control or cs.scene_file_path.contains("/ui/") or cs.scene_file_path.ends_with("camp.tscn")


func _process(delta: float) -> void:
	if _ring_t >= 0.0:
		_ring_t += delta
		if _ring_t > 0.3:
			_ring_t = -1.0
		_fx.queue_redraw()
	_pad_t = maxf(0.0, _pad_t - delta)
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if _menu_time():
		var l := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if l.length() > v.length():
			v = l
	if v.length() < DEAD:
		return
	# Curve: fine control near the centre, fast at the rim.
	var amt := (v.length() - DEAD) / (1.0 - DEAD)
	var step := v.normalized() * amt * amt * SPEED * delta
	var vp := get_viewport()
	var win := DisplayServer.window_get_size()
	var pos := vp.get_mouse_position() * (Vector2(win) / vp.get_visible_rect().size)
	DisplayServer.warp_mouse(Vector2i((pos + step * (float(win.y) / 720.0)).clamp(Vector2.ZERO, Vector2(win) - Vector2.ONE)))
	_pad_t = 3.0


func _click(down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = get_viewport().get_mouse_position()
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func _draw_fx() -> void:
	if _ring_t < 0.0:
		return
	var vp := get_viewport()
	var at := vp.get_mouse_position()
	var r := 4.0 + _ring_t * 40.0
	var a := 1.0 - _ring_t / 0.3
	_fx.draw_arc(at, r, 0.0, TAU, 20, Color(0.95, 0.72, 0.25, a), 2.0)
	_fx.draw_arc(at, r * 0.6, 0.0, TAU, 16, Color(1, 1, 0.9, a * 0.6), 1.0)
