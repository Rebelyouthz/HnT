extends SceneTree

## Dev: first map as one solo hero.
## godot --path . --script res://tools/dev/cap_hero.gd -- <son|father> <out_prefix>

var _n := 0
var _who := "father"
var _out := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_who = a[0] if a.size() > 0 else "father"
	_out = a[1] if a.size() > 1 else "/tmp/hero"


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("App").set("solo_role", _who)
		root.get_node("FamilyProfile").data["solo_role"] = _who
		root.get_node("App").call("enter_map", "dock_street")
	# Take whatever level-up card is focused so the street shows.
	if _n in [100, 160]:
		var e := InputEventAction.new()
		e.action = &"ui_accept"
		e.pressed = true
		Input.parse_input_event(e)
	if _n in [104, 164]:
		var e := InputEventAction.new()
		e.action = &"ui_accept"
		Input.parse_input_event(e)
	if _n in [240, 300]:
		root.get_texture().get_image().save_png("%s_%d.png" % [_out, _n])
		var names: Array = []
		for p in get_nodes_in_group("players"):
			names.append("%s vis=%s pos=%s" % [p.get("role"), p.call("is_visible_in_tree"), p.get("global_position")])
		print("PLAYERS ", names)
	return _n > 302
