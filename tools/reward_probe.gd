extends SceneTree

## Films the reward juice in the hub: gold claim, an upgrade with text, a
## reveal and an equip fly. Frames every 3rd frame to <out_dir>.
##   xvfb-run ... --fixed-fps 60 --script res://tools/reward_probe.gd -- <out_dir>

var _dir := ""
var _n := 0


func _initialize() -> void:
	_dir = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(_dir)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["named"] = true
		change_scene_to_file("res://scenes/ui/hub.tscn")
	var J := root.get_node("Juice")
	var t := _n - 90
	if t == 0:
		J.claim_burst(Vector2(320, 180), "DAILY CRATE", 120, 5)
	if t == 200:
		var target: Control = null
		for c in current_scene.find_children("*", "Button", true, false):
			if (c as Control).is_visible_in_tree():
				target = c
				break
		J.upgrade_fx(target, Color(1.0, 0.8, 0.3), "LV 4", false)
	if t == 290:
		J.rewards.reveal("cur_chest", "BIG CRATE", Color(1.0, 0.56, 0.12), "+300 GOLD", 0.8)
	if t == 420:
		J.equip_fly(null, load("res://assets/sprites/icons/cur_gold.png") if ResourceLoader.exists("res://assets/sprites/icons/cur_gold.png") else null, Vector2(500, 300), Vector2(60, 120), {"dmg": 3, "hp": -2})
	if t >= 0 and t % 3 == 0:
		root.get_texture().get_image().save_png("%s/r_%04d.png" % [_dir, t])
	if t >= 540:
		quit()
	return false
