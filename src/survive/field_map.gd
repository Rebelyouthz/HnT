class_name FieldMap
extends CanvasLayer

## The survivor field's radar: a small map of the arena (top right) with the
## heroes, chests and wells (gold / purple), elites (red) and the boss (big
## red pulse), plus arrows on the screen edge pointing at anything worth
## walking to that is off screen right now.

const SIZE := Vector2(170, 112)
const AT := Vector2(1096, 156)

var _c: Control
var _t := 0.0


static func place(host: Node) -> FieldMap:
	var m := FieldMap.new()
	host.add_child(m)
	return m


func _ready() -> void:
	layer = 19
	var root := PixelStage.attach_canvas(self)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_c = Control.new()
	_c.size = Vector2(PixelStage.DESIGN)
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_c)
	_c.draw.connect(_paint)


func _process(delta: float) -> void:
	_t += delta
	_c.queue_redraw()


func _pins() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("map_pins"):
		if n is Node2D and is_instance_valid(n):
			var k := str(n.get_meta("pin", "chest"))
			out.append([(n as Node2D).global_position, k])
	for n in get_tree().get_nodes_in_group("act_boss"):
		if n is Node2D and int(n.get("hp")) > 0:
			out.append([(n as Node2D).global_position, "boss"])
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and (n as Punk).elite_mod != "" and (n as Punk).hp > 0:
			out.append([(n as Node2D).global_position, "elite"])
	return out


func _col(kind: String) -> Color:
	match kind:
		"shrine":
			return Color(0.75, 0.5, 1.0)
		"cursed":
			return Color(0.9, 0.3, 1.0)
		"boss":
			return Color(1.0, 0.25, 0.2)
		"elite":
			return Color(1.0, 0.45, 0.35)
	return UiKit.GOLD


func _paint() -> void:
	if get_tree().paused:
		return
	var r := Rect2(AT, SIZE)
	_c.draw_rect(r.grow(3), Color(0, 0, 0, 0.55))
	_c.draw_rect(r, Color(0.04, 0.05, 0.08, 0.72))
	_c.draw_rect(r, Color(0.45, 1.0, 0.6, 0.7), false, 2.0)
	var k := SIZE / Vector2(SurviveField.W, SurviveField.H)
	var cam := get_viewport().get_camera_2d()
	# What the camera sees, as a faint box.
	if cam:
		var half := Vector2(640, 360) * 0.5 / cam.zoom.x
		var cc := cam.get_screen_center_position()
		_c.draw_rect(Rect2(AT + (cc - half) * k, half * 2.0 * k), Color(1, 1, 1, 0.16), false, 1.0)
	# Cars and the crowd: grey blocks and a faint red haze of dots.
	for n in get_tree().get_nodes_in_group("parked_cars"):
		if n is Node2D:
			_c.draw_rect(Rect2(AT + (n as Node2D).global_position * k - Vector2(4, 1.5), Vector2(8, 3)), Color(0.55, 0.58, 0.66, 0.6))
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D:
			_c.draw_rect(Rect2(AT + (n as Node2D).global_position * k, Vector2(1.5, 1.5)), Color(1.0, 0.3, 0.25, 0.55))
	var pins := _pins()
	for p in pins:
		var at: Vector2 = AT + (p[0] as Vector2) * k
		var kind := str(p[1])
		var rad := 4.0 if kind == "boss" else (2.0 if kind == "elite" else 3.0)
		if kind == "boss":
			_c.draw_arc(at, rad + 3.0 + 2.0 * sin(_t * 6.0), 0.0, TAU, 16, _col(kind), 1.5)
		_c.draw_circle(at, rad, _col(kind))
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			var at2: Vector2 = AT + (n as Fighter).global_position * k
			_c.draw_circle(at2, 3.5, Color.WHITE)
			_c.draw_circle(at2, 2.2, Palette.LEMON if (n as Fighter).role == "son" else Palette.BRICK)
	# Edge arrows for things off screen (not elites: too many).
	if cam == null:
		return
	var vp := cam.get_viewport_rect().size
	var half2 := vp * 0.5 / cam.zoom
	var cc2 := cam.get_screen_center_position()
	var design := Vector2(PixelStage.DESIGN)
	for p in pins:
		var kind := str(p[1])
		if kind == "elite":
			continue
		var d: Vector2 = (p[0] as Vector2) - cc2
		if absf(d.x) < half2.x * 0.95 and absf(d.y) < half2.y * 0.95:
			continue
		# Screen-space direction, clamped to an inset frame.
		var s := d / half2
		var m := maxf(absf(s.x), absf(s.y))
		var e := s / m
		var pos := design * 0.5 + e * (design * 0.5 - Vector2(40, 46))
		var ang := d.angle()
		var col := _col(kind)
		var pulse := 1.0 + 0.15 * sin(_t * 5.0)
		var tip := pos + Vector2.from_angle(ang) * 14.0 * pulse
		var l := pos + Vector2.from_angle(ang + 2.5) * 10.0 * pulse
		var rr := pos + Vector2.from_angle(ang - 2.5) * 10.0 * pulse
		_c.draw_colored_polygon(PackedVector2Array([tip, l, rr]), Color(0, 0, 0, 0.6))
		_c.draw_colored_polygon(PackedVector2Array([tip.lerp(pos, 0.18), l.lerp(pos, 0.18), rr.lerp(pos, 0.18)]), col)
		var dist := int(d.length() / 10.0)
		var lab := "%dm" % dist
		_c.draw_string_outline(UiKit.title_font(), pos - Vector2.from_angle(ang) * 22.0 - Vector2(12, -4), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color.BLACK)
		_c.draw_string(UiKit.title_font(), pos - Vector2.from_angle(ang) * 22.0 - Vector2(12, -4), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
