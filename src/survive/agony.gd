class_name Agony
extends RefCounted

## AGONY (Halls of Torment's dial): survivor hours played from the SURVIVOR
## lobby can be cranked from CALM to AGONY V. Each step: thugs +30% health,
## +15% on the field at once, a touch faster - and +35% S-COINS and gear
## luck. Holding an hour on a level opens the next one for that map.

const MAX := 5
const NAMES := ["CALM", "AGONY I", "AGONY II", "AGONY III", "AGONY IV", "AGONY V"]


static func cur() -> int:
	return clampi(App.agony, 0, MAX) if App.surv_solo else 0


static func hp() -> float:
	return 1.0 + 0.3 * float(cur())


static func cap() -> float:
	return 1.0 + 0.15 * float(cur())


static func speed() -> float:
	return 1.0 + 0.04 * float(cur())


static func coins() -> float:
	return 1.0 + 0.35 * float(cur())


## Highest level open on this map (0 = CALM only).
static func open_on(map_id: String) -> int:
	return int((FamilyProfile.data.get("agony", {}) as Dictionary).get(map_id, 0))


static func on_win(map_id: String) -> void:
	if not App.surv_solo:
		return
	var book: Dictionary = FamilyProfile.data.get("agony", {})
	var nxt := mini(MAX, cur() + 1)
	if nxt > int(book.get(map_id, 0)):
		book[map_id] = nxt
		FamilyProfile.data["agony"] = book
		FamilyProfile.save()
		Juice.unlock_logo(NAMES[nxt], "The hour held. The next one bites harder.", "AGONY UNLOCKED")


## Best hour on a map: time, kills (kept from the lobby's runs and story).
static func note_best(map_id: String, secs: int, kills: int, won: bool) -> void:
	var book: Dictionary = FamilyProfile.data.get("surv_map_best", {})
	var row: Dictionary = book.get(map_id, {"time": 0, "kills": 0, "wins": 0})
	row["time"] = maxi(int(row.get("time", 0)), secs)
	row["kills"] = maxi(int(row.get("kills", 0)), kills)
	if won:
		row["wins"] = int(row.get("wins", 0)) + 1
	book[map_id] = row
	FamilyProfile.data["surv_map_best"] = book


static func best(map_id: String) -> Dictionary:
	return (FamilyProfile.data.get("surv_map_best", {}) as Dictionary).get(map_id, {})
