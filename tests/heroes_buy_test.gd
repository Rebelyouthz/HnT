extends SceneTree

## HEROES with no money: every level / meta button is off and pressing them
## buys nothing; MOVES opens the moves sheet on top. Prints HEROES OK.

var _n := 0
var _bad: Array[String] = []


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.heroes_backup.json")


## CAMP=1: the hub as the hideout opens it (an overlay over the room).
func _camp() -> bool:
	return OS.get_environment("CAMP") != ""


func _snap(fp: Node) -> String:
	return JSON.stringify([fp.data.get("gold"), fp.data.get("gems"), fp.data.get("tokens"), fp.data.get("flow"), fp.data.get("meta"), fp.data.get("heroes")])


func _process(_d: float) -> bool:
	_n += 1
	var fp := root.get_node("FamilyProfile")
	if _n == 2:
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		fp.data["gold"] = int(OS.get_environment("GOLD")) if OS.get_environment("GOLD") != "" else 0
		fp.data["gems"] = 0
		fp.data["tokens"] = 0
		fp.data["flow"] = 0
		fp.data["errand_told_dock_street"] = true
		root.get_node("App").set("pending_tab", "heroes")
		change_scene_to_file("res://scenes/levels/camp.tscn" if _camp() else "res://scenes/ui/hub.tscn")
	if _n == 30 and _camp():
		for gd in get_nodes_in_group("guide"):
			gd.queue_free()
		current_scene.call("_open_hub", "heroes")
	if _n >= 60 and _n < 70 and OS.get_environment("GOLD") != "":
		# Some money: spam every buy; the purse never goes below zero.
		for c in root.find_children("*", "BaseButton", true, false):
			var k2 := str(c.get_meta("key", ""))
			if (k2.begins_with("lv_") or k2.begins_with("meta_")) and c.is_inside_tree():
				(c as BaseButton).pressed.emit()
		for cur in ["gold", "gems", "tokens", "flow"]:
			if int(fp.data.get(cur, 0)) < 0:
				_bad.append("%s went negative: %d" % [cur, int(fp.data.get(cur, 0))])
		if _n == 69:
			print("after spam: ", _snap(fp))
	if _n == 60 and OS.get_environment("GOLD") == "":
		var before := _snap(fp)
		var pressed := 0
		for c in root.find_children("*", "BaseButton", true, false):
			var k := str(c.get_meta("key", ""))
			if k.begins_with("lv_") or k.begins_with("meta_") or k.begins_with("rank_") or k.begins_with("up_"):
				if not (c as BaseButton).disabled:
					_bad.append("%s enabled with no money" % k)
				(c as BaseButton).pressed.emit()
				pressed += 1
		print("pressed ", pressed)
		if _snap(fp) != before:
			_bad.append("bought with no money: %s -> %s" % [before, _snap(fp)])
		for c in root.find_children("*", "BaseButton", true, false):
			if str(c.get_meta("key", "")) == "moves":
				(c as BaseButton).pressed.emit()
	if _n == 70 and OS.get_environment("GOLD") != "":
		for c in root.find_children("*", "BaseButton", true, false):
			if str(c.get_meta("key", "")) == "moves":
				(c as BaseButton).pressed.emit()
	if _n == 79 and OS.get_environment("SHOT") != "":
		root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	if _n == 80:
		var sheet: Control = null
		for c in root.find_children("*", "Control", true, false):
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("moves_sheet.gd"):
				sheet = c
		if sheet == null:
			_bad.append("MOVES opened nothing")
		elif not sheet.is_visible_in_tree():
			_bad.append("moves sheet not visible")
		else:
			var cl := sheet.get_canvas_layer_node()
			var top := 0
			for l in root.find_children("*", "CanvasLayer", true, false):
				if (l as CanvasLayer).visible and l.get_child_count() > 0 and l.find_children("*", "BaseButton", true, false).size() > 0:
					top = maxi(top, (l as CanvasLayer).layer)
			print("moves sheet layer ", cl.layer if cl else 0, " top menu layer ", top, " rect ", sheet.get_global_rect())
			if (cl.layer if cl else 0) < top:
				_bad.append("moves sheet drawn under the menu (layer %d < %d)" % [cl.layer if cl else 0, top])
		if _camp():
			# The room's purse pill follows the buys made in the menu.
			var lab: Label = (current_scene.get("_purse") as Dictionary).get("gold")
			if lab == null or lab.text != str(int(fp.data.get("gold", 0))):
				_bad.append("hideout gold shows %s, purse has %d" % [lab.text if lab else "?", int(fp.data.get("gold", 0))])
		print("HEROES OK" if _bad.is_empty() else "HEROES FAIL " + str(_bad))
		if FileAccess.file_exists("user://family.heroes_backup.json"):
			DirAccess.copy_absolute("user://family.heroes_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.heroes_backup.json")
		quit(0 if _bad.is_empty() else 1)
	return false
