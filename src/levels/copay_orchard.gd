extends RunAct

## Lake, forest, fields, farms. The wellness weekend they never booked.


func _configure() -> void:
	map_id = "copay_orchard"
	map_w = 3600.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	next_id = "sleet_hour"
	check_x = 2400.0
	check_pos = Vector2(2400, 490)
	light_preset = "copay_orchard"
	toast_title = "COPAY ORCHARD"
	toast_body = "Fields. Forest. A lake that still wants a copay. Slide the hill. Rope the silo."
	clear_title = Copy.ORCHARD_CLEAR
	clear_sub = Copy.ORCHARD_SUB
	next_label = Copy.NEXT_SLEET
	gate_sub = Copy.GATE_SLEET
	win_mode = "boss"


func build_world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.08, 0.12, 0.1), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "farm")
	Blockout.poly(self, Rect2(0, 430, map_w, 290), Color(0.16, 0.2, 0.1), 0)
	Blockout.poly(self, Rect2(0, 500, 900, 70), Color(0.12, 0.22, 0.18, 0.55), 1)
	NightStreet.water_band(self, 920.0, 548.0)
	NightStreet.barn(self, Rect2(1180, 140, 280, 360))
	NightStreet.silo(self, Vector2(1680, 80))
	NightStreet.tenement(self, Rect2(40, 80, 200, 240), Color(0.22, 0.16, 0.1))
	NightStreet.tenement(self, Rect2(2200, 60, 260, 220), Color(0.14, 0.2, 0.12))
	NightStreet.tenement(self, Rect2(3100, 50, 280, 230), Color(0.18, 0.14, 0.1))
	Blockout.solid(self, Rect2(420, 248, 420, 18), true)
	Blockout.poly(self, Rect2(420, 248, 420, 18), Color(0.28, 0.22, 0.12), 2)
	Blockout.solid(self, Rect2(1680, 200, 240, 18), true)
	Blockout.poly(self, Rect2(1680, 200, 240, 18), Color(0.3, 0.24, 0.14), 2)
	Blockout.solid(self, Rect2(2480, 248, 380, 18), true)
	Blockout.poly(self, Rect2(2480, 248, 380, 18), Color(0.26, 0.2, 0.12), 2)
	fire_escape(480.0, 248.0)
	fire_escape(1760.0, 200.0)
	fire_escape(2560.0, 248.0)
	ParkourToy.place(self, Vector2(720, 500), "hill")
	ParkourToy.place(self, Vector2(1520, 500), "rope")
	ParkourToy.place(self, Vector2(2100, 500), "pad")
	ParkourToy.place(self, Vector2(2880, 500), "escape")
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(980, 500)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(2680, 500)
	add_child(c2)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(1760, 200)
	add_child(board)
	var knife := WeaponPickup.new()
	knife.kind = "knife"
	knife.global_position = Vector2(640, 500)
	add_child(knife)
	anchor(Vector2(520, 60))
	anchor(Vector2(1760, 40))
	anchor(Vector2(2680, 50))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(40, 110), "COPAY ORCHARD  ·  WELLNESS THEY BILLED", Palette.EDGE, 22)
	NightStreet.section(self, Vector2(420, 160), "parkour")
	NightStreet.section(self, Vector2(1680, 140), "gun")
	NightStreet.section(self, Vector2(2480, 160), "brawl")
	NightStreet.plaque(self, Vector2(640, 200), "SLIDE HILL  ·  THE LAKE STILL WANTS A COPAY", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(1520, 140), "SILO ROPE  ·  SWING AND LAND", Palette.LEMON, 13)
	var crowd := Bystander.new()
	crowd.global_position = Vector2(1100, 500)
	add_child(crowd)
	NightStreet.rain(self, 1800.0)
	var shuttle := WellnessShuttle.new()
	shuttle.global_position = Vector2(3320, 490)
	add_child(shuttle)
