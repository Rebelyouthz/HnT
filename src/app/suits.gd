class_name Suits
extends RefCounted

## Hero suits in three parts - MASK, TOP, BOTTOM - worn over the same father
## and son. Every part has its own perk (masks a gadget or a sense, tops a
## movement trick, bottoms a special attack), parts mix freely between suits,
## and wearing all three of one suit adds a set bonus. Drawn per body region
## by the wound shader (suit_head / suit_body / suit_legs), so blood and
## wounds still land on top.

const PARTS := ["mask", "top", "bottom"]
const PART_NAMES := {"mask": "MASK", "top": "TOP", "bottom": "BOTTOM"}

const LIST := {
	"bat": {"title": "BAT", "code": 1, "rarity": "legendary",
		"blurb": "Cowl, cape, belt. Found in Gant's office. Nobody asks.",
		"set": "DARK KNIGHT: +20% damage, batwings fly through every thug.",
		"parts": {
			"mask": {"title": "BAT COWL", "perk": "Throw (LT) with nobody to grab: a BATWING boomerang.", "how": "Beat Collector Gant.", "stats": {"dmg": 1}},
			"top": {"title": "BAT CAPE", "perk": "The cape flaps; glide (hold jump) and DOUBLE JUMP.", "how": "Climb the giant tower on Dock Street.", "stats": {"hp": 2}},
			"bottom": {"title": "BAT BOOTS", "perk": "SPECIAL: BAT DIVE - leap and slam a shockwave.", "how": "Claim three WANTED bounties.", "stats": {"dmg": 1, "hp": 1}},
		}},
	"spider": {"title": "SPIDER", "code": 2, "rarity": "legendary",
		"blurb": "Red, blue, webs. Dad says it's for the back. It isn't.",
		"set": "MAX SENSE: dodge 40% of hits on instinct.",
		"parts": {
			"mask": {"title": "SPIDER MASK", "perk": "SPIDER SENSE: 20% of hits dodged on instinct.", "how": "Beat Collector Gant.", "stats": {"speed": 4}},
			"top": {"title": "SPIDER TOP", "perk": "Throw (LT) with nobody to grab: a WEB SHOT that snares.", "how": "Survive the Intake Lot hour.", "stats": {"dmg": 1}},
			"bottom": {"title": "SPIDER LEGS", "perk": "Jump 12% higher. SPECIAL: WEB SLAM launches the crowd.", "how": "Wall-kick twenty times.", "stats": {"speed": 8}},
		}},
	"shaolin": {"title": "SHAOLIN", "code": 3, "rarity": "epic",
		"blurb": "Saffron, beads, a shaved head. Inner peace, outer bruises.",
		"set": "IRON BODY: take 30% less damage.",
		"parts": {
			"mask": {"title": "SHAVED HEAD & BEADS", "perk": "INNER FOCUS: steam refills twice as fast.", "how": "Master one dojo move.", "stats": {"steam": 4}},
			"top": {"title": "SAFFRON ROBE", "perk": "Parry window 50% wider.", "how": "Master three dojo moves.", "stats": {"hp": 4}},
			"bottom": {"title": "MONK WRAPS", "perk": "SPECIAL: HUNDRED KICKS - a flurry in front of you.", "how": "Land ten perfect parries.", "stats": {"hp": 2, "steam": 2}},
		}},
	"ninja": {"title": "NINJA", "code": 4, "rarity": "epic",
		"blurb": "Black, quiet, one red sash. The street never saw you.",
		"set": "SMOKE BOMB: every dash leaves smoke that stuns thugs nearby.",
		"parts": {
			"mask": {"title": "NINJA HOOD", "perk": "Throw (LT) with nobody to grab: three SHURIKEN.", "how": "Find one secret stash.", "stats": {"dmg": 1}},
			"top": {"title": "NINJA GI", "perk": "The dash is a vanish: double i-frames, smoke.", "how": "Find three secret stashes.", "stats": {"speed": 8}},
			"bottom": {"title": "TABI & SASH", "perk": "SPECIAL: SHADOW STEP - appear behind a thug and strike.", "how": "Finish five side jobs.", "stats": {"speed": 6, "dmg": 1}},
		}},
}


static func part_id(suit: String, part: String) -> String:
	return "%s_%s" % [suit, part]


static func part_row(suit: String, part: String) -> Dictionary:
	if not LIST.has(suit):
		return {}
	return ((LIST[suit]["parts"] as Dictionary).get(part, {})) as Dictionary


static func owned_part(suit: String, part: String) -> bool:
	_migrate()
	return (FamilyProfile.data.get("suit_parts", []) as Array).has(part_id(suit, part))


static func owned(suit: String) -> bool:
	for p in PARTS:
		if owned_part(suit, p):
			return true
	return false


## What suit's part this fighter wears in a slot ("" = street clothes).
static func worn_part(role: String, part: String) -> String:
	_migrate()
	return str(FamilyProfile.data.get("suit_%s_%s" % [role, part], ""))


## The suit worn in full (all three parts of one suit), or "".
static func full_set(role: String) -> String:
	var s := worn_part(role, "mask")
	if s != "" and worn_part(role, "top") == s and worn_part(role, "bottom") == s:
		return s
	return ""


## Kept for old callers: the full set, or the top's suit.
static func worn(role: String) -> String:
	var f := full_set(role)
	return f if f != "" else worn_part(role, "top")


static func has_perk(role: String, suit: String, part: String) -> bool:
	return worn_part(role, part) == suit


static func grant_part(suit: String, part: String) -> void:
	if owned_part(suit, part) or part_row(suit, part).is_empty():
		return
	var a: Array = FamilyProfile.data.get("suit_parts", [])
	a.append(part_id(suit, part))
	FamilyProfile.data["suit_parts"] = a
	FamilyProfile.flag_unseen("suit_" + suit)
	FamilyProfile.save()
	var row := part_row(suit, part)
	Juice.unlock_logo(str(row["title"]), str(row["perk"]), "SUIT PART  ·  %s  ·  WEAR IT IN GEAR" % str(LIST[suit]["rarity"]).to_upper())
	Rarity.juice(str(LIST[suit]["rarity"]), str(row["title"]))


## Old API (boss drops): the suit's mask.
static func grant(suit: String) -> void:
	grant_part(suit, "mask")


## Unlocks earned by progress (dojo / stash / bounty / tower / side-job /
## wall-kick milestones).
static func check_progress() -> void:
	var d := FamilyProfile.data
	var masters := int(d.get("dojo_masters", 0))
	var stashes := int(d.get("stashes_found", 0))
	if masters >= 1:
		grant_part("shaolin", "mask")
	if masters >= 3:
		grant_part("shaolin", "top")
	if int(d.get("perfect_parries", 0)) >= 10:
		grant_part("shaolin", "bottom")
	if stashes >= 1:
		grant_part("ninja", "mask")
	if stashes >= 3:
		grant_part("ninja", "top")
	if int(d.get("side_jobs_done", 0)) >= 5:
		grant_part("ninja", "bottom")
	if int(d.get("towers_climbed", 0)) >= 1:
		grant_part("bat", "top")
	if int(d.get("wanted_claimed", 0)) >= 3:
		grant_part("bat", "bottom")
	if (d.get("maps_filed", []) as Array).has("intake_lot"):
		grant_part("spider", "top")
	if int(d.get("wallkicks", 0)) >= 20:
		grant_part("spider", "bottom")


static func wear_part(role: String, part: String, suit: String) -> void:
	FamilyProfile.data["suit_%s_%s" % [role, part]] = suit
	FamilyProfile.save()


## Old API: wear a whole suit (or "" for none), the parts you own.
static func wear(role: String, suit: String) -> void:
	for p in PARTS:
		if suit == "" or owned_part(suit, p):
			FamilyProfile.data["suit_%s_%s" % [role, p]] = suit
	FamilyProfile.save()


static func stats(role: String) -> Dictionary:
	var out := {}
	for p in PARTS:
		var st: Dictionary = part_row(worn_part(role, p), p).get("stats", {})
		for k in st:
			out[k] = int(out.get(k, 0)) + int(st[k])
	return out


static func code_of(suit: String) -> int:
	return int((LIST.get(suit, {}) as Dictionary).get("code", 0))


static func dress(anim: CanvasItem, role: String) -> void:
	if anim == null:
		return
	var h := code_of(worn_part(role, "mask"))
	var b := code_of(worn_part(role, "top"))
	var l := code_of(worn_part(role, "bottom"))
	if h == 0 and b == 0 and l == 0:
		return
	BloodSim.wound(anim, 0.0, 0.0, 1.0)
	var m := anim.material as ShaderMaterial
	if m:
		m.set_shader_parameter("suit_head", h)
		m.set_shader_parameter("suit_body", b)
		m.set_shader_parameter("suit_legs", l)


## Saves from before the split had whole suits: give their parts and dress
## the same.
static func _migrate() -> void:
	var d := FamilyProfile.data
	if bool(d.get("suits_split", false)):
		return
	d["suits_split"] = true
	var parts: Array = d.get("suit_parts", [])
	for s in (d.get("suits_owned", []) as Array):
		for p in PARTS:
			if not parts.has(part_id(str(s), p)):
				parts.append(part_id(str(s), p))
	d["suit_parts"] = parts
	for role in ["son", "father"]:
		var old := str(d.get("suit_" + role, ""))
		if old != "":
			for p in PARTS:
				d["suit_%s_%s" % [role, p]] = old
