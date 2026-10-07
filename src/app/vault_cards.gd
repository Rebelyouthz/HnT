class_name VaultCards
extends RefCounted

## CARD VAULT: level-up cards won by drawing in the vault (data/vault_cards.json).
## Owned cards join the level-up draw in story runs and survivor hours. A
## card's vault level (1-5, from duplicate draws) scales it; picking it again
## inside one run (max 3) adds half again.
##
## Draw price climbs with every draw - gold, more gold, gems, card tokens,
## then tokens and gems together - and slides back two steps for every night
## finished, so playing makes the vault cheap again. Paying with tokens
## guarantees RARE or better.

const MAX_LV := 5
const RUN_MAX := 3
const WEIGHTS := {"common": 44.0, "uncommon": 28.0, "rare": 17.0, "epic": 8.5, "legendary": 2.5}
## [gold, gems, tokens] for each step of the ladder; the last repeats.
const LADDER := [[120, 0, 0], [260, 0, 0], [0, 6, 0], [0, 12, 0], [0, 0, 1], [0, 0, 2], [0, 15, 2], [0, 25, 3]]

static var _book: Array = []
## This run's picks: id -> times picked.
static var run: Dictionary = {}


static func book() -> Array:
	if _book.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/vault_cards.json"))
		if d is Dictionary:
			_book = (d as Dictionary).get("cards", [])
	return _book


static func card(id: String) -> Dictionary:
	for c: Dictionary in book():
		if str(c["id"]) == id:
			return c
	return {}


static func is_vault(id: String) -> bool:
	return id.begins_with("v_") and not card(id).is_empty()


## The collection: card id -> copies per rarity tier [common..legendary].
static func inv() -> Dictionary:
	if not FamilyProfile.data.has("vault_inv"):
		var out := {}
		# Older saves kept one level per card: that becomes one copy.
		for id: String in (FamilyProfile.data.get("vault", {}) as Dictionary).keys():
			var c := [0, 0, 0, 0, 0]
			c[clampi(int(FamilyProfile.data["vault"][id]) - 1, 0, 4)] = 1
			out[id] = c
		FamilyProfile.data["vault_inv"] = out
	return FamilyProfile.data["vault_inv"]


static func counts(id: String) -> Array:
	return inv().get(id, [0, 0, 0, 0, 0])


## Best rarity owned + 1 (0 = not owned). This is the card's power level.
static func level(id: String) -> int:
	var c := counts(id)
	for t in range(4, -1, -1):
		if int(c[t]) > 0:
			return t + 1
	return 0


static func best_tier(id: String) -> int:
	return level(id) - 1


## Every owned card id -> its level, for older call sites.
static func owned() -> Dictionary:
	var out := {}
	for id: String in inv().keys():
		if level(id) > 0:
			out[id] = level(id)
	return out


static func add_copy(id: String, tier: int) -> void:
	var c: Array = counts(id).duplicate()
	c[clampi(tier, 0, 4)] = int(c[clampi(tier, 0, 4)]) + 1
	inv()[id] = c
	FamilyProfile.save()


## Two copies at the same rarity -> one at the next. Returns the new tier
## or -1 when it cannot merge.
static func can_merge(id: String, tier: int) -> bool:
	return tier < 4 and int(counts(id)[tier]) >= 2


static func merge(id: String, tier: int) -> int:
	if not can_merge(id, tier):
		return -1
	var c: Array = counts(id).duplicate()
	c[tier] = int(c[tier]) - 2
	c[tier + 1] = int(c[tier + 1]) + 1
	inv()[id] = c
	FamilyProfile.save()
	return tier + 1


## Evolution cards whose two parents are both at LEGENDARY.
static func evolutions_ready() -> Array:
	var out: Array = []
	if not FamilyProfile.has_cbt("deck_evolve"):
		return out
	for c: Dictionary in book():
		if str(c.get("kind", "")) != "evolution":
			continue
		var ok := true
		for n in c.get("needs", []):
			if int(counts(str(n))[4]) <= 0:
				ok = false
		if ok:
			out.append(str(c["id"]))
	return out


## Fuses both legendary parents into the evolved card (legendary).
static func evolve(eid: String) -> bool:
	if not evolutions_ready().has(eid):
		return false
	for n in card(eid).get("needs", []):
		var c: Array = counts(str(n)).duplicate()
		c[4] = int(c[4]) - 1
		inv()[str(n)] = c
	add_copy(eid, 4)
	return true


## Synergy pairs and whether each half is owned.
static func synergies() -> Array:
	var out: Array = []
	for c: Dictionary in book():
		if str(c.get("kind", "")) == "synergy":
			var have: Array = []
			for n in c.get("needs", []):
				have.append(level(str(n)) > 0)
			out.append({"id": str(c["id"]), "needs": c.get("needs", []), "have": have, "owned": level(str(c["id"])) > 0})
	return out


static func tokens() -> int:
	return int(FamilyProfile.data.get("card_tokens", 0))


static func add_tokens(n: int, why: String = "") -> void:
	FamilyProfile.data["card_tokens"] = tokens() + n
	FamilyProfile.save()
	if n > 0:
		Juice.toast("reward", "+%d CARD TOKEN%s" % [n, "" if n == 1 else "S"], why if why != "" else "Spend it in the CARD VAULT.", "cur_card_token")


static func hand_size() -> int:
	return 12 if FamilyProfile.has_cbt("deck_hand") else 9


## Can this card come out of the vault right now?
static func drawable(c: Dictionary) -> bool:
	match str(c.get("kind", "")):
		"evolution":
			return false
		"synergy":
			if not FamilyProfile.has_cbt("deck_synergy"):
				return false
			for n in c.get("needs", []):
				if level(str(n)) <= 0:
					return false
	return true


## ---- price ladder ---------------------------------------------------------

static func step() -> int:
	return int(FamilyProfile.data.get("vault_step", 0))


static func price() -> Array:
	return LADDER[mini(step(), LADDER.size() - 1)]


static func price_text(p: Array = []) -> String:
	if p.is_empty():
		p = price()
	var parts: Array[String] = []
	if int(p[0]) > 0:
		parts.append("%d GOLD" % int(p[0]))
	if int(p[1]) > 0:
		parts.append("%d GEMS" % int(p[1]))
	if int(p[2]) > 0:
		parts.append("%d TOKEN%s" % [int(p[2]), "" if int(p[2]) == 1 else "S"])
	return " + ".join(parts)


static func can_pay() -> bool:
	var p := price()
	return int(FamilyProfile.data.get("gold", 0)) >= int(p[0]) and int(FamilyProfile.data.get("gems", 0)) >= int(p[1]) and tokens() >= int(p[2])


## A finished night makes the vault cheaper again.
static func on_night() -> void:
	FamilyProfile.data["vault_step"] = maxi(0, step() - 2)


## Pays, rolls and grants. Returns the card dict with "lv" (new level) and
## "new" (first copy), or {} when it cannot be paid.
static func draw() -> Dictionary:
	if not can_pay():
		return {}
	var p := price()
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - int(p[0])
	FamilyProfile.data["gems"] = int(FamilyProfile.data.get("gems", 0)) - int(p[1])
	FamilyProfile.data["card_tokens"] = tokens() - int(p[2])
	FamilyProfile.data["vault_step"] = step() + 1
	var floor_rank := 2 if int(p[2]) > 0 else (1 if int(p[1]) > 0 else 0)
	var pool: Array = []
	for c: Dictionary in book():
		if drawable(c):
			pool.append(c)
	if pool.is_empty():
		FamilyProfile.add_gems(5)
		return {}
	var pick: Dictionary = pool[randi() % pool.size()]
	var tier := _roll_tier(floor_rank)
	var id := str(pick["id"])
	var was := level(id)
	add_copy(id, tier)
	FamilyProfile.data["vault_draws"] = int(FamilyProfile.data.get("vault_draws", 0)) + 1
	FamilyProfile.save()
	var out := pick.duplicate()
	out["tier"] = tier
	out["rarity"] = Rarity.ORDER[tier]
	out["lv"] = level(id)
	out["new"] = was == 0
	out["merge"] = can_merge(id, tier)
	return out


static func _roll_tier(floor_rank: int) -> int:
	var total := 0.0
	for t in range(floor_rank, 5):
		total += float(WEIGHTS[Rarity.ORDER[t]])
	var r := randf() * total
	for t in range(floor_rank, 5):
		r -= float(WEIGHTS[Rarity.ORDER[t]])
		if r <= 0.0:
			return t
	return 4


## ---- in a run ------------------------------------------------------------

static func reset_run() -> void:
	run.clear()


## Vault cards that may be offered at a level-up right now.
static func offers() -> Array:
	var out: Array = []
	for id: String in owned().keys():
		if level(id) > 0 and int(run.get(id, 0)) < RUN_MAX and not card(id).is_empty():
			out.append(id)
	return out


## The card as the level-up screens want it (name, blurb with numbers).
static func as_row(id: String) -> Dictionary:
	var c := card(id)
	if c.is_empty():
		return {}
	var n := int(run.get(id, 0)) + 1
	var k := _k(id, n)
	var blurb := str(c.get("blurb", ""))
	var st: Dictionary = c.get("stats", {})
	for key: String in st.keys():
		blurb = blurb.replace("{%s}" % key, _fmt(key, float(st[key]) * k))
	var tier := maxi(0, best_tier(id))
	return {"id": id, "name": str(c["name"]), "blurb": blurb, "rarity": Rarity.ORDER[tier],
		"tag": str(c.get("tag", "VAULT")), "level": n, "upgrade": n > 1, "icon": "cur_card_token"}


static func _k(id: String, picks: int) -> float:
	return float(maxi(1, level(id))) * (1.0 + 0.5 * float(maxi(0, picks - 1)))


static func _fmt(key: String, v: float) -> String:
	if key in ["speed", "hp", "heal"]:
		return "%d" % int(round(v))
	return "%d%%" % int(round(v * 100.0))


## Taken at a level-up. Instant parts (max HP) land now.
static func on_pick(id: String, tree: SceneTree) -> void:
	run[id] = int(run.get(id, 0)) + 1
	var add_hp := int(round(float((card(id).get("stats", {}) as Dictionary).get("hp", 0.0)) * float(maxi(1, level(id)))))
	if add_hp > 0:
		for f in tree.get_nodes_in_group("players"):
			if f is Fighter:
				(f as Fighter).max_hp += add_hp
				(f as Fighter).hp += add_hp
	var add_sp := float((card(id).get("stats", {}) as Dictionary).get("speed", 0.0)) * float(maxi(1, level(id)))
	if add_sp > 0.0:
		for f in tree.get_nodes_in_group("players"):
			if f is Fighter:
				(f as Fighter).speed += add_sp
	Rarity.juice(Rarity.ORDER[maxi(0, best_tier(id))], str(card(id).get("name", "")))


## Summed bonus for a stat from this run's vault picks.
static func stat(key: String) -> float:
	var s := 0.0
	for id: String in run.keys():
		var st: Dictionary = card(id).get("stats", {})
		if st.has(key):
			s += float(st[key]) * _k(id, int(run[id]))
	return s
