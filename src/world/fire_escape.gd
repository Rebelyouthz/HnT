class_name FireEscape
extends Area2D

@export var top_y: float = 248.0
@export var bottom_y: float = 500.0
@export var climb_x: float = 0.0


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


func configure(at_x: float, top: float, bottom: float) -> void:
	climb_x = at_x
	top_y = top
	bottom_y = bottom
	global_position = Vector2(at_x, (top + bottom) * 0.5)


func covers(pos: Vector2) -> bool:
	if absf(pos.x - climb_x) > 26.0:
		return false
	return pos.y >= top_y - 18.0 and pos.y <= bottom_y + 24.0


## Iron ladder at the same fine detail as the characters and the painted
## street: thin rails with a lit edge and a shadow edge, rungs every 6 u
## with rivets, rust streaks, a railed landing at the roof line and a
## drop-shadow on the wall behind.
func _paint() -> void:
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
