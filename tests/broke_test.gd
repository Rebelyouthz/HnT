extends SceneTree

## With an empty wallet nothing can be bought, built, learned or levelled:
## every buy path refuses and gold / gems / tokens never go below zero.
## Prints BROKE OK.

var _n := 0
var ok := true


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _ids(path: String) -> Array:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var out: Array = []
	if v is Array:
		for r in v:
			if r is Dictionary and (r as Dictionary).has("id"):
				out.append(str(r["id"]))
	elif v is Dictionary:
		for k in (v as Dictionary).keys():
			out.append(str(k))
	return out


func _process(_d: float) -> bool:
	_n += 1
	if _n != 3:
		return false
	var fp: Node = root.get_node("FamilyProfile")
	var d: Dictionary = fp.data
	for k in ["gold", "gems", "tokens", "card_tokens", "scrap", "parts"]:
		if d.has(k) and (d[k] is int or d[k] is float):
			d[k] = 0
	var bought := 0
	for id in _ids("res://data/buildings.json"):
		if fp.call("try_build", id): bought += 1
	for id in _ids("res://data/cbt.json") + _ids("res://data/skill_tree.json"):
		if fp.call("try_cbt", id): bought += 1
	for id in _ids("res://data/gear.json"):
		if fp.call("try_buy_gear", id): bought += 1
		if fp.call("try_upgrade_gear", id): bought += 1
	for id in _ids("res://data/research.json"):
		if fp.call("try_research", id): bought += 1
	for id in ["uppercut", "roundhouse", "air_mix", "land_roll"]:
		if fp.call("try_dojo", id): bought += 1
	if fp.call("buy_snack", "coffee", 5): bought += 1
	var meta: Script = load("res://src/app/meta.gd")
	for id in _ids("res://data/meta.json"):
		if meta.call("try_buy", id): bought += 1
	var heroes: Script = load("res://src/app/heroes.gd")
	for role in ["son", "father"]:
		for m in ["story", "survivor", "parkour"]:
			if heroes.call("try_level", role, m): bought += 1
		if heroes.call("try_rank", role): bought += 1
	var vault: Script = load("res://src/app/vault_cards.gd")
	if not (vault.call("draw") as Dictionary).is_empty(): bought += 1
	var arsenal: Script = load("res://src/app/arsenal.gd")
	for id in _ids("res://data/weapons.json"):
		if arsenal.call("try_level", id): bought += 1
	for k in ["gold", "gems", "tokens", "card_tokens"]:
		_check(int(d.get(k, 0)) >= 0, "%s never below zero (%d)" % [k, int(d.get(k, 0))])
	_check(bought == 0, "nothing bought with an empty wallet (%d went through)" % bought)
	print("BROKE OK" if ok else "BROKE FAILED")
	quit()
	return true
