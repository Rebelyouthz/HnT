class_name Charms
extends RefCounted

## Lucky charms: small trinkets found on bosses and in broken things. Wear
## up to three (locker); each bends one rule of the street.

const MAX_WORN := 3
const LIST := {
	"lucky_coin": {"title": "LUCKY COIN", "blurb": "+50% cash from everything you break.", "rarity": "uncommon"},
	"rabbit_foot": {"title": "RABBIT FOOT", "blurb": "12% of hits CRIT for double damage.", "rarity": "rare"},
	"moms_ring": {"title": "MOM'S RING", "blurb": "A second adrenaline syringe hides on every street.", "rarity": "epic"},
	"old_watch": {"title": "GRANDPA'S WATCH", "blurb": "Timing windows 25% wider. Parkour feels slower.", "rarity": "rare"},
	"fight_tape": {"title": "FIGHT TAPE", "blurb": "Every kill you land heals 3 HP.", "rarity": "rare"},
	"dog_tag": {"title": "DOG TAG", "blurb": "The level-up force wave reaches 40% further.", "rarity": "uncommon"},
}


static func owned() -> Array:
	return FamilyProfile.data.get("charms_owned", [])


static func worn() -> Array:
	return FamilyProfile.data.get("charms_worn", [])


static func has(id: String) -> bool:
	return worn().has(id)


static func grant(id: String) -> void:
	if owned().has(id) or not LIST.has(id):
		return
	var a := owned()
	a.append(id)
	FamilyProfile.data["charms_owned"] = a
	if worn().size() < MAX_WORN:
		var w := worn()
		w.append(id)
		FamilyProfile.data["charms_worn"] = w
	FamilyProfile.save()
	var row: Dictionary = LIST[id]
	Juice.unlock_logo(str(row["title"]), str(row["blurb"]), "CHARM  ·  %s" % Rarity.label(str(row["rarity"])))
	Rarity.juice(str(row["rarity"]), str(row["title"]))


## A random charm you don't have yet ("" when you have them all).
static func roll() -> String:
	var pool: Array = []
	for id: String in LIST.keys():
		if not owned().has(id):
			pool.append(id)
	return "" if pool.is_empty() else str(pool[randi() % pool.size()])


static func toggle(id: String) -> void:
	var w := worn()
	if w.has(id):
		w.erase(id)
	elif w.size() < MAX_WORN:
		w.append(id)
	FamilyProfile.data["charms_worn"] = w
	FamilyProfile.save()
