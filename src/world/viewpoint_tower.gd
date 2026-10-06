class_name ViewpointTower
extends Area2D

## Assassin's Creed perch. High, wind, creak, can fall. Guided climb + cling QTE.

var map_id := "dock_street"
var _busy := false
var _hint: Label
var _mast: Polygon2D
var _beacon: Polygon2D
var _wind_t := 0.0
var _creak_t := 2.4


static func place(host: Node, map: String) -> ViewpointTower:
	var row := TowerBook.map_row(map)
	if row.is_empty():
		return null
	var t := ViewpointTower.new()
	t.map_id = map
	t.global_position = Vector2(float(row.get("x", 1200.0)), float(row.get("y", 500.0)))
	if map == "raven_grid" and t.global_position.x > 2200.0:
		t.global_position.x = 1640.0
	# Never at the door: the tower is a mid-map reward, a bit past halfway.
	var w := float(host.get("map_w")) if host.get("map_w") != null else 0.0
	if w > 0.0 and t.global_position.y > 400.0:
		t.global_position.x = clampf(t.global_position.x, w * 0.56, w * 0.72)
	host.add_child(t)
	return t


func _ready() -> void:
	add_to_group("towers")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(70, 80)
	cs.shape = sh
	cs.position = Vector2(0, -40)
	add_child(cs)
	if TowerBook.map_row(map_id).has("film"):
		_build_giant()
		return
	_mast = Polygon2D.new()
	_mast.color = Color(0.28, 0.22, 0.18)
	_mast.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0), Vector2(10, -420), Vector2(-10, -420)
	])
	_mast.z_index = 3
	add_child(_mast)
	for i in 9:
		var bar := Polygon2D.new()
		bar.color = Color(0.2, 0.16, 0.12)
		var yy := -44.0 * float(i)
		bar.polygon = PackedVector2Array([
			Vector2(-14, yy - 5), Vector2(14, yy - 5), Vector2(12, yy), Vector2(-12, yy)
		])
		_mast.add_child(bar)
	var platform := Polygon2D.new()
	platform.color = Color(0.42, 0.32, 0.2)
	platform.polygon = PackedVector2Array([
		Vector2(-48, -428), Vector2(48, -428), Vector2(40, -412), Vector2(-40, -412)
	])
	platform.z_index = 4
	add_child(platform)
	var rail := Polygon2D.new()
	rail.color = Color(0.55, 0.45, 0.28, 0.9)
	rail.polygon = PackedVector2Array([
		Vector2(-46, -448), Vector2(-40, -448), Vector2(-40, -428), Vector2(-46, -428)
	])
	add_child(rail)
	var rail2 := rail.duplicate() as Polygon2D
	rail2.position.x = 86
	add_child(rail2)
	var antenna := Polygon2D.new()
	antenna.color = Color(0.62, 0.58, 0.5)
	antenna.polygon = PackedVector2Array([
		Vector2(-3, -428), Vector2(3, -428), Vector2(2, -478), Vector2(-2, -478)
	])
	antenna.z_index = 5
	add_child(antenna)
	_beacon = Polygon2D.new()
	_beacon.color = Color(0.95, 0.28, 0.18)
	_beacon.polygon = PackedVector2Array([
		Vector2(-5, -486), Vector2(5, -486), Vector2(4, -476), Vector2(-4, -476)
	])
	_beacon.z_index = 6
	add_child(_beacon)
	Blockout.add_glow(_beacon)
	_guy_wire(Vector2(-10, -410), Vector2(-110, 8))
	_guy_wire(Vector2(10, -410), Vector2(110, 8))
	var lamp := PointLight2D.new()
	lamp.texture = LightRig.radial_tex()
	lamp.texture_scale = 1.5
	lamp.color = Color(0.95, 0.55, 0.22)
	lamp.energy = 0.5
	lamp.height = 10.0
	lamp.shadow_enabled = false
	lamp.position = Vector2(0, -450)
	add_child(lamp)
	_wind_mist()
	_hint = Label.new()
	# World text at half scale (see NightStreet.WORLD_TEXT).
	_hint.scale = Vector2(NightStreet.WORLD_TEXT, NightStreet.WORLD_TEXT)
	_hint.position = Vector2(-110, -80)
	_hint.size = Vector2(440, 48)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 13, Palette.EDGE)
	_hint.text = "%s  ·  LIGHT CLIMBS" % str(TowerBook.map_row(map_id).get("label", "TOWER"))
	add_child(_hint)
	SpriteBook.attach_scaled(self, "tower", -200.0, Vector2(1.15, 3.2))
	NightStreet.plaque(get_parent(), global_position + Vector2(-90, -470), "140M  ·  HELL IS BELOW", Palette.LEMON, 13)


var _giant := false


## The Harbour Clock in the street: the painted tower's base and shaft rising
## out of frame behind the pavement (the rest is seen during the climb). A
## secret: no marker, just a quiet plaque and a lit door.
func _build_giant() -> void:
	_giant = true
	var base := load("res://assets/ui/tower/base.png") as Texture2D
	var mid := load("res://assets/ui/tower/mid.png") as Texture2D
	var k := 2.0 / 3.0
	var y := 0.0
	var holder := Node2D.new()
	holder.z_index = -2
	add_child(holder)
	for tex in [base, mid, mid, mid, mid, mid, mid, mid, mid, mid]:
		if tex == null:
			continue
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.scale = Vector2(k, k)
		var h := float(tex.get_height()) * k
		sp.position = Vector2(-float(tex.get_width()) * k * 0.5, y - h)
		sp.texture_filter = SpriteBook.world_filter()
		holder.add_child(sp)
		y -= h - 1.0
	_hint = Label.new()
	_hint.scale = Vector2(NightStreet.WORLD_TEXT, NightStreet.WORLD_TEXT)
	_hint.position = Vector2(-120, -96)
	_hint.size = Vector2(480, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_hint, 13, Palette.LEMON)
	_hint.text = "???"
	add_child(_hint)
	NightStreet.plaque(self, Vector2(-38, -112), "%d M" % int(TowerBook.map_row(map_id).get("height_m", 132)), Palette.MUTED, 12)


func _guy_wire(a: Vector2, b: Vector2) -> void:
	var w := Line2D.new()
	w.width = 2.0
	w.default_color = Color(0.34, 0.3, 0.24, 0.85)
	w.points = PackedVector2Array([a, b])
	w.z_index = 2
	add_child(w)


func _wind_mist() -> void:
	var p := GPUParticles2D.new()
	p.position = Vector2(0, -400)
	p.z_index = 5
	p.amount = 18
	p.lifetime = 1.6
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(36, 10, 1)
	mat.direction = Vector3(1, 0.05, 0)
	mat.spread = 18.0
	mat.gravity = Vector3(0, -6, 0)
	mat.initial_velocity_min = 16.0
	mat.initial_velocity_max = 40.0
	mat.color = Color(0.78, 0.84, 0.9, 0.22)
	p.process_material = mat
	add_child(p)


func _process(delta: float) -> void:
	_wind_t += delta
	if _giant:
		_process_giant()
		return
	_mast.rotation = 0.03 * sin(_wind_t * 1.7)
	_beacon.modulate.a = 0.4 + 0.6 * (0.5 + 0.5 * sin(_wind_t * 7.0))
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = 2.2 + randf() * 1.8
		if absf(_nearest_x()) < 420.0:
			Juice.play("res://assets/audio/creak.wav")
	if _busy:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			if f.downed or f.van_seat != "":
				continue
			_hint.modulate = Color(1.2, 1.15, 0.7)
			if f._just("light") or f._just("jump"):
				_start(f)
			return
	_hint.modulate = Color.WHITE


func _process_giant() -> void:
	if _busy:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			if f.downed or f.van_seat != "":
				continue
			_hint.text = "%s  ·  UP / JUMP TO CLIMB" % str(TowerBook.map_row(map_id).get("label", "TOWER"))
			_hint.modulate = Color(1.2, 1.15, 0.7)
			if f._just("up") or f._just("jump"):
				_start_film()
			return
	_hint.text = "???" if not FamilyProfile.data.get("tower_" + map_id, false) else str(TowerBook.map_row(map_id).get("label", "TOWER"))
	_hint.modulate = Color.WHITE


func _start_film() -> void:
	_busy = true
	if not bool(FamilyProfile.data.get("tower_" + map_id, false)):
		Juice.toast("reward", "SECRET FOUND", "%s  ·  %d metres of bad decisions" % [str(TowerBook.map_row(map_id).get("label", "TOWER")), int(TowerBook.map_row(map_id).get("height_m", 132))])
	get_tree().paused = true
	var film := GiantTowerFilm.new()
	film.map_id = map_id
	get_tree().root.add_child(film)
	var res: Dictionary = await film.finished
	get_tree().paused = false
	FamilyProfile.data["tower_" + map_id] = true
	FamilyProfile.save()
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and is_instance_valid(n):
			(n as Fighter).global_position = Vector2(global_position.x + 90.0 + (20.0 if (n as Fighter).role == "son" else 0.0), global_position.y)
			(n as Fighter).velocity = Vector2.ZERO
	var rs := get_tree().get_first_node_in_group("run_state")
	var pts := 120 + int(res.get("score", 0)) + 40 * int(res.get("perfects", 0))
	if rs and rs.has_method("add_points"):
		rs.add_points("father", pts, "tower")
	FamilyProfile.add_gold(25)
	Juice.toast("reward", "VIEWPOINT SYNCED", "+%d points  ·  +25 gold  ·  %s" % [pts, str(res.get("descent", "")).to_upper()])
	_busy = false


func _nearest_x() -> float:
	var best := 9999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D:
			best = minf(best, absf((n as Node2D).global_position.x - global_position.x))
	return best


func _start(lead: Fighter) -> void:
	if _busy:
		return
	if get_tree().get_first_node_in_group("clinic_van") or get_tree().get_first_node_in_group("chase_crash"):
		Juice.shout("WATCH THE CRASH")
		return
	_busy = true
	_hint.text = "WIND  ·  CREAK  ·  DON'T FALL"
	Juice.unlock_logo("VIEWPOINT", "Hell is below. The wind is the only honest therapist.", str(TowerBook.map_row(map_id).get("label", "TOWER")))
	var players: Array[Fighter] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and is_instance_valid(n) and not (n as Fighter).downed:
			players.append(n)
	if players.is_empty():
		players.append(lead)
	for f in players:
		f.van_seat = "tower"
		f.velocity = Vector2.ZERO
	_climb(players)


func _climb(players: Array[Fighter]) -> void:
	var rings := TowerBook.ring_count(map_id)
	var window := TowerBook.ring_window(map_id)
	for i in rings:
		var u := float(i + 1) / float(rings)
		var y := lerpf(global_position.y, global_position.y - 400.0, u)
		_cam_hold(Vector2(global_position.x, y - 40.0), true)
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.set_parallel(true)
		for f in players:
			if not is_instance_valid(f):
				continue
			tw.tween_property(f, "global_position", Vector2(global_position.x + (12.0 if f.role == "son" else -12.0), y), 0.28)
		await tw.finished
		Juice.play("res://assets/audio/wind.wav")
		Juice.pulse_shake(2.0)
		var qte := ClingQte.new()
		qte.window = window - float(i) * 0.012
		qte.prompt = "CLING  %d / %d" % [i + 1, rings]
		add_child(qte)
		var ok: bool = await qte.resolved
		if not ok:
			_fall(players)
			return
	_summit(players)


func _fall(players: Array[Fighter]) -> void:
	Juice.named_slowmo()
	Juice.pulse_shake(8.0)
	_cam_hold(global_position, false)
	var dmg := 18
	if FamilyProfile.has_cbt("farm_patience"):
		dmg = 11
	var land_y := global_position.y
	for f in players:
		if not is_instance_valid(f):
			continue
		f.van_seat = ""
		f.global_position = Vector2(global_position.x + randf_range(-20.0, 20.0), land_y)
		f.hop = 0.0
		var rs := get_tree().get_first_node_in_group("run_state")
		var refund := false
		if rs != null and rs.has_method("has_card"):
			refund = bool(rs.call("has_card", "escape_clause"))
		f.hp = maxi(1, f.hp - dmg)
		Juice.kill_burst(f.global_position, "fall")
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("pulse"):
			blood.pulse(f.global_position)
		if blood and blood.has_method("spray"):
			blood.spray(f.global_position, "heavy", 1.0)
		if refund:
			f.extra_jump = 1
			Juice.shout("CLAUSE")
	Juice.toast("challenge", "FELL", "The tower creaked. Try again. That's allowed.")
	_busy = false
	_hint.text = "%s  ·  LIGHT CLIMBS" % str(TowerBook.map_row(map_id).get("label", "TOWER"))


func _summit(players: Array[Fighter]) -> void:
	for f in players:
		if is_instance_valid(f):
			f.global_position = Vector2(global_position.x + (18.0 if f.role == "son" else -18.0), global_position.y - 412.0)
	_cam_hold(Vector2(global_position.x, global_position.y - 452.0), true)
	FamilyProfile.note_tower()
	var talk := SummitTalk.new()
	talk.map_id = map_id
	add_child(talk)
	await talk.finished
	_descend(players)


func _descend(players: Array[Fighter]) -> void:
	var kind := TowerBook.next_descent()
	Juice.unlock_logo(kind.to_upper(), "Peace ends. Hell resumes.", "DESCENT")
	match kind:
		"parachute":
			await _local_parachute(players)
		"zip":
			await _zip(players)
		"water":
			await _water(players)
		_:
			await _ledge(players)
	_cam_hold(global_position, false)
	for f in players:
		if is_instance_valid(f):
			f.van_seat = ""
			f.global_position = Vector2(global_position.x + 80.0, global_position.y)
	_busy = false
	_hint.text = "%s  ·  CLIMBED" % str(TowerBook.map_row(map_id).get("label", "TOWER"))
	Juice.toast("quest", "BACK IN HELL", "The wind stays up there. We don't.")


func _local_parachute(players: Array[Fighter]) -> void:
	Juice.shout("CANOPY")
	Juice.play("res://assets/audio/wind.wav")
	for i in 22:
		for f in players:
			if is_instance_valid(f):
				f.global_position.y = lerpf(f.global_position.y, global_position.y, 0.11)
		await get_tree().create_timer(0.05).timeout


func _zip(players: Array[Fighter]) -> void:
	Juice.shout("ZIP")
	Juice.play("res://assets/audio/zip.wav")
	Juice.pulse_shake(3.0)
	for i in 14:
		for f in players:
			if is_instance_valid(f):
				f.global_position += Vector2(18.0, 26.0)
		await get_tree().create_timer(0.04).timeout


func _water(players: Array[Fighter]) -> void:
	Juice.shout("WATER")
	Juice.play("res://assets/audio/splash.wav")
	Juice.pulse_shake(5.0)
	await get_tree().create_timer(0.35).timeout
	for f in players:
		if is_instance_valid(f):
			f.hp = mini(f.max_hp, f.hp + 4)


func _ledge(players: Array[Fighter]) -> void:
	Juice.shout("LEDGE BOUNCE")
	Juice.play("res://assets/audio/awning.wav")
	for i in 8:
		for f in players:
			if is_instance_valid(f):
				f.global_position.y += 40.0
		await get_tree().create_timer(0.05).timeout


func _cam_hold(at: Vector2, on: bool) -> void:
	for n in get_tree().get_nodes_in_group("couch_cam"):
		if not (n is CouchCamera):
			continue
		var cam: CouchCamera = n
		cam.cinematic_on = on
		if on:
			cam.cinematic = at
