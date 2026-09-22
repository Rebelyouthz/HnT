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


static func son_aaa() -> void:
	_play("res://assets/audio/vo_son_aaa.wav", "res://assets/audio/vo_son.wav")


static func _play(prefer: String, fallback: String) -> void:
	for path in [prefer.get_basename() + ".mp3", prefer, fallback.get_basename() + ".mp3", fallback]:
		if ResourceLoader.exists(path):
			Mixer.play_vo(path)
			return
