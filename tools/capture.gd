extends SceneTree

## Dev screenshots with a real renderer (not --headless):
## xvfb-run -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##   --resolution 1920x1080 --windowed --script res://tools/capture.gd -- <scene|map_id> <out.png> [frames] [walk]

var _out := "user://capture.png"
var _frames := 90
var _walk := false
var _left := false
var _n := 0
var _target := ""
var _tab := ""


## Autoloads are only in the tree once the loop runs: seed the profile on the
## first frame, change scene on the second.
func _prepare() -> void:
	var fp := root.get_node_or_null("FamilyProfile")
	if _tab == "locker_gear":
		Engine.set_meta("locker_slot", "clothes")
		_tab = "locker"
	if _tab == "build_surv" or _tab == "build_park":
		Engine.set_meta("build_mode", "survivor" if _tab == "build_surv" else "parkour")
		_tab = "build"
	if fp != null and fp.get("data") is Dictionary:
		var d := fp.data as Dictionary
		d["intro_done"] = true
		d["named"] = true
		if str(d.get("father_name", "")) == "":
			d["father_name"] = "Dad"
		if str(d.get("son_name", "")) == "":
			d["son_name"] = "Kid"
		# First-use guides stay out of shots unless GUIDE=<id> asks for one.
		var g_keep := OS.get_environment("GUIDE")
		var g_done: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			if str(gk) != g_keep:
				g_done.append(str(gk))
		d["guides_done"] = g_done
	var app := root.get_node_or_null("App")
	if app != null and _tab.begins_with("film_"):
		var pair := _tab.substr(5)
		app.set("film_from", pair.get_slice("->", 0))
		app.set("film_next", pair.get_slice("->", 1))
		app.set("film_kind", "bridge")
		app.set("film_to_camp", true)
	if app != null and _tab != "" and not _tab.begins_with("title") and not _tab.begins_with("camp") and not _tab.begins_with("tower") and not _tab.begins_with("film") and not _tab.begins_with("ui"):
		app.set("pending_tab", _tab)
	# Hideout shots: both brothers home and lumber money.
	if _tab.begins_with("camp_") and fp != null:
		(fp.data as Dictionary)["crew_benny"] = true
		(fp.data as Dictionary)["crew_rico"] = true
		(fp.data as Dictionary)["gold"] = 500
	# Menu shots: open the gated tabs so BUILD / LOCKER / AWARDS render.
	if _tab in ["build", "locker", "awards"] and fp != null:
		var b: Dictionary = (fp.data as Dictionary).get("buildings", {})
		for id in ["therapy_couch", "wardrobe_cage", "trophy_cabinet"]:
			b[id] = maxi(1, int(b.get(id, 0)))
		(fp.data as Dictionary)["buildings"] = b
	if _tab == "locker" and fp != null:
		(fp.data as Dictionary)["gear_inv"] = {"hoodie_lemon": [3, 1, 0, 0, 0], "polo_navy": [1, 0, 0, 0, 0], "headband": [1, 0, 0, 0, 0], "parkour_kicks": [2, 0, 0, 0, 0], "loafer_web": [1, 0, 0, 0, 0], "night_tutor": [0, 0, 1, 0, 0]}
		(fp.data as Dictionary)["owned_gear"] = ["hoodie_lemon", "polo_navy", "headband", "parkour_kicks", "loafer_web", "night_tutor"]
		(fp.data as Dictionary)["gold"] = 400
		var parts: Array = []
		for s in ["bat", "spider", "shaolin", "ninja"]:
			for p in ["mask", "top", "bottom"]:
				parts.append("%s_%s" % [s, p])
		(fp.data as Dictionary)["suits_split"] = true
		(fp.data as Dictionary)["suit_parts"] = parts
		for p in ["mask", "top", "bottom"]:
			(fp.data as Dictionary)["suit_son_" + p] = "bat"
		(fp.data as Dictionary)["suit_father_mask"] = "spider"
		(fp.data as Dictionary)["suit_father_top"] = "ninja"
		(fp.data as Dictionary)["suit_father_bottom"] = "shaolin"
	# ui:suit_<id> - the Son in that full suit, steam full, showing its
	# gadget, the top's move and the bottom's special.
	if _tab.begins_with("ui_suit_") and fp != null:
		var sid := _tab.substr(8)
		var owned: Array = []
		for p in ["mask", "top", "bottom"]:
			owned.append("%s_%s" % [sid, p])
			(fp.data as Dictionary)["suit_son_" + p] = sid
		(fp.data as Dictionary)["suits_split"] = true
		(fp.data as Dictionary)["suit_parts"] = owned
	if _tab.begins_with("moves") and fp != null:
		(fp.data as Dictionary)["gold"] = 400
		(fp.data as Dictionary)["loadout_moves"] = {"son": {"L3": "front_kick", "H": "side_kick", "STR": "roundhouse"}}
		(fp.data as Dictionary)["moves_learned"] = {"son": ["side_kick", "flying_knee", "cartwheel_kick"]}
		(fp.data as Dictionary)["combos_custom"] = {"son": [{"id": "custom_son_1", "who": "son", "title": "ALLEY LESSON", "steps": ["L", "L", "F+H"], "clip": "cartwheel_kick", "fx": "knockdown", "dmg": 44, "custom": true, "starter": true}]}
		(fp.data as Dictionary)["arts"] = {"fireball": 5, "lightning_dash": 2, "evolved": {}}
		(fp.data as Dictionary)["gems"] = 30
	if _tab == "codex" and fp != null:
		(fp.data as Dictionary)["kills_by"] = {"Collector Gant": 1, "Bag Snatch": 34, "Repo Goon": 21, "Mohawk Bo": 6, "Coping Imp": 88}
		(fp.data as Dictionary)["boss_tries_dock_street"] = 2
	if _tab == "codex" and fp != null:
		(fp.data as Dictionary)["codex_seen"] = {"enemy:Bag Snatch": 2, "enemy:Roof Runner": 1, "enemy:Mohawk Bo": 1, "enemy:Repo Goon": 2, "enemy:Coping Imp": 1, "boss:Shift Lead": 1, "weapon:pipe": 1, "place:dock_street": 2}
	if _tab == "rewards" and fp != null:
		var d := fp.data as Dictionary
		d["account_level"] = 7
		d["road_claimed"] = [2, 3]
		d["crate_last"] = int(Time.get_unix_time_from_system() / 86400.0) - 1
		d["crate_streak"] = 3
		d["finishers"] = 4
		d["titles"] = ["new_patient", "regular"]
		d["title"] = "regular"
		d["codex_seen"] = {"enemy:Bag Snatch": 1, "enemy:Roof Runner": 1, "boss:Shift Lead": 1}
		d["power_seen"] = 50
	if _tab == "jobs" and fp != null:
		(fp.data as Dictionary).erase("contracts")
		(fp.data as Dictionary)["kills_total"] = 0
	if (_tab == "codex" or _tab == "build") and fp != null:
		(fp.data as Dictionary)["tokens"] = 240
		(fp.data as Dictionary)["flow"] = 130
		(fp.data as Dictionary)["tree_survivor"] = ["u_cart", "u_bag", "s_slot", "s_reroll", "s_evolve", "f_start"]
		(fp.data as Dictionary)["tree_parkour"] = ["p_trick_steam", "p_air_jump", "p_stomp", "p_float"]
		(fp.data as Dictionary)["evolutions_seen"] = ["invoice_toss"]
		(fp.data as Dictionary)["surv_best_kills"] = 412
	if _tab == "heroes" and fp != null:
		(fp.data as Dictionary)["gold"] = 900
		(fp.data as Dictionary)["gems"] = 12
		(fp.data as Dictionary)["tricks"] = 70
		(fp.data as Dictionary)["hero_son"] = {"level": 10, "rarity": 0, "shards": 14}
		(fp.data as Dictionary)["hero_father"] = {"level": 13, "rarity": 1, "shards": 6}
		(fp.data as Dictionary)["meta"] = {"vitality": 2, "strength": 1, "spring_legs": 1}
	if _tab.begins_with("ui_gun_") and fp != null:
		(fp.data as Dictionary)["weapon_lv"] = {"pistol": 4, "smg": 4, "shotgun": 4}
		(fp.data as Dictionary)["attach_owned"] = ["suppressor", "laser", "long_barrel", "drum_mag", "hollow", "scope", "compensator"]
		(fp.data as Dictionary)["attach_on"] = {"pistol": {"muzzle": "suppressor", "optic": "laser", "barrel": "long_barrel", "mag": "drum_mag", "ammo": "hollow"}, "smg": {"muzzle": "compensator", "optic": "scope", "mag": "drum_mag"}}
	if _tab == "starter" and fp != null:
		(fp.data as Dictionary)["tokens"] = 300
		(fp.data as Dictionary)["surv_start"] = {"pick": "stapler", "w": {"stapler": {"lv": 4, "rar": 2, "copies": 3, "mods": ["rapid"]}, "invoice_toss": {"lv": 2, "rar": 0, "copies": 1, "mods": []}}}
		(fp.data as Dictionary)["surv_challenges"] = ["ch_kills_500"]
		(fp.data as Dictionary)["surv_ch_best"] = {"kills": 620, "time": 210, "level": 14}
	if _tab == "sgear" and fp != null:
		(fp.data as Dictionary)["tokens"] = 140
		(fp.data as Dictionary)["sgear"] = [{"id": "varsity", "rar": 2, "lv": 2}, {"id": "crocs", "rar": 1, "lv": 1}, {"id": "rabbit_foot", "rar": 3, "lv": 1}, {"id": "hard_hat", "rar": 0, "lv": 1}, {"id": "hard_hat", "rar": 0, "lv": 1}, {"id": "hard_hat", "rar": 0, "lv": 1}, {"id": "lab_coat", "rar": 4, "lv": 3}, {"id": "gold_chain", "rar": 2, "lv": 1}, {"id": "class_ring", "rar": 3, "lv": 2}]
		(fp.data as Dictionary)["sgear_on"] = {"jacket": 0, "shoes": 1, "charm": 2, "cap": 3, "neck": 7, "ring": 8}
	if _tab.begins_with("armory") and fp != null:
		(fp.data as Dictionary)["meta"] = {"starter_kit": 1}
		(fp.data as Dictionary)["carry_weapon"] = "baseball_bat"
		(fp.data as Dictionary)["weapons_found"] = ["knife", "pipe", "board", "chain", "baseball_bat", "machete", "pistol", "revolver", "shotgun", "flare_gun", "smg"]
		(fp.data as Dictionary)["weapon_kills"] = {"baseball_bat": 31, "machete": 12, "pistol": 25, "shotgun": 9, "pipe": 4, "revolver": 2}
		(fp.data as Dictionary)["weapon_lv"] = {"baseball_bat": 3, "pistol": 2}
		(fp.data as Dictionary)["mods_owned"] = ["nails", "weighted", "ext_mag"]
		(fp.data as Dictionary)["weapon_lv"] = {"baseball_bat": 3, "pistol": 4}
		(fp.data as Dictionary)["attach_owned"] = ["suppressor", "red_dot", "long_barrel", "hollow"]
		(fp.data as Dictionary)["attach_on"] = {"pistol": {"muzzle": "suppressor", "optic": "red_dot", "barrel": "long_barrel", "mag": "ext_mag", "ammo": "hollow"}}
		(fp.data as Dictionary)["gems"] = 6
		(fp.data as Dictionary)["weapon_mods"] = {"baseball_bat": ["nails", "weighted"], "pistol": ["ext_mag"]}
		(fp.data as Dictionary)["gold"] = 300
	if _tab == "stats":
		# Demo numbers so the report has something to draw.
		var d2 := fp.data as Dictionary
		var demo := {"runs": 23, "lights": 1840, "heavies": 612, "snaps": 97, "dual_snaps": 12, "parries": 140,
			"perfect_parries": 38, "clashes": 44, "stomps": 71, "smash_kills": 210, "revenges": 9, "catches": 33,
			"combo_banks": 58, "towers_climbed": 11, "summit_meals": 6, "tricks": 320, "perfect_tricks": 88,
			"wallkicks": 145, "grinds": 77, "poles": 52, "slides": 190, "dives": 64, "awnings": 41, "bounces": 99,
			"hoods": 27, "high_score": 184300, "streak_best": 7, "solo_clears": 9, "raven_kills": 2, "unmasks": 3}
		for k in demo:
			d2[k] = demo[k]
	change_scene_to_file(_target)


var _had_profile := false


func _initialize() -> void:
	# Shots edit the profile (names, unlocked tabs, demo stats) and the hub
	# saves it; put things back afterwards so tests see a clean profile.
	_had_profile = FileAccess.file_exists("user://family.json")
	if _had_profile:
		DirAccess.copy_absolute("user://family.json", "user://family.capture_backup.json")
	var args := OS.get_cmdline_user_args()
	var target := args[0] if args.size() > 0 else "res://scenes/ui/hub.tscn"
	if args.size() > 1:
		_out = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	_walk = args.size() > 3 and (args[3] == "walk" or args[3] == "left")
	_left = args.size() > 3 and args[3] == "left"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	# ui:<what> on Dock Street: results | cards | toasts
	if target.begins_with("ui:"):
		_tab = "ui_" + target.substr(3)
		target = "res://scenes/levels/intake_lot.tscn" if _tab in ["ui_surv", "ui_spick"] else "res://scenes/levels/dock_street.tscn"
	# art:<art|grab|team>:<id>[:father] fires an element art, grab or team
	# attack on Dock Street against three thugs; frames every 3rd tick.
	elif target.begins_with("art:"):
		_tab = "art_" + target.substr(4)
		target = "res://scenes/levels/dock_street.tscn"
	# film:<from>-><to> plays a bridge film.
	elif target.begins_with("film:"):
		_tab = "film_" + target.substr(5)
		target = "res://scenes/levels/act_film.tscn"
	# tower:<map> plays the giant tower film on autopilot.
	elif target.begins_with("tower:"):
		_tab = "tower_" + target.get_slice(":", 1)
		target = "res://scenes/levels/%s.tscn" % target.get_slice(":", 1).trim_suffix("@summit")
	# camp:hub / camp:dojo open a hideout menu over the camp.
	elif target.begins_with("camp:"):
		_tab = "camp_" + target.get_slice(":", 1)
		target = "res://scenes/levels/camp.tscn"
	# title / title:credits / title:options open the start screen.
	elif target.begins_with("title"):
		_tab = "title_" + (target.get_slice(":", 1) if ":" in target else "")
		target = "res://scenes/ui/title.tscn"
	# hub:<tab> opens the hub on that tab.
	elif target.begins_with("hub"):
		_tab = target.get_slice(":", 1) if ":" in target else ""
		target = "res://scenes/ui/hub.tscn"
	if not target.begins_with("res://"):
		target = "res://scenes/levels/%s.tscn" % target
	_target = target


func _process(_delta: float) -> bool:
	_n += 1
	if _n == 2:
		if _tab.begins_with("art_") and _tab.ends_with(":father"):
			var app := root.get_node_or_null("/root/App")
			if app:
				app.set("solo_role", "father")
		_prepare()
	if _tab.begins_with("art_"):
		_art_demo()
	# REWARD=key:amount[@frame] fires a reward fly-up in any shot (default
	# frame 60); UPFX=frame fires upgrade juice on the focused control.
	var rw := OS.get_environment("REWARD")
	if rw != "":
		var at := int(rw.get_slice("@", 1)) if "@" in rw else 60
		if _n == at:
			var jc := root.get_node_or_null("Juice")
			var spec := rw.get_slice("@", 0)
			jc.call("give", spec.get_slice(":", 0), int(spec.get_slice(":", 1)), Vector2(320, 190))
	# THROW=kind@frame lobs a throwable from the first hero; CHEST=frame
	# drops a story boss chest in front of them.
	var th := OS.get_environment("THROW")
	var hero: Node = null
	for n in root.get_tree().get_nodes_in_group("players"):
		hero = n
		break
	if th != "" and hero != null and _n == int(th.get_slice("@", 1)):
		load("res://src/extras/throw_lob.gd").call("lob", hero, th.get_slice("@", 0))
	# STICK=x,y@from steers the first hero with that stick from that frame on.
	var stk := OS.get_environment("STICK")
	if stk != "" and hero != null and _n >= int(stk.get_slice("@", 1)):
		hero.set("net_driven", true)
		var ns := root.get_node_or_null("NetSession")
		if ns:
			ns.set("stick", Vector2(float(stk.get_slice("@", 0).get_slice(",", 0)), float(stk.get_slice("@", 0).get_slice(",", 1))))
	var ch := OS.get_environment("CHEST")
	if ch != "" and hero != null and _n == int(ch):
		load("res://src/extras/loot_book.gd").call("drop_chest", hero.get_parent(), hero.global_position + Vector2(60, 0), true)
	# DUMP=frame prints every enemy and prop near the right of the screen.
	var dm := OS.get_environment("DUMP")
	if dm != "" and _n == int(dm):
		for e in root.get_tree().get_nodes_in_group("enemies"):
			print("ENEMY ", e.name, " ", e.get("title"), " pos=", e.global_position, " hp=", e.get("hp"), " vis=", e.visible, " script=", e.get_script().resource_path if e.get_script() else "")
		var cam := root.get_viewport().get_camera_2d()
		print("CAM ", cam.get_screen_center_position() if cam else Vector2.ZERO)
		for n in current_scene.find_children("*", "Node2D", true, false):
			var gp: Vector2 = (n as Node2D).global_position
			if cam and absf(gp.x - (cam.get_screen_center_position().x + 230)) < 120 and absf(gp.y - (cam.get_screen_center_position().y + 90)) < 120 and n.get_parent() == current_scene:
				print("NEAR ", n.name, " ", n.get_class(), " ", gp, " ", n.get_script().resource_path if n.get_script() else "")
	# PRESS=part@frame presses that part's tile in an open gunsmith.
	var pr := OS.get_environment("PRESS")
	if pr != "" and _n == int(pr.get_slice("@", 1)):
		for c in root.find_children("*", "Control", true, false):
			if c.has_method("_after_fit"):
				c.call("_press", pr.get_slice("@", 0), null)
				break
	var ux := OS.get_environment("UPFX")
	if ux != "" and _n == int(ux):
		var fo: Control = root.get_viewport().gui_get_focus_owner()
		root.get_node("Juice").call("upgrade_fx", fo, Color(1, 0.8, 0.3), "LV 2", true)
	if _tab == "stats" and _n == 40 and current_scene != null and current_scene.has_method("_open_stats"):
		current_scene.call("_open_stats")
	if _tab.begins_with("armory") and _n == 40 and current_scene != null and current_scene.has_method("_open_armory"):
		current_scene.call("_open_armory")
	if _tab == "starter" and _n == 40 and current_scene != null:
		current_scene.add_child(load("res://src/ui/starter_sheet.gd").new())
	if _tab == "sgear" and _n == 40 and current_scene != null:
		current_scene.add_child(load("res://src/ui/surv_gear_sheet.gd").new())
	if _tab == "armory_gun" and _n == 60:
		for n in root.get_tree().get_nodes_in_group("armory_sheet"):
			n.call("_gunsmith", "pistol")
		var sheets := root.find_children("*", "Control", true, false)
		for c in sheets:
			if c.has_method("_gunsmith"):
				c.call("_gunsmith", "pistol")
				break
	if _tab.begins_with("moves") and _n == 40 and current_scene != null:
		var ms: Control = load("res://src/ui/moves_sheet.gd").new()
		ms.set("_page", {"moves": "loadout", "moves_lib": "library", "moves_lab": "lab", "moves_sty": "styles", "moves_el": "elements"}.get(_tab, "loadout"))
		if _tab == "moves_lab":
			ms.set("_steps", ["L", "F+L", "U+H"])
		current_scene.add_child(ms)
	if _tab == "jobs" and _n == 40 and current_scene != null and current_scene.has_method("_open_jobs"):
		current_scene.call("_open_jobs")
	if _tab == "rewards" and _n == 40 and current_scene != null and current_scene.has_method("_open_rewards") and OS.get_environment("REWARDS_HUB") == "":
		current_scene.call("_open_rewards")
	if _tab == "codex" and _n == 40 and current_scene != null and current_scene.has_method("_open_codex"):
		current_scene.call("_open_codex")
	# hub:<sheet> for any hub sheet with an _open_<sheet> method (stats, jobs, log, profile, settings, intake).
	if _n == 40 and current_scene != null and not (_tab in ["codex", "rewards", "armory"]) and current_scene.has_method("_open_" + _tab):
		current_scene.call("_open_" + _tab)
	if _tab.begins_with("ui_") and _n == 80 and current_scene != null:
		match _tab.substr(3):
			"results":
				current_scene.call("_banner", "DOCK STREET FILED", "Gant is down. Benny is free.", true, false)
			"cards":
				current_scene.call("_cards")
			"items":
				var rs: Node = root.get_tree().get_first_node_in_group("run_state")
				rs.call("take_card", "stapler_orbit")
				var cp: CanvasLayer = load("res://src/combat/card_pick.gd").new()
				cp.set("ids", ["paper_drone", "stapler_orbit", "stray_cat"])
				current_scene.add_child(cp)
			"items_live":
				var rs2: Node = root.get_tree().get_first_node_in_group("run_state")
				var live: Array = ["paper_drone", "stapler_orbit", "stapler_orbit", "stray_cat", "repo_drone", "pigeon_squad"]
				if OS.get_environment("ITEMS") != "":
					live = Array(OS.get_environment("ITEMS").split(","))
				for id in live:
					rs2.call("take_card", id)
			"loot":
				var pl: Node2D = root.get_tree().get_first_node_in_group("players")
				if pl:
					var ld: Script = load("res://src/world/loot_drop.gd")
					var at := pl.global_position + Vector2(60, 0)
					ld.call("spawn", current_scene, at, "shard_son", 1, 0.3)
					ld.call("spawn", current_scene, at + Vector2(40, 8), "shard_father", 2, 0.3)
					for ti in 5:
						var dd: Node = ld.call("spawn", current_scene, at + Vector2(90 + 46 * ti, 4), "gear", 1, 0.2)
						dd.set("item", "headband")
						dd.set("item_tier", ti)
			"cart", "cartworld":
				var cart: Node = null
				for n in current_scene.get_children():
					if n.has_method("_enemy_near"):
						cart = n
				var p1: Node2D = root.get_tree().get_first_node_in_group("players")
				for e in root.get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				if cart and p1:
					p1.global_position = (cart as Node2D).global_position + Vector2(-50, 40)
					if _tab == "ui_cart":
						cart.call("_open", p1)
			"quest":
				var g: Node2D = root.get_tree().get_first_node_in_group("quest_givers")
				var p1: Node2D = root.get_tree().get_first_node_in_group("players")
				for e in root.get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				if g and p1:
					p1.global_position = g.global_position + Vector2(-46, 20)
					g.call("_talk_to")
			"pause":
				var hud := root.get_tree().get_first_node_in_group("run_hud")
				if hud == null:
					for n in current_scene.find_children("*", "CanvasLayer", true, false):
						if n.has_method("_toggle_pause"):
							hud = n
				if hud:
					hud.call("_toggle_pause")
					if OS.get_environment("MOVELIST") != "":
						for cpk in root.find_children("*", "CanvasLayer", true, false):
							if cpk.get_script() != null and str(cpk.get_script().resource_path).ends_with("card_pick.gd"):
								cpk.queue_free()
						var pz: Control = hud.get("_pause")
						hud.call("_move_list", pz, pz)
			"toasts":
				var j := root.get_node("Juice")
				j.call("toast", "reward", "SECRET FOUND", "The Harbour Clock  ·  128 metres")
				j.call("toast", "quest", "CHECKPOINT", "Gant's office is ahead")
				j.call("toast", "challenge", "LOCKED", "Buy Thick Skin at the therapy couch")
	# ui:gore - the nearest thug eats a jab, cross, gut, uppercut, a bullet
	# and a slide, then a heavy finish: blood, wounds, reactions, a body.
	if _tab == "ui_gore" and _n >= 70 and _n % 14 == 0 and _n <= 70 + 14 * 9 and current_scene != null:
		var p1: Node2D = null
		for n in root.get_tree().get_nodes_in_group("players"):
			p1 = n
			break
		var best: Node2D = null
		for n in root.get_tree().get_nodes_in_group("enemies"):
			if best == null or (n as Node2D).global_position.distance_to(p1.global_position) < best.global_position.distance_to(p1.global_position):
				best = n
		if best != null and p1 != null:
			best.global_position = p1.global_position + Vector2(40, 0)
			var step := (_n - 70) / 14
			var seq := [["light", "jab"], ["light", "cross"], ["heavy", "gut"], ["light", "jab"], ["uppercut", "uppercut"], ["heavy", "cross"], ["slide", "slide"], ["light", "jab"], ["heavy", "roundhouse"], ["heavy", "heavy"]]
			var row: Array = seq[mini(step, seq.size() - 1)]
			p1.set("_strike_clip", row[1])
			if step >= 8:
				best.set("hp", 4)
			best.call("take_hit", row[0], p1)
	# ui:smash - the nearest breakable takes blow after blow: stages, shards, loot.
	if _tab == "ui_smash" and _n >= 70 and _n % 10 == 0 and current_scene != null:
		var p1: Node2D = root.get_tree().get_nodes_in_group("players")[0]
		var best: Node2D = null
		for n in root.get_tree().get_nodes_in_group("smashables"):
			if not n.has_method("_chip"):
				continue
			if best == null or absf((n as Node2D).global_position.x - p1.global_position.x) < absf(best.global_position.x - p1.global_position.x):
				best = n
		if best != null:
			p1.global_position = best.global_position + Vector2(-50, 4)
			best.set_meta("syringe", true)
			best.call("take_hit", "light", p1)
	if _tab.begins_with("tower_") and _n == 58:
		# Skip the stage title card so it can't unpause under the film.
		for c in current_scene.get_children():
			if c.has_method("_close") and c.get("map_id") != null and c is CanvasLayer:
				c.queue_free()
	if _tab.begins_with("tower_") and _n == 60:
		load("res://src/ui/timing_ring.gd").set("autoplay", true)
		root.get_tree().paused = true
		var film: Node = load("res://src/world/giant_tower_film.gd").new()
		film.set("map_id", _tab.substr(6).trim_suffix("@summit"))
		if _tab.ends_with("@summit"):
			film.set_meta("skip_climb", true)
		root.add_child(film)
	if _tab.begins_with("camp_") and _n == 90 and current_scene != null:
		var what := _tab.substr(5)
		if what == "hub":
			current_scene.call("_open_hub", "clinic")
		elif what.begins_with("build_"):
			for st: Dictionary in current_scene.get("_stations"):
				if str(st["id"]) == what.substr(6):
					current_scene.get("_walker").position.x = float(st["x"]) + 30.0
					current_scene.call("_construct", st)
		else:
			current_scene.call("_use", {"id": what, "locked": false})
	if _tab.begins_with("title_") and _n == 60 and current_scene != null:
		var page := _tab.substr(6)
		if page != "" and current_scene.has_method("_" + page):
			current_scene.call("_" + page)
	# ui:surv (on a survive map) - every new ability at LV 7, two evolved,
	# then the ultimate; frames every 6 ticks.
	# ui:spick - the survivor level-up pick (sprite ID-badge cards).
	if _tab == "ui_spick" and _n == 80 and current_scene != null:
		var sp: Node = root.get_tree().get_first_node_in_group("survive_run")
		if sp:
			sp.set("_pending", 1)
			sp.call("_next_pick")
	if _tab == "ui_surv" and current_scene != null:
		var sr: Node = root.get_tree().get_first_node_in_group("survive_run")
		if _n == 90 and sr:
			get_root().get_tree().paused = false
			var ids := ["cart", "bag", "hydrant", "mailbomb", "sprinkler", "audit", "gravy"]
			if OS.get_environment("SURV_IDS") != "":
				ids = Array(OS.get_environment("SURV_IDS").split(","))
			for id in ids:
				sr.get("abilities")[id] = 7
				sr.call("_mount", id)
			sr.get("evolved")["cart"] = true
			sr.get("evolved")["sprinkler"] = true
			sr.call("emit_signal", "changed")
		if _n == 200 and sr:
			sr.set("ult_charge", 60.0)
			var pl: Node = root.get_tree().get_first_node_in_group("players")
			sr.call("fire_ult", pl)
		if _n >= 96 and _n % 6 == 0:
			for c in current_scene.get_children():
				if c is CanvasLayer and c.get_script() != null and str(c.get_script().resource_path).ends_with("survive_pick.gd"):
					c.queue_free()
					get_root().get_tree().paused = false
			root.get_texture().get_image().save_png(_out.get_basename() + "_%03d.png" % _n)
	# ui:extras - a street event and the tax refund runner right away.
	if _tab == "ui_extras" and current_scene != null:
		var ne: Node = current_scene.get_node_or_null("NightExtras")
		if _n == 90 and ne:
			get_root().get_tree().paused = false
			ne.set("_event_cd", 0.0)
			ne.set("_runner_cd", 0.0)
		if _n >= 100 and _n % 10 == 0:
			root.get_texture().get_image().save_png(_out.get_basename() + "_%03d.png" % _n)
	# ui:boss_<move> - the map's boss next to the Son runs one pattern;
	# frames every 4 ticks (<out>_NNN.png).
	if _tab.begins_with("ui_boss_") and current_scene != null:
		if _n == 80:
			get_root().get_tree().paused = false
			for e in root.get_tree().get_nodes_in_group("enemies"):
				e.queue_free()
			for d in root.get_tree().get_nodes_in_group("dog_buddy"):
				d.queue_free()
			if current_scene.has_method("_spawn_story_unit"):
				current_scene.call("_spawn_story_unit", false)
		if _n == 84:
			var p1: Node2D = root.get_tree().get_first_node_in_group("players")
			var bs: Node = root.get_tree().get_first_node_in_group("act_final_boss")
			if bs and p1:
				(bs as Node2D).global_position = p1.global_position + Vector2(230, 0)
				p1.set("invuln", 0)
		if _n == 100:
			var bs2: Node = root.get_tree().get_first_node_in_group("act_final_boss")
			var p2: Node = root.get_tree().get_first_node_in_group("players")
			if bs2 and bs2.get("brain") != null:
				bs2.get("brain").call("_start", _tab.substr(8), p2)
		if _n >= 96 and _n % 4 == 0:
			root.get_texture().get_image().save_png(_out.get_basename() + "_%03d.png" % _n)
	# ui:fight - one thug squared up in front of the Son, a jab-jab-heavy
	# string, frames saved around every contact (<out>_NNN.png).
	if (_tab == "ui_fight" or _tab.begins_with("ui_gun_") or _tab.begins_with("ui_suit_")) and current_scene != null:
		if _n == 80:
			get_root().get_tree().paused = false
			for c in current_scene.get_children():
				if c.has_method("show_for") or c.get_class() == "CanvasLayer" and c.get_script() != null and str(c.get_script().resource_path).ends_with("stage_card.gd"):
					c.queue_free()
			var p1: Node2D = root.get_tree().get_first_node_in_group("players")
			var keep: Node2D = null
			var pool := root.get_tree().get_nodes_in_group("enemies")
			for want in ["Repo Goon", "Mohawk Bo", "Roof Runner", "Beat Cop", ""]:
				for e in pool:
					if keep == null and e is Node2D and (want == "" or str(e.get("title")) == want) and str(e.get("title")) not in ["Drone", "Bag Snatch"]:
						keep = e
			for e in pool:
				if e != keep:
					e.queue_free()
			for d in root.get_tree().get_nodes_in_group("dog_buddy"):
				d.queue_free()
			if keep and p1:
				var melee_demo := _tab.begins_with("ui_gun_") and not (_tab.substr(7) in ["pistol", "nailgun", "shotgun", "smg", "ray", "revolver", "flare_gun"])
				keep.global_position = p1.global_position + Vector2(40 if _tab == "ui_fight" or melee_demo else 260, 0)
				keep.set("facing", -1)
				keep.set("recover", 99.0)
		if _n == 90:
			for b in root.get_tree().get_nodes_in_group("bounty"):
				b.remove_from_group("bounty")
			if current_scene.has_method("_pick_bounty"):
				current_scene.call("_pick_bounty")
		var gun := _tab.substr(7) if _tab.begins_with("ui_gun_") else ""
		if _n == 95 and gun != "":
			var pg: Node = root.get_tree().get_first_node_in_group("players")
			if pg:
				pg.call("equip_pickup", gun)
		if _tab.begins_with("ui_suit_"):
			_suit_demo()
		elif _n >= 100 and _n < 190:
			var k := (_n - 100) % (6 if gun == "smg" else (24 if gun == "sledgehammer" else 14))
			var is_gun := gun != "" and gun in ["pistol", "nailgun", "shotgun", "smg", "ray", "revolver", "flare_gun"]
			var heavy := _n >= 156 and not is_gun
			var act := "p1_heavy" if heavy else ("p1_shoot" if is_gun else "p1_light")
			if k == 0:
				Input.action_press(act)
				var pp: Node2D = root.get_tree().get_first_node_in_group("players")
				for e in root.get_tree().get_nodes_in_group("enemies"):
					if pp and e is Node2D:
						print("FIGHT_DIST ", _n, " dx=", snappedf((e as Node2D).global_position.x - pp.global_position.x, 0.1), " dy=", snappedf((e as Node2D).global_position.y - pp.global_position.y, 0.1), " title=", e.get("title"), " hp=", e.get("hp"))
			elif k == 2:
				Input.action_release(act)
			if (_n - 100) % 2 == 0 or gun != "":
				root.get_texture().get_image().save_png(_out.get_basename() + "_%03d.png" % _n)
	if _walk and _n > 20:
		Input.action_press("p1_left" if _left else "p1_right")
	if _n == _frames and OS.get_environment("PROBE") != "":
		var pt := Vector2(float(OS.get_environment("PROBE").get_slice(",", 0)), float(OS.get_environment("PROBE").get_slice(",", 1)))
		_probe(root, pt)
	if _n == _frames:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("CAPTURED ", _out, " ", img.get_size())
		_restore_profile()
		quit()
	return false


## Throw (gadget), double jump + glide, then the special; a frame every
## other tick from 96 to 300.
func _suit_demo() -> void:
	var pp: Node = root.get_tree().get_first_node_in_group("players")
	if pp and _n >= 96:
		pp.set("steam", 100.0)
	var script := {100: ["p1_throw", true], 103: ["p1_throw", false],
		150: ["p1_jump", true], 156: ["p1_jump", false], 166: ["p1_jump", true], 215: ["p1_jump", false],
		250: ["p1_special", true], 253: ["p1_special", false]}
	if script.has(_n):
		var e: Array = script[_n]
		if e[1]:
			Input.action_press(e[0])
		else:
			Input.action_release(e[0])
	if _n >= 96 and _n <= 320 and _n % 2 == 0:
		root.get_texture().get_image().save_png(_out.get_basename() + "_%03d.png" % _n)


func _art_demo() -> void:
	var parts := _tab.substr(4).split(":")
	var pl: Node2D = null
	for p in root.get_tree().get_nodes_in_group("players"):
		if p is Node2D and p.get("arts") != null:
			pl = p
	if pl == null:
		return
	if _n == 70:
		for i in 3:
			var e: Node2D = load("res://src/coop/party.gd").spawn_row(current_scene, {"title": "Bag Snatch"}, 4.0)
			e.global_position = pl.global_position + Vector2(170.0 + 50.0 * float(i), (float(i) - 1.0) * 10.0)
	if _n == 74:
		for e in root.get_tree().get_nodes_in_group("enemies"):
			if e is Node2D and (e as Node2D).global_position.distance_to(pl.global_position) > 320.0:
				(e as Node2D).queue_free()
	if _n == 80:
		pl.get("arts").call("perform", parts[0], parts[1])
	if _n >= 80 and _n <= 170 and (_n - 80) % 4 == 0:
		root.get_texture().get_image().save_png(_out.get_basename() + "_%03d.png" % _n)


func _probe(n: Node, pt: Vector2) -> void:
	for c in n.get_children():
		if c is CanvasItem and (c as CanvasItem).is_visible_in_tree():
			var ci := c as CanvasItem
			var r := Rect2()
			if ci is Control:
				r = Rect2(Vector2.ZERO, (ci as Control).size)
			elif ci is Sprite2D and (ci as Sprite2D).texture:
				r = (ci as Sprite2D).get_rect()
			elif ci is Polygon2D and (ci as Polygon2D).polygon.size() > 2:
				var pts := (ci as Polygon2D).polygon
				r = Rect2(pts[0], Vector2.ZERO)
				for q in pts:
					r = r.expand(q)
			elif ci is ColorRect:
				r = Rect2(Vector2.ZERO, (ci as ColorRect).size)
			if r.size != Vector2.ZERO:
				var xf := ci.get_global_transform_with_canvas()
				var sr := xf * r
				if sr.has_point(pt):
					print("PROBE ", ci.get_path(), " ", ci.get_class(), " z=", ci.z_index, " rect=", sr, " mod=", ci.modulate)
		_probe(c, pt)


func _restore_profile() -> void:
	if _had_profile:
		DirAccess.copy_absolute("user://family.capture_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.capture_backup.json")
	elif FileAccess.file_exists("user://family.json"):
		DirAccess.remove_absolute("user://family.json")
