class_name CrowdAI
extends RefCounted

## Street-fight crowd rules (the Streets of Rage way): only a couple of thugs
## may go for a hero at once - they hold ATTACK TICKETS. The rest stand off in
## a loose ring around the hero (in front, behind, up and down the lane),
## shuffling and waiting for a ticket. Bosses, minis, vehicles and anyone who
## throws or shoots always act on their own.

const TICKETS := 2
const RING := 118.0
const REFRESH := 0.4

static var _tickets: Dictionary = {}   # hero instance id -> Array of punk ids
static var _t := 0.0
static var _frame := -1


## "attack" or "wait" for thug `e` going for hero `t`.
static func role(e: Punk, t: Node2D) -> String:
	if e is ActBoss or e.vehicle != "" or e.home != "street":
		return "attack"
	var k := str(e.kit.get("attack", ""))
	if k in ["gun", "grenade"]:
		return "attack"
	# The survivor horde swarms: crowd rules are for the story streets.
	if SurviveRun.get_run(e.get_tree()) != null:
		return "attack"
	_refresh(e.get_tree())
	var list: Array = _tickets.get(t.get_instance_id(), [])
	return "attack" if list.has(e.get_instance_id()) else "wait"


static func _refresh(tree: SceneTree) -> void:
	var f := Engine.get_physics_frames()
	if f == _frame:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _t < REFRESH and _frame >= 0:
		_frame = f
		return
	_t = now
	_frame = f
	_tickets.clear()
	var heroes: Array = []
	for n in tree.get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			heroes.append(n)
	if heroes.is_empty():
		return
	# Every melee thug queues on its nearest hero; the closest ones (and the
	# ones already mid-swing) get the tickets.
	var queues := {}
	for n in tree.get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var e := n as Punk
		if e.hp <= 0 or e is ActBoss or e.home != "street" or e.has_meta("scoot") or e.has_meta("dragging"):
			continue
		var best: Node2D = null
		var bd := 99999.0
		for h in heroes:
			var d := (h as Node2D).global_position.distance_to(e.global_position)
			if d < bd:
				bd = d
				best = h
		if best == null:
			continue
		if e.telegraph > 0.0:
			bd -= 1000.0
		var q: Array = queues.get(best.get_instance_id(), [])
		q.append([bd, e.get_instance_id()])
		queues[best.get_instance_id()] = q
	for hid in queues:
		var q: Array = queues[hid]
		q.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var ids: Array = []
		for i in mini(TICKETS, q.size()):
			ids.append(q[i][1])
		_tickets[hid] = ids


## Where a waiting thug stands: a spot on a loose ring round the hero, its
## angle fixed per thug (front or behind the hero, up or down the lane), so
## the crowd surrounds instead of queueing.
static func spot(e: Punk, t: Node2D) -> Vector2:
	var seed := e.get_instance_id()
	var side := -1.0 if seed % 2 == 0 else 1.0
	var depth := float((seed / 2) % 3 - 1) * 26.0
	var wob := sin(Time.get_ticks_msec() / 1000.0 * 0.9 + float(seed % 17)) * 14.0
	return t.global_position + Vector2(side * (RING + wob), depth)
