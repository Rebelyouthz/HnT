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


## How far the muzzle moves out (gun sprite px) with a can or a long barrel.
static func muzzle_ext(gun: String) -> float:
	var x := 0.0
	for p: Dictionary in layout(gun):
		if str(p["mount"]) == "muzzle":
			var mz: Array = _gun_meta(gun_sprite(gun)).get("muzzle", [0, 0])
			x = maxf(x, (p["pos"] as Vector2).x + (p["size"] as Vector2).x - float(mz[0]))
	return x


# --- how the parts look (tools/gun_parts.py) ---------------------------------

static var _parts_meta := {}
static var _guns_meta := {}


static func part_meta(a: String) -> Dictionary:
	if _parts_meta.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/guns/parts/parts.json"))
		if d is Dictionary:
			_parts_meta = d
	return _parts_meta.get(a, {}) as Dictionary


static func _gun_meta(sprite: String) -> Dictionary:
	if _guns_meta.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/guns/guns.json"))
		if d is Dictionary:
			_guns_meta = d
	return _guns_meta.get(sprite, {}) as Dictionary


## The sprite a weapon id draws with (assets/sprites/guns/<name>.png).
static func gun_sprite(gun: String) -> String:
	return gun if ResourceLoader.exists("res://assets/sprites/guns/%s.png" % gun) else "pistol"


static func part_tex(a: String) -> Texture2D:
	var p := "res://assets/sprites/guns/parts/%s.png" % a
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


## Where every fitted part sits on the gun sprite: [{id, mount, pos (top-left,
## sprite px), size, tex}]. `fitted` overrides what is on (slot -> part) so
## menus can preview a part before it is bought.
static func layout(gun: String, fitted: Variant = null) -> Array:
	var on_: Dictionary = {}
	if fitted is Dictionary:
		on_ = fitted
	else:
		for slot in SLOTS:
			var a := on(gun, slot)
			if a != "" and slot_open(gun, slot):
				on_[slot] = a
	var gm := _gun_meta(gun_sprite(gun))
	var mz: Array = gm.get("muzzle", [28, 5])
	var out: Array = []
	# The barrel first: a muzzle device sits at the end of a long barrel.
	var muzzle := Vector2(float(mz[0]) - 2.0, float(mz[1]))
	for slot in ["barrel", "muzzle", "optic", "mag", "ammo"]:
		var a := str(on_.get(slot, ""))
		var pm := part_meta(a)
		if a == "" or pm.is_empty():
			continue
		var mount := str(pm["mount"])
		var at: Vector2
		if mount == "muzzle":
			at = muzzle
		else:
			var m: Array = gm.get(mount, mz)
			at = Vector2(float(m[0]), float(m[1]))
		var anc: Array = pm["anchor"]
		var sz: Array = pm["size"]
		var pos := at - Vector2(float(anc[0]), float(anc[1]))
		out.append({"id": a, "slot": slot, "mount": mount, "pos": pos, "size": Vector2(float(sz[0]), float(sz[1])), "tex": part_tex(a), "at": at})
		if slot == "barrel" and a == "long_barrel":
			muzzle.x += float(sz[0]) - 4.0
	return out


## Parts drawn on the held gun sprite (its texels), plus the laser line
## shown while aiming.
static func dress(gun_sprite_node: Sprite2D, gun: String, muzzle: Vector2, _grip: Vector2) -> void:
	for c in gun_sprite_node.get_children():
		if c.has_meta("attach"):
			c.queue_free()
	for p: Dictionary in layout(gun):
		if p["tex"] == null:
			continue
		var s := Sprite2D.new()
		s.set_meta("attach", true)
		s.texture = p["tex"]
		s.centered = false
		s.position = p["pos"]
		s.texture_filter = gun_sprite_node.texture_filter
		s.z_index = -1 if str(p["mount"]) == "mag" else 0
		s.z_as_relative = true
		gun_sprite_node.add_child(s)
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
		gun_sprite_node.add_child(l)
