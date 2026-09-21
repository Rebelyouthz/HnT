class_name RunState
extends Node

var lives: int = 3
var checkpoint := Vector2(220, 490)
var failed: bool = false
var cleared: bool = false

signal lives_changed
signal run_failed
signal run_cleared


func mark_checkpoint(pos: Vector2) -> void:
	checkpoint = pos


func spend_life() -> void:
	if failed or cleared:
		return
	lives = maxi(0, lives - 1)
	lives_changed.emit()
	if lives <= 0:
		failed = true
		run_failed.emit()


func clear_run() -> void:
	if failed or cleared:
		return
	cleared = true
	run_cleared.emit()
