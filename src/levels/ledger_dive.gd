extends SurviveAct

## Surprise last: flooded underground invoice vault / brine spa / billboard cenote.


func _configure() -> void:
	map_id = "ledger_dive"
	map_w = 2400.0
	spawn_at = Vector2(220, 490)
	goal_x = 99999.0
	next_id = "invoice_pier"
	light_preset = "ledger_dive"
	toast_title = "LEDGER DIVE"
	toast_body = "You dropped into the vault. A spa they billed as therapy. Billboards drown. Hold the brine."
	clear_title = Copy.LEDGER_CLEAR
	clear_sub = Copy.LEDGER_SUB
	next_label = Copy.NEXT_PIER
	gate_sub = Copy.GATE_PIER
	win_mode = "boss"
	duration = 88.0


func _ready() -> void:
	super._ready()
	if _horde:
		_horde.titles = ["Ledger Eel", "Brine Clerk", "Billboard Gull", "Vault Guard"]


func build_world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.04, 0.08, 0.1), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "vault")
	NightStreet.water_band(self, map_w, 540.0)
	Blockout.poly(self, Rect2(0, 430, map_w, 40), Color(0.18, 0.16, 0.12), 1)
	Blockout.solid(self, Rect2(360, 200, 280, 16), true)
	Blockout.poly(self, Rect2(360, 200, 280, 16), Color(0.22, 0.28, 0.24), 2)
	Blockout.solid(self, Rect2(1100, 248, 320, 16), true)
	Blockout.poly(self, Rect2(1100, 248, 320, 16), Color(0.2, 0.24, 0.22), 2)
	Blockout.solid(self, Rect2(1700, 180, 260, 16), true)
	Blockout.poly(self, Rect2(1700, 180, 260, 16), Color(0.24, 0.3, 0.26), 2)
	NightStreet.chapel(self, Rect2(1880, 200, 280, 300))
	NightStreet.tenement(self, Rect2(40, 40, 240, 220), Color(0.1, 0.16, 0.16))
	fire_escape(420.0, 200.0)
	fire_escape(1180.0, 248.0)
	fire_escape(1760.0, 180.0)
	ParkourToy.place(self, Vector2(200, 80), "drop")
	ParkourToy.place(self, Vector2(720, 500), "rope")
	ParkourToy.place(self, Vector2(1400, 248), "wire")
	ParkourToy.place(self, Vector2(1600, 500), "pad")
	var crate := VaultCrate.new()
	crate.global_position = Vector2(980, 500)
	add_child(crate)
	var knife := WeaponPickup.new()
	knife.kind = "knife"
	knife.global_position = Vector2(1240, 248)
	add_child(knife)
	anchor(Vector2(480, 30))
	anchor(Vector2(1280, 40))
	anchor(Vector2(1840, 20))
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(40, 90), "LEDGER DIVE  ·  THE BRINE ANNEX", Palette.READY, 20)
	NightStreet.section(self, Vector2(360, 130), "parkour")
	NightStreet.section(self, Vector2(1100, 150), "gun")
	NightStreet.section(self, Vector2(1700, 120), "brawl")
	NightStreet.plaque(self, Vector2(80, 140), "THE DROP  ·  A SPA THEY BILLED AS THERAPY", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(1880, 150), "BILLBOARDS DROWN HERE", Palette.EDGE, 13)
	NightStreet.rain(self, 1200.0)
