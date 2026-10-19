class_name SurvChallenges
extends RefCounted

## SURVIVOR CHALLENGES: lasting goals checked at the end of every coping
## hour (and some live). Each pays gems and S-COINS once, and some open a new
## STARTER WEAPON. Shown in CODEX > CHALLENGES and the STARTER sheet.

const LIST := {
	"ch_kills_500": {"title": "PAPERWORK PILE", "line": "Kill 500 in one hour.", "stat": "kills", "goal": 500, "gems": 2, "tokens": 60, "opens": "clipboards"},
	"ch_survive_5": {"title": "FIVE MINUTE BREAK", "line": "Survive 5:00.", "stat": "time", "goal": 300, "gems": 2, "tokens": 50, "opens": "name_badge"},
	"ch_level_20": {"title": "OVERQUALIFIED", "line": "Reach level 20 in one hour.", "stat": "level", "goal": 20, "gems": 3, "tokens": 80, "opens": "fax_beam"},
	"ch_evolve_1": {"title": "CAREER GROWTH", "line": "Evolve an ability.", "stat": "evolved", "goal": 1, "gems": 3, "tokens": 80, "opens": "shredder"},
	"ch_boss_1": {"title": "MANAGER DOWN", "line": "Beat the hour's boss.", "stat": "boss", "goal": 1, "gems": 4, "tokens": 100, "opens": "rubber_stamp"},
	"ch_nohit_3": {"title": "UNTOUCHABLE", "line": "Go 3:00 without losing health.", "stat": "nohit", "goal": 180, "gems": 4, "tokens": 100, "opens": "paperweight"},
	"ch_missions_3": {"title": "OVERTIME", "line": "Finish 3 missions in one hour.", "stat": "missions", "goal": 3, "gems": 3, "tokens": 70, "opens": ""},
	"ch_kills_1500": {"title": "PAPER SHREDDER", "line": "Kill 1500 in one hour.", "stat": "kills", "goal": 1500, "gems": 5, "tokens": 150, "opens": ""},
	"ch_champ_3": {"title": "UNION BUSTER", "line": "Put down 3 champions in one hour.", "stat": "champs", "goal": 3, "gems": 4, "tokens": 90, "opens": ""},
	"ch_win": {"title": "CLOCK OUT", "line": "Survive the whole hour.", "stat": "won", "goal": 1, "gems": 6, "tokens": 200, "opens": ""},
}


static func _done() -> Array:
	var a: Variant = FamilyProfile.data.get("surv_challenges", [])
	return a if a is Array else []


static func done(id: String) -> bool:
	return _done().has(id)


static func best(stat: String) -> int:
	return int((FamilyProfile.data.get("surv_ch_best", {}) as Dictionary).get(stat, 0))


## End of an hour (or live): `stats` holds this hour's numbers. Newly
## finished challenges pay out and open their starter. Returns their ids.
static func check(stats: Dictionary) -> Array:
	var bests: Dictionary = FamilyProfile.data.get("surv_ch_best", {})
	for k in stats:
		bests[k] = maxi(int(bests.get(k, 0)), int(stats[k]))
	FamilyProfile.data["surv_ch_best"] = bests
	var got: Array = []
	for id: String in LIST:
		if done(id):
			continue
		var c: Dictionary = LIST[id]
		if int(stats.get(str(c["stat"]), 0)) >= int(c["goal"]):
			var d := _done()
			d.append(id)
			FamilyProfile.data["surv_challenges"] = d
			FamilyProfile.data["gems"] = int(FamilyProfile.data.get("gems", 0)) + int(c["gems"])
			FamilyProfile.data["tokens"] = int(FamilyProfile.data.get("tokens", 0)) + int(c["tokens"])
			got.append(id)
			var opens := str(c.get("opens", ""))
			Juice.toast("challenge", "CHALLENGE  ·  %s" % str(c["title"]), ("Opens the %s starter" % opens.replace("_", " ").to_upper()) if opens != "" else "+%d gems" % int(c["gems"]), "node_crown")
			FamilyProfile.flag_unseen("surv_starter")
	FamilyProfile.save()
	return got
