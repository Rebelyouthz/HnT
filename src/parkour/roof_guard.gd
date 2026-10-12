class_name RoofGuard
extends Node2D

## A security guard planted on a roof. He turns to face you and winds up a
## swing when you come near. UP near him: kong vault over his head (he goes
## down). DOWN: slide into his legs (he trips). Run into him: you eat the
## baton and stumble.

var down := false
var anim: AnimatedSprite2D
var _t := 0.0


func _ready() -> void:
	anim = SpriteBook.make_anim("cop" if SpriteBook.has_who("cop") else "punk")
	SpriteBook.grow(anim, SpriteBook.ENEMY_SCALE)
	anim.flip_h = true
	add_child(anim)
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * 18.0, 3.0 + sin(a) * 5.0))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.35)
	sh.z_index = -1
	add_child(sh)


## The runner calls this every frame with its x (feet).
func watch(runner_x: float) -> void:
	if down or anim == null:
		return
	var d := position.x - runner_x
	if d > 0.0 and d < 170.0:
		if anim.animation != "attack" and anim.sprite_frames.has_animation("attack"):
			anim.play("attack")
	elif anim.animation != "idle":
		anim.play("idle")


func knock(how: String) -> void:
	if down:
		return
	down = true
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
	var tw := create_tween()
	if how == "kong":
		tw.tween_property(anim, "rotation", -0.9, 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 1.2).set_delay(1.4)
	Mixer.play_sfx("res://assets/audio/sfx/hit_heavy.ogg", randf_range(0.9, 1.05), -4.0)
