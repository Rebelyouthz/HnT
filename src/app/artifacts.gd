class_name Artifacts
extends RefCounted

## NIGHT ARTIFACTS (after Halls of Torment's artifacts / agony switches):
## up to two risk-and-reward modifiers picked in the RUN tab before a night.
## They change the rules for that run only and pay better for the trouble.

const MAX_ON := 2
const LIST := {
	"glass_jaw": {"title": "GLASS JAW", "risk": "Thugs hit 40% harder.", "reward": "+50% gold."},
	"thick_crowd": {"title": "THICK CROWD", "risk": "Thugs have 30% more health.", "reward": "Shards drop twice as often."},
	"no_lunch": {"title": "NO LUNCH BREAK", "risk": "Health flasks heal nothing.", "reward": "+40% gold and tokens."},
	"glass_cannon": {"title": "GLASS CANNON", "risk": "You take 30% more damage.", "reward": "You deal 30% more damage."},
	"one_life": {"title": "LAST CHANCE", "risk": "One life fewer.", "reward": "+1 gem and double shards on a clear."},
	"rush_job": {"title": "RUSH JOB", "risk": "Thugs move 25% faster.", "reward": "+50% experience and flow."},
}


static func on() -> Array:
	return FamilyProfile.data.get("artifacts_on", [])


static func has(id: String) -> bool:
	return on().has(id)


static func toggle(id: String) -> bool:
	var a: Array = on().duplicate()
	if a.has(id):
		a.erase(id)
	elif a.size() < MAX_ON and LIST.has(id):
		a.append(id)
	else:
		return false
	FamilyProfile.data["artifacts_on"] = a
	FamilyProfile.save()
	return true


static func enemy_dmg() -> float:
	return (1.4 if has("glass_jaw") else 1.0) * (1.3 if has("glass_cannon") else 1.0)


static func enemy_hp() -> float:
	return 1.3 if has("thick_crowd") else 1.0


static func enemy_speed() -> float:
	return 1.25 if has("rush_job") else 1.0


static func player_dmg() -> float:
	return 1.3 if has("glass_cannon") else 1.0


static func gold() -> float:
	return (1.5 if has("glass_jaw") else 1.0) * (1.4 if has("no_lunch") else 1.0)


static func shards() -> float:
	return 2.0 if has("thick_crowd") else 1.0
