class_name ActBoss
extends Punk

var display := ""
var is_mini := false
var accent := Color(0.72, 0.22, 0.2)
var sub := ""
var introed := false


func _ready() -> void:
	if title == "":
		title = display if display != "" else "Named Problem"
	super._ready()
	add_to_group("act_boss")
	if is_mini:
		add_to_group("act_mini")
	else:
		add_to_group("act_final_boss")
	armored = not is_mini
	_crown()
	died.connect(_on_dead)


func _crown() -> void:
	var band := Polygon2D.new()
	band.color = accent
	band.polygon = PackedVector2Array([
		Vector2(-22, -86), Vector2(22, -86), Vector2(16, -70), Vector2(-16, -70)
	])
	Blockout.add_glow(band)
	visual.add_child(band)
	visual.modulate = accent.lerp(Color.WHITE, 0.35)


func _on_dead() -> void:
	var act := get_tree().get_first_node_in_group("run_act")
	if is_mini:
		Juice.toast("challenge", "MINI DOWN", "%s filed. The street keeps going. That's the bit." % title.to_upper())
		Juice.shout("MINI FILED")
		if act and act.has_method("on_mini_down"):
			act.on_mini_down()
		return
	Juice.toast("quest", "BOSS FILED", "%s is a receipt now." % title.to_upper())
	if act and act.has_method("finish_boss"):
		act.finish_boss()
