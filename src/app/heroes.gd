class_name Heroes
extends RefCounted

## Character progression for the Son and the Father, on top of the skill
## tree and gear:
##   LEVEL   bought with gold, capped by rarity (common 10, then +5 a rarity:
##           15, 20, 25, 30).
##   RARITY  common (grey) -> uncommon (green) -> rare (blue) -> epic (purple)
##           -> legendary (orange), unlocked at the level cap with CHARACTER
##           SHARDS that drop from thugs, elites, bosses and stashes.
## The bodies start weaker than before (see Fighter.max_hp) so the climb is
## felt; enemies scale by how far into the city the map is (difficulty_mul).

const CAP_BASE := 10
const CAP_STEP := 5
## Shards (and gold) to reach uncommon, rare, epic, legendary.
const SHARDS := [10, 20, 35, 55]
const RARITY_GOLD := [120, 300, 600, 1000]
const ROLES := ["son", "father"]


static func _row(role: String) -> Dictionary:
	var key := "hero_" + role
	var r: Variant = FamilyProfile.data.get(key, null)
	if typeof(r) != TYPE_DICTIONARY:
		r = {"level": 1, "rarity": 0, "shards": 0}
		FamilyProfile.data[key] = r
	return r


static func level(role: String) -> int:
	return int(_row(role).get("level", 1))


static func rarity(role: String) -> int:
	return clampi(int(_row(role).get("rarity", 0)), 0, 4)


static func rarity_name(role: String) -> String:
	return Rarity.ORDER[rarity(role)]


static func shards(role: String) -> int:
	return int(_row(role).get("shards", 0))


static func cap(role: String) -> int:
	return CAP_BASE + CAP_STEP * rarity(role)


static func level_cost(role: String) -> int:
	return int(round(22.0 * pow(1.12, float(level(role) - 1))))


static func can_level(role: String) -> bool:
	return level(role) < cap(role) and int(FamilyProfile.data.get("gold", 0)) >= level_cost(role)


static func try_level(role: String) -> bool:
	if not can_level(role):
		return false
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - level_cost(role)
	_row(role)["level"] = level(role) + 1
	FamilyProfile.save()
	return true


## What the next rarity costs, or {} at legendary.
static func rank_cost(role: String) -> Dictionary:
	var r := rarity(role)
	if r >= 4:
		return {}
	return {"shards": SHARDS[r], "gold": RARITY_GOLD[r]}


static func can_rank(role: String) -> bool:
	var c := rank_cost(role)
	return not c.is_empty() and level(role) >= cap(role) and shards(role) >= int(c["shards"]) and int(FamilyProfile.data.get("gold", 0)) >= int(c["gold"])


static func try_rank(role: String) -> bool:
	if not can_rank(role):
		return false
	var c := rank_cost(role)
	var row := _row(role)
	row["shards"] = shards(role) - int(c["shards"])
	row["rarity"] = rarity(role) + 1
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - int(c["gold"])
	FamilyProfile.save()
	var who := FamilyProfile.son_name() if role == "son" else FamilyProfile.father_name()
	Juice.unlock_logo("%s IS %s" % [who.to_upper(), rarity_name(role).to_upper()], "Level cap %d. Tougher, harder, faster." % cap(role), "CHARACTER RARITY UP")
	Rarity.juice(rarity_name(role), who)
	return true


static func add_shards(role: String, n: int) -> void:
	if n <= 0:
		return
	var row := _row(role)
	row["shards"] = shards(role) + n
	Engine.set_meta("run_shards", int(Engine.get_meta("run_shards", 0)) + n)
	FamilyProfile.data["shards_found"] = int(FamilyProfile.data.get("shards_found", 0)) + n
	FamilyProfile.flag_unseen("heroes")


## Stat lines the fighter and enemies read.
static func hp_bonus(role: String) -> int:
	return 2 * (level(role) - 1) + 8 * rarity(role)


static func dmg_mul(role: String) -> float:
	return 1.0 + 0.025 * float(level(role) - 1) + 0.06 * float(rarity(role))


static func speed_bonus(role: String) -> float:
	return 4.0 * float(rarity(role))


static func steam_regen_mul(role: String) -> float:
	return 1.0 + 0.04 * float(rarity(role))


## One number for the menus: how strong this character is overall.
static func power(role: String) -> int:
	return int(round(100.0 * dmg_mul(role) + 1.2 * float(hp_bonus(role)) + 0.6 * float(int(FamilyProfile.gear_stat_bonus(role).get("hp", 0)) + 4 * int(FamilyProfile.gear_stat_bonus(role).get("dmg", 0)))))


static func role_of(n: Node) -> String:
	if n is Fighter:
		return (n as Fighter).role
	var r: Variant = n.get("owner_role") if n != null else null
	return str(r) if r != null else ""


## Roguelite pressure: thugs further into the city hit harder and last
## longer, so levels, rarity, gear and META are what carry you there.
static func map_tier() -> int:
	return maxi(0, App.ORDER.find(App.current_map))


## The first night is meant to beat a fresh family: roughly one life lost to
## the street and one to the boss before levels, gear and META catch up.
static func enemy_hp_mul() -> float:
	return 1.12 + 0.13 * float(map_tier())


static func enemy_dmg_mul() -> float:
	return 1.15 + 0.07 * float(map_tier())
