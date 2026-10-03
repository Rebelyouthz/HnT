extends RunAct


func _configure() -> void:
	map_id = "city_hall"
	map_w = 2200.0
	spawn_at = Vector2(180, 490)
	goal_x = 99999.0
	next_id = "copay_orchard"
	light_preset = "city_hall"
	toast_title = "CITY HALL"
	toast_body = "Deputy first. Then the landlord. Statues climb."
	clear_title = Copy.HALL_CLEAR
	clear_sub = Copy.HALL_SUB
	next_label = Copy.NEXT_ORCHARD
	gate_sub = Copy.GATE_ORCHARD
	win_mode = "boss"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "hall")
	# Painted hall sections (backdrops/hall_strip) replace the blockout
	# tenements; the painted wet street is the floor.
	if NightStreet.has_backdrop("hall") and WetStreet.available():
		WetStreet.lay(self, map_w)
	else:
		NightStreet.wet_floor(self, map_w)
		NightStreet.tenement(self, Rect2(40, 40, 360, 280), Color(0.16, 0.14, 0.12))
		NightStreet.tenement(self, Rect2(1780, 40, 360, 280), Color(0.14, 0.12, 0.14))
	NightStreet.statue(self, Vector2(620, 248), 248.0)
	NightStreet.statue(self, Vector2(1180, 208), 208.0)
	NightStreet.statue(self, Vector2(1680, 248), 248.0)
	fire_escape(620.0, 248.0)
	fire_escape(1180.0, 208.0)
	fire_escape(1680.0, 248.0)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1180, 208)
	add_child(pistol)
	anchor(Vector2(640, 40))
	anchor(Vector2(1200, 24))
	anchor(Vector2(1700, 40))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(80, 120), "CITY HALL  ·  THE LANDLORD IS IN", Palette.EDGE, 22)
	NightStreet.section(self, Vector2(80, 160), "brawl")
	NightStreet.section(self, Vector2(600, 160), "parkour")
	NightStreet.section(self, Vector2(1100, 140), "gun")
	NightStreet.plaque(self, Vector2(980, 160), "STATUES CLIMB. RAVEN DOES NOT SHARE.", Palette.MUTED, 13)
	NightStreet.rain(self, 1100.0)
	var raven := MayorRaven.new()
	raven.global_position = Vector2(1500, 500)
	raven.died.connect(func() -> void:
		FamilyProfile.mark_raven()
		finish_boss()
	)
	add_child(raven)
