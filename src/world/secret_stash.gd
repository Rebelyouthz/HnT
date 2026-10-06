class_name SecretStash
extends Area2D

## One unique reward per stash. Not scrap with a hat.

var spec: Dictionary = {}
var _taken := false
var _hint: Label
var _box: Polygon2D
var _glint := 0.0


static func place(host: Node, map_id: String) -> void:
	if not FileAccess.file_exists("res://data/secrets.json"):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/secrets.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var table: Dictionary = parsed
	var rows: Array = []
	var row: Variant = table.get(map_id, {})
	if typeof(row) == TYPE_DICTIONARY and not (row as Dictionary).is_empty():
		rows.append(row)
	elif typeof(row) == TYPE_ARRAY:
		rows = row
	var extra: Variant = table.get("_extra", [])
	if typeof(extra) == TYPE_ARRAY:
		for item in extra:
			if typeof(item) == TYPE_DICTIONARY and str((item as Dictionary).get("map", "")) == map_id:
				rows.append(item)
	for item in rows:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		_spawn(host, map_id, item as Dictionary)


static func _spawn(host: Node, map_id: String, spec: Dictionary) -> SecretStash:
	var s := SecretStash.new()
	s.spec = spec
	s.global_position = Vector2(float(spec.get("x", 1600.0)), float(spec.get("y", 500.0)))
	if map_id == "raven_grid" and s.global_position.x > 2200.0:
		s.global_position.x = 2080.0
	host.add_child(s)
	return s


func _ready() -> void:
	add_to_group("secrets")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var found: Array = FamilyProfile.data.get("secret_ids", [])
	if found.has(str(spec.get("id", ""))):
		_taken = true
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48, 40)
	cs.shape = sh
	cs.position = Vector2(0, -20)
	add_child(cs)
	_box = Polygon2D.new()
	_box.color = Color(0.79, 0.64, 0.15, 0.4 if _taken else 0.95)
	_box.polygon = _shape(str(spec.get("kind", "gold")))
	add_child(_box)
	Blockout.add_glow(_box)
	_hint = Label.new()
	# World text at world scale (like the parkour gate hints), shown only
	# when a hero comes close.
	_hint.scale = Vector2(0.5, 0.5)
	_hint.position = Vector2(-45, -50)
	_hint.size = Vector2(180, 32)
	_hint.modulate.a = 0.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_hint, 12, Palette.EDGE)
	_hint.text = "FILED" if _taken else str(spec.get("title", "SECRET"))
	add_child(_hint)
	SpriteBook.attach_living(self, "secret")


func _shape(kind: String) -> PackedVector2Array:
	match kind:
		"lunch":
			return PackedVector2Array([Vector2(-18, -22), Vector2(18, -22), Vector2(16, 0), Vector2(-16, 0)])
		"card":
			return PackedVector2Array([Vector2(-12, -30), Vector2(12, -30), Vector2(14, 0), Vector2(-14, 0)])
		"grenade":
			return PackedVector2Array([Vector2(-8, -28), Vector2(8, -28), Vector2(12, -8), Vector2(6, 0), Vector2(-6, 0), Vector2(-12, -8)])
		"album":
			return PackedVector2Array([Vector2(-16, -26), Vector2(16, -26), Vector2(16, -4), Vector2(-16, -4)])
		"frame":
			return PackedVector2Array([Vector2(-20, -28), Vector2(20, -28), Vector2(16, 0), Vector2(-16, 0)])
		_:
			return PackedVector2Array([Vector2(-16, -28), Vector2(16, -28), Vector2(14, 0), Vector2(-14, 0)])


func _process(delta: float) -> void:
	var near := 9999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D:
			near = minf(near, (n as Node2D).global_position.distance_to(global_position))
	_hint.modulate.a = move_toward(_hint.modulate.a, clampf(1.0 - (near - 70.0) / 90.0, 0.0, 1.0) * (0.5 if _taken else 1.0), delta * 3.0)
	if _taken:
		return
	_glint += delta
	_box.modulate = Color(1.0, 1.0, 0.85 + 0.15 * sin(_glint * 5.0), 1.0)
	for n in get_overlapping_bodies():
		if n is Fighter and ((n as Fighter)._just("light") or (n as Fighter)._just("special")):
			_claim(n as Fighter)
			return


func _claim(f: Fighter) -> void:
	FamilyProfile.data["stashes_found"] = int(FamilyProfile.data.get("stashes_found", 0)) + 1
	Suits.check_progress()
	if _taken:
		return
	_taken = true
	_hint.text = "FILED"
	FamilyProfile.note_secret(str(spec.get("id", "")))
	var kind := str(spec.get("kind", "gold"))
	var title := str(spec.get("title", "SECRET"))
	var rarity := str(spec.get("rarity", "rare"))
	var rs := get_tree().get_first_node_in_group("run_state")
	match kind:
		"lunch":
			if rs and rs.has_method("add_lunch"):
				rs.add_lunch()
			Juice.toast("reward", title, "Lunch for 140m. Sit. Eat. Don't share with the wind.")
		"card":
			if rs and rs.has_method("take_card"):
				rs.take_card(str(spec.get("card", "")))
		"gems":
			FamilyProfile.add_gems(int(spec.get("gems", 1)))
			Juice.claim_burst(get_global_transform_with_canvas().origin, title, 0, int(spec.get("gems", 1)))
		"grenade":
			f.grenades += 1
			Juice.toast("reward", title, "A receipt with a timer.")
		"parts":
			FamilyProfile.add_parts(str(spec.get("item", "scrap_coil")), int(spec.get("n", 1)))
			Juice.toast("reward", title, "Research material. Unique.")
		"badge":
			FamilyProfile.grant_cosmetic("badge", str(spec.get("item", "")), true)
		"frame":
			FamilyProfile.grant_cosmetic("frame", str(spec.get("item", "")), true)
		"album":
			var album: Array = FamilyProfile.data.get("album", [])
			var pid := str(spec.get("item", ""))
			if not album.has(pid):
				album.append(pid)
				FamilyProfile.data["album"] = album
				FamilyProfile.data["polaroids"] = int(FamilyProfile.data.get("polaroids", 0)) + 1
				FamilyProfile.save()
			Juice.unlock_logo(title, str(spec.get("blurb", "")), "SECRET  ·  ALBUM")
		"loot":
			var u := LootBook.roll(f.role)
			var line := LootBook.grant(u, f)
			title = str(u["title"])
			spec["blurb"] = line
		"weapon":
			f.equip_pickup(str(spec.get("weapon", "invoice_star")))
			Juice.toast("reward", title, str(spec.get("blurb", "A unique weapon. The clipboard missed this.")))
		_:
			FamilyProfile.add_gold(12)
			Juice.toast("reward", title, "Twelve gold. Unique would have been nicer.")
	Rarity.juice(rarity, title)
	Juice.unlock_logo(title, str(spec.get("blurb", "Unique. The clipboard missed this.")), "SECRET  ·  %s" % Rarity.label(rarity))
	# Every stash also hides a few character shards for whoever opened it.
	Heroes.add_shards(f.role, 3)
	Juice.toast("reward", "+3 SHARDS", "Character shards in the stash. Raise rarity in HEROES.")
	Juice.play("res://assets/audio/chest.wav")
	Juice.pulse_shake(3.0)
	queue_free()
