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


static func _play(prefer: String, fallback: String) -> void:
	for path in [prefer.get_basename() + ".mp3", prefer, fallback.get_basename() + ".mp3", fallback]:
		if ResourceLoader.exists(path):
			Mixer.play_vo(path)
			return
