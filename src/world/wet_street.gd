class_name WetStreet
extends Node2D

## The street after rain: a painted cobble road (assets/backdrops/street.png,
## tiled seamlessly) under a reflection pass that mirrors the shops, signs and
## lamps above the kerb into the puddles, light streaks under every lamp, and
## upside-down copies of everyone walking on it. Lit by the level's lights;
## the reflection itself is unshaded.

const TEX := "res://assets/backdrops/street.png"
const MASK := "res://assets/backdrops/street_wet.png"
## The paving is painted top-down: squashed 2:1 vertically it lies flat.
const TEXEL := 0.14
const TEXEL_Y := 0.075
const TOP := 426.0

var map_w := 3200.0
## Which painted ground: "street" (cobbles) or e.g. "lot_ground" (asphalt);
## <name>.png + <name>_wet.png in assets/backdrops.
var ground := "street"
var _fx: Sprite2D
var _mirrors := {}
var _streaks: Array[Node2D] = []
var _t := 0.0


static func available(name: String = "street") -> bool:
	return ResourceLoader.exists("res://assets/backdrops/%s.png" % name) and ResourceLoader.exists("res://assets/backdrops/%s_wet.png" % name)


static func lay(host: Node, width: float, name: String = "street") -> WetStreet:
	var w := WetStreet.new()
	w.map_w = width
	w.ground = name
	w.name = "WetStreet"
	host.add_child(w)
	return w


func _ready() -> void:
	var tex := load("res://assets/backdrops/%s.png" % ground) as Texture2D
	var region := Rect2(0, 0, ceilf(map_w / TEXEL) + 4.0, ceilf(300.0 / TEXEL_Y))
	var base := Sprite2D.new()
	base.texture = tex
	base.centered = false
	base.region_enabled = true
	base.region_rect = region
	base.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	base.scale = Vector2(TEXEL, TEXEL_Y)
	base.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	base.position = Vector2(0, TOP)
	base.z_index = 0
	add_child(base)
	# A soft kerb shadow where the backdrop's sidewalk meets the road.
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([Vector2(0, TOP), Vector2(map_w, TOP), Vector2(map_w, TOP + 10), Vector2(0, TOP + 10)])
	lip.vertex_colors = PackedColorArray([Color(0, 0, 0.02, 0.7), Color(0, 0, 0.02, 0.7), Color(0, 0, 0.02, 0), Color(0, 0, 0.02, 0)])
	lip.z_index = 0
	add_child(lip)
	_fx = Sprite2D.new()
	_fx.texture = tex
	_fx.centered = false
	_fx.region_enabled = true
	_fx.region_rect = region
	_fx.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_fx.scale = base.scale
	_fx.position = base.position
	_fx.z_index = 1
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/shaders/wet_reflect.gdshader")
	mat.set_shader_parameter("wet_mask", load("res://assets/backdrops/%s_wet.png" % ground))
	mat.set_shader_parameter("tex_size", Vector2(tex.get_width(), tex.get_height()))
	_fx.material = mat
	add_child(_fx)
	# LOW quality: no screen-space reflection pass.
	_fx.visible = Gfx.reflections()
	call_deferred("_lamp_streaks")


## Light on wet stone: a long soft streak under every lamp and sign glow.
func _lamp_streaks() -> void:
	var rig := get_tree().get_first_node_in_group("light_rig")
	var spots: Array = []
	if rig:
		for c in rig.get_children():
			if c is PointLight2D:
				spots.append([(c as Node2D).global_position.x, (c as PointLight2D).color, 1.0])
			elif c is Polygon2D:
				spots.append([(c as Node2D).global_position.x, (c as Polygon2D).color, 0.6])
	for n in get_tree().get_nodes_in_group("street_lamps"):
		if n is Node2D:
			spots.append([(n as Node2D).global_position.x, Color(1.0, 0.8, 0.5), 0.9])
	for s: Array in spots:
		_streak(float(s[0]), s[1] as Color, float(s[2]))


func _streak(x: float, col: Color, k: float) -> void:
	var t := _streak_tex()
	var sp := Sprite2D.new()
	sp.texture = t
	sp.centered = false
	sp.position = Vector2(x - 12.0, TOP + 4.0)
	sp.scale = Vector2(24.0 / 32.0, 160.0 / 128.0)
	sp.modulate = Color(col.r, col.g, col.b, 0.16 * k)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sp.material = m
	sp.z_index = 1
	sp.set_meta("x", x)
	add_child(sp)
	_streaks.append(sp)


static var _stex: Texture2D


## Soft vertical smear: bright under the kerb, fading down and to the sides.
static func _streak_tex() -> Texture2D:
	if _stex != null:
		return _stex
	var img := Image.create(32, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		var v := float(y) / 127.0
		var fall := clampf(v / 0.12, 0.0, 1.0) * pow(1.0 - v, 1.6)
		for x in 32:
			var u := absf(float(x) - 15.5) / 16.0
			var side := pow(clampf(1.0 - u, 0.0, 1.0), 2.2)
			# Broken by ripples: horizontal bands like light on wet asphalt.
			var band := 0.75 + 0.25 * sin(float(y) * 1.3)
			img.set_pixel(x, y, Color(1, 1, 1, fall * side * band))
	_stex = ImageTexture.create_from_image(img)
	return _stex


func _process(delta: float) -> void:
	_t += delta
	if _fx == null:
		return
	var vp := get_viewport()
	var ct := vp.get_canvas_transform()
	var vis := vp.get_visible_rect().size
	var kerb := ct * Vector2(0, TOP)
	var mat := _fx.material as ShaderMaterial
	mat.set_shader_parameter("mirror_y", kerb.y / vis.y)
	# Reflections snap to a fine block (about a world unit) so they read
	# as liquid without breaking the painted look.
	var sc := ct.get_scale().y * 0.75
	mat.set_shader_parameter("uv_block", Vector2(sc / vis.x, sc / vis.y))
	for i in _streaks.size():
		var sp := _streaks[i] as Sprite2D
		sp.position.x = float(sp.get_meta("x")) - 12.0 + sin(_t * 2.3 + float(i)) * 1.5
		sp.scale.x = (24.0 + 4.0 * sin(_t * 3.1 + float(i) * 1.7)) / 32.0
	_reflect_actors()


## Everyone on the street gets an upside-down twin in the wet stone.
func _reflect_actors() -> void:
	var seen := {}
	for g in ["players", "enemies", "crew"]:
		for n in get_tree().get_nodes_in_group(g):
			if not (n is Node2D) or not is_instance_valid(n):
				continue
			var anim := _anim_of(n as Node2D)
			if anim == null or not anim.is_visible_in_tree():
				continue
			var id := n.get_instance_id()
			seen[id] = true
			var m: Sprite2D = _mirrors.get(id)
			if m == null or not is_instance_valid(m):
				m = Sprite2D.new()
				m.z_index = 1
				var cm := CanvasItemMaterial.new()
				cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
				m.material = cm
				add_child(m)
				_mirrors[id] = m
			_copy(anim, m, (n as Node2D).global_position.y)
	for id: int in _mirrors.keys():
		if not seen.has(id):
			var m: Sprite2D = _mirrors[id]
			if is_instance_valid(m):
				m.queue_free()
			_mirrors.erase(id)


func _anim_of(n: Node2D) -> AnimatedSprite2D:
	for c in n.get_children():
		if c is AnimatedSprite2D:
			return c
		if c is Node2D:
			for cc in c.get_children():
				if cc is AnimatedSprite2D:
					return cc
	return null


func _copy(anim: AnimatedSprite2D, m: Sprite2D, feet: float) -> void:
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation(anim.animation):
		m.visible = false
		return
	var gp := anim.global_position
	if feet < TOP:
		# Up on a roof or a ledge: nothing to mirror in.
		m.visible = false
		return
	m.visible = true
	m.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	m.centered = anim.centered
	m.offset = anim.offset
	m.flip_h = anim.flip_h
	var gs := anim.global_scale
	m.global_scale = Vector2(gs.x, -gs.y)
	m.global_rotation = -anim.global_rotation
	m.global_position = Vector2(gp.x, 2.0 * feet - gp.y + 2.0)
	var a := 0.34
	if anim.modulate.a < 1.0:
		a *= anim.modulate.a
	m.modulate = Color(0.55, 0.62, 0.85, a)
