class_name QuestGiver
extends Area2D

## Somebody on the street with a problem (data/side_quests.json). A yellow
## "!" means they want to talk: walk up, UP / LIGHT. They say their piece,
## the job goes on the objectives card, and the marker turns into a small
## "..." while you work. When it is done the marker becomes a glowing "?":
## come back and they pay (gold, XP, sometimes a gem or a meal).

var quest: Dictionary = {}
var state := "offer"   # offer -> active -> ready -> paid
var count := 0
var _mark: Label
var _anim: AnimatedSprite2D
var _t := 0.0
var _busy := false
var _item: Node2D


static func place_for(host: Node, map_id: String, map_w: float) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/side_quests.json"))
	if not (parsed is Dictionary):
		return
	var book := parsed as Dictionary
	var rows: Array = []
	if book.has(map_id):
		rows = (book[map_id] as Array).duplicate()
	else:
		# Two from the shared pool, seeded by the map so they stay put.
		var pool: Array = (book.get("any", []) as Array).duplicate()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(map_id)
		for i in mini(2, pool.size()):
			var k := rng.randi_range(0, pool.size() - 1)
			var r: Dictionary = (pool[k] as Dictionary).duplicate()
			pool.remove_at(k)
			r["x"] = map_w * (0.22 + 0.36 * float(i))
			rows.append(r)
	for r: Dictionary in rows:
		var g := QuestGiver.new()
		g.quest = r
		g.position = Vector2(float(r.get("x", 600.0)), 446.0)
		host.add_child(g)


func _ready() -> void:
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("quest_givers")
	add_to_group("talkers")
	var who := "npc_" + str(quest.get("id", "x"))
	set_meta("who", who)
	StoryBook.npc_names[who] = str(quest.get("giver", "STRANGER"))
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(70, 60)
	cs.shape = r
	add_child(cs)
	var own := str(quest.get("sprite", ""))
	if own != "" and SpriteBook.has_who(own):
		# A drawn character of their own: no tint needed.
		_anim = SpriteBook.make_anim(own)
		SpriteBook.grow(_anim, SpriteBook.NPC_SCALE)
		_anim.flip_h = true
		add_child(_anim)
	elif SpriteBook.has_who("bystander"):
		_anim = SpriteBook.make_anim("bystander")
		SpriteBook.grow(_anim, SpriteBook.NPC_SCALE)
		var tint: Array = quest.get("tint", [1, 1, 1])
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/shaders/npc_tint.gdshader")
		m.set_shader_parameter("hue", fmod(float(hash(str(quest.get("id", "")))) * 0.0001, 1.0) * 0.6 + 0.2)
		m.set_shader_parameter("coat", Vector3(float(tint[0]), float(tint[1]), float(tint[2])) * 0.6)
		_anim.material = m
		_anim.flip_h = true
		add_child(_anim)
	_mark = Label.new()
	_mark.position = Vector2(-20, -82)
	_mark.size = Vector2(40, 24)
	_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mark.add_theme_font_override("font", UiKit.title_font())
	_mark.add_theme_font_size_override("font_size", 18)
	_mark.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_mark.add_theme_constant_override("outline_size", 4)
	add_child(_mark)
	_paint()


func _paint() -> void:
	match state:
		"offer":
			_mark.text = "!"
			_mark.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		"active":
			_mark.text = "..."
			_mark.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		"ready":
			_mark.text = "?"
			_mark.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		_:
			_mark.text = ""


func _process(delta: float) -> void:
	_t += delta
	_mark.position.y = -82.0 - 3.0 * absf(sin(_t * 3.0))
	if state == "ready":
		_mark.scale = Vector2.ONE * (1.0 + 0.12 * sin(_t * 8.0))
	if _busy or state == "paid":
		return
	for n in get_overlapping_bodies():
		if n is Fighter and not (n as Fighter).downed:
			var f := n as Fighter
			if _anim:
				_anim.flip_h = f.global_position.x < global_position.x
			if _wants(f):
				_talk_to()
			return


const VOICE := {"lost_dog": "npc_woman", "bin_rage": "npc_sal", "repo_revenge": "npc_old"}


func _say(n: int) -> void:
	var v := str(VOICE.get(str(quest.get("id", "")), ""))
	var path := "res://assets/audio/vo/%s_talk_%d.ogg" % [v, n]
	if v != "" and ResourceLoader.exists(path):
		Mixer.play_vo(path)


func _talk_to() -> void:
	var talk := _talk_node()
	var who := str(get_meta("who"))
	_say(2 if state == "ready" else 1)
	match state:
		"offer":
			var lines: Array = []
			for t in quest.get("lines", []):
				lines.append({"who": who, "text": str(t)})
			lines.append({"who": "son" if randf() < 0.5 else "father", "text": "Fine. But we're billing you."})
			_play(talk, lines)
			state = "active"
			if str((quest.get("goal", {}) as Dictionary).get("type", "")) == "fetch":
				_drop_item()
			_hud(_label(), "active")
			Juice.toast("quest", "SIDE JOB", str(quest.get("giver", "")) + ": " + _label())
		"active":
			_play(talk, [{"who": who, "text": "Still waiting. Like the rest of us."}])
		"ready":
			_play(talk, [{"who": who, "text": str(quest.get("done", "Thanks."))}])
			_pay()
	_paint()


func _play(talk: Node, lines: Array) -> void:
	if talk and talk.has_method("play"):
		_busy = true
		talk.call("play", lines, true)
		get_tree().create_timer(0.6).timeout.connect(func() -> void: _busy = false)


func _talk_node() -> Node:
	var act := get_tree().get_first_node_in_group("run_act")
	if act and act.get("_talk") != null:
		return act.get("_talk")
	return null


func _label() -> String:
	var g: Dictionary = quest.get("goal", {})
	var base := str(g.get("label", "Help out"))
	var n := int(g.get("n", 0))
	if n > 1 and state == "active":
		return "%s  (%d/%d)" % [base, count, n]
	return base


func _hud(text: String, st: String) -> void:
	var hud := get_tree().get_first_node_in_group("mission_hud")
	if hud and hud.has_method("quest_line"):
		hud.call("quest_line", str(quest.get("id", "")), str(quest.get("giver", "")) + ": " + text, st)


## Kill / smash events from QuestGiver.note().
func on_event(kind: String, arg: String) -> void:
	if state != "active":
		return
	var g: Dictionary = quest.get("goal", {})
	if str(g.get("type", "")) != kind:
		return
	if kind == "kill" and g.has("title") and str(g["title"]) != arg:
		return
	count += 1
	if count >= int(g.get("n", 1)):
		_ready_up()
	else:
		_hud(_label(), "active")


func _ready_up() -> void:
	state = "ready"
	_paint()
	_hud(str((quest.get("goal", {}) as Dictionary).get("label", "")) + "  ·  go back to " + str(quest.get("giver", "them")), "ready")
	Juice.shout("SIDE JOB DONE")
	Mixer.play_sfx("res://assets/audio/card.wav")


func _pay() -> void:
	state = "paid"
	FamilyProfile.data["side_jobs_done"] = int(FamilyProfile.data.get("side_jobs_done", 0)) + 1
	var rw: Dictionary = quest.get("reward", {})
	var gold := int(rw.get("gold", 0))
	if gold > 0:
		for i in mini(gold / 5, 10):
			LootDrop.spawn(get_parent(), global_position + Vector2(randf_range(-10, 10), 0), "coin", gold / mini(gold / 5, 10), 1.2)
	XpOrb.burst(get_parent(), global_position, int(rw.get("xp", 0)))
	if int(rw.get("gems", 0)) > 0:
		FamilyProfile.add_gems(int(rw["gems"]))
	if bool(rw.get("heal", false)):
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter:
				(n as Fighter).hp = (n as Fighter).max_hp
	_hud(str((quest.get("goal", {}) as Dictionary).get("label", "")), "paid")
	FamilyProfile.data["side_jobs"] = int(FamilyProfile.data.get("side_jobs", 0)) + 1
	Juice.toast("reward", "SIDE JOB PAID", "%s paid %d gold%s." % [str(quest.get("giver", "")), gold, " and a gem" if int(rw.get("gems", 0)) > 0 else ""])
	var hud := get_tree().get_first_node_in_group("mission_hud")
	if hud and hud.has_method("complete_side"):
		hud.call("complete_side")


func _drop_item() -> void:
	var g: Dictionary = quest.get("goal", {})
	var it := QuestItem.new()
	it.kind = str(g.get("item", "wallet"))
	it.giver = self
	it.position = Vector2(global_position.x + float(g.get("item_dx", 900.0)), 496.0)
	get_parent().add_child(it)
	_item = it


func found_item() -> void:
	if state == "active":
		_ready_up()


## Called by enemies dying and props breaking: forwards to every giver.
static func note(tree: SceneTree, kind: String, arg: String = "") -> void:
	if tree == null:
		return
	for g in tree.get_nodes_in_group("quest_givers"):
		g.call("on_event", kind, arg)


## Talk / shop only on a deliberate press: standing still (UP while walking
## past just walks you up the street).
func _wants(f: Fighter) -> bool:
	if absf(f.velocity.x) > 30.0 or absf(f._stick().x) > 0.35:
		return false
	return f._just("up") or f._just("light")
