class_name Blockout
extends Object


static func poly(parent: Node, rect: Rect2, color: Color, z: int = 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = color
	p.z_index = z
	var o := rect.position
	var s := rect.size
	p.polygon = PackedVector2Array([
		o,
		o + Vector2(s.x, 0.0),
		o + s,
		o + Vector2(0.0, s.y)
	])
	parent.add_child(p)
	return p


static func solid(parent: Node, rect: Rect2, roof: bool = false) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = rect.size
	cs.shape = sh
	cs.position = rect.position + rect.size * 0.5
	b.add_child(cs)
	b.set_meta("rect", rect)
	if roof:
		b.add_to_group("roof_solids")
		b.add_to_group("metal")
	parent.add_child(b)
	return b


static func occluder(parent: Node, rect: Rect2) -> LightOccluder2D:
	var o := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	var p := rect.position
	var s := rect.size
	poly.polygon = PackedVector2Array([
		p,
		p + Vector2(s.x, 0.0),
		p + s,
		p + Vector2(0.0, s.y)
	])
	o.occluder = poly
	parent.add_child(o)
	return o


static func add_glow(node: CanvasItem) -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	node.material = mat
