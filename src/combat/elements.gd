class_name Elements
extends RefCounted

## ELEMENT ARTS: four per hero (data/elements.json). LIGHT + HEAVY together
## fires one; the stick picks which (neutral / forward / up / down). Each one
## costs CHI, which fills from hits and kills. Levels 1-5 for gold (damage
## +18% a level, cost -2 a level), then EVOLVE for gems into a stronger form.
## GRABS: LIGHT + HEAVY standing next to a thug (neutral / forward / back).
## TEAM: the TEAM meter fills from kills; hold HEAVY and tap SPECIAL when it
## is full and the other hero comes in for a double attack.

const CHI_MAX := 100.0
const TEAM_MAX := 100.0
const MAX_LV := 5
const EVOLVE_GEMS := 25
const COLORS := {
	"fire": Color(1.0, 0.45, 0.12),
	"storm": Color(0.55, 0.8, 1.0),
	"wind": Color(0.7, 1.0, 0.8),
	"ice": Color(0.6, 0.9, 1.0),
	"earth": Color(0.85, 0.6, 0.3),
}

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/elements.json"))
		_data = parsed if parsed is Dictionary else {"arts": [], "grabs": [], "team": []}
	return _data


static func arts(role: String) -> Array:
	var out: Array = []
	for r: Dictionary in data().get("arts", []):
		if str(r["who"]) == role:
			out.append(r)
	return out


static func grabs(role: String) -> Array:
	var out: Array = []
	for r: Dictionary in data().get("grabs", []):
		if str(r["who"]) == role:
			out.append(r)
	return out


static func team() -> Array:
	return data().get("team", [])


static func art(id: String) -> Dictionary:
	for r: Dictionary in data().get("arts", []):
		if str(r["id"]) == id:
			return r
	return {}


static func art_for(role: String, dir: String) -> Dictionary:
	for r: Dictionary in arts(role):
		if str(r["dir"]) == dir:
			return r
	return {}


static func grab_for(role: String, dir: String) -> Dictionary:
	var fallback: Dictionary = {}
	for r: Dictionary in grabs(role):
		if str(r["dir"]) == dir:
			return r
		if str(r["dir"]) == "N":
			fallback = r
	return fallback


static func color(elem: String) -> Color:
	return COLORS.get(elem, Color.WHITE)


static func _store() -> Dictionary:
	var d: Variant = FamilyProfile.data.get("arts", {})
	return d if d is Dictionary else {}


static func level(id: String) -> int:
	var r := art(id)
	if r.is_empty():
		return 0
	var lv := int(_store().get(id, 0))
	if lv == 0 and int(r.get("gold", 0)) == 0:
		lv = 1
	return lv


static func owned(id: String) -> bool:
	return level(id) > 0


static func evolved(id: String) -> bool:
	var ev: Variant = _store().get("evolved", {})
	return ev is Dictionary and bool((ev as Dictionary).get(id, false))


static func title(id: String) -> String:
	var r := art(id)
	return str(r.get("evo", r.get("title", id))) if evolved(id) else str(r.get("title", id))


static func cost(id: String) -> float:
	return maxf(20.0, float(art(id).get("cost", 40)) - 2.0 * float(maxi(0, level(id) - 1)))


static func dmg(id: String) -> int:
	var base := float(art(id).get("dmg", 20))
	var k := 1.0 + 0.18 * float(maxi(0, level(id) - 1))
	if evolved(id):
		k *= 1.5
	return int(round(base * k))


## Gold to unlock (level 0) or to take the next level; -1 at the cap.
static func next_price(id: String) -> int:
	var lv := level(id)
	if lv == 0:
		return int(art(id).get("gold", 600))
	if lv >= MAX_LV:
		return -1
	return 250 * lv + 150


static func can_evolve(id: String) -> bool:
	return level(id) >= MAX_LV and not evolved(id)


static func buy(id: String) -> bool:
	var price := next_price(id)
	if price < 0 or int(FamilyProfile.data.get("gold", 0)) < price:
		return false
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - price
	var s := _store()
	s[id] = level(id) + 1
	FamilyProfile.data["arts"] = s
	FamilyProfile.save()
	return true


static func evolve(id: String) -> bool:
	if not can_evolve(id) or int(FamilyProfile.data.get("gems", 0)) < EVOLVE_GEMS:
		return false
	FamilyProfile.data["gems"] = int(FamilyProfile.data.get("gems", 0)) - EVOLVE_GEMS
	var s := _store()
	var ev: Dictionary = s.get("evolved", {}) if s.get("evolved") is Dictionary else {}
	ev[id] = true
	s["evolved"] = ev
	FamilyProfile.data["arts"] = s
	FamilyProfile.save()
	return true


## CHI from a hit (light ones count less) and from a kill. Charms and the
## brawl tree can add to it later; one place to tune.
static func chi_for_hit(kind: String) -> float:
	if kind == "light" or kind == "jab" or kind == "cross":
		return 1.5
	if kind == "combo" or kind == "finish":
		return 0.0
	return 3.0


const CHI_KILL := 12.0
const TEAM_KILL := 6.0
const TEAM_ASSIST := 3.0
