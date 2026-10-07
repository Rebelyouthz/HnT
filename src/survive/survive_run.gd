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
## Evolved abilities (id -> true): an ability at LV 7 with its partner item
## turns into its evolution in the next chest (needs the EVOLUTION node).
var evolved: Dictionary = {}
## The ultimate: kills charge it, SPECIAL fires it when full.
var ult := "copay_crash"
var ult_charge := 0.0
const ULT_NEED := 60.0
var revives := 0
var time_alive := 0.0
var _vamp_kills := 0
var _awarded := false
## S-COINS picked up this hour, and LIMIT BREAKS once everything is maxed.
var coins := 0
var limit_breaks := 0
## TALKING STICK (group circle): +40% damage while it lasts.
var share_t := 0.0
## Damage dealt per ability this hour (DPS meter).
var dealt: Dictionary = {}
var missions: SurvMissions
var luck_boost := 0.0


static func get_run(tree: SceneTree) -> SurviveRun:
	return tree.get_first_node_in_group("survive_run") as SurviveRun if tree else null


func _ready() -> void:
	add_to_group("survive_run")
	# The weekly hour: the same street for everyone all week.
	if App.weekly:
		seed(WeeklyBook.seed_n())
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
	book = parsed if parsed is Dictionary else {}
	# Everyone starts the hour with one ability: the Son's paper, the
	# Father's coffee (solo picks by role).
	var start := "invoice_toss" if App.solo_role == "son" else "coffee"
	# The STARTER WEAPON picked in the menus walks in with you instead.
	if SurvStarter.picked() != "":
		start = SurvStarter.picked()
	call_deferred("_grant", start)
	missions = SurvMissions.new()
	var extras := SurvExtras.new()
	(func() -> void:
		if is_inside_tree() and get_tree().current_scene:
			get_tree().current_scene.add_child(missions)
			get_tree().current_scene.add_child(extras)).call_deferred()
	if Trees.has("u_start2"):
		call_deferred("_second_start", start)
	# SURVIVOR meta + tree: extra rerolls, banishes, revives, a free trait.
	rerolls += Meta.rank("s_reroll") + (2 if Trees.has("s_reroll") else 0)
	banishes += Meta.rank("s_banish") + (2 if Trees.has("s_banish") else 0)
	revives = Meta.rank("s_revival") + (1 if Trees.has("f_revive") else 0)
	var chosen := str(FamilyProfile.data.get("surv_ult", "copay_crash"))
	if ult_unlocked(chosen):
		ult = chosen
	call_deferred("_meta_body")
	if Trees.has("f_start"):
		call_deferred("_free_trait")
	# A carried item from the Lost & Found well.
	call_deferred("_offer_stash")


func _second_start(first: String) -> void:
	var pool: Array = []
	for a: Dictionary in book.get("abilities", []):
		var id := str(a.get("id", ""))
		if id != first and ability_unlocked(id):
			pool.append(id)
	if not pool.is_empty():
		_grant(str(pool[randi() % pool.size()]))
		Juice.shout("DOUBLE SHIFT")


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


func _ex() -> SurvExtras:
	return SurvExtras.get_extras(get_tree()) if is_inside_tree() else null


func dmg_mul() -> float:
	return (_ex().dmg_mul() if _ex() else 1.0) * (1.4 if share_t > 0.0 else 1.0) * (1.0 + 0.12 * trait_n("t_dmg") + _item_mod("dmg") + 0.05 * Meta.rank("s_might") + SurvGear.stat("dmg") + (0.08 if Trees.has("u_limit") else 0.05) * float(limit_breaks))


func area_mul() -> float:
	return (_ex().area_mul() if _ex() else 1.0) * (1.0 + 0.14 * trait_n("t_area") + _item_mod("area") + 0.05 * Meta.rank("s_area") + SurvGear.stat("area"))


func cd_mul() -> float:
	var m := maxf(0.35, 1.0 - 0.08 * trait_n("t_cd") - _item_mod("cd") - 0.03 * Meta.rank("s_cooldown") - SurvGear.stat("cd"))
	return m * (0.5 if frenzy_t > 0.0 else 1.0) * (_ex().cd_mul() if _ex() else 1.0)


func proj_bonus() -> int:
	return trait_n("t_proj") + int(_item_mod("proj")) + Meta.rank("s_amount") + int(SurvGear.stat("proj"))


func crit() -> float:
	return 0.06 * trait_n("t_crit") + _item_mod("crit") + 0.04 * trait_n("t_luck") + 0.03 * Meta.rank("s_luck") + SurvGear.stat("crit")


func speed_mul() -> float:
	return (_ex().speed_mul() if _ex() else 1.0) * (1.0 + 0.07 * trait_n("t_speed") + _item_mod("speed") + 0.04 * Meta.rank("s_speed") + SurvGear.stat("speed"))


func armor() -> float:
	return minf(0.7, 0.07 * trait_n("t_armor") + 0.04 * Meta.rank("s_armor") + SurvGear.stat("armor"))


func pickup_mul() -> float:
	return (1.4 if _ex() and _ex().has("fleet") else 1.0) * (1.0 + 0.3 * trait_n("t_pickup") + _item_mod("pickup") + 0.15 * Meta.rank("s_magnet") + (0.4 if Trees.has("f_magnet") else 0.0) + SurvGear.stat("pickup"))


func max_abilities() -> int:
	return MAX_ABILITIES + (1 if Trees.has("s_slot") else 0)


func max_items() -> int:
	return MAX_ITEMS + (1 if Trees.has("s_item_slot") else 0)


func luck() -> float:
	return luck_boost + 0.05 * trait_n("t_luck") + 0.04 * Meta.rank("s_luck") + (0.15 if Trees.has("f_luck") else 0.0) + SurvGear.stat("luck")


func ult_unlocked(id: String) -> bool:
	var r := row("ultimates", id)
	return not r.is_empty() and (str(r.get("unlock", "")) == "" or Trees.has(str(r.get("unlock", ""))))


func ability_unlocked(id: String) -> bool:
	var r := row("abilities", id)
	return str(r.get("unlock", "")) == "" or Trees.has(str(r.get("unlock", "")))


func _meta_body() -> void:
	var hp := 10 * Meta.rank("s_maxhp") + int(SurvGear.stat("hp"))
	for f in _fighters():
		f.max_hp += hp
		f.hp += hp


func _free_trait() -> void:
	var pool: Array = []
	for r: Dictionary in book.get("traits", []):
		pool.append(str(r["id"]))
	if pool.is_empty():
		return
	var id: String = pool[randi() % pool.size()]
	take({"kind": "trait", "id": id})
	Juice.toast("reward", "HEAD START", str(row("traits", id).get("name", id)))


func slow() -> float:
	return _item_mod("slow")


## Damage of one hit of an ability at its level, with crit rolled.
func hit(id: String) -> Dictionary:
	var r := row("abilities", id)
	var lv := int(abilities.get(id, 1))
	var d := (float(r.get("dmg", 6)) + float(r.get("per", 1)) * float(lv - 1)) * dmg_mul() * (2.2 if evolved.has(id) else 1.0) * SurvStarter.dmg_mul(id)
	var c := randf() < crit() + SurvStarter.crit_bonus(id)
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
		n += proj_bonus() + SurvStarter.proj_bonus(id)
		if evolved.has(id):
			n += 2
	return n


# --- xp / levels ---------------------------------------------------------------

func need() -> int:
	var c: Dictionary = book.get("xp_curve", {})
	return int(round(float(c.get("base", 14)) * pow(float(c.get("growth", 1.22)), float(level - 1))))


func add_xp(n: int) -> void:
	n = int(ceil(float(n) * (1.0 + 0.12 * trait_n("t_xp") + 0.15 * trait_n("t_curse") + 0.05 * Meta.rank("s_growth") + SurvGear.stat("xp"))))
	xp += n
	while xp >= need():
		xp -= need()
		level += 1
		_pending += 1
		if Trees.has("s_boxes") and level % 5 == 0:
			call_deferred("open_item_chest")
		var heal := _item_mod("lvl_heal")
		for f in _fighters():
			if heal > 0.0:
				f.hp = mini(f.max_hp, f.hp + int(ceil(float(f.max_hp) * heal)))
		if _item_mod("frenzy") > 0.0:
			frenzy_t = _item_mod("frenzy")
		Juice.shout("LEVEL %d" % level)
		for ff in _fighters():
			SurvProj.ring(ff.get_parent(), ff.global_position, 150.0, Color(0.5, 1.0, 0.6))
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and (e as Node2D).global_position.distance_to(ff.global_position) < 150.0:
					var away := ((e as Node2D).global_position - ff.global_position).normalized()
					(e as Node2D).global_position += away * 40.0
					e.set("recover", maxf(float(e.get("recover")), 0.4))
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
	ult_charge = minf(ULT_NEED, ult_charge + 1.0)
	if trait_n("t_vamp") > 0:
		_vamp_kills += 1
		if _vamp_kills >= 25:
			_vamp_kills = 0
			for f in _fighters():
				f.hp = mini(f.max_hp, f.hp + 3 * trait_n("t_vamp"))
	var kh := int(_item_mod("kill_heal"))
	if kh > 0:
		for f in _fighters():
			f.hp = mini(f.max_hp, f.hp + kh)


func _process(delta: float) -> void:
	frenzy_t = maxf(0.0, frenzy_t - delta)
	time_alive += delta
	_tick_ult()
	_tick_revive()
	var rg := 0.6 * trait_n("t_regen") + 0.25 * Meta.rank("s_recovery") + SurvGear.stat("regen")
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
		if id in banned or not ability_unlocked(id):
			continue
		if abilities.has(id):
			if int(abilities[id]) < MAX_LV:
				pool.append({"kind": "ability", "id": id, "w": 3.0})
		elif abilities.size() < max_abilities():
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
				Discover.see("ability", id, str(row("abilities", id).get("name", id)))
		"trait":
			var id := str(o["id"])
			traits[id] = trait_n(id) + 1
			if id == "t_hp":
				for f in _fighters():
					f.max_hp += 12
					f.hp += 12
		"item":
			if items.size() < max_items():
				items.append(o["row"])
			else:
				items[randi() % items.size()] = o["row"]
		"evolve":
			var eid := str(o["id"])
			evolved[eid] = true
			var ev := evolution_of(eid)
			Juice.unlock_logo(str(ev.get("name", "EVOLVED")), str(ev.get("blurb", "")), "EVOLUTION")
			Rarity.juice("legendary", str(ev.get("name", "")))
			var ab: Array = FamilyProfile.data.get("evolutions_seen", [])
			if not ab.has(eid):
				ab.append(eid)
				FamilyProfile.data["evolutions_seen"] = ab
			var hp := int(((o["row"] as Dictionary).get("mods", {}) as Dictionary).get("hp", 0))
			for f in _fighters():
				f.max_hp += hp
				f.hp += hp
		"gold":
			# LIMIT BREAK: everything maxed, every pick is +5% damage instead.
			limit_breaks += 1
			Juice.shout("LIMIT BREAK %d" % limit_breaks)
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


func evolution_of(id: String) -> Dictionary:
	for e: Dictionary in book.get("evolutions", []):
		if str(e.get("ability", "")) == id:
			return e
	return {}


func has_item(id: String) -> bool:
	for it: Dictionary in items:
		if str(it.get("id", "")) == id:
			return true
	return false


## An ability ready to evolve: LV 7, partner item held, EVOLUTION owned.
func evolve_ready() -> String:
	if not Trees.has("s_evolve"):
		return ""
	for id in abilities:
		if int(abilities[id]) >= MAX_LV and not evolved.has(id):
			var e := evolution_of(str(id))
			if not e.is_empty() and has_item(str(e.get("item", ""))):
				return str(id)
	return ""


## Elite chest: pick one of three items (or an evolution when one is ready).
func open_item_chest() -> void:
	var ready := evolve_ready()
	if ready != "":
		var e := evolution_of(ready)
		var sh := preload("res://src/survive/survive_pick.gd").new()
		sh.run = self
		sh.mode = "evolve"
		sh.item_rows = [{"kind": "evolve", "id": ready, "name": str(e.get("name", "")), "blurb": str(e.get("blurb", "")), "icon": "evolve"}]
		get_tree().current_scene.add_child(sh)
		return
	var pool: Array = (book.get("items", []) as Array).duplicate()
	pool.shuffle()
	# LUCK: rarer items float to the front.
	if luck() > 0.0:
		# One roll per item (a comparator that re-rolls breaks the sort).
		var lk := luck()
		for it: Dictionary in pool:
			it["_roll"] = Rarity.rank(str(it.get("rarity", "common"))) * lk + randf()
		pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["_roll"]) > float(b["_roll"]))
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



# --- ultimate, revives, tokens -----------------------------------------------

func _tick_ult() -> void:
	if ult_charge < ULT_NEED:
		return
	for f in _fighters():
		if not f.downed and Input.is_action_just_pressed(str(f.prefix) + "special"):
			fire_ult(f)
			return


func fire_ult(f: Fighter) -> void:
	ult_charge = 0.0
	var r := row("ultimates", ult)
	Juice.shout(str(r.get("name", "ULTIMATE")))
	Juice.hitstop(8)
	Juice.pulse_shake(12.0)
	Mixer.play_sfx("res://assets/audio/boss_roar.wav" if ResourceLoader.exists("res://assets/audio/boss_roar.wav") else "res://assets/audio/kill.wav", 1.2, -2.0)
	var cam := f.get_viewport().get_camera_2d()
	var c := cam.global_position if cam else f.global_position
	match ult:
		"panic_room":
			for ff in _fighters():
				ff.invuln = maxi(ff.invuln, 360)
			SurvProj.ring(f.get_parent(), f.global_position, 120.0, Color(0.4, 0.75, 1.0))
			var t := 0
			while t < 12 and is_inside_tree():
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is Punk and (e as Node2D).global_position.distance_to(f.global_position) < 120.0:
						(e as Punk).take_hit("skill", f)
						(e as Node2D).global_position += ((e as Node2D).global_position - f.global_position).normalized() * 20.0
				SurvProj.ring(f.get_parent(), f.global_position, 120.0, Color(0.4, 0.75, 1.0, 0.5))
				await get_tree().create_timer(0.5).timeout
				t += 1
		"black_friday":
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Punk and absf((e as Node2D).global_position.x - c.x) < 700.0:
					(e as Punk).take_hit("skill", f)
					LootDrop.spawn(f.get_parent(), (e as Node2D).global_position, "coin", 1, 1.0)
					add_xp(4)
		_:
			SurvProj.ring(f.get_parent(), f.global_position, 340.0, Color(1.0, 0.6, 0.2))
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Punk and absf((e as Node2D).global_position.x - c.x) < 700.0:
					for i in 3:
						(e as Punk).take_hit("skill", f)
					(e as Punk).recover = maxf((e as Punk).recover, 1.0)


func _tick_revive() -> void:
	if revives <= 0:
		return
	for f in _fighters():
		if f.downed:
			revives -= 1
			f._revived()
			f.hp = int(round(float(f.max_hp) * 0.5))
			Juice.shout("SECOND SHIFT")
			SurvProj.ring(f.get_parent(), f.global_position, 140.0, Color(0.5, 1.0, 0.6))
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Punk and (e as Node2D).global_position.distance_to(f.global_position) < 140.0:
					(e as Punk).take_hit("skill", f)
			return


## Tokens for the SURVIVOR tree and meta: kills, minutes held, level, boss.
func award_tokens(won: bool) -> int:
	if _awarded:
		return 0
	_awarded = true
	var n := int(kills / 15) + int(time_alive / 60.0 * 8.0) + level * 2 + (40 if won else 0) + coins
	n = int(round(float(n) * (1.0 + 0.1 * trait_n("t_curse")) * (1.0 + SurvExtras.pact_sum("coins"))))
	var before := int(FamilyProfile.data.get("tokens", 0))
	Trees.add_tokens(n)
	var got := int(FamilyProfile.data.get("tokens", 0)) - before
	Engine.set_meta("run_tokens", got)
	# A piece of gear for every hour survived past 2:00, two on a win.
	for i in (2 if won else (1 if time_alive > 120.0 else 0)):
		SurvGear.drop(luck())
	FamilyProfile.data["surv_best_kills"] = maxi(int(FamilyProfile.data.get("surv_best_kills", 0)), kills)
	FamilyProfile.data["surv_best_level"] = maxi(int(FamilyProfile.data.get("surv_best_level", 0)), level)
	FamilyProfile.data["surv_best_time"] = maxi(int(FamilyProfile.data.get("surv_best_time", 0)), int(time_alive))
	var st := {"kills": kills, "time": int(time_alive), "level": level, "evolved": evolved.size(), "won": 1 if won else 0}
	if missions and is_instance_valid(missions):
		st.merge(missions.stats())
	SurvChallenges.check(st)
	if App.weekly:
		Juice.toast("reward", "WEEKLY GAUNTLET", WeeklyBook.record(int(time_alive), kills, won))
	FamilyProfile.save()
	return got
