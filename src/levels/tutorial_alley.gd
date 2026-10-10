extends RunAct

## Short alley: parkour plaque, gun pickup, brawl dummy, then film 2.

var _film2 := false
var _dummy_hit := false


func _configure() -> void:
	map_id = "tutorial_alley"
	map_w = 1800.0
	spawn_at = Vector2(180, 490)
	goal_x = 99999.0
	light_preset = "dock_street"
	toast_title = "TUTORIAL ALLEY"
	toast_body = "Jump. Shoot. Punch. Then a second film, because the clinic loves a sequel."
	win_mode = "boss"
	music = "res://assets/audio/music_street.wav"


func build_world() -> void:
	NightStreet.parallax(self, map_w, "tutorial")
	NightStreet.wet_floor(self, map_w, true)
	# The painted alley is the buildings; flat blockout walls only without it.
	if not NightStreet.has_backdrop("tutorial"):
		NightStreet.tenement(self, Rect2(40, 80, 260, 240), Color(0.14, 0.11, 0.12))
		NightStreet.tenement(self, Rect2(1400, 60, 280, 260), Color(0.12, 0.14, 0.16))
	NightStreet.pixel_dock(self, map_w, false)
	Blockout.solid(self, Rect2(480, 248, 280, 22), true)
	NightStreet.pixel_roof(self, Rect2(480, 248, 280, 22))
	fire_escape(520.0)
	var crate := VaultCrate.new()
	crate.global_position = Vector2(640, 500)
	add_child(crate)
	var gun := WeaponPickup.new()
	gun.kind = "pistol"
	gun.global_position = Vector2(980, 500)
	add_child(gun)
	anchor(Vector2(560, 70))
	NightStreet.bounds(self, map_w)
	NightStreet.section(self, Vector2(120, 140), "parkour")
	NightStreet.section(self, Vector2(900, 140), "gun")
	NightStreet.section(self, Vector2(1280, 140), "brawl")
	NightStreet.plaque(self, Vector2(80, 180), "JUMP THE LEDGE  ·  HOLD JUMP TO STALL", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(860, 180), "PICK UP THE PISTOL  ·  O / RB TO FIRE", Palette.MUTED, 13)
	NightStreet.plaque(self, Vector2(1240, 180), "PUNCH THE DUMMY  ·  THEN WALK RIGHT", Palette.MUTED, 13)
	NightStreet.rain(self, 900.0)
	AmbientProp.lamp(self, Vector2(360.0, 500.0), 3)
	AmbientProp.lamp(self, Vector2(1180.0, 500.0), 3)
	var dummy := Party.spawn_row(self, {
		"title": "Bag Snatch", "x": 1420, "y": 500, "home": "street", "hp": 24, "pmin": 1320, "pmax": 1560
	}, 0.6)
	if dummy:
		dummy.died.connect(func() -> void:
			_dummy_hit = true
			if _missions:
				_missions.complete_side()
			Juice.toast("challenge", "DUMMY FILED", "It didn't even charge you. Growth.")
		)


func _process(delta: float) -> void:
	super._process(delta)
	if _film2 or _state.failed or _state.cleared:
		return
	if Party.all_past(1580.0):
		_start_film2()


## Film 2 plays on the street itself: the two of them stop at the end of the
## alley and talk in bubbles over their heads, then Dock Street.
func _start_film2() -> void:
	if _film2:
		return
	_film2 = true
	var lines: Variant = StoryBook.all().get("intro", {}).get("film2", [])
	if typeof(lines) != TYPE_ARRAY or (lines as Array).is_empty() or _talk == null:
		_finish_intro()
		return
	Juice.play("res://assets/audio/sting_intro.wav")
	_talk.closed.connect(_finish_intro, CONNECT_ONE_SHOT)
	_talk.play(lines as Array, true)


func _finish_intro() -> void:
	get_tree().paused = false
	FamilyProfile.mark_intro()
	App.enter_map("dock_street")
