class_name StreetLife
extends Node2D

## The street breathes between fights: steam curling out of manholes and
## vents, headlights of a car you never see sweeping the facades, a
## neon-lit puddle shimmer. Pure atmosphere, no collision.

var vents: Array = []
var _puffs: Array[Dictionary] = []
var _t := 0.0
var _sweep_t := 6.0
var _beam: Polygon2D


static func dress(host: Node, xs: Array) -> StreetLife:
	var s := StreetLife.new()
	s.vents = xs
	s.z_index = 8
	host.add_child(s)
	return s


func _ready() -> void:
	_beam = Polygon2D.new()
	_beam.polygon = PackedVector2Array([Vector2(-10, 300), Vector2(10, 300), Vector2(120, 470), Vector2(-120, 470)])
	_beam.vertex_colors = PackedColorArray([Color(1, 0.95, 0.8, 0.0), Color(1, 0.95, 0.8, 0.0), Color(1, 0.95, 0.8, 0.12), Color(1, 0.95, 0.8, 0.12)])
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_beam.material = m
	_beam.visible = false
	_beam.z_index = -1
	add_child(_beam)


func _process(delta: float) -> void:
	_t += delta
	# Steam: a new puff from each vent every so often.
	for v in vents:
		if randf() < delta * 3.0:
			_puffs.append({"p": Vector2(float(v) + randf_range(-6, 6), 500.0), "v": Vector2(randf_range(-6, 10), randf_range(-26, -16)), "r": randf_range(4, 7), "life": 0.0, "max": randf_range(2.2, 3.4)})
	var i := 0
	while i < _puffs.size():
		var p: Dictionary = _puffs[i]
		p["life"] = float(p["life"]) + delta
		if float(p["life"]) >= float(p["max"]):
			_puffs.remove_at(i)
			continue
		p["p"] = (p["p"] as Vector2) + (p["v"] as Vector2) * delta
		p["r"] = float(p["r"]) + delta * 6.0
		i += 1
	queue_redraw()
	# Headlights from the cross street now and then.
	_sweep_t -= delta
	if _sweep_t <= 0.0 and not _beam.visible:
		_sweep()


func _sweep() -> void:
	_sweep_t = randf_range(14.0, 26.0)
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam else 600.0
	var dir := 1.0 if randf() < 0.5 else -1.0
	_beam.visible = true
	_beam.position = Vector2(cx - dir * 420.0, 0)
	_beam.skew = -dir * 0.4
	Juice.play("res://assets/audio/car_pass.wav" if ResourceLoader.exists("res://assets/audio/car_pass.wav") else "res://assets/audio/whoosh_heavy.wav")
	var tw := create_tween()
	tw.tween_property(_beam, "position:x", cx + dir * 420.0, 2.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: _beam.visible = false)


func _draw() -> void:
	for p in _puffs:
		var u := float(p["life"]) / float(p["max"])
		var a := sin(u * PI) * 0.16
		# Soft-edged puffs (a radial falloff, not hard discs) so steam reads
		# as vapour.
		var soft := LightRig.radial_tex()
		var r := float(p["r"]) * 1.7
		var c := p["p"] as Vector2
		draw_texture_rect(soft, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(0.75, 0.8, 0.88, a * 1.4))
		var c2 := c + Vector2(float(p["r"]) * 0.4, -2)
		draw_texture_rect(soft, Rect2(c2 - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4), false, Color(0.85, 0.88, 0.95, a))
