class_name WeeklyBook
extends RefCounted

## WEEKLY GAUNTLET (the Streets of Rage 4 way): one fixed coping hour for
## the whole week - the same street seed, the same two pacts - so every try
## is the same fight and the only thing that changes is you. Best time and
## kills are kept per week; the first time you hold 3:00 (or win) that week
## pays 3 gems and 150 gold.

const MAP := "intake_lot"
const HOLD := 180


## Weeks since 1970 (Thursday-aligned, like ISO weeks).
static func week_n() -> int:
	return int((int(Time.get_unix_time_from_system()) / 86400 + 3) / 7)


static func week_id() -> String:
	return "WEEK %d" % (week_n() % 1000)


static func seed_n() -> int:
	return hash("gauntlet-%d" % week_n())


## This week's two pacts (from SurvExtras.PACTS).
static func pacts() -> Array:
	var ids := SurvExtras.PACTS.keys()
	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n()
	var a := rng.randi_range(0, ids.size() - 1)
	var b := (a + 1 + rng.randi_range(0, ids.size() - 2)) % ids.size()
	return [ids[a], ids[b]]


static func _d() -> Dictionary:
	var w: Dictionary = FamilyProfile.data.get("weekly", {})
	if int(w.get("week", -1)) != week_n():
		w = {"week": week_n(), "best": 0, "kills": 0, "tries": 0, "paid": false}
		FamilyProfile.data["weekly"] = w
	return w


static func best() -> int:
	return int(_d().get("best", 0))


static func tries() -> int:
	return int(_d().get("tries", 0))


static func paid() -> bool:
	return bool(_d().get("paid", false))


## End of a weekly hour. Returns a line for the toast.
static func record(secs: int, kills: int, won: bool) -> String:
	var w := _d()
	w["tries"] = int(w.get("tries", 0)) + 1
	var line := "%s  ·  %d:%02d  ·  %d kills" % [week_id(), secs / 60, secs % 60, kills]
	if secs > int(w.get("best", 0)):
		w["best"] = secs
		w["kills"] = kills
		line = "NEW WEEKLY BEST  ·  " + line
	if not bool(w.get("paid", false)) and (secs >= HOLD or won):
		w["paid"] = true
		FamilyProfile.add_gems(3)
		FamilyProfile.add_gold(150)
		line += "  ·  +3 GEMS +150 GOLD"
	FamilyProfile.save()
	return line


static func rules_text() -> String:
	var names: Array[String] = []
	for id in pacts():
		names.append(str((SurvExtras.PACTS[id] as Dictionary)["title"]))
	return "  +  ".join(names)
