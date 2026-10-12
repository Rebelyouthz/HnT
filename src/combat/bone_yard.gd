class_name BoneYard
extends Object

## The BONE YARD: a one-life roguelike run through the yards behind the
## dojo (data/boneyard.json): Grimhollow, the Neon Maze, Butcher Row, Cold
## Storage and the Chapel of Bills. Each map pays FIGHT TOKENS for the
## BONE YARD tree: 1 for every clear, plus 1 per challenge the first time
## it is done. Clearing every open yard in one life once fills the yard
## (boneyard_full) and opens the big supers. Maps open with the story: the
## first after the first survivor night, the next after the parkour roofs
## and the next survivor night, then one per survivor night after that.

const PATH := "res://data/boneyard.json"
static var _data: Dictionary = {}

# The run in progress (one life, map to map).
static var active := false
static var chain: Array = []
static var step := 0
static var brutal_n := 0
static var kinds := {}
static var juggle_best := 0
static var t0 := 0.0
static var parries0 := 0


static func data() -> Dictionary:
	if _data.is_empty():
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if v is Dictionary:
			_data = v
	return _data


static func maps() -> Array:
	return data().get("maps", [])


static func map(id: String) -> Dictionary:
	for m in maps():
		if str(m["id"]) == id:
			return m
	return {}


static func is_map(id: String) -> bool:
	return not map(id).is_empty()


static func _fp() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	return loop.root.get_node_or_null("FamilyProfile") if loop else null


static func is_open(id: String) -> bool:
	var fp := _fp()
	if fp == null:
		return false
	var filed: Array = fp.data.get("maps_filed", [])
	for n in map(id).get("needs", []):
		if not filed.has(str(n)):
			return false
	return true


static func open_maps() -> Array:
	var out: Array = []
	for m in maps():
		if is_open(str(m["id"])):
			out.append(str(m["id"]))
	return out


static func done(key: String) -> bool:
	var fp := _fp()
	return fp != null and (fp.data.get("boneyard_done", []) as Array).has(key)


static func _mark(key: String) -> void:
	var fp := _fp()
	var d: Array = fp.data.get("boneyard_done", [])
	if not d.has(key):
		d.append(key)
	fp.data["boneyard_done"] = d


## First time the yard opens (after the first survivor night): a free token
## so the first move can be bought right away, and the guide takes over.
static func check_open(host: Node = null) -> void:
	var fp := _fp()
	if fp == null or bool(fp.data.get("boneyard_told", false)) or open_maps().is_empty():
		return
	fp.data["boneyard_told"] = true
	fp.data["fight_tokens"] = int(fp.data.get("fight_tokens", 0)) + 1
	fp.save()
	Juice.unlock_logo("THE BONE YARD IS OPEN", "One FIGHT TOKEN to start: spend it on the BONE YARD tree in the DOJO.", "DOJO  ·  NEW MODE")
	if host != null:
		Guide.play(host, "boneyard_open", [
			{"who": "father", "voice": true, "text": "Benny says my old gym had a back room. They called it the BONE YARD. One life, yard after yard, and finishers that break bones."},
			{"who": "son", "voice": true, "text": "He left us a FIGHT TOKEN. The DOJO has the tree: hold a move to buy it, drill it 3 times on the dummy, then we go in."},
		], 4.0)


## Start a one-life run through every open yard.
static func start() -> void:
	chain = open_maps()
	if chain.is_empty():
		return
	active = true
	step = 0
	brutal_n = 0
	kinds = {}
	juggle_best = 0
	t0 = Time.get_ticks_msec() / 1000.0
	parries0 = int(_fp().data.get("parries", 0))
	App.run_bag = {}
	App.surv_solo = false
	App.weekly = false
	App.versus = false
	App.enter_map(str(chain[0]))


static func next_map() -> String:
	return str(chain[step + 1]) if active and step + 1 < chain.size() else ""


static func note_brutal(id: String) -> void:
	if not active:
		return
	brutal_n += 1
	kinds[id] = true


static func note_juggle(n: int) -> void:
	if active:
		juggle_best = maxi(juggle_best, n)


## A yard cleared: pay the tokens, tick the challenges. Returns the lines
## for the results card.
static func on_clear(id: String, heroes: Array) -> Array:
	var fp := _fp()
	var lines: Array = []
	var got := 1
	lines.append("YARD CLEARED  +1")
	var hp_pct := 100.0
	for f in heroes:
		if f != null and is_instance_valid(f):
			hp_pct = minf(hp_pct, 100.0 * float(f.get("hp")) / maxf(1.0, float(f.get("max_hp"))))
	var secs := Time.get_ticks_msec() / 1000.0 - t0
	for c in map(id).get("challenges", []):
		var key := "%s:%s" % [id, str(c["id"])]
		var n := int(c.get("n", 1))
		var ok := false
		match str(c["kind"]):
			"brutal":
				ok = brutal_n >= n
			"hp_left":
				ok = hp_pct > float(n)
			"juggle":
				ok = juggle_best >= n
			"time":
				ok = secs <= float(n)
			"kinds":
				ok = kinds.size() >= n
			"parry":
				ok = int(fp.data.get("parries", 0)) - parries0 >= n
		if ok and not done(key):
			_mark(key)
			got += 1
			lines.append("%s  +1" % str(c["text"]))
		elif ok:
			lines.append("%s  (DONE BEFORE)" % str(c["text"]))
		else:
			lines.append("%s  (MISSED)" % str(c["text"]))
	_mark(id)
	if next_map() == "" and active and chain.size() >= maps().size() and not bool(fp.data.get("boneyard_full", false)):
		fp.data["boneyard_full"] = true
		var bonus := int(data().get("full_bonus", 2))
		got += bonus
		lines.append("EVERY YARD IN ONE LIFE  +%d  ·  SUPERS OPEN" % bonus)
	BrutalBook.add_tokens(got, "%s cleared." % str(map(id).get("title", id)))
	# The next yard starts its own clock and counters.
	brutal_n = 0
	kinds = {}
	juggle_best = 0
	t0 = Time.get_ticks_msec() / 1000.0
	parries0 = int(fp.data.get("parries", 0))
	return lines


static func end_run() -> void:
	active = false
	chain = []
	step = 0


## The BONE YARD block on the dojo sheet: tree, tokens, the run button and
## each yard's challenges.
static func dojo_panel(host: Control) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var h := Label.new()
	h.text = "BONE YARD  ·  %d FIGHT TOKEN%s" % [BrutalBook.tokens(), "" if BrutalBook.tokens() == 1 else "S"]
	UiKit.apply_label(h, 20, Color(0.92, 0.2, 0.16))
	box.add_child(h)
	var open := open_maps()
	if open.is_empty():
		var l := Label.new()
		l.text = "LOCKED  ·  " + str((maps()[0] as Dictionary).get("opens", "")) if not maps().is_empty() else ""
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(l, 13, Palette.MUTED)
		box.add_child(l)
		return box
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var tree := UiKit.button("BONE YARD TREE", Vector2(250, 44))
	tree.set_meta("key", "bone_tree")
	tree.pressed.connect(func() -> void:
		var t: Control = load("res://src/ui/bone_tree.gd").new()
		UiKit.open_over(host, t)
	)
	row.add_child(tree)
	var go := UiKit.button("ENTER THE BONE YARD  ·  1 LIFE", Vector2(360, 44))
	go.set_meta("key", "bone_go")
	go.pressed.connect(func() -> void:
		host.emit_signal("closed")
		host.queue_free()
		BoneYard.start()
	)
	row.add_child(go)
	box.add_child(row)
	if BrutalBook.tokens() > 0 and (_fp().data.get("brutal", []) as Array).is_empty():
		UiKit.pulse_ready(tree)
	Guide.play(host, "boneyard_dojo", [
		{"key": "bone_tree", "who": "father", "voice": true, "text": "The BONE YARD TREE. It grows from the bottom: the root first, then up. FIGHT TOKENS pay for it."},
		{"key": "bone_go", "who": "son", "voice": true, "text": "Then in here. One life, every open yard in a row. Each yard pays a token, and its two challenges pay one more each, once."},
	], 0.6)
	for m in maps():
		var id := str(m["id"])
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not is_open(id):
			l.text = "%s  ·  LOCKED  ·  %s" % [str(m["title"]), str(m.get("opens", ""))]
			UiKit.apply_label(l, 12, Palette.MUTED)
		else:
			var bits: Array = []
			for c in m.get("challenges", []):
				bits.append(("✓ " if done("%s:%s" % [id, str(c["id"])]) else "○ ") + str(c["text"]))
			l.text = "%s%s  ·  %s" % [str(m["title"]), "  ✓" if done(id) else "", "   ".join(bits)]
			UiKit.apply_label(l, 12, Palette.TEXT)
		box.add_child(l)
	return box
