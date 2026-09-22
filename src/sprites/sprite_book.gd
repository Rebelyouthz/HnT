class_name SpriteBook
extends Object

## Pixel sheets for Father, Son, Dock Street, Intake Lot, hub icons, punk, skinwalker.

static var _frames: Dictionary = {}
static var _tex: Dictionary = {}

const DRAW_SCALE := 0.5

const LOOP := {
	"idle": true,
	"walk": true,
	"parkour_run": true,
	"duck": true,
	"dog": true,
	"crawl": true
}


static func has_who(who: String) -> bool:
	return FileAccess.file_exists("res://assets/sprites/%s/idle/00.png" % who) or FileAccess.file_exists("res://assets/sprites/%s/dog/00.png" % who)


static func frames(who: String) -> SpriteFrames:
	if _frames.has(who):
		return _frames[who] as SpriteFrames
	var sf := SpriteFrames.new()
	var root := "res://assets/sprites/%s" % who
	var d := DirAccess.open(root)
	if d == null:
		_frames[who] = sf
		return sf
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if d.current_is_dir() and not name.begins_with("."):
			_add_clip(sf, root, name)
		name = d.get_next()
	d.list_dir_end()
	_frames[who] = sf
	return sf


static func _add_clip(sf: SpriteFrames, root: String, clip: String) -> void:
	var dir := "%s/%s" % [root, clip]
	var i := 0
	var texs: Array[Texture2D] = []
	while i < 16:
		var path := "%s/%02d.png" % [dir, i]
		if not FileAccess.file_exists(path):
			break
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			texs.append(loaded as Texture2D)
		i += 1
	if texs.is_empty():
		return
	sf.add_animation(clip)
	sf.set_animation_loop(clip, LOOP.has(clip))
	var spd := 10.0
	if clip == "idle" or clip == "dog":
		spd = 6.0
	elif clip == "parkour_run" or clip == "attack":
		spd = 14.0
	elif clip == "jab" or clip == "cross" or clip == "gut" or clip == "front_kick" or clip == "side_kick":
		spd = 16.0
	elif clip == "heavy" or clip == "roundhouse" or clip == "snap":
		spd = 12.0
	sf.set_animation_speed(clip, spd)
	for t in texs:
		sf.add_frame(clip, t)


static func make_anim(who: String) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.name = "Anim"
	a.sprite_frames = frames(who)
	a.centered = true
	a.position = Vector2(0, -20)
	a.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
	a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if a.sprite_frames.has_animation("idle"):
		a.play("idle")
	elif a.sprite_frames.has_animation("dog"):
		a.play("dog")
	return a


static func hide_polys(n: Node) -> void:
	if n == null:
		return
	for c in n.get_children():
		if c is Polygon2D:
			(c as CanvasItem).visible = false


static func tex(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path] as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var loaded: Variant = load(path)
	if loaded is Texture2D:
		_tex[path] = loaded
		return loaded as Texture2D
	return null


static func prop(kind: String) -> Texture2D:
	var a := tex("res://assets/sprites/dock/props/%s.png" % kind)
	if a:
		return a
	a = tex("res://assets/sprites/dock/toys/%s.png" % kind)
	if a:
		return a
	return tex("res://assets/sprites/lot/props/%s.png" % kind)


static func tile(kind: String) -> Texture2D:
	var a := tex("res://assets/sprites/dock/tiles/%s.png" % kind)
	if a:
		return a
	return tex("res://assets/sprites/lot/tiles/%s.png" % kind)


static func icon(id: String) -> Texture2D:
	return tex("res://assets/sprites/hub/%s.png" % id)


static func stamp(host: Node, kind: String, at: Vector2, z: int = 2) -> Sprite2D:
	var t := prop(kind)
	if t == null:
		t = tile(kind)
	if t == null:
		return null
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
	s.position = at + Vector2(-float(t.get_width()) * 0.5 * DRAW_SCALE, -float(t.get_height()) * DRAW_SCALE)
	s.z_index = z
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	host.add_child(s)
	return s
