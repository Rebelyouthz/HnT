extends Node

signal changed
signal claimed(kind: String, amount: int, line: String)

const SAVE_PATH := "user://family.json"
const BUILDINGS := [
	"front_desk", "street_map", "therapy_couch", "wardrobe_cage",
	"trophy_cabinet", "mail_slot", "bulletin_board", "compare_mirrors", "blood_fridge"
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
		"rooms_url": "http://127.0.0.1:8787"
	}


func _migrate() -> void:
	var d := _defaults()
	for k in d.keys():
		if not data.has(k):
			data[k] = d[k]
	for id in BUILDINGS:
		if not data["buildings"].has(id):
			data["buildings"][id] = 1 if id in ["front_desk", "street_map"] else 0


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


func push_log(title: String, body: String) -> void:
	(data["log"] as Array).push_front({
		"id": "n%d" % Time.get_ticks_msec(),
		"title": title,
		"body": body,
		"unread": true
	})
	save()
