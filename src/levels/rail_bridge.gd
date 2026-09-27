extends RunAct

const ROOF_Y := 248.0
const CAR_Y := 236.0


func _configure() -> void:
	map_id = "rail_bridge"
	map_w = 3000.0
	spawn_at = Vector2(200, 490)
	goal_x = 2760.0
	check_x = 2500.0
	check_pos = Vector2(2500, 490)
	next_id = "city_hall"
	light_preset = "rail_bridge"
	toast_title = "RAIL BRIDGE"
	toast_body = "Street under. Roofs on the cars. Mini in the freight."
	clear_title = Copy.BRIDGE_CLEAR
	clear_sub = Copy.BRIDGE_SUB
	next_label = Copy.NEXT_HALL
	gate_sub = Copy.HALL_GATE
	win_mode = "boss"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "rail")
	NightStreet.wet_floor(self, map_w)
	Blockout.poly(self, Rect2(0, 80, map_w, 36), Color(0.18, 0.16, 0.14), -2)
	NightStreet.tenement(self, Rect2(40, 120, 200, 200), Color(0.12, 0.11, 0.12))
	NightStreet.tenement(self, Rect2(2600, 100, 220, 220), Color(0.13, 0.12, 0.11))
	NightStreet.boxcar(self, Rect2(380, CAR_Y, 280, 70))
	NightStreet.boxcar(self, Rect2(820, CAR_Y, 260, 70))
	NightStreet.boxcar(self, Rect2(1280, ROOF_Y, 300, 70))
	NightStreet.boxcar(self, Rect2(1780, CAR_Y, 240, 70))
	NightStreet.boxcar(self, Rect2(2200, ROOF_Y, 280, 70))
	fire_escape(500.0, CAR_Y)
	fire_escape(1340.0, ROOF_Y)
	fire_escape(2260.0, ROOF_Y)
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(1100, 500)
	add_child(c1)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1640, CAR_Y)
	add_child(pistol)
	anchor(Vector2(500, 90))
	anchor(Vector2(1400, 70))
	anchor(Vector2(2320, 80))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(80, 150), "RAIL BRIDGE  ·  TOLL IS A PERSONALITY", Palette.EDGE, 20)
	NightStreet.section(self, Vector2(380, 180), "parkour")
	NightStreet.section(self, Vector2(1480, 180), "gun")
	NightStreet.section(self, Vector2(1100, 430), "brawl")
	NightStreet.plaque(self, Vector2(900, 180), "ROOFS ON CARS  ·  STREET STILL BITES", Palette.MUTED, 13)
	NightStreet.neon(self, Vector2(2480, 140), "TOLL BOOTH")
	NightStreet.rain(self, 1500.0)
	var shop := StreetShop.new()
	shop.catalog = "toll_booth"
	shop.title = "TOLL BOOTH"
	shop.idle = "TOLL BOOTH  ·  GRENADES AND SPARK"
	shop.hint = "SPECIAL GRENADE 10  ·  DOWN SPARK 6"
	shop.global_position = Vector2(2680, 490)
	add_child(shop)
