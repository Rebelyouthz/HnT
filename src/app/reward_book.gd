class_name RewardBook
extends RefCounted

## The REWARDS desk (menus): one place for everything that can be claimed.
##   DAILY CRATE   a free crate once a day; a 7-day streak grows the crate
##                 (day 7 is the big one), missing a day starts it over
##   CLINIC ROAD   every account level pays out; every 5th a big one + title
##   TITLES        earned from play (finishers, codex, styles, challenges...),
##                 worn under the names in the hub
##   POWER         one number for the whole family; the hub counts it up
##                 when it grew since you last looked
## Plus the claimables of the other systems (codex, jobs, awards) so CLAIM
## ALL takes everything in one go.

const DAILY := [
	{"gold": 40, "gems": 0, "tokens": 10},
	{"gold": 60, "gems": 1, "tokens": 15},
	{"gold": 80, "gems": 1, "tokens": 20},
	{"gold": 100, "gems": 2, "tokens": 25},
	{"gold": 130, "gems": 2, "tokens": 30},
	{"gold": 160, "gems": 3, "tokens": 40},
	{"gold": 250, "gems": 6, "tokens": 60},
]

const TITLES := {
	"new_patient": {"title": "NEW PATIENT", "line": "Walk in the door.", "key": "", "n": 0},
	"regular": {"title": "THE REGULAR", "line": "Finish 10 nights.", "key": "runs", "n": 10},
	"executioner": {"title": "EXECUTIONER", "line": "Land 10 FINISHERS.", "key": "finishers", "n": 10},
	"archivist": {"title": "ARCHIVIST", "line": "File 25 CODEX entries.", "key": "_codex", "n": 25},
	"stylish": {"title": "SSS STYLE", "line": "Get an S grade or better on a roof run.", "key": "_style", "n": 1},
	"survivor": {"title": "CLOCKED OUT", "line": "Finish 3 survivor challenges.", "key": "_challenges", "n": 3},
	"union_rep": {"title": "UNION REP", "line": "Finish 10 JOBS.", "key": "contracts_done", "n": 10},
	"high_roller": {"title": "HIGH ROLLER", "line": "Reach account level 10.", "key": "account_level", "n": 10},
	"loyal": {"title": "LOYAL CUSTOMER", "line": "Open a day-7 DAILY CRATE.", "key": "crate_day7", "n": 1},
	"legend": {"title": "CLINIC LEGEND", "line": "Reach account level 25.", "key": "account_level", "n": 25},
}

const ROAD_MAX := 30


static func _d() -> Dictionary:
	return FamilyProfile.data


static func _today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


# --- daily crate -------------------------------------------------------------

static func daily_ready() -> bool:
	return int(_d().get("crate_last", -1)) != _today()


## The streak the next crate would be (1..7).
static func daily_step() -> int:
	var last := int(_d().get("crate_last", -99))
	var st := int(_d().get("crate_streak", 0))
	if last == _today():
		return st
	if last != _today() - 1:
		st = 0
	return st % 7 + 1


static func daily_pay(step: int) -> Dictionary:
	return (DAILY[clampi(step, 1, 7) - 1] as Dictionary).duplicate()


static func open_daily() -> Dictionary:
	if not daily_ready():
		return {}
	var step := daily_step()
	var pay := daily_pay(step)
	_d()["crate_last"] = _today()
	_d()["crate_streak"] = step
	if step == 7:
		_d()["crate_day7"] = int(_d().get("crate_day7", 0)) + 1
	_pay(pay)
	pay["step"] = step
	return pay


## Seconds until the next crate.
static func daily_wait() -> int:
	return maxi(0, int(float(_today() + 1) * 86400.0 - Time.get_unix_time_from_system()))


# --- clinic road -------------------------------------------------------------

static func road_pay(lv: int) -> Dictionary:
	if lv % 5 == 0:
		return {"gold": 60 + lv * 10, "gems": 3 + lv / 5, "tokens": 30}
	return {"gold": 25 + lv * 5, "gems": 1 if lv % 2 == 0 else 0}


static func road_claimed() -> Array:
	return _d().get("road_claimed", [])


static func road_ready() -> Array:
	var out: Array = []
	var lv := int(_d().get("account_level", 1))
	for l in range(2, mini(lv, ROAD_MAX) + 1):
		if not road_claimed().has(l):
			out.append(l)
	return out


static func claim_road(lv: int) -> Dictionary:
	if not road_ready().has(lv):
		return {}
	var c := road_claimed()
	c.append(lv)
	_d()["road_claimed"] = c
	var pay := road_pay(lv)
	_pay(pay)
	return pay


# --- titles ------------------------------------------------------------------

static func _have(key: String) -> int:
	match key:
		"":
			return 1
		"_codex":
			return Discover.filed()
		"_style":
			var n := 0
			for k: String in _d().keys():
				if k.begins_with("style_") and str(_d()[k]).begins_with("S"):
					n += 1
			return n
		"_challenges":
			return (_d().get("surv_challenges", []) as Array).size()
	return int(_d().get(key, 0))


static func title_progress(id: String) -> Vector2i:
	var t: Dictionary = TITLES[id]
	return Vector2i(mini(_have(str(t["key"])), maxi(1, int(t["n"]))), maxi(1, int(t["n"])))


static func titles_owned() -> Array:
	return _d().get("titles", ["new_patient"])


## Checks every title; new ones are stored, flagged NEW and returned.
static func refresh_titles() -> Array:
	var own := titles_owned()
	var fresh: Array = []
	for id: String in TITLES:
		if own.has(id):
			continue
		var t: Dictionary = TITLES[id]
		if _have(str(t["key"])) >= int(t["n"]):
			own.append(id)
			fresh.append(id)
			FamilyProfile.flag_unseen("title_" + id)
	if not fresh.is_empty():
		_d()["titles"] = own
		FamilyProfile.save()
	return fresh


static func title() -> String:
	var id := str(_d().get("title", "new_patient"))
	return str((TITLES.get(id, TITLES["new_patient"]) as Dictionary)["title"])


static func wear_title(id: String) -> void:
	if titles_owned().has(id):
		_d()["title"] = id
		FamilyProfile.mark_seen("title_" + id)
		FamilyProfile.save()


static func new_titles() -> int:
	var n := 0
	for id in titles_owned():
		if FamilyProfile.is_unseen("title_" + str(id)):
			n += 1
	return n


# --- power -------------------------------------------------------------------

static func power() -> int:
	var p := Heroes.power("son") + Heroes.power("father")
	for m: String in Trees.MODES:
		p += 6 * Trees.count(m).x
	for id: String in Meta.LIST:
		p += 4 * Meta.rank(id)
	for id: String in SurvStarter.LIST:
		p += 3 * maxi(0, SurvStarter.level(id) - 1)
	return p


# --- everything claimable ----------------------------------------------------

static func _awards_ready() -> Array:
	var out: Array = []
	var awards: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/awards.json"))
	if not (awards is Array):
		return out
	var claimed: Array = _d().get("awards_claimed", [])
	for a: Dictionary in awards:
		if claimed.has(a["id"]):
			continue
		var ok := true
		var need: Dictionary = a["need"]
		for k in need.keys():
			if int(_d().get(k, 0)) < int(need[k]):
				ok = false
		if ok:
			out.append(a)
	return out


## Rows for the desk: {kind, id, title, icon, pay}.
static func claimables() -> Array:
	var out: Array = []
	if daily_ready():
		out.append({"kind": "daily", "id": "", "title": "DAILY CRATE  ·  DAY %d" % daily_step(), "icon": "cur_gift", "pay": daily_pay(daily_step())})
	for lv in road_ready():
		out.append({"kind": "road", "id": lv, "title": "CLINIC ROAD  ·  LV %d" % int(lv), "icon": "cur_road", "pay": road_pay(int(lv))})
	if Discover.unclaimed() > 0:
		out.append({"kind": "codex", "id": "", "title": "CODEX  ·  %d NEW ENTRIES" % Discover.unclaimed(), "icon": "node_school", "pay": {}})
	for r: Dictionary in Contracts.list():
		if not bool(r["claimed"]) and int(r["have"]) >= int(r["n"]):
			out.append({"kind": "job", "id": str(r["id"]), "title": "JOB  ·  " + str(r.get("title", r["id"])).to_upper(), "icon": "node_score", "pay": r["pay"]})
	for a: Dictionary in _awards_ready():
		out.append({"kind": "award", "id": str(a["id"]), "title": "AWARD  ·  " + str(a["title"]), "icon": "node_crown", "pay": {"gold": int(a["gold"]), "gems": int(a["gems"])}})
	return out


static func count() -> int:
	return claimables().size()


## Claims one row; returns what was paid ({gold, gems, tokens...}).
static func claim(row: Dictionary) -> Dictionary:
	match str(row["kind"]):
		"daily":
			return open_daily()
		"road":
			return claim_road(int(row["id"]))
		"codex":
			var g := {"gold": 0, "gems": 0}
			for c: String in Discover.CATS:
				for e: Array in Discover.catalog(c):
					var p := Discover.claim(c, str(e[0]))
					g["gold"] = int(g["gold"]) + int(p.get("gold", 0))
					g["gems"] = int(g["gems"]) + int(p.get("gems", 0))
			return g
		"job":
			if Contracts.claim(str(row["id"])):
				return row["pay"]
		"award":
			var claimed: Array = _d().get("awards_claimed", [])
			if not claimed.has(row["id"]):
				claimed.append(row["id"])
				_d()["awards_claimed"] = claimed
				var pay: Dictionary = row["pay"]
				_d()["gold"] = int(_d().get("gold", 0)) + int(pay["gold"])
				_d()["gems"] = int(_d().get("gems", 0)) + int(pay["gems"])
				FamilyProfile.save()
				return pay
	return {}


static func _pay(pay: Dictionary) -> void:
	for k: String in pay:
		var n := int(pay[k])
		match k:
			"gold":
				_d()["gold"] = int(_d().get("gold", 0)) + n
			"gems":
				_d()["gems"] = int(_d().get("gems", 0)) + n
			"tokens":
				_d()["tokens"] = int(_d().get("tokens", 0)) + n
	FamilyProfile.save()


static func pay_text(pay: Dictionary) -> String:
	var parts: Array[String] = []
	for k: String in ["gold", "gems", "tokens", "flow"]:
		if int(pay.get(k, 0)) > 0:
			parts.append("+%d %s" % [int(pay[k]), "S-COINS" if k == "tokens" else k.to_upper()])
	return "  ".join(parts)
