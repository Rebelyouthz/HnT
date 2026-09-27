class_name NightStreet
extends Object


static func parallax(host: Node, map_w: float, theme: String = "dock") -> void:
	var pal := _theme_pal(theme)
	var pb := ParallaxBackground.new()
	pb.name = "Parallax"
	host.add_child(pb)
	var sky_l := ParallaxLayer.new()
	sky_l.motion_scale = Vector2(0.02, 0.02)
	pb.add_child(sky_l)
	Blockout.poly(sky_l, Rect2(-200, -40, map_w + 600.0, 280), pal["sky"], -9)
	if theme == "lot":
		_tile_fill(sky_l, Rect2(-200, -40, map_w + 600.0, 280), "sodium_tile", -8, Color(1.0, 0.62, 0.28, 0.32))
	elif theme == "roofs":
		_tile_fill(sky_l, Rect2(-200, -40, map_w + 600.0, 280), "brick", -8, Color(0.4, 0.32, 0.48, 0.22))
	var moon_l := ParallaxLayer.new()
	moon_l.motion_scale = Vector2(0.05, 0.04)
	pb.add_child(moon_l)
	var moon := Polygon2D.new()
	moon.color = pal["moon"]
	moon.polygon = PackedVector2Array([
		Vector2(980, 36), Vector2(1050, 36), Vector2(1050, 106), Vector2(980, 106)
	])
	Blockout.add_glow(moon)
	moon_l.add_child(moon)
	if theme == "pier" or theme == "lot":
		var moon2 := Polygon2D.new()
		moon2.color = pal["moon"].darkened(0.25)
		moon2.polygon = PackedVector2Array([
			Vector2(420, 50), Vector2(460, 50), Vector2(460, 88), Vector2(420, 88)
		])
		moon_l.add_child(moon2)
	var stars := ParallaxLayer.new()
	stars.motion_scale = Vector2(0.06, 0.03)
	pb.add_child(stars)
	for i in 18:
		Blockout.poly(stars, Rect2(80.0 + i * 90.0, 20 + (i % 5) * 14, 3, 3), Color(0.85, 0.88, 0.95, 0.45), -8)
	var fog := ParallaxLayer.new()
	fog.motion_scale = Vector2(0.08, 0.03)
	pb.add_child(fog)
	if theme == "lot":
		_tile_fill(fog, Rect2(-80, 70, map_w + 240.0, 180), "sodium_tile", -7, Color(0.85, 0.45, 0.15, 0.22))
	elif theme == "roofs":
		_tile_fill(fog, Rect2(-80, 70, map_w + 240.0, 180), "roof", -7, Color(0.55, 0.45, 0.5, 0.22))
	else:
		Blockout.poly(fog, Rect2(-80, 70, map_w + 240.0, 240), pal["fog"], -7)
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.16, 0.08)
	pb.add_child(far)
	if theme == "lot":
		_tile_fill(far, Rect2(0, 190, map_w, 200), "lot_roof", -6, Color(0.5, 0.35, 0.22, 0.9))
	elif theme == "roofs":
		_tile_fill(far, Rect2(0, 190, map_w, 200), "brick", -6, Color(0.42, 0.32, 0.38, 0.88))
	else:
		Blockout.poly(far, Rect2(0, 190, map_w, 420), pal["far"], -6)
	_skyline(far, map_w, pal["far_b"], theme)
	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.34, 0.12)
	pb.add_child(mid)
	Blockout.poly(mid, Rect2(0, 250, map_w, 380), pal["mid"], -4)
	_mid_props(mid, map_w, theme, pal)
	var near := ParallaxLayer.new()
	near.motion_scale = Vector2(0.55, 0.2)
	pb.add_child(near)
	_near_props(near, map_w, theme, pal)
	var hung := ParallaxLayer.new()
	hung.motion_scale = Vector2(0.78, 0.22)
	pb.add_child(hung)
	_hung_props(hung, map_w, theme, pal)
	var mist := ParallaxLayer.new()
	mist.motion_scale = Vector2(0.92, 0.18)
	pb.add_child(mist)
	Blockout.poly(mist, Rect2(-60, 480, map_w + 200.0, 80), pal["mist"], 4)
	var fg := ParallaxLayer.new()
	fg.motion_scale = Vector2(1.18, 0.42)
	pb.add_child(fg)
	Blockout.poly(fg, Rect2(-40, 620, 220, 44), pal["fg"], 13)
	Blockout.poly(fg, Rect2(map_w * 0.35, 628, 180, 32), pal["fg"], 13)
	Blockout.poly(fg, Rect2(map_w * 0.7, 622, 200, 36), pal["fg"], 13)
	if theme == "pier" or theme == "lot":
		Blockout.poly(fg, Rect2(80, 640, map_w, 30), pal["water"], 13)


static func _theme_pal(theme: String) -> Dictionary:
	match theme:
		"roofs":
			return {
				"sky": Color(0.05, 0.06, 0.11, 0.9), "moon": Color(0.86, 0.72, 0.48, 0.9),
				"fog": Color(0.22, 0.16, 0.14, 0.2), "far": Color(0.1, 0.08, 0.12),
				"far_b": Color(0.12, 0.09, 0.11), "mid": Color(0.18, 0.1, 0.1),
				"mist": Color(0.2, 0.12, 0.1, 0.16), "fg": Color(0.08, 0.06, 0.07, 0.7),
				"water": Color(0.08, 0.1, 0.12, 0.4)
			}
		"neon":
			return {
				"sky": Color(0.08, 0.04, 0.12, 0.92), "moon": Color(0.95, 0.4, 0.75, 0.8),
				"fog": Color(0.4, 0.12, 0.32, 0.16), "far": Color(0.12, 0.06, 0.16),
				"far_b": Color(0.18, 0.06, 0.14), "mid": Color(0.16, 0.07, 0.14),
				"mist": Color(0.35, 0.1, 0.28, 0.14), "fg": Color(0.1, 0.04, 0.1, 0.7),
				"water": Color(0.12, 0.06, 0.14, 0.4)
			}
		"rail":
			return {
				"sky": Color(0.05, 0.06, 0.08, 0.92), "moon": Color(0.7, 0.82, 0.9, 0.85),
				"fog": Color(0.16, 0.18, 0.2, 0.2), "far": Color(0.09, 0.1, 0.12),
				"far_b": Color(0.12, 0.12, 0.1), "mid": Color(0.14, 0.13, 0.11),
				"mist": Color(0.14, 0.16, 0.16, 0.16), "fg": Color(0.07, 0.07, 0.08, 0.7),
				"water": Color(0.08, 0.09, 0.1, 0.4)
			}
		"hall":
			return {
				"sky": Color(0.06, 0.06, 0.09, 0.92), "moon": Color(0.92, 0.86, 0.62, 0.88),
				"fog": Color(0.2, 0.18, 0.14, 0.18), "far": Color(0.12, 0.11, 0.1),
				"far_b": Color(0.16, 0.14, 0.1), "mid": Color(0.15, 0.13, 0.11),
				"mist": Color(0.18, 0.16, 0.12, 0.14), "fg": Color(0.08, 0.07, 0.06, 0.7),
				"water": Color(0.1, 0.09, 0.08, 0.4)
			}
		"pier":
			return {
				"sky": Color(0.04, 0.08, 0.07, 0.95), "moon": Color(0.55, 0.92, 0.62, 0.8),
				"fog": Color(0.12, 0.28, 0.22, 0.22), "far": Color(0.06, 0.12, 0.11),
				"far_b": Color(0.08, 0.16, 0.14), "mid": Color(0.08, 0.14, 0.12),
				"mist": Color(0.1, 0.22, 0.18, 0.22), "fg": Color(0.04, 0.08, 0.07, 0.75),
				"water": Color(0.08, 0.22, 0.2, 0.55)
			}
		"lot":
			return {
				"sky": Color(0.07, 0.05, 0.04, 0.94), "moon": Color(0.95, 0.62, 0.28, 0.85),
				"fog": Color(0.28, 0.16, 0.08, 0.18), "far": Color(0.12, 0.09, 0.07),
				"far_b": Color(0.16, 0.1, 0.06), "mid": Color(0.14, 0.1, 0.07),
				"mist": Color(0.22, 0.12, 0.06, 0.16), "fg": Color(0.08, 0.06, 0.04, 0.7),
				"water": Color(0.12, 0.1, 0.08, 0.45)
			}
		"circle":
			return {
				"sky": Color(0.07, 0.07, 0.1, 0.92), "moon": Color(0.92, 0.84, 0.55, 0.88),
				"fog": Color(0.18, 0.22, 0.16, 0.16), "far": Color(0.1, 0.13, 0.11),
				"far_b": Color(0.12, 0.16, 0.12), "mid": Color(0.13, 0.16, 0.12),
				"mist": Color(0.16, 0.2, 0.14, 0.14), "fg": Color(0.07, 0.09, 0.07, 0.7),
				"water": Color(0.12, 0.18, 0.16, 0.4)
			}
		"waiting":
			return {
				"sky": Color(0.1, 0.11, 0.12, 0.95), "moon": Color(0.85, 0.9, 0.92, 0.5),
				"fog": Color(0.22, 0.24, 0.24, 0.2), "far": Color(0.14, 0.15, 0.16),
				"far_b": Color(0.18, 0.19, 0.18), "mid": Color(0.16, 0.17, 0.18),
				"mist": Color(0.2, 0.22, 0.22, 0.12), "fg": Color(0.1, 0.1, 0.11, 0.7),
				"water": Color(0.12, 0.14, 0.14, 0.3)
			}
		"versus":
			return {
				"sky": Color(0.1, 0.04, 0.06, 0.95), "moon": Color(0.95, 0.3, 0.28, 0.85),
				"fog": Color(0.32, 0.08, 0.1, 0.18), "far": Color(0.12, 0.05, 0.08),
				"far_b": Color(0.18, 0.06, 0.08), "mid": Color(0.16, 0.06, 0.08),
				"mist": Color(0.28, 0.08, 0.1, 0.14), "fg": Color(0.08, 0.04, 0.05, 0.7),
				"water": Color(0.12, 0.05, 0.06, 0.4)
			}
		"tutorial":
			return {
				"sky": Color(0.06, 0.07, 0.11, 0.9), "moon": Color(0.8, 0.82, 0.9, 0.8),
				"fog": Color(0.18, 0.2, 0.26, 0.16), "far": Color(0.1, 0.11, 0.16),
				"far_b": Color(0.12, 0.12, 0.16), "mid": Color(0.14, 0.11, 0.13),
				"mist": Color(0.16, 0.18, 0.22, 0.14), "fg": Color(0.07, 0.07, 0.09, 0.7),
				"water": Color(0.1, 0.12, 0.14, 0.35)
			}
		"processing":
			return {
				"sky": Color(0.05, 0.04, 0.06, 0.96), "moon": Color(0.79, 0.64, 0.15, 0.75),
				"fog": Color(0.18, 0.12, 0.08, 0.22), "far": Color(0.1, 0.08, 0.09),
				"far_b": Color(0.16, 0.12, 0.08), "mid": Color(0.14, 0.1, 0.09),
				"mist": Color(0.2, 0.12, 0.08, 0.18), "fg": Color(0.06, 0.05, 0.05, 0.75),
				"water": Color(0.12, 0.08, 0.06, 0.4)
			}
		"farm":
			return {
				"sky": Color(0.08, 0.14, 0.18, 0.92), "moon": Color(0.95, 0.82, 0.4, 0.88),
				"fog": Color(0.18, 0.28, 0.16, 0.18), "far": Color(0.1, 0.16, 0.1),
				"far_b": Color(0.14, 0.22, 0.12), "mid": Color(0.16, 0.22, 0.12),
				"mist": Color(0.2, 0.28, 0.14, 0.16), "fg": Color(0.08, 0.12, 0.07, 0.7),
				"water": Color(0.12, 0.28, 0.24, 0.5)
			}
		"snow":
			return {
				"sky": Color(0.14, 0.18, 0.24, 0.94), "moon": Color(0.92, 0.95, 1.0, 0.9),
				"fog": Color(0.7, 0.78, 0.86, 0.22), "far": Color(0.42, 0.5, 0.58),
				"far_b": Color(0.5, 0.58, 0.66), "mid": Color(0.55, 0.62, 0.7),
				"mist": Color(0.78, 0.84, 0.9, 0.2), "fg": Color(0.62, 0.7, 0.78, 0.55),
				"water": Color(0.55, 0.7, 0.8, 0.5)
			}
		"cyber":
			return {
				"sky": Color(0.05, 0.02, 0.1, 0.96), "moon": Color(0.95, 0.3, 0.85, 0.8),
				"fog": Color(0.35, 0.08, 0.4, 0.2), "far": Color(0.08, 0.04, 0.16),
				"far_b": Color(0.14, 0.04, 0.22), "mid": Color(0.12, 0.06, 0.2),
				"mist": Color(0.4, 0.1, 0.45, 0.16), "fg": Color(0.06, 0.03, 0.1, 0.75),
				"water": Color(0.12, 0.06, 0.18, 0.45)
			}
		"vault":
			return {
				"sky": Color(0.03, 0.07, 0.08, 0.97), "moon": Color(0.45, 0.9, 0.7, 0.7),
				"fog": Color(0.08, 0.22, 0.2, 0.24), "far": Color(0.06, 0.12, 0.12),
				"far_b": Color(0.08, 0.18, 0.16), "mid": Color(0.07, 0.14, 0.13),
				"mist": Color(0.1, 0.24, 0.2, 0.22), "fg": Color(0.04, 0.08, 0.08, 0.75),
				"water": Color(0.08, 0.28, 0.24, 0.6)
			}
		_:
			return {
				"sky": Color(0.06, 0.07, 0.12, 0.9), "moon": Color(0.78, 0.82, 0.92, 0.85),
				"fog": Color(0.18, 0.2, 0.28, 0.18), "far": Color(0.11, 0.12, 0.18),
				"far_b": Color(0.09, 0.1, 0.16), "mid": Color(0.15, 0.1, 0.12),
				"mist": Color(0.16, 0.18, 0.24, 0.14), "fg": Color(0.08, 0.08, 0.1, 0.7),
				"water": Color(0.1, 0.12, 0.16, 0.4)
			}


static func _tile_fill(host: Node, rect: Rect2, kind: String, z: int, mod: Color = Color.WHITE) -> void:
	var t := SpriteBook.tile(kind)
	if t == null:
		Blockout.poly(host, rect, Color(0.12, 0.09, 0.07, 0.7), z)
		return
	var tw := float(t.get_width()) * SpriteBook.DRAW_SCALE
	var th := float(t.get_height()) * SpriteBook.DRAW_SCALE
	var y := rect.position.y
	while y < rect.end.y - 4.0:
		var x := rect.position.x
		while x < rect.end.x - 4.0:
			var s := Sprite2D.new()
			s.texture = t
			s.centered = false
			s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
			s.position = Vector2(x, y)
			s.z_index = z
			s.modulate = mod
			s.texture_filter = SpriteBook.world_filter()
			host.add_child(s)
			x += tw
		y += th


static func _skyline(far: Node, map_w: float, color: Color, theme: String) -> void:
	var i := 0
	var x := 80.0
	while x < map_w:
		var h := 160.0 + (i % 4) * 50.0
		if theme == "pier":
			Blockout.poly(far, Rect2(x, 80, 18, 340), color.lightened(0.05), -6)
			Blockout.poly(far, Rect2(x + 18, 140, 90, 16), color, -6)
		elif theme == "lot":
			var roof := SpriteBook.tile("lot_roof")
			if roof:
				var s := Sprite2D.new()
				s.texture = roof
				s.centered = false
				s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
				s.position = Vector2(x, 200)
				s.z_index = -6
				s.modulate = Color(0.62, 0.42, 0.28)
				s.texture_filter = SpriteBook.world_filter()
				far.add_child(s)
			else:
				Blockout.poly(far, Rect2(x, 200, 110, 140), color, -6)
		elif theme == "waiting":
			Blockout.poly(far, Rect2(x, 120, 70, 260), color, -6)
			Blockout.poly(far, Rect2(x + 12, 140, 14, 18), Color(0.9, 0.92, 0.7, 0.35), -5)
		elif theme == "processing":
			Blockout.poly(far, Rect2(x, 100, 50, 280), color, -6)
			Blockout.poly(far, Rect2(x + 8, 120, 18, 22), Color(0.79, 0.64, 0.15, 0.35), -5)
		elif theme == "rail":
			Blockout.poly(far, Rect2(x, 160, 140, 40), color, -6)
		elif theme == "farm":
			Blockout.poly(far, Rect2(x, 240, 18, 180), color, -6)
			Blockout.poly(far, Rect2(x + 18, 250, 70, 90), color.lightened(0.05), -6)
		elif theme == "snow":
			Blockout.poly(far, Rect2(x, 260, 90, 120), color, -6)
		elif theme == "cyber":
			Blockout.poly(far, Rect2(x, 80, 50, 320), color, -6)
			Blockout.poly(far, Rect2(x + 10, 100, 16, 22), Color(0.95, 0.3, 0.85, 0.45), -5)
		elif theme == "vault":
			Blockout.poly(far, Rect2(x, 140, 80, 260), color, -6)
			Blockout.poly(far, Rect2(x + 20, 170, 28, 40), Color(0.35, 0.85, 0.55, 0.3), -5)
		else:
			Blockout.poly(far, Rect2(x, 320.0 - h, 70 + (i % 3) * 20, h), color, -6)
		x += 160.0
		i += 1


static func _mid_props(mid: Node, map_w: float, theme: String, pal: Dictionary) -> void:
	match theme:
		"pier":
			Blockout.poly(mid, Rect2(200, 220, 14, 260), pal["far_b"], -4)
			Blockout.poly(mid, Rect2(200, 220, 180, 14), pal["far_b"], -4)
			Blockout.poly(mid, Rect2(900, 180, 16, 300), pal["far_b"], -4)
			Blockout.poly(mid, Rect2(900, 180, 220, 12), pal["far_b"], -4)
			Blockout.poly(mid, Rect2(0, 500, map_w, 80), pal["water"], -3)
		"lot":
			for i in 6:
				_tile_fill(mid, Rect2(120.0 + i * 180.0, 360, 90, 40), "lot_roof", -4, Color(0.7, 0.5, 0.35))
		"circle":
			Blockout.poly(mid, Rect2(map_w * 0.4, 300, 180, 80), Color(0.16, 0.2, 0.16), -4)
		"waiting":
			for i in 8:
				Blockout.poly(mid, Rect2(80.0 + i * 140.0, 340, 50, 70), Color(0.2, 0.2, 0.22), -4)
		"processing":
			for i in 7:
				Blockout.poly(mid, Rect2(90.0 + i * 160.0, 280, 40, 180), Color(0.22, 0.16, 0.12), -4)
				Blockout.poly(mid, Rect2(96.0 + i * 160.0, 300, 18, 14), Color(0.79, 0.64, 0.15, 0.4), -3)
		"hall":
			Blockout.poly(mid, Rect2(400, 180, 40, 200), Color(0.28, 0.22, 0.16, 0.55), -4)
		"farm":
			for i in 8:
				Blockout.poly(mid, Rect2(80.0 + i * 160.0, 300, 12, 80), Color(0.18, 0.28, 0.12), -4)
		"snow":
			for i in 7:
				Blockout.poly(mid, Rect2(100.0 + i * 150.0, 340, 70, 28), Color(0.82, 0.88, 0.92, 0.5), -4)
		"cyber":
			for i in 6:
				Blockout.poly(mid, Rect2(120.0 + i * 180.0, 200, 28, 220), Color(0.2, 0.08, 0.28), -4)
				Blockout.poly(mid, Rect2(128.0 + i * 180.0, 220, 12, 16), Color(0.3, 0.9, 0.95, 0.5), -3)
		"vault":
			Blockout.poly(mid, Rect2(0, 480, map_w, 90), pal["water"], -3)
			for i in 5:
				Blockout.poly(mid, Rect2(160.0 + i * 200.0, 220, 90, 18), Color(0.2, 0.32, 0.28), -4)
		_:
			Blockout.poly(mid, Rect2(400, 180, 40, 200), Color(0.22, 0.12, 0.12, 0.5), -4)


static func _near_props(near: Node, map_w: float, theme: String, pal: Dictionary) -> void:
	var cols: Array = [pal["mid"], pal["far_b"], pal["far"]]
	for i in 5:
		var x := 80.0 + i * (map_w / 5.0)
		Blockout.poly(near, Rect2(x, 280, 70 + (i % 3) * 12, 190), cols[i % 3], -2)
	if theme == "neon":
		Blockout.poly(near, Rect2(600, 240, 90, 18), Color(0.95, 0.3, 0.7, 0.7), -1)
		Blockout.poly(near, Rect2(1500, 220, 110, 18), Color(0.3, 0.85, 0.95, 0.7), -1)
	if theme == "pier":
		Blockout.poly(near, Rect2(40, 520, map_w, 40), Color(0.12, 0.1, 0.08, 0.8), -1)
	if theme == "farm":
		Blockout.poly(near, Rect2(200, 420, 180, 50), Color(0.28, 0.18, 0.1), -1)
	if theme == "cyber":
		Blockout.poly(near, Rect2(500, 220, 120, 16), Color(0.95, 0.3, 0.85, 0.7), -1)
		Blockout.poly(near, Rect2(1700, 200, 140, 16), Color(0.3, 0.9, 0.95, 0.7), -1)
	if theme == "vault":
		Blockout.poly(near, Rect2(40, 500, map_w, 50), Color(0.08, 0.2, 0.18, 0.7), -1)


static func _hung_props(hung: Node, map_w: float, theme: String, pal: Dictionary) -> void:
	var n := 5
	for i in n:
		var x := 160.0 + i * (map_w / float(n))
		var c := Color(0.28, 0.18, 0.14, 0.85)
		if theme == "neon":
			c = Color(0.9, 0.25, 0.55, 0.8) if i % 2 == 0 else Color(0.25, 0.8, 0.9, 0.8)
		elif theme == "pier":
			c = Color(0.18, 0.32, 0.24, 0.85)
		elif theme == "lot":
			c = Color(0.55, 0.32, 0.12, 0.8)
		elif theme == "farm":
			c = Color(0.32, 0.55, 0.18, 0.8)
		elif theme == "snow":
			c = Color(0.85, 0.9, 0.95, 0.7)
		elif theme == "cyber":
			c = Color(0.95, 0.25, 0.8, 0.85) if i % 2 == 0 else Color(0.25, 0.9, 0.95, 0.85)
		elif theme == "vault":
			c = Color(0.25, 0.55, 0.4, 0.8)
		Blockout.poly(hung, Rect2(x, 190 + (i % 3) * 8, 64, 16), c, -1)


static func section(host: Node, at: Vector2, kind: String) -> void:
	var label := "BRAWL"
	var color := Palette.BRICK
	match kind:
		"parkour":
			label = "PARKOUR"
			color = Palette.LEMON
		"gun":
			label = "GUN"
			color = Palette.EDGE
		_:
			label = "BRAWL"
			color = Palette.BRICK
	plaque(host, at, label, color, 16)


static func crane(host: Node, at: Vector2, h: float = 320.0) -> void:
	Blockout.solid(host, Rect2(at.x, at.y, 18, h), false)
	Blockout.poly(host, Rect2(at.x, at.y, 18, h), Color(0.28, 0.32, 0.22), 2)
	Blockout.solid(host, Rect2(at.x, at.y, 220, 16), true)
	Blockout.poly(host, Rect2(at.x, at.y, 220, 16), Color(0.32, 0.36, 0.24), 3)
	Blockout.occluder(host, Rect2(at.x, at.y, 18, h))
	anchor_if(host, Vector2(at.x + 110, at.y - 20))


static func anchor_if(host: Node, at: Vector2) -> void:
	if host.has_method("anchor"):
		host.anchor(at)
	else:
		var a := WebAnchor.new()
		a.position = at
		host.add_child(a)


static func chapel(host: Node, rect: Rect2) -> void:
	Blockout.poly(host, rect, Color(0.16, 0.18, 0.16), -1)
	Blockout.occluder(host, rect)
	var peak := Polygon2D.new()
	peak.color = Color(0.12, 0.14, 0.12)
	peak.polygon = PackedVector2Array([
		rect.position + Vector2(0, 40),
		rect.position + Vector2(rect.size.x * 0.5, -70),
		rect.position + Vector2(rect.size.x, 40)
	])
	host.add_child(peak)
	var door := Blockout.poly(host, Rect2(rect.position.x + rect.size.x * 0.4, rect.end.y - 90, 48, 90), Color(0.08, 0.07, 0.07), 1)
	door.z_index = 1
	var win := Blockout.poly(host, Rect2(rect.position.x + 36, rect.position.y + 50, 22, 48), Color(0.35, 0.85, 0.55, 0.55), 1)
	Blockout.add_glow(win)


static func car(host: Node, at: Vector2, color: Color, who: String = "sedan") -> void:
	Blockout.solid(host, Rect2(at.x, at.y - 36, 110, 22), true)
	Blockout.occluder(host, Rect2(at.x, at.y - 36, 110, 36))
	var n := Node2D.new()
	n.position = at + Vector2(55, 0)
	n.z_index = 2
	host.add_child(n)
	if SpriteBook.attach_scaled(n, who, -8.0, Vector2(1.35, 1.05)):
		return
	Blockout.poly(host, Rect2(at.x, at.y - 36, 110, 36), color, 2)
	Blockout.poly(host, Rect2(at.x + 18, at.y - 58, 70, 24), color.darkened(0.15), 2)


static func water_band(host: Node, map_w: float, y: float = 560.0, tile_kind: String = "") -> void:
	if tile_kind != "":
		var t := SpriteBook.tile(tile_kind)
		if t:
			var tw := float(t.get_width()) * SpriteBook.DRAW_SCALE
			var x := 0.0
			while x < map_w:
				var s := Sprite2D.new()
				s.texture = t
				s.centered = false
				s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
				s.position = Vector2(x, y)
				s.z_index = 1
				s.texture_filter = SpriteBook.world_filter()
				host.add_child(s)
				x += tw
			return
	var w := Blockout.poly(host, Rect2(0, y, map_w, 160), Color(0.07, 0.16, 0.15, 0.85), 1)
	w.z_index = 1
	Blockout.poly(host, Rect2(0, y, map_w, 18), Color(0.18, 0.32, 0.28, 0.55), 2)


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
	var mist := GPUParticles2D.new()
	mist.position = Vector2(cx, 180)
	var mm := ParticleProcessMaterial.new()
	mm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mm.emission_box_extents = Vector3(maxi(int(cx), 900), 40, 1)
	mm.direction = Vector3(0.6, 0.05, 0)
	mm.spread = 20.0
	mm.gravity = Vector3(0, -4, 0)
	mm.initial_velocity_min = 6.0
	mm.initial_velocity_max = 16.0
	mm.color = Color(0.45, 0.5, 0.6, 0.12)
	mist.process_material = mm
	mist.amount = 18
	mist.lifetime = 3.2
	mist.z_index = 5
	host.add_child(mist)


static func wind(host: Node, cx: float) -> void:
	var p := GPUParticles2D.new()
	p.position = Vector2(cx, 120)
	p.z_index = 6
	p.amount = 22
	p.lifetime = 2.8
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(maxi(int(cx), 700), 80, 1)
	mat.direction = Vector3(1, 0.08, 0)
	mat.spread = 12.0
	mat.gravity = Vector3(0, -10, 0)
	mat.initial_velocity_min = 18.0
	mat.initial_velocity_max = 48.0
	mat.color = Color(0.78, 0.84, 0.9, 0.16)
	p.process_material = mat
	host.add_child(p)


static func wet_floor(host: Node, map_w: float, skip_fill: bool = false) -> void:
	if not skip_fill:
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


static func barn(host: Node, rect: Rect2) -> void:
	Blockout.poly(host, rect, Color(0.42, 0.18, 0.12), 1)
	Blockout.occluder(host, rect)
	var roof := Polygon2D.new()
	roof.color = Color(0.28, 0.12, 0.1)
	roof.polygon = PackedVector2Array([
		rect.position + Vector2(-20, 50),
		rect.position + Vector2(rect.size.x * 0.5, -60),
		rect.position + Vector2(rect.size.x + 20, 50)
	])
	host.add_child(roof)
	Blockout.poly(host, Rect2(rect.position.x + rect.size.x * 0.4, rect.end.y - 80, 44, 80), Color(0.12, 0.08, 0.06), 2)


static func silo(host: Node, at: Vector2) -> void:
	Blockout.poly(host, Rect2(at.x, at.y, 70, 380), Color(0.55, 0.52, 0.48), 1)
	Blockout.poly(host, Rect2(at.x - 8, at.y - 24, 86, 28), Color(0.4, 0.38, 0.34), 2)
	Blockout.occluder(host, Rect2(at.x, at.y, 70, 380))
	anchor_if(host, Vector2(at.x + 35, at.y - 10))


static func underpass(host: Node, at: Vector2, w: float = 400.0) -> void:
	Blockout.poly(host, Rect2(at.x, at.y, w, 18), Color(0.18, 0.16, 0.2), 2)
	Blockout.solid(host, Rect2(at.x, at.y, w, 18), true)
	Blockout.poly(host, Rect2(at.x, at.y + 18, 22, 160), Color(0.12, 0.11, 0.14), 1)
	Blockout.poly(host, Rect2(at.x + w - 22, at.y + 18, 22, 160), Color(0.12, 0.11, 0.14), 1)
	Blockout.poly(host, Rect2(at.x + 22, at.y + 18, w - 44, 140), Color(0.06, 0.06, 0.08, 0.85), 1)
	plaque(host, at + Vector2(24, -24), "UNDERPASS  ·  DROP AHEAD", Palette.MUTED, 12)


static func ramp(host: Node, at: Vector2) -> void:
	var p := Polygon2D.new()
	p.color = Color(0.32, 0.16, 0.38)
	p.position = at
	p.polygon = PackedVector2Array([
		Vector2(0, 48), Vector2(210, -96), Vector2(248, -96), Vector2(248, 48)
	])
	p.z_index = 2
	host.add_child(p)
	Blockout.add_glow(p)
	plaque(host, at + Vector2(8, -128), "RAMP  ·  DO NOT BRAKE", Palette.LEMON, 13)


static func canal(host: Node, x: float, w: float, y: float = 520.0) -> void:
	var water := Blockout.poly(host, Rect2(x, y, w, 200), Color(0.05, 0.14, 0.18, 0.92), 1)
	water.z_index = 1
	Blockout.poly(host, Rect2(x, y, w, 16), Color(0.22, 0.55, 0.5, 0.55), 2)
	Blockout.poly(host, Rect2(x - 18, 430, 22, 90), Color(0.16, 0.12, 0.1), 2)
	Blockout.poly(host, Rect2(x + w - 4, 430, 22, 90), Color(0.16, 0.12, 0.1), 2)
	plaque(host, Vector2(x + 24, y - 48), "CANAL  ·  THEY DON'T FOLLOW", Palette.EDGE, 13)


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


static func pixel_tenement(host: Node, rect: Rect2) -> void:
	var brick := SpriteBook.tile("brick")
	var win := SpriteBook.tile("brick_window")
	if brick == null:
		return
	var tw := float(brick.get_width()) * SpriteBook.DRAW_SCALE
	var th := float(brick.get_height()) * SpriteBook.DRAW_SCALE
	var y := rect.position.y
	var row := 0
	while y < rect.end.y - 8.0:
		var x := rect.position.x
		var col := 0
		while x < rect.end.x - 8.0:
			var s := Sprite2D.new()
			s.texture = win if win != null and row % 2 == 0 and col % 2 == 1 else brick
			s.centered = false
			s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
			s.position = Vector2(x, y)
			s.z_index = 0
			s.texture_filter = SpriteBook.world_filter()
			host.add_child(s)
			x += tw
			col += 1
		y += th
		row += 1


static func pixel_dock(host: Node, map_w: float) -> void:
	var cobble := SpriteBook.tile("cobble")
	var wet := SpriteBook.tile("cobble_wet")
	var plank := SpriteBook.tile("plank")
	var water := SpriteBook.tile("water")
	if cobble == null:
		return
	var tw := float(cobble.get_width()) * SpriteBook.DRAW_SCALE
	var th := float(cobble.get_height()) * SpriteBook.DRAW_SCALE
	var x := 0.0
	var n := 0
	while x < map_w:
		var s := Sprite2D.new()
		s.texture = wet if wet != null and n % 4 == 2 else cobble
		s.centered = false
		s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		s.position = Vector2(x, 430.0)
		s.z_index = 0
		s.texture_filter = SpriteBook.world_filter()
		host.add_child(s)
		var s2 := Sprite2D.new()
		s2.texture = cobble
		s2.centered = false
		s2.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		s2.position = Vector2(x, 430.0 + th)
		s2.z_index = 0
		s2.texture_filter = SpriteBook.world_filter()
		host.add_child(s2)
		x += tw
		n += 1
	if water:
		x = 0.0
		var ww := float(water.get_width()) * SpriteBook.DRAW_SCALE
		while x < 300.0:
			var w := Sprite2D.new()
			w.texture = water
			w.centered = false
			w.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
			w.position = Vector2(x, 560.0)
			w.z_index = 1
			w.texture_filter = SpriteBook.world_filter()
			host.add_child(w)
			x += ww
		if plank:
			x = 0.0
			var pw := float(plank.get_width()) * SpriteBook.DRAW_SCALE
			while x < 300.0:
				var p := Sprite2D.new()
				p.texture = plank
				p.centered = false
				p.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
				p.position = Vector2(x, 500.0)
				p.z_index = 1
				p.texture_filter = SpriteBook.world_filter()
				host.add_child(p)
				x += pw
	for lx in [420.0, 900.0, 1480.0, 2100.0, 2680.0]:
		AmbientProp.lamp(host, Vector2(lx, 500.0), 3)


static func pixel_roof(host: Node, rect: Rect2, kind: String = "roof") -> void:
	var roof := SpriteBook.tile(kind)
	if roof == null and kind != "roof":
		roof = SpriteBook.tile("roof")
	if roof == null:
		Blockout.poly(host, rect, Color(0.22, 0.18, 0.2), 2)
		return
	var tw := float(roof.get_width()) * SpriteBook.DRAW_SCALE
	var x := rect.position.x
	while x < rect.end.x - 2.0:
		var s := Sprite2D.new()
		s.texture = roof
		s.centered = false
		s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		s.position = Vector2(x, rect.position.y)
		s.z_index = 2
		s.texture_filter = SpriteBook.world_filter()
		host.add_child(s)
		x += tw


static func pixel_lot(host: Node, map_w: float) -> void:
	var asphalt := SpriteBook.tile("asphalt")
	var wet := SpriteBook.tile("asphalt_wet")
	if asphalt == null:
		return
	var tw := float(asphalt.get_width()) * SpriteBook.DRAW_SCALE
	var th := float(asphalt.get_height()) * SpriteBook.DRAW_SCALE
	var x := 0.0
	var n := 0
	while x < map_w:
		var s := Sprite2D.new()
		s.texture = wet if wet != null and n % 5 == 2 else asphalt
		s.centered = false
		s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		s.position = Vector2(x, 430.0)
		s.z_index = 0
		s.texture_filter = SpriteBook.world_filter()
		host.add_child(s)
		var s2 := Sprite2D.new()
		s2.texture = asphalt
		s2.centered = false
		s2.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		s2.position = Vector2(x, 430.0 + th)
		s2.z_index = 0
		s2.texture_filter = SpriteBook.world_filter()
		host.add_child(s2)
		x += tw
		n += 1
	var stall := SpriteBook.tile("stall")
	if stall:
		for i in 7:
			var st := Sprite2D.new()
			st.texture = stall
			st.centered = false
			st.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
			st.position = Vector2(80.0 + float(i) * 260.0, 470.0)
			st.z_index = 1
			st.texture_filter = SpriteBook.world_filter()
			host.add_child(st)
	for lx in [200.0, 700.0, 1100.0, 1500.0, 1880.0]:
		AmbientProp.place(host, "sodium_lamp", Vector2(lx, 500.0), 3)
	AmbientProp.place(host, "ticket_booth", Vector2(120.0, 500.0), 3)
	AmbientProp.place(host, "cone", Vector2(500.0, 500.0), 3)
	AmbientProp.place(host, "cone", Vector2(1040.0, 500.0), 3)
	AmbientProp.place(host, "barrier", Vector2(1480.0, 500.0), 3)
	AmbientProp.place(host, "drum", Vector2(900.0, 500.0), 3)
	AmbientProp.place(host, "fence", Vector2(48.0, 500.0), 3)
