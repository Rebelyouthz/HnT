class_name Arsenal
extends RefCounted

## Lifetime weapon records: which weapons you have held, kills with each,
## mastery (MASTERY_KILLS kills = +15% damage with it) and how long a melee
## weapon lasts before it breaks.

const MASTERY_KILLS := 25
const MASTERY_BONUS := 0.15
## Landed hits before a melee weapon breaks (wood splinters, metal bends).
const USES := {
	"board": 10, "baseball_bat": 18, "pipe": 22, "crowbar": 26, "chain": 20, "knife": 24,
	"machete": 18, "sledgehammer": 12, "clipboard": 8, "stapler": 10, "can": 4, "envelope": 6,
}
const WOOD := ["board", "baseball_bat", "clipboard"]


static func found(id: String) -> bool:
	return (FamilyProfile.data.get("weapons_found", []) as Array).has(id)


static func mark_found(id: String) -> void:
	if id == "" or found(id) or WeaponBook.spec(id).is_empty():
		return
	var a: Array = FamilyProfile.data.get("weapons_found", [])
	a.append(id)
	FamilyProfile.data["weapons_found"] = a
	FamilyProfile.flag_unseen("armory")


static func kills(id: String) -> int:
	return int((FamilyProfile.data.get("weapon_kills", {}) as Dictionary).get(id, 0))


static func mastered(id: String) -> bool:
	return kills(id) >= MASTERY_KILLS


static func add_kill(id: String) -> void:
	if id == "" or WeaponBook.spec(id).is_empty():
		return
	var d: Dictionary = FamilyProfile.data.get("weapon_kills", {})
	var n := int(d.get(id, 0)) + 1
	d[id] = n
	FamilyProfile.data["weapon_kills"] = d
	var run: Dictionary = Engine.get_meta("run_weapon_kills", {})
	run[id] = int(run.get(id, 0)) + 1
	Engine.set_meta("run_weapon_kills", run)
	if n == MASTERY_KILLS:
		var t := str(WeaponBook.spec(id).get("title", id)).to_upper()
		Juice.unlock_logo("MASTERED: " + t, "+15% damage with it, for good.", "WEAPON MASTERY  ·  ARMORY")


static func dmg_mul(id: String) -> float:
	return 1.0 + (MASTERY_BONUS if mastered(id) else 0.0)


static func uses(id: String) -> int:
	return int(USES.get(id, 16))


## The weapon used most in the current run ("" if none).
static func run_best() -> String:
	var run: Dictionary = Engine.get_meta("run_weapon_kills", {})
	var best := ""
	var n := 0
	for k in run:
		if int(run[k]) > n:
			n = int(run[k])
			best = str(k)
	return best


static func reset_run() -> void:
	Engine.set_meta("run_weapon_kills", {})
	Engine.set_meta("run_shards", 0)


static func bump(key: String, n: int = 1) -> void:
	FamilyProfile.data[key] = int(FamilyProfile.data.get(key, 0)) + n
