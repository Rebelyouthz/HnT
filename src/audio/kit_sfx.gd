class_name KitSfx
extends Object

## Per-attack, per-character. Pitch is the personality. Files when they exist.


static func hit(role: String, kind: String) -> void:
	var pitch := 1.12 if role == "son" else 0.86
	var named := "res://assets/audio/%s_%s.wav" % [kind, "son" if role == "son" else "dad"]
	if ResourceLoader.exists(named):
		Mixer.play_sfx(named, pitch)
		return
	var generic := "res://assets/audio/%s.wav" % kind
	if ResourceLoader.exists(generic):
		Mixer.play_sfx(generic, pitch)
		return
	match kind:
		"light", "jump-kick", "gut-punch", "slide", "air-mix":
			Mixer.play_sfx("res://assets/audio/hit_light.wav", pitch)
		"jump", "land":
			Mixer.play_sfx("res://assets/audio/jump.wav", pitch * (1.08 if kind == "land" else 1.0))
		"dash", "slide":
			Mixer.play_sfx("res://assets/audio/dash.wav", pitch)
		"uppercut", "air-upper":
			Mixer.play_sfx("res://assets/audio/uppercut.wav" if ResourceLoader.exists("res://assets/audio/uppercut.wav") else "res://assets/audio/hit_heavy.wav", pitch * 1.08)
		"roundhouse":
			Mixer.play_sfx("res://assets/audio/roundhouse.wav" if ResourceLoader.exists("res://assets/audio/roundhouse.wav") else "res://assets/audio/hit_heavy.wav", pitch * 0.94)
		"stomp1":
			Mixer.play_sfx("res://assets/audio/stomp1.wav" if ResourceLoader.exists("res://assets/audio/stomp1.wav") else "res://assets/audio/hit_heavy.wav", 0.92)
		"stomp2":
			Mixer.play_sfx("res://assets/audio/stomp2.wav" if ResourceLoader.exists("res://assets/audio/stomp2.wav") else "res://assets/audio/kill.wav", 1.0)
		"stomp3":
			Mixer.play_sfx("res://assets/audio/stomp3.wav" if ResourceLoader.exists("res://assets/audio/stomp3.wav") else "res://assets/audio/finish.wav", 0.86)
		"slap":
			Mixer.play_sfx("res://assets/audio/slap.wav", pitch)
		"parry":
			Mixer.play_sfx("res://assets/audio/parry.wav" if ResourceLoader.exists("res://assets/audio/parry.wav") else "res://assets/audio/block.wav", pitch * 1.12)
		"smash":
			Mixer.play_sfx("res://assets/audio/smash.wav", pitch)
		"revenge":
			Mixer.play_sfx("res://assets/audio/revenge.wav" if ResourceLoader.exists("res://assets/audio/revenge.wav") else "res://assets/audio/hit_heavy.wav", pitch * 0.9)
		"cart":
			Mixer.play_sfx("res://assets/audio/cart.wav" if ResourceLoader.exists("res://assets/audio/cart.wav") else "res://assets/audio/dash.wav", pitch)
		_:
			Mixer.play_sfx("res://assets/audio/hit_heavy.wav", pitch)


static func gun(id: String, role: String) -> void:
	var spec := WeaponBook.spec(id)
	var path := str(spec.get("sfx", "res://assets/audio/shuriken.wav"))
	var pitch := 1.1 if role == "son" else 0.9
	if FamilyProfile.has_research("silencer"):
		pitch *= 0.82
	Mixer.play_sfx(path, pitch)


static func foot(role: String, speed_frac: float, stumble := false) -> void:
	if stumble:
		Mixer.play_sfx("res://assets/audio/stumble.wav" if ResourceLoader.exists("res://assets/audio/stumble.wav") else "res://assets/audio/hit_heavy.wav", 0.92 if role == "father" else 1.08)
		return
	var pitch := (1.08 if role == "son" else 0.84) * (0.92 + speed_frac * 0.25)
	if ResourceLoader.exists("res://assets/audio/foot.wav"):
		Mixer.play_sfx("res://assets/audio/foot.wav", pitch, -16.0)
	else:
		Mixer.play_sfx("res://assets/audio/dash.wav", pitch, -22.0)


static func vehicle(kind: String) -> void:
	Mixer.play_sfx("res://assets/audio/dash.wav", 0.82 if kind == "car" else 1.12)


static func jab(role: String) -> void:
	hit(role, "light")


static func cross(role: String) -> void:
	hit(role, "gut-punch")


static func bam(role: String) -> void:
	hit(role, "heavy")
	VoBank.bam(role)
