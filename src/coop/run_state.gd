class_name RunState
extends Node

var lives: int = 3
var checkpoint := Vector2(220, 490)
var failed: bool = false
var cleared: bool = false
var gated: bool = false
var scrap: int = 0
var xp: int = 0
var wanted: int = 0
var cards: Array = []
var level_ups: int = 0
var shops_used: int = 0
var card_reroll: bool = false

signal lives_changed
signal run_failed
signal run_cleared
signal gate_reached
signal scrap_changed
signal xp_changed
signal wanted_changed
signal need_cards


func mark_checkpoint(pos: Vector2) -> void:
	checkpoint = pos


func spend_life() -> void:
	if failed or cleared:
		return
	lives = maxi(0, lives - 1)
	lives_changed.emit()
	if lives <= 0:
		failed = true
		run_failed.emit()


func reach_gate() -> void:
	if failed or cleared or gated:
		return
	gated = true
	FamilyProfile.add_gold(4)
	gate_reached.emit()


func clear_run() -> void:
	if failed or cleared:
		return
	cleared = true
	var gold := 12 + int(scrap / 5.0)
	FamilyProfile.add_gold(gold)
	run_cleared.emit()


func add_scrap(n: int) -> void:
	scrap += n
	scrap_changed.emit()


func add_xp(n: int) -> void:
	xp += n
	xp_changed.emit()
	if level_ups == 0 and xp >= 70:
		level_ups = 1
		need_cards.emit()
	elif level_ups == 1 and xp >= 160:
		level_ups = 2
		need_cards.emit()


func add_wanted(n: int) -> void:
	wanted = clampi(wanted + n, 0, 5)
	wanted_changed.emit()


func take_card(id: String) -> void:
	if not cards.has(id):
		cards.append(id)
	Juice.shout(id.replace("_", " ").to_upper())
	Juice.toast("reward", "RULE INSTALLED", id.replace("_", " ").to_upper())


func has_card(id: String) -> bool:
	return cards.has(id)


func note_shop() -> void:
	shops_used += 1


func request_reroll() -> void:
	card_reroll = true
	need_cards.emit()


func hp_mul() -> float:
	match App.difficulty:
		"open_house":
			return 0.75
		"finals":
			return 1.35
		_:
			return 1.0


func pack() -> Dictionary:
	return {
		"lives": lives,
		"scrap": scrap,
		"xp": xp,
		"wanted": wanted,
		"cards": cards.duplicate(),
		"level_ups": level_ups,
		"shops_used": shops_used
	}


func unpack(d: Dictionary) -> void:
	lives = int(d.get("lives", lives))
	scrap = int(d.get("scrap", scrap))
	xp = int(d.get("xp", xp))
	wanted = int(d.get("wanted", wanted))
	cards = (d.get("cards", []) as Array).duplicate()
	level_ups = int(d.get("level_ups", level_ups))
	shops_used = int(d.get("shops_used", shops_used))
	gated = false
	cleared = false
	failed = false
