extends RunAct

## The dojo floor: a lit back-alley mat, one sparring dummy, and the combo
## board. Every learned combo is listed with its buttons; the beat ring and
## the next input show on the fighter while a chain is live; a combo lights up
## on the board once landed (gold when every beat was perfect). Toggle SPAR
## and the dummy starts throwing high / mid / low strikes for guard drills.
## No enemies, no lives, no timer. Leave with Back / Select or the button.

var _dummy: TrainingDummy
var _board: DojoBoard
var _keep_role := ""


func _configure() -> void:
	map_id = "dojo_practice"
	map_w = 1400.0
	spawn_at = Vector2(640, 490)
	goal_x = 99999.0
	light_preset = "dock_street"
	toast_title = "DOJO"
	toast_body = "Combos on the dummy. The ring on your body is the beat: press as it closes."
	win_mode = "boss"
	music = "res://assets/audio/music_street.wav"
	# Practice as whoever the dojo sheet picked; the run's choice comes back
	# when you leave.
	_keep_role = App.solo_role
	if App.has_meta("dojo_role"):
		App.solo_role = str(App.get_meta("dojo_role"))


func build_world() -> void:
	NightStreet.parallax(self, map_w, "tutorial")
	NightStreet.wet_floor(self, map_w, true)
	NightStreet.pixel_dock(self, map_w, false)
	NightStreet.bounds(self, map_w)
	AmbientProp.lamp(self, Vector2(560.0, 500.0), 3)
	AmbientProp.lamp(self, Vector2(1060.0, 500.0), 3)
	_mat()
	_dummy = TrainingDummy.new()
	_dummy.home = "street"
	_dummy.global_position = Vector2(820, 492)
	add_child(_dummy)


## No props, thugs, toys or bounties on the mat.
func _place_parkour() -> void:
	pass


func _place_rescue() -> void:
	pass


## Chalk marks on the wet asphalt where the mat would be: two taped
## starting lines, under everyone (the street itself stays visible).
func _mat() -> void:
	for x in [660.0, 980.0]:
		var tape := Line2D.new()
		tape.points = PackedVector2Array([Vector2(x, 462), Vector2(x - 14.0, 520)])
		tape.width = 2.0
		tape.default_color = Color(0.86, 0.72, 0.3, 0.5)
		tape.z_index = 0
		add_child(tape)


func _ready() -> void:
	super._ready()
	for f in [_son, _dad]:
		if f != null and f.combo_ring != null:
			f.combo_ring.show_next = true
	_board = DojoBoard.new()
	add_child(_board)
	_board.bind(self, _son if _son != null else _dad, _dummy)
	_board.leave.connect(_leave)
	_board.spar_toggled.connect(func(on: bool) -> void:
		_dummy.mode = "spar" if on else "still"
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK:
		_leave()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE:
		_leave()


func _leave() -> void:
	get_tree().paused = false
	if _keep_role != "":
		App.solo_role = _keep_role
	FamilyProfile.save()
	App.enter_map("camp")
