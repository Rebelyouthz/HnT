class_name ManualRack
extends Node2D

## Twin-stick MANUAL weapons in the survivor hours. Auto weapons fire on
## their own; the manual ones are aimed (right stick / mouse) and share one
## trigger: only the ACTIVE manual weapon fires. Each has a magazine. When it
## runs dry the hero snaps to the next manual weapon that still has rounds
## (a quick swap); when every magazine is empty, all of them reload at once
## (mag drops, a ring fills round the feet, mag-in click). Ammo pips sit
## under the hero; the active weapon's name flashes on a swap.

## Rounds per magazine (+ per level above 1).
const MAG := {"nail_driver": [24, 3], "paperweight": [4, 1], "sprayer": [6, 1], "rivet_rifle": [8, 1]}
const SWAP := 0.14
const RELOAD := 1.25

var f: Fighter
var ammo: Dictionary = {}
var active := ""
var _reload := 0.0
var _swap := 0.0
var _flash := 0.0


static func of(fighter: Fighter) -> ManualRack:
	var r := fighter.get_node_or_null("ManualRack") as ManualRack
	if r == null:
		r = ManualRack.new()
		r.name = "ManualRack"
		r.f = fighter
		fighter.add_child(r)
	return r


func _ready() -> void:
	z_index = 20
	z_as_relative = false


func _run() -> SurviveRun:
	return SurviveRun.get_run(get_tree())


## Manual weapons this hero owns, in the order they were taken.
func owned() -> Array:
	var run := _run()
	var out: Array = []
	if run == null:
		return out
	for id: String in run.abilities.keys():
		if bool(run.row("abilities", id).get("manual", false)):
			out.append(id)
	return out


func mag_size(id: String) -> int:
	var run := _run()
	var spec: Array = MAG.get(id, [8, 1])
	var lv := int(run.abilities.get(id, 1)) if run else 1
	var n := int(spec[0]) + int(spec[1]) * (lv - 1)
	if run and run.evolved.has(id):
		n = int(n * 1.5)
	return n


func reloading() -> bool:
	return _reload > 0.0


## The ability asks before firing: only the active weapon, never mid-swap
## or mid-reload, and only with a round in it.
func can_fire(id: String) -> bool:
	_sync()
	return id == active and _reload <= 0.0 and _swap <= 0.0 and int(ammo.get(id, 0)) > 0


func spend(id: String) -> void:
	ammo[id] = maxi(0, int(ammo.get(id, 0)) - 1)
	if int(ammo[id]) > 0:
		return
	# Dry: next loaded weapon, or reload everything.
	for w in owned():
		if int(ammo.get(w, 0)) > 0:
			_swap_to(w)
			return
	_start_reload()


## Manual reload (all magazines), e.g. a long press of SNAP.
func force_reload() -> void:
	if _reload <= 0.0:
		_start_reload()


func _sync() -> void:
	for w in owned():
		if not ammo.has(w):
			ammo[w] = mag_size(w)
			if active == "":
				active = w
	if active != "" and not owned().has(active):
		active = ""
	if active == "" and not owned().is_empty():
		active = owned()[0]


func _swap_to(w: String) -> void:
	active = w
	_swap = SWAP
	_flash = 0.9
	Mixer.play_sfx("res://assets/audio/sfx/mag_in.ogg" if ResourceLoader.exists("res://assets/audio/sfx/mag_in.ogg") else "res://assets/audio/cling.wav", 1.5, -10.0)


func _start_reload() -> void:
	var run := _run()
	_reload = RELOAD * (run.cd_mul() if run else 1.0)
	if is_instance_valid(f):
		# The held gun tips up for the mag change (Fighter._place_gun).
		f.reload_t = _reload
		f.set("_reload_len", _reload)
		f.aim_t = maxf(f.aim_t, _reload + 0.1)
		GunFx.mag(f.get_parent(), f.global_position + Vector2(float(f.facing) * 6.0, -34.0), "pistol", f.facing, f.global_position.y + 4.0)
		Juice.popup_number(f.global_position + Vector2(0, -110), "RELOAD", Color(0.9, 0.9, 1.0))
		VoBank.line(f.role, "reload", 0.4)
	Mixer.play_sfx("res://assets/audio/sfx/mag_out.ogg" if ResourceLoader.exists("res://assets/audio/sfx/mag_out.ogg") else "res://assets/audio/cling.wav", 1.0, -6.0)


func _process(delta: float) -> void:
	_sync()
	if _swap > 0.0:
		_swap -= delta
	if _flash > 0.0:
		_flash -= delta
	if _reload > 0.0:
		_reload -= delta
		if _reload <= 0.0:
			for w in owned():
				ammo[w] = mag_size(w)
			if not owned().is_empty():
				active = owned()[0]
			_flash = 0.9
			Mixer.play_sfx("res://assets/audio/sfx/mag_in.ogg" if ResourceLoader.exists("res://assets/audio/sfx/mag_in.ogg") else "res://assets/audio/cling.wav", 1.0, -4.0)
			if is_instance_valid(f):
				f._squash_to(Vector2(1.03, 0.97))
	# Cycle by hand: tap SNAP to switch to the next loaded weapon.
	if is_instance_valid(f) and owned().size() > 1 and f.call("_just", "snap") and _reload <= 0.0:
		var list := owned()
		var i := list.find(active)
		for k in range(1, list.size() + 1):
			var w: String = list[(i + k) % list.size()]
			if int(ammo.get(w, 0)) > 0:
				_swap_to(w)
				break
	queue_redraw()


func _draw() -> void:
	var list := owned()
	if list.is_empty() or not is_instance_valid(f):
		return
	var font := ThemeDB.fallback_font
	var base := Vector2(0, 14)
	if _reload > 0.0:
		var run := _run()
		var full := RELOAD * (run.cd_mul() if run else 1.0)
		var p := 1.0 - _reload / maxf(0.01, full)
		draw_arc(base + Vector2(0, -2), 18.0, -PI * 0.5, -PI * 0.5 + TAU * p, 32, Color(0.95, 0.9, 0.5, 0.9), 3.0)
		draw_arc(base + Vector2(0, -2), 18.0, 0.0, TAU, 32, Color(0, 0, 0, 0.35), 1.0)
		return
	# Active weapon's rounds as pips (big mags as a bar).
	var n := int(ammo.get(active, 0))
	var cap := maxi(1, mag_size(active))
	if cap <= 10:
		var w := 5.0
		var x0 := -float(cap) * (w + 2.0) * 0.5
		for i in cap:
			var r := Rect2(base + Vector2(x0 + float(i) * (w + 2.0), 0), Vector2(w, 4))
			draw_rect(r, Color(1.0, 0.85, 0.35) if i < n else Color(0.15, 0.15, 0.2, 0.8))
	else:
		var r := Rect2(base + Vector2(-26, 0), Vector2(52, 4))
		draw_rect(r, Color(0.1, 0.1, 0.14, 0.85))
		draw_rect(Rect2(r.position, Vector2(52.0 * float(n) / float(cap), 4)), Color(1.0, 0.85, 0.35))
	# Other weapons: tiny dots, lit while they still hold rounds.
	var dx := -float(list.size() - 1) * 4.0
	for w2 in list:
		var lit := int(ammo.get(w2, 0)) > 0
		draw_circle(base + Vector2(dx, 9), 2.0 if w2 != active else 2.8, (Color(0.45, 1.0, 0.6) if w2 == active else Color(0.8, 0.8, 0.85)) if lit else Color(0.3, 0.3, 0.35))
		dx += 8.0
	if _flash > 0.0:
		var run2 := _run()
		var nm := str(run2.row("abilities", active).get("name", active)) if run2 else active
		var a := clampf(_flash / 0.3, 0.0, 1.0)
		var sz := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		draw_string_outline(font, Vector2(-sz.x * 0.5, 34), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0, 0, 0, a))
		draw_string(font, Vector2(-sz.x * 0.5, 34), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.45, 1.0, 0.6, a))
