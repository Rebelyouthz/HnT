extends SceneTree

## Renders the wound shader's gun states on a punk sprite side by side:
## intact, cut_head, flying head (only=1), gape, cut_leg, flying leg (only=2).
##   xvfb-run godot --path . --rendering-driver opengl3 --script res://tools/gore_shader_test.gd -- out.png

var _frame := 0


func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.22, 0.3)
	bg.size = Vector2(1400, 400)
	root.add_child(bg)
	var sf: SpriteFrames = load("res://src/sprites/sprite_book.gd").frames("punk")
	var shader := load("res://src/shaders/wound.gdshader") as Shader
	var bs: Script = load("res://src/juice/blood.gd")
	var states := [{"wound": 0.6}, {"cut_head": 1.0}, {"only": 1}, {"gape": "G"}, {"cut_leg": 1.0}, {"only": 2, "cut_leg": 1.0}]
	for i in states.size():
		var a := AnimatedSprite2D.new()
		a.sprite_frames = sf
		a.animation = "idle"
		a.frame = 0
		a.position = Vector2(50 + i * 105, 250)
		a.scale = Vector2(0.75, 0.75)
		var m := ShaderMaterial.new()
		m.shader = shader
		var head: Vector3 = bs.head_of(a)
		m.set_shader_parameter("head", head)
		m.set_shader_parameter("holes", PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
		for k in states[i]:
			var v: Variant = states[i][k]
			if str(v) == "G":
				v = Vector3(head.x - head.z * 0.45, head.y + head.z * 3.2, head.z * 1.2)
			m.set_shader_parameter(k, v)
		a.material = m
		root.add_child(a)
		print("head ", head)


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 5:
		root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		quit(0)
	return false
