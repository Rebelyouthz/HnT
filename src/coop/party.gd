class_name Party
extends Object

const TABLE := "res://data/encounters.json"


static func density_key() -> String:
	return "coop" if App.density_coop else "solo"


static func encounters(map_id: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE))
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var row: Variant = (parsed as Dictionary).get(map_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		return []
	var pack: Variant = (row as Dictionary).get(density_key(), [])
	if typeof(pack) != TYPE_ARRAY:
		return []
	return pack


static func count_for(map_id: String, coop: bool) -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE))
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	var row: Variant = (parsed as Dictionary).get(map_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		return 0
	var pack: Variant = (row as Dictionary).get("coop" if coop else "solo", [])
	if typeof(pack) != TYPE_ARRAY:
		return 0
	return (pack as Array).size()


static func make_son(at: Vector2, prefix: StringName = &"p1_") -> Fighter:
	var f := Fighter.new()
	f.role = "son"
	f.prefix = prefix
	f.max_hp = 92
	f.speed = 230.0
	f.accent = Palette.LEMON
	f.global_position = at
	f.add_to_group("players")
	return f


static func make_father(at: Vector2, prefix: StringName = &"p2_") -> Fighter:
	var f := Fighter.new()
	f.role = "father"
	f.prefix = prefix
	f.max_hp = 118
	f.speed = 180.0
	f.accent = Palette.BRICK
	f.global_position = at
	f.add_to_group("players")
	return f


static func spawn(host: Node, origin: Vector2) -> Dictionary:
	var son: Fighter = null
	var dad: Fighter = null
	if App.two_bodies():
		son = make_son(origin)
		dad = make_father(origin + Vector2(80, 10))
		host.add_child(son)
		host.add_child(dad)
	elif App.solo_role == "father":
		dad = make_father(origin, &"p1_")
		host.add_child(dad)
	else:
		son = make_son(origin)
		host.add_child(son)
	return {"son": son, "dad": dad}


static func join_missing(host: Node, near: Vector2) -> Fighter:
	var have_son := false
	var have_dad := false
	for n in host.get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			if (n as Fighter).role == "son":
				have_son = true
			else:
				have_dad = true
	var born: Fighter = null
	if not have_dad:
		born = make_father(near + Vector2(48, 0), &"p2_")
	elif not have_son:
		born = make_son(near + Vector2(48, 0), &"p2_")
	if born:
		host.add_child(born)
	return born


static func all_past(x: float) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var players := tree.get_nodes_in_group("players")
	if players.is_empty():
		return false
	for n in players:
		if n is Node2D and (n as Node2D).global_position.x <= x:
			return false
	return true


static func spawn_row(host: Node, row: Dictionary, hp_mul: float) -> Punk:
	var p := Punk.new()
	p.title = str(row.get("title", "Bag Snatch"))
	p.home = str(row.get("home", "street"))
	p.hp = int(round(float(row.get("hp", 40)) * hp_mul))
	p.patrol_min = float(row.get("pmin", 0.0))
	p.patrol_max = float(row.get("pmax", 0.0))
	p.cop = bool(row.get("cop", false))
	p.armored = bool(row.get("armored", false))
	match p.title:
		"Mohawk Bo":
			p.speed = 28.0
		"Roof Runner":
			p.speed = 56.0
		"Vest Ollie":
			p.speed = 32.0
			p.armored = true
		"Beat Cop":
			p.speed = 44.0
		"Agent Lin":
			p.speed = 54.0
			p.cop = true
		"Drone":
			p.speed = 62.0
			p.home = "air"
		"Toll Bot":
			p.speed = 24.0
			p.armored = true
		"Hall Guard":
			p.speed = 30.0
			p.armored = true
		_:
			p.speed = 48.0
	p.global_position = Vector2(float(row.get("x", 800.0)), float(row.get("y", 500.0)))
	host.add_child(p)
	return p
