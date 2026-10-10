class_name Arsenal
extends RefCounted

## Lifetime weapon records: which weapons you have held, kills with each,
## mastery (MASTERY_KILLS kills = +15% damage with it) and how long a melee
## weapon lasts before it breaks.

const MASTERY_KILLS := 25
const MASTERY_BONUS := 0.15
## Landed hits before a melee weapon breaks (wood splinters, metal bends).
const USES := {
	"board": 10, "baseball_bat": 18, "pipe": 22, "crowbar": 26, "chain": 20, "knife": 24,
	"machete": 18, "sledgehammer": 12, "clipboard": 8, "stapler": 10, "can": 4, "envelope": 6,
}
const WOOD := ["board", "baseball_bat", "clipboard"]


static func found(id: String) -> bool:
	return (FamilyProfile.data.get("weapons_found", []) as Array).has(id)


static func mark_found(id: String) -> void:
	if id == "" or found(id) or WeaponBook.spec(id).is_empty():
		return
	var a: Array = FamilyProfile.data.get("weapons_found", [])
	a.append(id)
	FamilyProfile.data["weapons_found"] = a
	FamilyProfile.flag_unseen("armory")
	Discover.see("weapon", id, str(WeaponBook.spec(id).get("title", id)).to_upper())


static func kills(id: String) -> int:
	return int((FamilyProfile.data.get("weapon_kills", {}) as Dictionary).get(id, 0))


static func mastered(id: String) -> bool:
	return kills(id) >= MASTERY_KILLS


static func add_kill(id: String) -> void:
	if id == "" or WeaponBook.spec(id).is_empty():
		return
	var d: Dictionary = FamilyProfile.data.get("weapon_kills", {})
	var n := int(d.get(id, 0)) + 1
	d[id] = n
	FamilyProfile.data["weapon_kills"] = d
	var run: Dictionary = Engine.get_meta("run_weapon_kills", {})
	run[id] = int(run.get(id, 0)) + 1
	Engine.set_meta("run_weapon_kills", run)
	if n == MASTERY_KILLS:
		var t := str(WeaponBook.spec(id).get("title", id)).to_upper()
		Juice.unlock_logo("MASTERED: " + t, "+15% damage with it, for good.", "WEAPON MASTERY  ·  ARMORY")


static func dmg_mul(id: String) -> float:
	return 1.0 + (MASTERY_BONUS if mastered(id) else 0.0)


static func uses(id: String) -> int:
	var n := float(USES.get(id, 16)) * (1.0 + 0.15 * float(level(id) - 1))
	if has_mod(id, "tape_grip"):
		n *= 1.6
	return int(round(n))


## The weapon used most in the current run ("" if none).
static func run_best() -> String:
	var run: Dictionary = Engine.get_meta("run_weapon_kills", {})
	var best := ""
	var n := 0
	for k in run:
		if int(run[k]) > n:
			n = int(run[k])
			best = str(k)
	return best


static func reset_run() -> void:
	Engine.set_meta("run_weapon_kills", {})
	Engine.set_meta("run_shards", 0)
	Engine.set_meta("run_tokens", 0)


static func bump(key: String, n: int = 1) -> void:
	FamilyProfile.data[key] = int(FamilyProfile.data.get(key, 0)) + n


# --- weapon levels and mods ----------------------------------------------------

const MAX_LV := 5
## One slot, two from level 3. Mods are bought once (gems) and fitted to any
## weapon of their kind.
const MODS := {
	"nails": {"for": "melee", "title": "NAILS", "line": "Every hit leaves it bleeding (3 ticks).", "gems": 2},
	"tape_grip": {"for": "melee", "title": "TAPE GRIP", "line": "+60% hits before it breaks.", "gems": 1},
	"weighted": {"for": "melee", "title": "WEIGHTED", "line": "+25% damage with it.", "gems": 2},
	"serrated": {"for": "melee", "title": "SERRATED", "line": "15% chance to crit for double.", "gems": 2},
	"live_wire": {"for": "melee", "title": "LIVE WIRE", "line": "20% chance to stun for a second.", "gems": 3},
}


static func is_gun(id: String) -> bool:
	return WeaponBook.spec(id).has("gun")


static func level(id: String) -> int:
	return int((FamilyProfile.data.get("weapon_lv", {}) as Dictionary).get(id, 1))


static func level_cost(id: String) -> int:
	var base := 60 if is_gun(id) else 40
	return int(round(float(base) * pow(1.7, float(level(id) - 1))))


static func try_level(id: String) -> bool:
	if not found(id) or level(id) >= MAX_LV:
		return false
	var c := level_cost(id)
	if int(FamilyProfile.data.get("gold", 0)) < c:
		return false
	FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - c
	var d: Dictionary = FamilyProfile.data.get("weapon_lv", {})
	d[id] = level(id) + 1
	FamilyProfile.data["weapon_lv"] = d
	FamilyProfile.save()
	return true


static func slots(id: String) -> int:
	return 2 if level(id) >= 3 else 1


static func mods_on(id: String) -> Array:
	return (FamilyProfile.data.get("weapon_mods", {}) as Dictionary).get(id, [])


static func has_mod(id: String, mod: String) -> bool:
	if id != "" and is_gun(id):
		return Attach.has(id, mod)
	return id != "" and mods_on(id).has(mod)


static func mod_owned(mod: String) -> bool:
	return (FamilyProfile.data.get("mods_owned", []) as Array).has(mod)


static func buy_mod(mod: String) -> bool:
	if mod_owned(mod) or not MODS.has(mod):
		return false
	var g := int(MODS[mod]["gems"])
	if int(FamilyProfile.data.get("gems", 0)) < g:
		return false
	FamilyProfile.data["gems"] = int(FamilyProfile.data["gems"]) - g
	var a: Array = FamilyProfile.data.get("mods_owned", [])
	a.append(mod)
	FamilyProfile.data["mods_owned"] = a
	FamilyProfile.save()
	return true


## Fit or remove a mod (toggle). Returns false if it does not fit.
static func toggle_mod(id: String, mod: String) -> bool:
	var spec: Dictionary = MODS.get(mod, {})
	if spec.is_empty() or not mod_owned(mod):
		return false
	if str(spec["for"]) != ("gun" if is_gun(id) else "melee"):
		return false
	var d: Dictionary = FamilyProfile.data.get("weapon_mods", {})
	var on: Array = d.get(id, [])
	if on.has(mod):
		on.erase(mod)
	elif on.size() < slots(id):
		on.append(mod)
	else:
		return false
	d[id] = on
	FamilyProfile.data["weapon_mods"] = d
	FamilyProfile.save()
	return true


## Everything that scales a weapon's damage: level, mastery, WEIGHTED.
static func power_mul(id: String) -> float:
	var m := dmg_mul(id) * (1.0 + 0.12 * float(level(id) - 1))
	if has_mod(id, "weighted"):
		m *= 1.25
	return m


static func clip_mul(id: String) -> float:
	return Attach.clip_mul(id) * (1.0 + 0.1 * float(level(id) - 1))


static func reload_mul(id: String) -> float:
	return Attach.reload_mul(id)


## On-hit mod effects, called by Punk.take_hit after the blow lands.
## Returns the extra damage dealt (crits).
static func on_hit(id: String, p: Punk, dmg: int) -> int:
	if id == "" or p == null or p.hp <= 0:
		return 0
	var extra := 0
	if has_mod(id, "nails"):
		p.staples = maxi(p.staples, 3)
	if (has_mod(id, "serrated") and randf() < 0.15) or (has_mod(id, "laser") and randf() < 0.2):
		extra = dmg
		Juice.popup_number(p.global_position + Vector2(0, -104), "CRIT", Color(1.0, 0.85, 0.2))
	if has_mod(id, "live_wire") and randf() < 0.2:
		p.snared = maxf(p.snared, 1.0)
		Juice.sparks(p.global_position + Vector2(0, -40))
		Juice.popup_number(p.global_position + Vector2(0, -90), "ZAP", Color(0.6, 0.85, 1.0))
	if has_mod(id, "incendiary") and randf() < 0.25:
		p.ignite(3.0, "flare_gun")
	if has_mod(id, "hollow") and not p.armored:
		extra += int(round(float(dmg) * 0.3))
	if is_gun(id):
		if Attach.has(id, "rubber"):
			p.recover = maxf(p.recover, 1.0)
		if Attach.has(id, "ap_rounds") and p.plates > 0:
			p.plates = 0
			p.armored = false
			Juice.popup_number(p.global_position + Vector2(0, -96), "AP", Color(0.9, 0.9, 1.0))
		if Attach.has(id, "scope") and float(p._shot.get("dist", 0.0)) > 180.0:
			extra += int(round(float(dmg) * 0.5))
		if Attach.has(id, "suppressor") and p.telegraph <= 0.0:
			extra += int(round(float(dmg) * 0.35))
	return extra
