extends SceneTree
## Story voice files are found by the same name the generator wrote, a
## voiced line holds the talk until the voice is done, and narrator
## captions stay silent.

func _initialize() -> void:
	var vo: GDScript = load("res://src/audio/story_vo.gd")
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	var film: Array = story["intro"]["film1"]
	var ok := true
	var spoken := 0
	for row: Dictionary in film:
		var p: String = vo.path(str(row["who"]), str(row["text"]))
		if str(row["who"]) == "":
			continue
		if not ResourceLoader.exists(p):
			print("missing voice for ", row["who"], ": ", row["text"])
			ok = false
		else:
			var s: AudioStream = load(p)
			if s == null or s.get_length() < 0.5:
				ok = false
			spoken += 1
	if vo.say("", "RAVEN WHARF.") != 0.0:
		ok = false
	var src := FileAccess.get_file_as_string("res://src/story/talk.gd")
	if not src.contains("StoryVo.say(who, text)") or not src.contains("StoryVo.hush()"):
		ok = false
	var src2 := FileAccess.get_file_as_string("res://src/ui/summit_talk.gd")
	if not src2.contains("StoryVo.say("):
		ok = false
	print("STORY VO OK" if ok and spoken >= 2 else "STORY VO FAIL")
	quit(0 if ok else 1)
