class_name Contracts
extends RefCounted

## DAILY CONTRACTS: three jobs a day, picked from a pool by the date, that
## count lifetime numbers from where they stood when the day began. Finish
## one and claim its pay (gold, gems, tokens or flow).

const POOL := [
	{"id": "kills", "key": "kills_total", "n": 40, "title": "FILE 40 THUGS", "pay": {"gold": 80}},
	{"id": "tricks", "key": "tricks", "n": 15, "title": "LAND 15 TRICKS", "pay": {"flow": 30}},
	{"id": "smash", "key": "smash_kills", "n": 6, "title": "6 SMASH KILLS", "pay": {"gold": 70}},
	{"id": "parry", "key": "parries", "n": 8, "title": "8 PARRIES", "pay": {"gems": 1}},
	{"id": "shards", "key": "shards_found", "n": 6, "title": "PICK UP 6 SHARDS", "pay": {"gold": 60}},
	{"id": "bounce", "key": "bounces", "n": 5, "title": "5 WALL BOUNCES", "pay": {"tokens": 25}},
	{"id": "events", "key": "street_events", "n": 2, "title": "LIVE THROUGH 2 STREET EVENTS", "pay": {"gems": 1}},
	{"id": "hours", "key": "survive_clears", "n": 1, "title": "HOLD ONE COPING HOUR", "pay": {"tokens": 40}},
	{"id": "refund", "key": "refunds", "n": 1, "title": "CATCH THE TAX REFUND", "pay": {"gold": 120}},
	{"id": "combo", "key": "combo_rewards", "n": 2, "title": "HIT 2 COMBO MILESTONES", "pay": {"flow": 25}},
	{"id": "bless", "key": "blessings", "n": 2, "title": "BUY 2 BLESSINGS", "pay": {"gold": 50}},
]


static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


static func _state() -> Dictionary:
	var st: Dictionary = FamilyProfile.data.get("contracts", {})
	if str(st.get("day", "")) != today():
		var seed_n := hash(today())
		var idx: Array = []
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_n
		while idx.size() < 3:
			var k := rng.randi_range(0, POOL.size() - 1)
			if not idx.has(k):
				idx.append(k)
		var base := {}
		for k in idx:
			var key := str(POOL[k]["key"])
			base[key] = int(FamilyProfile.data.get(key, 0))
		st = {"day": today(), "idx": idx, "base": base, "claimed": []}
		FamilyProfile.data["contracts"] = st
	return st


static func list() -> Array:
	var st := _state()
	var out: Array = []
	for k in st["idx"]:
		var row: Dictionary = (POOL[int(k)] as Dictionary).duplicate()
		var key := str(row["key"])
		row["have"] = mini(int(row["n"]), int(FamilyProfile.data.get(key, 0)) - int((st["base"] as Dictionary).get(key, 0)))
		row["claimed"] = (st["claimed"] as Array).has(str(row["id"]))
		out.append(row)
	return out


static func ready_count() -> int:
	var n := 0
	for r: Dictionary in list():
		if not bool(r["claimed"]) and int(r["have"]) >= int(r["n"]):
			n += 1
	return n


static func claim(id: String) -> bool:
	for r: Dictionary in list():
		if str(r["id"]) == id and not bool(r["claimed"]) and int(r["have"]) >= int(r["n"]):
			var pay: Dictionary = r["pay"]
			for cur in pay:
				if cur == "tokens":
					FamilyProfile.data["tokens"] = int(FamilyProfile.data.get("tokens", 0)) + int(pay[cur])
				elif cur == "flow":
					Trees.add_flow(int(pay[cur]))
				elif cur == "gems":
					FamilyProfile.add_gems(int(pay[cur]))
				else:
					FamilyProfile.add_gold(int(pay[cur]))
			(_state()["claimed"] as Array).append(id)
			FamilyProfile.data["contracts_done"] = int(FamilyProfile.data.get("contracts_done", 0)) + 1
			FamilyProfile.save()
			return true
	return false


static func pay_text(pay: Dictionary) -> String:
	var parts: Array[String] = []
	for cur in pay:
		parts.append("%d %s" % [int(pay[cur]), str(cur).to_upper()])
	return "  ".join(parts)
