class_name LightRig
extends Node2D

const MAX_POINT := 3

static var _radial: Texture2D


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

	_lamp(Vector2(640, 160), Color(1.0, 0.82, 0.48), 1.35)
	_lamp(Vector2(1760, 140), Color(0.95, 0.55, 0.32), 1.2)
	_lamp(Vector2(3040, 180), Color(0.55, 0.92, 0.7), 1.15)


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
