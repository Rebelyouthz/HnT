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


## Iron ladder drawn at the world grid: two rails with a lit edge, rungs
## every 11 u, bolts, a landing grate at the top. (The old board sprite was
## stretched up to 3.2x and smeared.)
func _paint() -> void:
	var h := bottom_y - top_y
	var iron := Color(0.11, 0.11, 0.13)
	var lit := Color(0.36, 0.33, 0.34)
	var rust := Color(0.34, 0.17, 0.12)
	for x in [-15.0, 11.0]:
		_rect(Rect2(x, -h * 0.5 - 6.0, 4, h + 6.0), iron)
		_rect(Rect2(x, -h * 0.5 - 6.0, 1, h + 6.0), lit)
	var y := -h * 0.5 + 4.0
	var n := 0
	while y < h * 0.5 - 2.0:
		_rect(Rect2(-11, y, 22, 2), iron)
		_rect(Rect2(-11, y, 22, 1), lit if n % 3 != 1 else rust)
		y += 11.0
		n += 1
	# Landing grate + bracket at the roof line.
	_rect(Rect2(-22, -h * 0.5 - 8.0, 44, 3), iron)
	_rect(Rect2(-22, -h * 0.5 - 8.0, 44, 1), lit)
	for bx in range(-20, 22, 6):
		_rect(Rect2(float(bx), -h * 0.5 - 5.0, 1, 6), iron)


func _rect(r: Rect2, c: Color) -> void:
	var p := Polygon2D.new()
	p.color = c
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	p.z_index = 1
	add_child(p)
