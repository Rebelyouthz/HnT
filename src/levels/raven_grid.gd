extends RunAct

## Cyberpunk city. Courier chase. Driver + 360° rail. Ramp crash over the canal.

var _van: ClinicVan
var _chase_armed := false


func _configure() -> void:
	map_id = "raven_grid"
	map_w = 4000.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	next_id = "ledger_dive"
	check_x = 3600.0
	check_pos = Vector2(3600, 490)
	light_preset = "raven_grid"
	toast_title = "RAVEN GRID"
	toast_body = "Cyberpunk downtown. Mini, then steal the lemon courier. Drive + rail 360°. Ramp. Canal. Crawl."
	clear_title = Copy.GRID_CLEAR
	clear_sub = Copy.GRID_SUB
	next_label = Copy.NEXT_LEDGER
	gate_sub = Copy.GATE_LEDGER
	win_mode = "boss"
	defer_final_boss = true


func build_world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.06, 0.03, 0.12), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "cyber")
	NightStreet.wet_floor(self, map_w)
	NightStreet.tenement(self, Rect2(40, 20, 280, 300), Color(0.16, 0.06, 0.2))
	NightStreet.tenement(self, Rect2(620, 10, 320, 250), Color(0.1, 0.08, 0.22))
	NightStreet.tenement(self, Rect2(1400, 0, 360, 240), Color(0.14, 0.05, 0.18))
	NightStreet.tenement(self, Rect2(3360, 20, 300, 260), Color(0.08, 0.12, 0.22))
	NightStreet.tenement(self, Rect2(3680, 10, 280, 250), Color(0.18, 0.06, 0.16))
	Blockout.solid(self, Rect2(480, 248, 520, 18), true)
	Blockout.poly(self, Rect2(480, 248, 520, 18), Color(0.28, 0.12, 0.32), 2)
	Blockout.solid(self, Rect2(1680, 208, 360, 18), true)
	Blockout.poly(self, Rect2(1680, 208, 360, 18), Color(0.12, 0.22, 0.32), 2)
	Blockout.solid(self, Rect2(3480, 248, 400, 18), true)
	Blockout.poly(self, Rect2(3480, 248, 400, 18), Color(0.22, 0.1, 0.28), 2)
	NightStreet.underpass(self, Vector2(1760, 360), 380.0)
	NightStreet.ramp(self, Vector2(2280, 472))
	NightStreet.canal(self, 2580.0, 780.0, 508.0)
	set_meta("canal", Rect2(2580, 0, 780, 720))
	fire_escape(560.0, 248.0)
	fire_escape(1760.0, 208.0)
	fire_escape(3520.0, 248.0)
	ParkourToy.place(self, Vector2(900, 500), "hill")
	ParkourToy.place(self, Vector2(1480, 248), "wire")
	ParkourToy.place(self, Vector2(2100, 500), "pad")
	ParkourToy.place(self, Vector2(3600, 500), "drop")
	var c1 := VaultCrate.new()
	c1.global_position = Vector2(780, 500)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(3560, 500)
	add_child(c2)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1880, 208)
	add_child(pistol)
	var board := WeaponPickup.new()
	board.kind = "board"
	board.global_position = Vector2(1100, 500)
	add_child(board)
	anchor(Vector2(640, 40))
	anchor(Vector2(1880, 30))
	anchor(Vector2(3600, 40))
	NightStreet.bounds(self, map_w)
	NightStreet.neon(self, Vector2(80, 110), "RAVEN GRID  ·  EVICTION PROCESSED HERE", Palette.LEMON)
	NightStreet.section(self, Vector2(480, 160), "parkour")
	NightStreet.section(self, Vector2(1680, 140), "gun")
	NightStreet.section(self, Vector2(3480, 160), "brawl")
	NightStreet.plaque(self, Vector2(1280, 170), "CHASE AFTER THE BROKER  ·  LEMON COURIER", Palette.EDGE, 13)
	NightStreet.plaque(self, Vector2(2280, 200), "FORCED RAMP  ·  THEN THE CANAL", Palette.LEMON, 13)
	NightStreet.plaque(self, Vector2(3480, 180), "FAR SHORE  ·  THEY DON'T FOLLOW", Palette.MUTED, 13)
	NightStreet.car(self, Vector2(1520, 500), Color(0.92, 0.82, 0.22))
	NightStreet.rain(self, 2000.0)


func on_mini_down() -> void:
	super.on_mini_down()
	_arm_chase()


func _arm_chase() -> void:
	if _chase_armed:
		return
	_chase_armed = true
	Juice.toast("quest", "STEAL THE COURIER", "The Son drives. The Father rails 360°. SPECIAL swaps. Solo hops the rail. Then the ramp.")
	Juice.shout("COURIER")


func _process(delta: float) -> void:
	super._process(delta)
	if _van != null or not _chase_armed or _state.failed or _state.cleared:
		return
	var lead := spawn_at
	if _son:
		lead = _son.global_position
	elif _dad:
		lead = _dad.global_position
	if lead.x < 1320.0:
		return
	_van = ClinicVan.start(self, Vector2(lead.x + 40.0, 490), _son, _dad, map_w)
	_van.ramp_x = 2480.0
	_van.dumped.connect(func() -> void:
		Juice.toast("quest", "FAR SHORE", "Canal ate the chase. Grid still wants a signature.")
	)
