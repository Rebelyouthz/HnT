extends SceneTree

## Screenshots of the menu focus frame gliding between clinic cards (needs a
## renderer): xvfb-run godot --path . --rendering-driver opengl3 --script res://tools/glide_show.gd -- <out_prefix>

var _n := 0
var _out := "user://glide"
var _cards: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	DisplayServer.window_set_size(Vector2i(1920, 1080))


func _snap(tag: String) -> void:
	get_root().get_texture().get_image().save_png("%s_%s.png" % [_out, tag])


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("FamilyProfile").data["named"] = true
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		root.get_node("FamilyProfile").data["guides_done"] = g
		root.get_node("App").call("back_to_hub", "clinic")
	if _n == 90:
		current_scene.call("_open_hub", "clinic")
	if _n == 200:
		for c in root.find_children("*", "BaseButton", true, false):
			if str(c.get_meta("key", "")).begins_with("card_") and (c as Control).is_visible_in_tree():
				_cards.append(c)
		if _cards.size() > 1:
			(_cards[0] as Control).grab_focus()
	if _n == 240:
		_snap("rest")
		if _cards.size() > 1:
			(_cards[1] as Control).grab_focus()
	if _n == 244:
		_snap("glide")
	if _n == 290:
		_snap("land")
		return true
	return false
