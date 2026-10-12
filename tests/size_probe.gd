extends SceneTree

## Prints the drawn height (world units) of every actor in a map:
## godot --headless --path . --script res://tests/size_probe.gd -- dock_street

var _n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var map := args[0] if args.size() > 0 else "dock_street"
	change_scene_to_file("res://scenes/levels/%s.tscn" % map)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 90:
		for n in root.get_tree().get_nodes_in_group("players") + root.get_tree().get_nodes_in_group("enemies") + root.get_tree().get_nodes_in_group("quest_givers"):
			var a := n.get("_anim") as AnimatedSprite2D
			if a == null:
				continue
			var t := a.sprite_frames.get_frame_texture(a.animation, a.frame)
			var reg := (t as AtlasTexture).region if t is AtlasTexture else Rect2(0, 0, t.get_width(), t.get_height())
			var gs := a.get_global_transform().get_scale()
			print("SIZE ", n.name, " ", str(n.get("title")) if n.get("title") != null else str(n.get("role")), " h=", snappedf(reg.size.y * absf(gs.y), 0.1), " scale=", snappedf(absf(gs.y), 0.001))
		quit()
	return false
