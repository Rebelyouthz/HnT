class_name ProxFade
extends Node

## Fades its parent CanvasItem in only while a player is near (world hint
## plaques, sign text): the street reads clean from a distance and the
## words come up when they matter.

const NEAR := 230.0
const FAR := 380.0

var _host: CanvasItem
var _base := 1.0


static func attach(item: CanvasItem) -> void:
	var p := ProxFade.new()
	p.name = "ProxFade"
	item.add_child(p)


func _ready() -> void:
	_host = get_parent() as CanvasItem
	if _host:
		_base = _host.modulate.a
		_host.modulate.a = 0.0


func _process(delta: float) -> void:
	if _host == null or not (_host is Node2D or _host is Control):
		return
	var at: Vector2 = (_host as Node2D).global_position if _host is Node2D else (_host as Control).global_position
	var best := 99999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D:
			best = minf(best, absf((n as Node2D).global_position.x - at.x))
	var want := _base * clampf((FAR - best) / (FAR - NEAR), 0.0, 1.0)
	_host.modulate.a = move_toward(_host.modulate.a, want, delta * 3.0)
