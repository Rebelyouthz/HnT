class_name BloodSim
extends Node2D

const POOL := 48
var _drops: Array[Dictionary] = []
var _stains: Array[Polygon2D] = []


func _ready() -> void:
	add_to_group("blood_sim")
	z_index = 6
	for i in POOL:
		var d := Polygon2D.new()
		d.color = Color(0.55, 0.05, 0.08, 0.92)
		d.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
		d.visible = false
		add_child(d)
		_drops.append({"node": d, "vel": Vector2.ZERO, "life": 0.0, "active": false})


func spray(at: Vector2, kind: String, dir: float) -> void:
	if FamilyProfile.less_gore():
		return
	if kind == "light":
		return
	var n := 8
	var speed := 180.0
	var cone := false
	if kind == "snap" or kind == "finish":
		n = 18
		speed = 280.0
		cone = true
	elif kind == "web-slam":
		n = 14
		speed = 240.0
	elif kind == "heavy" or kind == "dive" or kind == "launcher":
		n = 10
	elif kind == "blade":
		n = 12
		speed = 260.0
		cone = true
	var launched := 0
	for drop in _drops:
		if drop["active"]:
			continue
		drop["active"] = true
		drop["life"] = randf_range(0.35, 0.7)
		var ang: float
		if cone:
			ang = dir * 0.35 + randf_range(-0.35, 0.35)
		else:
			ang = dir * 0.6 + randf_range(-0.8, 0.8)
		drop["vel"] = Vector2(cos(ang), -absf(sin(ang)) - 0.2) * speed * randf_range(0.6, 1.2)
		var node: Polygon2D = drop["node"]
		node.visible = true
		node.global_position = at + Vector2(0, -28)
		node.modulate.a = 1.0
		launched += 1
		if launched >= n:
			break


func pump(at: Vector2, dir: float) -> void:
	if FamilyProfile.less_gore():
		return
	spray(at, "heavy", dir)
	get_tree().create_timer(0.08, true, false, true).timeout.connect(func() -> void:
		spray(at + Vector2(dir * 8.0, 4.0), "heavy", dir)
	)
	get_tree().create_timer(0.16, true, false, true).timeout.connect(func() -> void:
		spray(at + Vector2(dir * 4.0, 8.0), "blade", dir)
	)


func pulse(at: Vector2) -> void:
	if FamilyProfile.less_gore():
		return
	spray(at, "heavy", 1.0)
	spray(at, "heavy", -1.0)


func _process(delta: float) -> void:
	for drop in _drops:
		if not drop["active"]:
			continue
		drop["life"] -= delta
		drop["vel"].y += 980.0 * delta
		var node: Polygon2D = drop["node"]
		node.global_position += drop["vel"] * delta
		if node.global_position.y >= 520.0 or drop["life"] <= 0.0:
			_stain(node.global_position)
			if randf() < 0.22:
				_drip(node.global_position)
			node.visible = false
			drop["active"] = false


func _stain(at: Vector2) -> void:
	if _stains.size() > 28:
		var old: Polygon2D = _stains.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var s := Polygon2D.new()
	s.color = Color(0.42, 0.04, 0.07, 0.45)
	var w := randf_range(6.0, 14.0)
	s.polygon = PackedVector2Array([
		Vector2(-w, -3), Vector2(w, -3), Vector2(w * 0.8, 3), Vector2(-w * 0.8, 3)
	])
	s.global_position = Vector2(at.x, minf(at.y, 528.0))
	s.z_index = 1
	var host := get_parent()
	host.add_child(s)
	_stains.append(s)


func _drip(at: Vector2) -> void:
	for drop in _drops:
		if drop["active"]:
			continue
		drop["active"] = true
		drop["life"] = 0.45
		drop["vel"] = Vector2(randf_range(-18, 18), 40.0)
		var node: Polygon2D = drop["node"]
		node.visible = true
		node.global_position = at + Vector2(0, -8)
		node.modulate.a = 0.8
		break
