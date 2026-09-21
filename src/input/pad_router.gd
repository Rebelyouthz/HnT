extends Node

## Couch pads. Keyboard always stays on both prefixes (debug + P1 default).
## 0 pads: keyboard. 1 pad: that pad is The Father (P2). 2+ pads: device 0 The Son, device 1 The Father.

signal pads_changed
signal drop_in(device: int)

const DEAD := 0.22
const ACTIONS := [
	"left", "right", "up", "down", "jump", "light", "heavy", "special",
	"shoot", "block", "throw", "dash", "snap", "pause"
]

var p1_device := -1
var p2_device := -1
var last_kind := "kb"
var last_p1_kind := "kb"
var last_p2_kind := "kb"


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy)
	_bind_ui()
	refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event.device >= 0:
			last_kind = "pad"
			if event.device == p1_device:
				last_p1_kind = "pad"
			elif event.device == p2_device:
				last_p2_kind = "pad"
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
			_handle_start(event.device)
	elif event is InputEventKey and event.pressed:
		last_kind = "kb"


func _on_joy(_device: int, _connected: bool) -> void:
	refresh()


func refresh() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		p1_device = -1
		p2_device = -1
	elif pads.size() == 1:
		p1_device = -1
		p2_device = int(pads[0])
	else:
		p1_device = int(pads[0])
		p2_device = int(pads[1])
	_apply_pad_map()
	pads_changed.emit()


func _handle_start(device: int) -> void:
	var assigned := device == p1_device or device == p2_device
	if not assigned:
		var pads := Input.get_connected_joypads()
		if pads.size() == 1:
			p2_device = device
			p1_device = -1
		elif p2_device < 0:
			p2_device = device
		elif p1_device < 0:
			p1_device = device
		_apply_pad_map()
		pads_changed.emit()
	# Always emit so a solo run can spawn the empty chair. The map ignores a full party.
	drop_in.emit(device)


func _bind_ui() -> void:
	_joy_btn("ui_accept", JOY_BUTTON_A, -1)
	_joy_btn("ui_cancel", JOY_BUTTON_B, -1)
	_joy_btn("ui_left", JOY_BUTTON_DPAD_LEFT, -1)
	_joy_btn("ui_right", JOY_BUTTON_DPAD_RIGHT, -1)
	_joy_btn("ui_up", JOY_BUTTON_DPAD_UP, -1)
	_joy_btn("ui_down", JOY_BUTTON_DPAD_DOWN, -1)
	_axis("ui_left", JOY_AXIS_LEFT_X, -1.0, -1)
	_axis("ui_right", JOY_AXIS_LEFT_X, 1.0, -1)
	_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0, -1)
	_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0, -1)


func _apply_pad_map() -> void:
	for prefix in ["p1_", "p2_"]:
		for a in ACTIONS:
			_strip_joy(StringName(prefix + a))
	if p1_device >= 0:
		_bind_device("p1_", p1_device)
	if p2_device >= 0:
		_bind_device("p2_", p2_device)
	# Drop-in Start on any unused pad still reaches us via _input.


func _bind_device(prefix: String, device: int) -> void:
	_joy_btn(prefix + "jump", JOY_BUTTON_A, device)
	_joy_btn(prefix + "light", JOY_BUTTON_X, device)
	_joy_btn(prefix + "heavy", JOY_BUTTON_Y, device)
	_joy_btn(prefix + "special", JOY_BUTTON_B, device)
	_joy_btn(prefix + "shoot", JOY_BUTTON_RIGHT_SHOULDER, device)
	_joy_btn(prefix + "block", JOY_BUTTON_LEFT_SHOULDER, device)
	_joy_btn(prefix + "snap", JOY_BUTTON_RIGHT_STICK, device)
	_joy_btn(prefix + "pause", JOY_BUTTON_START, device)
	_joy_btn(prefix + "left", JOY_BUTTON_DPAD_LEFT, device)
	_joy_btn(prefix + "right", JOY_BUTTON_DPAD_RIGHT, device)
	_joy_btn(prefix + "up", JOY_BUTTON_DPAD_UP, device)
	_joy_btn(prefix + "down", JOY_BUTTON_DPAD_DOWN, device)
	_axis(prefix + "left", JOY_AXIS_LEFT_X, -1.0, device)
	_axis(prefix + "right", JOY_AXIS_LEFT_X, 1.0, device)
	_axis(prefix + "up", JOY_AXIS_LEFT_Y, -1.0, device)
	_axis(prefix + "down", JOY_AXIS_LEFT_Y, 1.0, device)
	_axis(prefix + "dash", JOY_AXIS_TRIGGER_RIGHT, 1.0, device)
	_axis(prefix + "throw", JOY_AXIS_TRIGGER_LEFT, 1.0, device)


func _strip_joy(name: StringName) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, DEAD)
		return
	for e in InputMap.action_get_events(name):
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			InputMap.action_erase_event(name, e)


func _joy_btn(name: StringName, button: JoyButton, device: int) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, DEAD)
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.device = device
	if not _has(name, e):
		InputMap.action_add_event(name, e)


func _axis(name: StringName, axis: JoyAxis, value: float, device: int) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.25)
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	e.device = device
	if not _has(name, e):
		InputMap.action_add_event(name, e)


func _has(name: StringName, ev: InputEvent) -> bool:
	for existing in InputMap.action_get_events(name):
		if existing.as_text() == ev.as_text():
			return true
	return false


func stick(prefix: StringName) -> Vector2:
	return Input.get_vector(prefix + "left", prefix + "right", prefix + "up", prefix + "down", DEAD)


func p1_prompt() -> String:
	if p1_device >= 0 and last_p1_kind == "pad":
		return "PAD1  LS move  A jump  X light  Y heavy  B cape  RB batwing  RT dash  RS SNAP"
	return "SON  WASD  SPACE jump  J light  K heavy  L cape  O batwing  SHIFT dash  F SNAP"


func p2_prompt() -> String:
	if p2_device >= 0:
		return "PAD2  LS move  A jump  X light  Y heavy  B web  RB snare  RT dash  RS SNAP"
	return "P2 JOIN  Start or keyboard P  ·  then arrows  CTRL jump  . light  / heavy  ; web  ' snare  ALT dash  N SNAP"


func map_lines() -> PackedStringArray:
	return PackedStringArray([
		"Xbox layout. Keyboard always works. Hub GO does not wait for a second player.",
		"Solo is the default. One body, fewer enemies. Couch 2P is a Run-tab toggle.",
		"P1 The Son  keyboard WASD + J K L O  ·  pad 0 only when two pads are plugged in.",
		"P2 The Father  first pad if one is plugged  ·  pad 1 if two  ·  arrows after join.",
		"A jump   X light (SNAP confirm in the window)   Y heavy   B special",
		"LB block   RB shoot   LT throw   RT dash/slide   RS click SNAP   Start pause",
		"D-pad or left stick. Hold RT + down to slide. Hold A in the air to cape-glide (The Son).",
		"Start on a pad (or keyboard P) drops the empty chair in. Enemies stay the count you booked."
	])
