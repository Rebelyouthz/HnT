class_name GuideFunds
extends Object

## The family is never walked to a buy it cannot pay for. Whenever a guide
## (a story errand arrow or a first-use Guide that says "buy this") lands
## on a purchase, whatever is short is handed over right there, big on
## screen: the currency icon bursts in the middle, the number counts up and
## the coins fly to the counter. Nothing is given when the wallet already
## covers it, so the guides themselves never change and nothing is free
## twice for a player who saved up.

## RewardFly keys for each profile field.
const FLY := {"gold": "gold", "gems": "gems", "tokens": "tokens", "rep": "rep", "flow": "flow"}


## Make sure `cur` is at least `need`; returns what was given.
static func top_up(cur: String, need: int) -> int:
	if need <= 0:
		return 0
	var have := int(FamilyProfile.data.get(cur, 0))
	var short := need - have
	if short <= 0:
		return 0
	FamilyProfile.data[cur] = have + short
	FamilyProfile.save()
	if Juice.rewards != null and FLY.has(cur):
		Juice.rewards.give(str(FLY[cur]), short)
	return short


## A story errand step (PowerBook.path / ErrandGuide.steps): gold, rep and
## crafting parts.
static func cover_step(step: Dictionary) -> int:
	var given := top_up("gold", int(step.get("gold", 0)))
	given += top_up("rep", int(step.get("rep", 0)))
	var parts: Dictionary = step.get("parts", {})
	for k in parts.keys():
		var have := int(FamilyProfile.part_n(str(k)))
		var want := int(parts[k])
		if have < want:
			FamilyProfile.add_parts(str(k), want - have)
			Juice.toast("reward", "PARTS FOR THE JOB", "+%d %s" % [want - have, str(k).replace("_", " ").to_upper()])
			given += want - have
	return given


## The first time a menu's Guide plays and tells you to buy something,
## the cheapest such buy is covered.
static func for_guide(gid: String) -> void:
	match gid:
		"build":
			var best: Dictionary = {}
			for r: Dictionary in Trees.nodes("brawl"):
				if Trees.state("brawl", r) in ["owned", "locked"]:
					continue
				if best.is_empty() or int(r.get("gold", 0)) < int(best.get("gold", 0)):
					best = r
			if not best.is_empty():
				top_up("gold", int(best.get("gold", 0)))
				top_up("rep", int(best.get("rep", 0)))
				top_up("gems", int(best.get("gems", 0)))
		"heroes":
			top_up("gold", Heroes.level_cost("son"))
		"gunsmith":
			var cheap := 0
			for a in Attach.LIST.keys():
				var g := int((Attach.LIST[a] as Dictionary).get("gems", 0))
				if g > 0 and (cheap == 0 or g < cheap):
					cheap = g
			top_up("gems", cheap)
		"sgear":
			top_up("tokens", SurvGear.BOX_PRICE)
		"moves":
			# The cheapest strike still to learn for the hero on screen.
			var cheap := 0
			for r in Moves.for_role(App.solo_role if App.solo_role in ["son", "father"] else "son"):
				var g := int((r as Dictionary).get("gold", 0))
				if g > 0 and not Moves.learned(App.solo_role if App.solo_role in ["son", "father"] else "son", str((r as Dictionary).get("id", ""))) and (cheap == 0 or g < cheap):
					cheap = g
			top_up("gold", cheap)
		"armory":
			var cheapest := 0
			for id in FamilyProfile.data.get("weapons_found", []):
				if Arsenal.level(str(id)) < Arsenal.MAX_LV:
					var c := Arsenal.level_cost(str(id))
					if c > 0 and (cheapest == 0 or c < cheapest):
						cheapest = c
			top_up("gold", cheapest)
		"forge":
			# The guide's first forging (the steel cap) is always in reach.
			var rc := ForgeBook.recipe(ErrandGuide.FORGE_FIRST)
			cover_step({"gold": int(rc.get("gold", 0)), "parts": rc.get("mats", {})})
