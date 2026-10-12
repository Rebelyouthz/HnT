class_name SurviveChest
extends Area2D

var _pop: ChestPop
var _taken := false


func _ready() -> void:
	add_to_group("survive_chests")
	add_to_group("map_pins")
	set_meta("pin", "chest")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(36, 28)
	cs.shape = r
	add_child(cs)
	_pop = ChestPop.make(self, false, Color(1.0, 0.82, 0.3))
	body_entered.connect(_open)
	Juice.popup_number(global_position, "CHEST", Palette.EDGE)


func _open(b: Node) -> void:
	if not (b is Fighter) or _taken:
		return
	_taken = true
	set_deferred("monitoring", false)
	remove_from_group("map_pins")
	remove_from_group("survive_chests")
	_pop.open(_pay.bind(b))


func _pay(b: Node) -> void:
	if not is_instance_valid(b):
		return
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_scrap"):
		rs.add_scrap(8)
	if rs and rs.has_method("add_xp") and SurviveRun.get_run(get_tree()) == null:
		rs.add_xp(22)
	if rs and rs.has_method("add_points"):
		rs.add_points((b as Fighter).role, 80, "chest")
	Rarity.juice("rare", "COPING CHEST")
	Juice.unlock_logo("COPING CHEST", "Halls of Torment called. It wants its loot table back.")
	Juice.toast("reward", "CHEST  ·  RARE", "Scrap, XP, and a worse personality.")
	var srun := SurviveRun.get_run(get_tree())
	if srun:
		srun.open_item_chest()
	elif rs and rs.has_signal("need_cards"):
		rs.emit_signal("need_cards")
	# The chest art fades on its own; drop the trigger after it.
	get_tree().create_timer(1.8, true, false, true).timeout.connect(queue_free)
