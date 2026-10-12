class_name Moves
extends RefCounted

## Your own fighting style. Every hero has a LOADOUT of move slots; any
## learned strike (data/moves.json) that fits a slot can go in it:
##   L1 L2 L3   the light string (1st, 2nd, 3rd press)
##   H          heavy        F+H  forward + heavy     U+H  up + heavy
##   STR        heavy after two lights (the string ender)
##   AIR_L      light in the air                       AIR_H  heavy in the air
## Damage follows the move's weight against the slot's default (a dropkick
## in L1 hits much harder than a jab, but it is slow to come out and long
## to recover). Moves are learned in the dojo (lessons or gold).
## COMBO LAB: up to six custom combos per hero (2-4 inputs + a finisher),
## merged into ComboBook so they fire like the built-in ones.
## STYLES: three saved loadouts per hero, switch any time.

const SLOTS := ["L1", "L2", "L3", "H", "F+H", "U+H", "STR", "AIR_L", "AIR_H"]
const SLOT_KIND := {"L1": "light", "L2": "light", "L3": "light", "H": "heavy", "F+H": "heavy", "U+H": "heavy", "STR": "heavy", "AIR_L": "air", "AIR_H": "air"}
const SLOT_NAME := {"L1": "LIGHT 1", "L2": "LIGHT 2", "L3": "LIGHT 3", "H": "HEAVY", "F+H": "FWD + HEAVY", "U+H": "UP + HEAVY", "STR": "STRING ENDER", "AIR_L": "AIR LIGHT", "AIR_H": "AIR HEAVY"}
const DEFAULT := {"L1": "jab", "L2": "cross", "L3": "gut", "H": "heavy", "F+H": "heavy", "U+H": "uppercut", "STR": "roundhouse", "AIR_L": "front_kick", "AIR_H": "air_spin_kick"}
const TOKENS := ["L", "H", "F+L", "F+H", "B+H", "U+H", "U+L", "Dn+L", "D", "J"]
const MAX_CUSTOM := 6
const FX := ["launch", "fling", "knockdown", "stun", "crush"]

static var _book: Array = []


static func book() -> Array:
	if _book.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves.json"))
		_book = (parsed as Dictionary).get("moves", []) if parsed is Dictionary else []
	return _book


static func row(id: String) -> Dictionary:
	for r: Dictionary in book():
		if str(r["id"]) == id:
			return r
	return {}


static func for_role(role: String) -> Array:
	var out: Array = []
	for r: Dictionary in book():
		if (r.get("who", []) as Array).has(role):
			out.append(r)
	return out


static func learned(role: String, id: String) -> bool:
	var r := row(id)
	if r.is_empty() or not (r.get("who", []) as Array).has(role):
		return false
	if bool(r.get("starter", false)):
		return true
	var lesson := str(r.get("lesson", ""))
	if lesson != "" and FamilyProfile.dojo_learned(lesson):
		return true
	return ((FamilyProfile.data.get("moves_learned", {}) as Dictionary).get(role, []) as Array).has(id)


static func learn(role: String, id: String) -> bool:
	var r := row(id)
	if r.is_empty() or learned(role, id):
		return false
	var g := int(r.get("gold", 0))
	if int(FamilyProfile.data.get("gold", 0)) < g:
		return false
	FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - g
	var d: Dictionary = FamilyProfile.data.get("moves_learned", {})
	var a: Array = d.get(role, [])
	a.append(id)
	d[role] = a
	FamilyProfile.data["moves_learned"] = d
	FamilyProfile.save()
	return true


static func fits(id: String, slot: String) -> bool:
	return (row(id).get("slots", []) as Array).has(str(SLOT_KIND.get(slot, "")))


static func loadout(role: String) -> Dictionary:
	var d: Dictionary = FamilyProfile.data.get("loadout_moves", {})
	var lo: Dictionary = (d.get(role, {}) as Dictionary).duplicate()
	for s in SLOTS:
		if not lo.has(s) or not learned(role, str(lo[s])):
			lo[s] = DEFAULT[s]
	return lo


static func set_slot(role: String, slot: String, id: String) -> bool:
	if not learned(role, id) or not fits(id, slot):
		return false
	var d: Dictionary = FamilyProfile.data.get("loadout_moves", {})
	var lo: Dictionary = d.get(role, {})
	lo[slot] = id
	d[role] = lo
	FamilyProfile.data["loadout_moves"] = d
	FamilyProfile.save()
	return true


## Next learned move that fits the slot (for cycling with left / right).
static func cycle(role: String, slot: String, step: int) -> String:
	var opts: Array = []
	for r: Dictionary in for_role(role):
		if learned(role, str(r["id"])) and fits(str(r["id"]), slot):
			opts.append(str(r["id"]))
	if opts.is_empty():
		return DEFAULT[slot]
	var cur := opts.find(str(loadout(role)[slot]))
	var nxt: String = opts[(cur + step + opts.size()) % opts.size()]
	set_slot(role, slot, nxt)
	return nxt


static func clip_for(role: String, slot: String) -> String:
	return str(loadout(role).get(slot, DEFAULT.get(slot, "jab")))


## Damage scale of a move in a slot, against the slot's default move.
static func dmg_mul(slot: String, id: String) -> float:
	var w := float(row(id).get("weight", 0.4))
	var base := float(row(str(DEFAULT.get(slot, "jab"))).get("weight", 0.4))
	return clampf((0.7 + 0.7 * w) / (0.7 + 0.7 * base), 0.6, 2.2)


# --- styles -------------------------------------------------------------------

static func styles(role: String) -> Array:
	var d: Dictionary = FamilyProfile.data.get("styles", {})
	var a: Array = d.get(role, [])
	while a.size() < 3:
		a.append({})
	return a


static func save_style(role: String, idx: int, title: String) -> void:
	var d: Dictionary = FamilyProfile.data.get("styles", {})
	var a: Array = styles(role)
	a[idx] = {"title": title, "loadout": loadout(role)}
	d[role] = a
	FamilyProfile.data["styles"] = d
	FamilyProfile.save()


static func load_style(role: String, idx: int) -> bool:
	var st: Dictionary = styles(role)[idx]
	if st.is_empty():
		return false
	for s in SLOTS:
		set_slot(role, s, str((st.get("loadout", {}) as Dictionary).get(s, DEFAULT[s])))
	return true


# --- combo lab -----------------------------------------------------------------

static func customs(role: String) -> Array:
	return (FamilyProfile.data.get("combos_custom", {}) as Dictionary).get(role, [])


## Finishers that can end a custom combo: any learned heavy or air strike.
static func finishers(role: String) -> Array:
	var out: Array = []
	for r: Dictionary in for_role(role):
		var sl: Array = r.get("slots", [])
		if learned(role, str(r["id"])) and (sl.has("heavy") or sl.has("air")):
			out.append(str(r["id"]))
	return out


## "" if valid, else why not.
static func check(role: String, steps: Array) -> String:
	if steps.size() < 2 or steps.size() > 4:
		return "2 TO 4 INPUTS"
	for c: Dictionary in ComboBook.all_for(role):
		if c.get("steps", []) == steps:
			return "SAME AS %s" % str(c.get("title", ""))
	return ""


static func add_custom(role: String, title: String, steps: Array, clip: String, fx: String) -> String:
	var why := check(role, steps)
	if why != "":
		return why
	if customs(role).size() >= MAX_CUSTOM:
		return "SIX AT MOST"
	var d: Dictionary = FamilyProfile.data.get("combos_custom", {})
	var a: Array = d.get(role, [])
	a.append({
		"id": "custom_%s_%d" % [role, Time.get_ticks_msec()],
		"who": role, "title": title, "steps": steps.duplicate(), "clip": clip,
		"fx": fx, "dmg": 16 + 7 * steps.size() + int(round(14.0 * float(row(clip).get("weight", 0.5)))),
		"box": [80, 56], "reach": 34, "vx": 60, "custom": true, "starter": true,
		"rarity": ["common", "uncommon", "rare"][clampi(steps.size() - 2, 0, 2)],
		"blurb": "Your own line. %s" % " - ".join(steps),
	})
	d[role] = a
	FamilyProfile.data["combos_custom"] = d
	FamilyProfile.save()
	ComboBook.invalidate()
	return ""


static func remove_custom(role: String, id: String) -> void:
	var d: Dictionary = FamilyProfile.data.get("combos_custom", {})
	var a: Array = d.get(role, [])
	for c: Dictionary in a.duplicate():
		if str(c.get("id", "")) == id:
			a.erase(c)
	d[role] = a
	FamilyProfile.data["combos_custom"] = d
	FamilyProfile.save()
	ComboBook.invalidate()
