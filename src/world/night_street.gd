class_name NightStreet
extends Object


static func parallax(host: Node, map_w: float) -> void:
	var pb := ParallaxBackground.new()
	host.add_child(pb)
	var moon_l := ParallaxLayer.new()
	moon_l.motion_scale = Vector2(0.05, 0.04)
	pb.add_child(moon_l)
	var moon := Polygon2D.new()
	moon.color = Color(0.78, 0.82, 0.92, 0.85)
	moon.polygon = PackedVector2Array([
		Vector2(980, 40), Vector2(1040, 40), Vector2(1040, 100), Vector2(980, 100)
	])
	moon_l.add_child(moon)
	var fog := ParallaxLayer.new()
	fog.motion_scale = Vector2(0.07, 0.03)
	pb.add_child(fog)
	Blockout.poly(fog, Rect2(-80, 80, map_w + 200.0, 220), Color(0.18, 0.2, 0.28, 0.18), -7)
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.15, 0.08)
	pb.add_child(far)
	Blockout.poly(far, Rect2(0, 200, map_w, 400), Color(0.11, 0.12, 0.18), -6)
	Blockout.poly(far, Rect2(240, 120, 90, 280), Color(0.09, 0.1, 0.16), -6)
	Blockout.poly(far, Rect2(920, 90, 120, 320), Color(0.1, 0.11, 0.17), -6)
	Blockout.poly(far, Rect2(1680, 110, 80, 300), Color(0.08, 0.1, 0.15), -6)
	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.35, 0.12)
	pb.add_child(mid)
	Blockout.poly(mid, Rect2(0, 260, map_w, 360), Color(0.15, 0.1, 0.12), -4)
	Blockout.poly(mid, Rect2(400, 180, 40, 200), Color(0.22, 0.12, 0.12, 0.5), -4)
	var near := ParallaxLayer.new()
	near.motion_scale = Vector2(0.55, 0.2)
	pb.add_child(near)
	Blockout.poly(near, Rect2(120, 300, 80, 180), Color(0.2, 0.12, 0.12), -2)
	Blockout.poly(near, Rect2(980, 280, 70, 200), Color(0.18, 0.11, 0.13), -2)
	Blockout.poly(near, Rect2(2100, 290, 90, 190), Color(0.16, 0.12, 0.14), -2)
	Blockout.poly(near, Rect2(1480, 270, 24, 220), Color(0.12, 0.1, 0.1), -2)
	var hung := ParallaxLayer.new()
	hung.motion_scale = Vector2(0.78, 0.22)
	pb.add_child(hung)
	Blockout.poly(hung, Rect2(180, 210, 70, 18), Color(0.28, 0.18, 0.14, 0.85), -1)
	Blockout.poly(hung, Rect2(860, 190, 54, 16), Color(0.2, 0.16, 0.18, 0.8), -1)
	Blockout.poly(hung, Rect2(1720, 200, 80, 20), Color(0.32, 0.2, 0.14, 0.82), -1)
	Blockout.poly(hung, Rect2(2480, 185, 48, 14), Color(0.18, 0.2, 0.22, 0.75), -1)
	var fg := ParallaxLayer.new()
	fg.motion_scale = Vector2(1.15, 0.4)
	pb.add_child(fg)
	Blockout.poly(fg, Rect2(-40, 620, 200, 40), Color(0.08, 0.08, 0.1, 0.7), 13)
	Blockout.poly(fg, Rect2(700, 630, 160, 30), Color(0.09, 0.08, 0.11, 0.65), 13)
	Blockout.poly(fg, Rect2(1600, 625, 180, 28), Color(0.07, 0.07, 0.09, 0.6), 13)


static func tenement(host: Node, rect: Rect2, color: Color) -> void:
	Blockout.poly(host, rect, color, -1)
	Blockout.occluder(host, rect)
	var win_y := rect.position.y + 24.0
	while win_y < rect.end.y - 40.0:
		var win_x := rect.position.x + 18.0
		while win_x < rect.end.x - 24.0:
			var lit := randf() > 0.45
			var w := Blockout.poly(host, Rect2(win_x, win_y, 14, 16), Color(0.9, 0.75, 0.35, 0.7) if lit else Color(0.08, 0.08, 0.1, 0.9), 0)
			if lit:
				Blockout.add_glow(w)
			win_x += 36.0
		win_y += 36.0


static func rain(host: Node, cx: float) -> void:
	var rain := GPUParticles2D.new()
	rain.position = Vector2(cx, -20)
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(maxi(int(cx), 900), 8, 1)
	mat.direction = Vector3(0.12, 1, 0)
	mat.spread = 4.0
	mat.gravity = Vector3(0, 980, 0)
	mat.initial_velocity_min = 220.0
	mat.initial_velocity_max = 320.0
	mat.color = Color(0.55, 0.62, 0.75, 0.35)
	rain.process_material = mat
	rain.amount = 88
	rain.lifetime = 1.35
	rain.z_index = 12
	host.add_child(rain)
	var dust := GPUParticles2D.new()
	dust.position = Vector2(cx, 540)
	var dm := ParticleProcessMaterial.new()
	dm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dm.emission_box_extents = Vector3(maxi(int(cx), 900), 6, 1)
	dm.direction = Vector3(0.4, -0.1, 0)
	dm.spread = 30.0
	dm.gravity = Vector3(0, -8, 0)
	dm.initial_velocity_min = 8.0
	dm.initial_velocity_max = 22.0
	dm.color = Color(0.3, 0.32, 0.4, 0.18)
	dust.process_material = dm
	dust.amount = 24
	dust.lifetime = 2.4
	dust.z_index = 11
	host.add_child(dust)


static func wet_floor(host: Node, map_w: float) -> void:
	Blockout.poly(host, Rect2(0, 430, map_w, 290), Color(0.10, 0.10, 0.12), 0)
	var wet := Blockout.poly(host, Rect2(0, 520, map_w, 90), Color(0.18, 0.2, 0.28, 0.38), 1)
	wet.z_index = 1
	wet.uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = preload("res://src/shaders/wet_asphalt.gdshader")
	wet.material = wet_mat


static func bounds(host: Node, map_w: float) -> void:
	var floor := Blockout.solid(host, Rect2(-40, 600, map_w + 200.0, 80), false)
	floor.collision_layer = 1
	var wall_l := Blockout.solid(host, Rect2(-40, 0, 40, 720), false)
	var wall_r := Blockout.solid(host, Rect2(map_w, 0, 40, 720), false)
	wall_l.collision_layer = 1
	wall_r.collision_layer = 1


static func plaque(host: Node, at: Vector2, text: String, color: Color, size: int = 16) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.position = at
	UiKit.apply_label(lab, size, color)
	host.add_child(lab)
	return lab


static func neon(host: Node, at: Vector2, text: String, color: Color = Palette.BRICK) -> Label:
	var lab := plaque(host, at, text, color, 18)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/shaders/neon_flicker.gdshader")
	mat.set_shader_parameter("neon", color)
	lab.material = mat
	return lab


static func boxcar(host: Node, rect: Rect2) -> void:
	Blockout.solid(host, Rect2(rect.position.x, rect.position.y, rect.size.x, 22), true)
	Blockout.poly(host, rect, Color(0.18, 0.16, 0.14), 1)
	Blockout.poly(host, Rect2(rect.position.x + 10, rect.position.y + 18, 40, 22), Color(0.08, 0.08, 0.09), 1)
	Blockout.poly(host, Rect2(rect.end.x - 50, rect.position.y + 18, 40, 22), Color(0.08, 0.08, 0.09), 1)
	Blockout.occluder(host, rect)


static func statue(host: Node, top: Vector2, top_y: float) -> void:
	Blockout.solid(host, Rect2(top.x - 40, top_y, 80, 22), true)
	Blockout.poly(host, Rect2(top.x - 28, 320, 56, 280), Color(0.22, 0.2, 0.18), 1)
	Blockout.poly(host, Rect2(top.x - 40, top_y, 80, 22), Color(0.28, 0.24, 0.2), 2)
	Blockout.occluder(host, Rect2(top.x - 28, 320, 56, 280))


static func heli(host: Node, map_w: float) -> Node2D:
	var n := HeliSweep.new()
	n.map_w = map_w
	n.name = "HeliSweep"
	var glow := Polygon2D.new()
	glow.color = Color(0.95, 0.92, 0.55, 0.28)
	glow.polygon = PackedVector2Array([
		Vector2(-40, -20), Vector2(40, -20), Vector2(180, 520), Vector2(-180, 520)
	])
	Blockout.add_glow(glow)
	n.add_child(glow)
	host.add_child(n)
	return n
