class_name Meta
extends RefCounted

## META: permanent upgrades, one set per way of playing (three metas next to
## the three skill trees in Trees):
##   body      BRAWL: health, damage, steam, money, shards, gear, starting
##             weapon, an extra life. Gold (+ gems).
##   survivor  SURVIVOR: Vampire Survivors style power-ups for the coping
##             hours (might, armour, cooldown, area, amount...). TOKENS.
##   parkour   PARKOUR: jump, wall runs, air control, flow, landings. FLOW.

const LIST := {
	"vitality": {"branch": "body", "title": "VITALITY", "ranks": 5, "line": "+5 max HP a rank.", "gold": 60, "gems": 0},
	"strength": {"branch": "body", "title": "STRENGTH", "ranks": 5, "line": "+3% damage a rank.", "gold": 70, "gems": 0},
	"second_wind": {"branch": "body", "title": "SECOND WIND", "ranks": 5, "line": "Steam refills 10% faster a rank.", "gold": 55, "gems": 0},
	"fortune": {"branch": "body", "title": "FORTUNE", "ranks": 5, "line": "+8% gold from coins and cash a rank.", "gold": 80, "gems": 1},
	"shard_sense": {"branch": "body", "title": "SHARD SENSE", "ranks": 5, "line": "Character shards drop 20% more often a rank.", "gold": 90, "gems": 1},
	"scavenger": {"branch": "body", "title": "SCAVENGER", "ranks": 3, "line": "Gear drops 25% more often a rank.", "gold": 100, "gems": 2},
	"starter_kit": {"branch": "body", "title": "STARTER KIT", "ranks": 3, "line": "Start every night armed: a pipe, then a bat, then a pistol.", "gold": 120, "gems": 2},
	"extra_life": {"branch": "body", "title": "SPARE LIFE", "ranks": 2, "line": "+1 life every night.", "gold": 250, "gems": 4},
	"spring_legs": {"branch": "parkour", "title": "SPRING LEGS", "ranks": 3, "line": "Jump 4% higher a rank.", "gold": 25, "gems": 0},
	"wall_runner": {"branch": "parkour", "title": "WALL RUNNER", "ranks": 3, "line": "Wall runs last 15% longer a rank.", "gold": 30, "gems": 0},
	"air_control": {"branch": "parkour", "title": "AIR CONTROL", "ranks": 3, "line": "Steer harder in the air; glides go 6% faster a rank.", "gold": 30, "gems": 0},
	"flow_state": {"branch": "parkour", "title": "FLOW STATE", "ranks": 3, "line": "Trick speed boosts are 25% stronger and last longer a rank.", "gold": 40, "gems": 0},
	"iron_ankles": {"branch": "parkour", "title": "IRON ANKLES", "ranks": 2, "line": "Rank 1: big drops never stagger. Rank 2: every hard landing rolls.", "gold": 60, "gems": 0},
	"trick_value": {"branch": "parkour", "title": "SHOWBOAT", "ranks": 5, "line": "+20% FLOW from every trick a rank.", "gold": 35, "gems": 0},
	"sprint": {"branch": "parkour", "title": "SPRINTER", "ranks": 3, "line": "+3% run speed a rank.", "gold": 35, "gems": 0},
	"s_might": {"branch": "survivor", "title": "MIGHT", "ranks": 5, "line": "+5% ability damage a rank.", "gold": 20, "gems": 0},
	"s_armor": {"branch": "survivor", "title": "ARMOR", "ranks": 3, "line": "-4% damage taken in the hour a rank.", "gold": 30, "gems": 0},
	"s_maxhp": {"branch": "survivor", "title": "MAX HEALTH", "ranks": 3, "line": "+10 max HP in the hour a rank.", "gold": 25, "gems": 0},
	"s_recovery": {"branch": "survivor", "title": "RECOVERY", "ranks": 3, "line": "Heal 0.25 HP a second a rank.", "gold": 30, "gems": 0},
	"s_cooldown": {"branch": "survivor", "title": "COOLDOWN", "ranks": 3, "line": "-3% ability cooldown a rank.", "gold": 40, "gems": 0},
	"s_area": {"branch": "survivor", "title": "AREA", "ranks": 3, "line": "+5% ability area a rank.", "gold": 30, "gems": 0},
	"s_speed": {"branch": "survivor", "title": "MOVE SPEED", "ranks": 3, "line": "+4% move speed in the hour a rank.", "gold": 25, "gems": 0},
	"s_amount": {"branch": "survivor", "title": "AMOUNT", "ranks": 1, "line": "+1 projectile on everything that throws.", "gold": 200, "gems": 0},
	"s_magnet": {"branch": "survivor", "title": "MAGNET", "ranks": 3, "line": "+15% pickup radius a rank.", "gold": 20, "gems": 0},
	"s_luck": {"branch": "survivor", "title": "LUCK", "ranks": 3, "line": "+3% crit and better chests a rank.", "gold": 35, "gems": 0},
	"s_growth": {"branch": "survivor", "title": "GROWTH", "ranks": 5, "line": "+5% experience a rank.", "gold": 25, "gems": 0},
	"s_greed": {"branch": "survivor", "title": "GREED", "ranks": 5, "line": "+10% tokens a rank.", "gold": 25, "gems": 0},
	"s_reroll": {"branch": "survivor", "title": "REROLL", "ranks": 3, "line": "+1 reroll every hour a rank.", "gold": 40, "gems": 0},
	"s_banish": {"branch": "survivor", "title": "BANISH", "ranks": 2, "line": "+1 banish every hour a rank.", "gold": 40, "gems": 0},
	"s_revival": {"branch": "survivor", "title": "REVIVAL", "ranks": 1, "line": "Get back up once every hour.", "gold": 250, "gems": 0},
}

## What each branch is paid in.
const BRANCH_CUR := {"body": "gold", "survivor": "tokens", "parkour": "flow"}


static func rank(id: String) -> int:
	return int((FamilyProfile.data.get("meta", {}) as Dictionary).get(id, 0))


static func max_rank(id: String) -> int:
	return int((LIST.get(id, {}) as Dictionary).get("ranks", 1))


## Price of the next rank: grows 1.6x a rank.
static func cost(id: String) -> Dictionary:
	var row: Dictionary = LIST.get(id, {})
	var r := rank(id)
	var k := pow(1.6, float(r))
	var cur := str(BRANCH_CUR.get(str(row.get("branch", "body")), "gold"))
	var c := {"cur": cur, "price": int(round(float(row.get("gold", 50)) * k)), "gold": 0, "gems": int(round(float(row.get("gems", 0)) * (1.0 + float(r))))}
	if cur == "gold":
		c["gold"] = c["price"]
	return c


static func tricks_done() -> int:
	return int(FamilyProfile.data.get("tricks", 0)) + int(FamilyProfile.data.get("wallkicks", 0))


## "" if it can be bought, else why not.
static func blocker(id: String) -> String:
	if rank(id) >= max_rank(id):
		return "MAXED"
	var c := cost(id)
	var cur := str(c["cur"])
	if int(FamilyProfile.data.get(cur, 0)) < int(c["price"]):
		return "NEED %d %s" % [int(c["price"]), cur.to_upper()]
	if int(FamilyProfile.data.get("gems", 0)) < int(c["gems"]):
		return "NEED %d GEMS" % int(c["gems"])
	return ""


static func try_buy(id: String) -> bool:
	if blocker(id) != "":
		return false
	var c := cost(id)
	var cur := str(c["cur"])
	FamilyProfile.data[cur] = int(FamilyProfile.data.get(cur, 0)) - int(c["price"])
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
	return (1.0 + 0.04 * float(rank("spring_legs"))) * (1.06 if Trees.has("p_high") else 1.0)


static func wall_mul() -> float:
	return (1.0 + 0.15 * float(rank("wall_runner"))) * (1.3 if Trees.has("p_wall") else 1.0)


static func air_mul() -> float:
	return (1.0 + 0.06 * float(rank("air_control"))) * (1.15 if Trees.has("p_air_ctrl") else 1.0)


static func flow_mul() -> float:
	return 1.0 + 0.25 * float(rank("flow_state"))


static func starter_weapon() -> String:
	return ["", "pipe", "baseball_bat", "pistol"][clampi(rank("starter_kit"), 0, 3)]



# --- survivor power-ups ---------------------------------------------------------

static func token_mul() -> float:
	return 1.0 + 0.1 * float(rank("s_greed"))


static func trick_flow_mul() -> float:
	return 1.0 + 0.2 * float(rank("trick_value"))


static func run_speed_mul() -> float:
	return (1.0 + 0.03 * float(rank("sprint"))) * (1.08 if Trees.has("p_speed") else 1.0)
