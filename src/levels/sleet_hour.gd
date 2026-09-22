extends SurviveAct

## Snow hour after the orchard. Frozen lake. Ice wires. The retreat froze.


func _configure() -> void:
	map_id = "sleet_hour"
	map_w = 2200.0
	spawn_at = Vector2(200, 490)
	goal_x = 99999.0
	next_id = "raven_grid"
	light_preset = "sleet_hour"
	toast_title = "SLEET HOUR"
	toast_body = "The orchard froze. Hold the lake. Elites on snowmobiles. Don't sit on the ice."
	clear_title = Copy.SLEET_CLEAR
	clear_sub = Copy.SLEET_SUB
	next_label = Copy.NEXT_GRID
	gate_sub = Copy.GATE_GRID
	win_mode = "boss"
	duration = 88.0


func _ready() -> void:
	super._ready()
	if _horde:
		_horde.titles = ["Sleet Imp", "Ice Drone", "Frost Clerk", "Snowmobile"]


func build_world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.12, 0.16, 0.22), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "snow")
	Blockout.poly(self, Rect2(0, 430, map_w, 290), Color(0.78, 0.84, 0.9, 0.55), 0)
	Blockout.poly(self, Rect2(0, 520, map_w, 80), Color(0.55, 0.72, 0.82, 0.45), 1)
	Blockout.solid(self, Rect2(280, 248, 300, 16), true)
	Blockout.poly(self, Rect2(280, 248, 300, 16), Color(0.72, 0.8, 0.88), 2)
	Blockout.solid(self, Rect2(1180, 220, 340, 16), true)
	Blockout.poly(self, Rect2(1180, 220, 340, 16), Color(0.7, 0.78, 0.86), 2)
	NightStreet.tenement(self, Rect2(40, 40, 200, 200), Color(0.55, 0.62, 0.7))
	NightStreet.tenement(self, Rect2(1760, 30, 240, 210), Color(0.5, 0.58, 0.68))
	fire_escape(320.0, 248.0)
	fire_escape(1280.0, 220.0)
	ParkourToy.place(self, Vector2(700, 500), "hill")
	ParkourToy.place(self, Vector2(980, 248), "wire")
	ParkourToy.place(self, Vector2(1500, 500), "pad")
	var crate := VaultCrate.new()
	crate.global_position = Vector2(1040, 500)
	add_child(crate)
	var pistol := WeaponPickup.new()
	pistol.kind = "pistol"
	pistol.global_position = Vector2(1320, 220)
	add_child(pistol)
	anchor(Vector2(360, 40))
	anchor(Vector2(1400, 30))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(40, 100), "SLEET HOUR  ·  THE RETREAT FROZE", Palette.EDGE, 20)
	NightStreet.section(self, Vector2(280, 150), "parkour")
	NightStreet.section(self, Vector2(1180, 140), "gun")
	NightStreet.section(self, Vector2(700, 150), "brawl")
	NightStreet.plaque(self, Vector2(900, 180), "ICE WIRE  ·  DON'T SIT", Palette.MUTED, 13)
	NightStreet.rain(self, 1100.0)
