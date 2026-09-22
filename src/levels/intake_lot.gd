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
	duration = 88.0


func build_world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.07, 0.05, 0.04), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "lot")
	NightStreet.wet_floor(self, map_w)
	NightStreet.water_band(self, map_w, 580.0)
	for i in 7:
		var x := 80.0 + i * 260.0
		var stall := Blockout.poly(self, Rect2(x, 470, 200, 8), Color(0.55, 0.45, 0.18, 0.7), 1)
		stall.z_index = 1
	NightStreet.car(self, Vector2(360, 500), Color(0.28, 0.18, 0.12))
	NightStreet.car(self, Vector2(820, 500), Color(0.18, 0.2, 0.22))
	NightStreet.car(self, Vector2(1280, 500), Color(0.32, 0.14, 0.1))
	NightStreet.car(self, Vector2(1680, 500), Color(0.16, 0.16, 0.18))
	Blockout.solid(self, Rect2(520, 248, 220, 18), true)
	Blockout.poly(self, Rect2(520, 248, 220, 18), Color(0.22, 0.16, 0.1), 2)
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
