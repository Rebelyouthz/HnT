extends SceneTree

## Dev: prologue beats without dialogue input.
## godot --path . --script res://tools/dev/cap_prologue.gd -- <out_prefix>

var _n := 0
var _out := ""
var _film: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else "/tmp/pro"


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		change_scene_to_file("res://scenes/levels/prologue.tscn")
	if _n == 40:
		_film = current_scene
		_film.set("_done", true)
		_film.call("_enter_collectors")
	if _n in [50, 110]:
		_shot("enter%d" % _n)
	if _n == 130:
		_film.call("_drag_off")
	if _n in [150, 200, 260]:
		_shot("drag%d" % _n)
	return _n > 262


func _shot(tag: String) -> void:
	root.get_texture().get_image().save_png("%s_%s.png" % [_out, tag])
