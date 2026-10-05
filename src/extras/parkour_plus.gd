class_name ParkourPlus
extends Node2D

## Ten parkour things on every map with roofs (one per run, from RunAct):
##   SPEED LINES     streaks across the screen when running flat out
##   AFTERIMAGES     a cyan trail of the body while dashing fast
##   GHOST           your best run to the goal replays as a blue ghost
##   SPLIT TIMES     at the checkpoint: time and +/- against your best
##   GRAFFITI TAGS   five hidden tags per map on ladders and web points
##   AIR TIME        long airs pay FLOW ("AIR TIME 1.4s")
##   HEAVY LANDING   dust ring and a camera dip after a long fall
##   PRECISION PADS  chalk marks on roof edges: land on one for FLOW
##   MEDALS          bronze / silver / gold time at the goal, best kept
##   WALL-RUN SPARKS sparks and dust from the feet on a wall run

var act: Node
var map_id := ""
var goal_x := 99999.0
var check_x := 0.0
var _t := 0.0
var _done := false
var _split_done := false
var _rec: PackedVector2Array = []
var _rec_t := 0.0
var _ghost_path: PackedVector2Array = []
var _ghost: Node2D
var _ghost_anim: AnimatedSprite2D
var _air := {}
var _after_t := 0.0
var _spark_t := 0.0
var _lines: SpeedLines
var _tags: Array[Node2D] = []
var _pads: Array[Vector2] = []
var _pad_hit := {}


static func place(host: Node, mid: String, goal: float, check: float) -> ParkourPlus:
	var p := ParkourPlus.new()
	p.act = host
	p.map_id = mid
	p.goal_x = goal
	p.check_x = check
	p.z_index = 1
	host.add_child(p)
	return p


var _clock_l: Label


func _ready() -> void:
	_lines = SpeedLines.new()
	add_child(_lines)
	call_deferred("_setup")
	# RACE THE CLOCK on the roof maps: the medal times on screen from the start.
	if bool(act.get("roof_start")):
		var layer := CanvasLayer.new()
		layer.layer = 6
		add_child(layer)
		var root := PixelStage.attach_canvas(layer)
		_clock_l = Label.new()
		_clock_l.position = Vector2(0, 92)
		_clock_l.size = Vector2(1280, 20)
		_clock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiKit.apply_label(_clock_l, 14, Color(0.6, 0.9, 1.0))
		root.add_child(_clock_l)
		var g := goal_x / 240.0
		Juice.toast("reward", "RACE THE CLOCK", "GOLD %.0fs  ·  SILVER %.0fs  ·  BRONZE %.0fs" % [g, g * 1.35, g * 1.8])


func _setup() -> void:
	var g: Variant = FamilyProfile.data.get("ghost_" + map_id)
	if g is Array and (g as Array).size() > 4:
		for v in g:
			if v is Array and (v as Array).size() == 2:
				_ghost_path.append(Vector2(float(v[0]), float(v[1])))
	if not _ghost_path.is_empty() and SpriteBook.has_who("son"):
		_ghost = Node2D.new()
		_ghost.modulate = Color(0.45, 0.75, 1.0, 0.35)
		_ghost.z_index = 1
		act.add_child(_ghost)
		_ghost_anim = SpriteBook.make_anim("son")
		SpriteBook.grow(_ghost_anim, SpriteBook.FIGHTER_SCALE)
		_ghost.add_child(_ghost_anim)
		if _ghost_anim.sprite_frames.has_animation("parkour_run"):
			_ghost_anim.play("parkour_run")
	_place_tags()
	_place_pads()
	# A chest on the highest roof: worth the climb.
	var top_r := Rect2()
	for r in get_tree().get_nodes_in_group("roof_solids"):
		var rect: Rect2 = r.get_meta("rect", Rect2())
		if rect.size.x > 100.0 and (top_r.size == Vector2.ZERO or rect.position.y < top_r.position.y):
			top_r = rect
	if top_r.size != Vector2.ZERO:
		var c := SurviveChest.new()
		c.global_position = Vector2(top_r.end.x - 50.0, top_r.position.y)
		act.add_child.call_deferred(c)


func _place_tags() -> void:
	var spots: Array[Vector2] = []
	for n in get_tree().get_nodes_in_group("ladders"):
		if n is Node2D:
			spots.append(Vector2((n as Node2D).get("climb_x"), float((n as Node2D).get("top_y")) - 40.0))
	for n in get_tree().get_nodes_in_group("web_anchors"):
		if n is Node2D:
			spots.append((n as Node2D).global_position + Vector2(0, 30))
	for r in get_tree().get_nodes_in_group("roof_solids"):
		var rect: Rect2 = r.get_meta("rect", Rect2())
		if rect.size.x > 200.0:
			spots.append(Vector2(rect.end.x - 30.0, rect.position.y - 60.0))
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var got: Array = (FamilyProfile.data.get("tags", {}) as Dictionary).get(map_id, [])
	var step := maxi(1, spots.size() / 5)
	var k := 0
	for i in range(0, spots.size(), step):
		if k >= 5:
			break
		var tag := Tag.new()
		tag.id = k
		tag.taken = got.has(k)
		tag.global_position = spots[i]
		act.add_child.call_deferred(tag)
		_tags.append(tag)
		k += 1


func _place_pads() -> void:
	for r in get_tree().get_nodes_in_group("roof_solids"):
		var rect: Rect2 = r.get_meta("rect", Rect2())
		if rect.size.x < 120.0:
			continue
		for x in [rect.position.x + 26.0, rect.end.x - 26.0]:
			var at := Vector2(x, rect.position.y)
			_pads.append(at)
			var mark := Pad.new()
			mark.global_position = at
			act.add_child.call_deferred(mark)


func _players() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			out.append(n)
	return out


func _physics_process(delta: float) -> void:
	_t += delta
	var ps := _players()
	if ps.is_empty():
		return
	var lead := ps[0]
	for f in ps:
		if f.global_position.x > lead.global_position.x:
			lead = f
	# GHOST: record the lead, replay the best.
	_rec_t -= delta
	if _rec_t <= 0.0 and not _done:
		_rec_t = 0.1
		_rec.append(lead.global_position + Vector2(0, lead.visual.position.y))
	if _ghost and not _ghost_path.is_empty():
		var i := clampi(int(_t / 0.1), 0, _ghost_path.size() - 1)
		var j := mini(i + 1, _ghost_path.size() - 1)
		var u := fmod(_t, 0.1) / 0.1
		var gp := _ghost_path[i].lerp(_ghost_path[j], u)
		if gp.x < _ghost.global_position.x - 1.0:
			_ghost_anim.scale.x = -absf(_ghost_anim.scale.x)
		elif gp.x > _ghost.global_position.x + 1.0:
			_ghost_anim.scale.x = absf(_ghost_anim.scale.x)
		_ghost.global_position = gp
		_ghost.visible = i < _ghost_path.size() - 1
	# SPLIT / GOAL
	if not _split_done and check_x > 0.0 and lead.global_position.x >= check_x:
		_split_done = true
		var best := float(FamilyProfile.data.get("split_" + map_id, 0.0))
		var txt := "SPLIT %.1fs" % _t
		var col := Palette.TEXT
		if best > 0.0:
			txt += "  %s%.1f" % ["+" if _t > best else "-", absf(_t - best)]
			col = Palette.READY if _t <= best else Palette.BRICK
		if best <= 0.0 or _t < best:
			FamilyProfile.data["split_" + map_id] = _t
		Juice.popup_number(lead.global_position + Vector2(0, -120), txt, col)
	if not _done and lead.global_position.x >= goal_x:
		_finish()
	for f in ps:
		_feet(f, delta)
	_lines.speed = absf(lead.velocity.x)
	if _clock_l:
		var g := goal_x / 240.0
		var next := "GOLD" if _t <= g else ("SILVER" if _t <= g * 1.35 else ("BRONZE" if _t <= g * 1.8 else "NO MEDAL"))
		_clock_l.text = ("%.1fs  ·  ON PACE FOR %s" % [_t, next]) if not _done else "FINISHED %.1fs" % float(FamilyProfile.data.get("best_" + map_id, _t))


func _feet(f: Fighter, delta: float) -> void:
	var key := f.get_instance_id()
	var airborne := f.hop < -10.0 or (f.plane == "roof" and not f.is_on_floor())
	var a: float = _air.get(key, 0.0)
	if airborne:
		_air[key] = a + delta
	elif a > 0.0:
		_air[key] = 0.0
		_landed(f, a)
	# AFTERIMAGES
	_after_t -= delta
	if (f.dashing or absf(f.velocity.x) > 380.0) and _after_t <= 0.0 and f._anim:
		_after_t = 0.05
		var s := Sprite2D.new()
		s.texture = f._anim.sprite_frames.get_frame_texture(f._anim.animation, f._anim.frame)
		s.global_transform = f._anim.global_transform
		s.centered = f._anim.centered
		s.offset = f._anim.offset
		s.modulate = Color(0.45, 0.85, 1.0, 0.45)
		s.z_index = 1
		act.add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "modulate:a", 0.0, 0.25)
		tw.tween_callback(s.queue_free)
	# WALL-RUN SPARKS
	_spark_t -= delta
	if f.wall_run > 0.0 and _spark_t <= 0.0:
		_spark_t = 0.06
		Juice.sparks(f.global_position + Vector2(-8.0 * float(f.facing), f.visual.position.y))


func _landed(f: Fighter, air: float) -> void:
	if air > 0.8:
		var n := int(round(air * 3.0))
		Trees.add_flow(n)
		Juice.popup_number(f.global_position + Vector2(0, -110), "AIR TIME %.1fs  +%d FLOW" % [air, n], Color(0.6, 0.9, 1.0))
	if air > 0.55:
		Juice.land_puff(f.global_position)
		ArtFx.spawn(act, f.global_position, "ring", Color(0.85, 0.82, 0.75), 50.0, 0.3)
		CouchCamera.punch(get_tree(), 0.03, 0.2, f.global_position)
	# PRECISION PADS
	if f.plane == "roof":
		for i in _pads.size():
			if not _pad_hit.has(i) and absf(_pads[i].x - f.global_position.x) < 14.0 and absf(_pads[i].y - f.global_position.y) < 10.0:
				_pad_hit[i] = true
				Trees.add_flow(3)
				Juice.popup_number(f.global_position + Vector2(0, -96), "PRECISION  +3 FLOW", UiKit.GOLD)
				Mixer.play_sfx("res://assets/audio/trick_perfect.wav", 1.2, -6.0)


func _finish() -> void:
	_done = true
	var key := "medal_" + map_id
	var gold_t := goal_x / 240.0
	var medal := "GOLD" if _t <= gold_t else ("SILVER" if _t <= gold_t * 1.35 else ("BRONZE" if _t <= gold_t * 1.8 else ""))
	var rank := {"": 0, "BRONZE": 1, "SILVER": 2, "GOLD": 3}
	var best_t := float(FamilyProfile.data.get("best_" + map_id, 0.0))
	if best_t <= 0.0 or _t < best_t:
		FamilyProfile.data["best_" + map_id] = _t
		var arr: Array = []
		for v in _rec:
			arr.append([snappedf(v.x, 0.1), snappedf(v.y, 0.1)])
		FamilyProfile.data["ghost_" + map_id] = arr
		Juice.popup_number(Vector2(goal_x, 200), "NEW BEST %.1fs" % _t, Palette.READY)
	if int(rank[medal]) > int(rank.get(str(FamilyProfile.data.get(key, "")), 0)):
		FamilyProfile.data[key] = medal
	if medal != "":
		Juice.shout("%s MEDAL  %.1fs" % [medal, _t])
		Trees.add_flow({"BRONZE": 3, "SILVER": 6, "GOLD": 10}[medal])
		get_tree().create_timer(1.2).timeout.connect(func() -> void: LuckyWheel.spin(get_tree(), "parkour"))
	FamilyProfile.save()


## Screen streaks at full speed.
class SpeedLines extends CanvasLayer:
	var speed := 0.0
	var _c: Control
	var _t := 0.0

	func _ready() -> void:
		layer = 4
		_c = Control.new()
		_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_c.size = Vector2(640, 360)
		_c.draw.connect(_draw_lines)
		add_child(_c)

	func _process(delta: float) -> void:
		_t += delta
		_c.queue_redraw()

	func _draw_lines() -> void:
		var k := clampf((speed - 300.0) / 200.0, 0.0, 1.0)
		if k <= 0.0:
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = int(_t * 20.0)
		for i in int(10.0 * k):
			var y := rng.randf_range(10.0, 350.0)
			var x := rng.randf_range(0.0, 640.0)
			var l := rng.randf_range(30.0, 90.0) * k
			_c.draw_line(Vector2(x, y), Vector2(x + l, y), Color(1, 1, 1, 0.12 * k), 1.0)


## A graffiti tag to find: touch it to spray your own over it.
class Tag extends Node2D:
	var id := 0
	var taken := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_t += delta
		if not taken:
			for n in get_tree().get_nodes_in_group("players"):
				if n is Fighter and ((n as Fighter).global_position + Vector2(0, (n as Fighter).visual.position.y - 30.0)).distance_to(global_position) < 34.0:
					taken = true
					var mid := str(get_parent().get("map_id"))
					var d: Dictionary = FamilyProfile.data.get("tags", {})
					var arr: Array = d.get(mid, [])
					if not arr.has(id):
						arr.append(id)
					d[mid] = arr
					FamilyProfile.data["tags"] = d
					Trees.add_flow(5)
					Juice.popup_number(global_position + Vector2(0, -30), "TAG %d/5  +5 FLOW" % arr.size(), Color(1.0, 0.4, 0.8))
					Mixer.play_sfx("res://assets/audio/spray.wav", 1.0, -4.0)
					FamilyProfile.save()
		queue_redraw()

	func _draw() -> void:
		var bob := sin(_t * 3.0) * 2.0
		if taken:
			draw_string(ThemeDB.fallback_font, Vector2(-14, 4 + bob), "F&S", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 1.0, 0.6, 0.6))
			return
		draw_circle(Vector2(0, bob), 11.0, Color(1.0, 0.3, 0.75, 0.2 + 0.1 * sin(_t * 5.0)))
		draw_rect(Rect2(-4, -9 + bob, 8, 14), Color(0.85, 0.2, 0.6))
		draw_rect(Rect2(-3, -12 + bob, 6, 3), Color(0.9, 0.9, 0.95))
		draw_circle(Vector2(0, -13 + bob), 1.5, Color(1, 1, 1))


## Chalk X on a roof edge.
class Pad extends Node2D:
	func _ready() -> void:
		z_index = 3

	func _draw() -> void:
		var c := Color(1.0, 0.9, 0.5, 0.65)
		draw_line(Vector2(-6, -4), Vector2(6, 1), c, 1.5)
		draw_line(Vector2(-6, 1), Vector2(6, -4), c, 1.5)
