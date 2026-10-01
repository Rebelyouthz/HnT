class_name CrewNPC
extends Node2D

## Benny and Rico Vale: the brothers who built the hideout. One painted
## sprite each (assets/sprites/crew/<who>.png), brought to life in code:
## breathing, a head-turn toward the player, walking with a step bob, and
## Benny's hammer swing (a drawn hammer in his hand) for live construction.
## role / hop make Talk put speech bubbles over their heads.

const BODY_H := 44.0

var role := "benny"
var hop := 0.0
var facing := 1
var _spr: Sprite2D
var _hammer: Node2D
var _t := 0.0
var _swing := 0.0
var _walk := 0.0
var hammering := false


static func texture_of(who: String) -> Texture2D:
	var p := "res://assets/sprites/crew/%s.png" % who
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


## Head-and-shoulders crop for portraits / docked speech bubbles.
static func bust(who: String) -> Texture2D:
	var t := texture_of(who)
	if t == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = t
	at.region = Rect2(0, 0, t.get_width(), t.get_height() * 0.4)
	return at


func setup(who: String) -> void:
	role = who
	add_to_group("players")
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * 14.0, sin(a) * 3.2))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.42)
	sh.position = Vector2(0, 2)
	add_child(sh)
	var tex := texture_of(who)
	_spr = Sprite2D.new()
	_spr.texture = tex
	_spr.centered = false
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if tex != null:
		var k := BODY_H / float(tex.get_height())
		_spr.scale = Vector2(k, k)
		_spr.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()))
	add_child(_spr)
	if who == "benny":
		_hammer = Node2D.new()
		_hammer.position = Vector2(8, -24)
		var handle := Polygon2D.new()
		handle.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(1, 0), Vector2(1, -13), Vector2(-1, -13)])
		handle.color = Color(0.45, 0.28, 0.14)
		_hammer.add_child(handle)
		var head := Polygon2D.new()
		head.polygon = PackedVector2Array([Vector2(-4, -16), Vector2(5, -16), Vector2(5, -12), Vector2(-4, -12)])
		head.color = Color(0.55, 0.57, 0.62)
		_hammer.add_child(head)
		_hammer.visible = false
		add_child(_hammer)


func face(dir: int) -> void:
	facing = 1 if dir >= 0 else -1


func walk_to(x: float, speed := 70.0) -> Tween:
	face(1 if x > position.x else -1)
	var tw := create_tween()
	var dur := absf(x - position.x) / speed
	_walk = 1.0
	tw.tween_property(self, "position:x", x, maxf(0.05, dur))
	tw.tween_callback(func() -> void: _walk = 0.0)
	return tw


func _process(delta: float) -> void:
	_t += delta
	if _spr == null:
		return
	_spr.flip_h = facing < 0
	var breathe := 1.0 + 0.012 * sin(_t * 2.4)
	var bob := 0.0
	if _walk > 0.0:
		bob = -absf(sin(_t * 11.0)) * 1.6
		_spr.rotation = sin(_t * 11.0) * 0.03
	else:
		_spr.rotation = 0.0
	var base := BODY_H / float(maxi(1, _spr.texture.get_height())) if _spr.texture else 1.0
	_spr.scale = Vector2(base, base * breathe)
	_spr.position = Vector2(0, bob)
	if _hammer:
		_hammer.visible = hammering
		_hammer.position.x = 8.0 * float(facing)
		_hammer.scale.x = float(facing)
		if hammering:
			_swing += delta * 9.0
			# Wind up slow, strike fast: a hammer, not a metronome.
			var ph := fmod(_swing, TAU)
			var ang := -1.6 + (1.9 if ph < 0.9 else 1.9 * (1.0 - (ph - 0.9) / (TAU - 0.9)))
			_hammer.rotation = ang * float(facing)
			_spr.rotation = 0.04 * sin(_swing) * float(facing)
