class_name SpriteBook
extends Object

## Pixel sheets for Father, Son, Dock Street, Intake Lot, hub icons, punk, skinwalker.

static var _frames: Dictionary = {}
static var _tex: Dictionary = {}

## 4.5 texels per world unit. The couch camera zooms 1.5x, so a 1080p window
## (3x of 640x360) shows every texel 1:1. Props are 216 px cells, actors
## >= 288 px, tiles 144 px.
const CELL := 216.0
const DRAW_SCALE := 1.0 / 4.5
## attach_scaled callers speak in the old 96 px cell (1 texel per world unit).
const LEGACY_CELL := 96.0

const LOOP := {
	"idle": true,
	"walk": true,
	"parkour_run": true,
	"duck": true,
	"dog": true,
	"crawl": true,
	"lamp": true
}


## Nearest when the stretch lands on an exact multiple of 3x (texels 1:1 or
## 2:2 under the 1.5x camera); trilinear otherwise so 720p/1440p/phones never
## drop or double texels.
static func world_filter() -> CanvasItem.TextureFilter:
	var win := DisplayServer.window_get_size()
	var k := minf(float(win.x) / 640.0, float(win.y) / 360.0)
	var whole := roundi(k)
	if whole >= 3 and whole % 3 == 0 and absf(k - float(whole)) < 0.01:
		return CanvasItem.TEXTURE_FILTER_NEAREST
	return CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Portraits and icons are always shrunk into UI boxes.
const UI_FILTER := CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


static func has_who(who: String) -> bool:
	return FileAccess.file_exists("res://assets/sprites/%s/idle.json" % who) or FileAccess.file_exists("res://assets/sprites/%s/dog.json" % who)


## Every clip is one packed sheet (<clip>.png) plus <clip>.json: the logical
## cell and, per frame, its trimmed region in the sheet and its offset inside
## the cell. AtlasTexture margins restore the full cell, so AnimatedSprite2D
## sees fixed-size frames while memory holds only the trimmed pixels.
static func frames(who: String) -> SpriteFrames:
	if _frames.has(who):
		return _frames[who] as SpriteFrames
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var root := "res://assets/sprites/%s" % who
	var d := DirAccess.open(root)
	if d == null:
		_frames[who] = sf
		return sf
	var clips: PackedStringArray = []
	for f in d.get_files():
		if f.ends_with(".json"):
			clips.append(f.get_basename())
	clips.sort()
	for clip in clips:
		_add_clip(sf, root, clip)
	_frames[who] = sf
	return sf


static func clip_meta(who: String, clip: String) -> Dictionary:
	var path := "res://assets/sprites/%s/%s.json" % [who, clip]
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


static func _clip_textures(root: String, clip: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var meta_path := "%s/%s.json" % [root, clip]
	var sheet_path := "%s/%s.png" % [root, clip]
	if not FileAccess.file_exists(meta_path) or not ResourceLoader.exists(sheet_path):
		return out
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	var sheet := load(sheet_path) as Texture2D
	if not (parsed is Dictionary) or sheet == null:
		return out
	var meta := parsed as Dictionary
	var cell: Array = meta.get("cell", [0, 0])
	var cw := float(cell[0])
	var ch := float(cell[1])
	for fr: Dictionary in meta.get("frames", []):
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(float(fr["x"]), float(fr["y"]), float(fr["w"]), float(fr["h"]))
		at.margin = Rect2(float(fr["ox"]), float(fr["oy"]), cw - float(fr["w"]), ch - float(fr["h"]))
		at.filter_clip = true
		out.append(at)
	return out


static func _add_clip(sf: SpriteFrames, root: String, clip: String) -> void:
	var texs := _clip_textures(root, clip)
	if texs.is_empty():
		return
	sf.add_animation(clip)
	sf.set_animation_loop(clip, LOOP.has(clip))
	var spd := 10.0
	if clip == "idle" or clip == "dog":
		spd = 6.0
	if "/lamp" in root:
		spd = 4.0
	elif "/bystander" in root and clip == "idle":
		spd = 5.0
	elif clip == "parkour_run" or clip == "attack":
		spd = 14.0
	elif clip == "jab" or clip == "cross" or clip == "gut" or clip == "front_kick" or clip == "side_kick":
		spd = 16.0
	elif clip == "heavy" or clip == "roundhouse" or clip == "snap":
		spd = 12.0
	sf.set_animation_speed(clip, spd)
	for t in texs:
		sf.add_frame(clip, t)


## Head-and-shoulders crop of the first idle cel (no empty cell margin),
## for small portrait slots.
static func bust(who: String, frac: float = 0.42) -> Texture2D:
	var f := face(who)
	if not (f is AtlasTexture):
		return f
	var at := f as AtlasTexture
	var r := at.region
	var b := AtlasTexture.new()
	b.atlas = at.atlas
	b.region = Rect2(r.position, Vector2(r.size.x, maxf(8.0, r.size.y * frac)))
	b.filter_clip = true
	return b


## First idle cel, for portraits (hub faces, boss cards, locker).
static func face(who: String) -> Texture2D:
	var sf := frames(who)
	for clip in ["idle", "dog"]:
		if sf.has_animation(clip) and sf.get_frame_count(clip) > 0:
			return sf.get_frame_texture(clip, 0)
	return null


static func make_anim(who: String) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.name = "Anim"
	a.sprite_frames = frames(who)
	a.centered = true
	a.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
	# Feet sit 2 texels above the cell floor; keep them ~3.5 units below the
	# actor origin whatever the cell height (the 96 px era used y = -20).
	var cell_h := CELL
	var sfr := a.sprite_frames
	for clip in ["idle", "dog"]:
		if sfr.has_animation(clip) and sfr.get_frame_count(clip) > 0:
			cell_h = float(sfr.get_frame_texture(clip, 0).get_height())
			break
	a.position = Vector2(0, 4.0 - cell_h * DRAW_SCALE * 0.5)
	a.texture_filter = world_filter()
	if a.sprite_frames.has_animation("idle"):
		a.play("idle")
	elif a.sprite_frames.has_animation("dog"):
		a.play("dog")
	return a


static func hide_polys(n: Node) -> void:
	if n == null:
		return
	for c in n.get_children():
		if c is Polygon2D or c is ColorRect:
			(c as CanvasItem).visible = false


static func attach_living(host: Node, who: String, extra_y: float = 0.0) -> bool:
	if host == null or who == "" or not has_who(who):
		return false
	hide_polys(host)
	var a := make_anim(who)
	a.position.y += extra_y
	host.add_child(a)
	return true


static func attach_scaled(host: Node, who: String, extra_y: float, scl: Vector2) -> bool:
	if host == null or who == "" or not has_who(who):
		return false
	hide_polys(host)
	var a := make_anim(who)
	a.scale = scl * (LEGACY_CELL / CELL)
	a.position.y += extra_y
	host.add_child(a)
	return true


static func tex(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path] as Texture2D
	if not ResourceLoader.exists(path):
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
	s.texture_filter = world_filter()
	host.add_child(s)
	return s
