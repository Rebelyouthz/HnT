class_name SurviveMods
extends Object


static func apply(id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for n in tree.get_nodes_in_group("players"):
		if not (n is Fighter):
			continue
		var f: Fighter = n
		match id:
			"coping_magnet":
				f.magnet_r += 110.0
				Juice.shout("MAGNET")
			"orbit_form":
				if f.get_node_or_null("OrbitKit") == null:
					var o := OrbitKit.new()
					o.name = "OrbitKit"
					f.add_child(o)
			"drip_feed":
				if f.get_node_or_null("DripAura") == null:
					var d := DripAura.new()
					d.name = "DripAura"
					f.add_child(d)
			"vacuum_hour":
				f.magnet_r += 60.0
				_vacuum(tree)
	if id == "vacuum_hour":
		Juice.toast("reward", "VACUUM", "Every chip in the room just remembered your name.")


static func _vacuum(tree: SceneTree) -> void:
	for g in tree.get_nodes_in_group("xp_gems"):
		if g is XpGem:
			(g as XpGem).amount += 1
	for n in tree.get_nodes_in_group("players"):
		if n is Fighter:
			(n as Fighter).magnet_r = maxf((n as Fighter).magnet_r, 420.0)
