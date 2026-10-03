class_name Nemesis
extends RefCounted

## The thug who takes one of your lives gets a name, a grudge and a title.
## He comes back in a later stage (once per stage, midway) tougher every
## time he wins, wearing his name over his head. Put him down for good and
## he pays out big. One nemesis at a time (FamilyProfile "nemesis").

const FIRST := ["Gary", "Big Lou", "Denise", "Marco", "Tiny", "Sheila", "Duncan", "Vlad", "Ronnie", "Pam"]
const EPITHET := ["Who Took Your Lunch", "the Collector's Nephew", "of the Late Fees", "Who Knows Your Address",
		"With the Opinions", "Who Never Signs Anything", "the Unbillable", "Who Laughed At Dad"]


## A thug just took a life: he becomes (or grows) the nemesis.
static func note_death(by: String) -> void:
	if by == "" or by == "the street" or by.begins_with("a "):
		return
	var n: Dictionary = FamilyProfile.data.get("nemesis", {})
	if not n.is_empty() and str(n.get("title", "")) == by:
		n["level"] = int(n.get("level", 1)) + 1
		Juice.toast("challenge", "NEMESIS GROWS", "%s is now level %d. He's telling people." % [str(n["name"]), int(n["level"])])
	elif n.is_empty():
		n = {"title": by, "name": "%s %s" % [FIRST[randi() % FIRST.size()], EPITHET[randi() % EPITHET.size()]], "level": 1, "born": App.current_map + str(App.map_index)}
		Juice.toast("challenge", "NEW NEMESIS", "%s (%s) will remember this." % [str(n["name"]), by])
	FamilyProfile.data["nemesis"] = n
	FamilyProfile.save()


## Spawn him once in a story stage if there is one (not on the stage where
## he was born: he needs time to brag).
static func maybe_spawn(host: Node, map_id: String, map_w: float, hp_mul: float) -> void:
	var n: Dictionary = FamilyProfile.data.get("nemesis", {})
	if n.is_empty() or str(n.get("born", "")) == map_id + str(App.map_index):
		return
	var lv := int(n.get("level", 1))
	var row := {"title": str(n["title"]), "x": map_w * 0.55, "y": 500, "home": "street",
			"hp": 60 + 30 * lv, "pmin": map_w * 0.45, "pmax": map_w * 0.7}
	var p := Party.spawn_row(host, row, hp_mul)
	if p == null:
		return
	p.set_meta("nemesis", true)
	p.scale = Vector2(1.15, 1.15) * (1.0 + 0.04 * float(lv))
	p.speed *= 1.0 + 0.05 * float(lv)
	var tag := Label.new()
	tag.text = "%s  ·  NEMESIS LV %d" % [str(n["name"]).to_upper(), lv]
	tag.position = Vector2(-90, -104)
	tag.size = Vector2(180, 12)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 7)
	tag.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tag.add_theme_constant_override("outline_size", 3)
	p.add_child(tag)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 0.45
	l.color = Color(1.0, 0.15, 0.15)
	l.energy = 1.1
	l.position = Vector2(0, -30)
	p.add_child(l)
	p.died.connect(func() -> void:
		FamilyProfile.data["nemesis"] = {}
		FamilyProfile.data["nemeses_beaten"] = int(FamilyProfile.data.get("nemeses_beaten", 0)) + 1
		FamilyProfile.add_gold(25 * lv)
		FamilyProfile.add_gems(1)
		Juice.shout("NEMESIS DOWN")
		Juice.toast("reward", "GRUDGE SETTLED", "%s is done. +%d gold, +1 gem." % [str(n["name"]), 25 * lv])
		FamilyProfile.save()
	)
