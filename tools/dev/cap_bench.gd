extends SceneTree

## Dev: the MOD BENCH on a weapon, fitting nails then live wire; frames saved.
##   -- <weapon> <out_prefix>
var _n := 0
var _w := "baseball_bat"
var _out := "/tmp/bench"
var _sheet: Control


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_w = a[0] if a.size() > 0 else _w
	_out = a[1] if a.size() > 1 else _out


func _snap(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("%s_%s.png" % [_out, tag])


func _process(_dt: float) -> bool:
	_n += 1
	if _n == 3:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["gems"] = 20
		fp.data["mods_owned"] = ["tape_grip"]
		fp.data["weapon_mods"] = {_w: ["tape_grip"]}
		fp.data["weapon_lv"] = {_w: 3}
		var holder := Control.new()
		root.add_child(holder)
		load("res://src/ui/pixel_stage.gd").apply_control(holder)
		_sheet = load("res://src/ui/mod_bench_sheet.gd").new()
		_sheet.set("weapon", _w)
		holder.add_child(_sheet)
	if _n == 40:
		_sheet.call("_focus", "nails")
	if _n == 46:
		_snap("ghost")
	if _n == 50:
		for b in _sheet.find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == "mod_nails":
				_sheet.call("_press", "nails", b)
	if _n in [58, 66, 75, 90, 110]:
		_snap("buy%d" % _n)
	if _n == 160:
		_snap("hammer")
	if _n == 260:
		_snap("nails")
	if _n == 262:
		_sheet.call("_focus", "live_wire")
	if _n == 268:
		_snap("preview")
	if _n == 270:
		quit()
	return false
