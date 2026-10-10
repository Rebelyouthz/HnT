class_name ThrowKnife
extends Node2D

## A throwing knife. THROW with nobody in arm's reach and knives on the belt
## sends one spinning down the lane: a blade hit that bleeds. A miss (or a
## thug's drop) lies on the street a while; walk over it to get it back.

const SPEED := 720.0
const LIFE := 0.9
const LIE := 9.0

var by: Fighter
var dir := 1
var on_ground := false
var _t := 0.0
var _spin := 0.0
var _hit := {}


static func throw_from(f: Fighter) -> ThrowKnife:
	var k := ThrowKnife.new()
	k.by = f
	k.dir = f.facing
	k.global_position = f.global_position + Vector2(18.0 * float(f.facing), 0.0)
	f.get_parent().add_child(k)
	return k


static func drop(host: Node, at: Vector2) -> ThrowKnife:
	var k := ThrowKnife.new()
	k.on_ground = true
	k.global_position = at
	host.add_child(k)
	return k


func _ready() -> void:
	z_index = 4


func _physics_process(delta: float) -> void:
	_t += delta
	if on_ground:
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and (n as Fighter).global_position.distance_to(global_position) < 26.0:
				(n as Fighter).knives = mini((n as Fighter).knives_max, (n as Fighter).knives + 1)
				Juice.popup_number(global_position + Vector2(0, -50), "+1 KNIFE", Color(0.85, 0.9, 1.0))
				Mixer.play_sfx("res://assets/audio/cling.wav", 1.4, -6.0)
				queue_free()
				return
		if _t > LIE:
			queue_free()
		queue_redraw()
		return
	_spin += delta * 28.0
	global_position.x += float(dir) * SPEED * delta
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk:
			var e: Punk = n
			if e.hp > 0 and not _hit.has(e.get_instance_id()) and absf(e.global_position.x - global_position.x) < 18.0 and absf(e.global_position.y - global_position.y) < 24.0:
				_hit[e.get_instance_id()] = true
				e.guarding = false
				e.take_hit("blade", by if is_instance_valid(by) else self)
				if is_instance_valid(e) and e.hp > 0:
					e.staples = maxi(e.staples, 2)
				Mixer.play_sfx("res://assets/audio/sfx/melee_knife.ogg", 1.1, -2.0)
				Juice.sparks(e.global_position + Vector2(0, -36))
				if not ItemRack.knife_pierce:
					queue_free()
					return
	if _t > LIFE:
		on_ground = true
		_t = 0.0
		Mixer.play_sfx("res://assets/audio/cling.wav", 1.6, -10.0)
	queue_redraw()


func _draw() -> void:
	var h := -34.0 if not on_ground else -2.0
	var ang := _spin if not on_ground else 0.3
	draw_set_transform(Vector2(0, h), ang, Vector2.ONE)
	draw_rect(Rect2(-1.5, -9.0, 3.0, 10.0), Color(0.82, 0.85, 0.9))
	draw_rect(Rect2(-0.5, -9.0, 1.0, 10.0), Color(1, 1, 1))
	draw_rect(Rect2(-2.5, 1.0, 5.0, 1.5), Color(0.3, 0.3, 0.32))
	draw_rect(Rect2(-1.5, 2.5, 3.0, 5.0), Color(0.25, 0.15, 0.1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if on_ground:
		var a := 0.4 + 0.3 * sin(_t * 6.0)
		draw_circle(Vector2(0, -2), 6.0, Color(1, 1, 1, a * 0.25))
