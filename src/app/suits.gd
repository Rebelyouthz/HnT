class_name Suits
extends RefCounted

## Hero suits worn over the same father and son (the people under them stay
## who they are). Every suit fits either of them; each is earned once for
## the family. Drawn by the wound shader's suit pass, so blood and wounds
## still land on top. Stats are small flavour bonuses shown in the locker.

const LIST := {
	"bat": {"title": "BAT SUIT", "code": 1, "rarity": "legendary", "icon": "bat",
		"blurb": "Cowl, belt, the emblem. Found in Gant's office. Nobody asks.",
		"how": "Beat Collector Gant (Dock Street boss).", "perk": "PERK: the cape glides - either of you.", "stats": {"hp": 2, "dmg": 2, "steam": 0, "speed": 0}},
	"spider": {"title": "SPIDER SUIT", "code": 2, "rarity": "legendary", "icon": "spider",
		"blurb": "Red, blue, webs. Dad says it's for the back. It isn't.",
		"how": "Beat Collector Gant (Dock Street boss).", "perk": "PERK: jumps 12% higher.", "stats": {"hp": 0, "dmg": 1, "steam": 0, "speed": 12}},
	"shaolin": {"title": "SHAOLIN ROBE", "code": 3, "rarity": "epic", "icon": "fist",
		"blurb": "Saffron, beads, a shaved head. Inner peace, outer bruises.",
		"how": "Master three moves in the dojo.", "perk": "PERK: 50% wider parry window.", "stats": {"hp": 6, "dmg": 0, "steam": 6, "speed": 0}},
	"ninja": {"title": "NINJA GI", "code": 4, "rarity": "epic", "icon": "eye",
		"blurb": "Black, quiet, one red sash. The street never saw you.",
		"how": "Find three secret stashes.", "perk": "PERK: the dash is a vanish - double i-frames, smoke.", "stats": {"hp": 0, "dmg": 1, "steam": 0, "speed": 16}},
}


static func owned(id: String) -> bool:
	return (FamilyProfile.data.get("suits_owned", []) as Array).has(id)


static func worn(role: String) -> String:
	return str(FamilyProfile.data.get("suit_" + role, ""))


static func grant(id: String) -> void:
	if owned(id) or not LIST.has(id):
		return
	var a: Array = FamilyProfile.data.get("suits_owned", [])
	a.append(id)
	FamilyProfile.data["suits_owned"] = a
	FamilyProfile.flag_unseen("suit_" + id)
	FamilyProfile.save()
	var row: Dictionary = LIST[id]
	Juice.unlock_logo(str(row["title"]), str(row["blurb"]), "SUIT  ·  %s  ·  WEAR IT IN GEAR" % str(row["rarity"]).to_upper())
	Rarity.juice(str(row["rarity"]), str(row["title"]))


## Unlocks earned by progress (called after dojo training / stash finds).
static func check_progress() -> void:
	if int(FamilyProfile.data.get("dojo_masters", 0)) >= 3:
		grant("shaolin")
	if int(FamilyProfile.data.get("stashes_found", 0)) >= 3:
		grant("ninja")


static func wear(role: String, id: String) -> void:
	FamilyProfile.data["suit_" + role] = id
	FamilyProfile.save()


static func stats(role: String) -> Dictionary:
	var id := worn(role)
	return (LIST[id]["stats"] as Dictionary) if LIST.has(id) else {}


static func dress(anim: CanvasItem, role: String) -> void:
	var id := worn(role)
	if anim == null or id == "" or not LIST.has(id):
		return
	BloodSim.wound(anim, 0.0, 0.0, 1.0)
	var m := anim.material as ShaderMaterial
	if m:
		m.set_shader_parameter("suit", int(LIST[id]["code"]))
