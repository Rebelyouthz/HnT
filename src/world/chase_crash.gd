class_name ChaseCrash
extends Node2D

## Forced ramp, slow-mo tumble, canal crash, crawl-out talk, then the act boss.

signal finished

var van: ClinicVan
var cam: CouchCamera
var son: Fighter
var dad: Fighter
var host: Node
var ramp_x := 2480.0
var land_x := 3480.0
var _overlay: CanvasLayer
var _banner: Label
var _junk: Array[Dictionary] = []
var _flung: Array[Node2D] = []


static func begin(world: Node, courier: ClinicVan) -> ChaseCrash:
	var c := ChaseCrash.new()
	c.host = world
	c.van = courier
	c.son = courier.driver if courier.driver and courier.driver.role == "son" else courier.gunner
	c.dad = courier.driver if courier.driver and courier.driver.role == "father" else courier.gunner
	if c.son != null and c.son.role != "son":
		c.son = courier.gunner if courier.gunner and courier.gunner.role == "son" else c.son
	if c.dad != null and c.dad.role != "father":
		c.dad = courier.gunner if courier.gunner and courier.gunner.role == "father" else c.dad
	world.add_child(c)
	c.call_deferred("_run")
	return c


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("chase_crash")
	_overlay = CanvasLayer.new()
	_overlay.layer = 62
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var bars := ColorRect.new()
	bars.color = Color(0, 0, 0, 0.0)
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.name = "Bars"
	_overlay.add_child(bars)
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -420
	_banner.offset_right = 420
	_banner.offset_top = -80
	_banner.offset_bottom = 80
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.visible = false
	UiKit.apply_label(_banner, 64, Palette.LEMON)
	_overlay.add_child(_banner)


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.04)
	for j in _junk:
		var n: Node2D = j.get("n")
		if n == null or not is_instance_valid(n):
			continue
		n.position += (j.get("v") as Vector2) * real
		n.rotation += float(j.get("spin", 2.0)) * real
		j["v"] = (j.get("v") as Vector2) + Vector2(0, 420.0) * real
	for p in _flung:
		if is_instance_valid(p):
			p.rotation += 3.4 * real
			p.global_position += Vector2(90.0, -40.0) * real


func _run() -> void:
	if van == null or not is_instance_valid(van):
		_abort()
		return
	cam = get_tree().get_first_node_in_group("couch_cam") as CouchCamera
	if cam == null:
		var n := get_tree().get_first_node_in_group("run_act")
		if n:
			for c in n.get_children():
				if c is CouchCamera:
					cam = c
					break
	van.crashing = true
	Juice.unlock_logo("RAMP", "Do not brake. The canal does not take passengers.", "CHASE  ·  FORCED LAUNCH")
	Juice.shout("RAMP")
	Mixer.play_sfx("res://assets/audio/dash.wav", 0.78)
	await _force_ramp()
	if not _alive():
		_abort()
		return
	await _launch_air()
	if not _alive():
		_abort()
		return
	await _closeups()
	if not _alive():
		_abort()
		return
	await _new_angle_crash()
	if not _alive():
		_abort()
		return
	await _crawl_talk()
	await _boss_walks_in()
	_restore_time()
	finished.emit()
	queue_free()


func _force_ramp() -> void:
	var guard := 4.0
	while _alive() and van.global_position.x < ramp_x and guard > 0.0:
		var dt := get_process_delta_time()
		guard -= dt
		van.global_position.x += 460.0 * dt
		van.global_position.y = lerpf(van.global_position.y, 438.0, 0.18)
		van.rotation = lerpf(van.rotation, -0.42, 0.12)
		van.seat_keep()
		_hold_cam(Vector2(ramp_x + 240.0, 300.0))
		await get_tree().process_frame
	if _alive():
		van.global_position = Vector2(ramp_x + 8.0, 420.0)
		van.rotation = -0.55
		van.seat_keep()
		Juice.pulse_shake(5.0)
		Juice.shout("LAUNCH")
		KitSfx.hit("son", "jump")


func _launch_air() -> void:
	_letterbox(0.55)
	Juice.slowmo(0.22)
	_hold_cam(Vector2(ramp_x + 260.0, 250.0))
	_spawn_junk(14)
	_fling_near()
	var t := 0.0
	while t < 2.15 and _alive():
		var dt := get_process_delta_time() / maxf(Engine.time_scale, 0.04)
		t += dt
		van.global_position += Vector2(210.0, -118.0) * dt
		van.rotation += 2.8 * dt
		van.seat_keep()
		_hold_cam(Vector2(ramp_x + 300.0 + t * 40.0, 240.0 - t * 18.0))
		await get_tree().process_frame
	# Car is up, skewed, going upside-down, junk + enemies in frame. Slow-mo can end after closeups.


func _closeups() -> void:
	if not _alive():
		return
	_hold_cam(van.global_position + Vector2(40.0, -30.0))
	_face_card("NOOOO", Palette.BRICK)
	Juice.shout("NOOOO")
	VoBank.father_nooo()
	Juice.pulse_shake(3.0)
	await get_tree().create_timer(0.72, true, false, true).timeout
	_face_card("AAAA", Palette.LEMON)
	Juice.shout("AAAA")
	VoBank.son_aaa()
	await get_tree().create_timer(0.86, true, false, true).timeout
	_banner.visible = false


func _new_angle_crash() -> void:
	_restore_time()
	_letterbox(0.22)
	_hold_cam(Vector2(land_x - 40.0, 390.0))
	Juice.shout("…")
	await get_tree().create_timer(0.32, true, false, true).timeout
	if not _alive():
		return
	van.global_position = Vector2(land_x, 498.0)
	van.rotation = 2.95
	van.seat_keep()
	Juice.pulse_shake(12.0)
	Juice.freeze_frames(7)
	Juice.shout("CRASH")
	Mixer.play_sfx("res://assets/audio/finish.wav" if ResourceLoader.exists("res://assets/audio/finish.wav") else "res://assets/audio/hit_heavy.wav", 0.72)
	_spawn_junk(8)
	_kill_near_side()
	await get_tree().create_timer(0.55, true, false, true).timeout
	_letterbox(0.0)


func _crawl_talk() -> void:
	if van and is_instance_valid(van):
		van.release_seats()
	var wreck := van.global_position if van and is_instance_valid(van) else Vector2(land_x, 500.0)
	if van and is_instance_valid(van):
		van.queue_free()
		van = null
	var a := son if son else dad
	var b := dad if dad and dad != a else son
	if a and is_instance_valid(a):
		a.rotation = 0.0
		a.global_position = wreck + Vector2(-54.0, 8.0)
		a.hop = 10.0
		a.crawling = 1.35
	if b and is_instance_valid(b) and b != a:
		b.rotation = 0.0
		b.global_position = wreck + Vector2(78.0, -6.0)
		b.hop = 12.0
		b.crawling = 1.55
	if cam:
		cam.cinematic_on = false
		cam.targets = _targets()
	Juice.unlock_logo("DITCHED", "Far side of the canal. They don't follow. That's the bit.", "CHASE OVER  ·  CRAWL")
	Juice.toast("quest", "ON FOOT", "Crawl out. Then somebody with a clipboard walks in.")
	await get_tree().create_timer(1.45, true, false, true).timeout
	if a and is_instance_valid(a):
		a.hop = 0.0
		a.crawling = 0.0
	if b and is_instance_valid(b):
		b.hop = 0.0
		b.crawling = 0.0
	var talk := _talk()
	if talk == null:
		return
	var lines: Array = [
		{"who": "son", "text": "I crawled out of a lemon. That's not a metaphor. That's citrus with a title."},
		{"who": "father", "text": "I networked. With a canal. LinkedIn does not have a field for that."},
		{"who": "son", "text": "The water ate the chase. Enemies don't swim invoices. That's the bit."},
		{"who": "father", "text": "If a helicopter walks in I'm going to bill it. Dead serious."}
	]
	talk.play(lines, true)
	while talk.busy():
		await get_tree().process_frame


func _boss_walks_in() -> void:
	var act := get_tree().get_first_node_in_group("run_act")
	if act and act.has_method("spawn_deferred_boss"):
		act.spawn_deferred_boss()
	Juice.toast("quest", "BOSS INTRO", "The crash was the greeting. Invoice Chopper still wants a signature.")
	Juice.shout("CLIPBOARD")


func _spawn_junk(n: int) -> void:
	if not _alive():
		return
	for i in n:
		var p := Polygon2D.new()
		p.color = Color(0.92, 0.82, 0.22) if i % 3 == 0 else (Color(0.2, 0.7, 0.85) if i % 3 == 1 else Color(0.45, 0.4, 0.38))
		var s := 6.0 + float(i % 5) * 3.0
		p.polygon = PackedVector2Array([
			Vector2(-s, -s * 0.4), Vector2(s, -s * 0.6), Vector2(s * 0.7, s), Vector2(-s * 0.8, s * 0.5)
		])
		p.global_position = van.global_position + Vector2(randf_range(-40, 50), randf_range(-24, 10))
		p.z_index = 8
		host.add_child(p)
		_junk.append({
			"n": p,
			"v": Vector2(randf_range(-80, 260), randf_range(-420, -80)),
			"spin": randf_range(-8, 8)
		})


func _fling_near() -> void:
	if van == null:
		return
	var grabbed := 0
	for n in get_tree().get_nodes_in_group("enemies"):
		if grabbed >= 5:
			break
		if not (n is Node2D) or not is_instance_valid(n):
			continue
		if n is ActBoss and not (n as ActBoss).is_mini:
			continue
		var p: Node2D = n
		if p.global_position.distance_to(van.global_position) > 420.0:
			continue
		if n is Punk:
			(n as Punk).flung = true
			(n as Punk).snared = 99.0
		_flung.append(p)
		grabbed += 1


func _kill_near_side() -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n):
			continue
		if n is ActBoss and not (n as ActBoss).is_mini:
			continue
		if n is Node2D and (n as Node2D).global_position.x < land_x - 180.0:
			n.queue_free()
	for j in _junk:
		var node: Node2D = j.get("n")
		if node and is_instance_valid(node) and node.global_position.y > 640.0:
			node.queue_free()
	_flung.clear()


func _face_card(word: String, color: Color) -> void:
	_banner.text = word
	_banner.visible = true
	_banner.add_theme_color_override("font_color", color)
	_banner.scale = Vector2(0.6, 0.6)
	_banner.pivot_offset = _banner.size * 0.5
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.14)


func _letterbox(a: float) -> void:
	var bars := _overlay.get_node_or_null("Bars") as ColorRect
	if bars == null:
		return
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(bars, "color", Color(0, 0, 0, a), 0.18)


func _hold_cam(at: Vector2) -> void:
	if cam == null:
		return
	cam.cinematic_on = true
	cam.cinematic = at


func _talk() -> Talk:
	var act := get_tree().get_first_node_in_group("run_act")
	if act and act.get("_talk") is Talk:
		return act._talk
	for n in get_tree().get_nodes_in_group("run_act"):
		if n.get("_talk") is Talk:
			return n._talk
	return null


func _targets() -> Array[Node2D]:
	var t: Array[Node2D] = []
	if son and is_instance_valid(son):
		t.append(son)
	if dad and is_instance_valid(dad) and dad != son:
		t.append(dad)
	return t


func _alive() -> bool:
	return van != null and is_instance_valid(van)


func _restore_time() -> void:
	Juice.restore_time()


func _abort() -> void:
	_restore_time()
	if cam:
		cam.cinematic_on = false
	if van and is_instance_valid(van):
		van.release_seats()
		van.queue_free()
	finished.emit()
	queue_free()
