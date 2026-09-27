extends RunAct

## Late-act climax. Filing basement. The Family Plan waits at the far desk.


func _configure() -> void:
	map_id = "processing_floor"
	map_w = 2800.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	check_x = 620.0
	check_pos = Vector2(620, 490)
	next_id = "ending"
	light_preset = "processing_floor"
	toast_title = "THE PROCESSING FLOOR"
	toast_body = "Bandage first. Then strip the armor. Then live long enough to file him."
	clear_title = Copy.FLOOR_CLEAR
	clear_sub = Copy.FLOOR_SUB
	next_label = Copy.NEXT_ENDING
	gate_sub = Copy.GATE_ENDING
	win_mode = "boss"
	music = "res://assets/audio/music_street.wav"
	_skip_story_boss = true


func build_world() -> void:
	NightStreet.parallax(self, map_w, "processing")
	NightStreet.wet_floor(self, map_w)
	Blockout.solid(self, Rect2(0, 492, 780, 18), true)
	Blockout.poly(self, Rect2(0, 492, 780, 18), Color(0.22, 0.2, 0.18), 2)
	Blockout.solid(self, Rect2(920, 248, 280, 18), true)
	Blockout.poly(self, Rect2(920, 248, 280, 18), Color(0.28, 0.22, 0.16), 2)
	Blockout.solid(self, Rect2(1320, 492, 1480, 18), true)
	Blockout.poly(self, Rect2(1320, 492, 1480, 18), Color(0.2, 0.18, 0.16), 2)
	Blockout.solid(self, Rect2(1680, 220, 240, 18), true)
	Blockout.poly(self, Rect2(1680, 220, 240, 18), Color(0.26, 0.2, 0.14), 2)
	fire_escape(940.0, 248.0)
	fire_escape(1700.0, 220.0)
	NightStreet.tenement(self, Rect2(40, 80, 280, 320), Color(0.16, 0.12, 0.12))
	NightStreet.tenement(self, Rect2(2360, 40, 360, 360), Color(0.14, 0.1, 0.12))
	var mart := BloodMart.new()
	mart.global_position = Vector2(520, 490)
	add_child(mart)
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(1100, 248)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(1880, 490)
	add_child(c2)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1740, 220)
	add_child(pistol)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(1080, 248)
	add_child(board)
	anchor(Vector2(480, 70))
	anchor(Vector2(1400, 50))
	anchor(Vector2(2100, 40))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(60, 110), "PROCESSING FLOOR  ·  THE FAMILY PLAN", Palette.EDGE, 22)
	NightStreet.section(self, Vector2(80, 160), "brawl")
	NightStreet.section(self, Vector2(920, 170), "parkour")
	NightStreet.section(self, Vector2(1680, 150), "gun")
	NightStreet.plaque(self, Vector2(500, 200), "BANDAGE BEFORE THE DIRECTOR. THAT'S ENABLING. DO IT ANYWAY.", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(1960, 120), "STRIP THE SUIT. THEN THE BODY. THEN THE NIGHT.", Palette.BRICK, 14)
	NightStreet.rain(self, 1400.0)
	var plan := FamilyPlan.new()
	plan.global_position = Vector2(2320, 500)
	plan.patrol_min = 1960.0
	plan.patrol_max = 2680.0
	add_child(plan)
