extends RunAct

const ROOF_Y := 248.0


func _configure() -> void:
	map_id = "dock_street"
	map_w = 3200.0
	spawn_at = Vector2(220, 490)
	goal_x = 3000.0
	check_x = 2920.0
	check_pos = Vector2(2920, 490)
	next_id = "intake_lot"
	light_preset = "dock_street"
	toast_title = "DOCK STREET"
	clear_title = Copy.CLEAR
	clear_sub = Copy.CLEAR_SUB
	next_label = Copy.NEXT_LOT
	gate_sub = Copy.GATE_LOT
	win_mode = "boss"


func build_world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.07, 0.08, 0.13), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "dock")
	NightStreet.wet_floor(self, map_w, true)
	for r in [
		Rect2(80, 160, 220, 280),
		Rect2(420, 90, 260, 160),
		Rect2(860, 70, 300, 180),
		Rect2(1480, 60, 340, 190),
		Rect2(2480, 80, 280, 170),
		Rect2(2920, 140, 220, 290)
	]:
		Blockout.occluder(self, r)
		NightStreet.pixel_tenement(self, r)
	NightStreet.pixel_dock(self, map_w)
	Blockout.solid(self, Rect2(400, ROOF_Y, 840, 22), true)
	NightStreet.pixel_roof(self, Rect2(400, ROOF_Y, 840, 22))
	Blockout.solid(self, Rect2(1420, ROOF_Y, 580, 22), true)
	NightStreet.pixel_roof(self, Rect2(1420, ROOF_Y, 580, 22))
	Blockout.solid(self, Rect2(2480, ROOF_Y, 440, 22), true)
	NightStreet.pixel_roof(self, Rect2(2480, ROOF_Y, 440, 22))
	var wall := Blockout.solid(self, Rect2(1234, 140, 18, 110), false)
	wall.add_to_group("metal")
	NightStreet.pixel_tenement(self, Rect2(1230, 140, 32, 110))
	fire_escape(480.0)
	fire_escape(1920.0)
	fire_escape(2520.0)
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(640, 500)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(2320, 500)
	add_child(c2)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1760, 248)
	add_child(pistol)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(2100, 500)
	add_child(board)
	anchor(Vector2(640, 88))
	anchor(Vector2(1320, 64))
	anchor(Vector2(1760, 84))
	anchor(Vector2(2680, 90))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(140, 150), "DOCK STREET  ·  RAVEN WHARF", Palette.EDGE, 22)
	NightStreet.section(self, Vector2(420, 180), "parkour")
	NightStreet.section(self, Vector2(1680, 180), "gun")
	NightStreet.section(self, Vector2(2140, 180), "brawl")
	NightStreet.neon(self, Vector2(900, 178), "HIRING  ·  WE LIE ABOUT THAT", Palette.BRICK)
	NightStreet.plaque(self, Vector2(2940, 168), "24/7 BLOOD MART", Palette.READY, 20)
	NightStreet.plaque(self, Vector2(1258, 210), "GAP  ·  GLIDE OR WEB", Palette.MUTED, 14)
	NightStreet.rain(self, 1600.0)
	var mart := BloodMart.new()
	mart.global_position = Vector2(3040, 490)
	add_child(mart)
