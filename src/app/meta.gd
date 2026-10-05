class_name Meta
extends RefCounted

## META: permanent upgrades bought in the hideout with gold and gems, on top
## of the BUILD skill tree, hero levels and gear. Two branches:
##   BODY     health, damage, steam, money, shards, gear finds, a starting
##            weapon, an extra life.
##   PARKOUR  jump, wall runs, air control, trick flow, landings. Each rank
##            also needs lifetime tricks: you get better by doing it.

const LIST := {
	"vitality": {"branch": "body", "title": "VITALITY", "ranks": 5, "line": "+5 max HP a rank.", "gold": 60, "gems": 0},
	"strength": {"branch": "body", "title": "STRENGTH", "ranks": 5, "line": "+3% damage a rank.", "gold": 70, "gems": 0},
	"second_wind": {"branch": "body", "title": "SECOND WIND", "ranks": 5, "line": "Steam refills 10% faster a rank.", "gold": 55, "gems": 0},
	"fortune": {"branch": "body", "title": "FORTUNE", "ranks": 5, "line": "+8% gold from coins and cash a rank.", "gold": 80, "gems": 1},
	"shard_sense": {"branch": "body", "title": "SHARD SENSE", "ranks": 5, "line": "Character shards drop 20% more often a rank.", "gold": 90, "gems": 1},
	"scavenger": {"branch": "body", "title": "SCAVENGER", "ranks": 3, "line": "Gear drops 25% more often a rank.", "gold": 100, "gems": 2},
	"starter_kit": {"branch": "body", "title": "STARTER KIT", "ranks": 3, "line": "Start every night armed: a pipe, then a bat, then a pistol.", "gold": 120, "gems": 2},
	"extra_life": {"branch": "body", "title": "SPARE LIFE", "ranks": 2, "line": "+1 life every night.", "gold": 250, "gems": 4},
	"spring_legs": {"branch": "parkour", "title": "SPRING LEGS", "ranks": 3, "line": "Jump 4% higher a rank.", "gold": 60, "gems": 0, "tricks": 15},
	"wall_runner": {"branch": "parkour", "title": "WALL RUNNER", "ranks": 3, "line": "Wall runs last 15% longer a rank.", "gold": 70, "gems": 0, "tricks": 25},
	"air_control": {"branch": "parkour", "title": "AIR CONTROL", "ranks": 3, "line": "Steer harder in the air; glides go 6% faster a rank.", "gold": 70, "gems": 1, "tricks": 25},
	"flow_state": {"branch": "parkour", "title": "FLOW STATE", "ranks": 3, "line": "Trick speed boosts are 25% stronger and last longer a rank.", "gold": 90, "gems": 1, "tricks": 40},
	"iron_ankles": {"branch": "parkour", "title": "IRON ANKLES", "ranks": 2, "line": "Rank 1: big drops never stagger. Rank 2: every hard landing rolls.", "gold": 110, "gems": 2, "tricks": 60},
}


static func rank(id: String) -> int:
	return int((FamilyProfile.data.get("meta", {}) as Dictionary).get(id, 0))


static func max_rank(id: String) -> int:
	return int((LIST.get(id, {}) as Dictionary).get("ranks", 1))


## Price of the next rank: grows 1.6x a rank.
static func cost(id: String) -> Dictionary:
	var row: Dictionary = LIST.get(id, {})
	var r := rank(id)
	var k := pow(1.6, float(r))
	var c := {"gold": int(round(float(row.get("gold", 50)) * k)), "gems": int(round(float(row.get("gems", 0)) * (1.0 + float(r))))}
	if row.has("tricks"):
		c["tricks"] = int(row["tricks"]) * (r + 1) * (r + 1)
	return c


static func tricks_done() -> int:
	return int(FamilyProfile.data.get("tricks", 0)) + int(FamilyProfile.data.get("wallkicks", 0))


## "" if it can be bought, else why not.
static func blocker(id: String) -> String:
	if rank(id) >= max_rank(id):
		return "MAXED"
	var c := cost(id)
	if c.has("tricks") and tricks_done() < int(c["tricks"]):
		return "NEED %d TRICKS" % int(c["tricks"])
	if int(FamilyProfile.data.get("gold", 0)) < int(c["gold"]):
		return "NEED %d GOLD" % int(c["gold"])
	if int(FamilyProfile.data.get("gems", 0)) < int(c["gems"]):
		return "NEED %d GEMS" % int(c["gems"])
	return ""


static func try_buy(id: String) -> bool:
	if blocker(id) != "":
		return false
	var c := cost(id)
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - int(c["gold"])
	FamilyProfile.data["gems"] = int(FamilyProfile.data.get("gems", 0)) - int(c["gems"])
	var m: Dictionary = FamilyProfile.data.get("meta", {})
	m[id] = rank(id) + 1
	FamilyProfile.data["meta"] = m
	FamilyProfile.save()
	return true


# --- effects ------------------------------------------------------------------

static func hp_bonus() -> int:
	return 5 * rank("vitality")


static func dmg_mul() -> float:
	return 1.0 + 0.03 * float(rank("strength"))


static func steam_mul() -> float:
	return 1.0 + 0.1 * float(rank("second_wind"))


static func gold_mul() -> float:
	return 1.0 + 0.08 * float(rank("fortune"))


static func shard_mul() -> float:
	return 1.0 + 0.2 * float(rank("shard_sense"))


static func gear_mul() -> float:
	return 1.0 + 0.25 * float(rank("scavenger"))


static func jump_mul() -> float:
	return 1.0 + 0.04 * float(rank("spring_legs"))


static func wall_mul() -> float:
	return 1.0 + 0.15 * float(rank("wall_runner"))


static func air_mul() -> float:
	return 1.0 + 0.06 * float(rank("air_control"))


static func flow_mul() -> float:
	return 1.0 + 0.25 * float(rank("flow_state"))


static func starter_weapon() -> String:
	return ["", "pipe", "baseball_bat", "pistol"][clampi(rank("starter_kit"), 0, 3)]
