extends SceneTree

## THE FORGE: the yard room past the camp with the portal in its arch, the
## forge + salvage bench locked until Ember is home, then smelt / forge /
## salvage move materials and gear as the sheet says.
## Prints FORGE OK.

var _n := 0
var ok := true


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _process(_d: float) -> bool:
	_n += 1
	var fp := root.get_node("FamilyProfile")
	if _n == 2:
		fp.data["intro_done"] = true
		fp.data["crew_benny"] = true
		fp.data["crew_ember"] = false
		root.get_node("App").set("solo_role", "son")
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 30:
		var camp := current_scene
		_check(bool(camp.call("has_yard")), "camp has the forge yard")
		var w: Node2D = camp.get("_walker")
		var portal: Node2D = camp.get("_portal")
		_check(portal.position.x > float(camp.get("_w")), "portal stands in the yard")
		_check(absf(w.position.x - portal.position.x) < 60.0, "you step out by the portal")
		var forge: Dictionary = {}
		for st: Dictionary in camp.get("_stations"):
			if str(st["id"]) == "forge":
				forge = st
		_check(not forge.is_empty(), "forge station placed")
		_check(bool(forge.get("locked", false)), "forge locked before Ember")
		_check(str(camp.call("_prompt_for", forge)).find("EMBER") >= 0, "locked prompt names Ember")
	if _n == 34:
		fp.data["crew_ember"] = true
		fp.data["crew_home_ember"] = true
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 64:
		var camp := current_scene
		_check(camp.get("_crew").has("ember"), "Ember stands in the yard")
		var forge: Dictionary = {}
		for st: Dictionary in camp.get("_stations"):
			if str(st["id"]) == "forge":
				forge = st
		_check(not bool(forge.get("locked", true)), "forge open with Ember home")
		for g in get_nodes_in_group("errand_guide"):
			g.queue_free()
		camp.set("_busy", false)
		camp.call("_use", forge)
		_check(bool(camp.call("overlay_open")), "forge sheet opens")
	if _n == 70:
		# Book: salvage, forge, smelt.
		for m in ["iron_scrap", "leather_strip", "cloth_roll", "ember_core"]:
			fp.data.get("parts", {}).erase(m)
		fp.data["runs"] = 7
		fp.data["salvage_run"] = -1
		var fb: Variant = load("res://src/app/forge_book.gd")
		_check(fb.salvage_ready(), "salvage ready once a night")
		var got: Dictionary = fb.salvage()
		_check(not got.is_empty(), "salvage gives materials")
		_check(not fb.salvage_ready(), "salvage picked clean till the next run")
		var inv: Variant = fp.data.get("gear_inv", {})
		if inv is Dictionary:
			(inv as Dictionary).erase("steel_cap")
		fp.add_parts("iron_scrap", 10)
		fp.add_parts("cloth_roll", 10)
		fp.data["gold"] = 500
		var cap: Dictionary = fb.recipe("steel_cap")
		_check(str(fb.can_forge(cap)) == "", "steel cap affordable")
		var before: int = int(fp.part_n("iron_scrap"))
		var out: Dictionary = fb.forge("steel_cap", 3)
		_check(not out.is_empty(), "forged a steel cap")
		_check(int(fp.part_n("iron_scrap")) == before - 3, "forging spends iron")
		_check(int(fp.data["gold"]) == 460, "forging spends gold")
		var c: Array = load("res://src/app/gear_inv.gd").counts("steel_cap")
		var total := 0
		for n in c:
			total += int(n)
		_check(total == 1, "one steel cap in the locker")
		_check(fb.smeltable().filter(func(p: Array) -> bool: return p[0] == "steel_cap").is_empty(), "the only copy never melts")
		fb.forge("steel_cap", 0)
		var sm: Array = fb.smeltable().filter(func(p: Array) -> bool: return p[0] == "steel_cap")
		_check(not sm.is_empty(), "a spare copy can melt")
		if not sm.is_empty():
			var y: Dictionary = fb.smelt(sm[0][0], int(sm[0][1]))
			_check(not y.is_empty(), "smelting gives materials back")
		print("FORGE OK" if ok else "FORGE FAILED")
		quit(0 if ok else 1)
	return false
