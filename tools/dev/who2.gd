extends SceneTree
var _n := 0
var _map := "dock_street"
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_map = a[0]
func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		root.get_node("App").call("enter_map", _map)
	if _n in [120, 400, 900]:
		var cam := get_first_node_in_group("couch_camera")
		var hero = get_first_node_in_group("players")
		print("--- frame ", _n, " hero ", hero.global_position if hero else null)
		for e in get_nodes_in_group("enemies"):
			var who := ""
			if e.has_method("_sprite_who"):
				who = e.call("_sprite_who")
			print("ENEMY ", e.get("title"), " who=", who, " pos=", e.global_position, " hp=", e.get("hp"), " phys=", e.is_physics_processing(), " vis=", e.visible)
		for e in get_nodes_in_group("bystanders"):
			print("BYST ", e.global_position)
	return _n > 900
