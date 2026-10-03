extends SurviveAct

## Flooded parking. Sodium. Cars as roofs. Not a street palette-swap.


func _configure() -> void:
	map_id = "intake_lot"
	map_w = 2000.0
	spawn_at = Vector2(220, 490)
	goal_x = 99999.0
	next_id = "fire_escapes"
	light_preset = "intake_lot"
	toast_title = "THE INTAKE LOT"
	toast_body = "Hold the lot. Magnet the chips. Clamp King at 0:32."
	clear_title = Copy.LOT_CLEAR
	clear_sub = Copy.LOT_SUB
	next_label = Copy.NEXT_FIRE
	gate_sub = Copy.GATE_FIRE
	win_mode = "boss"
	duration = 300.0


func build_world() -> void:
	NightStreet.parallax(self, map_w, "lot")
	NightStreet.wet_floor(self, map_w, true)
	NightStreet.water_band(self, map_w, 580.0, "puddle")
	NightStreet.car(self, Vector2(360, 500), Color(0.28, 0.18, 0.12), "sedan")
	NightStreet.car(self, Vector2(820, 500), Color(0.18, 0.2, 0.22), "hatchback")
	NightStreet.car(self, Vector2(1280, 500), Color(0.32, 0.14, 0.1), "van")
	NightStreet.car(self, Vector2(1680, 500), Color(0.16, 0.16, 0.18), "sedan")
	Blockout.solid(self, Rect2(520, 248, 220, 18), true)
	NightStreet.pixel_roof(self, Rect2(520, 248, 220, 18), "lot_roof")
	fire_escape(560.0, 248.0)
	var crate := VaultCrate.new()
	crate.global_position = Vector2(980, 500)
	add_child(crate)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(620, 248)
	add_child(pistol)
	anchor(Vector2(580, 60))
	anchor(Vector2(1400, 70))
	NightStreet.pixel_lot(self, map_w)
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(60, 120), "THE INTAKE LOT  ·  COPING HOUR", Palette.EDGE, 20)
	NightStreet.section(self, Vector2(340, 160), "parkour")
	NightStreet.section(self, Vector2(820, 160), "gun")
	NightStreet.section(self, Vector2(1280, 160), "brawl")
	NightStreet.plaque(self, Vector2(500, 200), "CAR ROOFS  ·  MAGNET THE CHIPS", Palette.MUTED, 13)
	NightStreet.rain(self, 1000.0)
