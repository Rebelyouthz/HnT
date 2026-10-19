extends SceneTree
## The mod bench opens for a melee weapon, draws every mod on it, buying
## needs gems, fitting animates the dress and the stat rows show the gain.

func _initialize() -> void:
	await process_frame
	var prof: Node = root.get_node("FamilyProfile")
	prof.data["gems"] = 0
	prof.data["mods_owned"] = []
	prof.data["weapon_mods"] = {}
	prof.data["found_weapons"] = ["baseball_bat"]
	var sheet: Control = load("res://src/ui/mod_bench_sheet.gd").new()
	sheet.set("weapon", "baseball_bat")
	root.add_child(sheet)
	for i in 5:
		await process_frame
	var ok := true
	var dress: Node2D = sheet.get("_dress")
	if dress == null:
		print("no dress")
		ok = false
	var tiles := []
	for b in sheet.find_children("*", "Button", true, false):
		if str(b.get_meta("key", "")).begins_with("mod_"):
			tiles.append(b)
	if tiles.size() != 5:
		print("tiles ", tiles.size())
		ok = false
	# Broke: pressing BUY does nothing.
	sheet.call("_press", "nails", tiles[0])
	if (prof.data["mods_owned"] as Array).has("nails"):
		print("bought without gems")
		ok = false
	prof.data["gems"] = 10
	sheet.call("_press", "nails", tiles[0])
	if not (prof.data["mods_owned"] as Array).has("nails") or int(prof.data["gems"]) != 8:
		print("buy failed")
		ok = false
	for i in 260:
		await process_frame
	if not (prof.data["weapon_mods"].get("baseball_bat", []) as Array).has("nails"):
		print("not fitted")
		ok = false
	dress = sheet.get("_dress")
	if not (dress.get("mods") as Array).has("nails"):
		print("dress lacks nails")
		ok = false
	var rows: Dictionary = sheet.get("_rows")
	if float(rows["bleed"].get("now")) != 3.0:
		print("bleed row ", rows["bleed"].get("now"))
		ok = false
	# Every mod draws without error on every melee weapon.
	var md: GDScript = load("res://src/ui/melee_dress.gd")
	for w in ["pipe", "board", "chain", "crowbar", "knife", "clipboard", "stapler", "baseball_bat", "machete", "sledgehammer"]:
		var d: Node2D = md.new()
		root.add_child(d)
		d.call("setup", w, ["nails", "tape_grip", "weighted", "serrated", "live_wire"])
		var prof2: Dictionary = md.profile(w)
		if int(prof2["w"]) <= 0:
			print("no profile ", w)
			ok = false
	for i in 3:
		await process_frame
	print("MOD BENCH OK" if ok else "MOD BENCH FAIL")
	quit(0 if ok else 1)
