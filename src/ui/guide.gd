class_name Guide
extends CanvasLayer

## First-use guides. The first time a menu or feature opens, Dad (or the
## Kid) walks you through it: the screen dims except a lit window round the
## thing being explained, an arrow bobs at it, and a speech bubble with the
## speaker's face says in plain words what it is and how to use it. A / click
## goes on, B skips the rest. Each guide plays once (FamilyProfile
## "guides_done"); Options can reset them.
##
##   Guide.play(self, "gunsmith", [
##       {"key": "part_suppressor", "who": "father", "text": "Pick a part..."},
##       {"text": "No key: the bubble sits in the middle."},
##   ])
##
## A step's target is the Control whose meta "key" matches, else a Button
## whose text starts with "button", else none.

var steps: Array = []
var id := ""
var host: Node
var _i := 0
var _rect := Rect2()
var _t := 0.0
var _shade: Control
var _bubble: PanelContainer
var _face: TextureRect
var _text: RichTextLabel
var _hint: Label
var _arrow: Control


static func done(gid: String) -> bool:
	return (FamilyProfile.data.get("guides_done", []) as Array).has(gid)


static func play(from: Node, gid: String, gsteps: Array, delay := 0.35) -> void:
	if done(gid) or from == null or not from.is_inside_tree():
		return
	if from.get_tree().get_first_node_in_group("guide") != null:
		return
	var g := Guide.new()
	g.id = gid
	g.steps = gsteps
	g.host = from
	var tree := from.get_tree()
	tree.create_timer(delay, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(from) and from.is_inside_tree() and tree.get_first_node_in_group("guide") == null:
			tree.root.add_child(g)
		else:
			g.free()
	)


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("guide")
	_shade = Shade.new()
	_shade.guide = self
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_next())
	add_child(_shade)
	_arrow = Arrow.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow)
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.95, 0.88)
	sb.border_color = UiKit.INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_offset = Vector2(2, 3)
	sb.shadow_size = 1
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_bubble.add_child(row)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(34, 34)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.texture_filter = SpriteBook.UI_FILTER
	_face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_face)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(220, 0)
	_text.add_theme_font_override("normal_font", UiKit.pixel_font())
	_text.add_theme_font_size_override("normal_font_size", 8)
	_text.add_theme_color_override("default_color", Color(0.12, 0.1, 0.14))
	col.add_child(_text)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_override("font", UiKit.pixel_font())
	_hint.add_theme_font_size_override("font_size", 7)
	_hint.add_theme_color_override("font_color", Color(0.5, 0.3, 0.1))
	col.add_child(_hint)
	_show(0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_jump") or event.is_action_pressed("p1_light"):
		_next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_heavy"):
		_finish()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Nothing else gets through while Dad is talking.
		get_viewport().set_input_as_handled()


func _next() -> void:
	RewardFly.snd("coin_tick", 1.4, -8.0)
	if _i + 1 >= steps.size():
		_finish()
	else:
		_show(_i + 1)


func _finish() -> void:
	var d: Array = FamilyProfile.data.get("guides_done", [])
	if not d.has(id):
		d.append(id)
	FamilyProfile.data["guides_done"] = d
	FamilyProfile.save()
	queue_free()


func _target(key: String) -> Control:
	if key == "" or host == null or not is_instance_valid(host):
		return null
	var root: Node = host.get_tree().root
	for c in root.find_children("*", "Control", true, false):
		if str(c.get_meta("key", "")) == key and (c as Control).is_visible_in_tree():
			return c
	if key.begins_with("button:"):
		var want := key.substr(7).to_upper()
		for c in root.find_children("*", "Button", true, false):
			if (c as Button).text.to_upper().begins_with(want) and (c as Button).is_visible_in_tree():
				return c
	return null


func _show(i: int) -> void:
	_i = i
	var s: Dictionary = steps[i]
	var t := _target(str(s.get("key", "")))
	var vp := get_viewport().get_visible_rect().size
	if t:
		var tf := t.get_global_transform_with_canvas()
		_rect = Rect2(tf.origin, t.size * tf.get_scale()).grow(3)
	else:
		_rect = Rect2(vp * 0.5, Vector2.ZERO)
	var who := str(s.get("who", "father"))
	_face.texture = SpriteBook.bust(who, 0.42)
	var name_col := "#a0522d" if who == "father" else "#2a6fbf"
	var nm := FamilyProfile.father_name() if who == "father" else FamilyProfile.son_name()
	_text.text = "[color=%s]%s[/color]  %s" % [name_col, nm.to_upper(), str(s.get("text", ""))]
	_hint.text = ("A  NEXT   ·   B  SKIP   %d/%d" % [i + 1, steps.size()]) if i + 1 < steps.size() else "A  GOT IT"
	_bubble.reset_size()
	await get_tree().process_frame
	if not is_instance_valid(_bubble):
		return
	var bs := _bubble.size
	var at := Vector2.ZERO
	if _rect.size == Vector2.ZERO:
		at = (vp - bs) * 0.5
	elif _rect.end.y + bs.y + 16.0 < vp.y:
		at = Vector2(_rect.get_center().x - bs.x * 0.5, _rect.end.y + 12.0)
	else:
		at = Vector2(_rect.get_center().x - bs.x * 0.5, _rect.position.y - bs.y - 12.0)
	at.x = clampf(at.x, 6.0, vp.x - bs.x - 6.0)
	at.y = clampf(at.y, 6.0, vp.y - bs.y - 6.0)
	_bubble.position = at.round()
	_arrow.visible = _rect.size != Vector2.ZERO
	_arrow.set("below", at.y > _rect.position.y)
	_arrow.position = Vector2(_rect.get_center().x, _rect.end.y + 2.0 if at.y > _rect.position.y else _rect.position.y - 2.0).round()
	_bubble.scale = Vector2(0.85, 0.85)
	_bubble.pivot_offset = bs * 0.5
	var tw := _bubble.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bubble, "scale", Vector2.ONE, 0.14)
	_shade.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_shade.queue_redraw()
	if _arrow:
		_arrow.queue_redraw()


## The dim with a lit window round the target.
class Shade extends Control:
	var guide: Guide

	func _draw() -> void:
		var r := guide._rect
		var full := get_viewport_rect().size
		var c := Color(0, 0, 0.03, 0.62)
		if r.size == Vector2.ZERO:
			draw_rect(Rect2(Vector2.ZERO, full), c)
			return
		draw_rect(Rect2(0, 0, full.x, r.position.y), c)
		draw_rect(Rect2(0, r.end.y, full.x, full.y - r.end.y), c)
		draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), c)
		draw_rect(Rect2(r.end.x, r.position.y, full.x - r.end.x, r.size.y), c)
		var a := 0.6 + 0.4 * sin(guide._t * 5.0)
		draw_rect(r, Color(1.0, 0.85, 0.3, a), false, 1.0)
		draw_rect(r.grow(2), Color(1.0, 0.85, 0.3, a * 0.4), false, 1.0)


## A bobbing pixel arrow pointing at the target.
class Arrow extends Control:
	var below := true

	func _draw() -> void:
		var g := get_parent() as Guide
		var bob := roundf(sin(g._t * 6.0) * 2.0)
		var d := 1.0 if below else -1.0
		var tip := Vector2(0, (4.0 + bob) * d)
		var pts := PackedVector2Array([tip, tip + Vector2(-5, 6 * d), tip + Vector2(-2, 6 * d), tip + Vector2(-2, 11 * d), tip + Vector2(2, 11 * d), tip + Vector2(2, 6 * d), tip + Vector2(5, 6 * d)])
		draw_colored_polygon(pts, Color(1.0, 0.85, 0.3))
		draw_polyline(pts + PackedVector2Array([tip]), UiKit.INK, 1.0)
