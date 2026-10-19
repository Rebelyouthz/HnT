class_name Palettes
extends RefCounted

## Colour palettes for the two heroes (Streets of Rage 4 style alternates):
## the clothes a suit part does not cover are re-dyed in the wound shader
## (`pal`), skin and blood untouched. Each unlocks off something you did.

const LIST := {
	"street": {"title": "STREET", "dye": Color(0, 0, 0, 0), "need": "", "line": "As they came in."},
	"midnight": {"title": "MIDNIGHT", "dye": Color(0.28, 0.36, 0.78, 0.75), "need": "kills_total:100", "line": "100 thugs filed."},
	"blood": {"title": "BLOOD DEBT", "dye": Color(0.78, 0.12, 0.14, 0.8), "need": "kills_total:400", "line": "400 thugs filed."},
	"neon": {"title": "NEON EXCHANGE", "dye": Color(0.15, 0.95, 0.75, 0.7), "need": "tricks:150", "line": "150 tricks landed."},
	"ghost": {"title": "GHOST SHIFT", "dye": Color(0.86, 0.88, 0.95, 0.75), "need": "survive_clears:3", "line": "3 coping hours held."},
	"gold": {"title": "GOLD CARD", "dye": Color(0.95, 0.72, 0.18, 0.8), "need": "account_level:10", "line": "Account level 10."},
}


static func unlocked(id: String) -> bool:
	var need := str((LIST.get(id, {}) as Dictionary).get("need", ""))
	if need == "":
		return true
	var k := need.get_slice(":", 0)
	return int(FamilyProfile.data.get(k, 0)) >= int(need.get_slice(":", 1))


static func worn(role: String) -> String:
	var id := str(FamilyProfile.data.get("palette_" + role, "street"))
	return id if LIST.has(id) and unlocked(id) else "street"


static func wear(role: String, id: String) -> void:
	if unlocked(id):
		FamilyProfile.data["palette_" + role] = id
		FamilyProfile.save()


## Dyes `anim` with the role's palette (call after Suits.dress).
static func apply(anim: CanvasItem, role: String) -> void:
	if anim == null:
		return
	var id := worn(role)
	var dye: Color = (LIST[id] as Dictionary)["dye"]
	if dye.a <= 0.0 and not (anim.material is ShaderMaterial):
		return
	if not (anim.material is ShaderMaterial):
		BloodSim.wound(anim, 0.0, 0.0, 1.0)
	var m := anim.material as ShaderMaterial
	if m:
		m.set_shader_parameter("pal", Vector4(dye.r, dye.g, dye.b, dye.a))
