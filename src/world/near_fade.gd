class_name NearFade
extends Node

## Attach to a CanvasItem: it is only seen when a hero comes close (full
## inside `near` px, gone past `far`), so world labels stop crowding the
## street ahead.

var near := 120.0
var far := 260.0


static func on(item: CanvasItem, near_px: float = 120.0, far_px: float = 260.0) -> void:
	if item == null:
		return
	var f := NearFade.new()
	f.near = near_px
	f.far = far_px
	item.add_child(f)
	item.modulate.a = 0.0


func _process(_d: float) -> void:
	var it := get_parent() as CanvasItem
	if it == null:
		return
	var p := (it as Node2D).global_position if it is Node2D else (it as Control).global_position if it is Control else Vector2.ZERO
	var d := 99999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D:
			d = minf(d, absf((n as Node2D).global_position.x - p.x))
	var want := clampf((far - d) / maxf(1.0, far - near), 0.0, 1.0)
	it.modulate.a = lerpf(it.modulate.a, want, 0.12)
