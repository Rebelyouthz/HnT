extends SceneTree
## Options > RESET GAME PROGRESS: the confirm box takes the pad. Focus lands
## on NO, left/right moves between NO and YES, and nothing behind the box
## (settings rows, the hub, the hero) can take focus or input meanwhile.
## Prints RESET CONFIRM OK.

var _n := 0
var ok := true
var _sheet: Control
var _log: Array = []


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _pad(btn: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	e.device = 0
	Input.parse_input_event(e)
	var u := e.duplicate() as InputEventJoypadButton
	u.pressed = false
	Input.parse_input_event(u)


func _owner_text() -> String:
	var f := root.get_viewport().gui_get_focus_owner()
	if f == null:
		return "<none>"
	return (f as Button).text if f is Button and (f as Button).text != "" else str(f.get_path())


func _process(_d: float) -> bool:
	_n += 1
	if _n == 3:
		var host := Control.new()
		root.add_child(host)
		host.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sheet = load("res://src/ui/settings_sheet.gd").new()
		_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
		host.add_child(_sheet)
	if _n == 10:
		_sheet.call("_confirm_reset")
	if _n == 14:
		_log.append(_owner_text())
		_check(_owner_text() == "NO, KEEP IT", "focus starts on NO (got %s)" % _owner_text())
		_pad(JOY_BUTTON_DPAD_RIGHT)
	if _n == 18:
		_log.append(_owner_text())
		_check(_owner_text() == "YES, WIPE IT", "right moves to YES (got %s)" % _owner_text())
		_pad(JOY_BUTTON_DPAD_DOWN)
	if _n == 22:
		_log.append(_owner_text())
		_check(_owner_text() == "YES, WIPE IT" or _owner_text() == "NO, KEEP IT", "down stays in the box (got %s)" % _owner_text())
		_pad(JOY_BUTTON_DPAD_UP)
	if _n == 26:
		_log.append(_owner_text())
		_check(_owner_text() == "YES, WIPE IT" or _owner_text() == "NO, KEEP IT", "up stays in the box (got %s)" % _owner_text())
		print(_log)
		print("RESET CONFIRM OK" if ok else "RESET CONFIRM FAILED")
		quit()
	return false
