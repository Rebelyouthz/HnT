extends RunAct

const ROOF_Y := 248.0


func _configure() -> void:
	map_id = "neon_exchange"
	map_w = 3000.0
	spawn_at = Vector2(200, 490)
	goal_x = 2780.0
	check_x = 2600.0
	check_pos = Vector2(2600, 490)
	next_id = "waiting_room"
	light_preset = "neon_exchange"
	toast_title = "NEON EXCHANGE"
	toast_body = "Agents. Police. Mini with a badge. Pawn at the end."
	clear_title = Copy.NEON_CLEAR
	clear_sub = Copy.NEON_SUB
	next_label = Copy.NEXT_WAIT
	gate_sub = Copy.GATE_WAIT
	win_mode = "boss"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "neon")
	NightStreet.wet_floor(self, map_w)
	NightStreet.tenement(self, Rect2(60, 80, 240, 240), Color(0.18, 0.08, 0.16))
	NightStreet.tenement(self, Rect2(420, 40, 280, 200), Color(0.12, 0.1, 0.2))
	NightStreet.tenement(self, Rect2(880, 20, 320, 220), Color(0.2, 0.08, 0.12))
	NightStreet.tenement(self, Rect2(1400, 50, 260, 190), Color(0.14, 0.12, 0.18))
	NightStreet.tenement(self, Rect2(1960, 30, 300, 210), Color(0.16, 0.07, 0.14))
	NightStreet.tenement(self, Rect2(2480, 70, 280, 230), Color(0.1, 0.14, 0.16))
	Blockout.solid(self, Rect2(360, ROOF_Y, 520, 22), true)
	Blockout.poly(self, Rect2(360, ROOF_Y, 520, 22), Color(0.28, 0.16, 0.22), 2)
	Blockout.solid(self, Rect2(1100, ROOF_Y, 480, 22), true)
	Blockout.poly(self, Rect2(1100, ROOF_Y, 480, 22), Color(0.22, 0.18, 0.28), 2)
	Blockout.solid(self, Rect2(1880, 228.0, 420, 22), true)
	Blockout.poly(self, Rect2(1880, 228.0, 420, 22), Color(0.24, 0.14, 0.2), 2)
	fire_escape(420.0)
	fire_escape(1180.0)
	fire_escape(1960.0)
	fire_escape(2520.0)
	var crate := VaultCrate.new()
	crate.global_position = Vector2(980, 500)
	add_child(crate)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(720, 500)
	add_child(board)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1320, ROOF_Y)
	add_child(pistol)
	anchor(Vector2(520, 70))
	anchor(Vector2(1280, 56))
	anchor(Vector2(2040, 48))
	anchor(Vector2(2660, 80))
	NightStreet.bounds(self, map_w)
	NightStreet.neon(self, Vector2(120, 140), "NEON EXCHANGE  ·  CASH ONLY FEELINGS")
	NightStreet.section(self, Vector2(380, 180), "brawl")
	NightStreet.section(self, Vector2(1100, 180), "parkour")
	NightStreet.section(self, Vector2(1880, 170), "gun")
	NightStreet.neon(self, Vector2(760, 168), "AGENTS INSIDE  ·  SMILE")
	NightStreet.neon(self, Vector2(1680, 150), "PAWN & PLATE")
	NightStreet.plaque(self, Vector2(2520, 180), "SELL YOUR PIPE. KEEP THE WOUND.", Palette.MUTED, 13)
	NightStreet.rain(self, 1500.0)
	var shop := StreetShop.new()
	shop.catalog = "pawn_plate"
	shop.title = "PAWN & PLATE"
	shop.idle = "PAWN & PLATE  ·  WE BUY REGRET"
	shop.hint = "SPECIAL TAPE 9  ·  DOWN PIPE 7  ·  UP SELL 0"
	shop.global_position = Vector2(2720, 490)
	add_child(shop)
