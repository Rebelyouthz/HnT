extends SceneTree
var n := 0
func _process(_d: float) -> bool:
	n += 1
	if n == 3:
		var bg := ColorRect.new()
		bg.color = Color(0.3, 0.3, 0.35)
		bg.size = Vector2(2000, 2000)
		root.add_child(bg)
		var sb = load("res://src/sprites/sprite_book.gd")
		var bs = load("res://src/juice/blood.gd")
		var i := 0
		for who in ["son", "father"]:
			for clip in ["idle", "jab", "walk"]:
				var a = sb.make_anim(who)
				a.scale = Vector2(0.3, 0.3)
				a.position = Vector2(60 + i * 100, 200)
				root.add_child(a)
				if a.sprite_frames.has_animation(clip):
					a.play(clip)
					a.frame = 3
				a.pause()
				var mat := ShaderMaterial.new()
				mat.shader = load("res://src/shaders/wound.gdshader")
				mat.set_shader_parameter("head", bs.head_of(a))
				mat.set_shader_parameter("suit", 1 if who == "son" else 2)
				mat.set_shader_parameter("holes", PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
				a.material = mat
				i += 1
	if n == 12:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/pw/qa/suits.png")
		return true
	return false
