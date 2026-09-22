extends Node

signal changed
signal claimed(kind: String, amount: int, line: String)

const SAVE_PATH := "user://family.json"
const BUILDINGS := [
	"front_desk", "street_map", "therapy_couch", "wardrobe_cage",
	"trophy_cabinet", "mail_slot", "bulletin_board", "compare_mirrors", "blood_fridge",
	"pawn_shop", "patrol_desk", "research_lab", "dojo", "workshop"
]

var data: Dictionary = {}


func _enter_tree() -> void:
	load_or_create()


func load_or_create() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var raw := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed: Variant = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
			_migrate()
			return
	data = _defaults()
	save()


func backup_to(path: String) -> void:
	var abs := path
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func save() -> void:
	data["last_unix"] = int(Time.get_unix_time_from_system())
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write Family Profile")
		return
	f.store_string(JSON.stringify(data, "\t"))
	changed.emit()


func _defaults() -> Dictionary:
	var b := {}
	for id in BUILDINGS:
		b[id] = 0
	b["front_desk"] = 1
	b["street_map"] = 1
	return {
		"father_name": "",
		"son_name": "",
		"named": false,
		"gold": 40,
		"gems": 3,
		"rep": 1,
		"runs": 0,
		"heavies": 0,
		"lights": 0,
		"snaps": 0,
		"buildings_tapped": 0,
		"buildings": b,
		"awards_claimed": [],
		"daily_date": "",
		"daily_progress": 0,
		"daily_claimed": [],
		"lifetime_points": 0,
		"lifetime_claimed": [],
		"log": [
			{
				"id": "welcome",
				"title": "INTAKE COMPLETE",
				"body": "Congratulations on seeking help. The city is still on fire. That is a you problem.",
				"unread": true
			}
		],
		"cbt": [],
		"seen": {"clinic": true, "run": true, "build": false, "locker": false, "awards": false},
		"pin": "",
		"less_gore": false,
		"vol_master": 1.0,
		"vol_sfx": 1.0,
		"vol_vo": 1.0,
		"vol_music": 0.72,
		"difficulty": "night_class",
		"solo_clears": 0,
		"city_clears": 0,
		"raven_kills": 0,
		"remote_clears": 0,
		"rooms_url": "http://127.0.0.1:8787",
		"costume_son": "default",
		"costume_father": "default",
		"combo_banks": 0,
		"intro_done": false,
		"vs_wins": 0,
		"annex_clears": 0,
		"survive_clears": 0,
		"sides_filed": 0,
		"skip_films": false,
		"account_xp": 0,
		"account_level": 1,
		"high_score": 0,
		"ending_seen": false,
		"family_plan_kills": 0,
		"file_alives": 0,
		"legendary_takes": 0,
		"gear_upgrades": 0,
		"owned_gear": ["hoodie_lemon", "polo_navy", "headband", "parkour_kicks", "loafer_web"],
		"gear_levels": {},
		"loadout": {
			"son": {"clothes": "hoodie_lemon", "hat": "headband", "shoes": "parkour_kicks"},
			"father": {"clothes": "polo_navy", "hat": "headband", "shoes": "loafer_web"}
		},
		"unseen": [],
		"frame_son": "frame_intake",
		"frame_father": "frame_intake",
		"banner_son": "banner_clinic",
		"banner_father": "banner_clinic",
		"badge_son": "",
		"badge_father": "",
		"owned_frames": ["frame_intake"],
		"owned_banners": ["banner_clinic"],
		"owned_badges": [],
		"patrol_left": 2,
		"patrol_day": "",
		"patrol_until": 0,
		"patrol_active": false,
		"last_unix": 0,
		"research": [],
		"dojo": {},
		"dojo_masters": 0,
		"parts": { "scrap_coil": 2, "clinic_thread": 0, "invoice_ink": 0 },
		"stomps": 0,
		"tricks": 0,
		"perfect_tricks": 0,
		"patrols": 0,
		"menu_alert": false,
		"patrol_bank_gold": 0,
		"patrol_bank_xp": 0
	}


func _migrate() -> void:
	var d := _defaults()
	for k in d.keys():
		if not data.has(k):
			data[k] = d[k]
	for id in BUILDINGS:
		if not data["buildings"].has(id):
			data["buildings"][id] = 1 if id in ["front_desk", "street_map"] else 0
	if str(data.get("costume_son", "default")) == "night_tutor":
		_wear("son", "clothes", "night_tutor")
	if str(data.get("costume_father", "default")) == "pink_slip":
		_wear("father", "clothes", "pink_slip")
	_roll_patrol_day()
	sync_cosmetics(false)
	settle_idle()


func father_name() -> String:
	var n := str(data.get("father_name", "")).strip_edges()
	return n if n != "" else "THE FATHER"


func son_name() -> String:
	var n := str(data.get("son_name", "")).strip_edges()
	return n if n != "" else "THE SON"


func building_level(id: String) -> int:
	if not data.has("buildings"):
		load_or_create()
	return int((data["buildings"] as Dictionary).get(id, 0))


func is_built(id: String) -> bool:
	return building_level(id) > 0


func tab_unlocked(tab: String) -> bool:
	match tab:
		"clinic", "run":
			return true
		"build":
			return is_built("therapy_couch")
		"locker":
			return is_built("wardrobe_cage")
		"awards":
			return is_built("trophy_cabinet")
		_:
			return false


func build_cost(id: String) -> int:
	var lvl := building_level(id)
	if lvl == 0:
		return 15
	return 20 + lvl * 10


func try_build(id: String) -> bool:
	var cost := build_cost(id)
	if int(data["gold"]) < cost:
		return false
	data["gold"] = int(data["gold"]) - cost
	data["buildings"][id] = building_level(id) + 1
	data["buildings_tapped"] = int(data["buildings_tapped"]) + 1
	_bump_daily("build")
	flag_unseen("build_%s" % id)
	save()
	return true


func add_gold(n: int) -> void:
	data["gold"] = int(data["gold"]) + n
	save()


func add_gems(n: int) -> void:
	data["gems"] = int(data["gems"]) + n
	save()


func grant(gold: int, gems: int, line: String) -> void:
	if gold:
		data["gold"] = int(data["gold"]) + gold
		claimed.emit("gold", gold, line)
	if gems:
		data["gems"] = int(data["gems"]) + gems
		claimed.emit("gems", gems, line)
	save()


func mark_run_finished(ok: bool = true) -> void:
	data["runs"] = int(data["runs"]) + 1
	data["lifetime_points"] = int(data["lifetime_points"]) + (2 if ok else 1)
	data["rep"] = int(data["rep"]) + (1 if ok else 0)
	_bump_daily("run")
	save()


func mark_solo_clear() -> void:
	data["solo_clears"] = int(data.get("solo_clears", 0)) + 1
	save()
	Juice.toast("achievement", "I DIDN'T NEED HIM", "One chair. Same street. Filed anyway.")


func mark_city_clear() -> void:
	data["city_clears"] = int(data.get("city_clears", 0)) + 1
	save()
	Juice.toast("quest", "CITY HALL", "The landlord lost. The invoice won.")


func mark_raven() -> void:
	data["raven_kills"] = int(data.get("raven_kills", 0)) + 1
	save()
	Juice.toast("achievement", "THE LANDLORD HAD THROWING STARS", "Cape down. Election over.")


func mark_remote_clear() -> void:
	data["remote_clears"] = int(data.get("remote_clears", 0)) + 1
	save()
	Juice.toast("achievement", "LONG DISTANCE PARENTING", "Two cities. One camera.")


func mark_heavy() -> void:
	data["heavies"] = int(data["heavies"]) + 1
	save()


func mark_light() -> void:
	data["lights"] = int(data["lights"]) + 1
	save()


func mark_snap() -> void:
	data["snaps"] = int(data.get("snaps", 0)) + 1
	save()


func _bump_daily(kind: String) -> void:
	_roll_daily()
	var flags: Dictionary = data.get("daily_flags", {})
	if not flags.get(kind, false):
		flags[kind] = true
		data["daily_flags"] = flags
		data["daily_progress"] = mini(5, int(data["daily_progress"]) + 1)


func _roll_daily() -> void:
	var today := Time.get_date_string_from_system()
	if str(data.get("daily_date", "")) != today:
		data["daily_date"] = today
		data["daily_progress"] = 0
		data["daily_claimed"] = []
		data["daily_flags"] = {}
		_roll_patrol_day()


func unread_log_count() -> int:
	var n := 0
	for item in data["log"]:
		if item.get("unread", false):
			n += 1
	return n


func mark_log_read() -> void:
	for item in data["log"]:
		item["unread"] = false
	_bump_daily("log")
	save()


func has_cbt(id: String) -> bool:
	return (data["cbt"] as Array).has(id)


func less_gore() -> bool:
	return bool(data.get("less_gore", false))


func costume_for(role: String) -> String:
	return equipped_id(role, "clothes")


func equipped_id(role: String, slot: String) -> String:
	var loadout: Dictionary = data.get("loadout", {})
	var row: Variant = loadout.get(role, {})
	if typeof(row) != TYPE_DICTIONARY:
		return ""
	return str((row as Dictionary).get(slot, ""))


func owns_gear(id: String) -> bool:
	var owned: Array = data.get("owned_gear", [])
	return owned.has(id)


func gear_level(id: String) -> int:
	var lv: Dictionary = data.get("gear_levels", {})
	return int(lv.get(id, 0))


func gear_stat_bonus(role: String) -> Dictionary:
	var out := {"hp": 0, "dmg": 0, "steam": 0, "speed": 0}
	for slot in ["clothes", "hat", "shoes"]:
		var spec := GearBook.item(equipped_id(role, slot))
		if spec.is_empty():
			continue
		var st: Variant = spec.get("stats", {})
		var lvl := gear_level(str(spec.get("id", "")))
		if typeof(st) != TYPE_DICTIONARY:
			continue
		for k in out.keys():
			out[k] = int(out[k]) + int((st as Dictionary).get(k, 0)) + lvl
	return out


func try_buy_gear(id: String) -> bool:
	var spec := GearBook.item(id)
	if spec.is_empty() or owns_gear(id):
		return false
	if int(data.get("gold", 0)) < int(spec.get("gold", 0)):
		return false
	if int(data.get("rep", 0)) < int(spec.get("rep", 0)):
		return false
	data["gold"] = int(data["gold"]) - int(spec.get("gold", 0))
	(data["owned_gear"] as Array).append(id)
	save()
	return true


func try_upgrade_gear(id: String) -> bool:
	if not owns_gear(id):
		return false
	var spec := GearBook.item(id)
	var lvl := gear_level(id)
	if lvl >= 3:
		return false
	var cost := int(spec.get("upgrade", 20)) * (lvl + 1)
	if int(data.get("gold", 0)) < cost:
		return false
	data["gold"] = int(data["gold"]) - cost
	var lv: Dictionary = data.get("gear_levels", {})
	lv[id] = lvl + 1
	data["gear_levels"] = lv
	data["gear_upgrades"] = int(data.get("gear_upgrades", 0)) + 1
	save()
	return true


func wear_slot(role: String, slot: String, id: String) -> bool:
	if not owns_gear(id):
		return false
	var spec := GearBook.item(id)
	var who := str(spec.get("role", "any"))
	if who != "any" and who != role:
		return false
	_wear(role, slot, id)
	save()
	return true


func _wear(role: String, slot: String, id: String) -> void:
	var loadout: Dictionary = data.get("loadout", {})
	var row: Dictionary = loadout.get(role, {})
	row[slot] = id
	loadout[role] = row
	data["loadout"] = loadout
	if slot == "clothes":
		if role == "son":
			data["costume_son"] = id
		else:
			data["costume_father"] = id


func account_need() -> int:
	return 100 + int(data.get("account_level", 1)) * 50


func grant_account_xp(n: int) -> Dictionary:
	var gained := maxi(0, n)
	if has_cbt("pinball_brain"):
		gained = int(round(float(gained) * 1.2))
	data["account_xp"] = int(data.get("account_xp", 0)) + gained
	var dings := 0
	while int(data["account_xp"]) >= account_need():
		data["account_xp"] = int(data["account_xp"]) - account_need()
		data["account_level"] = int(data.get("account_level", 1)) + 1
		data["gold"] = int(data.get("gold", 0)) + 8
		dings += 1
		flag_unseen("level_%d" % int(data["account_level"]))
	save()
	var out := {
		"gained": gained,
		"xp": int(data["account_xp"]),
		"need": account_need(),
		"level": int(data["account_level"]),
		"dings": dings
	}
	if dings > 0:
		Juice.level_up(out)
		sync_cosmetics(true)
	return out


func note_score(total: int) -> void:
	if total > int(data.get("high_score", 0)):
		data["high_score"] = total
		save()


func reset_progress() -> void:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	backup_to("user://family.json.bak")
	backup_to("user://family-%s.bak.json" % stamp)
	data = _defaults()
	save()
	Juice.toast("challenge", "PROGRESS WIPED", "Backup kept. The fridge does not remember you.")


func mark_ending() -> void:
	data["ending_seen"] = true
	data["rep"] = int(data.get("rep", 0)) + 2
	save()
	Juice.toast("achievement", "THE FRIDGE STAYS", "Homework over. The clipboard is a corpse.")


func mark_family_plan() -> void:
	data["family_plan_kills"] = int(data.get("family_plan_kills", 0)) + 1
	save()


func mark_file_alive() -> void:
	data["file_alives"] = int(data.get("file_alives", 0)) + 1
	save()


func mark_legendary() -> void:
	data["legendary_takes"] = int(data.get("legendary_takes", 0)) + 1
	save()


func costume_unlocked(id: String) -> bool:
	if id == "default":
		return true
	return int(data.get("rep", 0)) >= 8


func wear_costume(role: String, id: String) -> bool:
	if not costume_unlocked(id):
		return false
	if role == "son":
		data["costume_son"] = id
	else:
		data["costume_father"] = id
	save()
	return true


func mark_combo_bank(hits: int) -> void:
	data["combo_banks"] = int(data.get("combo_banks", 0)) + 1
	if hits >= 20:
		data["lifetime_points"] = int(data.get("lifetime_points", 0)) + 1
	save()


func mark_intro() -> void:
	data["intro_done"] = true
	save()
	Juice.toast("achievement", "INTAKE FILMED", "Two films, three panels, one dummy. Homework starts.")


func mark_vs() -> void:
	data["vs_wins"] = int(data.get("vs_wins", 0)) + 1
	save()
	Juice.toast("achievement", "THERAPY MATCH", "Someone got GROUNDED. Someone got fired.")


func mark_annex() -> void:
	data["annex_clears"] = int(data.get("annex_clears", 0)) + 1
	save()
	Juice.toast("quest", "INVOICE PIER", "Dr. Splint filed. The bill did not die. It just moved.")


func mark_survive(map_id: String) -> void:
	data["survive_clears"] = int(data.get("survive_clears", 0)) + 1
	save()
	Juice.toast("achievement", "COPING HOUR", "%s held. The magnet still wants a tip." % map_id.replace("_", " ").to_upper())


func mark_side() -> void:
	data["sides_filed"] = int(data.get("sides_filed", 0)) + 1
	save()


func push_log(title: String, body: String) -> void:
	(data["log"] as Array).push_front({
		"id": "n%d" % Time.get_ticks_msec(),
		"title": title,
		"body": body,
		"unread": true
	})
	save()


func flag_unseen(id: String) -> void:
	var u: Array = data.get("unseen", [])
	if not u.has(id):
		u.append(id)
		data["unseen"] = u
	data["menu_alert"] = true


func peek_menu() -> void:
	data["menu_alert"] = false
	save()


func has_menu_alert() -> bool:
	return bool(data.get("menu_alert", false)) or has_unseen()


func mark_seen(id: String) -> void:
	var u: Array = data.get("unseen", [])
	u.erase(id)
	data["unseen"] = u
	save()


func has_unseen() -> bool:
	return not (data.get("unseen", []) as Array).is_empty()


func is_unseen(id: String) -> bool:
	return (data.get("unseen", []) as Array).has(id)


func equipped_cosmetic(role: String, kind: String) -> String:
	return str(data.get("%s_%s" % [kind, role], ""))


func wear_cosmetic(role: String, kind: String, id: String) -> bool:
	var key := "owned_%ss" % kind
	if kind == "badge":
		key = "owned_badges"
	var owned: Array = data.get(key, [])
	if id != "" and not owned.has(id):
		return false
	data["%s_%s" % [kind, role]] = id
	mark_seen(id)
	save()
	return true


func grant_cosmetic(kind: String, id: String, shout := true) -> bool:
	var key := "owned_frames"
	if kind == "banner":
		key = "owned_banners"
	elif kind == "badge":
		key = "owned_badges"
	var owned: Array = data.get(key, [])
	if owned.has(id):
		return false
	owned.append(id)
	data[key] = owned
	flag_unseen(id)
	if shout:
		var spec := Cosmetics.item(kind + "s" if kind != "badge" else "badges", id)
		if kind == "badge":
			spec = Cosmetics.item("badges", id)
		elif kind == "frame":
			spec = Cosmetics.item("frames", id)
		else:
			spec = Cosmetics.item("banners", id)
		var title := str(spec.get("title", id))
		Juice.unlock_logo(title, str(spec.get("blurb", "Proof. Pin it.")), "%s  ·  %s" % [kind.to_upper(), Rarity.label(str(spec.get("rarity", "common")))])
		Rarity.juice(str(spec.get("rarity", "common")), title)
	save()
	return true


func sync_cosmetics(shout := false) -> void:
	for kind_v in ["frames", "banners", "badges"]:
		var kind := str(kind_v)
		var short: String = kind.substr(0, kind.length() - 1)
		if kind == "badges":
			short = "badge"
		for row in Cosmetics.list_for(kind):
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var id := str((row as Dictionary).get("id", ""))
			if Cosmetics.need_ok(row):
				grant_cosmetic(short, id, shout)


func part_n(id: String) -> int:
	var p: Dictionary = data.get("parts", {})
	return int(p.get(id, 0))


func add_parts(id: String, n: int) -> void:
	var p: Dictionary = data.get("parts", {})
	p[id] = int(p.get(id, 0)) + n
	data["parts"] = p
	save()


func spend_parts(need: Dictionary) -> bool:
	for k in need.keys():
		if part_n(str(k)) < int(need[k]):
			return false
	var p: Dictionary = data.get("parts", {})
	for k in need.keys():
		p[k] = int(p.get(k, 0)) - int(need[k])
	data["parts"] = p
	return true


func has_research(id: String) -> bool:
	return (data.get("research", []) as Array).has(id)


func try_research(id: String) -> bool:
	if has_research(id) or not is_built("research_lab"):
		return false
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/research.json"))
	var spec := {}
	for row in table:
		if str(row.get("id", "")) == id:
			spec = row
			break
	if spec.is_empty():
		return false
	if int(data.get("gold", 0)) < int(spec.get("gold", 0)):
		return false
	var need: Dictionary = spec.get("parts", {})
	if not spend_parts(need):
		return false
	data["gold"] = int(data["gold"]) - int(spec.get("gold", 0))
	(data["research"] as Array).append(id)
	flag_unseen("research_%s" % id)
	save()
	Juice.unlock_logo(str(spec.get("title", id)), str(spec.get("blurb", "")), "RESEARCH  ·  %s" % Rarity.label(str(spec.get("rarity", "common"))))
	Rarity.juice(str(spec.get("rarity", "common")), str(spec.get("title", id)))
	return true


func dojo_rank(id: String) -> int:
	var d: Dictionary = data.get("dojo", {})
	return int(d.get(id, 0))


func try_dojo(id: String) -> bool:
	if not is_built("dojo"):
		return false
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/dojo.json"))
	var spec := {}
	for row in table:
		if str(row.get("id", "")) == id:
			spec = row
			break
	if spec.is_empty():
		return false
	var rank := dojo_rank(id)
	if rank >= 3:
		return false
	var costs: Array = spec.get("gold", [20, 35, 55])
	var cost := int(costs[mini(rank, costs.size() - 1)])
	if int(data.get("gold", 0)) < cost:
		return false
	data["gold"] = int(data["gold"]) - cost
	var d: Dictionary = data.get("dojo", {})
	d[id] = rank + 1
	data["dojo"] = d
	if int(d[id]) >= 3:
		data["dojo_masters"] = int(data.get("dojo_masters", 0)) + 1
		grant_cosmetic("badge", "badge_shaolin", true)
	flag_unseen("dojo_%s" % id)
	save()
	var title := str(spec.get("title", id))
	Juice.unlock_logo("%s  RANK %d" % [title, int(d[id])], "Shaolin billing. The move is meaner.", "MOVE  ·  RANK %d/3" % int(d[id]))
	return true


func _roll_patrol_day() -> void:
	var today := Time.get_date_string_from_system()
	if str(data.get("patrol_day", "")) != today:
		data["patrol_day"] = today
		data["patrol_left"] = 2


func settle_idle() -> void:
	_roll_patrol_day()
	if not bool(data.get("patrol_active", false)):
		return
	var now := int(Time.get_unix_time_from_system())
	var last := int(data.get("last_unix", now))
	if last <= 0:
		last = now
	var until := int(data.get("patrol_until", 0))
	var end_t := now
	if until > 0:
		end_t = mini(now, until)
	var elapsed := maxi(0, end_t - last)
	var ticks := int(elapsed / 15)
	if ticks > 0:
		_bank_patrol(ticks)


func _bank_patrol(ticks: int) -> void:
	data["patrol_bank_gold"] = int(data.get("patrol_bank_gold", 0)) + ticks
	data["patrol_bank_xp"] = int(data.get("patrol_bank_xp", 0)) + ticks * 2


var _idle_acc := 0.0


func _process(delta: float) -> void:
	if not bool(data.get("patrol_active", false)):
		return
	_idle_acc += delta
	if _idle_acc < 15.0:
		return
	_idle_acc = 0.0
	if patrol_ready():
		return
	_bank_patrol(1)


func patrol_ready() -> bool:
	return bool(data.get("patrol_active", false)) and int(Time.get_unix_time_from_system()) >= int(data.get("patrol_until", 0))


func start_patrol() -> bool:
	if not is_built("patrol_desk"):
		return false
	_roll_patrol_day()
	if int(data.get("patrol_left", 0)) <= 0:
		return false
	if bool(data.get("patrol_active", false)) and not patrol_ready():
		return false
	if patrol_ready():
		claim_patrol()
	data["patrol_left"] = int(data["patrol_left"]) - 1
	data["patrol_active"] = true
	data["patrol_until"] = int(Time.get_unix_time_from_system()) + 12 * 60
	save()
	Juice.unlock_logo("QUICK PATROL", "Idle of the Dead energy. Ticks while you play and while the fridge is closed.", "PATROL  ·  12 MIN  ·  2×/DAY")
	return true


func claim_patrol() -> Dictionary:
	if not patrol_ready():
		return {}
	data["patrol_active"] = false
	data["patrols"] = int(data.get("patrols", 0)) + 1
	var bank_g := int(data.get("patrol_bank_gold", 0))
	var bank_x := int(data.get("patrol_bank_xp", 0))
	data["patrol_bank_gold"] = 0
	data["patrol_bank_xp"] = 0
	add_gold(18 + bank_g)
	add_parts("scrap_coil", 1)
	var xp_n := 40 + bank_x
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("idle_alibi"):
		add_gold(int(round(float(18 + bank_g) * 0.5)))
		xp_n = int(round(float(xp_n) * 1.5))
	var xp := grant_account_xp(xp_n)
	save()
	Juice.unlock_logo("PATROL FILED", "The alley walked itself. Gold and XP came home.", "+%d GOLD  ·  +%d XP  ·  COIL" % [18 + bank_g, int(xp.get("gained", 40))])
	return xp


func mark_trick() -> void:
	data["tricks"] = int(data.get("tricks", 0)) + 1
	sync_cosmetics(true)
	save()


func mark_perfect() -> void:
	data["perfect_tricks"] = int(data.get("perfect_tricks", 0)) + 1
	save()


func mark_stomp() -> void:
	data["stomps"] = int(data.get("stomps", 0)) + 1
	sync_cosmetics(true)
	save()


func try_craft(id: String) -> bool:
	if not is_built("workshop"):
		return false
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/crafts.json"))
	var spec := {}
	for row in table:
		if str(row.get("id", "")) == id:
			spec = row
			break
	if spec.is_empty():
		return false
	if int(data.get("gold", 0)) < int(spec.get("gold", 0)):
		return false
	var need: Dictionary = spec.get("parts", {})
	if not spend_parts(need):
		return false
	data["gold"] = int(data["gold"]) - int(spec.get("gold", 0))
	var grant := str(spec.get("grant", ""))
	if grant == "gear_hat":
		var hat := equipped_id("son", "hat")
		if hat != "":
			try_upgrade_gear(hat)
	elif grant != "" and not has_research(grant):
		(data["research"] as Array).append(grant)
	flag_unseen("craft_%s" % id)
	save()
	Juice.unlock_logo(str(spec.get("title", id)), str(spec.get("blurb", "Crafted. Filed.")), "CRAFT  ·  %s" % Rarity.label(str(spec.get("rarity", "common"))))
	Rarity.juice(str(spec.get("rarity", "common")), str(spec.get("title", id)))
	return true
