extends Control

## CONTROLLER SETUP (Options -> Controls). For pads the game does not know
## (iPega PG-9777 in some modes, cheap Bluetooth pads): one prompt at a
## time, press that button or push that stick once on the pad you play
## with. The answer is stored for that pad (its GUID) in
## FamilyProfile.data["pad_maps"] and PadRouter binds it from then on.
## Raw input is read here directly, so it works even when the pad's
## buttons are all wrong in the menus. SPACE / A on another pad skips a step,
## ESC cancels, R (or holding Select on the pad) clears the pad's map.

signal closed

const STEPS := [
	["right", "Push the LEFT STICK to the RIGHT", "axis"],
	["down", "Push the LEFT STICK DOWN", "axis"],
	["jump", "Press JUMP  (the bottom face button, A / cross)", "button"],
	["light", "Press LIGHT ATTACK  (left face button, X / square)", "button"],
	["heavy", "Press HEAVY ATTACK  (top face button, Y / triangle)", "button"],
	["special", "Press SPECIAL / BACK  (right face button, B / circle)", "button"],
	["shoot", "Press SHOOT  (RIGHT BUMPER, R1 / RB)", "button"],
	["block", "Press BLOCK / SKILL 1  (LEFT BUMPER, L1 / LB)", "button"],
	["dash", "Press or pull DASH  (RIGHT TRIGGER, R2 / RT)", "any"],
	["throw", "Press or pull THROW / SKILL 2  (LEFT TRIGGER, L2 / LT)", "any"],
	["snap", "Press SNAP  (click the RIGHT STICK)", "button"],
	["duck", "Press DUCK  (click the LEFT STICK)", "button"],
	["pause", "Press PAUSE  (START / MENU)", "button"],
	["aim_x", "Push the RIGHT STICK to the RIGHT  (aim)", "axis"],
	["aim_y", "Push the RIGHT STICK DOWN  (aim)", "axis"],
]

var _step := 0
var _device := -1
var _map: Dictionary = {}
var _rest: Dictionary = {}
var _cool := 0.0
var _title: Label
var _prompt: Label
var _pad: Label
var _done: Label
var _bar: ProgressBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.LEMON, 0.4))
	card.position = Vector2(140, 90)
	card.size = Vector2(1000, 540)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	card.add_child(col)
	_title = UiKit.title("CONTROLLER SETUP", 30, Palette.LEMON)
	col.add_child(_title)
	_pad = Label.new()
	UiKit.apply_label(_pad, 16, Color(0.75, 0.78, 0.85))
	col.add_child(_pad)
	_prompt = Label.new()
	_prompt.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_prompt, 30, Palette.TEXT)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.custom_minimum_size = Vector2(940, 120)
	col.add_child(_prompt)
	_bar = ProgressBar.new()
	_bar.max_value = STEPS.size()
	_bar.custom_minimum_size = Vector2(940, 18)
	_bar.show_percentage = false
	col.add_child(_bar)
	_done = Label.new()
	_done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_done.custom_minimum_size = Vector2(940, 0)
	UiKit.apply_label(_done, 15, Color(0.45, 1.0, 0.6))
	col.add_child(_done)
	var help := Label.new()
	help.text = "SPACE skip this step  ·  R clear this pad's map  ·  ESC cancel\nUse the pad you want to play with. Hold each stick a moment, then let go."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(940, 0)
	UiKit.apply_label(help, 14, Color(0.6, 0.62, 0.7))
	col.add_child(help)
	UiKit.pop_in(card)
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		_prompt.text = "No controller found. Turn the pad on and pair it (Bluetooth), then open this again."
		_pad.text = ""
		_step = STEPS.size()
		return
	_cool = 0.4
	_show()


func _show() -> void:
	_bar.value = _step
	var lines: PackedStringArray = []
	for d in Input.get_connected_joypads():
		lines.append(PadCompat.describe(int(d)))
	_pad.text = "\n".join(lines)
	if _step >= STEPS.size():
		_finish()
		return
	_prompt.text = "%d / %d   %s" % [_step + 1, STEPS.size(), str(STEPS[_step][1])]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			closed.emit()
			return
		if k == KEY_SPACE and _step < STEPS.size():
			get_viewport().set_input_as_handled()
			_step += 1
			_show()
			return
		if k == KEY_R and _device >= 0:
			_clear(_device)
			return
		if (k == KEY_ENTER or k == KEY_SPACE) and _step >= STEPS.size():
			closed.emit()
			return
	if _cool > 0.0 or _step >= STEPS.size():
		if _step >= STEPS.size() and event is InputEventJoypadButton and event.pressed:
			closed.emit()
		return
	if event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		var b := event as InputEventJoypadButton
		var kind := str(STEPS[_step][2])
		# Skip with any button on a different pad than the one being set up.
		if _device >= 0 and b.device != _device:
			_step += 1
			_show()
			return
		if kind == "axis":
			return
		_take(b.device, {"t": "b", "i": b.button_index})
	elif event is InputEventJoypadMotion:
		var m := event as InputEventJoypadMotion
		if _device >= 0 and m.device != _device:
			return
		# Triggers rest at -1 on some pads: measure from where the axis rests.
		var key := "%d:%d" % [m.device, m.axis]
		if not _rest.has(key):
			_rest[key] = m.axis_value if absf(m.axis_value) > 0.9 else 0.0
		var d := m.axis_value - float(_rest[key])
		if absf(d) < 0.65:
			return
		var kind2 := str(STEPS[_step][2])
		if kind2 == "button":
			return
		get_viewport().set_input_as_handled()
		_take(m.device, {"t": "a", "i": m.axis, "v": signf(d) if float(_rest[key]) == 0.0 else signf(m.axis_value)})


func _take(device: int, m: Dictionary) -> void:
	if _device < 0:
		_device = device
	_map[str(STEPS[_step][0])] = m
	Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.2 + 0.03 * float(_step), -6.0)
	_step += 1
	_cool = 0.35
	_show()


func _process(delta: float) -> void:
	if _cool > 0.0:
		_cool -= delta


func _finish() -> void:
	if _device < 0 or _map.is_empty():
		_prompt.text = "Nothing was set. ESC to go back."
		return
	var maps: Dictionary = FamilyProfile.data.get("pad_maps", {})
	maps[Input.get_joy_guid(_device)] = _map
	FamilyProfile.data["pad_maps"] = maps
	FamilyProfile.save()
	PadRouter.refresh()
	_prompt.text = "SAVED for %s.  Press any button or ENTER." % Input.get_joy_name(_device).to_upper()
	_done.text = "%d controls set. It is remembered for this pad from now on." % _map.size()
	Juice.rewards.upgrade(null, Color(0.45, 1.0, 0.6), "PAD READY", true)


func _clear(device: int) -> void:
	var maps: Dictionary = FamilyProfile.data.get("pad_maps", {})
	maps.erase(Input.get_joy_guid(device))
	FamilyProfile.data["pad_maps"] = maps
	FamilyProfile.save()
	PadRouter.refresh()
	_done.text = "Cleared the custom map for %s (back to the standard layout)." % Input.get_joy_name(device)
