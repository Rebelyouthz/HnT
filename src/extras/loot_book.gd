class_name LootBook
extends RefCounted

## What story-mode chests and secret stashes can hold beyond gold: something
## you don't own yet, picked at random -
##   MOVE        a strike from the move library (learned for free)
##   GUN PART    a Gunsmith part (owned, fits any gun)
##   SUIT PART   a mask / top / bottom from a hero suit
##   THROWABLE   a stack of molotovs, flashbangs, bricks or teargas
## Everything already owned falls back to gems.

const THROWS := {"molotov": 3, "flashbang": 2, "brick": 5, "teargas": 2}


static func roll(role: String, allow_throw := true) -> Dictionary:
	var pool: Array = []
	for r: Dictionary in Moves.for_role(role):
		var id := str(r["id"])
		if not bool(r.get("starter", false)) and not Moves.learned(role, id):
			pool.append({"kind": "move", "id": id, "title": str(r.get("title", id)).to_upper()})
	for a: String in Attach.LIST:
		if not Attach.owned(a):
			pool.append({"kind": "part", "id": a, "title": str(Attach.LIST[a]["title"])})
	for s: String in Suits.LIST:
		for p: String in Suits.PARTS:
			if not Suits.owned_part(s, p):
				pool.append({"kind": "suit", "id": s, "part": p, "title": str(Suits.part_row(s, p)["title"])})
	if allow_throw:
		for t: String in THROWS:
			pool.append({"kind": "throw", "id": t, "title": "%d x %s" % [int(THROWS[t]), str(ThrowLob.KINDS[t]["title"])]})
	if pool.is_empty():
		return {"kind": "gems", "id": "", "title": "+3 GEMS"}
	return pool[randi() % pool.size()]


static func icon(u: Dictionary) -> String:
	match str(u.get("kind", "")):
		"move":
			return "node_combo"
		"part":
			return IconBook.for_part(str(u["id"]))
		"suit":
			return "node_wardrobe"
		"throw":
			return str(ThrowLob.KINDS[str(u["id"])]["icon"])
	return "cur_gem"


## Gives `u` to fighter `f` (or the profile). Returns a short line.
static func grant(u: Dictionary, f: Fighter) -> String:
	match str(u.get("kind", "")):
		"move":
			var role := f.role if f else "son"
			var d: Dictionary = FamilyProfile.data.get("moves_learned", {})
			var a: Array = d.get(role, [])
			if not a.has(str(u["id"])):
				a.append(str(u["id"]))
			d[role] = a
			FamilyProfile.data["moves_learned"] = d
			FamilyProfile.flag_unseen("moves")
			FamilyProfile.save()
			return "NEW MOVE  ·  put it in a slot in MOVES"
		"part":
			var arr: Array = FamilyProfile.data.get("attach_owned", [])
			if not arr.has(str(u["id"])):
				arr.append(str(u["id"]))
			FamilyProfile.data["attach_owned"] = arr
			FamilyProfile.flag_unseen("armory")
			FamilyProfile.save()
			Discover.see("part", str(u["id"]), str(u["title"]))
			return "GUN PART  ·  fit it at the GUNSMITH"
		"suit":
			Suits.grant_part(str(u["id"]), str(u["part"]))
			return "SUIT PART  ·  wear it in GEAR"
		"throw":
			if f:
				if f.throw_kind != str(u["id"]):
					f.throw_n = 0
				f.throw_kind = str(u["id"])
				f.throw_n += int(THROWS[str(u["id"])])
			return "THROWABLE  ·  SHOOT + UP to throw"
	FamilyProfile.data["gems"] = int(FamilyProfile.data.get("gems", 0)) + 3
	FamilyProfile.save()
	return "Everything found. Gems instead."


## The chest a story boss (or a mini) leaves: drops with a bounce, opens when
## a hero walks in (or by itself after a few seconds): gold, gems, shards
## and one LootBook find - bosses two.
class StoryChest extends Node2D:
	var big := true
	var _t := 0.0
	var _open := false

	func _ready() -> void:
		z_index = 5
		var s := Sprite2D.new()
		s.texture = IconBook.tex("cur_chest")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -16)
		s.scale = Vector2.ONE * (1.15 if big else 0.9)
		s.light_mask = 0
		s.position.y = -160.0
		add_child(s)
		var l := PointLight2D.new()
		l.texture = LightRig.radial_tex()
		l.texture_scale = 0.7
		l.color = Color(1.0, 0.56, 0.12)
		l.energy = 0.9
		l.range_item_cull_mask = 1
		l.position = Vector2(0, -18)
		add_child(l)
		var tw := create_tween()
		tw.tween_property(s, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			Juice.pulse_shake(3.0)
			Juice.land_puff(global_position))
		Juice.popup_number(global_position + Vector2(0, -60), "BOSS LOOT" if big else "LOOT", UiKit.GOLD)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _open or _t < 0.6:
			return
		var near: Fighter = null
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and not (n as Fighter).downed and (n as Fighter).global_position.distance_to(global_position) < 40.0:
				near = n
		if near == null and _t > 4.0:
			for n in get_tree().get_nodes_in_group("players"):
				if n is Fighter and not (n as Fighter).downed:
					near = n
					break
		if near != null:
			_burst(near)

	func _burst(f: Fighter) -> void:
		_open = true
		var at := get_global_transform_with_canvas().origin + Vector2(0, -20)
		var gold := (60 if big else 25) + randi() % 20
		var gems := 2 if big else (1 if randf() < 0.5 else 0)
		FamilyProfile.add_gold(gold)
		Juice.rewards.give("gold", gold, at, false)
		if gems > 0:
			FamilyProfile.add_gems(gems)
			Juice.rewards.give("gems", gems, at + Vector2(0, -12), false)
		Heroes.add_shards(f.role, 5 if big else 2)
		var lines: Array[String] = ["+%d GOLD" % gold]
		var finds := 2 if big else 1
		var first := {}
		for i in finds:
			var u := LootBook.roll(f.role, i > 0 or not big)
			var line := LootBook.grant(u, f)
			lines.append(str(u["title"]))
			if first.is_empty():
				first = u
				first["line"] = line
		Juice.play("res://assets/audio/chest.wav")
		RewardFly.snd("up_boom", 0.9, -3.0)
		Juice.rewards.reveal(LootBook.icon(first), str(first["title"]), Color(1.0, 0.56, 0.12), "  ·  ".join(lines), 1.6)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.3, 0.7), 0.06)
		tw.tween_property(self, "scale", Vector2(0.0, 1.6), 0.12)
		tw.tween_callback(queue_free)

	func _draw() -> void:
		var c := Color(1.0, 0.56, 0.12)
		for i in 10:
			var a := _t * 1.2 + float(i) * TAU / 10.0
			draw_line(Vector2(0, -20), Vector2(0, -20) + Vector2.from_angle(a) * (34.0 + 5.0 * sin(_t * 4.0 + float(i))), Color(c.r, c.g, c.b, 0.22), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.35))


static func drop_chest(host: Node, at: Vector2, is_big: bool) -> void:
	var c := StoryChest.new()
	c.big = is_big
	c.global_position = at
	host.add_child.call_deferred(c)
