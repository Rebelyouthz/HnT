class_name SurviveRun
extends Node

## The build of one coping hour (data/survive.json): its own XP and levels
## (many of them, Halls of Torment pace), the abilities owned and their
## levels, stacked traits and up to four items. Every level-up pauses for a
## pick of three (reroll x2, banish x1). Stats are read live by the
## abilities and the fighters.

signal changed

const MAX_ABILITIES := 6
const MAX_ITEMS := 4
const MAX_LV := 7

var book: Dictionary = {}
var xp := 0
var level := 1
var abilities: Dictionary = {}   # id -> level
var traits: Dictionary = {}      # id -> stacks
var items: Array = []            # item rows
var rerolls := 2
var banishes := 1
var banned: Array = []
var kills := 0
var frenzy_t := 0.0
var _pending := 0
var _picking := false
var _regen_acc := 0.0


static func get_run(tree: SceneTree) -> SurviveRun:
	return tree.get_first_node_in_group("survive_run") as SurviveRun if tree else null


func _ready() -> void:
	add_to_group("survive_run")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
	book = parsed if parsed is Dictionary else {}
	# Everyone starts the hour with one ability: the Son's paper, the
	# Father's coffee (solo picks by role).
	var start := "invoice_toss" if App.solo_role == "son" else "coffee"
	call_deferred("_grant", start)
	# A carried item from the Lost & Found well.
	call_deferred("_offer_stash")


func _grant(id: String) -> void:
	abilities[id] = 1
	_mount(id)
	changed.emit()


func row(kind: String, id: String) -> Dictionary:
	for r: Dictionary in book.get(kind, []):
		if str(r.get("id", "")) == id:
			return r
	return {}


# --- stats ---------------------------------------------------------------------

func _item_mod(key: String) -> float:
	var v := 0.0
	for it: Dictionary in items:
		v += float((it.get("mods", {}) as Dictionary).get(key, 0.0))
	return v


func trait_n(id: String) -> int:
	return int(traits.get(id, 0))


func dmg_mul() -> float:
	return 1.0 + 0.12 * trait_n("t_dmg") + _item_mod("dmg")


func area_mul() -> float:
	return 1.0 + 0.14 * trait_n("t_area") + _item_mod("area")


func cd_mul() -> float:
	var m := maxf(0.35, 1.0 - 0.08 * trait_n("t_cd") - _item_mod("cd"))
	return m * (0.5 if frenzy_t > 0.0 else 1.0)


func proj_bonus() -> int:
	return trait_n("t_proj") + int(_item_mod("proj"))


func crit() -> float:
	return 0.06 * trait_n("t_crit") + _item_mod("crit")


func speed_mul() -> float:
	return 1.0 + 0.07 * trait_n("t_speed") + _item_mod("speed")


func armor() -> float:
	return minf(0.6, 0.07 * trait_n("t_armor"))


func pickup_mul() -> float:
	return 1.0 + 0.3 * trait_n("t_pickup") + _item_mod("pickup")


func slow() -> float:
	return _item_mod("slow")


## Damage of one hit of an ability at its level, with crit rolled.
func hit(id: String) -> Dictionary:
	var r := row("abilities", id)
	var lv := int(abilities.get(id, 1))
	var d := (float(r.get("dmg", 6)) + float(r.get("per", 1)) * float(lv - 1)) * dmg_mul()
	var c := randf() < crit()
	if c:
		d *= 2.0
	return {"dmg": int(round(d)), "crit": c}


func proj_count(id: String) -> int:
	var r := row("abilities", id)
	var lv := int(abilities.get(id, 1))
	var n := int(r.get("proj", 1))
	for at in r.get("proj_at", []):
		if lv >= int(at):
			n += 1
	if int(r.get("proj", 0)) > 0:
		n += proj_bonus()
	return n


# --- xp / levels ---------------------------------------------------------------

func need() -> int:
	var c: Dictionary = book.get("xp_curve", {})
	return int(round(float(c.get("base", 14)) * pow(float(c.get("growth", 1.22)), float(level - 1))))


func add_xp(n: int) -> void:
	n = int(ceil(float(n) * (1.0 + 0.12 * trait_n("t_xp"))))
	xp += n
	while xp >= need():
		xp -= need()
		level += 1
		_pending += 1
		var heal := _item_mod("lvl_heal")
		for f in _fighters():
			if heal > 0.0:
				f.hp = mini(f.max_hp, f.hp + int(ceil(float(f.max_hp) * heal)))
		if _item_mod("frenzy") > 0.0:
			frenzy_t = _item_mod("frenzy")
		Juice.shout("LEVEL %d" % level)
		Mixer.play_sfx("res://assets/audio/sfx/perfect_sting.ogg" if ResourceLoader.exists("res://assets/audio/sfx/perfect_sting.ogg") else "res://assets/audio/card.wav", 1.2, -4.0)
	changed.emit()
	if _pending > 0 and not _picking:
		call_deferred("_next_pick")


## Damage numbers for ability hits (small, so the hour reads like HoT).
func note_hit(e: Node, dmg: int) -> void:
	if e is Node2D and randf() < 0.45:
		Juice.popup_number((e as Node2D).global_position + Vector2(randf_range(-8, 8), -48), str(dmg), Color(1, 1, 1, 0.8))


func note_kill() -> void:
	kills += 1
	var kh := int(_item_mod("kill_heal"))
	if kh > 0:
		for f in _fighters():
			f.hp = mini(f.max_hp, f.hp + kh)


func _process(delta: float) -> void:
	frenzy_t = maxf(0.0, frenzy_t - delta)
	var rg := 0.6 * trait_n("t_regen")
	if rg > 0.0:
		_regen_acc += rg * delta
		if _regen_acc >= 1.0:
			var whole := int(_regen_acc)
			_regen_acc -= float(whole)
			for f in _fighters():
				if not f.downed:
					f.hp = mini(f.max_hp, f.hp + whole)


func _fighters() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			out.append(n as Fighter)
	return out


# --- picks ---------------------------------------------------------------------

## Three offers: owned abilities to level, new abilities while slots are
## free, traits not maxed. Weighted toward levelling what you have.
func offers(n: int = 3) -> Array:
	var pool: Array = []
	for r: Dictionary in book.get("abilities", []):
		var id := str(r["id"])
		if id in banned:
			continue
		if abilities.has(id):
			if int(abilities[id]) < MAX_LV:
				pool.append({"kind": "ability", "id": id, "w": 3.0})
		elif abilities.size() < MAX_ABILITIES:
			pool.append({"kind": "ability", "id": id, "w": 1.6})
	for r: Dictionary in book.get("traits", []):
		var id := str(r["id"])
		if id in banned:
			continue
		if trait_n(id) < int(r.get("max", 5)):
			pool.append({"kind": "trait", "id": id, "w": 1.2})
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for p: Dictionary in pool:
			total += float(p["w"])
		var roll := randf() * total
		for i in pool.size():
			roll -= float(pool[i]["w"])
			if roll <= 0.0:
				out.append(pool[i])
				pool.remove_at(i)
				break
	if out.is_empty():
		out.append({"kind": "gold", "id": "gold"})
	return out


func take(o: Dictionary) -> void:
	match str(o.get("kind", "")):
		"ability":
			var id := str(o["id"])
			var was := abilities.has(id)
			abilities[id] = int(abilities.get(id, 0)) + 1
			if not was:
				_mount(id)
		"trait":
			var id := str(o["id"])
			traits[id] = trait_n(id) + 1
			if id == "t_hp":
				for f in _fighters():
					f.max_hp += 12
					f.hp += 12
		"item":
			if items.size() < MAX_ITEMS:
				items.append(o["row"])
			else:
				items[randi() % MAX_ITEMS] = o["row"]
			var hp := int(((o["row"] as Dictionary).get("mods", {}) as Dictionary).get("hp", 0))
			for f in _fighters():
				f.max_hp += hp
				f.hp += hp
		"gold":
			FamilyProfile.add_gold(10)
	changed.emit()


func _mount(id: String) -> void:
	for f in _fighters():
		if f.get_node_or_null("Skill_" + id) == null:
			var a := SurviveAbility.new()
			a.name = "Skill_" + id
			a.id = id
			f.add_child(a)


func _next_pick() -> void:
	if _pending <= 0 or _picking:
		return
	_picking = true
	_pending -= 1
	var sheet := preload("res://src/survive/survive_pick.gd").new()
	sheet.run = self
	sheet.mode = "level"
	get_tree().current_scene.add_child(sheet)
	sheet.closed.connect(func() -> void:
		_picking = false
		if _pending > 0:
			call_deferred("_next_pick")
	)


## Elite chest: pick one of three items.
func open_item_chest() -> void:
	var pool: Array = (book.get("items", []) as Array).duplicate()
	pool.shuffle()
	var sheet := preload("res://src/survive/survive_pick.gd").new()
	sheet.run = self
	sheet.mode = "item"
	sheet.item_rows = pool.slice(0, 3)
	get_tree().current_scene.add_child(sheet)


## The Lost & Found well: carried items from earlier hours (FamilyProfile
## "lost_found"), pick one to take in.
func _offer_stash() -> void:
	var stash: Array = FamilyProfile.data.get("lost_found", [])
	if stash.is_empty():
		return
	var rows: Array = []
	for id in stash:
		var r := row("items", str(id))
		if not r.is_empty():
			rows.append(r)
	if rows.is_empty():
		return
	var sheet := preload("res://src/survive/survive_pick.gd").new()
	sheet.run = self
	sheet.mode = "stash"
	sheet.item_rows = rows.slice(0, 4)
	get_tree().current_scene.add_child(sheet)


## On clearing the hour: keep one of this run's items for the next ones.
func well() -> void:
	if items.is_empty():
		return
	var sheet := preload("res://src/survive/survive_pick.gd").new()
	sheet.run = self
	sheet.mode = "well"
	sheet.item_rows = items.duplicate()
	get_tree().current_scene.add_child(sheet)


func keep(row_: Dictionary) -> void:
	var stash: Array = FamilyProfile.data.get("lost_found", [])
	var id := str(row_.get("id", ""))
	if not stash.has(id):
		stash.append(id)
	while stash.size() > 6:
		stash.pop_front()
	FamilyProfile.data["lost_found"] = stash
	FamilyProfile.save()
