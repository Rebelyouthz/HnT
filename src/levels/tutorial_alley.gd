extends RunAct

## Short alley: parkour plaque, gun pickup, brawl dummy, then film 2.

var _film2 := false
var _dummy_hit := false
var _overlay: CanvasLayer
var _fi := 0


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
	var sky := Blockout.poly(self, Rect2(0, 0, map_w, 720), Color(0.07, 0.08, 0.12), -8)
	sky.z_index = -8
	NightStreet.parallax(self, map_w, "tutorial")
	NightStreet.wet_floor(self, map_w)
	NightStreet.tenement(self, Rect2(40, 80, 260, 240), Color(0.14, 0.11, 0.12))
	NightStreet.tenement(self, Rect2(1400, 60, 280, 260), Color(0.12, 0.14, 0.16))
	Blockout.solid(self, Rect2(480, 248, 280, 22), true)
	Blockout.poly(self, Rect2(480, 248, 280, 22), Color(0.22, 0.18, 0.2), 2)
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


func _start_film2() -> void:
	if _film2:
		return
	_film2 = true
	get_tree().paused = true
	_overlay = CanvasLayer.new()
	_overlay.layer = 55
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var top := ColorRect.new()
	top.color = Color.BLACK
	top.size = Vector2(1280, 80)
	_overlay.add_child(top)
	var bot := ColorRect.new()
	bot.color = Color.BLACK
	bot.position = Vector2(0, 640)
	bot.size = Vector2(1280, 80)
	_overlay.add_child(bot)
	_fi = 0
	_paint_f2()


func _paint_f2() -> void:
	var lines: Variant = StoryBook.all().get("intro", {}).get("film2", [])
	if typeof(lines) != TYPE_ARRAY or _fi >= (lines as Array).size():
		_finish_intro()
		return
	for c in _overlay.get_children():
		if c is Label:
			c.queue_free()
	var row: Variant = (lines as Array)[_fi]
	if typeof(row) != TYPE_DICTIONARY:
		_fi += 1
		_paint_f2()
		return
	var d: Dictionary = row
	var who := Label.new()
	who.position = Vector2(80, 500)
	who.size = Vector2(1120, 24)
	UiKit.apply_label(who, 14, Palette.EDGE)
	who.text = StoryBook.who_name(str(d.get("who", ""))) if str(d.get("who", "")) != "" else "INTRO"
	who.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(who)
	var body := Label.new()
	body.position = Vector2(80, 536)
	body.size = Vector2(1120, 80)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(body, 22, Palette.TEXT)
	body.text = str(d.get("text", ""))
	body.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(body)
	var skip := Label.new()
	skip.position = Vector2(40, 24)
	skip.text = Copy.SKIP_FILM
	skip.process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.apply_label(skip, 14, Palette.MUTED)
	_overlay.add_child(skip)
	Juice.play("res://assets/audio/sting_intro.wav")


func _unhandled_input(event: InputEvent) -> void:
	if not _film2:
		return
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		_finish_intro()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("p1_light") or event.is_action_pressed("p1_jump") or event.is_action_pressed("p2_light"):
		_fi += 1
		_paint_f2()
		get_viewport().set_input_as_handled()


func _finish_intro() -> void:
	get_tree().paused = false
	FamilyProfile.mark_intro()
	App.enter_map("dock_street")
