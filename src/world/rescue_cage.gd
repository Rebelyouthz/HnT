class_name RescueCage
extends Area2D

## A crew member held by the collectors: a padlocked impound cage with Benny
## or Rico behind the bars. Hit it (any strike) until the lock gives: bars
## fly, the brother steps out, says his piece in speech bubbles and heads to
## the hideout (FamilyProfile "crew_<who>"). One per story map (data/story.json
## acts.<map>.rescue).

const HP := 5

var who := "benny"
var lines: Array = []
var _hp := HP
var _npc: CrewNPC
var _bars: Node2D
var _lock: PixelIcon
var _open := false
var _sign: Label


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitorable = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(44, 56)
	cs.shape = r
	cs.position = Vector2(0, -28)
	add_child(cs)
	_npc = CrewNPC.new()
	_npc.setup(who)
	_npc.remove_from_group("players")
	_npc.face(-1)
	add_child(_npc)
	_bars = Node2D.new()
	add_child(_bars)
	var frame_c := Color(0.16, 0.16, 0.18)
	var lit := Color(0.48, 0.46, 0.46)
	_rect(_bars, Rect2(-24, -58, 48, 4), frame_c)
	_rect(_bars, Rect2(-24, -2, 48, 4), frame_c)
	for i in 7:
		var x := -22.0 + float(i) * 7.3
		_rect(_bars, Rect2(x, -56, 2.4, 55), frame_c)
		_rect(_bars, Rect2(x, -56, 0.8, 55), lit)
	_lock = PixelIcon.new()
	_lock.kind = "lock"
	_lock.size = Vector2(14, 14)
	_lock.position = Vector2(-7, -34)
	_lock.scale = Vector2.ONE
	_bars.add_child(_lock)
	_sign = NightStreet.plaque(self, Vector2(-30, -78), "HELP  ·  %s" % StoryBook.who_name(who), Talk.accent(who), 10)
	add_to_group("rescue_cage")


func _rect(host: Node2D, r: Rect2, c: Color) -> void:
	var p := Polygon2D.new()
	p.color = c
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	host.add_child(p)


func take_hit(_kind: String, _from: Node) -> void:
	if _open:
		return
	_hp -= 1
	Juice.play("res://assets/audio/smash.wav")
	Juice.sparks(global_position + Vector2(0, -34))
	var tw := create_tween()
	tw.tween_property(_bars, "position:x", 2.0, 0.03)
	tw.tween_property(_bars, "position:x", -2.0, 0.05)
	tw.tween_property(_bars, "position:x", 0.0, 0.03)
	if _hp <= 0:
		_break_open()


func _break_open() -> void:
	_open = true
	Juice.pulse_shake(6.0)
	Juice.hitstop(6)
	# Bars fly apart, the lock spins off.
	for c in _bars.get_children():
		if c is CanvasItem:
			var n := c as Node2D
			var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.4, -0.4)).normalized()
			var t2 := n.create_tween().set_parallel(true)
			t2.tween_property(n, "position", n.position + dir * randf_range(30.0, 70.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t2.tween_property(n, "rotation", randf_range(-3.0, 3.0), 0.55)
			t2.tween_property(n, "modulate:a", 0.0, 0.6)
	_sign.queue_free()
	FamilyProfile.data["crew_" + who] = true
	FamilyProfile.save()
	_npc.add_to_group("players")
	_npc.face(-1)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		var act := get_tree().get_first_node_in_group("run_act")
		var talk: Variant = act.get("_talk") if act != null else null
		if talk is Talk and not lines.is_empty():
			(talk as Talk).play(lines, true)
		Juice.toast("reward", "%s JOINS THE HIDEOUT" % StoryBook.who_name(who), str((StoryBook.all().get("crew", {}) as Dictionary).get(who, {}).get("job", "")))
	)
	tw.tween_interval(7.0)
	tw.tween_callback(func() -> void:
		# Off to the hideout.
		_npc.walk_to(_npc.position.x + 260.0, 90.0)
	)
	tw.tween_interval(3.2)
	tw.tween_callback(queue_free)
