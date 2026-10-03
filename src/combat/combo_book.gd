class_name ComboBook
extends RefCounted

## Dojo combos (data/combos.json) and the per-fighter chain reader.
##
## Every press the fighter makes becomes a token: L light, H heavy, J jump,
## D dash, with the stick as a prefix (F forward / B back relative to where
## the body faced when the chain started, U up, Dn down). The normal move for
## that button plays as always; the reader only remembers the chain. When the
## tokens complete a learned combo, the last press becomes the finisher.
##
## Timing is the point. After each strike reaches its contact frame (or a
## jump / dash starts) a beat ring closes on the fighter. Press the next input
## as it closes: PERFECT. Anywhere else inside the window: GOOD. Wait too long
## and the chain is gone. A finisher whose every beat was perfect hits half
## again as hard and gets the slow-mo.

const PERFECT_AT := 0.18
const PERFECT_TOL := 0.08
const WINDOW := 0.8

static var _data: Dictionary = {}

var role := "son"
var hist: Array = []
var beat_t := -1.0
var grades: Array = []
var ring_t := -1.0
var last_grade := ""


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/combos.json"))
		_data = parsed as Dictionary if parsed is Dictionary else {"combos": [], "styles": {}}
	return _data


static func all_for(who: String) -> Array:
	var out: Array = []
	for c: Dictionary in data().get("combos", []):
		if str(c.get("who", "")) == who:
			out.append(c)
	return out


static func by_id(id: String) -> Dictionary:
	for c: Dictionary in data().get("combos", []):
		if str(c.get("id", "")) == id:
			return c
	return {}


static func style(who: String) -> Dictionary:
	return (data().get("styles", {}) as Dictionary).get(who, {}) as Dictionary


static func learned(who: String) -> Array:
	var out: Array = []
	for c: Dictionary in all_for(who):
		if bool(c.get("starter", false)) or FamilyProfile.dojo_learned(str(c["id"])):
			out.append(c)
	return out


static func is_learned(c: Dictionary) -> bool:
	return bool(c.get("starter", false)) or FamilyProfile.dojo_learned(str(c.get("id", "")))


## Pretty label for one step, e.g. "U+H" -> "↑ + Y" on a pad, "↑ + K" on keys.
static func step_label(tok: String, pad: bool) -> String:
	var parts := tok.split("+")
	var btn := parts[parts.size() - 1]
	var dir := parts[0] if parts.size() > 1 else ""
	var b := ""
	match btn:
		"L":
			b = "X" if pad else "J"
		"H":
			b = "Y" if pad else "K"
		"J":
			b = "A" if pad else "SPACE"
		"D":
			b = "RT" if pad else "SHIFT"
	var d := ""
	match dir:
		"F":
			d = "→ "
		"B":
			d = "← "
		"U":
			d = "↑ "
		"Dn":
			d = "↓ "
	return d + b


static func steps_label(c: Dictionary, pad: bool) -> String:
	var bits: PackedStringArray = []
	for s in c.get("steps", []):
		bits.append(step_label(str(s), pad))
	return "  ›  ".join(bits)


## Does a pressed token satisfy a step? A step without a direction takes a
## neutral or forward stick (players lean in while they punch); a step with
## one needs that direction.
static func fits(step: String, tok: String) -> bool:
	if step == tok:
		return true
	if not step.contains("+"):
		return tok == "F+" + step
	return false


static func _prefix(steps: Array, toks: Array) -> bool:
	if toks.size() > steps.size():
		return false
	for i in toks.size():
		if not fits(str(steps[i]), str(toks[i])):
			return false
	return true


func _init(who: String = "son") -> void:
	role = who


## Grade a press against the current beat. "" when the chain is cold.
func grade_now(now: float) -> String:
	if hist.is_empty() or beat_t < 0.0:
		return ""
	var dt := now - beat_t
	if dt < -0.05:
		return "early"
	if absf(dt - PERFECT_AT) <= PERFECT_TOL:
		return "perfect"
	return "good"


func cold(now: float) -> bool:
	if hist.is_empty():
		return true
	var since := now - maxf(beat_t, float((hist[hist.size() - 1] as Dictionary)["t"]))
	return since > WINDOW


## Feed one press. Returns the combo to finish with (and fills `grades`), or
## an empty dictionary when the normal move should play.
func feed(tok: String, now: float, pool: Array) -> Dictionary:
	if cold(now):
		hist.clear()
		grades.clear()
	var g := grade_now(now)
	var toks: Array = []
	for h: Dictionary in hist:
		toks.append(h["tok"])
	toks.append(tok)
	var live := false
	for c: Dictionary in pool:
		var steps: Array = c.get("steps", [])
		if not _prefix(steps, toks):
			continue
		if toks.size() == steps.size():
			var gs := grades.duplicate()
			if g != "":
				gs.append(g)
			grades = gs
			last_grade = g
			hist.clear()
			beat_t = -1.0
			ring_t = -1.0
			return c
		live = true
	if live:
		hist.append({"tok": tok, "t": now})
		if g != "":
			grades.append(g)
		last_grade = g
		return {}
	# Not part of anything we know from here: maybe it starts a new chain.
	hist.clear()
	grades.clear()
	last_grade = ""
	for c: Dictionary in pool:
		if _prefix(c.get("steps", []), [tok]):
			hist.append({"tok": tok, "t": now})
			break
	return {}


## The strike of the last step reached contact (or a jump / dash began): the
## beat ring for the next press starts now.
func beat(now: float) -> void:
	if hist.is_empty():
		return
	beat_t = now
	ring_t = now


## Which steps of which combos are live right now (for the dojo board and the
## on-body hint): [{combo, next_index}].
func live(pool: Array) -> Array:
	var out: Array = []
	if hist.is_empty():
		return out
	var toks: Array = []
	for h: Dictionary in hist:
		toks.append(h["tok"])
	for c: Dictionary in pool:
		if _prefix(c.get("steps", []), toks):
			out.append({"combo": c, "next": toks.size()})
	return out


func all_perfect() -> bool:
	if grades.is_empty():
		return false
	for g in grades:
		if str(g) != "perfect":
			return false
	return true
