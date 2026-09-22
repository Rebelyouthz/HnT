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
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/tricks.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		_table = (parsed as Dictionary).get(kind, {})
	_hint = Label.new()
	_hint.position = Vector2(-120, -70)
	_hint.size = Vector2(240, 56)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 12, Palette.EDGE)
	_hint.text = _idle()
	add_child(_hint)


func _idle() -> String:
	var e: Dictionary = _table.get("easy", {})
	var m: Dictionary = _table.get("mid", {})
	var h: Dictionary = _table.get("hard", {})
	return "%s  ·  UP %s  ·  SPECIAL %s" % [
		str(e.get("title", "JUMP")), str(m.get("title", "VAULT")), str(h.get("title", "KONG"))
	]


func _process(_delta: float) -> void:
	if _used:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			_hint.modulate = Color(1.25, 1.2, 0.7)
			if f._just("jump") or f._just("special") or f._just("dash"):
				_attempt(f)
			return
	_hint.modulate = Color.WHITE


func _attempt(f: Fighter) -> void:
	if _used:
		return
	_used = true
	var pick := "easy"
	if f._just("special") or (f._pressed("special") and f._just("jump")):
		pick = "hard"
	elif f._stick().y < -0.35 or f._just("dash"):
		pick = "mid" if not f._just("dash") else ("hard" if kind == "crate" else "mid")
		if f._just("dash") and kind == "crate":
			pick = "hard"
	var row: Dictionary = _table.get(pick, _table.get("easy", {}))
	var title := str(row.get("title", "JUMP"))
	var pts := int(row.get("points", 8))
	var spd := float(row.get("speed", 1.0))
	var rank := FamilyProfile.dojo_rank(str(row.get("id", "jump")))
	pts += rank * 8
	if rank >= 1:
		spd += 0.02 * float(rank)
	var window := absf(f.global_position.x - global_position.x) < 32.0
	if pick != "easy" and not window:
		_fail(f)
		return
	var perfect := window and pick != "easy"
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
	f.parkour_lock = 0.22
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


func _fail(f: Fighter) -> void:
	var worst := f.hop < -160.0
	var hard := f.hop < -70.0
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
