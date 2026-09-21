class_name Rarity
extends Object

## Common → Legendary. "special" is the old name for epic.

const ORDER: Array[String] = ["common", "uncommon", "rare", "epic", "legendary"]


static func normalize(raw: String) -> String:
	var t := raw.to_lower().strip_edges()
	if t == "special":
		return "epic"
	if t in ORDER:
		return t
	return "common"


static func color(raw: String) -> Color:
	match normalize(raw):
		"uncommon":
			return Color(0.35, 0.78, 0.42)
		"rare":
			return Color(0.32, 0.55, 0.95)
		"epic":
			return Color(0.72, 0.38, 0.92)
		"legendary":
			return Palette.EDGE
		_:
			return Palette.MUTED


static func fill(raw: String) -> Color:
	match normalize(raw):
		"legendary":
			return Color(0.16, 0.13, 0.06)
		"epic":
			return Color(0.14, 0.08, 0.18)
		"rare":
			return Color(0.08, 0.1, 0.18)
		"uncommon":
			return Color(0.07, 0.12, 0.09)
		_:
			return Palette.PANEL


static func label(raw: String) -> String:
	return normalize(raw).to_upper()


static func rank(raw: String) -> int:
	return ORDER.find(normalize(raw))


static func juice(raw: String, title: String) -> void:
	var r := normalize(raw)
	if r == "legendary":
		Juice.unlock_logo(title, "LEGENDARY. The clipboard blushed.")
		Juice.pulse_shake(8.0)
		Juice.shout("LEGENDARY")
		Juice.play("res://assets/audio/chest.wav")
	elif r == "epic":
		Juice.shout("EPIC")
		Juice.pulse_shake(4.0)
		Juice.play("res://assets/audio/card.wav")
	elif r == "rare":
		Juice.play("res://assets/audio/card.wav")


static func buy(title: String, info: Dictionary) -> void:
	var r := normalize(str(info.get("rarity", "common")))
	juice(r, title)
	Juice.toast("reward", "%s  ·  %s" % [title, label(r)], str(info.get("line", "")))


static func of_pickup(kind: String) -> String:
	match kind:
		"pistol":
			return "rare"
		"knife", "board":
			return "uncommon"
		_:
			return "common"
