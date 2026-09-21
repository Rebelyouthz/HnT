class_name LightRig
extends Node2D

const MAX_POINT := 3

static var _radial: Texture2D
var preset := "dock_street"


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
	var night := CanvasModulate.new()
	night.color = Palette.NIGHT
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

	if preset == "fire_escapes":
		_lamp(Vector2(480, 120), Color(1.0, 0.82, 0.48), 1.3)
		_lamp(Vector2(1500, 90), Color(0.95, 0.55, 0.32), 1.2)
		_lamp(Vector2(2520, 80), Color(0.55, 0.92, 0.7), 1.15)
		_glow(Vector2(480, 128), Color(1.0, 0.78, 0.4, 0.55))
		_glow(Vector2(1500, 98), Color(0.95, 0.5, 0.28, 0.5))
		_glow(Vector2(2520, 88), Color(0.5, 0.9, 0.65, 0.45))
		_glow(Vector2(980, 120), Color(0.95, 0.55, 0.32, 0.4))
		_glow(Vector2(2100, 100), Color(0.55, 0.8, 0.9, 0.35))
	else:
		_lamp(Vector2(640, 160), Color(1.0, 0.82, 0.48), 1.35)
		_lamp(Vector2(1760, 140), Color(0.95, 0.55, 0.32), 1.2)
		_lamp(Vector2(3040, 180), Color(0.55, 0.92, 0.7), 1.15)
		_glow(Vector2(640, 168), Color(1.0, 0.78, 0.4, 0.55))
		_glow(Vector2(1760, 148), Color(0.95, 0.5, 0.28, 0.5))
		_glow(Vector2(3040, 188), Color(0.5, 0.9, 0.65, 0.45))


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
