class_name WebAnchor
extends Marker2D

const MIN_LEN := 80.0
const MAX_LEN := 280.0


func _ready() -> void:
	add_to_group("web_anchors")
	add_to_group("metal")
	z_index = 4
	var hook := Polygon2D.new()
	hook.color = Color(0.72, 0.74, 0.8)
	hook.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0), Vector2(3, 14), Vector2(-3, 14)
	])
	add_child(hook)
	var beam := Polygon2D.new()
	beam.color = Color(0.18, 0.16, 0.2)
	beam.polygon = PackedVector2Array([
		Vector2(-40, -8), Vector2(40, -8), Vector2(40, 0), Vector2(-40, 0)
	])
	add_child(beam)


static func nearest_in_cone(from: Vector2, facing: int, origin: Node) -> WebAnchor:
	var best: WebAnchor = null
	var best_d := MAX_LEN + 1.0
	for n in origin.get_tree().get_nodes_in_group("web_anchors"):
		if n is WebAnchor:
			var a: WebAnchor = n
			var d: Vector2 = a.global_position - from
			var dist := d.length()
			if dist < MIN_LEN or dist > MAX_LEN:
				continue
			if facing > 0 and d.x < -12.0:
				continue
			if facing < 0 and d.x > 12.0:
				continue
			if dist < best_d:
				best_d = dist
				best = a
	return best
