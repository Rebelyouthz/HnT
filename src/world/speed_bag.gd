class_name SpeedBag
extends Node2D

## The little speed bag on its stand (dojo mat, training alley): stand at it
## and throw quick hands. Each blow knocks it round the swivel - forward,
## rebound off the board, back - with a leather tick; keep the rhythm going
## and the streak counts up over it (x5, x10 ...). Painted by
## tools/paint_bag.py (6 frames of the rebound, frame 0 is at rest).

const SHEET := "res://assets/sprites/yard/props/speed_bag.png"
const FRAMES := 6
const REACH := 74.0
## World height of the board: about head height on the heroes.
const BOARD_Y := -104.0
const RHYTHM := 0.75

var streak := 0
var _spr: Sprite2D
var _seen := {}
var _t := 0.0
var _anim := -1.0
var _last_hit := -9.0


func _ready() -> void:
	z_index = 0
	var tex := load(SHEET) as Texture2D
	_draw_stand()
	if tex == null:
		return
	_spr = Sprite2D.new()
	_spr.texture = tex
	_spr.hframes = FRAMES
	_spr.frame = 0
	_spr.centered = true
	_spr.scale = Vector2.ONE * SpriteBook.DRAW_SCALE
	_spr.texture_filter = SpriteBook.world_filter()
	# The sheet's board sits 13 px from its top: pin the board to BOARD_Y.
	_spr.position = Vector2(0, BOARD_Y + (float(tex.get_height()) * 0.5 - 13.0) * SpriteBook.DRAW_SCALE)
	add_child(_spr)


## A steel post and arm from the floor up to the board, with a foot plate.
func _draw_stand() -> void:
	var steel := Color(0.2, 0.22, 0.27)
	var hi := Color(0.42, 0.46, 0.53)
	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-12, 0), Vector2(-12, BOARD_Y - 2), Vector2(-16, BOARD_Y - 2)])
	post.color = steel
	add_child(post)
	var lit := Polygon2D.new()
	lit.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-15, 0), Vector2(-15, BOARD_Y - 2), Vector2(-16, BOARD_Y - 2)])
	lit.color = hi
	add_child(lit)
	var foot := Polygon2D.new()
	foot.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-2, 0), Vector2(-4, -3), Vector2(-24, -3)])
	foot.color = steel.darkened(0.3)
	add_child(foot)
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(-14 + cos(a) * 18.0, 1 + sin(a) * 3.0))
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.z_index = -1
	add_child(shadow)


func _physics_process(delta: float) -> void:
	_t += delta
	if _anim >= 0.0 and _spr != null:
		# Five quick rebound frames, then it settles back to rest.
		_anim += delta * 26.0
		var fr := int(_anim) + 1
		if fr >= FRAMES:
			_anim = -1.0
			_spr.frame = 0
		else:
			_spr.frame = fr
	if _t - _last_hit > RHYTHM * 1.6 and streak > 0:
		streak = 0
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter):
			continue
		var f := n as Fighter
		var id := f.get_instance_id()
		var bt := float(f.last_btn_t)
		if float(_seen.get(id, bt)) == bt:
			_seen[id] = bt
			continue
		_seen[id] = bt
		var dx := global_position.x - f.global_position.x
		if absf(dx) > REACH or absf(f.global_position.y - global_position.y) > 26.0:
			continue
		if signf(dx) != float(f.facing) and absf(dx) > 10.0:
			continue
		_hit(f)


func _hit(f: Fighter) -> void:
	_anim = 0.0
	streak = streak + 1 if _t - _last_hit < RHYTHM else 1
	_last_hit = _t
	Mixer.play_sfx("res://assets/audio/sfx/punch_light.ogg", 1.25 + 0.04 * float(mini(streak, 10)), -9.0)
	if streak >= 5 and streak % 5 == 0:
		Juice.popup_number(global_position + Vector2(0, BOARD_Y - 30.0), "SPEED x%d" % streak, Color(1.0, 0.86, 0.4).lerp(Color(1.0, 0.45, 0.3), clampf(float(streak) / 30.0, 0.0, 1.0)))
		if streak % 10 == 0:
			Mixer.play_sfx("res://assets/audio/sfx/combo_sting.ogg", 1.0, -10.0)
	if f != null and f.has_method("gain_hit"):
		f.gain_hit("light")
