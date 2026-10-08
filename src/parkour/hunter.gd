class_name Hunter
extends Node2D

## The man after you. He runs your own line a few seconds behind: every
## jump, vault and climb you made, he makes too. His lag is your safety
## margin - slow down, bump, bail or land hard and it shrinks; perfect
## tricks and landings stretch it. When it runs out he has you.

const START_LAG := 2.0
const MAX_LAG := 2.8
const CATCH := 0.28

var target: Runner
var lag := START_LAG
var active := false
var anim: AnimatedSprite2D
var _trail: Array = []   # [t, pos, rot, state]
var _t := 0.0
var _last := Vector2.ZERO


func _ready() -> void:
	z_index = 1
	anim = SpriteBook.make_anim("bailiff" if SpriteBook.has_who("bailiff") else "cop")
	SpriteBook.grow(anim, SpriteBook.ENEMY_SCALE * 1.05)
	add_child(anim)
	modulate = Color(0.85, 0.82, 0.95)
	visible = false


func record(delta: float) -> void:
	if target == null:
		return
	_t += delta
	_trail.append([_t, target.position, target.pivot.rotation, target.state])
	while _trail.size() > 2 and float(_trail[0][0]) < _t - MAX_LAG - 1.0:
		_trail.pop_front()


## Shift the margin (seconds). Positive = more room.
func nudge(dt: float) -> void:
	lag = clampf(lag + dt, 0.0, MAX_LAG)


func tick(delta: float) -> bool:
	if not active or target == null or _trail.is_empty():
		return false
	# Holding near top speed buys time slowly; dawdling gives it away.
	var pace := clampf(target.vx / Runner.TOP, 0.0, 1.3)
	nudge((pace - 0.8) * 0.3 * delta)
	var want := _t - lag
	var p: Vector2 = _trail[0][1]
	var rot := 0.0
	for i in range(_trail.size() - 1, -1, -1):
		if float(_trail[i][0]) <= want:
			p = _trail[i][1]
			rot = float(_trail[i][2]) * 0.5
			break
	var v := (p - _last) / maxf(delta, 0.001)
	_last = p
	position = p
	visible = true
	anim.rotation = rot
	if absf(v.x) > 20.0:
		if anim.animation != "walk":
			anim.play("walk")
		anim.speed_scale = clampf(absf(v.x) / 110.0, 0.8, 3.2)
	elif anim.animation != "idle":
		anim.play("idle")
	return lag <= CATCH
