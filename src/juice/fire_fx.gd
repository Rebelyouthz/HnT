class_name FireFx
extends Node2D

## Fire: flames licking up a burning body (attached to it), or a patch of
## burning flare on the street. Flickering light, embers, smoke, a crackle.

var life := 3.0
var size := 1.0
var _t := 0.0
var _light: PointLight2D
var _flames: CPUParticles2D


## Burning patch on the street where a flare landed.
static func ground(host: Node, at: Vector2, secs: float) -> FireFx:
	if host == null:
		return null
	var f := FireFx.new()
	f.life = secs
	f.size = 0.7
	f.position = at
	host.add_child(f)
	return f


## Flames on a body (follows it as a child).
static func on_body(body: Node2D, secs: float) -> FireFx:
	for c in body.get_children():
		if c is FireFx:
			(c as FireFx).life = maxf((c as FireFx).life - (c as FireFx)._t, secs)
			(c as FireFx)._t = 0.0
			return c
	var f := FireFx.new()
	f.life = secs
	f.size = 1.0
	f.position = Vector2(0, -30)
	body.add_child(f)
	return f


func _ready() -> void:
	z_index = 5
	_flames = CPUParticles2D.new()
	_flames.amount = int(30 * size)
	_flames.lifetime = 0.5
	_flames.local_coords = false
	_flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_flames.emission_rect_extents = Vector2(12, 22) * size if size >= 1.0 else Vector2(10, 2)
	_flames.direction = Vector2(0, -1)
	_flames.spread = 18.0
	_flames.gravity = Vector2(0, -120)
	_flames.initial_velocity_min = 20.0
	_flames.initial_velocity_max = 60.0
	_flames.scale_amount_min = 2.0
	_flames.scale_amount_max = 4.5
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.add_point(0.35, Color(1.0, 0.5, 0.12, 0.9))
	g.set_color(g.get_point_count() - 1, Color(0.3, 0.28, 0.3, 0.0))
	_flames.color_ramp = g
	var cm := CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_flames.material = cm
	add_child(_flames)
	var embers := CPUParticles2D.new()
	embers.amount = 8
	embers.lifetime = 0.9
	embers.local_coords = false
	embers.gravity = Vector2(0, -60)
	embers.initial_velocity_min = 30.0
	embers.initial_velocity_max = 90.0
	embers.spread = 50.0
	embers.direction = Vector2(0, -1)
	embers.color = Color(1.0, 0.7, 0.3)
	embers.material = cm
	add_child(embers)
	_light = PointLight2D.new()
	_light.texture = LightRig.radial_tex()
	_light.texture_scale = 0.7 * size + 0.2
	_light.color = Color(1.0, 0.5, 0.2)
	_light.energy = 1.3
	add_child(_light)
	if ResourceLoader.exists("res://assets/audio/sfx/fire_crackle.ogg"):
		Mixer.play_sfx("res://assets/audio/sfx/fire_crackle.ogg", randf_range(0.9, 1.1), -9.0)


func _process(delta: float) -> void:
	_t += delta
	var fade := clampf((life - _t) / 0.6, 0.0, 1.0)
	_light.energy = (1.2 + randf_range(-0.3, 0.3)) * fade
	_flames.emitting = _t < life
	if _t > life + 0.6:
		queue_free()
