class_name SurviveIcons
extends RefCounted

## Icons for the coping hour (tools/survive_art.py).


static func tex(name: String) -> Texture2D:
	var p := "res://assets/sprites/survive/%s.png" % name
	return load(p) as Texture2D if ResourceLoader.exists(p) else null
