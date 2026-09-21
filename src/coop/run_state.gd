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
var rerolls: int = 0
var score_son: int = 0
var score_dad: int = 0
var score_total: int = 0

signal lives_changed
signal points_changed
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


func add_points(role: String, n: int, _why: String = "") -> void:
	if n <= 0:
		return
	if role == "father":
		score_dad += n
	else:
		score_son += n
	score_total += n
	points_changed.emit()
	Juice.last_hitter = role


func add_scrap(n: int) -> void:
	scrap += n
	scrap_changed.emit()
	add_points(Juice.last_hitter, n * 4, "scrap")


func add_xp(n: int) -> void:
	xp += n
	xp_changed.emit()
	if level_ups == 0 and xp >= 70:
		level_ups = 1
		need_cards.emit()
	elif level_ups == 1 and xp >= 160:
		level_ups = 2
		need_cards.emit()
	elif level_ups == 2 and xp >= 260:
		level_ups = 3
		need_cards.emit()
	elif level_ups == 3 and xp >= 380:
		level_ups = 4
		need_cards.emit()


func add_wanted(n: int) -> void:
	wanted = clampi(wanted + n, 0, 5)
	wanted_changed.emit()


func take_card(id: String) -> void:
	if id == "" or id == "skip":
		Juice.shout("SKIPPED")
		Juice.toast("reward", Copy.SKIP, "No rule. Same street. Cowardice is also a build.")
		return
	if not cards.has(id):
		cards.append(id)
	var rarity := "common"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if typeof(parsed) == TYPE_ARRAY:
		for c in parsed:
			if typeof(c) == TYPE_DICTIONARY and str((c as Dictionary).get("id", "")) == id:
				rarity = str((c as Dictionary).get("rarity", "common"))
				break
	Rarity.juice(rarity, id.replace("_", " ").to_upper())
	if Rarity.normalize(rarity) == "legendary":
		FamilyProfile.mark_legendary()
	Juice.shout(id.replace("_", " ").to_upper())
	Juice.toast("reward", "RULE INSTALLED", "%s  ·  %s" % [id.replace("_", " ").to_upper(), Rarity.label(rarity)])
	add_points(Juice.last_hitter, 40 + Rarity.rank(rarity) * 25, "card")
	SurviveMods.apply(id)


func has_card(id: String) -> bool:
	return cards.has(id)


func note_shop() -> void:
	shops_used += 1


func request_reroll() -> void:
	rerolls += 1
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
		"shops_used": shops_used,
		"rerolls": rerolls,
		"score_son": score_son,
		"score_dad": score_dad,
		"score_total": score_total
	}


func unpack(d: Dictionary) -> void:
	lives = int(d.get("lives", lives))
	scrap = int(d.get("scrap", scrap))
	xp = int(d.get("xp", xp))
	wanted = int(d.get("wanted", wanted))
	cards = (d.get("cards", []) as Array).duplicate()
	level_ups = int(d.get("level_ups", level_ups))
	shops_used = int(d.get("shops_used", shops_used))
	rerolls = int(d.get("rerolls", rerolls))
	score_son = int(d.get("score_son", score_son))
	score_dad = int(d.get("score_dad", score_dad))
	score_total = int(d.get("score_total", score_total))
	gated = false
	cleared = false
	failed = false
