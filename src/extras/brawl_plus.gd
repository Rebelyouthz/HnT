class_name BrawlPlus
extends RefCounted

## Ten small brawl rules on top of the fighting (story mode and survivor):
##   BACKSTAB       +25% on a thug facing away from you
##   INTERRUPT      a hit during a thug's wind-up: +40%, the swing is cancelled
##   JUGGLE         every extra hit on an airborne thug +10% (JUGGLE xN)
##   TAUNT          double-tap DUCK: CHI and TEAM, more with thugs close
##   CLUTCH         once a night a lethal hit leaves you on 1 HP
##   FLINCH         three kills in two seconds and the rest of them falter
##   PROP SLAM      a flung thug hitting a lamp post or a car takes more
##   PERFECT DODGE  roll as a swing lands: slow motion, CHI
##   TOGETHER       Dad and Son close to each other hit 10% harder
##   LAST HIT       a melee weapon breaking on a thug takes him with it

const BACKSTAB := 1.25
const INTERRUPT := 1.4
const TOGETHER := 1.1


static func _pop(at: Vector2, txt: String, col: Color, node: Node, key: String, gap := 0.6) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if node and now - float(node.get_meta(key, -9.0)) < gap:
		return
	if node:
		node.set_meta(key, now)
	Juice.popup_number(at, txt, col)


## Damage scaling for a hero's blow on a thug (Punk.take_hit).
static func on_blow(e: Punk, f: Fighter, kind: String, dmg: int) -> int:
	var m := 1.0
	var head := e.global_position + Vector2(0, -98)
	# BACKSTAB
	if e.facing * signf(f.global_position.x - e.global_position.x) < 0.0 and kind != "throw":
		m *= BACKSTAB
		_pop(head, "BACKSTAB", Color(1.0, 0.55, 0.3), e, "bp_back")
	# INTERRUPT
	if e.telegraph > 0.0 and kind != "throw":
		m *= INTERRUPT
		e.telegraph = 0.0
		e.atk_height = ""
		e.recover = maxf(e.recover, 0.6)
		_pop(head + Vector2(0, -14), "INTERRUPT", Color(0.6, 0.9, 1.0), e, "bp_int", 0.2)
		f.chi = minf(Elements.CHI_MAX, f.chi + 4.0)
	# JUGGLE
	var airborne := e.flung or (e.visual != null and e.visual.position.y < -12.0)
	if airborne:
		var n := int(e.get_meta("juggle", 0)) + 1
		e.set_meta("juggle", n)
		m *= 1.0 + 0.1 * float(n)
		if n >= 2:
			Juice.popup_number(head + Vector2(0, -28), "JUGGLE x%d" % n, UiKit.GOLD)
	else:
		e.set_meta("juggle", 0)
	# TOGETHER
	for p in f.get_tree().get_nodes_in_group("players"):
		if p is Fighter and p != f and not (p as Fighter).downed and (p as Fighter).global_position.distance_to(f.global_position) < 130.0:
			m *= TOGETHER
			break
	return BrawlMore.on_blow(e, f, kind, int(round(float(dmg) * m)))


## FLINCH: called when a hero kills.
static func on_kill(f: Fighter, at: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var times: Array = f.get_meta("bp_kills", [])
	times.append(now)
	while times.size() > 0 and now - float(times[0]) > 2.0:
		times.pop_front()
	f.set_meta("bp_kills", times)
	if times.size() >= 3 and now - float(f.get_meta("bp_flinch", -9.0)) > 4.0:
		f.set_meta("bp_flinch", now)
		var n := 0
		for m in f.get_tree().get_nodes_in_group("enemies"):
			if m is Punk and (m as Punk).hp > 0 and not (m is ActBoss) and (m as Punk).global_position.distance_to(at) < 220.0:
				(m as Punk).recover = maxf((m as Punk).recover, 1.4)
				(m as Punk).telegraph = 0.0
				n += 1
		if n > 0:
			Juice.shout("THEY FLINCH")
			Juice.pulse_shake(3.0)


## TAUNT: double-tap DUCK while standing (Fighter._combat).
static func taunt(f: Fighter) -> void:
	var close := 0
	for m in f.get_tree().get_nodes_in_group("enemies"):
		if m is Punk and (m as Punk).hp > 0 and absf((m as Punk).global_position.x - f.global_position.x) < 140.0:
			close += 1
	var gain := 10.0 + 8.0 * float(mini(close, 3))
	f.chi = minf(Elements.CHI_MAX, f.chi + gain)
	f.team = minf(Elements.TEAM_MAX, f.team + 4.0 + 2.0 * float(mini(close, 3)))
	f.art_lock = 0.55
	f.art_vx = 0.0
	if f._anim and f._anim.sprite_frames.has_animation("idle"):
		f.anim_atk = "idle"
		f._atk_t = 0.5
	var lines := ["COME ON", "IS THAT IT", "MY DAD HITS HARDER", "YOU CALL THAT A COPAY"] if f.role == "son" else ["SIT DOWN", "I HAVE A MORTGAGE", "BACK IN MY DAY", "THAT'S GROUNDING"]
	Juice.popup_number(f.global_position + Vector2(0, -104), str(lines[randi() % lines.size()]), UiKit.GOLD)
	Juice.popup_number(f.global_position + Vector2(0, -84), "+%d CHI" % int(gain), Elements.color("fire"))
	VoBank.line(f.role, "banter", 0.7)


## CLUTCH: a lethal hit once a night (story runs only).
static func clutch(f: Fighter) -> bool:
	if bool(f.get_meta("bp_clutch", false)) or SurviveRun.get_run(f.get_tree()) != null:
		return false
	f.set_meta("bp_clutch", true)
	f.hp = 1
	f.invuln = maxi(f.invuln, 70)
	Juice.shout("NOT TODAY")
	Juice.named_slowmo()
	Juice.pulse_shake(8.0)
	ArtFx.spawn(f.get_parent(), f.global_position, "ring", Color(1.0, 0.3, 0.3), 140.0, 0.5)
	for m in f.get_tree().get_nodes_in_group("enemies"):
		if m is Punk and (m as Punk).global_position.distance_to(f.global_position) < 140.0:
			(m as Punk).recover = maxf((m as Punk).recover, 1.0)
			(m as Punk).global_position.x += signf((m as Punk).global_position.x - f.global_position.x) * 40.0
	return true


## PERFECT DODGE: rolling as a swing is about to land.
static func dodge(f: Fighter) -> void:
	for m in f.get_tree().get_nodes_in_group("enemies"):
		if m is Punk:
			var e: Punk = m
			if e.telegraph > 0.0 and e.telegraph < 0.2 and e.global_position.distance_to(f.global_position) < 80.0:
				f.invuln = maxi(f.invuln, 34)
				f.chi = minf(Elements.CHI_MAX, f.chi + 10.0)
				Juice.named_slowmo()
				Juice.popup_number(f.global_position + Vector2(0, -100), "PERFECT DODGE", Color(0.6, 1.0, 0.8))
				Mixer.play_sfx("res://assets/audio/sfx/sense_dodge.ogg", 1.0, -3.0)
				return


## PROP SLAM: a flung thug running into a lamp post or a car.
static func prop_slam(e: Punk) -> void:
	if bool(e.get_meta("bp_slam", false)):
		return
	for g in ["street_lamps", "slam_props"]:
		for n in e.get_tree().get_nodes_in_group(g):
			if n is Node2D:
				var w := float((n as Node2D).get_meta("half_w", 12.0))
				var dx := absf((n as Node2D).global_position.x - e.global_position.x)
				if dx < w and absf((n as Node2D).global_position.y - e.global_position.y) < 30.0:
					e.set_meta("bp_slam", true)
					e.hp = maxi(0 if e.hp <= 12 else 1, e.hp - 12)
					e.flung_t = 0.0
					Juice.shout("PROP SLAM")
					Juice.pulse_shake(6.0)
					Juice.hitstop(5)
					Juice.sparks(e.global_position + Vector2(0, -40))
					Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", 0.9, -2.0)
					if e.hp <= 0:
						e.take_hit("finish", e)
					return


## LAST HIT: a breaking weapon finishes what it hit.
static func last_hit(f: Fighter, at: Vector2) -> void:
	var best: Punk = null
	var bd := 70.0
	for m in f.get_tree().get_nodes_in_group("enemies"):
		if m is Punk and (m as Punk).hp > 0 and (m as Punk).global_position.distance_to(at) < bd:
			bd = (m as Punk).global_position.distance_to(at)
			best = m
	if best:
		best.take_hit("heavy", f)
		Juice.popup_number(best.global_position + Vector2(0, -110), "LAST HIT", Color(1.0, 0.85, 0.4))
