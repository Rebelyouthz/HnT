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


func _paint() -> void:
	var h := bottom_y - top_y
	var rail := Polygon2D.new()
	rail.color = Color(0.28, 0.16, 0.14)
	rail.polygon = PackedVector2Array([
		Vector2(-16, -h * 0.5), Vector2(-10, -h * 0.5),
		Vector2(-10, h * 0.5), Vector2(-16, h * 0.5)
	])
	add_child(rail)
	var rail2 := rail.duplicate() as Polygon2D
	rail2.position.x = 26
	add_child(rail2)
	var y := -h * 0.5
	while y < h * 0.5:
		var rung := Polygon2D.new()
		rung.color = Color(0.42, 0.24, 0.2)
		rung.polygon = PackedVector2Array([
			Vector2(-16, y), Vector2(16, y), Vector2(16, y + 5), Vector2(-16, y + 5)
		])
		add_child(rung)
		y += 22.0
	var span := maxf(96.0, h)
	SpriteBook.attach_scaled(self, "fire_escape", 0.0, Vector2(0.85, clampf(span / 96.0, 1.4, 3.2)))
