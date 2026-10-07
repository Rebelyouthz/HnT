class_name WoundGait
extends RefCounted

## How a hurt thug carries himself, and how the living deal with the dead.
##   LIMP     a leg wound (or low HP from below): slower, dipping on the bad
##            leg every other step
##   CLUTCH   a gut wound: folded over the hole, slower, now and then stops
##            to hold it, dripping
##   DAZED    head blows: a slow sway, a touch slower
##   SCOOT    on FINISH health some lose their nerve: down on the backside,
##            shuffling away from the hero, begging with their hands
##   TRIP     walking over a body on the street can take the legs out
##   DRAG     a thug waiting his turn sometimes drags a dead friend out of
##            the way, leaving a smear
## Bosses, vehicles and fliers are exempt. Art poses go on the sprite
## (_anim) so hit reactions on `visual` still play on top.

const HURT := 0.35


static func exempt(p: Punk) -> bool:
	return p is ActBoss or p.vehicle != "" or p.home != "street" or p._anim == null


## "", "limp", "clutch", "dazed" or "scoot".
static func mode(p: Punk) -> String:
	if exempt(p) or p.hp <= 0:
		return ""
	if p.has_meta("scoot"):
		return "scoot"
	if float(p.hp) > float(p.max_hp) * HURT:
		return ""
	match str(p._last_zone):
		"low", "legs", "crush":
			return "limp"
		"gut", "blade", "bullet":
			return "clutch"
	return "dazed"


static func speed_mul(p: Punk) -> float:
	match mode(p):
		"limp":
			return 0.55
		"clutch":
			return 0.7
		"dazed":
			return 0.85
	return 1.0


## Takes over the chase when the thug is scooting away or dragging a body.
## True when it set the velocity itself.
static func override(p: Punk, t: Node2D, delta: float) -> bool:
	if exempt(p):
		return false
	var away := -signf(t.global_position.x - p.global_position.x)
	if away == 0.0:
		away = 1.0
	# Lost his nerve at FINISH health (once per thug, not every time).
	if p.crush and not p.has_meta("scoot_rolled"):
		p.set_meta("scoot_rolled", true)
		if randf() < 0.4:
			p.set_meta("scoot", true)
			Juice.popup_number(p.global_position + Vector2(0, -100), str(["WAIT WAIT", "NOT THE FACE", "I HAVE KIDS", "OK OK OK"][randi() % 4]), Color(0.9, 0.85, 0.75))
	if p.has_meta("scoot"):
		var stutter := maxf(0.0, sin(Time.get_ticks_msec() / 1000.0 * 7.0 + float(p.get_instance_id() % 11)))
		p.velocity.x = away * p.speed * 0.28 * stutter
		return true
	var dragged: Variant = p.get_meta("dragging") if p.has_meta("dragging") else null
	if dragged != null and not is_instance_valid(dragged):
		p.remove_meta("dragging")
		dragged = null
	if dragged is DeathFall:
		var body := dragged as DeathFall
		if body.drag_t <= 0.0:
			p.remove_meta("dragging")
			return false
		p.velocity.x = away * p.speed * 0.45
		return true
	# A waiting thug with a body at his feet may haul it off the street.
	if CrowdAI.role(p, t) == "wait" and randf() < 0.25 * delta:
		for n in p.get_tree().get_nodes_in_group("corpses"):
			if n is DeathFall and (n as DeathFall).settled and (n as DeathFall).dragger == null:
				var b := n as DeathFall
				if absf(b.gx - p.global_position.x) < 60.0 and absf(b.gy - p.global_position.y) < 26.0:
					b.start_drag(p, away)
					p.set_meta("dragging", b)
					return true
	return false


## After moving: trip over bodies on the street.
static func underfoot(p: Punk, delta: float) -> void:
	if exempt(p) or p.recover > 0.0 or absf(p.velocity.x) < 40.0:
		return
	var cd := float(p.get_meta("trip_cd", 0.0)) - delta
	p.set_meta("trip_cd", cd)
	if cd > 0.0 or p.has_meta("dragging"):
		return
	for n in p.get_tree().get_nodes_in_group("corpses"):
		if not (n is DeathFall) or not (n as DeathFall).settled:
			continue
		var b := n as DeathFall
		if absf(b.gx - p.global_position.x) < b.H * 0.35 and absf(b.gy - p.global_position.y) < 10.0:
			p.set_meta("trip_cd", 3.0)
			# Most step over; some catch a foot.
			if randf() < 0.45:
				var dir := signf(p.velocity.x)
				p.recover = maxf(p.recover, 0.55)
				p.telegraph = 0.0
				HitReact.react(p.visual, p.facing, "trip", -dir * float(p.facing), 0.9)
				Juice.land_puff(p.global_position + Vector2(dir * 10.0, 0))
				Mixer.play_sfx("res://assets/audio/stumble.wav", randf_range(0.9, 1.1), -6.0)
			return


## The art pose for the gait, every frame.
static func pose(p: Punk, delta: float) -> void:
	var a: AnimatedSprite2D = p._anim
	if a == null:
		return
	if not a.has_meta("base_y"):
		a.set_meta("base_y", a.position.y)
	var base: float = a.get_meta("base_y")
	var m := mode(p)
	var tick := Time.get_ticks_msec() / 1000.0 + float(p.get_instance_id() % 13)
	var rot := 0.0
	var dy := 0.0
	var walking := absf(p.velocity.x) > 10.0
	match m:
		"limp":
			var step := maxf(0.0, sin(tick * 6.0)) if walking else 0.0
			# (negative rotation leans the art toward its front)
			rot = -0.14 * step
			dy = 5.0 * step
		"clutch":
			rot = -0.26 - 0.03 * sin(tick * 2.0)
			dy = 4.0
			if randf() < delta * 0.5:
				var blood := p.get_tree().get_first_node_in_group("blood_sim")
				if blood and blood.has_method("burst"):
					blood.burst(p.global_position + Vector2(float(p.facing) * 6.0, -34), p.global_position.y, float(p.facing) * 0.1, {"n": 2, "speed": 16.0, "spread": 1.0, "rise": 0.0, "size": 0.8})
		"dazed":
			rot = 0.11 * sin(tick * 1.6)
		"scoot":
			# Down on the backside, leaning away from the hero.
			var h := float(a.get_meta("art_h", 0.0))
			if h <= 0.0:
				var tex := a.sprite_frames.get_frame_texture(a.animation, a.frame)
				h = HitReact._used_rect(tex).size.y * absf(a.scale.y) if tex else 80.0
				a.set_meta("art_h", h)
			rot = 0.62 + 0.05 * sin(tick * 7.0)
			dy = h * 0.22
	a.rotation = lerpf(a.rotation, rot, minf(1.0, delta * 10.0))
	a.position.y = lerpf(a.position.y, base + dy, minf(1.0, delta * 10.0))
