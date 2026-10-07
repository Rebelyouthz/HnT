class_name QuickBelt
extends Node

## The QUICK BELT: four slots per hero for things picked up in a run, used
## when you want them instead of the moment you walk over them.
##   1 FLASK       a quarter of max HP            (d-pad left  / key 1)
##   2 ADRENALINE  every heart back, steam full   (d-pad up    / key 2)
##   3 ENERGY CAN  run faster and refill steam    (d-pad right / key 3)
##   4 SMOKE BOMB  thugs close by lose you 2 s    (d-pad down  / key 4)
## P2 on keyboard uses 7 8 9 0. A full stack uses the pickup on the spot.
## The belt lasts the run (App.run_bag) and resets at home.

const ORDER := ["flask", "syringe", "energy", "smoke"]
const ITEMS := {
	"flask": {"name": "FLASK", "max": 3, "icon": "res://assets/sprites/loot/flask.png"},
	"syringe": {"name": "ADRENALINE", "max": 1, "icon": "res://assets/sprites/loot/syringe.png"},
	"energy": {"name": "ENERGY CAN", "max": 2, "icon": "res://assets/sprites/icons/card_protein_shake.png"},
	"smoke": {"name": "SMOKE BOMB", "max": 2, "icon": "res://assets/sprites/icons/card_smoke_bomb.png"},
}

signal changed(role: String)

static var _inst: QuickBelt


static func find() -> QuickBelt:
	return _inst if is_instance_valid(_inst) else null


static func place(host: Node) -> QuickBelt:
	var b := QuickBelt.new()
	host.add_child(b)
	return b


func _enter_tree() -> void:
	_inst = self


static func _belt(role: String) -> Dictionary:
	var key := "belt_" + role
	if not App.run_bag.has(key):
		App.run_bag[key] = {"flask": 1, "syringe": 0, "energy": 0, "smoke": 0}
	return App.run_bag[key]


static func count(role: String, id: String) -> int:
	return int(_belt(role).get(id, 0))


## Stores a pickup. Returns false when that stack is full.
static func add(role: String, id: String) -> bool:
	var b := _belt(role)
	if count(role, id) >= int(ITEMS[id]["max"]):
		return false
	b[id] = count(role, id) + 1
	if find():
		find().changed.emit(role)
	return true


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	for n in get_tree().get_nodes_in_group("players"):
		var f := n as Fighter
		if f == null or f.downed or f.net_driven:
			continue
		for i in 4:
			var act := StringName("%sslot%d" % [str(f.prefix), i + 1])
			if InputMap.has_action(act) and Input.is_action_just_pressed(act):
				use(f, ORDER[i])


## Uses one from the belt. An empty slot just clicks.
static func use(f: Fighter, id: String) -> bool:
	if count(f.role, id) <= 0:
		Mixer.play_sfx("res://assets/audio/ui_click.wav", 0.7, -10.0)
		Juice.popup_number(f.global_position + Vector2(0, -96), "NO %s" % str(ITEMS[id]["name"]), Palette.MUTED)
		return false
	_belt(f.role)[id] = count(f.role, id) - 1
	apply(f, id)
	if find():
		find().changed.emit(f.role)
	return true


## The effect itself (also used when a pickup lands on a full stack).
static func apply(f: Fighter, id: String) -> void:
	match id:
		"flask":
			var heal := 0 if Artifacts.has("no_lunch") else int(round(float(f.max_hp) * 0.25))
			f.hp = mini(f.max_hp, f.hp + heal)
			Juice.popup_number(f.global_position + Vector2(0, -96), "+%d HP" % heal, Palette.READY)
			Juice.play("res://assets/audio/heal.wav" if ResourceLoader.exists("res://assets/audio/heal.wav") else "res://assets/audio/cling_ok.wav")
			Juice.pulse_shake(1.5)
		"syringe":
			f.hp = f.max_hp
			f.steam = Fighter.STEAM_MAX
			Juice.popup_number(f.global_position + Vector2(0, -100), "FULL REFILL", Palette.READY)
			Juice.play("res://assets/audio/trick_perfect.wav")
			Juice.hitstop(4)
			Juice.pulse_shake(4.0)
			FamilyProfile.data["syringes"] = int(FamilyProfile.data.get("syringes", 0)) + 1
		"energy":
			f.trick_boost = maxf(f.trick_boost, 1.22)
			f.trick_t = maxf(f.trick_t, 6.0)
			f.steam = minf(Fighter.STEAM_MAX, f.steam + 50.0)
			Juice.popup_number(f.global_position + Vector2(0, -96), "ENERGY  +SPEED", Color(0.5, 0.9, 1.0))
			Juice.play("res://assets/audio/cling.wav")
		"smoke":
			var n := 0
			for e in f.get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and (e as Node2D).global_position.distance_to(f.global_position) < 190.0 and e.get("snared") != null:
					e.set("snared", maxf(float(e.get("snared")), 2.0))
					n += 1
			ArtFx.spawn(f.get_parent(), f.global_position + Vector2(0, -20), "ring", Color(0.75, 0.75, 0.8), 120.0, 0.6)
			Juice.land_puff(f.global_position)
			Juice.popup_number(f.global_position + Vector2(0, -96), "SMOKE  ·  %d LOST YOU" % n, Color(0.8, 0.8, 0.85))
			Juice.play("res://assets/audio/whoosh_light.wav")
