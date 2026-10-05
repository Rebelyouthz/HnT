class_name Attach
extends RefCounted

## Gun attachments, Gunsmith style: every gun has five slots and each holds
## one part. Parts are bought once (gems) and fit any gun; slots open with
## the gun's level. The old gun mods (EXTENDED MAG, HOLLOW POINTS, LASER,
## QUICK LOADER, INCENDIARY) carry over as owned parts.
##   MUZZLE  suppressor / compensator              (LV 1)
##   AMMO    hollow / incendiary / armor piercing / rubber   (LV 1)
##   OPTIC   red dot / laser / scope               (LV 2)
##   MAG     extended / drum / quick loader        (LV 3)
##   BARREL  long / sawn-off                       (LV 4)

const SLOTS := ["muzzle", "optic", "barrel", "mag", "ammo"]
const SLOT_LV := {"muzzle": 1, "ammo": 1, "optic": 2, "mag": 3, "barrel": 4}
const SLOT_NAME := {"muzzle": "MUZZLE", "optic": "OPTIC", "barrel": "BARREL", "mag": "MAGAZINE", "ammo": "AMMO"}
const LIST := {
	"suppressor": {"slot": "muzzle", "title": "SUPPRESSOR", "line": "Quiet shots: +35% damage on a thug who is not swinging at you, no muzzle blast. -10% range.", "gems": 2},
	"compensator": {"slot": "muzzle", "title": "COMPENSATOR", "line": "Half the recoil and half the spread.", "gems": 1},
	"red_dot": {"slot": "optic", "title": "RED DOT", "line": "Chest shots climb to the head one time in four.", "gems": 1},
	"laser": {"slot": "optic", "title": "LASER SIGHT", "line": "20% chance to crit for double. A red line shows the shot.", "gems": 2},
	"scope": {"slot": "optic", "title": "SCOPE", "line": "+50% damage at range (past 180).", "gems": 2},
	"long_barrel": {"slot": "barrel", "title": "LONG BARREL", "line": "+20% damage and +40% range, fires 10% slower.", "gems": 2},
	"short_barrel": {"slot": "barrel", "title": "SAWN-OFF", "line": "Fires 25% faster, wider spread, -10% damage.", "gems": 1},
	"ext_mag": {"slot": "mag", "title": "EXTENDED MAG", "line": "+50% rounds per magazine.", "gems": 2},
	"drum_mag": {"slot": "mag", "title": "DRUM MAG", "line": "Double the magazine, reloads 40% slower.", "gems": 3},
	"quick_loader": {"slot": "mag", "title": "QUICK LOADER", "line": "Reloads 40% faster.", "gems": 1},
	"hollow": {"slot": "ammo", "title": "HOLLOW POINTS", "line": "+30% damage to anyone without armor.", "gems": 2},
	"incendiary": {"slot": "ammo", "title": "INCENDIARY", "line": "25% chance to set them on fire.", "gems": 3},
	"ap_rounds": {"slot": "ammo", "title": "ARMOR PIERCING", "line": "Through vests and plates, and one more body.", "gems": 2},
	"rubber": {"slot": "ammo", "title": "RUBBER ROUNDS", "line": "-40% damage, every hit stuns, one spare magazine more.", "gems": 1},
}
const LEGACY := ["ext_mag", "hollow", "laser", "quick_loader", "incendiary"]


static func owned(a: String) -> bool:
	if (FamilyProfile.data.get("attach_owned", []) as Array).has(a):
		return true
	return LEGACY.has(a) and (FamilyProfile.data.get("mods_owned", []) as Array).has(a)


static func buy(a: String) -> bool:
	if owned(a) or not LIST.has(a):
		return false
	var g := int(LIST[a]["gems"])
	if int(FamilyProfile.data.get("gems", 0)) < g:
		return false
	FamilyProfile.data["gems"] = int(FamilyProfile.data["gems"]) - g
	var arr: Array = FamilyProfile.data.get("attach_owned", [])
	arr.append(a)
	FamilyProfile.data["attach_owned"] = arr
	FamilyProfile.save()
	return true


static func slot_open(gun: String, slot: String) -> bool:
	return Arsenal.level(gun) >= int(SLOT_LV.get(slot, 9))


static func _fitted(gun: String) -> Dictionary:
	var d: Dictionary = FamilyProfile.data.get("attach_on", {})
	if d.has(gun):
		return d[gun]
	# First look at a gun from before attachments: its old mods move over.
	var out := {}
	for m in (FamilyProfile.data.get("weapon_mods", {}) as Dictionary).get(gun, []):
		if LIST.has(str(m)):
			out[str(LIST[str(m)]["slot"])] = str(m)
	return out


static func on(gun: String, slot: String) -> String:
	if gun == "":
		return ""
	return str(_fitted(gun).get(slot, ""))


static func has(gun: String, a: String) -> bool:
	if gun == "" or not LIST.has(a):
		return false
	var slot := str(LIST[a]["slot"])
	return on(gun, slot) == a and slot_open(gun, slot)


## Fit a part (or take it off when it is already on). False if not allowed.
static func fit(gun: String, a: String) -> bool:
	if not LIST.has(a) or not owned(a):
		return false
	var slot := str(LIST[a]["slot"])
	if not slot_open(gun, slot):
		return false
	var d: Dictionary = FamilyProfile.data.get("attach_on", {})
	var f := _fitted(gun).duplicate()
	if str(f.get(slot, "")) == a:
		f.erase(slot)
	else:
		f[slot] = a
	d[gun] = f
	FamilyProfile.data["attach_on"] = d
	FamilyProfile.save()
	return true


# --- what the parts do (read by Fighter._fire_gun and Arsenal) ---------------

static func dmg_mul(gun: String) -> float:
	var m := 1.0
	if has(gun, "long_barrel"):
		m *= 1.2
	if has(gun, "short_barrel"):
		m *= 0.9
	if has(gun, "rubber"):
		m *= 0.6
	return m


static func rate_mul(gun: String) -> float:
	return (1.1 if has(gun, "long_barrel") else 1.0) * (0.75 if has(gun, "short_barrel") else 1.0)


static func spread_mul(gun: String) -> float:
	return (0.5 if has(gun, "compensator") else 1.0) * (1.5 if has(gun, "short_barrel") else 1.0)


static func recoil_mul(gun: String) -> float:
	return 0.5 if has(gun, "compensator") else 1.0


static func range_mul(gun: String) -> float:
	return (1.4 if has(gun, "long_barrel") else 1.0) * (0.9 if has(gun, "suppressor") else 1.0)


static func clip_mul(gun: String) -> float:
	return 2.0 if has(gun, "drum_mag") else (1.5 if has(gun, "ext_mag") else 1.0)


static func reload_mul(gun: String) -> float:
	return 1.4 if has(gun, "drum_mag") else (0.6 if has(gun, "quick_loader") else 1.0)


static func spare_mags(gun: String) -> int:
	return 1 if has(gun, "rubber") else 0


## How far the muzzle moves out (gun texels) with a can or a long barrel.
static func muzzle_ext(gun: String) -> float:
	return (16.0 if has(gun, "suppressor") else 0.0) + (10.0 if has(gun, "long_barrel") else 0.0)


## Parts drawn on the gun sprite, in its texels: a can on the muzzle, a
## scope or red dot on top, a drum under the grip, a longer barrel, and the
## laser line (shown while aiming).
static func dress(gun_sprite: Sprite2D, gun: String, muzzle: Vector2, grip: Vector2) -> void:
	for c in gun_sprite.get_children():
		if c.has_meta("attach"):
			c.queue_free()
	var x := muzzle.x
	if has(gun, "long_barrel"):
		_part(gun_sprite, [Vector2(x - 2, muzzle.y - 2), Vector2(x + 10, muzzle.y - 2), Vector2(x + 10, muzzle.y + 2), Vector2(x - 2, muzzle.y + 2)], Color(0.2, 0.2, 0.22))
		x += 10.0
	if has(gun, "suppressor"):
		_part(gun_sprite, [Vector2(x - 1, muzzle.y - 4), Vector2(x + 16, muzzle.y - 4), Vector2(x + 16, muzzle.y + 4), Vector2(x - 1, muzzle.y + 4)], Color(0.1, 0.1, 0.12))
		_part(gun_sprite, [Vector2(x + 2, muzzle.y - 4), Vector2(x + 14, muzzle.y - 4), Vector2(x + 14, muzzle.y - 3), Vector2(x + 2, muzzle.y - 3)], Color(0.4, 0.42, 0.46))
	var top := muzzle.y - 6.0
	var mid := (grip.x + muzzle.x) * 0.5
	if has(gun, "scope"):
		_part(gun_sprite, [Vector2(mid - 10, top - 6), Vector2(mid + 10, top - 6), Vector2(mid + 10, top), Vector2(mid - 10, top)], Color(0.12, 0.12, 0.14))
		_part(gun_sprite, [Vector2(mid + 8, top - 5), Vector2(mid + 11, top - 5), Vector2(mid + 11, top - 1), Vector2(mid + 8, top - 1)], Color(0.4, 0.75, 1.0))
	elif has(gun, "red_dot"):
		_part(gun_sprite, [Vector2(mid - 4, top - 5), Vector2(mid + 4, top - 5), Vector2(mid + 4, top), Vector2(mid - 4, top)], Color(0.15, 0.15, 0.17))
		_part(gun_sprite, [Vector2(mid, top - 4), Vector2(mid + 2, top - 4), Vector2(mid + 2, top - 2), Vector2(mid, top - 2)], Color(1.0, 0.2, 0.2))
	if has(gun, "drum_mag"):
		var pts: Array = []
		for k in 14:
			var ang := TAU * float(k) / 14.0
			pts.append(Vector2(grip.x + 8.0, grip.y + 2.0) + Vector2(cos(ang), sin(ang)) * 7.0)
		_part(gun_sprite, pts, Color(0.16, 0.16, 0.18))
	elif has(gun, "ext_mag"):
		_part(gun_sprite, [Vector2(grip.x + 2, grip.y), Vector2(grip.x + 9, grip.y), Vector2(grip.x + 9, grip.y + 12), Vector2(grip.x + 2, grip.y + 12)], Color(0.14, 0.14, 0.16))
	if has(gun, "laser"):
		var l := Line2D.new()
		l.set_meta("attach", true)
		l.name = "Laser"
		l.points = PackedVector2Array([Vector2(muzzle.x, muzzle.y + 3), Vector2(muzzle.x + 900.0, muzzle.y + 3)])
		l.width = 1.0
		l.default_color = Color(1.0, 0.1, 0.1, 0.55)
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		l.material = m
		gun_sprite.add_child(l)


static func _part(host: Node2D, pts: Array, col: Color) -> void:
	var p := Polygon2D.new()
	p.set_meta("attach", true)
	p.polygon = PackedVector2Array(pts)
	p.color = col
	host.add_child(p)
