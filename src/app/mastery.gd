class_name Mastery
extends RefCounted

## Practice makes it land: every strike a hero throws counts for that move
## (its clip - the plain jab, the cross, the roundhouse...). Use it enough and
## it ranks up: a little more power, a slightly quicker wind-up, a shorter
## recovery. Small steps on purpose - the jab you have thrown 800 times is
## noticeably better, never broken.

const STEPS := [20, 60, 140, 280, 500, 800]
const DMG := 0.03
const SPEED := 0.025
const RECOVER := 0.03


static func _book() -> Dictionary:
	if not FamilyProfile.data.has("mastery"):
		FamilyProfile.data["mastery"] = {"son": {}, "father": {}}
	return FamilyProfile.data["mastery"]


static func uses(role: String, clip: String) -> int:
	return int((_book().get(role, {}) as Dictionary).get(clip, 0))


static func level(role: String, clip: String) -> int:
	var n := uses(role, clip)
	var lv := 0
	for s in STEPS:
		if n >= int(s):
			lv += 1
	return lv


## Uses still needed for the next rank (0 when maxed).
static func to_next(role: String, clip: String) -> int:
	var lv := level(role, clip)
	if lv >= STEPS.size():
		return 0
	return int(STEPS[lv]) - uses(role, clip)


static func power(role: String, clip: String) -> float:
	return 1.0 + DMG * float(level(role, clip))


## Multiplier on the wind-up time (lower is faster).
static func speed(role: String, clip: String) -> float:
	return 1.0 - SPEED * float(level(role, clip))


## Multiplier on the recovery (attack cooldown).
static func recovery(role: String, clip: String) -> float:
	return 1.0 - RECOVER * float(level(role, clip))


## One more throw. Announces a new rank where the hero stands.
static func use(role: String, clip: String, at: Vector2) -> void:
	if role != "son" and role != "father" or clip == "":
		return
	var b := _book()
	if not b.has(role):
		b[role] = {}
	var before := level(role, clip)
	(b[role] as Dictionary)[clip] = uses(role, clip) + 1
	var after := level(role, clip)
	if after > before:
		var nm := clip.replace("_", " ").to_upper()
		Juice.popup_number(at + Vector2(0, -110), "%s MASTERY %d" % [nm, after], Color(1.0, 0.85, 0.3))
		Juice.toast("achievement", "%s  ·  MASTERY %d" % [nm, after], "+%d%% power, quicker wind-up, shorter recovery." % int(round(DMG * 100.0 * float(after))), "cur_xp")
