class_name FireEscape
extends Area2D

@export var top_y: float = 248.0
@export var bottom_y: float = 500.0
@export var climb_x: float = 0.0
## How this way up looks and climbs:
##   ladder  the fire-escape ladder (steady, both heroes)
##   pipe    a drainpipe: the son shimmies it fast, dad hauls slower
##   boost   dumpster + crate + awning: a quick vault, two hops and up
@export var style: String = "ladder"


func _ready() -> void:
	add_to_group("ladders")
	add_to_group("metal")
	collision_layer = 16
	collision_mask = 2
	monitorable = true
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(36, absf(bottom_y - top_y) + 40.0)
	cs.shape = r
	cs.position = Vector2(0, (top_y + bottom_y) * 0.5 - global_position.y)
	add_child(cs)
	_paint()


func configure(at_x: float, top: float, bottom: float, how: String = "ladder") -> void:
	style = how
	climb_x = at_x
	top_y = top
	bottom_y = bottom
	global_position = Vector2(at_x, (top + bottom) * 0.5)


func covers(pos: Vector2) -> bool:
	if absf(pos.x - climb_x) > 26.0:
		return false
	return pos.y >= top_y - 18.0 and pos.y <= bottom_y + 24.0


## Climb speed multiplier for this way up and this hero.
func speed_k(role: String) -> float:
	match style:
		"pipe":
			return 1.35 if role == "son" else 0.8
		"boost":
			return 3.4
	return 1.0


## Iron ladder at the same fine detail as the characters and the painted
## street: thin rails with a lit edge and a shadow edge, rungs every 6 u
## with rivets, rust streaks, a railed landing at the roof line and a
## drop-shadow on the wall behind.
func _paint() -> void:
	if style == "pipe":
		_paint_pipe()
		return
	if style == "boost":
		_paint_boost()
		return
	var h := bottom_y - top_y
	var top := -h * 0.5
	var iron := Color(0.09, 0.09, 0.11)
	var mid := Color(0.2, 0.19, 0.21)
	var lit := Color(0.48, 0.45, 0.46)
	var rust := Color(0.42, 0.2, 0.12)
	# Shadow cast on the wall.
	_rect(Rect2(-12, top - 4.0, 28, h + 4.0), Color(0, 0, 0.02, 0.28), 0)
	for x in [-13.0, 10.0]:
		_rect(Rect2(x, top - 6.0, 3, h + 6.0), iron)
		_rect(Rect2(x + 0.5, top - 6.0, 1.0, h + 6.0), mid)
		_rect(Rect2(x, top - 6.0, 0.5, h + 6.0), lit)
	var y := top + 3.0
	var n := 0
	while y < h * 0.5 - 1.0:
		_rect(Rect2(-10, y, 20, 1.5), iron)
		_rect(Rect2(-10, y, 20, 0.5), lit if n % 4 != 2 else rust)
		_rect(Rect2(-12.5, y - 0.25, 1.5, 1.5), mid)
		_rect(Rect2(10.5, y - 0.25, 1.5, 1.5), mid)
		if n % 5 == 3:
			_rect(Rect2(-9.0 + float(n % 7) * 2.0, y + 1.5, 0.8, 3.0), Color(rust.r, rust.g, rust.b, 0.6))
		y += 6.0
		n += 1
	# Landing: grate deck, handrail, posts.
	_rect(Rect2(-24, top - 9.0, 48, 2.5), iron)
	_rect(Rect2(-24, top - 9.0, 48, 0.5), lit)
	var bx := -23.0
	while bx < 24.0:
		_rect(Rect2(bx, top - 6.5, 0.8, 4.0), mid)
		bx += 3.0
	_rect(Rect2(-24, top - 22.0, 48, 1.2), iron)
	_rect(Rect2(-24, top - 22.0, 48, 0.4), lit)
	for px in [-24.0, -8.0, 8.0, 23.0]:
		_rect(Rect2(px, top - 22.0, 1.2, 13.0), iron)


func _rect(r: Rect2, c: Color, z: int = 1) -> void:
	var p := Polygon2D.new()
	p.color = c
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	p.z_index = z
	add_child(p)


## A cast-iron drainpipe: one fat downspout with a lit edge, brackets bolted
## to the wall every 22 u, a gutter lip and elbow at the roof line, a shoe
## splashing onto the street, rust and a damp streak down the wall.
func _paint_pipe() -> void:
	var h := bottom_y - top_y
	var top := -h * 0.5
	var iron := Color(0.12, 0.13, 0.14)
	var mid := Color(0.26, 0.28, 0.27)
	var lit := Color(0.55, 0.57, 0.52)
	var rust := Color(0.45, 0.22, 0.12)
	_rect(Rect2(-2, top, 10, h), Color(0, 0, 0.02, 0.25), 0)
	_rect(Rect2(-8, top - 2.0, 30, h + 2.0), Color(0.05, 0.08, 0.1, 0.18), 0)
	_rect(Rect2(-4, top - 4.0, 7, h + 4.0), iron)
	_rect(Rect2(-3, top - 4.0, 4, h + 4.0), mid)
	_rect(Rect2(-3, top - 4.0, 1, h + 4.0), lit)
	var y := top + 10.0
	var n := 0
	while y < h * 0.5 - 8.0:
		_rect(Rect2(-6, y, 11, 2.5), iron)
		_rect(Rect2(-6, y, 11, 0.6), lit)
		_rect(Rect2(-5.5, y + 0.8, 1.2, 1.2), mid)
		_rect(Rect2(3.5, y + 0.8, 1.2, 1.2), mid)
		if n % 2 == 1:
			_rect(Rect2(-2, y + 2.5, 1.0, 5.0), Color(rust.r, rust.g, rust.b, 0.7))
		y += 22.0
		n += 1
	# Gutter and elbow at the roof line.
	_rect(Rect2(-26, top - 10.0, 52, 4), iron)
	_rect(Rect2(-26, top - 10.0, 52, 1), lit)
	_rect(Rect2(-4, top - 7.0, 7, 4), mid)
	# Shoe at the street, a puddle under it.
	_rect(Rect2(-4, h * 0.5 - 6.0, 10, 4), iron)
	_rect(Rect2(-4, h * 0.5 - 6.0, 10, 1), lit)
	_rect(Rect2(0, h * 0.5 - 1.0, 18, 2), Color(0.5, 0.65, 0.8, 0.3))


## The street way up for people without a ladder: a dumpster to hop on, a
## crate stacked on its lid, an awning to spring off, the roof above.
func _paint_boost() -> void:
	var h := bottom_y - top_y
	var bot := h * 0.5
	var k := SpriteBook.DRAW_SCALE * 1.5
	var dump := SpriteBook.prop("dumpster")
	if dump:
		_sprite(dump, Vector2(0, bot), k)
	var crate := SpriteBook.prop("crate")
	if crate:
		_sprite(crate, Vector2(10, bot - 46.0), k * 0.6)
	# Two canopies up the wall, each a spring: the first over the bin,
	# the second just under the roof, a window ledge and an AC box between.
	var awn := SpriteBook.prop("awning")
	for step in [[bot - h * 0.42, 1.0, -6.0], [bot - h * 0.78, 0.8, 8.0]]:
		if awn == null:
			break
		var ka := k * float(step[1])
		var cv := _sprite(awn, Vector2.ZERO, ka)
		cv.region_enabled = true
		cv.region_rect = Rect2(0, 30, 216, 80)
		cv.position = Vector2(-108.0 * ka + float(step[2]), float(step[0]) - 80.0 * ka)
	var ledge_y := bot - h * 0.6
	_rect(Rect2(-22, ledge_y, 40, 4), Color(0.32, 0.3, 0.3), 1)
	_rect(Rect2(-22, ledge_y, 40, 1), Color(0.55, 0.52, 0.5), 1)
	_rect(Rect2(-16, ledge_y - 24.0, 28, 24), Color(0.08, 0.1, 0.14), 1)
	_rect(Rect2(-15, ledge_y - 23.0, 12, 22), Color(0.35, 0.3, 0.18, 0.8), 1)
	_rect(Rect2(-1, ledge_y - 23.0, 12, 22), Color(0.35, 0.3, 0.18, 0.8), 1)
	var ac_y := bot - h * 0.68
	_rect(Rect2(14, ac_y - 14.0, 20, 14), Color(0.55, 0.57, 0.56), 1)
	_rect(Rect2(14, ac_y - 14.0, 20, 2), Color(0.75, 0.77, 0.74), 1)
	for gx in 4:
		_rect(Rect2(16.0 + float(gx) * 4.5, ac_y - 10.0, 2.5, 8), Color(0.25, 0.26, 0.27), 1)
	# Chalk chevrons: someone's done this before.
	var chalk := Color(0.92, 0.92, 0.86, 0.5)
	for y0 in [bot - h * 0.3, bot - h * 0.53, bot - h * 0.88]:
		_rect(Rect2(-30, y0, 2, 2), chalk, 1)
		_rect(Rect2(-28, y0 - 2.0, 2, 2), chalk, 1)
		_rect(Rect2(-26, y0, 2, 2), chalk, 1)


func _sprite(tex: Texture2D, feet: Vector2, k: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(k, k)
	s.position = feet - Vector2(float(tex.get_width()) * 0.5 * k, float(tex.get_height()) * k)
	s.texture_filter = SpriteBook.world_filter()
	s.z_index = 1
	add_child(s)
	return s
