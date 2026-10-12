class_name FocusGlide
extends CanvasLayer

## The "you are here" frame for every menu: a gold frame with corner
## brackets that glides from the button you were on to the one you move to
## (stick, d-pad, keys) and settles with a small overshoot, breathing while
## it rests. Pointing at a button with the mouse or the pad pointer (right
## stick) gives it focus too, so the frame and the pointer never disagree.

const GLIDE := 16.0      # how fast the frame chases its target (1/s)
const PAD := 0.0         # frame sits on the button edge: never over a neighbour

static var _me: FocusGlide
var _draw: Control
var _rect := Rect2()
var _vel := Vector4.ZERO
var _target: Control
var _alpha := 0.0
var _t := 0.0
var _pop := 0.0


static func install(tree: SceneTree) -> void:
	if _me != null and is_instance_valid(_me):
		return
	_me = FocusGlide.new()
	_me.name = "FocusGlide"
	tree.root.call_deferred("add_child", _me)


func _ready() -> void:
	layer = 127
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw = Control.new()
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.draw.connect(_paint)
	add_child(_draw)


func _input(event: InputEvent) -> void:
	# The first stick / d-pad / arrow press on a menu with nothing focused
	# lands on its first button instead of doing nothing.
	if not (event is InputEventMouse) and event.is_pressed() and not event.is_echo():
		for a in ["ui_up", "ui_down", "ui_left", "ui_right"]:
			if event.is_action(a) and get_viewport().gui_get_focus_owner() == null and _menu_up():
				var first := _first_button()
				if first != null:
					first.grab_focus()
					get_viewport().set_input_as_handled()
				return
	# Pointing at a button focuses it (mouse, or the pad pointer warping it),
	# on menus only: in play the hideout's floor stations are buttons too.
	if event is InputEventMouseMotion and _menu_up():
		var h := get_viewport().gui_get_hovered_control()
		var b := h as BaseButton
		while h != null and b == null and h.mouse_filter == Control.MOUSE_FILTER_PASS:
			h = h.get_parent() as Control
			b = h as BaseButton
		if b != null and not b.disabled and b.focus_mode != Control.FOCUS_NONE and b.is_visible_in_tree() and not b.has_focus():
			b.grab_focus()


func _process(delta: float) -> void:
	_t += delta
	var f := get_viewport().gui_get_focus_owner()
	var ok := f != null and f.is_visible_in_tree() and f.size.x > 2.0 and f.size.y > 2.0 and not _hidden(f) and _menu_up() \
			and get_tree().get_first_node_in_group("guide") == null
	if ok:
		# Drawn just above the layer the button lives on, so banners, popups
		# and toasts in front of the menu cover the frame too.
		layer = layer_above(f)
		var tf := f.get_global_transform_with_canvas()
		var want := Rect2(tf.origin, f.size * tf.get_scale()).grow(PAD)
		if f != _target:
			# A fresh target: jump there if the frame was not showing.
			if _target == null or not is_instance_valid(_target) or _alpha < 0.05:
				_rect = want
				_vel = Vector4.ZERO
			_target = f
			_pop = 1.0
		# Spring toward the target: quick, with a touch of overshoot.
		var cur := Vector4(_rect.position.x, _rect.position.y, _rect.end.x, _rect.end.y)
		var goal := Vector4(want.position.x, want.position.y, want.end.x, want.end.y)
		var k := GLIDE * GLIDE
		# Small fixed steps so a long frame (a scene loading) cannot blow up.
		var left := minf(delta, 0.1)
		while left > 0.0:
			var dt := minf(left, 1.0 / 120.0)
			_vel += ((goal - cur) * k - _vel * (2.0 * GLIDE * 0.72)) * dt
			cur += _vel * dt
			left -= dt
		if not (is_finite(cur.x) and is_finite(cur.y) and is_finite(cur.z) and is_finite(cur.w)):
			cur = goal
			_vel = Vector4.ZERO
		_rect = Rect2(Vector2(cur.x, cur.y), Vector2(cur.z - cur.x, cur.w - cur.y))
	_alpha = move_toward(_alpha, 1.0 if ok else 0.0, delta * (8.0 if ok else 5.0))
	_pop = move_toward(_pop, 0.0, delta * 4.0)
	if _alpha > 0.0 or ok:
		_draw.queue_redraw()


## One canvas layer above the one this item is drawn on.
static func layer_above(c: CanvasItem) -> int:
	var cl := c.get_canvas_layer_node() if c != null else null
	return (cl.layer if cl != null else 0) + 1


## A menu is in front: the game is paused (pause, card picks, results), the
## scene itself is a menu, or the hideout has a sheet open. Never while
## walking around, where the d-pad moves the hero.
func _menu_up() -> bool:
	var tree := get_tree()
	if tree.paused:
		return true
	var cs := tree.current_scene
	if cs == null:
		return false
	if cs is Control or cs.scene_file_path.contains("/ui/"):
		return true
	return cs.has_method("overlay_open") and bool(cs.call("overlay_open"))


## The top-left focusable button on the top-most layer that has one.
func _first_button() -> Control:
	var best: Control = null
	var best_layer := -9999
	var best_key := INF
	for c in get_tree().root.find_children("*", "BaseButton", true, false):
		var b := c as BaseButton
		if b.disabled or b.focus_mode == Control.FOCUS_NONE or not b.is_visible_in_tree():
			continue
		var cl := b.get_canvas_layer_node()
		var lay := cl.layer if cl != null else 0
		var tf := b.get_global_transform_with_canvas()
		var key := tf.origin.y * 4.0 + tf.origin.x
		if lay > best_layer or (lay == best_layer and key < best_key):
			best = b
			best_layer = lay
			best_key = key
	return best


## Controls that draw their own focus (the skill tree's nodes, sliders in
## the middle of a drag) or ask not to be framed.
func _hidden(c: Control) -> bool:
	if c.has_meta("no_glide"):
		return true
	# Only things you press or slide get the frame: a panel that kept focus
	# (a chart row, a card) must not draw a box across the screen.
	if not (c is BaseButton or c is Range or c is ItemList or c is TabBar or c is Tree):
		return true
	return c is LineEdit or c is TextEdit


func _paint() -> void:
	if _alpha <= 0.0 or _rect.size.x < 2.0:
		return
	# A thin line on the button's own edge (inset half a pixel) so it never
	# spills over the box next door or a text field; only the landing pop
	# reaches a pixel out, for a blink.
	var breathe := 0.5 + 0.5 * sin(_t * 3.0)
	var r := _rect.grow(-0.5 + 1.0 * _pop)
	var gold := Color(1.0, 0.8, 0.3, _alpha)
	_draw.draw_rect(r, Color(gold.r, gold.g, gold.b, _alpha * (0.55 + 0.25 * breathe)), false, 1.0)
	# Small corner brackets on the frame, drawn inward.
	var L := clampf(minf(r.size.x, r.size.y) * 0.16, 3.0, 7.0)
	var ink := Color(0.04, 0.03, 0.06, _alpha * 0.5)
	for c in [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)],
			[Vector2(r.position.x, r.end.y), Vector2(1, -1)], [r.end, Vector2(-1, -1)]]:
		var p: Vector2 = c[0] + (c[1] as Vector2) * 0.75
		var s: Vector2 = c[1]
		for pass_i in 2:
			var col := ink if pass_i == 0 else gold
			var w := 2.5 if pass_i == 0 else 1.5
			_draw.draw_line(p, p + Vector2(s.x * L, 0), col, w)
			_draw.draw_line(p, p + Vector2(0, s.y * L), col, w)
