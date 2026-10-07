class_name Heroes
extends RefCounted

## Character progression for the Son and the Father, on top of the skill
## tree and gear:
##   LEVEL   three of them - STREETS (the brawl maps), SURVIVOR (the hours)
##           and ROOFTOPS (parkour) - each bought with gold and each only
##           counting in its own mode, capped by rarity (common 10, then +5 a
##           rarity: 15, 20, 25, 30).
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
const MODES := ["story", "survivor", "parkour"]
const MODE_NAME := {"story": "STREETS", "survivor": "SURVIVOR", "parkour": "ROOFTOPS"}
const MODE_KEY := {"story": "level", "survivor": "lv_survivor", "parkour": "lv_parkour"}
## The side tracks are a bit cheaper: they only pay off in one mode.
const MODE_COST := {"story": 1.0, "survivor": 0.8, "parkour": 0.7}


static func _row(role: String) -> Dictionary:
	var key := "hero_" + role
	var r: Variant = FamilyProfile.data.get(key, null)
	if typeof(r) != TYPE_DICTIONARY:
		r = {"level": 1, "rarity": 0, "shards": 0}
		FamilyProfile.data[key] = r
	# Older saves had one level: both new tracks start from it.
	if not (r as Dictionary).has("lv_survivor"):
		r["lv_survivor"] = int(r.get("level", 1))
		r["lv_parkour"] = int(r.get("level", 1))
	return r


## Which level track counts right now: the mode of the map being played.
## Menus pass a mode explicitly.
static func mode() -> String:
	var sc: Node = Engine.get_main_loop().current_scene if Engine.get_main_loop() is SceneTree else null
	if sc is RunAct:
		if StoryBook.is_survive((sc as RunAct).map_id):
			return "survivor"
		if (sc as RunAct).roof_start:
			return "parkour"
	return "story"


static func level(role: String, m: String = "") -> int:
	return int(_row(role).get(MODE_KEY[m if m != "" else mode()], 1))


static func rarity(role: String) -> int:
	return clampi(int(_row(role).get("rarity", 0)), 0, 4)


static func rarity_name(role: String) -> String:
	return Rarity.ORDER[rarity(role)]


static func shards(role: String) -> int:
	return int(_row(role).get("shards", 0))


static func cap(role: String) -> int:
	return CAP_BASE + CAP_STEP * rarity(role)


static func level_cost(role: String, m: String = "story") -> int:
	return int(round(22.0 * float(MODE_COST[m]) * pow(1.12, float(level(role, m) - 1))))


static func can_level(role: String, m: String = "story") -> bool:
	return level(role, m) < cap(role) and int(FamilyProfile.data.get("gold", 0)) >= level_cost(role, m)


## Any track that can be bought right now (for red dots and tips).
static func can_level_any(role: String) -> bool:
	for m in MODES:
		if can_level(role, m):
			return true
	return false


static func try_level(role: String, m: String = "story") -> bool:
	if not can_level(role, m):
		return false
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - level_cost(role, m)
	_row(role)[MODE_KEY[m]] = level(role, m) + 1
	FamilyProfile.save()
	return true


## What the next rarity costs, or {} at legendary.
static func rank_cost(role: String) -> Dictionary:
	var r := rarity(role)
	if r >= 4:
		return {}
	return {"shards": SHARDS[r], "gold": RARITY_GOLD[r]}


## The highest of the three tracks: any one at the cap opens the next rarity.
static func top_level(role: String) -> int:
	var best := 1
	for m in MODES:
		best = maxi(best, level(role, m))
	return best


static func can_rank(role: String) -> bool:
	var c := rank_cost(role)
	return not c.is_empty() and top_level(role) >= cap(role) and shards(role) >= int(c["shards"]) and int(FamilyProfile.data.get("gold", 0)) >= int(c["gold"])


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
	Juice.unlock_logo("%s IS %s" % [who.to_upper(), rarity_name(role).to_upper()], "Level cap %d on all three tracks. +1 SURVIVOR weapon slot." % cap(role), "CHARACTER RARITY UP")
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


## Survivor: every rarity above common opens one more weapon slot.
static func weapon_slots() -> int:
	var best := 0
	for r in ROLES:
		best = maxi(best, rarity(r))
	return best


## Rooftops: the parkour level widens trick timing windows a little.
static func trick_window_mul(role: String) -> float:
	return 1.0 + 0.02 * float(level(role, "parkour") - 1)


static func steam_regen_mul(role: String) -> float:
	return 1.0 + 0.04 * float(rarity(role))


## One number for the menus: how strong this character is overall.
static func power(role: String) -> int:
	var lv := level(role, "story") + (level(role, "survivor") + level(role, "parkour")) / 2
	return int(round(100.0 * (1.0 + 0.02 * float(lv - 1) + 0.06 * float(rarity(role))) + 1.2 * float(hp_bonus(role)) + 0.6 * float(int(FamilyProfile.gear_stat_bonus(role).get("hp", 0)) + 4 * int(FamilyProfile.gear_stat_bonus(role).get("dmg", 0)))))


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
