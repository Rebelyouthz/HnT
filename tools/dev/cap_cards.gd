extends SceneTree
## Dev: the level-up card pick over a street, snapshot after the deal.  -- <out>
var _n := 0
var _out := "/tmp/cards.png"
var _t0 := 0
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else _out
func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("App").call("enter_map", "dock_street")
	if _n == 40:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		var cp: Node = load("res://src/combat/card_pick.gd").new()
		cp.set("ids", ["steam_tax", "quiet_lunch", "paper_drone"])
		root.add_child(cp)
		_t0 = Time.get_ticks_msec()
	if _t0 > 0 and Time.get_ticks_msec() - _t0 > 6000:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
