class_name RunAct
extends Node2D

## Shared boot for Raven Wharf acts: party, HUD, drop-in, cards, wanted, banners.

var map_id := "dock_street"
var map_w := 3200.0
var spawn_at := Vector2(220, 490)
var roof_start := false
var goal_x := 3000.0
var next_id := ""
var light_preset := "dock_street"
var toast_title := "DOCK STREET"
var toast_body := ""
var fail_sub := "Shared lives. Solo or not, three stamps and you are out."
var clear_title := "FILED"
var clear_sub := ""
var next_label := ""
var gate_sub := ""
var music := "res://assets/audio/music_street.wav"
var win_mode := "gate"
var check_x := 0.0
var check_pos := Vector2.ZERO

var _son: Fighter
var _dad: Fighter
var _state: RunState
var _hud: CanvasLayer
var _end: Node
var _cam: CouchCamera
var _join_grace := 0
var _wanted_cop := false
var _heli: Node2D
var _phone_ghost := false
var _dumpster_king := false
var _meter_maid := false
var _rig: LightRig
var _talk: Talk
var _missions: MissionHud
var _talked: Dictionary = {}
var _mini_down := false
var _boss_down := false
var _skip_story_boss := false
var defer_final_boss := false


func _configure() -> void:
	pass


func build_world() -> void:
	pass


func _place_parkour() -> void:
	var rows: Dictionary = {
		"dock_street": [[720.0, 500.0, "crate"], [1260.0, 500.0, "gap"], [2100.0, 500.0, "rail"]],
		"fire_escapes": [[560.0, 248.0, "rail"], [1100.0, 248.0, "gap"], [2000.0, 500.0, "crate"]],
		"neon_exchange": [[640.0, 500.0, "crate"], [1320.0, 500.0, "rail"], [2100.0, 500.0, "gap"]],
		"rail_bridge": [[700.0, 500.0, "rail"], [1500.0, 500.0, "gap"], [2300.0, 500.0, "crate"]],
		"city_hall": [[480.0, 500.0, "crate"], [980.0, 500.0, "rail"]],
		"invoice_pier": [[900.0, 500.0, "gap"], [1600.0, 500.0, "rail"], [2600.0, 500.0, "crate"]],
		"processing_floor": [[620.0, 500.0, "rail"], [1480.0, 500.0, "gap"]],
		"tutorial_alley": [[640.0, 500.0, "crate"], [1100.0, 500.0, "rail"]],
		"intake_lot": [[520.0, 500.0, "crate"], [1280.0, 500.0, "rail"]],
		"group_circle": [[640.0, 500.0, "rail"]],
		"waiting_room": [[720.0, 500.0, "crate"], [1400.0, 500.0, "gap"]],
		"copay_orchard": [[720.0, 500.0, "crate"], [2100.0, 500.0, "gap"]],
		"sleet_hour": [[700.0, 500.0, "rail"], [1500.0, 500.0, "crate"]],
		"raven_grid": [[900.0, 500.0, "rail"], [2200.0, 500.0, "gap"]],
		"ledger_dive": [[720.0, 500.0, "crate"], [1600.0, 500.0, "rail"]]
	}
	var list: Variant = rows.get(map_id, [])
	if typeof(list) != TYPE_ARRAY:
		return
	for row in list:
		if typeof(row) != TYPE_ARRAY or (row as Array).size() < 3:
			continue
		ParkourGate.place(self, Vector2(float(row[0]), float(row[1])), str(row[2]))
	_place_toys()
	_place_smash()
	_place_towers()
	_place_secrets()
	_place_extras()


func _place_toys() -> void:
	var rows: Dictionary = {
		"dock_street": [[880.0, 500.0, "dumpster"], [1000.0, 500.0, "bench"], [1100.0, 500.0, "awning"], [1320.0, 500.0, "cart"], [1420.0, 500.0, "hood"], [1540.0, 500.0, "pole"], [1680.0, 500.0, "billboard"], [2000.0, 500.0, "scaffold"], [2480.0, 500.0, "grind"], [560.0, 500.0, "flag"], [1880.0, 500.0, "crate"]],
		"fire_escapes": [[800.0, 248.0, "wallrun"], [1180.0, 248.0, "awning"], [1320.0, 500.0, "bench"], [1500.0, 500.0, "pole"], [1680.0, 500.0, "dumpster"], [1900.0, 500.0, "hood"], [980.0, 248.0, "flag"]],
		"neon_exchange": [[920.0, 500.0, "billboard"], [1040.0, 500.0, "bench"], [1180.0, 500.0, "awning"], [1400.0, 500.0, "cart"], [1580.0, 500.0, "pole"], [1760.0, 500.0, "grind"], [2000.0, 500.0, "hood"], [640.0, 500.0, "flag"], [2160.0, 500.0, "crate"]],
		"rail_bridge": [[1100.0, 500.0, "grind"], [1280.0, 500.0, "hood"], [1480.0, 500.0, "scaffold"], [1680.0, 500.0, "pole"], [1900.0, 500.0, "dumpster"], [2100.0, 500.0, "bench"], [860.0, 500.0, "flag"]],
		"city_hall": [[720.0, 500.0, "dumpster"], [860.0, 500.0, "bench"], [980.0, 500.0, "awning"], [1280.0, 500.0, "cart"], [1480.0, 500.0, "hood"], [1600.0, 500.0, "pole"], [540.0, 500.0, "flag"], [1720.0, 500.0, "crate"]],
		"invoice_pier": [[1200.0, 500.0, "grind"], [1360.0, 500.0, "bench"], [1480.0, 500.0, "awning"], [1680.0, 500.0, "cart"], [1900.0, 500.0, "pole"], [2040.0, 500.0, "hood"], [2200.0, 500.0, "billboard"], [980.0, 500.0, "flag"]],
		"processing_floor": [[980.0, 500.0, "wallrun"], [1200.0, 500.0, "hood"], [1400.0, 500.0, "scaffold"], [1700.0, 500.0, "pole"], [1900.0, 500.0, "bench"], [760.0, 500.0, "flag"]],
		"tutorial_alley": [[860.0, 500.0, "dumpster"]],
		"intake_lot": [[900.0, 500.0, "dumpster"], [1080.0, 500.0, "bench"], [1200.0, 500.0, "awning"], [1480.0, 500.0, "cart"], [1700.0, 500.0, "pole"], [1900.0, 500.0, "hood"], [640.0, 500.0, "flag"], [2040.0, 500.0, "crate"]],
		"group_circle": [[880.0, 500.0, "grind"], [1000.0, 500.0, "bench"], [1100.0, 500.0, "pole"], [1280.0, 500.0, "scaffold"], [1480.0, 500.0, "hood"], [720.0, 500.0, "flag"]],
		"waiting_room": [[1100.0, 500.0, "billboard"], [1300.0, 500.0, "hood"], [1500.0, 500.0, "awning"], [1750.0, 500.0, "pole"], [1900.0, 500.0, "bench"], [860.0, 500.0, "crate"]],
		"copay_orchard": [[1100.0, 500.0, "dumpster"], [1280.0, 500.0, "bench"], [1400.0, 500.0, "awning"], [1680.0, 500.0, "cart"], [1800.0, 500.0, "hood"], [2000.0, 500.0, "pole"], [2480.0, 500.0, "grind"], [860.0, 500.0, "flag"]],
		"sleet_hour": [[1100.0, 500.0, "grind"], [1300.0, 500.0, "hood"], [1480.0, 500.0, "awning"], [1680.0, 500.0, "pole"], [1900.0, 500.0, "dumpster"], [2100.0, 500.0, "bench"], [820.0, 500.0, "flag"]],
		"raven_grid": [[980.0, 500.0, "bench"], [1080.0, 500.0, "awning"], [1200.0, 500.0, "dumpster"], [1380.0, 500.0, "pole"], [1560.0, 500.0, "cart"], [1680.0, 500.0, "hood"], [1900.0, 500.0, "grind"], [2100.0, 500.0, "scaffold"], [740.0, 500.0, "flag"], [2040.0, 500.0, "crate"]],
		"ledger_dive": [[1100.0, 500.0, "grind"], [1280.0, 500.0, "hood"], [1480.0, 500.0, "scaffold"], [1700.0, 500.0, "pole"], [2000.0, 500.0, "dumpster"], [2200.0, 500.0, "bench"], [1860.0, 500.0, "flag"]]
	}
	var list: Variant = rows.get(map_id, [])
	if typeof(list) != TYPE_ARRAY:
		return
	for row in list:
		if typeof(row) != TYPE_ARRAY or (row as Array).size() < 3:
			continue
		var x := float(row[0])
		if map_id == "raven_grid" and x > 2200.0:
			continue
		ParkourToy.place(self, Vector2(x, float(row[1])), str(row[2]))


func _place_smash() -> void:
	var rows: Dictionary = {
		"dock_street": [[640.0, "booth"], [860.0, "barrel"], [1100.0, "hydrant"], [1240.0, "manhole"], [1480.0, "kiosk"], [1760.0, "news"], [1960.0, "cop_car"], [2320.0, "dumpster"], [980.0, "mail"]],
		"fire_escapes": [[700.0, "booth"], [1000.0, "manhole"], [1200.0, "vending"], [1500.0, "barrel"], [1900.0, "fridge"], [1640.0, "news"]],
		"neon_exchange": [[800.0, "billboard"], [1100.0, "hydrant"], [1300.0, "barrel"], [1600.0, "kiosk"], [1800.0, "manhole"], [2000.0, "mail"], [2400.0, "booth"], [920.0, "vending"]],
		"rail_bridge": [[900.0, "dumpster"], [1180.0, "manhole"], [1400.0, "news"], [1650.0, "barrel"], [2000.0, "kiosk"], [780.0, "hydrant"]],
		"city_hall": [[620.0, "booth"], [900.0, "mail"], [1100.0, "cop_car"], [1280.0, "barrel"], [1400.0, "kiosk"], [1540.0, "manhole"], [760.0, "news"]],
		"invoice_pier": [[1100.0, "kiosk"], [1300.0, "manhole"], [1500.0, "hydrant"], [1700.0, "barrel"], [2000.0, "booth"], [880.0, "mail"]],
		"processing_floor": [[800.0, "fridge"], [1000.0, "manhole"], [1200.0, "vending"], [1500.0, "barrel"], [1800.0, "kiosk"], [640.0, "news"]],
		"tutorial_alley": [[780.0, "booth"]],
		"intake_lot": [[700.0, "dumpster"], [1000.0, "manhole"], [1200.0, "news"], [1400.0, "barrel"], [1600.0, "fridge"], [860.0, "hydrant"]],
		"group_circle": [[900.0, "kiosk"], [1100.0, "barrel"], [1300.0, "mail"], [1500.0, "manhole"], [720.0, "news"]],
		"waiting_room": [[1000.0, "booth"], [1200.0, "manhole"], [1400.0, "vending"], [1600.0, "barrel"], [1800.0, "fridge"], [860.0, "mail"]],
		"copay_orchard": [[980.0, "dumpster"], [1200.0, "manhole"], [1400.0, "hydrant"], [1600.0, "barrel"], [1880.0, "kiosk"], [760.0, "mail"]],
		"sleet_hour": [[860.0, "booth"], [1100.0, "barrel"], [1300.0, "mail"], [1500.0, "manhole"], [1700.0, "fridge"], [980.0, "news"]],
		"raven_grid": [[640.0, "booth"], [820.0, "hydrant"], [980.0, "cop_car"], [1120.0, "barrel"], [1280.0, "billboard"], [1500.0, "mail"], [1760.0, "kiosk"], [1880.0, "manhole"], [2040.0, "news"]],
		"ledger_dive": [[880.0, "fridge"], [1100.0, "manhole"], [1400.0, "vending"], [1600.0, "barrel"], [1900.0, "kiosk"], [720.0, "mail"]]
	}
	var list: Variant = rows.get(map_id, [])
	if typeof(list) != TYPE_ARRAY:
		return
	var placed: Array = []
	for row in list:
		if typeof(row) != TYPE_ARRAY or (row as Array).size() < 2:
			continue
		var x := float(row[0])
		if map_id == "raven_grid" and x > 2200.0:
			continue
		var sp := SmashProp.place(self, Vector2(x, 500.0), str(row[1]))
		placed.append(sp)
	# One adrenaline syringe per street, inside one of the breakables.
	if not placed.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(map_id)
		var first := rng.randi() % placed.size()
		(placed[first] as Node).set_meta("syringe", true)
		if Charms.has("moms_ring") and placed.size() > 1:
			(placed[(first + 1 + rng.randi() % (placed.size() - 1)) % placed.size()] as Node).set_meta("syringe", true)
	_place_weapons()
	_place_life()


func _place_weapons() -> void:
	var rows: Dictionary = {
		"dock_street": [[900.0, 500.0, "chain"]],
		"intake_lot": [[760.0, 500.0, "crowbar"]],
		"fire_escapes": [[860.0, 248.0, "stapler"]],
		"group_circle": [[1180.0, 500.0, "clipboard"]],
		"neon_exchange": [[1480.0, 248.0, "nailgun"]],
		"waiting_room": [[1320.0, 500.0, "chain"]],
		"rail_bridge": [[1220.0, 500.0, "clipboard"]],
		"city_hall": [[1040.0, 500.0, "nailgun"]],
		"copay_orchard": [[640.0, 500.0, "crowbar"]],
		"sleet_hour": [[980.0, 500.0, "stapler"]],
		"raven_grid": [[1100.0, 500.0, "nailgun"]],
		"ledger_dive": [[1240.0, 500.0, "chain"]],
		"invoice_pier": [[1560.0, 500.0, "crowbar"]],
		"processing_floor": [[880.0, 500.0, "clipboard"]]
	}
	var list: Variant = rows.get(map_id, [])
	if typeof(list) != TYPE_ARRAY:
		return
	for row in list:
		if typeof(row) != TYPE_ARRAY or (row as Array).size() < 3:
			continue
		var x := float(row[0])
		if map_id == "raven_grid" and x > 2200.0:
			continue
		var wp := WeaponPickup.new()
		wp.kind = str(row[2])
		wp.global_position = Vector2(x, float(row[1]))
		add_child(wp)


func _place_life() -> void:
	NightStreet.wind(self, map_w * 0.5)
	var crowd: Array = [
		Vector2(480, 500), Vector2(1560, 500), Vector2(2140, 500)
	]
	match map_id:
		"fire_escapes":
			crowd = [Vector2(480, 248), Vector2(1680, 500)]
		"raven_grid":
			crowd = [Vector2(520, 500), Vector2(1180, 500), Vector2(1980, 500)]
		"tutorial_alley":
			crowd = [Vector2(520, 500)]
	for at in crowd:
		if map_id == "raven_grid" and at.x > 2100.0:
			continue
		Bystander.place(self, at)
	if map_id == "neon_exchange":
		NightStreet.neon(self, Vector2(480, 120), "CASH ONLY FEELINGS  ·  STILL OPEN", Palette.LEMON)
	elif map_id == "dock_street":
		NightStreet.neon(self, Vector2(1680, 120), "AFTER HOURS  ·  THE CLIPBOARD NEVER CLOCKS OUT", Palette.BRICK)
	elif map_id == "city_hall":
		NightStreet.neon(self, Vector2(240, 120), "EVICTION PROCESSED HERE", Palette.EDGE)


## Spray cans, Rufus the dog, photo mode and tonight's bounty.
func _place_extras() -> void:
	SprayCan.place_all(self, map_id)
	add_child(PhotoMode.new())
	if DogBuddy.joined():
		var dog := DogBuddy.new()
		dog.position = spawn_at + Vector2(-30, 6)
		add_child(dog)
	elif map_id == "dock_street":
		var stray := StrayDog.new()
		stray.position = Vector2(1320, 494)
		add_child(stray)
	get_tree().create_timer(3.0).timeout.connect(_pick_bounty)


## One ordinary thug per street is WANTED: tougher, crowned, and worth
## gems and gold when he drops.
func _pick_bounty() -> void:
	if not is_inside_tree() or get_tree().get_first_node_in_group("bounty"):
		return
	var pool: Array = []
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and not (n is ActBoss) and is_instance_valid(n) and (n as Punk).hp > 0:
			pool.append(n)
	if pool.is_empty():
		get_tree().create_timer(4.0).timeout.connect(_pick_bounty)
		return
	var p := pool[randi() % pool.size()] as Punk
	p.add_to_group("bounty")
	p.max_hp = int(round(float(p.max_hp) * 1.6))
	p.hp = p.max_hp
	var crown := Polygon2D.new()
	crown.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(-8, -6), Vector2(-4, -2), Vector2(0, -8), Vector2(4, -2), Vector2(8, -6), Vector2(8, 0)])
	crown.color = UiKit.GOLD
	crown.position = Vector2(0, -52)
	var cm := CanvasItemMaterial.new()
	cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	crown.material = cm
	p.add_child(crown)
	var tw := crown.create_tween().set_loops()
	tw.tween_property(crown, "position:y", -55.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(crown, "position:y", -52.0, 0.5).set_trans(Tween.TRANS_SINE)
	Juice.toast("challenge", "WANTED: %s" % p.title.to_upper(), "The crowned one. 2 gems and 40 gold on his head.")
	p.died.connect(func() -> void:
		FamilyProfile.add_gems(2)
		FamilyProfile.add_gold(40)
		Juice.unlock_logo("BOUNTY CLAIMED", "%s won't collect anything again." % p.title, "+2 GEMS  ·  +40 GOLD")
	)


func _place_towers() -> void:
	ViewpointTower.place(self, map_id)


func _place_secrets() -> void:
	SecretStash.place(self, map_id)


func boss_filed() -> bool:
	return _boss_down


## A crew member waiting in an impound cage on this map (data/story.json
## acts.<map>.rescue), until the family breaks them out once.
func _place_rescue() -> void:
	var r := StoryBook.rescue(map_id)
	if r.is_empty():
		return
	var who := str(r.get("who", ""))
	if who == "" or StoryBook.has_crew(who):
		return
	var cage := RescueCage.new()
	cage.who = who
	var v: Variant = r.get("lines", [])
	cage.lines = v if v is Array else []
	cage.position = Vector2(float(r.get("x", spawn_at.x + 600.0)), 498.0)
	add_child(cage)


func _ready() -> void:
	_configure()
	if App.resume_map == map_id and App.resume_pos != Vector2.ZERO:
		spawn_at = App.resume_pos
	App.resume_map = ""
	_save_resume(spawn_at, false)
	add_to_group("dock_world")
	add_to_group("run_act")
	_state = RunState.new()
	_state.add_to_group("run_state")
	_state.checkpoint = spawn_at
	_state.run_failed.connect(_on_fail)
	_state.gate_reached.connect(_on_gate)
	_state.run_cleared.connect(_on_clear)
	_state.wanted_changed.connect(_on_wanted)
	add_child(_state)
	if not App.run_bag.is_empty():
		_state.unpack(App.run_bag)
	build_world()
	_place_parkour()
	_place_rescue()
	_rig = LightRig.new()
	_rig.preset = light_preset
	add_child(_rig)
	add_child(SnapDirector.new())
	add_child(DuoDirector.new())
	add_child(BloodSim.new())
	Mixer.play_music(music)
	var party: Dictionary = Party.spawn(self, spawn_at)
	_son = party.get("son") as Fighter
	_dad = party.get("dad") as Fighter
	if roof_start:
		for f in [_son, _dad]:
			if f:
				f.plane = "roof"
				f._enter_roof()
	NetSession.bind_run(_son, _dad)
	for row in Party.encounters(map_id):
		Party.spawn_row(self, row, _state.hp_mul())
	_cam = CouchCamera.new()
	_cam.limit_right = int(map_w)
	_cam.targets = _targets()
	add_child(_cam)
	var hud_script := preload("res://src/ui/run_hud.gd")
	_hud = hud_script.new()
	add_child(_hud)
	_hud.bind(_son, _dad, _state)
	if DisplayServer.is_touchscreen_available():
		add_child(preload("res://src/ui/touch_hud.gd").new())
	_state.need_cards.connect(_cards)
	PadRouter.drop_in.connect(_on_dropin)
	var body := toast_body
	if body == "":
		body = Copy.COUCH_HINT if App.density_coop else Copy.SOLO_HINT
	Juice.toast("quest", toast_title, body)
	_boot_story()


func _targets() -> Array[Node2D]:
	var t: Array[Node2D] = []
	if _son:
		t.append(_son)
	if _dad:
		t.append(_dad)
	return t


func _process(_delta: float) -> void:
	if _join_grace > 0:
		_join_grace -= 1
	if _state.failed or _state.cleared or _state.gated:
		return
	if _dad == null and Input.is_action_just_pressed("p2_pause") and not App.remote_coop:
		_on_dropin(-1)
		return
	var lead_x := -9999.0
	for f in [_son, _dad]:
		if f and is_instance_valid(f):
			lead_x = maxf(lead_x, f.global_position.x)
	_tick_talk(lead_x)
	_tick_boss_intro(lead_x)
	if check_x > 0.0 and lead_x > check_x:
		var cp := check_pos if check_pos != Vector2.ZERO else Vector2(check_x, spawn_at.y)
		if _state.checkpoint != cp:
			_save_resume(cp, true)
		_state.mark_checkpoint(cp)
	if win_mode == "boss":
		return
	if _boss_down and next_id != "":
		_state.reach_gate()
		return
	if _boss_down:
		_state.clear_run()
		return
	if Party.all_past(goal_x) and _boss_down:
		if next_id != "":
			_state.reach_gate()
		else:
			_state.clear_run()


func _cards() -> void:
	if get_node_or_null("CardPick") or get_node_or_null("LevelUpFx"):
		return
	# Glow, LEVEL UP over the heads and the force wave first; then the cards.
	var fighters: Array = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			fighters.append(n)
	var fx := LevelUpFx.play(self, fighters)
	fx.name = "LevelUpFx"
	await fx.done
	if not is_inside_tree():
		return
	var pick := CardPick.new()
	pick.name = "CardPick"
	if _state.level_ups >= 2 or _state.card_reroll:
		var pool: Array = []
		var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
		for c in table:
			if not bool(c.get("fixed", false)) and not _state.cards.has(c["id"]):
				pool.append(c["id"])
		pool.shuffle()
		pick.ids = pool.slice(0, 3)
		_state.card_reroll = false
	add_child(pick)
	pick.picked.connect(func(id: String) -> void:
		_state.take_card(id)
	)


func _on_dropin(device: int) -> void:
	if App.remote_coop:
		return
	if _son != null and _dad != null:
		return
	var near := spawn_at
	if _son:
		near = _son.global_position
	elif _dad:
		near = _dad.global_position
	var born := Party.join_missing(self, near)
	if born == null:
		return
	if born.role == "son":
		_son = born
	else:
		_dad = born
	if roof_start:
		born.plane = "roof"
		born._enter_roof()
	_cam.targets = _targets()
	_hud.bind(_son, _dad, _state)
	_join_grace = 18
	var who := "PAD %d" % (device + 1) if device >= 0 else "KEYBOARD"
	Juice.unlock_logo("DROP-IN", "%s sat down. Punks were not restocked." % who)
	Juice.pulse_shake(4.0)


func _on_wanted() -> void:
	var at := Vector2(spawn_at.x + 400.0, 500.0)
	if _cam:
		at.x = _cam.global_position.x + 280.0
	if map_id == "raven_grid":
		at.x = minf(at.x, 2000.0)
	Juice.siren()
	if _state.wanted >= 1 and not _meter_maid:
		_meter_maid = true
		Party.spawn_row(self, {
			"title": "Meter Maid", "x": at.x - 40.0, "y": 500, "home": "street",
			"hp": 36, "pmin": at.x - 180.0, "pmax": at.x + 220.0, "cop": true
		}, _state.hp_mul())
		Juice.toast("challenge", Copy.METER_MAID, "Wanted 1. A scooter with a citation. Not in the seed roster.")
	if _state.wanted >= 2 and not _phone_ghost:
		_phone_ghost = true
		Party.spawn_row(self, {
			"title": "Phone Ghost", "x": at.x, "y": 430, "home": "air",
			"hp": 34, "pmin": at.x - 180.0, "pmax": at.x + 240.0
		}, _state.hp_mul())
		Juice.toast("challenge", "WANTED 2", "A ringtone with a stapler. Not in the seed roster.")
	if _state.wanted >= 3 and not _wanted_cop:
		_wanted_cop = true
		Party.spawn_row(self, {
			"title": "Beat Cop", "x": at.x + 40.0, "y": 500, "home": "street",
			"hp": 48, "pmin": at.x - 160.0, "pmax": at.x + 220.0, "cop": true
		}, _state.hp_mul())
		Juice.toast("challenge", "WANTED 3", "A patrol heard the feelings.")
	if _state.wanted >= 4 and not _dumpster_king:
		_dumpster_king = true
		Party.spawn_row(self, {
			"title": "Dumpster King", "x": at.x + 80.0, "y": 500, "home": "street",
			"hp": 86, "pmin": at.x - 140.0, "pmax": at.x + 260.0
		}, _state.hp_mul())
		Juice.toast("challenge", "WANTED 4", "The dumpster learned parkour.")
	if _state.wanted >= 5 and _heli == null:
		_heli = NightStreet.heli(self, map_w)
		Juice.toast("challenge", "WANTED 5", "Spotlight. Hide under a ledge or eat it.")


## Save to continue later: the map and where to stand. CONTINUE on the title
## screen drops you back here.
func _save_resume(at: Vector2, announce: bool) -> void:
	if App.remote_coop or App.versus:
		return
	FamilyProfile.data["resume"] = {"map": map_id, "x": at.x, "y": at.y}
	FamilyProfile.save()
	if announce:
		Juice.toast("quest", "GAME SAVED", "Checkpoint. CONTINUE starts here.")


func _clear_resume() -> void:
	FamilyProfile.data.erase("resume")
	FamilyProfile.save()


func _on_fail() -> void:
	_clear_resume()
	FamilyProfile.mark_run_finished(false)
	var g := 0
	if _state:
		FamilyProfile.note_score(_state.score_total)
		g = FamilyProfile.cash_fail(_state.scrap, _state.score_total)
	_banner(Copy.FAIL, fail_sub if fail_sub != "" else Copy.FAIL_GOLD, false, false, g)
	if _end is ResultsSheet:
		(_end as ResultsSheet).death_line = DeathCause.for_run(get_tree())


func _on_gate() -> void:
	# Filed: CONTINUE picks up at the start of the next street.
	if next_id != "":
		FamilyProfile.data["resume"] = {"map": next_id, "x": 0.0, "y": 0.0}
		FamilyProfile.save()
	if _missions:
		_missions.complete_main()
	match map_id:
		"city_hall":
			FamilyProfile.mark_city_clear()
		"intake_lot", "group_circle", "waiting_room", "sleet_hour", "ledger_dive":
			FamilyProfile.mark_survive(map_id)
		"invoice_pier":
			FamilyProfile.mark_annex()
	FamilyProfile.mark_map_filed(map_id)
	if _state:
		FamilyProfile.note_score(_state.score_total)
	Juice.toast("quest", "CHECKPOINT", gate_sub)
	_banner(clear_title, gate_sub, true, true)


func _on_clear() -> void:
	_clear_resume()
	FamilyProfile.mark_run_finished(true)
	FamilyProfile.mark_map_filed(map_id)
	if App.is_solo_density():
		FamilyProfile.mark_solo_clear()
	if map_id == "city_hall":
		FamilyProfile.mark_city_clear()
	if map_id == "invoice_pier":
		FamilyProfile.mark_annex()
	if map_id == "processing_floor":
		FamilyProfile.mark_family_plan()
	if map_id in ["intake_lot", "group_circle", "waiting_room", "sleet_hour", "ledger_dive"]:
		FamilyProfile.mark_survive(map_id)
	if App.remote_coop:
		FamilyProfile.mark_remote_clear()
	if _missions:
		_missions.complete_main()
	if _state:
		FamilyProfile.note_score(_state.score_total)
	FamilyProfile.push_log(clear_title, clear_sub)
	_banner(clear_title, clear_sub, true, false)


func finish_boss() -> void:
	if _boss_down:
		return
	_boss_down = true
	if _missions:
		_missions.complete_main()
	if next_id != "":
		_state.reach_gate()
	else:
		_state.clear_run()


func on_mini_down() -> void:
	_mini_down = true
	Juice.toast("quest", "LATER CONTENT", "Mini filed. The rest of the act still wants a conversation.")


func _boot_story() -> void:
	_talk = Talk.new()
	add_child(_talk)
	_missions = MissionHud.new()
	_missions.add_to_group("mission_hud")
	add_child(_missions)
	_missions.bind(map_id)
	var row := StoryBook.act(map_id)
	if row.is_empty():
		return
	if not bool(row.get("survive", false)) and not _skip_story_boss:
		_spawn_story_unit(true)
		var boss: Variant = row.get("boss", {})
		var boss_lock := PowerBook.lock(map_id, "boss")
		if not boss_lock.is_empty():
			var bx := float((boss as Dictionary).get("x", spawn_at.x + 1800.0)) if typeof(boss) == TYPE_DICTIONARY else spawn_at.x + 1800.0
			PowerGate.place(self, Vector2(bx, 500.0), PowerBook.line(boss_lock))
			Juice.toast("challenge", "LOCKED", PowerBook.line(boss_lock))
		elif typeof(boss) == TYPE_DICTIONARY and str((boss as Dictionary).get("kind", "")) not in ["mayor_raven", "family_plan"] and not defer_final_boss:
			_spawn_story_unit(false)
	var talks: Variant = row.get("talk", [])
	if typeof(talks) == TYPE_ARRAY and (talks as Array).size() > 0:
		var first: Variant = (talks as Array)[0]
		if typeof(first) == TYPE_DICTIONARY and float((first as Dictionary).get("at", 0)) <= 0.0:
			_talked[0] = true
			_talk.play((first as Dictionary).get("lines", []) as Array)


func _spawn_story_unit(mini: bool) -> void:
	var row := StoryBook.act(map_id)
	var key := "miniboss" if mini else "boss"
	var spec: Variant = row.get(key, {})
	if typeof(spec) != TYPE_DICTIONARY or spec.is_empty():
		return
	var d: Dictionary = spec
	if str(d.get("kind", "")) in ["mayor_raven", "family_plan"]:
		return
	if str(d.get("kind", "")) == "skinwalker":
		_spawn_skinwalker(d, mini)
		return
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	var x := float(d.get("x", spawn_at.x + 800.0))
	if StoryBook.is_survive(map_id) and cam:
		x = cam.global_position.x + (280.0 if mini else 340.0)
	var unit := ActBoss.new()
	unit.title = str(d.get("title", "Named Problem"))
	unit.display = unit.title
	unit.is_mini = mini
	unit.sub = str(d.get("sub", ""))
	unit.home = str(d.get("home", "street"))
	unit.hp = int(round(float(d.get("hp", 100)) * _state.hp_mul()))
	unit.patrol_min = float(d.get("pmin", x - 160.0))
	unit.patrol_max = float(d.get("pmax", x + 160.0))
	unit.speed = 34.0 if not mini else 40.0
	unit.armored = not mini
	unit.global_position = Vector2(x, float(d.get("y", 500.0)))
	unit.accent = Palette.EDGE if mini else Palette.BRICK
	add_child(unit)


func _spawn_skinwalker(d: Dictionary, mini: bool) -> void:
	var existing := get_tree().get_first_node_in_group("skinwalker")
	if existing and existing.has_method("wake"):
		var was_awake := false
		if existing is Skinwalker:
			was_awake = (existing as Skinwalker)._woke
		existing.wake()
		if existing is Skinwalker and not was_awake:
			var sw: Skinwalker = existing
			sw.hp = int(round(float(d.get("hp", 128)) * _state.hp_mul()))
			sw.max_hp = sw.hp
		return
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	var x := float(d.get("x", spawn_at.x + 800.0))
	if StoryBook.is_survive(map_id) and cam:
		x = cam.global_position.x + (280.0 if mini else 340.0)
	var unit := Skinwalker.new()
	unit.title = str(d.get("title", "Skinwalker"))
	unit.display = unit.title
	unit.is_mini = mini
	unit.sub = str(d.get("sub", "THAT"))
	unit.home = str(d.get("home", "street"))
	unit.patrol_min = float(d.get("pmin", x - 180.0))
	unit.patrol_max = float(d.get("pmax", x + 180.0))
	unit.global_position = Vector2(x, float(d.get("y", 500.0)))
	unit.dormant = false
	add_child(unit)
	unit.hp = int(round(float(d.get("hp", 128)) * _state.hp_mul()))
	unit.max_hp = unit.hp
	unit.wake()


func _tick_talk(lead_x: float) -> void:
	if _talk and _talk.busy():
		return
	var talks: Variant = StoryBook.act(map_id).get("talk", [])
	if typeof(talks) != TYPE_ARRAY:
		return
	var idx := 0
	for item in talks:
		idx += 1
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var at := float((item as Dictionary).get("at", 0))
		if at <= 0.0:
			continue
		if _talked.get(idx, false):
			continue
		if lead_x >= at:
			_talked[idx] = true
			_talk.play((item as Dictionary).get("lines", []) as Array)
			return


func _tick_boss_intro(lead_x: float) -> void:
	for n in get_tree().get_nodes_in_group("act_boss"):
		if not (n is Node2D) or not is_instance_valid(n):
			continue
		if bool(n.get_meta("introed", false)):
			continue
		var boss := n as Node2D
		if absf(boss.global_position.x - lead_x) > 320.0:
			continue
		n.set_meta("introed", true)
		var title := "BOSS"
		var sub := ""
		var full := true
		var accent := Palette.BRICK
		if n is ActBoss:
			var ab: ActBoss = n
			title = ab.title
			sub = ab.sub
			full = not ab.is_mini
			accent = ab.accent
		elif n is MayorRaven:
			title = "Mayor Raven"
			sub = "LANDLORD · NINJA · INVOICE"
			full = true
			accent = Color(0.12, 0.1, 0.14)
		elif n is FamilyPlan:
			title = "The Family Plan"
			sub = "DIRECTOR BINDER · BILLING MECH"
			full = true
			accent = Palette.EDGE
		BossCard.present(self, title, sub, accent, full)


func _banner(title: String, sub: String, win: bool, gate: bool, gold_n: int = 0) -> void:
	if _end and is_instance_valid(_end):
		return
	var sheet := ResultsSheet.new()
	sheet.headline = title
	sheet.sub = sub
	sheet.win = win
	sheet.gate = gate
	sheet.next_id = next_id
	sheet.next_label = next_label if next_label != "" else Copy.NEXT_MAP
	sheet.state = _state
	sheet.fail_gold = gold_n
	if gate and next_id != "":
		var enter_lock := PowerBook.lock(next_id, "enter")
		if not enter_lock.is_empty():
			sheet.lock_line = PowerBook.line(enter_lock)
	add_child(sheet)
	_end = sheet


func lock_boss_card(line: String) -> void:
	if get_node_or_null("LockCard"):
		return
	var layer := CanvasLayer.new()
	layer.name = "LockCard"
	layer.layer = 50
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	get_tree().paused = true
	var ui := PixelStage.attach_canvas(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.BRICK))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -280
	card.offset_right = 280
	card.offset_top = -140
	card.offset_bottom = 140
	ui.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	col.add_child(UiKit.portrait(SpriteBook.icon("therapy_couch"), Vector2(56, 56)))
	var t := Label.new()
	t.text = line
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(t, 22, Palette.LEMON)
	col.add_child(t)
	var back := UiKit.button("BACK TO THE CLINIC", Vector2(280, 48))
	back.process_mode = Node.PROCESS_MODE_ALWAYS
	back.pressed.connect(func() -> void:
		get_tree().paused = false
		layer.queue_free()
		if not _state.failed:
			_state.failed = true
			_state.run_failed.emit()
	)
	col.add_child(back)
	var stay := UiKit.button(Copy.KEEP_SMASHING, Vector2(280, 44))
	stay.process_mode = Node.PROCESS_MODE_ALWAYS
	stay.pressed.connect(func() -> void:
		get_tree().paused = false
		layer.queue_free()
	)
	col.add_child(stay)
	back.grab_focus()


func spawn_deferred_boss() -> void:
	_spawn_story_unit(false)


func fire_escape(at_x: float, top_y: float = 248.0, bottom: float = 500.0) -> void:
	var fe := FireEscape.new()
	fe.configure(at_x, top_y, bottom)
	add_child(fe)


func anchor(at: Vector2) -> void:
	var a := WebAnchor.new()
	a.position = at
	add_child(a)
