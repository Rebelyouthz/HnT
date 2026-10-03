class_name Suits
extends RefCounted

## Hero suits found on the streets and worn from the locker in the camp:
## the Bat Suit (the son) and the Spider Suit (the father), both dropped by
## Collector Gant when Dock Street is filed. Drawn by the wound shader's
## suit pass, so blood and wounds still land on top.

const LIST := {
	"bat": {"role": "son", "title": "BAT SUIT", "blurb": "Cowl, belt, the emblem. Found in Gant's office. Nobody asks.", "code": 1},
	"spider": {"role": "father", "title": "SPIDER SUIT", "blurb": "Red, blue, webs. Dad says it's for the back. It isn't.", "code": 2},
}


static func owned(id: String) -> bool:
	return (FamilyProfile.data.get("suits_owned", []) as Array).has(id)


static func worn(role: String) -> String:
	return str(FamilyProfile.data.get("suit_" + role, ""))


static func grant(id: String) -> void:
	if owned(id):
		return
	var a: Array = FamilyProfile.data.get("suits_owned", [])
	a.append(id)
	FamilyProfile.data["suits_owned"] = a
	FamilyProfile.flag_unseen("suit_" + id)
	FamilyProfile.save()
	var row: Dictionary = LIST[id]
	Juice.unlock_logo(str(row["title"]), str(row["blurb"]), "SUIT  ·  LEGENDARY  ·  WEAR IT IN THE LOCKER")
	Rarity.juice("legendary", str(row["title"]))


static func wear(role: String, id: String) -> void:
	FamilyProfile.data["suit_" + role] = id
	FamilyProfile.save()


static func dress(anim: CanvasItem, role: String) -> void:
	var id := worn(role)
	if anim == null or id == "" or not LIST.has(id):
		return
	BloodSim.wound(anim, 0.0, 0.0, 1.0)
	var m := anim.material as ShaderMaterial
	if m:
		m.set_shader_parameter("suit", int(LIST[id]["code"]))
