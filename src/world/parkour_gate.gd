class_name ParkourGate
extends Area2D

## Vector-style: up to 3 named tricks. Just-jump is the easy path.

@export var kind := "rail"
var _hint: Label
var _used := false
var _table: Dictionary = {}


static func place(host: Node, at: Vector2, style: String) -> ParkourGate:
	var g := ParkourGate.new()
	g.kind = style
	g.global_position = at
	host.add_child(g)
	return g


func _ready() -> void:
	add_to_group("parkour")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(90, 80)
	cs.shape = r
	add_child(cs)
	var rail := Polygon2D.new()
	rail.color = Color(0.42, 0.38, 0.34, 0.95)
	rail.polygon = PackedVector2Array([
		Vector2(-40, -8), Vector2(40, -8), Vector2(36, 8), Vector2(-36, 8)
	])
	add_child(rail)
	SpriteBook.attach_living(self, kind)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/tricks.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		_table = (parsed as Dictionary).get(kind, {})
	_hint = Label.new()
	# World text at half scale (see NightStreet.WORLD_TEXT).
	_hint.scale = Vector2(0.5, 0.5)
	_hint.position = Vector2(-120, -62)
	_hint.size = Vector2(480, 56)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 12, Palette.EDGE)
	_hint.text = _idle()
	add_child(_hint)


func _idle() -> String:
	var t := _pick_trick()
	var keys: PackedStringArray = []
	for k in t.get("combo", [t.get("input", "jump")]):
		keys.append(str(TimingRing.NAMES.get(str(k), str(k).to_upper())))
	return "%s  ·  %s" % [str(t.get("title", "JUMP")), " + ".join(keys)]


## Learned tricks that fit this gate (data/parkour.json, learn = dojo id).
static func known_tricks(gate_kind: String) -> Array:
	var out: Array = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/parkour.json"))
	if not (parsed is Dictionary):
		return out
	for t: Dictionary in (parsed as Dictionary).get("tricks", []):
		if not (gate_kind in (t.get("kinds", []) as Array)):
			continue
		var learn := str(t.get("learn", ""))
		if learn == "" or FamilyProfile.dojo_learned(learn):
			out.append(t)
	return out


var _next: Dictionary = {}


## How many times each trick has been asked for this run, so the gates walk
## through the whole learned repertoire before repeating one.
static var _shown: Dictionary = {}


## The move this gate will ask for: the least-shown learned trick that fits
## (ties go to the harder one), so a run shows every trick you own.
func _pick_trick() -> Dictionary:
	if not _next.is_empty():
		return _next
	var list := known_tricks(kind)
	if list.is_empty():
		_next = {"id": "jump", "title": "JUMP", "input": "jump", "points": 8, "speed": 1.0, "tier": 0}
		return _next
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var na := int(_shown.get(str(a.get("id", "")), 0))
		var nb := int(_shown.get(str(b.get("id", "")), 0))
		if na != nb:
			return na < nb
		return int(a.get("tier", 0)) > int(b.get("tier", 0))
	)
	_next = list[0]
	var id := str(_next.get("id", ""))
	_shown[id] = int(_shown.get(id, 0)) + 1
	return _next


func _process(_delta: float) -> void:
	# The prompt only shows when a hero is coming up on the gate.
	if _hint:
		var near := 9999.0
		for p in get_tree().get_nodes_in_group("players"):
			if p is Node2D:
				near = minf(near, absf((p as Node2D).global_position.x - global_position.x))
		var want := clampf((230.0 - near) / 110.0, 0.0, 1.0)
		_hint.modulate.a = lerpf(_hint.modulate.a, want, 0.15)
	if _used:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			# Only a body actually running at it triggers the move.
			if f.downed or f.van_seat != "" or absf(f.velocity.x) < 40.0:
				continue
			_hint.modulate = Color(1.25, 1.2, 0.7)
			_attempt(f)
			return
	_hint.modulate = Color.WHITE


## Entering the gate shows the trick's button in the timing ring; the press
## timing grades the move (perfect / good / ok / miss / big miss).
func _attempt(f: Fighter) -> void:
	if _used:
		return
	_used = true
	var trick := _pick_trick()
	# A trick is a button combo: each press timed in its own shrinking ring,
	# one straight after the other. The worst press grades the trick.
	var combo: Array = trick.get("combo", [trick.get("input", "jump")])
	var grade := "perfect"
	var order := ["perfect", "good", "ok", "miss", "big_miss"]
	for i in combo.size():
		var step_title := str(trick.get("title", "JUMP")) if combo.size() == 1 else "%s  %d/%d" % [str(trick.get("title", "JUMP")), i + 1, combo.size()]
		var ring := TimingRing.spawn(get_tree().current_scene, str(combo[i]), f, 0.62 if i == 0 else 0.42, step_title)
		ring.slow = 0.45
		var g: String = await ring.resolved
		if not is_instance_valid(f):
			return
		if order.find(g) > order.find(grade):
			grade = g
		if not TimingRing.is_success(g):
			break
	if not is_instance_valid(f):
		return
	_next = {}
	if grade == "miss":
		_fail(f, false)
		return
	if grade == "big_miss":
		_fail(f, true)
		return
	var perfect := grade == "perfect"
	var row: Dictionary = trick
	var pick := "easy" if int(trick.get("tier", 0)) == 0 else ("hard" if int(trick.get("tier", 0)) >= 3 else "mid")
	if grade == "ok":
		row = trick.duplicate()
		row["points"] = int(round(float(trick.get("points", 8)) * 0.6))
	var title := str(row.get("title", "JUMP"))
	var pts := int(row.get("points", 8))
	var spd := float(row.get("speed", 1.0))
	var rank := FamilyProfile.dojo_rank(str(row.get("id", "jump")))
	pts += rank * 8
	if rank >= 1:
		spd += 0.02 * float(rank)
	var rs0 := get_tree().get_first_node_in_group("run_state")
	if perfect and rs0 and rs0.has_method("has_card") and rs0.has_card("named_line"):
		pts += 12
	if perfect:
		pts = int(round(float(pts) * 1.25))
		spd += 0.04
		Juice.shout("PERFECT  %s" % title)
		Juice.play("res://assets/audio/trick_perfect.wav")
		FamilyProfile.mark_perfect()
		Juice.unlock_logo(title, "Perfect. +speed. Next rail is cheaper.", "NAMED TRICK  ·  PERFECT")
		Juice.named_slowmo()
	elif pick == "easy":
		Juice.shout(title)
		Juice.play("res://assets/audio/trick_ok.wav")
	else:
		Juice.shout(title)
		Juice.play("res://assets/audio/trick_ok.wav")
		Juice.unlock_logo(title, "Named trick. The coach would bill this.", title)
	f.trick_boost = spd
	f.trick_t = 2.4 if perfect else 1.4
	# The body actually goes over: a vault hop and a burst forward.
	if f.plane == "street" and f.hop >= -2.0:
		f.hop_v = -380.0 if perfect else -320.0
		f.hop = -1.0
	f.velocity.x = float(f.facing) * 340.0 * spd
	f.parkour_lock = 0.22
	TrickMove.play(f, str(row.get("anim", "hop")), perfect)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points"):
		rs.add_points(f.role, pts, "trick")
	FamilyProfile.mark_trick()
	Juice.popup_number(global_position + Vector2(0, -40), title, Palette.EDGE if perfect else Palette.LEMON)
	Juice.toast("reward", title, "%+d  ·  %s" % [pts, "PERFECT" if perfect else Rarity.label("rare" if pick == "hard" else "uncommon")])
	_hint.text = title
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		_used = false
		_hint.text = _idle()
	)


func _fail(f: Fighter, big := false) -> void:
	var worst := big and f.hop < -60.0
	var hard := big
	if worst:
		Juice.shout("SPLAT")
		Juice.play("res://assets/audio/stumble.wav")
		f.take_hit("heavy", f)
		Juice.unlock_logo("FAILED LINE", "Worst 3. You ate the rail.", "-POINTS  ·  HARD FALL")
	elif hard:
		Juice.shout("HARD FALL")
		Juice.play("res://assets/audio/stumble.wav")
		f.take_hit("light", f)
		Juice.popup_number(global_position, "HARD FALL", Palette.BRICK)
	else:
		Juice.shout("STUMBLE")
		Juice.play("res://assets/audio/stumble.wav")
		f.stumble()
	var rs := get_tree().get_first_node_in_group("run_state")
	var pen := -40 if worst else (-24 if hard else -12)
	if rs and rs.has_method("add_points"):
		rs.add_points(f.role, pen, "fail")
	_hint.text = "FAIL"
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		_used = false
		_hint.text = _idle()
	)
