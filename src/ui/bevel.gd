class_name Bevel
extends Control

## A 3D finish laid over any box, button, card or round skill node: a lit
## top-left rim, a shaded bottom-right rim, a gloss on the upper half, and a
## shine that sweeps across now and then (at once on hover / focus), so
## frames read as raised, cut blocks that are a little alive.

const ENABLED := false

var round := false
var radius := 5.0
var strength := 1.0
var _t := 0.0
var _sweep := -1.0
var _next := 0.0
var _hot := false


static func dress(c: Control, round_node := false, k := 1.0) -> Bevel:
	# Off: the plain frames read better (player feedback). Kept as an
	# opt-in for later; every caller ignores the return value.
	if c == null or not ENABLED:
		return null
	for ch in c.get_children():
		if ch is Bevel:
			return ch
	var b := Bevel.new()
	b.round = round_node
	b.strength = k
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(b)
	if c is BaseButton:
		var bb := c as BaseButton
		bb.mouse_entered.connect(b.shine)
		bb.focus_entered.connect(b.shine)
		bb.mouse_entered.connect(func() -> void: b._hot = true)
		bb.mouse_exited.connect(func() -> void: b._hot = false)
		bb.focus_entered.connect(func() -> void: b._hot = true)
		bb.focus_exited.connect(func() -> void: b._hot = false)
	return b


func _ready() -> void:
	_next = randf_range(1.5, 6.0)


func shine() -> void:
	_sweep = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _sweep >= 0.0:
		_sweep += delta * 1.8
		if _sweep > 1.4:
			_sweep = -1.0
			_next = randf_range(4.0, 9.0)
	else:
		_next -= delta
		if _next <= 0.0:
			shine()
	queue_redraw()


func _draw() -> void:
	var s := size
	if s.x < 4.0 or s.y < 4.0:
		return
	var k := strength * (1.25 if _hot else 1.0)
	if round:
		var c := s * 0.5
		var r := minf(s.x, s.y) * 0.5 - 2.0
		draw_arc(c, r - 1.0, PI * 0.95, PI * 1.75, 24, Color(1, 1, 1, 0.38 * k), 2.5)
		draw_arc(c, r - 1.0, -PI * 0.05, PI * 0.75, 24, Color(0, 0, 0.04, 0.5 * k), 3.0)
		draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.32, Color(1, 1, 1, 0.08 * k))
		if _sweep >= 0.0:
			var a := lerpf(-1.2, 1.2, _sweep)
			draw_arc(c, r * 0.8, PI * 1.1 + a, PI * 1.35 + a, 10, Color(1, 1, 1, 0.3 * k), 3.0)
		return
	var hl := Color(1, 1, 1, 0.3 * k)
	var sd := Color(0, 0, 0.03, 0.55 * k)
	var m := 3.0
	# Lit top and left rims, shaded bottom and right rims (inside the border),
	# and a thin inset line one step in: a cut, raised block.
	draw_rect(Rect2(m, m, s.x - m * 2.0, 3.0), hl)
	draw_rect(Rect2(m, m, 3.0, s.y - m * 2.0), Color(1, 1, 1, 0.16 * k))
	draw_rect(Rect2(m, s.y - m - 4.0, s.x - m * 2.0, 4.0), sd)
	draw_rect(Rect2(s.x - m - 3.0, m, 3.0, s.y - m * 2.0), Color(0, 0, 0.03, 0.38 * k))
	if s.x > 40.0 and s.y > 30.0:
		draw_rect(Rect2(m + 5, m + 5, s.x - m * 2.0 - 10, s.y - m * 2.0 - 10), Color(0, 0, 0, 0.18 * k), false, 1.0)
	# Gloss: a soft light on the upper half, fading down.
	var g := PackedVector2Array([Vector2(m + 2, m + 2), Vector2(s.x - m - 2, m + 2), Vector2(s.x - m - 2, s.y * 0.48), Vector2(m + 2, s.y * 0.48)])
	draw_polygon(g, PackedColorArray([Color(1, 1, 1, 0.09 * k), Color(1, 1, 1, 0.09 * k), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
	# The shine: a slanted band of light crossing the face.
	if _sweep >= 0.0:
		var x := lerpf(-s.y, s.x + s.y, _sweep)
		var w := clampf(s.x * 0.12, 10.0, 40.0)
		var band := PackedVector2Array([Vector2(x, m), Vector2(x + w, m), Vector2(x + w - s.y * 0.6, s.y - m), Vector2(x - s.y * 0.6, s.y - m)])
		for i in band.size():
			band[i].x = clampf(band[i].x, m, s.x - m)
		draw_colored_polygon(band, Color(1, 1, 1, 0.13 * k))
