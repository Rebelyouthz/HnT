class_name GearInv
extends RefCounted

## Gear copies by rarity. Every gear piece can exist at any rarity from its
## base up to legendary; three identical pieces at one rarity COMBINE into
## one at the next. The best copy owned is the one worn. Rarity raises the
## stats (x1.35 a step above base) and the level cap (common 3, +2 a step).

const STEP_MUL := 0.35


static func _all() -> Dictionary:
	var inv: Variant = FamilyProfile.data.get("gear_inv", null)
	if typeof(inv) != TYPE_DICTIONARY:
		inv = {}
		for id in (FamilyProfile.data.get("owned_gear", []) as Array):
			inv[str(id)] = _fresh(str(id), 1)
		FamilyProfile.data["gear_inv"] = inv
	return inv


static func _fresh(id: String, n: int) -> Array:
	var a := [0, 0, 0, 0, 0]
	a[base_tier(id)] = n
	return a


static func counts(id: String) -> Array:
	var inv := _all()
	if not inv.has(id):
		return [0, 0, 0, 0, 0]
	return inv[id]


static func base_tier(id: String) -> int:
	return maxi(0, Rarity.rank(str(GearBook.item(id).get("rarity", "common"))))


## Best rarity owned (-1: none).
static func tier(id: String) -> int:
	var c := counts(id)
	for t in range(4, -1, -1):
		if int(c[t]) > 0:
			return t
	return -1


static func tier_name(id: String) -> String:
	return Rarity.ORDER[maxi(0, tier(id))]


static func add(id: String, t: int = -1, n: int = 1) -> void:
	if GearBook.item(id).is_empty():
		return
	var inv := _all()
	var c: Array = inv.get(id, [0, 0, 0, 0, 0])
	var tt := base_tier(id) if t < 0 else clampi(t, base_tier(id), 4)
	c[tt] = int(c[tt]) + n
	inv[id] = c
	var owned: Array = FamilyProfile.data.get("owned_gear", [])
	if not owned.has(id):
		owned.append(id)
		FamilyProfile.data["owned_gear"] = owned


## Lowest rarity that has three copies to merge (-1: none).
static func combinable(id: String) -> int:
	var c := counts(id)
	for t in 4:
		if int(c[t]) >= 3:
			return t
	return -1


static func combine(id: String) -> bool:
	var t := combinable(id)
	if t < 0:
		return false
	var c: Array = counts(id)
	c[t] = int(c[t]) - 3
	c[t + 1] = int(c[t + 1]) + 1
	_all()[id] = c
	FamilyProfile.data["gear_combines"] = int(FamilyProfile.data.get("gear_combines", 0)) + 1
	FamilyProfile.save()
	var title := str(GearBook.item(id).get("title", GearBook.item(id).get("name", id)))
	Juice.unlock_logo("%s  ·  %s" % [title.to_upper(), Rarity.ORDER[t + 1].to_upper()], "Three became one. Stronger, and the level cap went up.", "GEAR COMBINED")
	Rarity.juice(Rarity.ORDER[t + 1], title)
	return true


static func level_cap(id: String) -> int:
	return 3 + 2 * maxi(0, tier(id))


static func stat_mul(id: String) -> float:
	return 1.0 + STEP_MUL * float(maxi(0, tier(id) - base_tier(id)))


## A random piece for a drop: commoner bases more often; a small chance it
## comes one rarity up.
static func roll_drop() -> Dictionary:
	var pool: Array = []
	for row in GearBook.items():
		var id := str((row as Dictionary).get("id", ""))
		var w: int = [10, 6, 3, 2, 1][base_tier(id)]
		for i in w:
			pool.append(id)
	if pool.is_empty():
		return {}
	var id: String = pool[randi() % pool.size()]
	var t := base_tier(id)
	if t < 4 and randf() < 0.1:
		t += 1
	return {"id": id, "tier": t}
