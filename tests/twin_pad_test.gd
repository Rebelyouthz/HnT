extends SceneTree

## One pad that shows up as two devices (ROG Ally) is recognised as twins
## from a doubled press, so its second half never drops in as player 2;
## two real pads pressing apart are not twins. Prints TWIN OK.
##   godot --headless -s tests/twin_pad_test.gd

var _n := 0


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	var pr := root.get_node("PadRouter")
	pr.call("_note_twin", 0, JOY_BUTTON_X)
	pr.call("_note_twin", 1, JOY_BUTTON_X)      # same press, same moment
	var twin := bool(pr.call("is_twin_of", 1, 0))
	pr.call("_note_twin", 2, JOY_BUTTON_Y)
	OS.delay_msec(120)
	pr.call("_note_twin", 3, JOY_BUTTON_Y)      # a second real pad, later
	var apart := bool(pr.call("is_twin_of", 3, 2))
	if twin and not apart:
		print("TWIN OK")
	else:
		print("TWIN FAIL twin=%s apart=%s" % [twin, apart])
	return true
