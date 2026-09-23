class_name PowerGate
extends Area2D

## Street wall when Night Class still owes a camp buy. Smash stays legal.

var line := "LOCKED"
var _shown := false


static func place(host: Node, at: Vector2, lock_line: String) -> PowerGate:
	var g := PowerGate.new()
	g.line = lock_line
	g.global_position = at
	host.add_child(g)
	return g


func _ready() -> void:
	add_to_group("power_gate")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(80, 140)
	cs.shape = r
	cs.position = Vector2(0, -40)
	add_child(cs)
	if not SpriteBook.attach_living(self, "power_gate", -40.0):
		var post := ColorRect.new()
		post.color = Palette.BRICK
		post.size = Vector2(10, 96)
		post.position = Vector2(-5, -96)
		add_child(post)
		var board := ColorRect.new()
		board.color = Color(0.08, 0.07, 0.1, 0.95)
		board.size = Vector2(72, 28)
		board.position = Vector2(-36, -118)
		add_child(board)
	body_entered.connect(_on_body)


func _on_body(n: Node) -> void:
	if _shown or not (n is Fighter):
		return
	_shown = true
	_card()


func _card() -> void:
	var host := get_tree().get_first_node_in_group("run_act")
	if host == null:
		return
	if host.has_method("lock_boss_card"):
		host.call("lock_boss_card", line)
		return
	Juice.toast("challenge", "LOCKED", line)
