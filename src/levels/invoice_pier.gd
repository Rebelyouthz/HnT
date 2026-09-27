extends RunAct

## Flooded annex. Not Dock Street with a cold. Cranes, boardwalk, chapel.


func _configure() -> void:
	map_id = "invoice_pier"
	map_w = 3400.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	next_id = "processing_floor"
	check_x = 2500.0
	check_pos = Vector2(2500, 490)
	light_preset = "invoice_pier"
	toast_title = "INVOICE PIER"
	toast_body = "The annex. Cranes. Chapel. Dr. Splint has the original invoice."
	clear_title = Copy.PIER_CLEAR
	clear_sub = Copy.PIER_SUB
	next_label = Copy.NEXT_FLOOR
	gate_sub = Copy.GATE_FLOOR
	win_mode = "boss"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "pier")
	NightStreet.water_band(self, map_w, 560.0)
	Blockout.poly(self, Rect2(0, 500, map_w, 28), Color(0.22, 0.18, 0.12), 1)
	Blockout.solid(self, Rect2(0, 492, 620, 18), true)
	Blockout.poly(self, Rect2(0, 492, 620, 18), Color(0.28, 0.22, 0.14), 2)
	Blockout.solid(self, Rect2(780, 248, 360, 18), true)
	Blockout.poly(self, Rect2(780, 248, 360, 18), Color(0.3, 0.28, 0.16), 2)
	Blockout.solid(self, Rect2(1280, 492, 520, 18), true)
	Blockout.poly(self, Rect2(1280, 492, 520, 18), Color(0.26, 0.2, 0.12), 2)
	Blockout.solid(self, Rect2(1980, 220, 280, 18), true)
	Blockout.poly(self, Rect2(1980, 220, 280, 18), Color(0.24, 0.3, 0.2), 2)
	Blockout.solid(self, Rect2(2420, 492, 980, 18), true)
	Blockout.poly(self, Rect2(2420, 492, 980, 18), Color(0.22, 0.18, 0.12), 2)
	NightStreet.crane(self, Vector2(860, 80), 340.0)
	NightStreet.crane(self, Vector2(2040, 40), 380.0)
	NightStreet.chapel(self, Rect2(2680, 160, 420, 340))
	fire_escape(860.0, 248.0)
	fire_escape(2040.0, 220.0)
	fire_escape(2760.0, 492.0)
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(1480, 490)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(2860, 490)
	add_child(c2)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(2100, 220)
	add_child(pistol)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(1520, 490)
	add_child(board)
	anchor(Vector2(400, 80))
	anchor(Vector2(1480, 70))
	anchor(Vector2(2580, 50))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(60, 120), "INVOICE PIER  ·  THE ANNEX", Palette.READY, 22)
	NightStreet.section(self, Vector2(80, 170), "brawl")
	NightStreet.section(self, Vector2(780, 170), "parkour")
	NightStreet.section(self, Vector2(1980, 150), "gun")
	NightStreet.plaque(self, Vector2(640, 210), "GAP  ·  THE WATER BILLS LATE FEES", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(2680, 120), "CHAPEL OF COPAY", Palette.EDGE, 16)
	NightStreet.rain(self, 1700.0)
