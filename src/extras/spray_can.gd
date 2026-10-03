class_name SprayCan
extends Node2D

## Three spray cans hidden on every street (roofs, corners, behind things).
## Grab one and the kid tags the nearest wall with the family mark. All
## three: a gem and the TAGGER badge.

const SPOTS := {
	"dock_street": [Vector2(600, 248), Vector2(1940, 490), Vector2(2700, 248)],
	"tutorial_alley": [Vector2(900, 490)],
	"intake_lot": [Vector2(520, 490), Vector2(1250, 490), Vector2(1900, 490)],
}

var map_id := ""
var idx := 0
var _sp: Sprite2D
var _t := 0.0


static func place_all(host: Node, map: String) -> void:
	var spots: Array = SPOTS.get(map, [])
	var got: Array = FamilyProfile.data.get("tags_" + map, [])
	for i in spots.size():
		if got.has(i):
			_paint_tag(host, spots[i], true)
			continue
		var c := SprayCan.new()
		c.map_id = map
		c.idx = i
		c.position = spots[i]
		host.add_child(c)


func _ready() -> void:
	z_index = 4
	_sp = Sprite2D.new()
	_sp.texture = load("res://assets/sprites/loot/spray.png")
	_sp.scale = Vector2.ONE * SpriteBook.DRAW_SCALE * 0.8
	_sp.offset = Vector2(0, -float(_sp.texture.get_height()) * 0.5)
	_sp.texture_filter = SpriteBook.world_filter()
	add_child(_sp)
	var glow := PointLight2D.new()
	glow.texture = LightRig.radial_tex()
	glow.texture_scale = 0.3
	glow.color = Color(1.0, 0.9, 0.3)
	glow.energy = 0.7
	glow.position = Vector2(0, -8)
	add_child(glow)


func _process(delta: float) -> void:
	_t += delta
	_sp.position.y = -3.0 - 2.0 * sin(_t * 3.0)
	_sp.rotation = 0.15 * sin(_t * 2.0)
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D and (n as Node2D).global_position.distance_to(global_position) < 26.0:
			_take()
			return


func _take() -> void:
	var got: Array = FamilyProfile.data.get("tags_" + map_id, [])
	got.append(idx)
	FamilyProfile.data["tags_" + map_id] = got
	FamilyProfile.data["tags_total"] = int(FamilyProfile.data.get("tags_total", 0)) + 1
	FamilyProfile.add_gold(15)
	var all: int = (SPOTS.get(map_id, []) as Array).size()
	Juice.play("res://assets/audio/spray.wav" if ResourceLoader.exists("res://assets/audio/spray.wav") else "res://assets/audio/cling_ok.wav")
	Juice.toast("reward", "TAGGED  %d / %d" % [got.size(), all], "+15 gold. The family mark is on the wall.")
	if got.size() >= all:
		FamilyProfile.add_gems(1)
		FamilyProfile.grant_cosmetic("badge", "badge_tagger", false)
		Juice.unlock_logo("TAGGER", "Every can on %s. The street knows your name." % map_id.replace("_", " ").to_upper(), "ALL TAGS  ·  +1 GEM")
	FamilyProfile.save()
	_paint_tag(get_parent(), position, false)
	queue_free()


## The family mark sprayed on the wall behind where the can was.
static func _paint_tag(host: Node, at: Vector2, instant: bool) -> void:
	var l := Label.new()
	l.text = "H&T"
	l.add_theme_font_override("font", UiKit.title_font())
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.9, 0.2, 0.5, 0.8))
	l.add_theme_constant_override("outline_size", 8)
	l.scale = Vector2(0.5, 0.5)
	l.rotation = -0.12
	l.position = at + Vector2(-26, -70 if at.y > 300.0 else -54)
	l.z_index = -1
	host.add_child(l)
	if not instant:
		l.modulate.a = 0.0
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.6)
