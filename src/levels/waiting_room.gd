extends SurviveAct


func _configure() -> void:
	map_id = "waiting_room"
	map_w = 1900.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	next_id = "rail_bridge"
	light_preset = "waiting_room"
	toast_title = "THE WAITING ROOM"
	toast_body = "Fluorescent forever. Number 87 is already sitting."
	clear_title = Copy.WAIT_CLEAR
	clear_sub = Copy.WAIT_SUB
	next_label = Copy.NEXT_BRIDGE
	gate_sub = Copy.BRIDGE_GATE
	win_mode = "boss"
	duration = 90.0


func build_world() -> void:
	NightStreet.parallax(self, map_w, "waiting")
	# Painted sections (backdrops/waiting_strip) replace the blockout
	# buildings; the painted wet street is the floor.
	if NightStreet.has_backdrop("waiting") and WetStreet.available():
		# Indoors: a mopped floor, not cobbles.
		WetStreet.lay(self, map_w, "clinic_floor" if WetStreet.available("clinic_floor") else "street")
	else:
		NightStreet.wet_floor(self, map_w)
		Blockout.poly(self, Rect2(0, 80, map_w, 40), Color(0.82, 0.84, 0.78, 0.35), -2)
		NightStreet.tenement(self, Rect2(20, 20, 200, 180), Color(0.18, 0.18, 0.2))
		NightStreet.tenement(self, Rect2(1640, 20, 220, 190), Color(0.16, 0.18, 0.18))
	for i in 8:
		var x := 80.0 + i * 210.0
		Blockout.poly(self, Rect2(x, 470, 70, 28), Color(0.28, 0.28, 0.3), 2)
		Blockout.poly(self, Rect2(x + 8, 448, 54, 22), Color(0.32, 0.32, 0.34), 2)
	Blockout.solid(self, Rect2(420, 248, 240, 18), true)
	Blockout.poly(self, Rect2(420, 248, 240, 18), Color(0.3, 0.3, 0.32), 2)
	Blockout.solid(self, Rect2(1100, 228, 260, 18), true)
	Blockout.poly(self, Rect2(1100, 228, 260, 18), Color(0.26, 0.28, 0.28), 2)
	fire_escape(460.0, 248.0)
	fire_escape(1180.0, 228.0)
	var crate := VaultCrate.new()
	crate.global_position = Vector2(860, 500)
	add_child(crate)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1220, 228)
	add_child(pistol)
	anchor(Vector2(500, 40))
	anchor(Vector2(1220, 36))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(60, 110), "WAITING ROOM  ·  NOW SERVING PAIN", Palette.EDGE, 20)
	NightStreet.section(self, Vector2(420, 150), "parkour")
	NightStreet.section(self, Vector2(1100, 150), "gun")
	NightStreet.section(self, Vector2(80, 150), "brawl")
	NightStreet.plaque(self, Vector2(700, 180), "DON'T SIT. SITTING IS HOW THEY WIN.", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(980, 430), "THERAPY DOG  ·  PLEASE DO NOT PET", Palette.MUTED, 12)
	NightStreet.neon(self, Vector2(1400, 140), "88")
	var walker := Skinwalker.new()
	walker.title = "Number 87"
	walker.display = "Number 87"
	walker.is_mini = true
	walker.sub = "ALREADY SITTING"
	walker.home = "street"
	walker.hp = 128
	walker.max_hp = 128
	walker.patrol_min = 820.0
	walker.patrol_max = 1180.0
	walker.global_position = Vector2(980, 500)
	walker.dormant = true
	add_child(walker)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("hp_mul"):
		walker.hp = int(round(128.0 * float(rs.call("hp_mul"))))
		walker.max_hp = walker.hp
