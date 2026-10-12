class_name StoryVo
extends RefCounted
## Spoken story lines (films, prologue, act talk, towers). One clip per
## speaker+text, named by hash so rewording a line simply drops its voice
## until tools/story_vo.py records it again. Narrator captions stay silent.

const DIR := "res://assets/audio/vo/story/"


static func path(who: String, text: String) -> String:
	return DIR + (who + "|" + text).md5_text().substr(0, 10) + ".ogg"


## Plays the line if it was recorded; returns its length (0 = silent).
static func say(who: String, text: String) -> float:
	if who == "" or text == "":
		return 0.0
	var p := path(who, text)
	if not ResourceLoader.exists(p):
		return 0.0
	var tree := Engine.get_main_loop() as SceneTree
	var mixer := tree.root.get_node_or_null("Mixer") if tree else null
	if mixer == null:
		return 0.0
	mixer.play_vo(p)
	var s: AudioStream = load(p)
	return s.get_length() if s else 0.0


static func hush() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mixer := tree.root.get_node_or_null("Mixer") if tree else null
	if mixer != null:
		mixer.stop_vo()
