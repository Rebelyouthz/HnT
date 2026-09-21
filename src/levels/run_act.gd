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
var _end: Control
var _cam: CouchCamera
var _join_grace := 0
var _wanted_cop := false
var _heli: Node2D
var _rig: LightRig
var _talk: Talk
var _missions: MissionHud
var _talked: Dictionary = {}
var _mini_down := false
var _boss_down := false
var _skip_story_boss := false


func _configure() -> void:
	pass


func build_world() -> void:
	pass


func _ready() -> void:
	_configure()
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
		_state.mark_checkpoint(check_pos if check_pos != Vector2.ZERO else Vector2(check_x, spawn_at.y))
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
	if get_node_or_null("CardPick"):
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
	if _state.wanted >= 3 and not _wanted_cop:
		_wanted_cop = true
		var at := Vector2(spawn_at.x + 400.0, 500.0)
		if _cam:
			at.x = _cam.global_position.x + 280.0
		Party.spawn_row(self, {
			"title": "Beat Cop", "x": at.x, "y": 500, "home": "street",
			"hp": 48, "pmin": at.x - 160.0, "pmax": at.x + 220.0, "cop": true
		}, _state.hp_mul())
		Juice.toast("challenge", "WANTED 3", "A patrol heard the feelings.")
	if _state.wanted >= 5 and _heli == null:
		_heli = NightStreet.heli(self, map_w)
		Juice.toast("challenge", "WANTED 5", "Spotlight. Hide under a ledge or eat it.")


func _on_fail() -> void:
	FamilyProfile.mark_run_finished(false)
	_banner(Copy.FAIL, fail_sub, false, false)


func _on_gate() -> void:
	if _missions:
		_missions.complete_main()
	match map_id:
		"city_hall":
			FamilyProfile.mark_city_clear()
		"intake_lot", "group_circle", "waiting_room":
			FamilyProfile.mark_survive(map_id)
	Juice.toast("quest", "CHECKPOINT", gate_sub)
	_banner(clear_title, gate_sub, true, true)


func _on_clear() -> void:
	FamilyProfile.mark_run_finished(true)
	if App.is_solo_density():
		FamilyProfile.mark_solo_clear()
	if map_id == "city_hall":
		FamilyProfile.mark_city_clear()
	if map_id == "invoice_pier":
		FamilyProfile.mark_annex()
	if map_id in ["intake_lot", "group_circle", "waiting_room"]:
		FamilyProfile.mark_survive(map_id)
	if App.remote_coop:
		FamilyProfile.mark_remote_clear()
	if _missions:
		_missions.complete_main()
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
		if typeof(boss) == TYPE_DICTIONARY and str((boss as Dictionary).get("kind", "")) != "mayor_raven":
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
	if str(d.get("kind", "")) == "mayor_raven":
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
		BossCard.present(self, title, sub, accent, full)


func _banner(title: String, sub: String, win: bool, gate: bool) -> void:
	if _end and is_instance_valid(_end):
		return
	get_tree().paused = true
	var layer := CanvasLayer.new()
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_end = Control.new()
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_end)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.add_child(dim)
	var col := VBoxContainer.new()
	col.position = Vector2(360, 180)
	col.add_theme_constant_override("separation", 12)
	_end.add_child(col)
	var t := Label.new()
	t.text = title
	UiKit.apply_label(t, 32, Palette.LEMON if win else Palette.BRICK)
	col.add_child(t)
	var s := Label.new()
	s.text = sub
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(560, 0)
	UiKit.apply_label(s, 16, Palette.TEXT)
	col.add_child(s)
	if gate and next_id != "":
		var nxt := UiKit.button(next_label, Vector2(320, 52))
		nxt.process_mode = Node.PROCESS_MODE_ALWAYS
		nxt.pressed.connect(func() -> void:
			App.advance(next_id, _state)
		)
		col.add_child(nxt)
		nxt.grab_focus()
	var b := UiKit.button("BACK TO THE CLINIC", Vector2(280, 48))
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(func() -> void:
		get_tree().paused = false
		if win and not gate:
			pass
		elif win and gate:
			FamilyProfile.mark_run_finished(true)
			if App.is_solo_density():
				FamilyProfile.mark_solo_clear()
			FamilyProfile.push_log(clear_title, clear_sub)
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		if App.remote_coop:
			NetSession.shutdown()
		App.back_to_hub("awards" if win else "clinic")
	)
	col.add_child(b)
	if not gate:
		b.grab_focus()
	Juice.pulse_shake(8.0 if win else 5.0)
	if win:
		Juice.unlock_logo(title, sub)


func fire_escape(at_x: float, top_y: float = 248.0, bottom: float = 500.0) -> void:
	var fe := FireEscape.new()
	fe.configure(at_x, top_y, bottom)
	add_child(fe)


func anchor(at: Vector2) -> void:
	var a := WebAnchor.new()
	a.position = at
	add_child(a)
