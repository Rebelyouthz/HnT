class_name VoBank
extends Object

## English VO. ElevenLabs files when they exist; Mixer ducks music either way.


static func father_level() -> void:
	_play("res://assets/audio/vo_dad_level.wav", "res://assets/audio/vo_grounded.wav")


static func son_trick() -> void:
	_play("res://assets/audio/vo_son_kong.wav", "res://assets/audio/vo_son.wav")


static func mayor_radio() -> void:
	_play("res://assets/audio/vo_mayor_radio.wav", "res://assets/audio/sting_boss.wav")


static func bam(role: String) -> void:
	if role == "father":
		_play("res://assets/audio/vo_dad_level.wav", "res://assets/audio/slap.wav")
	else:
		_play("res://assets/audio/vo_son_kong.wav", "res://assets/audio/slap.wav")


static func father_nooo() -> void:
	_play("res://assets/audio/vo_dad_nooo.wav", "res://assets/audio/vo_grounded.wav")


static func dumpster() -> void:
	_play("res://assets/audio/vo_son_dumpster.wav", "res://assets/audio/vo_son_kong.wav")


static func dual() -> void:
	_play("res://assets/audio/vo_son_dual.wav", "res://assets/audio/vo_son_aaa.wav")


static func son_aaa() -> void:
	_play("res://assets/audio/vo_son_aaa.wav", "res://assets/audio/vo_son_dual.wav")


static func fridge() -> void:
	_play("res://assets/audio/vo_dad_fridge.wav", "res://assets/audio/vo_dad_level.wav")


static func bounce() -> void:
	_play("res://assets/audio/vo_dad_bounce.wav", "res://assets/audio/vo_dad_nooo.wav")


static func lottery() -> void:
	_play("res://assets/audio/vo_mayor_lottery.wav", "res://assets/audio/vo_mayor_radio.wav")


static func revenge() -> void:
	_play("res://assets/audio/vo_dad_revenge.wav", "res://assets/audio/vo_dad_level.wav")


static func cart() -> void:
	_play("res://assets/audio/vo_son_cart.wav", "res://assets/audio/vo_son_kong.wav")


static func fax() -> void:
	_play("res://assets/audio/vo_dad_fax.wav", "res://assets/audio/vo_dad_fridge.wav")


static func catch_vo(role: String) -> void:
	if role == "father":
		_play("res://assets/audio/vo_dad_catch.wav", "res://assets/audio/vo_dad_level.wav")
	else:
		_play("res://assets/audio/vo_son_catch.wav", "res://assets/audio/vo_son_kong.wav")


static func clash() -> void:
	_play("res://assets/audio/vo_dad_clash.wav", "res://assets/audio/vo_dad_revenge.wav")


static func awning() -> void:
	_play("res://assets/audio/vo_son_awning.wav", "res://assets/audio/vo_son_cart.wav")


static func tip() -> void:
	_play("res://assets/audio/vo_mayor_tip.wav", "res://assets/audio/vo_mayor_lottery.wav")


static func phone() -> void:
	_play("res://assets/audio/vo_dad_phone.wav", "res://assets/audio/vo_dad_fax.wav")


static func barrel() -> void:
	_play("res://assets/audio/vo_dad_barrel.wav", "res://assets/audio/vo_dad_clash.wav")


static func pole() -> void:
	_play("res://assets/audio/vo_son_pole.wav", "res://assets/audio/vo_son_awning.wav")


static func dive() -> void:
	_play("res://assets/audio/vo_dad_dive.wav", "res://assets/audio/vo_dad_revenge.wav")


static func cooler() -> void:
	_play("res://assets/audio/vo_mayor_cooler.wav", "res://assets/audio/vo_mayor_tip.wav")


static func manhole() -> void:
	_play("res://assets/audio/vo_dad_manhole.wav", "res://assets/audio/vo_dad_barrel.wav")


static func hood() -> void:
	_play("res://assets/audio/vo_son_hood.wav", "res://assets/audio/vo_son_pole.wav")


static func slide() -> void:
	_play("res://assets/audio/vo_dad_slide.wav", "res://assets/audio/vo_dad_dive.wav")


static func clock() -> void:
	_play("res://assets/audio/vo_mayor_clock.wav", "res://assets/audio/vo_mayor_cooler.wav")


static func bleach() -> void:
	_play("res://assets/audio/vo_mayor_bleach.wav", "res://assets/audio/vo_mayor_cooler.wav")


static func summit_dad() -> void:
	_play("res://assets/audio/vo_dad_summit.wav", "res://assets/audio/vo_dad_level.wav")


static func summit_son() -> void:
	_play("res://assets/audio/vo_son_summit.wav", "res://assets/audio/vo_son_kong.wav")


static func dad_skinwalker() -> void:
	_play("res://assets/audio/vo_dad_skinwalker.wav", "res://assets/audio/vo_dad_level.wav")


static func son_skinwalker() -> void:
	_play("res://assets/audio/vo_son_skinwalker.wav", "res://assets/audio/vo_son_kong.wav")


static var _lines: Dictionary = {}
static var _last: Dictionary = {}
static var _last_any := -10.0


## A voiced bark from data/vo_lines.json (assets/audio/vo/<id>.ogg): a
## random line for this speaker and event, at `chance`, never on top of
## another bark and never the same speaker twice inside 3 s.
static func line(who: String, ev: String, chance: float = 1.0) -> void:
	if randf() > chance:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_any < 1.4 or now - float(_last.get(who, -10.0)) < 3.0:
		return
	if _lines.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/vo_lines.json"))
		if parsed is Dictionary:
			for l: Dictionary in (parsed as Dictionary).get("lines", []):
				var key := "%s/%s" % [str(l["who"]), str(l["ev"])]
				var arr: Array = _lines.get(key, [])
				arr.append(str(l["id"]))
				_lines[key] = arr
	var pool: Array = _lines.get("%s/%s" % [who, ev], [])
	if pool.is_empty():
		return
	var path := "res://assets/audio/vo/%s.ogg" % str(pool[randi() % pool.size()])
	if not ResourceLoader.exists(path):
		return
	_last_any = now
	_last[who] = now
	Mixer.play_vo(path)


static var _effort_last: Dictionary = {}


## A short fighting shout (hah! hyah! hngh!) on a swing: its own clock so it
## never waits behind a bark, and never on every single jab.
static func effort(role: String, weight: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_effort_last.get(role, -10.0)) < 0.35:
		return
	if randf() > 0.35 + 0.55 * weight:
		return
	var n := 6
	var path := "res://assets/audio/vo/%s_effort_%d.ogg" % [role, 1 + randi() % n]
	if ResourceLoader.exists(path):
		_effort_last[role] = now
		Mixer.play_vo(path)


## Speaker key for an enemy (matches vo_lines.json).
static func who_of(p: Node) -> String:
	if p == null:
		return "thug"
	if bool(p.get("cop")):
		return "cop"
	match str(p.get("title")):
		"Mohawk Bo":
			return "mohawk"
		"Shift Lead":
			return "shift_lead"
		"Collector Gant":
			return "gant"
		"Repo Goon":
			return "repo"
		"Bailiff":
			return "bailiff"
		"Roof Runner":
			return "runner"
		"Bag Snatch":
			return "snatch"
		"Coping Imp", "Sleet Imp":
			return "imp"
		"Valet":
			return "valet"
	return "thug"


static func _play(prefer: String, fallback: String) -> void:
	for path in [prefer.get_basename() + ".mp3", prefer, fallback.get_basename() + ".mp3", fallback]:
		if ResourceLoader.exists(path):
			Mixer.play_vo(path)
			return
