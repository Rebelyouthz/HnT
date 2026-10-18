class_name StickBook
extends RefCounted

## Right-stick fighting LOADOUT. Every punch and kick that can be thrown with
## a stick path lives here; the face buttons keep the rest (Moves slots:
## air strikes, jumping kicks, the string ender ...).
##   Each stick PATH is a slot holding one move. Punch paths take punches,
##   R2 + path takes kicks. Learning a strike asks EQUIP NOW? (EquipPrompt):
##   it goes in a free path, or you pick which one it replaces.
## Paths, read when the stick springs back (in the facing direction):
##   flick ............ flick forward          diag_up ..... flick up-forward
##   diag_down ........ flick down-forward     down ........ flick down
##   circle ........... quarter circle         upper ....... half circle up
##   spin ............. full circle            back ........ flick back
##   windup ........... pull back, then push   charge ...... hold back 1s, push
## Every stick throw also counts as a combo input (combo_tok), so the dojo
## and COMBO LAB strings work on the stick.

const PUNCH := ["flick", "diag_up", "diag_down", "down", "circle", "upper", "spin", "back", "windup", "charge"]
const KICK := ["k_flick", "k_diag_up", "k_down", "k_circle", "k_upper", "k_spin", "k_windup"]
const NAME := {
	"flick": "FLICK  ▶", "diag_up": "FLICK  ◥", "diag_down": "FLICK  ◢", "down": "FLICK  ▼",
	"circle": "QUARTER CIRCLE", "upper": "HALF CIRCLE UP", "spin": "FULL CIRCLE", "back": "FLICK  ◀",
	"windup": "PULL BACK + PUSH", "charge": "HOLD BACK 1s + PUSH",
	"k_flick": "R2 + FLICK  ▶", "k_diag_up": "R2 + FLICK  ◥", "k_down": "R2 + FLICK  ▼",
	"k_circle": "R2 + QUARTER CIRCLE", "k_upper": "R2 + HALF CIRCLE UP", "k_spin": "R2 + FULL CIRCLE",
	"k_windup": "R2 + PULL BACK + PUSH",
}
## What a fresh hero has on the stick. Slots whose move is not learned yet
## stand EMPTY (the plain strike comes out) until something is equipped.
const DEFAULT := {
	"flick": "cross", "diag_up": "overhand", "diag_down": "body_hook", "down": "gut", "circle": "hook",
	"upper": "uppercut", "spin": "spin_backfist", "back": "turn_punch", "windup": "haymaker", "charge": "mega_punch",
	"k_flick": "front_kick", "k_diag_up": "high_kick", "k_down": "low_kick", "k_circle": "roundhouse",
	"k_upper": "high_kick", "k_spin": "spin_high_kick", "k_windup": "spin_low_kick",
}
## The plain strike a path throws while it is empty.
const PLAIN := {"punch": "jab", "kick": "front_kick"}
## Combo input each path counts as (ComboBook tokens).
const TOK := {
	"flick": "L", "diag_up": "U+L", "diag_down": "Dn+L", "down": "Dn+L", "circle": "H", "upper": "U+H",
	"spin": "B+H", "back": "B+H", "windup": "F+H", "charge": "F+H",
	"k_flick": "F+H", "k_diag_up": "U+H", "k_down": "Dn+L", "k_circle": "H", "k_upper": "U+H", "k_spin": "B+H", "k_windup": "F+H",
}

## Every strike that fits the stick. kind = the Fighter attack it throws;
## need = "" (everyone has it), "dojo:<id>" (bought + drilled) or "move"
## (learned in the MOVES library). clips = what plays (first one found).
const CAT := {
	"jab": {"type": "punch", "kind": "light", "title": "JAB STRING", "need": "", "w": 0.15},
	"cross": {"type": "punch", "kind": "cross_rs", "title": "CROSS", "need": "", "w": 0.35, "clips": ["cross", "jab"]},
	"overhand": {"type": "punch", "kind": "overhand", "title": "OVERHAND", "need": "", "w": 0.55, "clips": ["superman_punch", "cross", "heavy"]},
	"body_hook": {"type": "punch", "kind": "body_hook", "title": "BODY HOOK", "need": "", "w": 0.5},
	"gut": {"type": "punch", "kind": "gut-punch", "title": "GUT PUNCH", "need": "", "w": 0.45},
	"hook": {"type": "punch", "kind": "hook", "title": "HOOK", "need": "", "w": 0.45},
	"turn_punch": {"type": "punch", "kind": "turn_punch", "title": "TURN PUNCH", "need": "", "w": 0.6},
	"uppercut": {"type": "punch", "kind": "uppercut", "title": "UPPERCUT", "need": "dojo:uppercut", "w": 0.75},
	"haymaker": {"type": "punch", "kind": "haymaker", "title": "HAYMAKER", "need": "dojo:haymaker", "w": 0.9},
	"mega_punch": {"type": "punch", "kind": "power_punch", "title": "MEGA PUNCH", "need": "dojo:power_punch", "w": 1.0},
	"spin_backfist": {"type": "punch", "kind": "spin_backfist", "title": "SPIN BACKFIST", "need": "dojo:spin_backfist", "w": 0.75},
	"elbow": {"type": "punch", "kind": "elbow", "title": "ELBOW", "need": "move", "w": 0.55, "clips": ["elbow", "cross"]},
	"headbutt": {"type": "punch", "kind": "headbutt", "title": "HEADBUTT", "need": "move", "w": 0.6, "clips": ["headbutt", "heavy"]},
	"hammer": {"type": "punch", "kind": "hammer", "title": "HAMMER FIST", "need": "move", "w": 0.95, "clips": ["hammer", "heavy"]},
	"superman_punch": {"type": "punch", "kind": "superman_punch", "title": "SUPERMAN PUNCH", "need": "move", "w": 0.8, "clips": ["superman_punch", "heavy"]},
	"shoulder_charge": {"type": "punch", "kind": "shoulder_charge", "title": "SHOULDER CHARGE", "need": "move", "w": 0.85, "clips": ["shoulder_charge", "heavy"]},
	"front_kick": {"type": "kick", "kind": "front_kick", "title": "FRONT KICK", "need": "", "w": 0.5},
	"side_kick": {"type": "kick", "kind": "side_kick_rs", "title": "SIDE KICK", "need": "move", "w": 0.65, "clips": ["side_kick", "front_kick"]},
	"roundhouse": {"type": "kick", "kind": "roundhouse", "title": "ROUNDHOUSE", "need": "dojo:roundhouse", "w": 0.85},
	"high_kick": {"type": "kick", "kind": "high_kick", "title": "HIGH KICK", "need": "dojo:high_kick", "w": 0.7},
	"low_kick": {"type": "kick", "kind": "low_kick", "title": "LOW KICK", "need": "dojo:low_kick", "w": 0.4},
	"spin_high_kick": {"type": "kick", "kind": "spin_high_kick", "title": "SPINNING HIGH KICK", "need": "move", "w": 0.9, "clips": ["spin_high_kick", "roundhouse", "side_kick"]},
	"spin_low_kick": {"type": "kick", "kind": "spin_low_kick", "title": "SPINNING LEG SWEEP", "need": "move", "w": 0.7, "clips": ["spin_low_kick", "sweep", "boot_kick", "front_kick"], "low": true},
	"boot_kick": {"type": "kick", "kind": "boot_kick", "title": "DOCK BOOT", "need": "move", "w": 0.8, "clips": ["boot_kick", "front_kick"]},
	"sweep": {"type": "kick", "kind": "sweep", "title": "LEG SWEEP", "need": "move", "w": 0.55, "clips": ["sweep", "boot_kick", "front_kick"], "low": true},
	"flying_knee": {"type": "kick", "kind": "flying_knee", "title": "FLYING KNEE", "need": "move", "w": 0.7, "clips": ["flying_knee", "front_kick"]},
	"clinch_knee": {"type": "kick", "kind": "clinch_knee", "title": "CLINCH KNEE", "need": "move", "w": 0.6, "clips": ["clinch_knee", "front_kick"]},
	"cartwheel_kick": {"type": "kick", "kind": "cartwheel_kick", "title": "CARTWHEEL KICK", "need": "move", "w": 0.8, "clips": ["cartwheel_kick", "roundhouse"]},
}


static func slots_of(type: String) -> Array:
	return PUNCH if type == "punch" else KICK


static func type_of_slot(slot: String) -> String:
	return "kick" if slot.begins_with("k_") else "punch"


static func fits(id: String) -> bool:
	return CAT.has(id)


## Can this hero throw it? Library moves follow data/moves.json's "who".
static func usable(role: String, id: String) -> bool:
	if not CAT.has(id):
		return false
	var need := str((CAT[id] as Dictionary).get("need", ""))
	if need == "":
		return true
	if need.begins_with("dojo:"):
		return FamilyProfile.dojo_learned(need.substr(5))
	return Moves.learned(role, id)


static func _store(role: String) -> Dictionary:
	var d: Dictionary = FamilyProfile.data.get("stick_loadout", {})
	return (d.get(role, {}) as Dictionary)


## The first look at a hero's stick fills it with what he can already throw
## and leaves the rest EMPTY, so every strike learned later asks EQUIP NOW?
static func _ensure(role: String) -> void:
	var d: Dictionary = FamilyProfile.data.get("stick_loadout", {})
	if d.has(role):
		return
	var lo := {}
	for s in PUNCH + KICK:
		lo[s] = str(DEFAULT[s]) if usable(role, str(DEFAULT[s])) else ""
	# One path per move: the first path that names it keeps it.
	var seen := {}
	for s in PUNCH + KICK:
		if lo[s] != "" and seen.has(lo[s]):
			lo[s] = ""
		seen[lo[s]] = true
	d[role] = lo
	FamilyProfile.data["stick_loadout"] = d


## slot -> move id ("" = empty) for this hero.
static func loadout(role: String) -> Dictionary:
	_ensure(role)
	var saved := _store(role)
	var out := {}
	for s in PUNCH + KICK:
		var id := str(saved.get(s, DEFAULT[s]))
		out[s] = id if id != "" and usable(role, id) else ""
	return out


static func set_slot(role: String, slot: String, id: String) -> bool:
	if id != "" and (not usable(role, id) or str((CAT[id] as Dictionary)["type"]) != type_of_slot(slot)):
		return false
	var d: Dictionary = FamilyProfile.data.get("stick_loadout", {})
	var lo: Dictionary = d.get(role, {})
	# One move sits on one path: equipping it again moves it.
	if id != "":
		for s in lo.keys():
			if str(lo[s]) == id and s != slot:
				lo[s] = ""
	lo[slot] = id
	d[role] = lo
	FamilyProfile.data["stick_loadout"] = d
	FamilyProfile.save()
	return true


static func slot_of(role: String, id: String) -> String:
	var lo := loadout(role)
	for s in lo:
		if str(lo[s]) == id:
			return s
	return ""


## First empty path that takes this move, "" when they are all full.
static func free_slot(role: String, id: String) -> String:
	if not CAT.has(id):
		return ""
	var lo := loadout(role)
	var paths: Array = slots_of(str((CAT[id] as Dictionary)["type"]))
	# Its home path first (the uppercut on HALF CIRCLE UP), then any empty one.
	for s in paths:
		if str(DEFAULT[s]) == id and str(lo[s]) == "":
			return s
	for s in paths:
		if str(lo[s]) == "":
			return s
	return ""


## The move a path throws right now (its plain strike when empty).
static func move_at(role: String, slot: String) -> String:
	var id := str(loadout(role).get(slot, ""))
	return id if id != "" else str(PLAIN[type_of_slot(slot)])


static func kind_of(id: String) -> String:
	return str((CAT.get(id, {}) as Dictionary).get("kind", "light"))


static func title(id: String) -> String:
	return str((CAT.get(id, {}) as Dictionary).get("title", id.to_upper()))


## Hitbox / timing for stick kinds the Fighter has no hand-made entry for
## (Fighter.RS_MOVES covers the classics). Empty when unknown.
static func spec(kind: String) -> Dictionary:
	for id in CAT:
		var r: Dictionary = CAT[id]
		if str(r["kind"]) == kind and r.has("clips"):
			var w := float(r.get("w", 0.5))
			return {"clips": r["clips"], "size": Vector2(54.0 + 30.0 * w, 30.0 if bool(r.get("low", false)) else 40.0 + 12.0 * w),
				"cd": 14 + int(round(18.0 * w)), "shout": str(r["title"]) if w >= 0.7 else "", "low": bool(r.get("low", false))}
	return {}


## Damage of a generic stick kind (Punk), 0 when it is not one.
static func dmg(kind: String) -> int:
	for id in CAT:
		var r: Dictionary = CAT[id]
		if str(r["kind"]) == kind and r.has("clips"):
			return 9 + int(round(24.0 * float(r.get("w", 0.5))))
	return 0


## Dojo lesson ids -> the stick move they teach.
const FROM_DOJO := {"uppercut": "uppercut", "haymaker": "haymaker", "power_punch": "mega_punch", "spin_backfist": "spin_backfist", "roundhouse": "roundhouse", "high_kick": "high_kick", "low_kick": "low_kick"}


## Every stick strike of a kind this hero can throw now.
static func options(role: String, type: String) -> Array:
	var out: Array = []
	for id in CAT:
		if str((CAT[id] as Dictionary)["type"]) == type and usable(role, str(id)):
			out.append(str(id))
	return out


## Step a path through EMPTY and every usable strike of its kind.
static func cycle(role: String, slot: String, step: int) -> String:
	var opts: Array = [""]
	opts.append_array(options(role, type_of_slot(slot)))
	var cur := opts.find(str(loadout(role).get(slot, "")))
	var nxt: String = opts[(cur + step + opts.size()) % opts.size()]
	set_slot(role, slot, nxt)
	return nxt


## Icon clip of a stick strike (what the menus draw).
static func clip_of(id: String) -> String:
	var r: Dictionary = CAT.get(id, {})
	if r.has("clips"):
		return str((r["clips"] as Array)[0])
	return str({"jab": "jab", "gut": "gut", "mega_punch": "mega_punch", "haymaker": "heavy", "hook": "cross", "body_hook": "body_hook", "turn_punch": "turn_punch", "high_kick": "side_kick", "low_kick": "boot_kick"}.get(id, id))
