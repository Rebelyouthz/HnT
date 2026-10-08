extends SceneTree

## Opens a menu sheet over the hub and films it.
##   xvfb-run ... --fixed-fps 60 --script res://tools/sheet_probe.gd -- <out_dir> <res://sheet.gd> [call@frame,...]
## e.g. "_open_pack@60" calls sheet._open_pack(null-safe button) at frame 60.

var _dir := ""
var _path := ""
var _calls: Array = []
var _n := 0
var _sheet: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_dir = a[0]
	_path = a[1]
	if a.size() > 2:
		_calls = Array(a[2].split(","))
	DirAccess.make_dir_recursive_absolute(_dir)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["named"] = true
		fp.data["tokens"] = 2400
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		change_scene_to_file("res://scenes/ui/hub.tscn")
	if _n == 40:
		_sheet = load(_path).new()
		current_scene.add_child(_sheet)
	var t := _n - 40
	for c: String in _calls:
		if c.get_slice("@", 1).is_valid_int() and t == int(c.get_slice("@", 1)):
			var m := c.get_slice("@", 0)
			if m == "_open_pack":
				_sheet.call(m, Button.new())
			elif m.begins_with("press:"):
				for b in _sheet.find_children("*", "Button", true, false):
					if str(b.get_meta("key", "")) == m.substr(6):
						(b as Button).emit_signal("pressed")
						break
			else:
				_sheet.call(m)
	if t >= 0 and t % 6 == 0:
		root.get_texture().get_image().save_png("%s/m_%04d.png" % [_dir, t])
	if t >= int(OS.get_environment("PROBE_END") if OS.get_environment("PROBE_END") != "" else "60"):
		quit()
	return false
