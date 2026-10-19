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
## Crew with filmed clips (assets/sprites/<who>/idle + hammer, tools/hf_npc.py)
## play those instead of the one painted still.
var _anim: AnimatedSprite2D
var _body_k := 1.0
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
	if SpriteBook.has_who(who):
		_setup_anim(who)
		return
	var tex := texture_of(who)
	_spr = Sprite2D.new()
	_spr.texture = tex
	_spr.centered = false
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if tex != null:
		# On the street they stand with the townsfolk (NPC_SCALE); films and
		# the hideout keep the base size the scenes were framed for.
		var on_street := Engine.get_main_loop() != null and (Engine.get_main_loop() as SceneTree).get_first_node_in_group("run_act") != null
		var in_camp := Engine.get_main_loop() != null and (Engine.get_main_loop() as SceneTree).current_scene != null and str((Engine.get_main_loop() as SceneTree).current_scene.get_script().resource_path if (Engine.get_main_loop() as SceneTree).current_scene.get_script() else "").ends_with("camp_hideout.gd")
		var k := BODY_H * (SpriteBook.NPC_SCALE if on_street else (1.3 if in_camp else 1.0)) / float(tex.get_height())
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


func _setup_anim(who: String) -> void:
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = SpriteBook.frames(who)
	_anim.centered = true
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Size by the tallest idle body so she stands as tall as the painted crew.
	var tall := 1.0
	for fr: Dictionary in SpriteBook.clip_meta(who, "idle").get("frames", []):
		tall = maxf(tall, float(fr["h"]))
	var tree := Engine.get_main_loop() as SceneTree
	var on_street := tree != null and tree.get_first_node_in_group("run_act") != null
	var in_camp := tree != null and tree.current_scene != null and tree.current_scene.get_script() != null and str(tree.current_scene.get_script().resource_path).ends_with("camp_hideout.gd")
	_body_k = BODY_H * 1.1 * (SpriteBook.NPC_SCALE if on_street else (1.3 if in_camp else 1.0)) / tall
	_anim.scale = Vector2(_body_k, _body_k)
	var cell := _anim.sprite_frames.get_frame_texture("idle", 0)
	_anim.position = Vector2(0, -float(cell.get_height()) * _body_k * 0.5 + 1.0)
	_anim.play("idle")
	_anim.animation_finished.connect(func() -> void: _anim.play("idle"))
	add_child(_anim)


## One filmed swing when she has one (the forge's hammer strike).
func strike() -> void:
	if _anim != null and _anim.sprite_frames.has_animation("hammer"):
		_anim.play("hammer")


## Top of the hair above the feet, in this node's units (SpeechBubble).
func bubble_head() -> float:
	if _anim != null:
		var t := _anim.sprite_frames.get_frame_texture("idle", 0)
		var top := (t as AtlasTexture).margin.position.y if t is AtlasTexture else 0.0
		return float(t.get_height() - top) * _body_k + 6.0
	if _spr == null or _spr.texture == null:
		return BODY_H + 6.0
	return float(_spr.texture.get_height()) * _spr.scale.y + 6.0


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
	if _anim != null:
		_anim.flip_h = facing < 0
		_anim.rotation = 0.0
		# Filmed walk when there is one (no sliding idle across the room).
		var want := "walk" if _walk > 0.0 and _anim.sprite_frames.has_animation("walk") else ""
		if want != "" and _anim.animation != want:
			_anim.play(want)
		elif want == "" and _anim.animation == "walk":
			_anim.play("idle")
		elif _walk > 0.0 and want == "":
			_anim.rotation = sin(_t * 11.0) * 0.03
		# A forge hand never stands still for long: a swing every few seconds.
		if hammering and _anim.animation == "idle" and fmod(_t, 3.2) < delta:
			strike()
		return
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
