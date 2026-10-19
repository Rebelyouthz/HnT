class_name ActorLight
extends Node2D

## Lamp light on a character, the way a lit street reads in a painted
## beat 'em up:
## - Cast shadows shaped like the body: the frame on screen, blacked out,
##   laid on the floor (squashed and sheared away from each of the two
##   nearest lamps), longer and fainter the further the lamp; a faint one
##   from the moon everywhere. The shadow stays on the ground through hops.
## - Rim light: the body edge facing the nearest lamp catches its colour
##   (wound.gdshader rim_*), and the body is brighter under a lamp and
##   darker in the gaps (lit).
## Light sources: LightRig's lamps and the street lamp props.

const RANGE := 420.0
const MAX_LAMPS := 2
## Street lamp props stand on their base; the bulb hangs this high above.
const LAMP_HEAD := 150.0

static var _frame := -1
static var _srcs: Array = []

var actor: Node2D
var anim: AnimatedSprite2D
var _shadows: Array[Sprite2D] = []
var _tick := 0


static func attach(who: Node2D, a: AnimatedSprite2D) -> ActorLight:
	if who == null or a == null:
		return null
	var l := ActorLight.new()
	l.actor = who
	l.anim = a
	l.z_index = 0
	l.name = "ActorLight"
	who.add_child(l)
	who.move_child(l, 0)
	return l


func _ready() -> void:
	for i in MAX_LAMPS + 1:
		var s := Sprite2D.new()
		s.modulate = Color(0, 0, 0, 0)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(s)
		_shadows.append(s)
	# The wound shader carries the rim light: give every body one now.
	if anim.material == null:
		BloodSim._wound_mat(anim)


## Every lamp in the scene, gathered once a frame for all actors:
## [bulb position, colour, strength].
static func sources(tree: SceneTree) -> Array:
	var f := Engine.get_process_frames()
	if f == _frame:
		return _srcs
	_frame = f
	_srcs = []
	var rig := tree.get_first_node_in_group("light_rig")
	if rig:
		for c in rig.get_children():
			if c is PointLight2D and (c as PointLight2D).visible:
				var p := c as PointLight2D
				_srcs.append([p.global_position, p.color, clampf(p.energy, 0.2, 1.6)])
	for n in tree.get_nodes_in_group("street_lamps"):
		if n is Node2D and (n as Node2D).is_inside_tree():
			_srcs.append([(n as Node2D).global_position + Vector2(0, -LAMP_HEAD), Color(1.0, 0.8, 0.5), 1.0])
	return _srcs


func _process(_delta: float) -> void:
	if anim == null or not is_instance_valid(anim) or anim.sprite_frames == null:
		return
	if not anim.is_visible_in_tree():
		for s in _shadows:
			s.visible = false
		return
	var feet := actor.global_position
	# The two nearest lamps by floor distance.
	var near: Array = []
	for src: Array in sources(get_tree()):
		var d := absf((src[0] as Vector2).x - feet.x)
		if d < RANGE:
			near.append([d, src])
	near.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var tex := anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	var rel := actor.global_transform.affine_inverse() * anim.global_transform
	var vis := actor.get("visual") as Node2D
	var lift := 0.0
	if vis:
		lift = -vis.position.y
		rel.origin.y += lift
	var air := clampf(lift / 90.0, 0.0, 1.0)
	# Moon: a short faint shadow everywhere, down-right (LightRig's moon).
	_lay(_shadows[0], tex, rel, 0.35, -0.3, 0.26 * (1.0 - air))
	var glow := 0.0
	var best: Array = []
	for i in MAX_LAMPS:
		var s := _shadows[i + 1]
		if i >= near.size():
			s.visible = false
			continue
		var src: Array = near[i][1]
		var d := float(near[i][0])
		var dx := feet.x - (src[0] as Vector2).x
		var t := 1.0 - d / RANGE
		var k := -(0.3 + 0.24 * (1.0 - t))
		var shear := -signf(dx) * clampf(absf(dx) / 260.0, 0.0, 0.85)
		_lay(s, tex, rel, shear, k, clampf(0.8 * sqrt(t) * float(src[2]), 0.0, 0.75) * (1.0 - air * 0.8))
		var g := t * t * float(src[2])
		if g > glow:
			glow = g
			best = src
	# Rim light and brightness, a few times a second is plenty.
	_tick += 1
	if _tick % 3 != 0:
		return
	var m := anim.material as ShaderMaterial
	if m == null:
		return
	if best.is_empty():
		m.set_shader_parameter("rim_k", 0.0)
		m.set_shader_parameter("lit", 0.82)
		return
	var head := feet + Vector2(0, -60)
	var dir := ((best[0] as Vector2) - head).normalized()
	# Screen -> texture space: undo the body's facing flip.
	var sx := signf(anim.global_transform.x.x) * (-1.0 if anim.flip_h else 1.0)
	m.set_shader_parameter("rim_dir", Vector2(dir.x * sx, dir.y))
	m.set_shader_parameter("rim_k", 0.9 * glow)
	m.set_shader_parameter("rim_col", best[1])
	m.set_shader_parameter("lit", lerpf(0.82, 1.12, glow))


func _lay(s: Sprite2D, tex: Texture2D, rel: Transform2D, shear: float, k: float, a: float) -> void:
	if a < 0.02 or tex == null:
		s.visible = false
		return
	s.visible = true
	s.texture = tex
	s.centered = anim.centered
	s.offset = anim.offset
	s.flip_h = anim.flip_h
	# Lay the frame on the floor: the feet stay put, height becomes depth.
	var lay := Transform2D(Vector2(1, 0), Vector2(shear, k), Vector2.ZERO)
	s.transform = lay * rel
	s.modulate = Color(0.0, 0.0, 0.02, a)
