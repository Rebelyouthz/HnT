extends SceneTree

## The arrow never walks you to a buy you cannot pay for: spend all the
## gold on something else, reach the story skill-tree node, and the shortfall
## is handed over (once it is covered nothing more is given). First-use
## guides that say "buy" cover their cheapest buy. Prints GUIDE FUNDS OK.

var _n := 0
var _fail: Array[String] = []


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	var fp := root.get_node("FamilyProfile")
	var gf: GDScript = load("res://src/app/guide_funds.gd")
	# A story LEARN step costing 120 gold and 2 rep, with an empty wallet.
	fp.data["gold"] = 0
	fp.data["rep"] = 0
	var step := {"what": "LEARN", "id": "thick_skin", "name": "THICK SKIN", "gold": 120, "rep": 2, "parts": {"scrap_coil": 2}}
	var given := int(gf.call("cover_step", step))
	if int(fp.data["gold"]) < 120 or int(fp.data["rep"]) < 2 or int(fp.call("part_n", "scrap_coil")) < 2:
		_fail.append("short after cover: gold %d rep %d" % [int(fp.data["gold"]), int(fp.data["rep"])])
	if given <= 0:
		_fail.append("nothing given")
	# Covered: a second pass gives nothing.
	if int(gf.call("cover_step", step)) != 0:
		_fail.append("paid twice")
	# Saved up already: nothing given.
	fp.data["gold"] = 999
	if int(gf.call("top_up", "gold", 120)) != 0 or int(fp.data["gold"]) != 999:
		_fail.append("gave to a full wallet")
	# The skill tree's first guide covers its cheapest open node.
	fp.data["gold"] = 0
	fp.data["rep"] = 0
	fp.data["gems"] = 0
	gf.call("for_guide", "build")
	var can := false
	for r in load("res://src/app/trees.gd").call("nodes", "brawl"):
		if load("res://src/app/trees.gd").call("state", "brawl", r) == "can":
			can = true
	if not can:
		_fail.append("no tree node affordable after the build guide")
	print("GUIDE FUNDS OK" if _fail.is_empty() else "GUIDE FUNDS FAIL %s" % [_fail])
	return true
