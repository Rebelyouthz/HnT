class_name OverheadBadge
extends Sprite2D

## A small badge floating above a thug's head (not on it): BOUNTY (gold
## coin shield), ELITE (purple chevrons), BOSS (red skull). It follows the
## drawn head, bobs, and hides while its wearer is lying down.

var _anim: AnimatedSprite2D
var _t := 0.0


static func attach(p: Node2D, kind: String) -> OverheadBadge:
	if p == null:
		return null
	for c in p.get_children():
		if c is OverheadBadge:
			c.queue_free()
	var path := "res://assets/sprites/ui/badge_%s.png" % kind
	if not ResourceLoader.exists(path):
		return null
	var b := OverheadBadge.new()
	b.texture = load(path)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.scale = Vector2.ONE * 0.28
	b.z_index = 30
	var cm := CanvasItemMaterial.new()
	cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	b.material = cm
	b._anim = p.get("_anim") as AnimatedSprite2D
	p.add_child(b)
	return b


func _process(delta: float) -> void:
	_t += delta
	var top := -80.0
	if _anim != null and is_instance_valid(_anim):
		visible = not (str(_anim.animation) in ["knockdown", "death", "getup"])
		var hd := BloodSim.head_of(_anim)
		var vis := _anim.get_parent() as Node2D
		top = _anim.position.y + (hd.y - hd.z * 1.1) * absf(_anim.scale.y) + (vis.position.y if vis else 0.0)
	position = Vector2(0, top - 14.0 + 1.5 * sin(_t * 3.0))
