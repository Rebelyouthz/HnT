extends RunAct

const ROOF_Y := 248.0
const HIGH_Y := 208.0


func _configure() -> void:
	map_id = "fire_escapes"
	map_w = 2800.0
	spawn_at = Vector2(220, 248)
	roof_start = true
	goal_x = 2620.0
	check_x = 2400.0
	check_pos = Vector2(2400, 208)
	next_id = "group_circle"
	light_preset = "fire_escapes"
	toast_title = "FIRE ESCAPES"
	toast_body = "Roofs. Gaps. A man selling opinions. Mini on the pipe."
	clear_title = Copy.FIRE_CLEAR
	clear_sub = Copy.FIRE_SUB
	next_label = Copy.NEXT_CIRCLE
	gate_sub = Copy.GATE_CIRCLE
	win_mode = "boss"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "roofs")
	NightStreet.wet_floor(self, map_w, true)
	for r in [
		Rect2(40, 40, 280, 210),
		Rect2(420, 20, 300, 190),
		Rect2(880, 10, 260, 200),
		Rect2(1480, 8, 320, 200),
		Rect2(2100, 30, 280, 180),
		Rect2(2520, 50, 240, 160)
	]:
		Blockout.occluder(self, r)
		# The painted skyline (roofs_strip) is the view; drawn tenements only without it.
		if not NightStreet.has_backdrop("roofs"):
			NightStreet.pixel_tenement(self, r)
	Blockout.solid(self, Rect2(0, ROOF_Y, 520, 22), true)
	NightStreet.pixel_roof(self, Rect2(0, ROOF_Y, 520, 22))
	Blockout.solid(self, Rect2(700, ROOF_Y, 420, 22), true)
	NightStreet.pixel_roof(self, Rect2(700, ROOF_Y, 420, 22))
	Blockout.solid(self, Rect2(1280, HIGH_Y, 380, 22), true)
	NightStreet.pixel_roof(self, Rect2(1280, HIGH_Y, 380, 22))
	Blockout.solid(self, Rect2(1840, ROOF_Y, 360, 22), true)
	NightStreet.pixel_roof(self, Rect2(1840, ROOF_Y, 360, 22))
	Blockout.solid(self, Rect2(2360, HIGH_Y, 440, 22), true)
	NightStreet.pixel_roof(self, Rect2(2360, HIGH_Y, 440, 22))
	var wall := Blockout.solid(self, Rect2(1164, 90, 18, 130), false)
	wall.add_to_group("metal")
	NightStreet.pixel_tenement(self, Rect2(1164, 90, 18, 130))
	fire_escape(360.0, ROOF_Y)
	fire_escape(900.0, ROOF_Y)
	fire_escape(1960.0, ROOF_Y)
	fire_escape(2400.0, HIGH_Y)
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(480, 500)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(1680, 500)
	add_child(c2)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1500, HIGH_Y)
	add_child(pistol)
	anchor(Vector2(480, 64))
	anchor(Vector2(980, 48))
	anchor(Vector2(1500, 40))
	anchor(Vector2(2100, 70))
	anchor(Vector2(2580, 44))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(80, 110), "THE FIRE ESCAPES  ·  RAVEN WHARF", Palette.EDGE, 20)
	NightStreet.section(self, Vector2(80, 150), "parkour")
	NightStreet.section(self, Vector2(1480, 140), "gun")
	NightStreet.section(self, Vector2(1680, 430), "brawl")
	NightStreet.plaque(self, Vector2(530, 210), "GAP  ·  GLIDE, WEB, OR FALL AND JOKE ABOUT IT", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(1320, 170), "HIGH LEDGE  ·  WALL-RUN THE PIPE", Palette.MUTED, 13)
	NightStreet.neon(self, Vector2(2380, 120), "ROOF VENDOR  ·  AMMO AND A SECOND OPINION")
	NightStreet.rain(self, 1400.0)
	var vendor := RoofVendor.new()
	vendor.global_position = Vector2(2520, 208)
	add_child(vendor)
