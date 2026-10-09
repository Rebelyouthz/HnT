class_name BossChest
extends Node2D

## The chest a finished mission, a champion or the hour's boss leaves: a
## pixel chest that drops in with a bounce and a rarity glow. Walk into it:
## it bursts open into a reveal and pays S-COINS, often a gear piece and a
## STARTER WEAPON copy (bosses always both). Coins fly to the counter.

var big := false
var _t := 0.0
var _y0 := 0.0
var _open := false
var _pop: ChestPop


static func drop(host: Node, at: Vector2, is_big: bool) -> BossChest:
	var c := BossChest.new()
	c.big = is_big
	c.global_position = at
	host.add_child.call_deferred(c)
	return c


func _ready() -> void:
	add_to_group("map_pins")
	set_meta("pin", "chest")
	z_index = 5
	_pop = ChestPop.make(self, big, Color(1.0, 0.56, 0.12) if big else Color(0.4, 1.0, 0.7))
	_pop.position.y = -120.0
	var tw := create_tween()
	tw.tween_property(_pop, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Juice.popup_number(global_position + Vector2(0, -40), "BOSS CHEST" if big else "MISSION CHEST", UiKit.GOLD)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _open or _t < 0.4:
		return
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and (n as Fighter).global_position.distance_to(global_position) < 26.0:
			_burst()
			return


func _burst() -> void:
	_open = true
	_pop.open(_pay)


func _pay() -> void:
	var at := get_global_transform_with_canvas().origin
	var coins := (45 if big else 18) + randi() % 10
	# The hour's boss always carries a CARD TOKEN; mission chests sometimes.
	if big or randf() < 0.15:
		VaultCards.add_tokens(1, "From the chest. Spend it in the CARD VAULT.")
	Trees.add_tokens(coins)
	Juice.rewards.give("tokens", coins, at + Vector2(0, -20))
	var sub: Array[String] = ["+%d S-COINS" % coins]
	if big or randf() < 0.4:
		var p := SurvGear.drop(0.1 if big else 0.0)
		if not p.is_empty():
			sub.append(str(SurvGear.LIST[str(p["id"])]["name"]))
	if big or randf() < 0.3:
		var pool: Array = []
		for id: String in SurvStarter.LIST:
			if SurvStarter.unlocked(id):
				pool.append(id)
		if not pool.is_empty():
			var sid := SurvStarter.picked() if SurvStarter.picked() != "" and randf() < 0.6 else str(pool[randi() % pool.size()])
			SurvStarter.add_copy(sid)
			sub.append("%s COPY" % sid.replace("_", " ").to_upper())
	Juice.rewards.reveal("cur_chest", "BOSS CHEST" if big else "MISSION CHEST", Color(1.0, 0.56, 0.12) if big else Color(0.4, 1.0, 0.7), "  ·  ".join(sub), 1.2)
	remove_from_group("map_pins")
	get_tree().create_timer(1.8, true, false, true).timeout.connect(queue_free)


func _draw() -> void:
	if _open:
		return
	var c := Color(1.0, 0.56, 0.12) if big else Color(0.4, 1.0, 0.7)
	for i in 8:
		var a := _t * 1.5 + float(i) * TAU / 8.0
		draw_line(Vector2(0, -18), Vector2(0, -18) + Vector2.from_angle(a) * (26.0 + 4.0 * sin(_t * 4.0 + float(i))), Color(c.r, c.g, c.b, 0.25), 2.0)
