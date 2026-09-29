extends Node

signal changed
signal claimed(kind: String, amount: int, line: String)

const SAVE_PATH := "user://family.json"
const BUILDINGS := [
	"front_desk", "street_map", "therapy_couch", "wardrobe_cage",
	"trophy_cabinet", "mail_slot", "bulletin_board", "compare_mirrors", "blood_fridge",
	"pawn_shop", "patrol_desk", "research_lab", "dojo", "workshop",
	"bounty_board", "radio_tower", "album_wall",
	"streak_locker", "invoice_wheel", "punching_bag", "warrant_fax",
	"tip_jar", "lost_found", "payphone", "water_cooler", "coat_check",
	"time_clock", "bleach_closet"
]

var data: Dictionary = {}


func _enter_tree() -> void:
	load_or_create()


func load_or_create() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var raw := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed: Variant = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			data = _whole(parsed) as Dictionary
			_migrate()
			return
	data = _defaults()
	save()


## JSON has one number type: counters saved as 40 load back as 40.0 and the
## menus printed "GOLD 40.0". Whole floats become ints again; volume sliders
## (vol_*) stay floats.
static func _whole(v: Variant, key: String = "") -> Variant:
	if v is Dictionary:
		var d := {}
		for k in (v as Dictionary):
			d[k] = _whole((v as Dictionary)[k], str(k))
		return d
	if v is Array:
		var a := []
		for x in (v as Array):
			a.append(_whole(x, key))
		return a
	if v is float and not key.begins_with("vol_") and is_equal_approx(float(v), roundf(float(v))) and absf(float(v)) < 9.0e15:
		return int(v)
	return v


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
		"skinwalkers_filed": 0,
		"unmasks": 0,
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
		"patrol_bank_xp": 0,
		"album": [],
		"bounties_claimed": [],
		"bounty_counts": {},
		"radio_day": "",
		"radio_heard": 0,
		"heat_peak": 0,
		"polaroids": 0,
		"smash_kills": 0,
		"dual_snaps": 0,
		"parries": 0,
		"snacks_bought": 0,
		"lottery_spins": 0,
		"streak": 0,
		"streak_best": 0,
		"streak_claimed": [],
		"snack_buff": "",
		"bounces": 0,
		"bag_rounds": 0,
		"bag_hits": 0,
		"revenges": 0,
		"cart_rides": 0,
		"faxes": 0,
		"fax_day": "",
		"catches": 0,
		"clashes": 0,
		"awnings": 0,
		"tips": 0,
		"phones": 0,
		"papers": 0,
		"perfect_parries": 0,
		"packed_weapon": "",
		"lost_found_day": "",
		"phone_day": "",
		"barrels": 0,
		"grinds": 0,
		"poles": 0,
		"wallkicks": 0,
		"dives": 0,
		"coolers": 0,
		"coats": 0,
		"cooler_day": "",
		"coat_day": "",
		"hoods": 0,
		"benches": 0,
		"manholes": 0,
		"slides": 0,
		"clocks": 0,
		"bleaches": 0,
		"clock_day": "",
		"bleach_day": "",
		"last_descent": "",
		"towers_climbed": 0,
		"summit_meals": 0,
		"secrets_found": 0,
		"secret_ids": [],
		"talk_choices": {},
		"maps_filed": [],
		"crafts": []
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


func next_run_map() -> String:
	var filed: Array = data.get("maps_filed", [])
	for id in App.ORDER:
		if not filed.has(id):
			return str(id)
	return "dock_street"


func mark_map_filed(id: String) -> void:
	if id == "" or id == "tutorial_alley" or id == "intro_flow":
		return
	var filed: Array = data.get("maps_filed", [])
	if filed.has(id):
		return
	filed.append(id)
	data["maps_filed"] = filed
	save()


func cash_fail(scrap: int, score: int) -> int:
	var gold := 10 + int(scrap / 4.0) + mini(20, int(score / 50.0))
	add_gold(gold)
	return gold


func has_craft(id: String) -> bool:
	return (data.get("crafts", []) as Array).has(id)


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
	if ok:
		data["streak"] = int(data.get("streak", 0)) + 1
		data["streak_best"] = maxi(int(data.get("streak_best", 0)), int(data["streak"]))
		flag_unseen("build_streak_locker")
	else:
		data["streak"] = 0
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


func try_cbt(id: String) -> bool:
	if has_cbt(id):
		return false
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/cbt.json"))
	var spec := {}
	for row in list:
		if str(row.get("id", "")) == id:
			spec = row
			break
	if spec.is_empty():
		return false
	var req := str(spec.get("requires", ""))
	if req != "" and not has_cbt(req):
		return false
	if int(data.get("gold", 0)) < int(spec.get("gold", 0)):
		return false
	if int(data.get("rep", 0)) < int(spec.get("rep", 0)):
		return false
	data["gold"] = int(data["gold"]) - int(spec.get("gold", 0))
	(data["cbt"] as Array).append(id)
	save()
	Rarity.juice(str(spec.get("rarity", "common")), str(spec.get("name", id)))
	Juice.claim_burst(Vector2(640, 360), "COPING MECHANISM INSTALLED", 0, 0)
	Juice.toast("reward", str(spec.get("name", id)), "COPING MECHANISM INSTALLED")
	return true


func note_tower() -> void:
	data["towers_climbed"] = int(data.get("towers_climbed", 0)) + 1
	save()


func note_summit_meal() -> void:
	data["summit_meals"] = int(data.get("summit_meals", 0)) + 1
	save()


func note_secret(id: String) -> void:
	var ids: Array = data.get("secret_ids", [])
	if ids.has(id):
		return
	ids.append(id)
	data["secret_ids"] = ids
	data["secrets_found"] = ids.size()
	save()


func note_talk_choice(talk_id: String, choice: String) -> void:
	var t: Dictionary = data.get("talk_choices", {})
	t[talk_id] = choice
	data["talk_choices"] = t
	save()


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
	flag_unseen("gear_%s" % id)
	save()
	Juice.unlock_logo(str(spec.get("name", id)), str(spec.get("blurb", "Clothes with opinions.")), "GEAR  ·  %s" % Rarity.label(str(spec.get("rarity", "common"))))
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
	if has_cbt("school_pride"):
		gained = int(round(float(gained) * 1.1))
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
	if int(d[id]) == 1:
		Juice.unlock_logo("%s  LEARNED" % title, "Dojo gates the move. Rank 1 unlocks. Rank 3 pins a badge.", "MOVE  ·  UNLOCKED")
		VoBank.father_level() if str(spec.get("kind", "")) == "combat" else VoBank.son_trick()
	else:
		Juice.unlock_logo("%s  RANK %d" % [title, int(d[id])], "Shaolin billing. The move is meaner.", "MOVE  ·  RANK %d/3" % int(d[id]))
	return true


func dojo_learned(id: String) -> bool:
	return dojo_rank(id) >= 1


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
	bump_bounty("stomp")
	sync_cosmetics(true)
	save()


func mark_smash() -> void:
	data["smash_kills"] = int(data.get("smash_kills", 0)) + 1
	save()


func mark_dual_snap() -> void:
	data["dual_snaps"] = int(data.get("dual_snaps", 0)) + 1
	save()


func mark_parry() -> void:
	data["parries"] = int(data.get("parries", 0)) + 1
	save()


func mark_bounce() -> void:
	data["bounces"] = int(data.get("bounces", 0)) + 1
	save()


func mark_skinwalker() -> void:
	data["skinwalkers_filed"] = int(data.get("skinwalkers_filed", 0)) + 1
	save()


func mark_unmask() -> void:
	data["unmasks"] = int(data.get("unmasks", 0)) + 1
	save()


func stash_snack(kind: String) -> void:
	data["snack_buff"] = kind
	save()


func buy_snack(kind: String, gold: int) -> bool:
	if int(data.get("gold", 0)) < gold:
		return false
	data["gold"] = int(data["gold"]) - gold
	data["snack_buff"] = kind
	data["snacks_bought"] = int(data.get("snacks_bought", 0)) + 1
	save()
	return true


func consume_snack_buff() -> String:
	var k := str(data.get("snack_buff", ""))
	if k == "":
		return ""
	data["snack_buff"] = ""
	save()
	return k


func claim_streak(at: int) -> bool:
	var claimed: Array = data.get("streak_claimed", [])
	if claimed.has(at):
		return false
	if int(data.get("streak", 0)) < at:
		return false
	claimed.append(at)
	data["streak_claimed"] = claimed
	var gold := 20 + at * 8
	var gems := 1 if at >= 5 else 0
	grant(gold, gems, "STREAK %d" % at)
	return true


func spin_lottery() -> Dictionary:
	if int(data.get("gems", 0)) < 2:
		return {}
	data["gems"] = int(data["gems"]) - 2
	data["lottery_spins"] = int(data.get("lottery_spins", 0)) + 1
	var bag: Array = [
		{"title": "GOLD RECEIPT", "gold": 28, "gems": 0, "got": "+28 GOLD"},
		{"title": "GOLD RECEIPT", "gold": 28, "gems": 0, "got": "+28 GOLD"},
		{"title": "SCRAP COIL", "gold": 8, "gems": 0, "got": "COIL  ·  +8 GOLD"},
		{"title": "GEM BACK", "gold": 0, "gems": 1, "got": "+1 GEM"},
		{"title": "JACKPOT INVOICE", "gold": 60, "gems": 1, "got": "+60 GOLD  ·  +1 GEM"}
	]
	bag.shuffle()
	var pay: Dictionary = bag[0]
	if int(pay.get("gold", 0)) > 0:
		data["gold"] = int(data["gold"]) + int(pay["gold"])
	if int(pay.get("gems", 0)) > 0:
		data["gems"] = int(data["gems"]) + int(pay["gems"])
	if str(pay.get("title", "")).find("COIL") >= 0:
		add_parts("scrap_coil", 1)
	save()
	return pay


func mark_bag(hits: int) -> void:
	data["bag_rounds"] = int(data.get("bag_rounds", 0)) + 1
	data["bag_hits"] = int(data.get("bag_hits", 0)) + hits
	save()


func mark_revenge() -> void:
	data["revenges"] = int(data.get("revenges", 0)) + 1
	save()


func mark_cart() -> void:
	data["cart_rides"] = int(data.get("cart_rides", 0)) + 1
	save()


func fax_ready() -> bool:
	return str(data.get("fax_day", "")) != Time.get_date_string_from_system()


func fax_today() -> bool:
	if not fax_ready():
		return false
	data["fax_day"] = Time.get_date_string_from_system()
	data["faxes"] = int(data.get("faxes", 0)) + 1
	data["snack_buff"] = "tape"
	grant(8, 0, "FAX FILED")
	return true


func mark_catch() -> void:
	data["catches"] = int(data.get("catches", 0)) + 1
	save()


func mark_clash() -> void:
	data["clashes"] = int(data.get("clashes", 0)) + 1
	save()


func mark_awning() -> void:
	data["awnings"] = int(data.get("awnings", 0)) + 1
	save()


func mark_perfect_parry() -> void:
	data["perfect_parries"] = int(data.get("perfect_parries", 0)) + 1
	save()


func mark_paper() -> void:
	data["papers"] = int(data.get("papers", 0)) + 1
	save()


func toss_tip() -> Dictionary:
	if int(data.get("gold", 0)) < 5:
		return {}
	data["gold"] = int(data["gold"]) - 5
	data["tips"] = int(data.get("tips", 0)) + 1
	var roll := randf()
	var pay := {"line": "THE JAR ATE IT", "gold": 0, "gems": 0}
	if roll < 0.28:
		data["gems"] = int(data.get("gems", 0)) + 1
		pay = {"line": "THE JAR BLINKED  ·  +1 GEM", "gold": 0, "gems": 1}
	elif roll < 0.52:
		data["snack_buff"] = "boost"
		pay = {"line": "SNACK IN THE JAR  ·  BOOST PACKED", "gold": 0, "gems": 0}
	save()
	return pay


func lost_found_ready() -> bool:
	return str(data.get("lost_found_day", "")) != Time.get_date_string_from_system()


func pack_lost_found() -> bool:
	if not lost_found_ready():
		return false
	data["lost_found_day"] = Time.get_date_string_from_system()
	data["packed_weapon"] = "pipe"
	save()
	return true


func consume_packed_weapon() -> String:
	var k := str(data.get("packed_weapon", ""))
	if k == "":
		return ""
	data["packed_weapon"] = ""
	save()
	return k


func payphone_ready() -> bool:
	return str(data.get("phone_day", "")) != Time.get_date_string_from_system()


func call_payphone() -> bool:
	if not payphone_ready():
		return false
	data["phone_day"] = Time.get_date_string_from_system()
	data["phones"] = int(data.get("phones", 0)) + 1
	grant(8, 0, "PAYPHONE")
	return true


func mark_barrel() -> void:
	data["barrels"] = int(data.get("barrels", 0)) + 1
	save()


func mark_grind() -> void:
	data["grinds"] = int(data.get("grinds", 0)) + 1
	save()


func mark_pole() -> void:
	data["poles"] = int(data.get("poles", 0)) + 1
	save()


func mark_wallkick() -> void:
	data["wallkicks"] = int(data.get("wallkicks", 0)) + 1
	save()


func mark_dive() -> void:
	data["dives"] = int(data.get("dives", 0)) + 1
	save()


func cooler_ready() -> bool:
	return str(data.get("cooler_day", "")) != Time.get_date_string_from_system()


func drink_cooler() -> bool:
	if not cooler_ready():
		return false
	data["cooler_day"] = Time.get_date_string_from_system()
	data["coolers"] = int(data.get("coolers", 0)) + 1
	data["snack_buff"] = "steam"
	grant(4, 0, "WATER COOLER")
	return true


func coat_ready() -> bool:
	return str(data.get("coat_day", "")) != Time.get_date_string_from_system()


func claim_coat() -> bool:
	if not coat_ready():
		return false
	data["coat_day"] = Time.get_date_string_from_system()
	data["coats"] = int(data.get("coats", 0)) + 1
	data["snack_buff"] = "tape"
	save()
	return true


func mark_hood() -> void:
	data["hoods"] = int(data.get("hoods", 0)) + 1
	save()


func mark_bench() -> void:
	data["benches"] = int(data.get("benches", 0)) + 1
	save()


func mark_manhole() -> void:
	data["manholes"] = int(data.get("manholes", 0)) + 1
	save()


func mark_slide() -> void:
	data["slides"] = int(data.get("slides", 0)) + 1
	save()


func clock_ready() -> bool:
	return str(data.get("clock_day", "")) != Time.get_date_string_from_system()


func punch_clock() -> bool:
	if not clock_ready():
		return false
	data["clock_day"] = Time.get_date_string_from_system()
	data["clocks"] = int(data.get("clocks", 0)) + 1
	grant(6, 0, "TIME CLOCK")
	return true


func bleach_ready() -> bool:
	return str(data.get("bleach_day", "")) != Time.get_date_string_from_system()


func claim_bleach() -> bool:
	if not bleach_ready():
		return false
	data["bleach_day"] = Time.get_date_string_from_system()
	data["bleaches"] = int(data.get("bleaches", 0)) + 1
	data["snack_buff"] = "steam"
	save()
	return true


func bump_bounty(kind: String) -> void:
	var c: Dictionary = data.get("bounty_counts", {})
	c[kind] = int(c.get(kind, 0)) + 1
	data["bounty_counts"] = c
	flag_unseen("bounty")


func bounty_progress(id: String) -> int:
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/bounties.json"))
	for row in table:
		if str((row as Dictionary).get("id", "")) != id:
			continue
		var kind := str((row as Dictionary).get("kind", ""))
		if kind == "stomp":
			return int(data.get("stomps", 0))
		if kind == "cop":
			return int((data.get("bounty_counts", {}) as Dictionary).get("cop", 0))
		return int((data.get("bounty_counts", {}) as Dictionary).get(kind, 0))
	return 0


func bounty_claimed(id: String) -> bool:
	return (data.get("bounties_claimed", []) as Array).has(id)


func bounty_ready(id: String) -> bool:
	if bounty_claimed(id):
		return false
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/bounties.json"))
	for row in table:
		if str((row as Dictionary).get("id", "")) == id:
			return bounty_progress(id) >= int((row as Dictionary).get("need", 1))
	return false


func claim_bounty(id: String) -> bool:
	if not bounty_ready(id) or not is_built("bounty_board"):
		return false
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/bounties.json"))
	var spec := {}
	for row in table:
		if str((row as Dictionary).get("id", "")) == id:
			spec = row
			break
	if spec.is_empty():
		return false
	(data["bounties_claimed"] as Array).append(id)
	add_gold(int(spec.get("gold", 0)))
	grant_account_xp(int(spec.get("xp", 0)))
	flag_unseen("bounty_%s" % id)
	save()
	Juice.unlock_logo(str(spec.get("title", id)), str(spec.get("blurb", "")), "BOUNTY  ·  +%dG" % int(spec.get("gold", 0)))
	return true


func album_has(id: String) -> bool:
	return (data.get("album", []) as Array).has(id)


func album_ready(info: Dictionary) -> bool:
	var need: Dictionary = info.get("need", {})
	for k in need.keys():
		if int(data.get(str(k), 0)) < int(need[k]):
			return false
	return true


func claim_album(info: Dictionary) -> bool:
	if not is_built("album_wall"):
		return false
	var id := str(info.get("id", ""))
	if album_has(id) or not album_ready(info):
		return false
	(data["album"] as Array).append(id)
	data["polaroids"] = int(data.get("polaroids", 0)) + 1
	add_gold(int(info.get("gold", 0)))
	flag_unseen("album_%s" % id)
	save()
	Juice.play("res://assets/audio/polaroid.wav" if ResourceLoader.exists("res://assets/audio/polaroid.wav") else "res://assets/audio/claim.wav")
	Juice.unlock_logo(str(info.get("title", id)), str(info.get("blurb", "")), "POLAROID  ·  %s" % Rarity.label(str(info.get("rarity", "common"))))
	return true


func radio_line() -> String:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/radio.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return "This is Mayor Raven. The invoice is still due."
	var lines: Array = (parsed as Dictionary).get("lines", [])
	if lines.is_empty():
		return "This is Mayor Raven. The invoice is still due."
	var i := int(data.get("radio_heard", 0)) % lines.size()
	return str(lines[i])


func hear_radio() -> void:
	var today := Time.get_date_string_from_system()
	if str(data.get("radio_day", "")) != today:
		data["radio_day"] = today
		flag_unseen("radio")
	data["radio_heard"] = int(data.get("radio_heard", 0)) + 1
	save()


func grant_prize(id: String) -> void:
	if id.begins_with("gear_"):
		var gid := id.substr(5)
		if not owns_gear(gid):
			(data["owned_gear"] as Array).append(gid)
			flag_unseen("gear_%s" % gid)
			save()
			Juice.unlock_logo(gid.replace("_", " ").to_upper(), "It fell out of a chest. Wear it.", "GEAR")
		return
	if id.begins_with("weapon_"):
		flag_unseen(id)
		save()
		Juice.unlock_logo(id.replace("_", " ").to_upper(), "Caliber with opinions.", "WEAPON")
		return
	if id == "envelope":
		add_gold(18)
		data["gems"] = int(data.get("gems", 0)) + 1
		save()
		Juice.unlock_logo("LUCKY ENVELOPE", "Mystery mail. The Session Log would be jealous.", "+18 GOLD  ·  +1 GEM")
		Juice.play("res://assets/audio/envelope.wav" if ResourceLoader.exists("res://assets/audio/envelope.wav") else "res://assets/audio/claim.wav")


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
	var crafts: Array = data.get("crafts", [])
	if not crafts.has(id):
		crafts.append(id)
		data["crafts"] = crafts
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
