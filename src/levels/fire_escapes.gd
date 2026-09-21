extends Node2D

const MAP_W := 2800.0
const ROOF_Y := 248.0
const HIGH_Y := 208.0
const GOAL_X := 2620.0

var _son: Fighter
var _dad: Fighter
var _state: RunState
var _hud: CanvasLayer
var _cam: CouchCamera
var _end: Control
var _join_grace := 0


func _ready() -> void:
	add_to_group("dock_world")
	_state = RunState.new()
	_state.add_to_group("run_state")
	_state.checkpoint = Vector2(220, 248)
	_state.run_failed.connect(_on_fail)
	_state.run_cleared.connect(_on_clear)
	add_child(_state)
	if not App.run_bag.is_empty():
		_state.unpack(App.run_bag)
	_world()
	var rig := LightRig.new()
	rig.preset = "fire_escapes"
	add_child(rig)
	add_child(SnapDirector.new())
	add_child(DuoDirector.new())
	add_child(BloodSim.new())
	Mixer.play_music("res://assets/audio/music_street.wav")

	var party: Dictionary = Party.spawn(self, Vector2(220, 248))
	_son = party.get("son") as Fighter
	_dad = party.get("dad") as Fighter
	for f in [_son, _dad]:
		if f:
			f.plane = "roof"
			f._enter_roof()
	for row in Party.encounters("fire_escapes"):
		Party.spawn_row(self, row, _state.hp_mul())

	_cam = CouchCamera.new()
	_cam.limit_right = int(MAP_W)
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
	var vendor := RoofVendor.new()
	vendor.global_position = Vector2(2520, 208)
	add_child(vendor)
	Juice.toast("quest", "FIRE ESCAPES", "Roofs. Gaps. A man selling opinions.")


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
	if _state.failed or _state.cleared:
		return
	if _dad == null and Input.is_action_just_pressed("p2_pause"):
		_on_dropin(-1)
		return
	var lead_x := -9999.0
	for f in [_son, _dad]:
		if f and is_instance_valid(f):
			lead_x = maxf(lead_x, f.global_position.x)
	if lead_x > 2400.0:
		_state.mark_checkpoint(Vector2(2400, 208))
	if Party.all_past(GOAL_X):
		_state.clear_run()


func _world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, MAP_W, 720), Color(0.06, 0.07, 0.12), -8)
	sky.z_index = -8
	NightStreet.parallax(self, MAP_W)
	NightStreet.wet_floor(self, MAP_W)

	NightStreet.tenement(self, Rect2(40, 40, 280, 210), Color(0.13, 0.1, 0.12))
	NightStreet.tenement(self, Rect2(420, 20, 300, 190), Color(0.15, 0.1, 0.13))
	NightStreet.tenement(self, Rect2(880, 10, 260, 200), Color(0.14, 0.11, 0.14))
	NightStreet.tenement(self, Rect2(1480, 8, 320, 200), Color(0.16, 0.1, 0.12))
	NightStreet.tenement(self, Rect2(2100, 30, 280, 180), Color(0.13, 0.11, 0.13))
	NightStreet.tenement(self, Rect2(2520, 50, 240, 160), Color(0.12, 0.16, 0.14))

	Blockout.solid(self, Rect2(0, ROOF_Y, 520, 22), true)
	Blockout.poly(self, Rect2(0, ROOF_Y, 520, 22), Color(0.22, 0.18, 0.2), 2)
	Blockout.solid(self, Rect2(700, ROOF_Y, 420, 22), true)
	Blockout.poly(self, Rect2(700, ROOF_Y, 420, 22), Color(0.22, 0.18, 0.2), 2)
	Blockout.solid(self, Rect2(1280, HIGH_Y, 380, 22), true)
	Blockout.poly(self, Rect2(1280, HIGH_Y, 380, 22), Color(0.24, 0.19, 0.2), 2)
	Blockout.solid(self, Rect2(1840, ROOF_Y, 360, 22), true)
	Blockout.poly(self, Rect2(1840, ROOF_Y, 360, 22), Color(0.22, 0.18, 0.2), 2)
	Blockout.solid(self, Rect2(2360, HIGH_Y, 440, 22), true)
	Blockout.poly(self, Rect2(2360, HIGH_Y, 440, 22), Color(0.22, 0.2, 0.18), 2)

	var wall := Blockout.solid(self, Rect2(1164, 90, 18, 130), false)
	wall.add_to_group("metal")
	Blockout.poly(self, Rect2(1164, 90, 18, 130), Color(0.3, 0.22, 0.2), 3)

	_fire_escape(360.0)
	_fire_escape(900.0)
	_fire_escape(1960.0)
	_fire_escape(2400.0)

	var c1 := VaultCrate.new()
	c1.global_position = Vector2(480, 500)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(1680, 500)
	add_child(c2)

	_anchor(Vector2(480, 64))
	_anchor(Vector2(980, 48))
	_anchor(Vector2(1500, 40))
	_anchor(Vector2(2100, 70))
	_anchor(Vector2(2580, 44))

	NightStreet.bounds(self, MAP_W)

	var sign := Label.new()
	sign.text = "THE FIRE ESCAPES  ·  RAVEN WHARF"
	sign.position = Vector2(80, 110)
	UiKit.apply_label(sign, 20, Palette.EDGE)
	add_child(sign)
	var gap := Label.new()
	gap.text = "GAP  ·  GLIDE, WEB, OR FALL AND JOKE ABOUT IT"
	gap.position = Vector2(530, 210)
	UiKit.apply_label(gap, 13, Palette.MUTED)
	add_child(gap)
	var high := Label.new()
	high.text = "HIGH LEDGE  ·  WALL-RUN THE PIPE"
	high.position = Vector2(1320, 170)
	UiKit.apply_label(high, 13, Palette.MUTED)
	add_child(high)
	var shop := Label.new()
	shop.text = "ROOF VENDOR  ·  AMMO AND A SECOND OPINION"
	shop.position = Vector2(2380, 120)
	UiKit.apply_label(shop, 16, Palette.EDGE)
	add_child(shop)
	Blockout.add_glow(shop)
	NightStreet.rain(self, 1400.0)


func _fire_escape(at_x: float) -> void:
	var fe := FireEscape.new()
	fe.configure(at_x, ROOF_Y if at_x < 2300.0 else HIGH_Y, 500.0)
	add_child(fe)


func _anchor(at: Vector2) -> void:
	var a := WebAnchor.new()
	a.position = at
	add_child(a)


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
	if _son != null and _dad != null:
		return
	var near := Vector2(220, 248)
	if _son:
		near = _son.global_position
	elif _dad:
		near = _dad.global_position
	var born := Party.join_missing(self, near)
	if born == null:
		return
	if born.role == "son":
		_son = born
		_son.plane = "roof"
		_son._enter_roof()
	else:
		_dad = born
		_dad.plane = "roof"
		_dad._enter_roof()
	_cam.targets = _targets()
	_hud.bind(_son, _dad, _state)
	_join_grace = 18
	var who := "PAD %d" % (device + 1) if device >= 0 else "KEYBOARD"
	Juice.unlock_logo("DROP-IN", "%s sat down. Punks were not restocked." % who)
	Juice.pulse_shake(4.0)


func _on_fail() -> void:
	FamilyProfile.mark_run_finished(false)
	_banner(Copy.FAIL, "Shared lives. Solo or not, three stamps and you are out.", false)


func _on_clear() -> void:
	FamilyProfile.mark_run_finished(true)
	if App.is_solo_density():
		FamilyProfile.mark_solo_clear()
	FamilyProfile.push_log("FIRE ESCAPES", "You filed the roofs. The vendor still wants a tip.")
	_banner(Copy.FIRE_CLEAR, Copy.FIRE_SUB, true)


func _banner(title: String, sub: String, win: bool) -> void:
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
	col.position = Vector2(360, 200)
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
	var b := UiKit.button("BACK TO THE CLINIC", Vector2(280, 48))
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(func() -> void:
		get_tree().paused = false
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		App.back_to_hub("awards" if win else "clinic")
	)
	col.add_child(b)
	b.grab_focus()
	Juice.pulse_shake(8.0 if win else 5.0)
	if win:
		Juice.unlock_logo(title, sub)
