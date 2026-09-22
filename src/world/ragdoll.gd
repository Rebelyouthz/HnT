class_name StreetRagdoll
extends Node2D

## Parts fly. Gravity. Stains. Not a second blood sim.

var _bits: Array[Dictionary] = []
var _life := 0.95
var _dir := 1.0


static func burst(host: Node, at: Vector2, dir: float, accent: Color) -> void:
	if FamilyProfile.less_gore():
		return
	if host == null:
		return
	var n := StreetRagdoll.new()
	n.global_position = at
	host.add_child(n)
	n._spew(dir, accent)


func _spew(dir: float, accent: Color) -> void:
	_dir = dir
	z_index = 7
	for i in 4:
		var p := Polygon2D.new()
		p.color = accent if i == 0 else Color(0.42, 0.08, 0.1, 0.92)
		var s := 6.0 + float(i) * 2.0
		p.polygon = PackedVector2Array([
			Vector2(-s, -s * 0.6), Vector2(s, -s * 0.5), Vector2(s * 0.7, s), Vector2(-s * 0.8, s)
		])
		add_child(p)
		_bits.append({
			"node": p,
			"vel": Vector2(dir * randf_range(80.0, 220.0), randf_range(-280.0, -80.0)),
			"spin": randf_range(-8.0, 8.0)
		})


func _process(delta: float) -> void:
	_life -= delta
	for bit in _bits:
		var node: Polygon2D = bit["node"]
		bit["vel"].y += 980.0 * delta
		node.position += bit["vel"] * delta
		node.rotation += float(bit["spin"]) * delta
	if _life > 0.0:
		return
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("run_pool"):
		blood.run_pool(global_position, _dir)
	queue_free()
