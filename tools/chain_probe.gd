extends SceneTree

## Story chain: fresh save, then for every scene on the way - a fight map is
## "cleared" (its results sheet opens and NEXT is pressed), films are tapped
## through, the hideout portal is taken - until <stop_map> has run a while.
## Logs every scene change; frames every 90.
##   xvfb-run ... --fixed-fps 60 --script res://tools/chain_probe.gd -- <out_dir> <stop_map> [max_frames]

var _dir := ""
var _stop := "neon_exchange"
var _max := 30000
var _n := 0
var _scene := ""
var _since := 0
var _acted := false


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_dir = a[0]
	if a.size() > 1:
		_stop = a[1]
	if a.size() > 2:
		_max = int(a[2])
	DirAccess.make_dir_recursive_absolute(_dir)
	# Play on a scratch save; the real one comes back on quit.
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.chain_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	if _n == 3:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		fp.data["intro_done"] = true
		fp.data["intro_plays"] = 1
		fp.data["named"] = true
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		Engine.set_meta("probe_no_draw", true)
		_camp_buys("dock_street", "boss")
		root.get_node("App").call("start_run")
	var cs := current_scene
	var nm := str(cs.scene_file_path) if cs else "<none>"
	if nm != _scene:
		_scene = nm
		_since = 0
		_acted = false
		print("CHAIN ", _n, " ", nm)
	_since += 1
	if cs:
		var map_id := nm.get_file().get_basename()
		if map_id == _stop and _since > 900:
			print("CHAIN REACHED ", _stop)
			_restore()
			quit()
			return false
		# Films / talk: tap confirm.
		if _since % 25 == 0:
			Input.action_press("ui_accept")
			Input.action_press("p1_jump")
		elif _since % 25 == 3:
			Input.action_release("ui_accept")
			Input.action_release("p1_jump")
		# Fight / survivor maps: clear them.
		if cs.has_method("_banner") and _since == 700 and not _acted:
			_acted = true
			print("CHAIN clear ", map_id, " next=", cs.get("next_id"))
			get_root().get_tree().paused = false
			if cs.has_method("_on_gate"):
				cs.call("_on_gate")
			else:
				cs.call("_banner", "CLEARED", "", true, true)
		if cs.has_method("_win") and _since == 600 and not _acted:
			_acted = true
			print("CHAIN win ", map_id, " done_before=", cs.get("_done"))
			for n in cs.find_children("*", "", true, false):
				if n.get_script() != null and str(n.get_script().resource_path).ends_with("results_sheet.gd"):
					n.queue_free()
			cs.set("_done", false)
			cs.call("_win")
		if _acted and _since % 120 == 0:
			for n in cs.find_children("*", "", true, false):
				if n.get_script() != null and str(n.get_script().resource_path).ends_with("results_sheet.gd"):
					print("CHAIN next from results (", map_id, ")")
					var nid := str(n.get("next_id"))
					_camp_buys(nid, "enter")
					print("CHAIN results next_id=", nid, " lock=", PowerBook.lock(nid, "enter"), " state=", n.get("state"))
					n.call("_go_next")
					break
		# The hideout: take the portal.
		if map_id == "camp" and _since == 400:
			print("CHAIN leave camp")
			root.get_node("App").call("leave_camp")
	if _n % 90 == 0 and DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("%s/c_%05d.png" % [_dir, _n])
	if _n >= _max:
		print("CHAIN TIMEOUT in ", _scene)
		_restore()
		quit()
	return false


## What a player does at camp after a gate: take the fund, then buy each step
## with the real purchase calls. Fails loudly when a step cannot be bought.
func _camp_buys(map_id: String, when: String) -> void:
	if PowerBook.lock(map_id, when).is_empty():
		return
	var fp := root.get_node("FamilyProfile")
	print("CHAIN gate ", map_id, " ", PowerBook.path_line(map_id), "  gold=", fp.data["gold"])
	print("CHAIN next_run_map=", fp.call("next_run_map"), " shops=", PowerBook.story_shops(), " filed=", fp.data.get("maps_filed", []))
	print("CHAIN fund +", PowerBook.fund(map_id))
	for s in PowerBook.path(map_id):
		var d := s as Dictionary
		var id := str(d["id"])
		var ok := false
		match str(d["what"]):
			"BUILD":
				ok = fp.call("try_build", id)
			"BUY":
				ok = fp.call("try_buy_gear", id)
			"RESEARCH":
				ok = fp.call("try_research", id)
			"CRAFT":
				ok = fp.call("try_craft", id)
			_:
				ok = fp.call("try_cbt", id) or fp.call("try_dojo", id)
		print("CHAIN buy ", d["what"], " ", id, " -> ", ok, "  gold=", fp.data["gold"])
	print("CHAIN gate ", map_id, " open=", PowerBook.lock(map_id, when).is_empty())


func _restore() -> void:
	if FileAccess.file_exists("user://family.chain_backup.json"):
		DirAccess.copy_absolute("user://family.chain_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.chain_backup.json")
	else:
		DirAccess.remove_absolute("user://family.json")
