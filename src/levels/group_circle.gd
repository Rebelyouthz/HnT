extends SurviveAct


func _configure() -> void:
	map_id = "group_circle"
	map_w = 1900.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	next_id = "neon_exchange"
	light_preset = "group_circle"
	toast_title = "GROUP CIRCLE"
	toast_body = "Share. Don't share. The courtyard still bites."
	clear_title = Copy.CIRCLE_CLEAR
	clear_sub = Copy.CIRCLE_SUB
	next_label = Copy.NEXT_NEON
	gate_sub = Copy.GATE_NEON
	win_mode = "boss"
	duration = 88.0


func build_world() -> void:
	NightStreet.parallax(self, map_w, "circle")
	# Painted sections (backdrops/circle_strip) replace the blockout
	# buildings; the painted wet street is the floor.
	if NightStreet.has_backdrop("circle") and WetStreet.available():
		WetStreet.lay(self, map_w)
	else:
		NightStreet.wet_floor(self, map_w)
		NightStreet.tenement(self, Rect2(40, 40, 220, 200), Color(0.14, 0.16, 0.12))
		NightStreet.tenement(self, Rect2(1600, 30, 240, 210), Color(0.12, 0.14, 0.12))
	Blockout.poly(self, Rect2(620, 430, 280, 90), Color(0.18, 0.24, 0.16, 0.55), 1)
	Blockout.poly(self, Rect2(720, 400, 80, 24), Color(0.35, 0.55, 0.7, 0.5), 2)
	for i in 5:
		var a := float(i) / 5.0 * TAU
		var px := 760.0 + cos(a) * 160.0
		var py := 460.0 + sin(a) * 40.0
		Blockout.poly(self, Rect2(px, py, 36, 18), Color(0.28, 0.22, 0.16), 2)
	Blockout.solid(self, Rect2(200, 248, 260, 18), true)
	Blockout.poly(self, Rect2(200, 248, 260, 18), Color(0.2, 0.24, 0.18), 2)
	Blockout.solid(self, Rect2(1180, 228, 300, 18), true)
	Blockout.poly(self, Rect2(1180, 228, 300, 18), Color(0.22, 0.2, 0.16), 2)
	fire_escape(240.0, 248.0)
	fire_escape(1240.0, 228.0)
	var crate := VaultCrate.new()
	crate.global_position = Vector2(980, 500)
	add_child(crate)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(1320, 228)
	add_child(board)
	anchor(Vector2(280, 50))
	anchor(Vector2(1320, 40))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(60, 110), "GROUP CIRCLE  ·  PASS OR BLEED", Palette.EDGE, 20)
	NightStreet.section(self, Vector2(200, 150), "parkour")
	NightStreet.section(self, Vector2(1180, 150), "gun")
	NightStreet.section(self, Vector2(620, 150), "brawl")
	NightStreet.rain(self, 950.0)
