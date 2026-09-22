class_name KitBook
extends Object

## Unique enemy kits. SoR4 lesson: behavior, not a palette swap.

const PATH := "res://data/kits.json"
const ARMOR_PLATES := {
	"none": 0, "light": 1, "medium": 2, "heavy": 3, "elite": 4, "miniboss": 5
}

static var _table: Dictionary = {}


static func all() -> Dictionary:
	if not _table.is_empty():
		return _table
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_table = parsed
	return _table


static func spec(title: String) -> Dictionary:
	var row: Variant = all().get(title, {})
	if typeof(row) == TYPE_DICTIONARY:
		return row
	return {}


static func plates(grade: String) -> int:
	return int(ARMOR_PLATES.get(grade, 0))


static func apply(p: Punk) -> void:
	var s := spec(p.title)
	if s.is_empty():
		return
	p.kit = s
	p.tier = str(s.get("tier", "light"))
	p.armor_grade = str(s.get("armor", "none"))
	p.attack_style = str(s.get("style", "brawl"))
	p.vehicle = str(s.get("vehicle", ""))
	p.plates = plates(p.armor_grade)
	p.armored = p.plates > 0
	p.speed = float(s.get("speed", p.speed))
	p._walk = p.speed
	if int(s.get("hp", 0)) > 0 and p.hp == p.max_hp:
		p.hp = int(s.get("hp", p.hp))
		p.max_hp = p.hp
	if bool(s.get("cop", false)):
		p.cop = true
	var home := str(s.get("home", ""))
	if home != "":
		p.home = home
