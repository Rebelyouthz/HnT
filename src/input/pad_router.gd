extends Node

## Pads. Keyboard always stays on both prefixes (debug + P1 default).
## SOLO (one body on screen): EVERY pad drives P1 - whichever pad you pick up
## works, and the last pad touched is the one the right stick reads.
## COUCH: 1 pad = The Father (P2, keyboard is The Son); 2+ pads = the pad that
## was already P1 stays The Son, the next one is The Father.

signal pads_changed
signal drop_in(device: int)

const DEAD := 0.22
const ACTIONS := [
	"left", "right", "up", "down", "jump", "light", "heavy", "special",
	"shoot", "block", "throw", "dash", "snap", "pause", "duck",
	"slot1", "slot2", "slot3", "slot4"
]

var p1_device := -1
var p2_device := -1
var last_kind := "kb"
var last_p1_kind := "kb"
var last_p2_kind := "kb"
## Mouse aim is live for a few seconds after the mouse last moved (P1 only).
var _mouse_t := -100.0
var _solo := true
## Solo: has the P1 pad actually been played with? Until then a Start press on
## any pad is just pause, so picking up the "other" pad never spawns Dad.
var _p1_used := false


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy)
	_bind_ui()
	_solo = _is_solo()
	refresh()


## Solo vs couch can flip any time (Run-tab toggle, drop-in, scene change).
func _process(_delta: float) -> void:
	var s := _is_solo()
	if s != _solo:
		_solo = s
		refresh()


func _is_solo() -> bool:
	var app := get_node_or_null("/root/App")
	if app == null:
		return true
	return not bool(app.call("two_bodies"))


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event.device >= 0:
			last_kind = "pad"
			# Solo: the pad in your hands is P1 (Start on another pad drops in).
			var start: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START
			if _solo and not start and _moved(event):
				p1_device = event.device
				_p1_used = true
			if event.device == p1_device:
				last_p1_kind = "pad"
			elif event.device == p2_device:
				last_p2_kind = "pad"
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
			_handle_start(event.device)
	elif event is InputEventKey and event.pressed:
		last_kind = "kb"
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 2.0:
		_mouse_t = Time.get_ticks_msec() / 1000.0
		last_kind = "kb"
		last_p1_kind = "kb"


func _moved(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return absf((event as InputEventJoypadMotion).axis_value) > 0.5


func _on_joy(_device: int, _connected: bool) -> void:
	refresh()


func refresh() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		p1_device = -1
		p2_device = -1
	elif _solo:
		if not pads.has(p1_device):
			p1_device = int(pads[0])
		p2_device = -1
	elif pads.size() == 1:
		p1_device = -1
		p2_device = int(pads[0])
	else:
		if not pads.has(p1_device):
			p1_device = int(pads[0])
		p2_device = -1
		for d in pads:
			if int(d) != p1_device:
				p2_device = int(d)
				break
	_apply_pad_map()
	pads_changed.emit()


func _handle_start(device: int) -> void:
	# Solo: Start on the pad you play with is pause, not a second player.
	if _solo and (device == p1_device or not _p1_used or Input.get_connected_joypads().size() < 2):
		return
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
	if _solo and p1_device >= 0:
		_bind_device("p1_", -1)
	elif p1_device >= 0:
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
	# The d-pad is the QUICK BELT; moving is the left stick, duck its click.
	_joy_btn(prefix + "duck", JOY_BUTTON_LEFT_STICK, device)
	_joy_btn(prefix + "slot1", JOY_BUTTON_DPAD_LEFT, device)
	_joy_btn(prefix + "slot2", JOY_BUTTON_DPAD_UP, device)
	_joy_btn(prefix + "slot3", JOY_BUTTON_DPAD_RIGHT, device)
	_joy_btn(prefix + "slot4", JOY_BUTTON_DPAD_DOWN, device)
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


func device_of(prefix: StringName) -> int:
	return p1_device if str(prefix) == "p1_" else p2_device


## The right stick of this player's pad (zero inside the dead zone).
func rstick(prefix: StringName) -> Vector2:
	var dev := device_of(prefix)
	if dev < 0:
		return Vector2.ZERO
	var v := Vector2(Input.get_joy_axis(dev, JOY_AXIS_RIGHT_X), Input.get_joy_axis(dev, JOY_AXIS_RIGHT_Y))
	return v if v.length() > DEAD else Vector2.ZERO


## True while P1 is steering with the mouse (it moved in the last 3 s).
func mouse_live(prefix: StringName) -> bool:
	return str(prefix) == "p1_" and Time.get_ticks_msec() / 1000.0 - _mouse_t < 3.0


func p1_prompt() -> String:
	if p1_device >= 0 and last_p1_kind == "pad":
		return "PAD1  LS move  A jump  X light  Y heavy  B cape  RB batwing  RT dash  RS SNAP  D-PAD belt"
	return "WASD move  SPACE jump  C duck  J / LEFT CLICK light  K / MIDDLE CLICK heavy  L special  O / RIGHT CLICK shoot  SHIFT dash  1-4 belt"


func p2_prompt() -> String:
	if p2_device >= 0:
		return "PAD2  LS move  A jump  X light  Y heavy  B web  RB snare  RT dash  RS SNAP  D-PAD belt"
	return "P2 JOIN  Start or keyboard P  ·  then arrows  CTRL jump  M duck  . light  / heavy  ; web  ' snare  ALT dash  N SNAP"


func map_lines() -> PackedStringArray:
	return PackedStringArray([
		"Xbox layout (Xbox, iPega and other pads). Keyboard and mouse always work too.",
		"SOLO: any pad you pick up plays your hero. Couch 2P is a Run-tab toggle.",
		"Mouse: LEFT click light attack  ·  MIDDLE click heavy  ·  RIGHT click shoot.",
		"Keyboard: WASD move  SPACE jump  C duck  J light  K heavy  L special  O shoot  I block  U throw  SHIFT dash.",
		"COUCH: one pad = The Father (keyboard is The Son)  ·  two pads = one each.",
		"A jump   X light (SNAP confirm in the window)   Y heavy   B special",
		"LB block   RB shoot   LT throw   RT dash/slide   RS click SNAP   Start pause",
		"D-pad or left stick. Hold RT + down to slide. Hold A in the air to cape-glide (The Son).",
		"Start on a pad (or keyboard P) drops the empty chair in. Enemies stay the count you booked."
	])
