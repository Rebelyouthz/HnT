class_name LightRig
extends Node2D

const MAX_POINT := 3

static var _radial: Texture2D
var preset := "dock_street"
var _flicker := 0.0


static func radial_tex() -> Texture2D:
	if _radial != null:
		return _radial
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0.45),
		Color(1, 1, 1, 0)
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	_radial = t
	return _radial


func _ready() -> void:
	add_to_group("light_rig")
	var night := CanvasModulate.new()
	night.color = Palette.NIGHT
	night.name = "Night"
	add_child(night)

	var moon := DirectionalLight2D.new()
	moon.color = Color(0.62, 0.7, 0.92)
	moon.energy = 0.38
	moon.rotation = deg_to_rad(-38.0)
	moon.shadow_enabled = true
	moon.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	moon.shadow_filter_smooth = 1.6
	moon.height = 22.0
	add_child(moon)

	match preset:
		"fire_escapes":
			_lamp(Vector2(480, 120), Color(1.0, 0.82, 0.48), 1.3)
			_lamp(Vector2(1500, 90), Color(0.95, 0.55, 0.32), 1.2)
			_lamp(Vector2(2520, 80), Color(0.55, 0.92, 0.7), 1.15)
			_glow(Vector2(480, 128), Color(1.0, 0.78, 0.4, 0.55))
			_glow(Vector2(1500, 98), Color(0.95, 0.5, 0.28, 0.5))
			_glow(Vector2(2520, 88), Color(0.5, 0.9, 0.65, 0.45))
			_glow(Vector2(980, 120), Color(0.95, 0.55, 0.32, 0.4))
			_glow(Vector2(2100, 100), Color(0.55, 0.8, 0.9, 0.35))
		"neon_exchange":
			_lamp(Vector2(520, 140), Color(0.95, 0.35, 0.7), 1.35)
			_lamp(Vector2(1480, 110), Color(0.4, 0.85, 0.95), 1.25)
			_lamp(Vector2(2680, 150), Color(0.95, 0.55, 0.25), 1.2)
			_glow(Vector2(520, 150), Color(0.95, 0.3, 0.65, 0.55))
			_glow(Vector2(1480, 120), Color(0.35, 0.8, 0.95, 0.5))
			_glow(Vector2(2680, 160), Color(0.95, 0.5, 0.2, 0.5))
			_glow(Vector2(900, 130), Color(0.9, 0.4, 0.8, 0.4))
			_glow(Vector2(2100, 100), Color(0.45, 0.9, 0.7, 0.35))
		"rail_bridge":
			_lamp(Vector2(500, 130), Color(0.95, 0.85, 0.45), 1.2)
			_lamp(Vector2(1500, 100), Color(0.7, 0.8, 0.95), 1.15)
			_lamp(Vector2(2600, 140), Color(0.55, 0.9, 0.6), 1.2)
			_glow(Vector2(500, 140), Color(0.95, 0.8, 0.4, 0.45))
			_glow(Vector2(1500, 110), Color(0.65, 0.78, 0.95, 0.4))
			_glow(Vector2(2600, 150), Color(0.5, 0.9, 0.55, 0.45))
		"city_hall":
			_lamp(Vector2(400, 120), Color(0.85, 0.78, 0.55), 1.15)
			_lamp(Vector2(1100, 80), Color(0.95, 0.9, 0.7), 1.25)
			_lamp(Vector2(1800, 110), Color(0.9, 0.4, 0.3), 1.2)
			_glow(Vector2(400, 130), Color(0.85, 0.75, 0.5, 0.4))
			_glow(Vector2(1100, 90), Color(0.95, 0.88, 0.65, 0.45))
			_glow(Vector2(1800, 120), Color(0.9, 0.35, 0.25, 0.5))
		"invoice_pier":
			_lamp(Vector2(520, 140), Color(0.45, 0.95, 0.62), 1.3)
			_lamp(Vector2(1680, 100), Color(0.7, 0.95, 0.4), 1.2)
			_lamp(Vector2(2920, 150), Color(0.95, 0.85, 0.35), 1.25)
			_glow(Vector2(520, 150), Color(0.4, 0.95, 0.55, 0.5))
			_glow(Vector2(1680, 110), Color(0.65, 0.95, 0.35, 0.45))
			_glow(Vector2(2920, 160), Color(0.95, 0.8, 0.3, 0.5))
		"intake_lot":
			_lamp(Vector2(480, 130), Color(0.95, 0.62, 0.28), 1.3)
			_lamp(Vector2(1100, 110), Color(0.9, 0.5, 0.2), 1.2)
			_lamp(Vector2(1780, 140), Color(0.95, 0.7, 0.3), 1.2)
			_glow(Vector2(480, 140), Color(0.95, 0.55, 0.22, 0.5))
			_glow(Vector2(1100, 120), Color(0.9, 0.45, 0.18, 0.45))
			_glow(Vector2(1780, 150), Color(0.95, 0.65, 0.25, 0.45))
		"group_circle":
			_lamp(Vector2(500, 120), Color(0.92, 0.82, 0.45), 1.2)
			_lamp(Vector2(1080, 90), Color(0.55, 0.9, 0.6), 1.2)
			_lamp(Vector2(1680, 130), Color(0.95, 0.78, 0.4), 1.15)
			_glow(Vector2(500, 130), Color(0.9, 0.78, 0.4, 0.45))
			_glow(Vector2(1080, 100), Color(0.5, 0.9, 0.55, 0.4))
			_glow(Vector2(1680, 140), Color(0.95, 0.72, 0.35, 0.4))
		"waiting_room":
			_lamp(Vector2(420, 80), Color(0.85, 0.9, 0.92), 1.15)
			_lamp(Vector2(1040, 70), Color(0.75, 0.95, 0.85), 1.2)
			_lamp(Vector2(1660, 90), Color(0.9, 0.88, 0.7), 1.15)
			_glow(Vector2(420, 90), Color(0.8, 0.88, 0.9, 0.4))
			_glow(Vector2(1040, 80), Color(0.7, 0.95, 0.8, 0.4))
			_glow(Vector2(1660, 100), Color(0.9, 0.85, 0.65, 0.4))
		_:
			_lamp(Vector2(640, 160), Color(1.0, 0.82, 0.48), 1.35)
			_lamp(Vector2(1760, 140), Color(0.95, 0.55, 0.32), 1.2)
			_lamp(Vector2(3040, 180), Color(0.55, 0.92, 0.7), 1.15)
			_glow(Vector2(640, 168), Color(1.0, 0.78, 0.4, 0.55))
			_glow(Vector2(1760, 148), Color(0.95, 0.5, 0.28, 0.5))
			_glow(Vector2(3040, 188), Color(0.5, 0.9, 0.65, 0.45))


func _process(delta: float) -> void:
	_flicker += delta
	for c in get_children():
		if c is PointLight2D:
			var p := c as PointLight2D
			if not p.has_meta("base_e"):
				p.set_meta("base_e", p.energy)
			p.energy = float(p.get_meta("base_e")) * (0.9 + 0.1 * sin(_flicker * 6.4 + p.position.x * 0.008))


func tint_at(world: Vector2) -> Color:
	var best := Color.WHITE
	var best_d := 320.0
	for c in get_children():
		if not (c is PointLight2D):
			continue
		var p := c as PointLight2D
		var d := p.global_position.distance_to(world)
		if d >= best_d:
			continue
		best_d = d
		var t := 1.0 - d / 320.0
		best = Color.WHITE.lerp(p.color, t * 0.42)
	return best


func blackout() -> void:
	var night := get_node_or_null("Night") as CanvasModulate
	if night:
		night.color = Color(0.08, 0.08, 0.12)
	for c in get_children():
		if c is DirectionalLight2D:
			(c as DirectionalLight2D).energy = 0.08
		elif c is PointLight2D:
			(c as PointLight2D).energy = 0.12
			(c as PointLight2D).color = Color(0.9, 0.25, 0.2)
			(c as PointLight2D).set_meta("base_e", 0.12)


func _lamp(at: Vector2, color: Color, energy: float) -> void:
	if get_child_count() >= MAX_POINT + 2:
		return
	var p := PointLight2D.new()
	p.position = at
	p.texture = radial_tex()
	p.texture_scale = 3.4
	p.color = color
	p.energy = energy
	p.height = 14.0
	p.shadow_enabled = true
	p.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(p)


func _glow(at: Vector2, color: Color) -> void:
	var g := Polygon2D.new()
	g.position = at
	g.color = color
	g.polygon = PackedVector2Array([
		Vector2(-36, -10), Vector2(36, -10), Vector2(70, 90), Vector2(-70, 90)
	])
	Blockout.add_glow(g)
	g.z_index = -1
	add_child(g)
