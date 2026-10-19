extends SceneTree

## Dev shots of a skill-tree buy (the name showcase), several frames:
## xvfb-run godot --path . --script res://tools/dev/cap_buy.gd -- <node_id> <out_prefix>

var _n := 0
var _args := PackedStringArray()
var _hb: Node = null


func _initialize() -> void:
	_args = OS.get_cmdline_user_args()
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.cap_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		fp.data["named"] = true
		fp.data["gold"] = 5000
		var b: Dictionary = fp.data.get("buildings", {})
		b["therapy_couch"] = 1
		fp.data["buildings"] = b
		root.get_node("App").set("pending_tab", "build")
		change_scene_to_file("res://scenes/ui/hub.tscn")
	if _n == 60:
		for c in root.find_children("*", "", true, false):
			if c.has_method("_buy") and c.get("mode") != null:
				_hb = c
		print("hub_build: ", _hb)
	if _n == 70 and _hb != null:
		var node: Dictionary = load("res://src/app/trees.gd").call("node", _hb.get("mode"), _args[0])
		print("node ", node.get("name"))
		_hb.call("_buy", node)
	for k in [74, 80, 88, 100]:
		if _n == k:
			root.get_texture().get_image().save_png("%s_%d.png" % [_args[1], k])
	if _n == 102:
		if FileAccess.file_exists("user://family.cap_backup.json"):
			DirAccess.copy_absolute("user://family.cap_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.cap_backup.json")
		quit()
	return false
