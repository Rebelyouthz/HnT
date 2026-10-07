class_name Fighter
extends CharacterBody2D

@export var role: String = "son"
@export var prefix: StringName = &"p1_"
@export var max_hp: int = 80
@export var speed: float = 210.0
@export var depth_speed: float = 110.0
@export var accent: Color = Palette.LEMON

const GRAV := 2400.0
const JUMP := -620.0
const FALL_MUL := 1.65
const COYOTE := 6
const BUFFER := 8
const STREET_MIN := 430.0
const STREET_MAX := 520.0
const STEAM_MAX := 100.0
const JUMP_HEIGHT := (620.0 * 620.0) / (2.0 * 2400.0)

var hp: int
var steam: float = STEAM_MAX
var steam_lock := 0.0
var ammo: int = 3
var ammo_cd := 0.0
var facing := 1
var hop := 0.0
var hop_v := 0.0
var coyote := 0
var jump_buf := 0
var attack_cd := 0
var invuln := 0
var plane := "street"
var gliding := false
var vaulting := false
var sliding := false
var dashing := false
var web_incoming := false
var snap_ready := false
var downed := false
var armored := false
var charge_frames := 0
var dash_frames := 0
var slide_frames := 0
var wall_run := 0.0
var cape_guard := 0.0
var web_length := 160.0
var web_anchor: WebAnchor
var ladder: FireEscape
var bleed := 0.0
var revive_hold := 0.0
var web_line: Line2D
var visual: Node2D
var squash_root: Node2D
var cape: Polygon2D
var ears: Polygon2D
var blocking := false
var block_low := false
var pickup := ""
var bandage := 0
var extra_jump := 0
var buff_t := 0.0
var staple_ready := false
var guard: Node2D
var string_n := 0
var string_ttl := 0.0
var lights_clean := 0
var net_driven := false
var puppeted := false
var net_report := false
var snap_pos := Vector2.ZERO
var snap_hop := 0.0
var tape_t := 0.0
var grenades := 0
## Throwables (ThrowLob): SHOOT + up throws one of these before a grenade.
var throw_kind := ""
var throw_n := 0
var _shadow: Polygon2D
var _slip: Polygon2D
var _breath := 0.0
var vs_mode := false
var magnet_r := 72.0
var pistol_shots := 0
## Rounds left outside the gun (spare mags / shells) and the reload clock.
var gun_reserve := 0
var reload_t := 0.0
var _reload_len := 0.0
var _shell_t := 0.0
var _pump_t := 0.0
## Per gun: reload time (shotgun: per shell), spare mags carried.
const RELOAD := {"pistol": [0.85, 1], "smg": [1.15, 1], "shotgun": [0.34, 1], "nailgun": [1.0, 1], "ray": [1.3, 1], "revolver": [1.5, 1], "flare_gun": [1.1, 2]}
## Hand guns (data/weapons.json "gun"): the held sprite, cooldown, and how
## long the arm stays up after a shot.
const GUNS := ["pistol", "nailgun", "shotgun", "smg", "ray", "revolver", "flare_gun"]
var gun_cd := 0.0
var aim_t := 0.0
var _gun: Sprite2D
static var _hands := {}
var trick_boost := 1.0
var trick_t := 0.0
var stumble_t := 0.0
## Knocked flat by a big hit: the knockdown clip plays (fall, lie, get up),
## no control and no damage until it ends.
var knock_t := 0.0
## Knockdown flight: height over the street and its speed (a launch variant
## flies on gravity and bounces before the fall art takes over).
var _knock_hop := 0.0
var _knock_hv := 0.0
## Time since going down (plays the fall, then holds the lying frame).
var _down_t := 0.0
const LIE_FRAME := {"son": 12, "father": 9}
var ducking := false
var _anim: AnimatedSprite2D
var anim_atk := ""
var _hurt_t := 0.0
var _atk_t := 0.0
var parkour_lock := 0.0
var stomp_n := 0
var stomp_cd := 0.0
var _foot_cd := 0.0
var _land_v := 0.0
var rolling := false
var van_seat := ""
var crawling := 0.0
var parry_win := 0
var revenge_win := 0
var cart_t := 0.0
var _slide_clerk := false
## Move system (MoveBook): the body position the last strike ended in, how
## long it stays live for chaining, and the strike in flight.
var stance := "guard"
var stance_t := 0.0
var _strike_id := 0
var _strike_clip := ""
## Who and what last hurt this fighter: the death screen names it.
var last_hit_by := ""
var last_hit_kind := ""
var _splat := 0.0
var _strike_phase := 0
var _strike_hit := false
var _strike_grade := ""
var _lunge_v := 0.0
var _drift_v := 0.0
var _drift_t := 0.0
var _plant := 1.0
var _land_t := 0.0
## Dojo combos: the chain reader, the finisher's damage/effect for the
## victim to read, and the finisher's own travel (flips, flying knees).
var _combo: ComboBook
var combo_dmg := 0
## Element arts / grabs / team attacks (ArtMoves): CHI pays for arts, TEAM
## fills from kills; art_lock owns the body while one plays.
var chi := 0.0
## Throwing knives on the belt (THROW with nobody in reach).
var knives_max := 6
var knives := 2
var team := 0.0
var art_lock := 0.0
var art_vx := 0.0
var art_hit := false
var arts: ArtMoves
var _duck_tap := -9.0
var combo_fx := ""
var combo_id := ""
var _combo_vx := 0.0
var _combo_t := 0.0
var _clock := 0.0
var _pre_face := 1
var _hit_y := -34.0
var combo_ring: ComboRing
## Guard: which height the block covers (high / mid / low) and how long the
## guard has been up; a clean block opens a counter window.
var block_height := "mid"
var counter_t := 0.0
var _block_flinch := 0.0
## Combat roll (block + dash) and the get-up attack from a knockdown.
var roll_t := 0.0
var _roll_dir := 0.0
var _getup_done := false
## A light pressed during recovery is kept for a few frames and thrown the
## moment the body is free, so chains don't eat presses.
var _light_buf := 0
var _heavy_buf := 0
var _run_breath := 0
## The hero suit worn this run (its perk is read in play).
## Suit parts worn (mask / top / bottom -> suit id or ""), and the full set.
var _gear := {"mask": "", "top": "", "bottom": ""}
var _gear_set := ""
var _cape_fx: CapeFx
var _dive_pending := false
var _gadget_cd := 0.0
## Landed hits left on the melee weapon in hand before it breaks.
var melee_uses := 0
## COPAY: part of every hit you take is billable - it drains away over a
## few seconds unless you bill it back by landing hits (risk / reward, like
## Streets of Rage 4's green health, but earned from defence, not specials).
var copay := 0.0
var _copay_hold := 0.0

signal died
signal hit_landed(kind: String, global_pos: Vector2)
signal downed_changed
signal combo_landed(id: String, perfect: bool)


func _ready() -> void:
	if FamilyProfile.has_cbt("thick_skin"):
		max_hp += 12
	if FamilyProfile.has_cbt("iron_gut"):
		max_hp += 8
	hp = max_hp
	if FamilyProfile.has_cbt("bandage_pocket"):
		bandage = 1
	if FamilyProfile.has_cbt("long_commute"):
		magnet_r += 40.0
	collision_layer = 2
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	floor_snap_length = 8.0
	_build_body()
	_apply_locker()
	arts = ArtMoves.attach(self)
	var bonus := FamilyProfile.gear_stat_bonus(role)
	max_hp += int(bonus.get("hp", 0))
	# Hero level / rarity and META vitality.
	max_hp += Heroes.hp_bonus(role) + Meta.hp_bonus()
	speed += Heroes.speed_bonus(role)
	if FamilyProfile.has_cbt("wardrobe_stats"):
		max_hp += 4
	hp = max_hp
	speed += float(int(bonus.get("speed", 0))) * 1.6
	# Bigger bodies at the old pace read as slow motion.
	speed *= 1.1
	steam = mini(STEAM_MAX, steam + float(int(bonus.get("steam", 0))))
	if FamilyProfile.has_research("mag_plus"):
		if role == "son":
			ammo = 4
		else:
			ammo = 7
	if FamilyProfile.has_research("tape_wrap"):
		tape_t = 6.0
		armored = true
	var snack := FamilyProfile.consume_snack_buff()
	if snack != "":
		_apply_snack(snack)
	var packed := FamilyProfile.consume_packed_weapon()
	if packed != "":
		equip_pickup(packed)
	_shadow = Polygon2D.new()
	_shadow.color = Color(0.02, 0.02, 0.04, 0.45)
	_shadow.polygon = PackedVector2Array([
		Vector2(-20, 2), Vector2(20, 2), Vector2(12, 10), Vector2(-12, 10)
	])
	_shadow.z_index = -1
	add_child(_shadow)
	var cap := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14 * SpriteBook.ACTOR_K
	shape.height = 64 * SpriteBook.ACTOR_K
	cap.shape = shape
	cap.position = Vector2(0, -32 * SpriteBook.ACTOR_K)
	add_child(cap)
	# Feet occluder: a muzzle flash (shadow-casting light) throws this body's
	# shadow along the street, away from the light.
	var occ := LightOccluder2D.new()
	var op := OccluderPolygon2D.new()
	op.polygon = PackedVector2Array([Vector2(-9, -2), Vector2(9, -2), Vector2(9, 2), Vector2(-9, 2)])
	occ.occluder = op
	# Only muzzle flashes (light mask 2) see it: a street lamp turned the feet
	# into a wedge of black over the whole road beside the body.
	occ.occluder_light_mask = 2
	add_child(occ)
	web_line = Line2D.new()
	web_line.width = 2.0
	web_line.default_color = Color(0.85, 0.9, 1.0, 0.9)
	web_line.visible = false
	web_line.z_index = 8
	add_child(web_line)
	if role == "son":
		ammo = 3
	else:
		ammo = 6
	snap_pos = global_position
	hit_landed.connect(_on_hit_landed)
	_combo = ComboBook.new(role)
	combo_ring = ComboRing.new()
	combo_ring.fighter = self
	add_child(combo_ring)


func _build_body() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	squash_root = Node2D.new()
	squash_root.name = "Squash"
	visual.add_child(squash_root)
	var outline := Palette.BRICK if role == "father" else Palette.LEMON
	_part(Vector2(-16, -72), Vector2(32, 14), outline)
	_part(Vector2(-14, -60), Vector2(28, 18), Palette.TEXT.darkened(0.15))
	if role == "son":
		ears = Polygon2D.new()
		ears.color = Color(0.12, 0.12, 0.14)
		ears.polygon = PackedVector2Array([
			Vector2(-14, -86), Vector2(-6, -72), Vector2(-18, -72),
			Vector2(14, -86), Vector2(18, -72), Vector2(6, -72)
		])
		ears.visible = false
		squash_root.add_child(ears)
		cape = Polygon2D.new()
		cape.color = Color(0.1, 0.1, 0.12, 0.92)
		cape.polygon = PackedVector2Array([
			Vector2(-8, -48), Vector2(8, -48), Vector2(18, -6), Vector2(-18, -6)
		])
		cape.visible = false
		squash_root.add_child(cape)
	_part(Vector2(-18, -42), Vector2(36, 28), accent)
	_part(Vector2(-28, -38), Vector2(10, 24), accent.darkened(0.2))
	_part(Vector2(18, -38), Vector2(10, 24), accent.darkened(0.2))
	_part(Vector2(-16, -14), Vector2(12, 28), Color(0.15, 0.14, 0.18))
	_part(Vector2(4, -14), Vector2(12, 28), Color(0.15, 0.14, 0.18))
	_mount_sprite()


func _mount_sprite() -> void:
	if not SpriteBook.has_who(role):
		return
	SpriteBook.hide_polys(squash_root)
	_anim = SpriteBook.make_anim(role)
	SpriteBook.grow(_anim, SpriteBook.FIGHTER_SCALE * (SpriteBook.FATHER_K if role == "father" else 1.0))
	squash_root.add_child(_anim)
	Suits.dress(_anim, role)
	Palettes.apply(_anim, role)
	refresh_suit()


## Re-read the suit parts (also after changing them in GEAR) and hang or
## drop the bat cape.
func refresh_suit() -> void:
	for p in Suits.PARTS:
		_gear[p] = Suits.worn_part(role, p)
	_gear_set = Suits.full_set(role)
	var want_cape := suit_part("top") == "bat"
	var want_ears := suit_part("mask") == "bat"
	if (want_cape or want_ears) and _anim != null and _cape_fx == null:
		_cape_fx = CapeFx.new()
		_cape_fx.anim = _anim
		_cape_fx.who = self
		squash_root.add_child(_cape_fx)
		squash_root.move_child(_cape_fx, _anim.get_index())
	elif not (want_cape or want_ears) and _cape_fx != null:
		_cape_fx.queue_free()
		_cape_fx = null
	if _cape_fx != null:
		_cape_fx.draw_cape = want_cape
		_cape_fx.draw_ears = want_ears


func suit_part(part: String) -> String:
	return str(_gear.get(part, ""))


func suit_set() -> String:
	return _gear_set


## Which LOADOUT slot a strike kind uses (Moves.SLOTS).
var _slot_hint := ""
## Damage scale of the move in the slot (Moves.dmg_mul), read by Punk.
var move_mul := 1.0


func _slot_of(kind: String) -> String:
	match kind:
		"light":
			return "L%d" % clampi(maxi(1, string_n), 1, 3)
		"heavy", "launcher":
			return _slot_hint if _slot_hint != "" else "H"
		"uppercut":
			return "U+H"
		"roundhouse":
			return "STR"
		"jump-kick":
			return "AIR_L"
		"air-spin":
			return "AIR_H"
	return ""


func _sprite_clip(kind: String) -> String:
	move_mul = 1.0
	var slot := _slot_of(kind)
	_slot_hint = ""
	if slot != "":
		var pick := Moves.clip_for(role, slot)
		if pick != str(Moves.DEFAULT[slot]) and _anim != null and _anim.sprite_frames.has_animation(pick):
			move_mul = Moves.dmg_mul(slot, pick)
			return pick
	var base := _base_clip(kind)
	var st := _live_stance()
	var v := base
	if kind == "light" or kind == "gut-punch":
		v = MoveBook.light_variant(st, base)
	elif kind == "heavy":
		v = MoveBook.heavy_variant(st, base)
	if v != base and _anim != null and _anim.sprite_frames.has_animation(v):
		return v
	return base


## Body position for the next move: the last strike's end pose while it is
## live, else what the legs are doing right now.
func _live_stance() -> String:
	if stance_t > 0.0:
		return stance
	if hop < -16.0 or (plane == "roof" and not is_on_floor()):
		return "air"
	if dashing or absf(velocity.x) > 180.0:
		return "run"
	if ducking or sliding:
		return "low"
	return "guard"


func _base_clip(kind: String) -> String:
	match kind:
		"light":
			if string_n <= 1:
				return "jab"
			if string_n == 2:
				return "cross"
			return "gut"
		"gut-punch":
			return "gut"
		"jump-kick":
			return "side_kick" if absf(_stick().x) > 0.55 else "front_kick"
		"roundhouse":
			return "roundhouse"
		"uppercut", "air-upper":
			return "uppercut"
		"air-mix":
			return "air_mix"
		"air-spin":
			return "air_spin_kick"
		"heavy", "launcher":
			return "heavy"
		"snap", "special":
			return "snap"
		"slide":
			return "slide"
		"dive":
			return "dive"
		_:
			return "jab"


func _tick_sprite() -> void:
	if _anim == null or _anim.sprite_frames == null:
		return
	var clip := "idle"
	if knock_t > 0.0 and _anim.sprite_frames.has_animation("knockdown"):
		clip = "knockdown"
	elif downed and _anim.sprite_frames.has_animation("knockdown"):
		# Down: the fall plays out, then the body lies on the street.
		var lie: int = mini(int(LIE_FRAME.get(role, 10)), _anim.sprite_frames.get_frame_count("knockdown") - 1)
		if _anim.animation != "knockdown":
			_anim.play("knockdown")
		_anim.pause()
		_anim.frame = mini(lie, int(_down_t * _anim.sprite_frames.get_animation_speed("knockdown") * 1.3))
		return
	elif downed:
		clip = "hurt"
	elif anim_atk != "" and _atk_t > 0.0:
		clip = anim_atk
	elif aim_t > 0.0 and _gun != null and _anim.sprite_frames.has_animation("cross"):
		clip = "cross"
	elif blocking and _anim.sprite_frames.has_animation("block_" + block_height):
		clip = "block_" + block_height
	elif snap_ready:
		clip = "snap"
	elif _hurt_t > 0.0:
		clip = "hurt"
	elif ducking:
		clip = "duck"
	elif _land_t > 0.0 and _anim.sprite_frames.has_animation("land"):
		clip = "land"
	elif hop < -8.0 or (plane == "roof" and not is_on_floor()) or gliding:
		clip = "jump"
	elif sliding or slide_frames > 0:
		clip = "slide"
	elif dashing or parkour_lock > 0.0 or absf(velocity.x) > 110.0:
		clip = "parkour_run"
	elif absf(velocity.x) > 18.0 or (plane == "street" and absf(velocity.y) > 18.0):
		clip = "walk"
		# Up / down the lane: the three-quarter back or front walk when the
		# move is mostly into or out of the street.
		if plane == "street" and absf(velocity.y) > 18.0 and absf(velocity.y) > absf(velocity.x) * 0.55:
			var lane := "walk_up" if velocity.y < 0.0 else "walk_down"
			if _anim.sprite_frames.has_animation(lane):
				clip = lane
	if not _anim.sprite_frames.has_animation(clip):
		if clip == "side_kick" and _anim.sprite_frames.has_animation("front_kick"):
			clip = "front_kick"
		elif clip == "air_mix" and _anim.sprite_frames.has_animation("jump"):
			clip = "jump"
		elif clip == "slide" and _anim.sprite_frames.has_animation("duck"):
			clip = "duck"
		elif clip == "dive" and _anim.sprite_frames.has_animation("jump"):
			clip = "jump"
		elif _anim.sprite_frames.has_animation("idle"):
			clip = "idle"
		else:
			return
	if clip == "cross" and aim_t > 0.0 and anim_atk == "":
		# Arm out, gun level: hold the extension frame of the cross.
		var hi := _hand_frame()
		if _anim.animation != "cross":
			_anim.play("cross")
		_anim.pause()
		_anim.frame = hi
		_place_gun()
		return
	if _gun != null:
		_gun.visible = false
	if _anim.animation != clip:
		_anim.speed_scale = 1.0
		_anim.play(clip)
	elif not _anim.is_playing() and _anim.sprite_frames.get_animation_loop(clip):
		_anim.play(clip)
	_drive_clip(clip)


## Clips the physics drives instead of a clock. Locomotion plays at the
## speed the feet actually travel (no ice-skating); the jump clip is scrubbed
## by vertical velocity so take-off, tuck, apex and drop line up with the arc.
func _drive_clip(clip: String) -> void:
	match clip:
		"walk":
			_anim.speed_scale = SpriteBook.stride_rate(_anim, "walk", maxf(absf(velocity.x), absf(velocity.y) * 1.4))
		"walk_up", "walk_down":
			_anim.speed_scale = SpriteBook.stride_rate(_anim, clip, velocity.length() * 1.4)
		"parkour_run":
			var spd := maxf(absf(velocity.x), 420.0 if dashing else 0.0)
			_anim.speed_scale = SpriteBook.stride_rate(_anim, "parkour_run", spd)
		"jump":
			if anim_atk == "jump":
				return
			var n := _anim.sprite_frames.get_frame_count("jump")
			if n < 3:
				return
			var vy := hop_v if plane == "street" else velocity.y
			# Take-off, tuck and flip at the apex, reach for the ground on the way down.
			# Rising covers the first half (take-off -> apex), falling the second;
			# falling is faster (FALL_MUL), so its velocity range is wider.
			var t := 0.0
			if vy < 0.0:
				t = 0.5 * clampf((vy - JUMP) / absf(JUMP), 0.0, 1.0)
			else:
				t = 0.5 + 0.5 * clampf(vy / (absf(JUMP) * sqrt(FALL_MUL)), 0.0, 1.0)
			_anim.pause()
			_anim.frame = clampi(int(round(t * float(n - 1))), 0, n - 1)
		"idle":
			# Breathing deepens with exertion: low HP or low steam = faster.
			var tired := 1.0 - minf(float(hp) / float(maxi(max_hp, 1)), steam / STEAM_MAX)
			_anim.speed_scale = 1.0 + 0.5 * clampf(tired, 0.0, 1.0)


func _part(pos: Vector2, size: Vector2, color: Color) -> void:
	var outline_c := Palette.BRICK if role == "father" else Palette.LEMON
	var o := Polygon2D.new()
	o.color = outline_c
	var op := pos - Vector2(2, 2)
	var os := size + Vector2(4, 4)
	o.polygon = PackedVector2Array([
		op, op + Vector2(os.x, 0), op + os, op + Vector2(0, os.y)
	])
	squash_root.add_child(o)
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		pos,
		pos + Vector2(size.x, 0),
		pos + size,
		pos + Vector2(0, size.y)
	])
	squash_root.add_child(p)


func _apply_locker() -> void:
	var clothes := FamilyProfile.equipped_id(role, "clothes")
	var spec := GearBook.item(clothes)
	if not spec.is_empty():
		var tint: Variant = spec.get("tint", [])
		if typeof(tint) == TYPE_ARRAY and (tint as Array).size() >= 3:
			accent = Color(float(tint[0]), float(tint[1]), float(tint[2]))
	if (clothes == "night_tutor" or clothes == "void_cape") and cape:
		cape.visible = true
		cape.color = Color(0.07, 0.07, 0.1, 0.96)
		if ears:
			ears.visible = true
	if clothes == "pink_slip" or clothes == "eviction_polo":
		_slip = Polygon2D.new()
		_slip.color = Color(0.86, 0.32, 0.52, 0.92) if clothes == "pink_slip" else Palette.BRICK
		_slip.polygon = PackedVector2Array([
			Vector2(-12, -40), Vector2(12, -40), Vector2(12, -24), Vector2(-12, -24)
		])
		squash_root.add_child(_slip)
	var hat := FamilyProfile.equipped_id(role, "hat")
	if hat != "" and hat != "headband":
		var brim := Polygon2D.new()
		brim.color = Rarity.color(str(GearBook.item(hat).get("rarity", "common")))
		brim.polygon = PackedVector2Array([
			Vector2(-18, -78), Vector2(18, -78), Vector2(14, -70), Vector2(-14, -70)
		])
		squash_root.add_child(brim)
	var shoes := FamilyProfile.equipped_id(role, "shoes")
	if shoes == "gold_wingtips":
		var tip := Polygon2D.new()
		tip.color = Palette.EDGE
		tip.polygon = PackedVector2Array([
			Vector2(-16, 10), Vector2(16, 10), Vector2(12, 16), Vector2(-12, 16)
		])
		squash_root.add_child(tip)


func _physics_process(delta: float) -> void:
	_clock += delta
	_pre_face = facing
	_tick_meters(delta)
	if van_seat != "":
		return
	if crawling > 0.0:
		crawling -= delta
		velocity.x = float(facing) * 34.0
		velocity.y = 0.0
		hop = 10.0
		motion_mode = MOTION_MODE_FLOATING
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
		if crawling <= 0.0:
			hop = 0.0
		return
	if puppeted:
		if snap_pos != Vector2.ZERO:
			global_position = global_position.lerp(snap_pos, 0.4)
		visual.position.y = lerpf(visual.position.y, snap_hop, 0.4)
		if downed:
			_process_downed(delta)
		return
	if downed:
		_process_downed(delta)
		return
	if knock_t > 0.0:
		knock_t -= delta
		if _try_getup_attack():
			return
		if _knock_hop < 0.0 or _knock_hv < 0.0:
			_knock_hv += 1250.0 * delta
			_knock_hop += _knock_hv * delta
			if _knock_hop >= 0.0:
				var spd := _knock_hv
				_knock_hop = 0.0
				_knock_hv = -spd * 0.28 if spd > 220.0 else 0.0
				Juice.land_puff(global_position)
				Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", randf_range(0.9, 1.05), clampf(-12.0 + spd / 60.0, -12.0, -3.0))
				if spd > 300.0:
					Juice.pulse_shake(3.0)
			visual.position.y = _knock_hop
		velocity.x = move_toward(velocity.x, 0.0, (600.0 if _knock_hop >= 0.0 else 120.0) * delta)
		velocity.y = 0.0
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
		_tick_sprite()
		if knock_t <= 0.0:
			visual.position.y = 0.0
			_knock_hop = 0.0
			_knock_hv = 0.0
		return
	if art_lock > 0.0:
		art_lock -= delta
		charge_frames = 0
		velocity = Vector2(art_vx, 0.0)
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
		_tick_sprite()
		return
	if _pressed("jump"):
		jump_buf = BUFFER
	ladder = _find_ladder()
	if plane == "climb":
		_process_climb(delta)
		_combat()
		return
	if web_anchor != null:
		_process_web(delta)
		_combat()
		return
	if plane == "roof":
		_process_roof(delta)
	else:
		_process_street(delta)
	_combat()
	if cape:
		cape.visible = gliding or cape_guard > 0.0 or FamilyProfile.costume_for(role) == "night_tutor"
	if ears:
		ears.visible = gliding or cape_guard > 0.0 or FamilyProfile.costume_for(role) == "night_tutor"


func _tick_meters(delta: float) -> void:
	if attack_cd > 0:
		attack_cd -= 1
	if invuln > 0:
		invuln -= 1
	if coyote > 0:
		coyote -= 1
	if jump_buf > 0:
		jump_buf -= 1
	if dash_frames > 0:
		dash_frames -= 1
		if dash_frames == 0:
			dashing = false
	if slide_frames > 0:
		slide_frames -= 1
		if slide_frames == 0:
			sliding = false
	if wall_run > 0.0:
		wall_run -= delta
	if parry_win > 0:
		parry_win -= 1
	if gun_cd > 0.0:
		gun_cd -= delta
	if _pump_t > 0.0:
		_pump_t -= delta
	if copay > 0.0:
		if _copay_hold > 0.0:
			_copay_hold -= delta
		else:
			copay = maxf(0.0, copay - 6.0 * delta)
	if reload_t > 0.0:
		_tick_reload(delta)
	if aim_t > 0.0:
		aim_t -= delta
	# OVERTIME is automatic: hold shoot (or light) and it keeps going.
	if pickup == "smg" and pistol_shots > 0 and reload_t <= 0.0 and (_pressed("shoot") or _pressed("light")) and gun_cd <= 0.0 and not downed:
		_fire_gun()
	if _light_buf > 0:
		_light_buf -= 1
	if _heavy_buf > 0:
		_heavy_buf -= 1
	if revenge_win > 0:
		revenge_win -= 1
	if cart_t > 0.0:
		cart_t -= delta
	if _just("block"):
		parry_win = 15 if suit_part("top") == "shaolin" else 10
	if _gadget_cd > 0.0:
		_gadget_cd -= delta
	if cape_guard > 0.0:
		cape_guard -= delta
	if web_incoming:
		web_incoming = absf(velocity.x) > 220.0
	if ammo_cd > 0.0:
		ammo_cd -= delta
		if ammo_cd <= 0.0:
			var cap := 3 if role == "son" else 6
			if FamilyProfile.has_research("mag_plus"):
				cap += 1
			if ammo < cap:
				ammo += 1
				ammo_cd = 2.4 if ammo < cap else 0.0
	if steam_lock > 0.0:
		steam_lock -= delta
	else:
		var regen := 22.0
		if FamilyProfile.has_cbt("second_lungs"):
			regen *= 1.15
		steam = minf(STEAM_MAX, steam + regen * (1.0 + 0.3 * float(_cart("energy_drink"))) * (2.0 if suit_part("mask") == "shaolin" else 1.0) * Meta.steam_mul() * Heroes.steam_regen_mul(role) * delta)
	blocking = _pressed("block") and steam > 2.0 and not downed
	if tape_t > 0.0:
		tape_t -= delta
		if tape_t <= 0.0:
			armored = charge_frames >= 18
	if trick_t > 0.0:
		trick_t -= delta / Meta.flow_mul()
		if trick_t <= 0.0:
			trick_boost = 1.0
	if stumble_t > 0.0:
		stumble_t -= delta
	if parkour_lock > 0.0:
		parkour_lock -= delta
	if stomp_cd > 0.0:
		stomp_cd -= delta
		if stomp_cd <= 0.0:
			stomp_n = 0
	if roll_t > 0.0 or knock_t > 0.0:
		blocking = false
	# Guard height from the stick: up = high (face), down = low (legs),
	# neutral or back = mid (body).
	var bst := _stick()
	block_height = "high" if bst.y < -0.4 else ("low" if bst.y > 0.4 else "mid")
	block_low = blocking and block_height == "low"
	if counter_t > 0.0:
		counter_t -= delta
	if _block_flinch > 0.0:
		_block_flinch -= delta
	if blocking:
		steam = maxf(0.0, steam - 8.0 * delta)
		steam_lock = 0.15
	if buff_t > 0.0:
		buff_t -= delta
	if string_ttl > 0.0:
		string_ttl -= delta
		if string_ttl <= 0.0:
			string_n = 0
	_update_guard()
	armored = charge_frames >= 18 or tape_t > 0.0
	_update_web_line()
	_apply_lamp()
	_breath += delta * 6.0
	if _hurt_t > 0.0:
		_hurt_t -= delta
	if _atk_t > 0.0:
		_atk_t -= delta
	else:
		anim_atk = ""
		if _strike_phase == 3:
			_strike_phase = 0
	if stance_t > 0.0:
		stance_t -= delta
		if stance_t <= 0.0:
			stance = "guard"
	if _drift_t > 0.0:
		_drift_t -= delta
	if _land_t > 0.0:
		_land_t -= delta
	ducking = _street_grounded() and _pressed("duck") and not dashing and not sliding
	if squash_root:
		if _anim:
			# Squash/stretch springs back to rest in world time, so it
			# holds through a hitstop and snaps out after it.
			_sq = _sq.lerp(Vector2.ONE, 1.0 - exp(-15.0 * delta))
			squash_root.scale = _sq
			squash_root.position.y = 0.0
		elif ducking:
			squash_root.scale.y = 0.62
			squash_root.position.y = 14.0
			squash_root.scale.x = 1.0
		elif attack_cd >= 13:
			squash_root.scale.x = 1.22
			squash_root.scale.y = 1.0
			squash_root.position.y = 0.0
		elif attack_cd >= 11:
			squash_root.scale.x = 0.9
			squash_root.scale.y = 1.0
			squash_root.position.y = 0.0
		elif _street_grounded() and attack_cd == 0 and not dashing and not sliding:
			squash_root.scale.x = 1.0
			squash_root.scale.y = 1.0
			squash_root.position.y = 1.6 * sin(_breath)
		else:
			squash_root.scale.x = 1.0
			squash_root.scale.y = 1.0
			squash_root.position.y = 0.0
		var hurt := clampf(1.0 - float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
		if hurt > 0.35:
			squash_root.modulate = squash_root.modulate.lerp(Color(0.85, 0.45, 0.4), hurt * 0.35)
	_tick_sprite()
	_place_melee(delta)
	if _shadow:
		var air := absf(hop) if plane == "street" else maxf(0.0, -minf(velocity.y, 0.0))
		_shadow.scale.x = 1.1 - clampf(air / 200.0, 0.0, 0.5)
		_shadow.modulate.a = 0.7 - clampf(air / 240.0, 0.0, 0.5)


func _process_street(delta: float) -> void:
	motion_mode = MOTION_MODE_FLOATING
	gliding = false
	var stick := _stick()
	var x := stick.x
	var y := stick.y
	if wall_run > 0.0:
		if _just("jump"):
			wall_run = 0.0
			hop_v = -640.0
			hop = -40.0
			velocity.x = float(facing) * 380.0
			Juice.shout(Copy.WALL_KICK)
			Juice.named_slowmo()
			KitSfx.hit(role, "jump")
			if ResourceLoader.exists("res://assets/audio/sfx/wall_kick.ogg"):
				Mixer.play_sfx("res://assets/audio/sfx/wall_kick.ogg", randf_range(0.95, 1.05), -4.0)
			FamilyProfile.mark_wallkick()
			FamilyProfile.mark_trick()
			return
		hop = minf(hop, -40.0)
		hop_v = -40.0
		velocity.x = float(facing) * 340.0
		velocity.y = 0.0
		visual.position.y = hop
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
		_face(x)
		return
	if cart_t > 0.0:
		hop = -10.0
		hop_v = 0.0
		velocity.x = float(facing) * 360.0
		velocity.y = 0.0
		visual.position.y = hop
		if _just("jump"):
			cart_t = 0.0
			hop_v = -560.0
			Juice.shout("CART POP")
			Juice.named_slowmo()
			KitSfx.hit(role, "jump")
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
		_face(x)
		return
	if dashing:
		velocity.x = float(facing) * 420.0
		velocity.y = 0.0
	elif sliding:
		velocity.x = float(facing) * 360.0
		velocity.y = 0.0
	else:
		var limp := 0.72 if hp <= int(float(max_hp) * 0.35) else 1.0
		var combo_spd := 1.0 + clampf(float(Juice.combo) * 0.008, 0.0, 0.14)
		if stumble_t > 0.0:
			limp *= 0.4
		velocity.x = x * speed * limp * (1.0 + (trick_boost - 1.0) * Meta.flow_mul()) * Meta.run_speed_mul() * NightExtras.speed_mul() * combo_spd * (1.0 + 0.12 * float(_cart("energy_drink"))) * _surv_speed() * ItemRack.speed_k
		if _street_grounded():
			velocity.y = y * depth_speed * limp
		else:
			velocity.y = 0.0
		_strike_motion()
		if blocking and roll_t <= 0.0:
			# Feet set under the guard: you can shuffle, not walk.
			velocity.x *= 0.25
			velocity.y *= 0.4
	if _combo_t > 0.0:
		_combo_t -= delta
		velocity.x = float(facing) * _combo_vx
		velocity.y = 0.0
	if roll_t > 0.0:
		roll_t -= delta
		velocity.x = _roll_dir * 330.0 * clampf(roll_t / 0.2, 0.35, 1.0)
		velocity.y = y * depth_speed * 0.5
	if _street_grounded():
		coyote = COYOTE * (2 if Trees.has("p_coyote") else 1)
		if suit_part("top") == "bat":
			extra_jump = maxi(extra_jump, 1)
		# PARKOUR tree DOUBLE JUMP: the Father gets one, the Son a third.
		if Trees.has("p_air_jump"):
			extra_jump = maxi(extra_jump, 1 if role == "father" else 2)
		_footsteps(delta, absf(velocity.x))
	if jump_buf > 0 and coyote > 0:
		hop_v = JUMP * (1.12 if suit_part("bottom") == "spider" else 1.0) * Meta.jump_mul()
		hop = -1.0
		jump_buf = 0
		coyote = 0
		KitSfx.hit(role, "jump")
	elif jump_buf > 0 and extra_jump > 0 and hop < -8.0:
		hop_v = JUMP * 0.8
		jump_buf = 0
		extra_jump -= 1
		KitSfx.hit(role, "jump")
		if suit_part("top") == "bat":
			_cape_beat()
	if hop < 0.0 or hop_v != 0.0:
		var g := GRAV
		if hop_v > 0.0:
			g *= FALL_MUL
		# HANG TIME: the top of the jump floats.
		if Trees.has("p_hang") and absf(hop_v) < 70.0:
			g *= 0.45
		if (role == "son" or suit_part("top") == "bat" or Trees.has("p_float")) and hop < 0.0 and _pressed("jump") and hop_v > -80.0:
			if not gliding and ResourceLoader.exists("res://assets/audio/sfx/glide.ogg"):
				Mixer.play_sfx("res://assets/audio/sfx/glide.ogg", 1.0, -10.0)
			gliding = true
			g = GRAV * 0.22
			hop_v = minf(hop_v, 90.0)
			velocity.x = move_toward(velocity.x, float(facing) * speed * 1.05 * Meta.air_mul(), 600.0 * Meta.air_mul() * delta)
		if _released("jump") and hop_v < 0.0:
			hop_v *= 0.45
		hop_v += g * delta
		hop += hop_v * delta
		if hop >= 0.0:
			var fall := hop_v
			hop = 0.0
			hop_v = 0.0
			_on_land(fall)
	visual.position.y = hop
	move_and_slide()
	global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	_face(x)
	if ladder and y < -0.45:
		_start_climb()
	elif ladder and y > 0.45 and plane == "street":
		pass


func _process_roof(delta: float) -> void:
	motion_mode = MOTION_MODE_GROUNDED
	visual.position.y = 0.0
	var stick := _stick()
	var x := stick.x
	var y := stick.y
	if wall_run > 0.0:
		velocity = Vector2(float(facing) * 330.0, -50.0)
		move_and_slide()
		_face(x)
		return
	if not is_on_floor():
		var g := GRAV
		if velocity.y > 0.0:
			g *= FALL_MUL
		if (role == "son" or suit_part("top") == "bat" or Trees.has("p_float")) and _pressed("jump") and velocity.y > -90.0:
			gliding = true
			g = GRAV * 0.18
			velocity.y = minf(velocity.y, 10.0)
			velocity.x = move_toward(velocity.x, float(facing) * speed * 1.08 * Meta.air_mul(), 700.0 * Meta.air_mul() * delta)
		else:
			gliding = false
		if _released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5
		velocity.y += g * delta
	else:
		gliding = false
		coyote = COYOTE * (2 if Trees.has("p_coyote") else 1)
		if suit_part("top") == "bat":
			extra_jump = maxi(extra_jump, 1)
		# PARKOUR tree DOUBLE JUMP: the Father gets one, the Son a third.
		if Trees.has("p_air_jump"):
			extra_jump = maxi(extra_jump, 1 if role == "father" else 2)
		if hop_v != 0.0:
			_on_land(absf(hop_v) if velocity.y >= 0.0 else 0.0)
		hop_v = 0.0
	if jump_buf > 0 and coyote > 0:
		velocity.y = JUMP * Meta.jump_mul()
		jump_buf = 0
		coyote = 0
		KitSfx.hit(role, "jump")
	elif jump_buf > 0 and extra_jump > 0 and not is_on_floor():
		velocity.y = JUMP * 0.85
		jump_buf = 0
		extra_jump -= 1
		KitSfx.hit(role, "jump")
	if dashing:
		velocity.x = float(facing) * 400.0
	else:
		velocity.x = x * speed
	if is_on_wall() and jump_buf > 0 and role == "son":
		wall_run = 0.42 * Meta.wall_mul()
		jump_buf = 0
	move_and_slide()
	_face(x)
	if global_position.y >= STREET_MIN - 6.0:
		_enter_street()
		return
	if ladder and y > 0.4:
		_start_climb()
	_try_land_roof()


func _process_climb(delta: float) -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_mask = 0
	var y := _stick().y
	if absf(y) < 0.15:
		y = -1.0 if (ladder and global_position.y > ladder.top_y + 8.0) else 1.0
	velocity = Vector2.ZERO
	if ladder:
		global_position.x = move_toward(global_position.x, ladder.climb_x, 240.0 * delta)
		global_position.y += y * 190.0 * ladder.speed_k(role) * delta
		if ladder.style == "boost" and y < 0.0:
			# Two springy hops: bin lid, awning, roof.
			visual.position.y = -absf(sin((ladder.bottom_y - global_position.y) / maxf(1.0, ladder.bottom_y - ladder.top_y) * TAU)) * 14.0
		if global_position.y <= ladder.top_y + 2.0 and y < 0.0:
			global_position.y = ladder.top_y
			_enter_roof()
			return
		if global_position.y >= ladder.bottom_y - 2.0 and y > 0.0:
			global_position.y = clampf(ladder.bottom_y, STREET_MIN, STREET_MAX)
			_enter_street()
			return
	else:
		_enter_street()
	if ladder == null or ladder.style != "boost":
		visual.position.y = 0.0
	_face(0.0)


func _process_web(delta: float) -> void:
	if web_anchor == null or not is_instance_valid(web_anchor):
		_release_web(false)
		return
	collision_mask = 1
	visual.position.y = 0.0
	var x := _stick().x
	velocity.y += GRAV * 0.62 * delta
	var to_me: Vector2 = global_position - web_anchor.global_position
	var dist := to_me.length()
	if dist > 4.0:
		var tangent := Vector2(-to_me.y, to_me.x).normalized()
		velocity += tangent * x * 280.0 * delta
		if dist > web_length:
			var n := to_me / dist
			global_position = web_anchor.global_position + n * web_length
			velocity -= n * velocity.dot(n)
	move_and_slide()
	if jump_buf > 0 or _just("special"):
		_release_web(true)
		jump_buf = 0
	_try_land_roof()
	if global_position.y >= STREET_MIN and plane != "street":
		_enter_street()
	_face(x)


func _process_downed(delta: float) -> void:
	_down_t += delta
	visual.rotation = 0.0
	_tick_sprite()
	velocity.x = _stick().x * 40.0
	velocity.y = 0.0
	if plane == "street":
		motion_mode = MOTION_MODE_FLOATING
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	else:
		move_and_slide()
	if vs_mode:
		return
	bleed -= delta
	revive_hold = 0.0
	for n in get_tree().get_nodes_in_group("players"):
		if n == self or not (n is Fighter):
			continue
		var other: Fighter = n
		if other.downed:
			continue
		if other.global_position.distance_to(global_position) > 58.0:
			continue
		if other._pressed("snap"):
			revive_hold += delta
			if revive_hold >= 1.15:
				_revived()
			return
	if bleed <= 0.0:
		_life_lost()


func _combat() -> void:
	if parkour_lock > 0.0:
		return
	var y := _stick().y
	if snap_ready and (_just("light") or _just("snap")):
		return
	if roll_t > 0.0 or _combo_t > 0.0:
		return
	if blocking and _just("dash") and plane == "street" and _street_grounded():
		_roll()
		return
	if _just("duck") and plane == "street" and _street_grounded() and attack_cd == 0:
		if _clock - _duck_tap < 0.32:
			_duck_tap = -9.0
			BrawlPlus.taunt(self)
			return
		_duck_tap = _clock
	if _just("jump"):
		_combo_press("J")
	if attack_cd == 0 and _just("dash") and not dashing:
		if y > 0.45 and plane == "street":
			_slide()
		else:
			_combo_press("D")
			_dash()
	if _street_grounded() or (plane == "roof" and is_on_floor()):
		_try_vault()
	if _just("throw"):
		_throw()
	if _just("special"):
		if string_n >= 2:
			_attack("gut-punch", false)
			string_n = 0
			Juice.shout("STRING")
			return
		var air_mix := hop < -16.0 or (plane == "roof" and not is_on_floor())
		if air_mix:
			if not FamilyProfile.dojo_learned("air_mix"):
				Juice.shout("DOJO LOCK")
				return
			_attack("air-mix", false)
			return
		_special()
	if _just("shoot"):
		_shoot()
	var charge_need := 20
	if FamilyProfile.has_cbt("heavy_wrist"):
		charge_need = 16
	var airborne := hop < -16.0 or (plane == "roof" and not is_on_floor())
	if _pressed("heavy"):
		charge_frames += 1
		if charge_frames >= charge_need + 25:
			_attack("heavy", true)
	elif charge_frames > 0:
		if not airborne or _combo_air_ok():
			if _combo_press("H"):
				charge_frames = 0
				return
		if airborne and y > 0.35:
			_dive()
		elif airborne and y < -0.35:
			_attack("air-upper", false)
		elif airborne and _anim != null and _anim.sprite_frames.has_animation("air_spin_kick"):
			# Jump + heavy: the spinning heel in the air.
			_attack("air-spin", false)
		elif airborne:
			_attack("jump-kick", false)
		elif y > 0.4 and _try_stomp():
			charge_frames = 0
		elif y < -0.35:
			if not FamilyProfile.dojo_learned("uppercut"):
				Juice.shout("DOJO LOCK")
				charge_frames = 0
			else:
				_attack("uppercut", false)
		elif string_n >= 2:
			if FamilyProfile.dojo_learned("roundhouse"):
				_attack("roundhouse", false)
			else:
				_attack("heavy", charge_frames >= charge_need)
		else:
			if absf(_stick().x) > 0.55 and signf(_stick().x) == float(facing):
				_slot_hint = "F+H"
			_attack("heavy", charge_frames >= charge_need)
	elif attack_cd == 0 and _heavy_buf > 0 and not airborne:
		_heavy_buf = 0
		if string_n >= 2 and FamilyProfile.dojo_learned("roundhouse"):
			_attack("roundhouse", false)
		else:
			_attack("heavy", false)
	elif _just("light") and attack_cd > 0:
		_light_buf = 9
	elif attack_cd == 0 and (_just("light") or _light_buf > 0):
		_light_buf = 0
		if (not airborne or _combo_air_ok()) and _combo_press("L"):
			return
		if airborne and y < -0.35:
			_attack("air-upper", false)
		elif airborne:
			_attack("jump-kick", false)
		else:
			_attack("light", false)


func _dash() -> void:
	if not _spend(18.0):
		return
	dashing = true
	dash_frames = 10
	invuln = 8
	if suit_part("top") == "ninja":
		# Ninja gi: the dash is a vanish - double i-frames and a smoke puff.
		invuln = 16
		SuitFx.spawn(global_position + Vector2(0, -30), "smoke", 46.0)
		SuitFx.spawn(global_position + Vector2(0, -40), "ghost", 90.0, float(facing), Color(0.2, 0.2, 0.28))
		_suit_sfx("smoke_puff", -8.0)
		if suit_set() == "ninja":
			# Full set: it's a smoke bomb - thugs around you lose their bearings.
			SuitFx.spawn(global_position + Vector2(0, -20), "smoke", 96.0)
			for n in get_tree().get_nodes_in_group("enemies"):
				if n is Punk and (n as Punk).global_position.distance_to(global_position) < 90.0:
					(n as Punk).snared = maxf((n as Punk).snared, 1.2)
					Juice.popup_number((n as Punk).global_position + Vector2(0, -80), "?!", Color(0.8, 0.8, 0.9))
	var blitz := get_tree().get_first_node_in_group("run_state")
	if blitz and blitz.has_method("has_card") and blitz.has_card("family_blitz"):
		invuln = 12
		dash_frames = 12
	velocity.x = float(facing) * 420.0
	KitSfx.hit(role, "dash")


func _slide() -> void:
	if not _spend(18.0):
		return
	sliding = true
	slide_frames = 16
	invuln = 6
	dashing = false
	anim_atk = "slide" if _anim != null and _anim.sprite_frames.has_animation("slide") else "duck"
	_atk_t = 0.42
	KitSfx.hit(role, "slide")
	Juice.shout(Copy.SLIDE)
	FamilyProfile.mark_slide()
	VoBank.slide()
	_spawn_hit("slide", Vector2(52, 28), 0.22, Vector2(24 * facing, -12))
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("family_blitz"):
		_spawn_hit("slide", Vector2(64, 30), 0.18, Vector2(40 * facing, -10))
	if rs != null and rs.has_method("has_card"):
		if bool(rs.call("has_card", "slide_tax")):
			invuln = 10
			_spawn_hit("slide", Vector2(70, 28), 0.2, Vector2(48 * facing, -8))
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(global_position, "slide", float(facing))
	_spawn_slide_clerk()


func _spawn_slide_clerk() -> void:
	if _slide_clerk:
		return
	_slide_clerk = true
	var act := get_tree().get_first_node_in_group("run_act")
	if act is RunAct and (act as RunAct).map_id == "raven_grid" and global_position.x > 2200.0:
		return
	var host := get_parent()
	if host == null:
		return
	Party.spawn_row(host, {
		"title": "Slide Clerk", "x": global_position.x + 52.0, "y": 500,
		"home": "street", "hp": 34, "pmin": global_position.x - 120.0, "pmax": global_position.x + 220.0
	}, 1.0)
	Juice.toast("challenge", "SLIDE CLERK", "You billed the asphalt. He still wants you to sit.")


func _try_vault() -> void:
	if vaulting:
		return
	var x := _stick().x
	if absf(x) < 0.5:
		return
	for n in get_tree().get_nodes_in_group("vaults"):
		if n is VaultCrate and (n as VaultCrate).covers(global_position):
			vaulting = true
			invuln = 10
			(n as VaultCrate).smash()
			Juice.keep_combo()
			if plane == "street":
				hop_v = -420.0
				hop = -1.0
			else:
				velocity.y = -360.0
			velocity.x = signf(x) * 340.0
			get_tree().create_timer(0.26).timeout.connect(func() -> void:
				vaulting = false
			)
			return


func _special() -> void:
	if role == "father":
		if web_anchor != null:
			_release_web(true)
			return
		var a := WebAnchor.nearest_in_cone(global_position + Vector2(0, -40), facing, self)
		if a:
			_attach_web(a)
			return
	if suit_part("bottom") != "" and _suit_special():
		return
	if role == "father":
		if not _spend(35.0):
			return
		BrawlMore.special_used(self, 35.0)
		_spawn_hit("special", Vector2(78, 44), 0.22, Vector2(44 * facing, -34))
		attack_cd = 22
	else:
		if not _spend(35.0):
			return
		BrawlMore.special_used(self, 35.0)
		cape_guard = 0.4
		_spawn_hit("special", Vector2(86, 52), 0.4, Vector2(36 * facing, -36))
		attack_cd = 18
		if cape:
			cape.visible = true


func _attack(kind: String, charged: bool) -> void:
	if attack_cd > 0 and kind == "heavy" and not charged:
		# Released during recovery: keep it and throw it the moment the
		# body is free, so a light-into-heavy press never gets eaten.
		charge_frames = 0
		_heavy_buf = 9
		return
	if kind == "heavy":
		_heavy_buf = 0
	if (kind == "heavy" or kind == "launcher") and charged and not _spend(12.0):
		charge_frames = 0
		return
	charge_frames = 0
	attack_cd = 14 if kind == "light" or kind == "jump-kick" else 24
	var size := Vector2(46, 40) if kind == "light" or kind == "jump-kick" else Vector2(66, 44)
	if kind == "light":
		string_n += 1
		string_ttl = 0.4
		lights_clean += 1
		# Grade shout + impact sound wait for contact (_strike_impact): a jab
		# that hits air only makes a whoosh.
		_strike_grade = HitGrade.of_lights(string_n)
		if string_n >= 3:
			kind = "gut-punch"
			size = Vector2(54, 42)
			attack_cd = 12
	elif kind == "jump-kick":
		size = Vector2(50, 36)
	elif kind == "launcher":
		size = Vector2(72, 52)
		string_n = 0
	elif kind == "uppercut" or kind == "air-upper":
		size = Vector2(48, 70)
		attack_cd = 18
		if plane == "street":
			hop_v = -280.0 - 40.0 * float(FamilyProfile.dojo_rank("uppercut"))
			hop = -1.0
		Juice.shout("UPPERCUT")
		# Drive up from the legs and lean back through the finish.
		if _anim != null:
			var tw := _anim.create_tween()
			tw.tween_property(_anim, "rotation", 0.12, 0.08)
			tw.tween_property(_anim, "rotation", -0.16, 0.12).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_anim, "rotation", 0.0, 0.18)
	elif kind == "roundhouse":
		size = Vector2(86, 44)
		attack_cd = 18
		string_n = 0
		Juice.shout("ROUNDHOUSE")
	elif kind == "air-mix":
		size = Vector2(70, 56)
		attack_cd = 16
		Juice.shout("AIR MIX")
	elif kind == "air-spin":
		size = Vector2(80, 56)
		attack_cd = 18
		string_n = 0
		Juice.shout("SPINNING HEEL")
		# Hang a beat at the top of the jump so the whole turn reads.
		if plane == "street" and hop_v > -120.0:
			hop_v = minf(hop_v, -120.0)
	if pickup == "pipe" or pickup == "board" or pickup == "chain" or pickup == "crowbar":
		size += Vector2(18, 6) if pickup == "pipe" or pickup == "chain" else Vector2(24, 8)
	elif pickup == "knife" or pickup == "clipboard" or pickup == "stapler" or pickup == "invoice_star":
		size += Vector2(10, 0)
		if kind == "light" or kind == "gut-punch":
			kind = "blade"
	elif pickup == "envelope":
		size += Vector2(8, 2)
		if kind == "light" or kind == "gut-punch":
			kind = "blade"
	elif pickup == "can":
		size += Vector2(8, 4)
	elif pickup != "" and not (pickup in GUNS) and WeaponBook.spec(pickup).has("reach"):
		# Data-driven melee (bat, machete, sledge): reach, blade cuts, and
		# the sledge makes every swing a slow heavy one.
		var ws := WeaponBook.spec(pickup)
		var rch: Array = ws["reach"]
		size += Vector2(float(rch[0]), float(rch[1]))
		if str(ws.get("hit", "")) == "blade" and (kind == "light" or kind == "gut-punch"):
			kind = "blade"
		if bool(ws.get("slow", false)):
			if kind == "light" or kind == "gut-punch":
				kind = "heavy"
			attack_cd += 10
	elif pickup in GUNS and (kind == "light" or kind == "gut-punch") and (pistol_shots > 0 or reload_t > 0.0):
		# A gun in hand: light pulls the trigger instead of punching.
		_fire_gun()
		return
	if charged and kind == "heavy":
		size = Vector2(78, 50)
	if kind != "light":
		_strike_grade = ""
	anim_atk = _sprite_clip(kind)
	_atk_t = 0.48 if kind == "light" or kind == "gut-punch" or kind == "jump-kick" else 0.72
	var life := 0.12 if kind == "light" or kind == "jump-kick" or kind == "gut-punch" else 0.2
	_begin_strike(kind, size, life, 36.0)


## Strike in three beats, timed by the sprite: wind-up (body steps in, the
## hitbox does not exist yet), contact on the art's extension frame, then
## recovery. A chain from a live stance enters the clip part-way through its
## wind-up, so combos flow as one motion instead of resetting to guard.
func _begin_strike(kind: String, size: Vector2, life: float, reach: float) -> void:
	var clip := anim_atk
	var mv := MoveBook.move(clip)
	var info: Dictionary = SpriteBook.clip_info(role, clip) if _anim != null else {}
	var fps := maxf(1.0, float(info.get("fps", 16.0)))
	var count := int(info.get("count", 0))
	var hit_f := int(info.get("hit", -1))
	var start_f := 0
	var startup := 0.0
	if hit_f > 0:
		var skip := MoveBook.entry_skip(_live_stance(), clip)
		start_f = clampi(roundi(float(hit_f) * skip), 0, hit_f - 1)
		startup = minf(float(hit_f - start_f) / fps, float(mv["startup_cap"]))
		# The art must reach its peak on the contact tick: speed the wind-up
		# up if the cap is shorter than the drawn extension.
		var natural := float(hit_f - start_f) / fps
		var rate := natural / maxf(startup, 0.001)
		_atk_t = startup + float(count - hit_f) / fps + 0.02
		if _anim != null and _anim.sprite_frames.has_animation(clip):
			_anim.play(clip)
			_anim.frame = start_f
			_anim.speed_scale = rate
	else:
		# Old boards without timing data: near-instant contact as before.
		startup = 0.05
	_strike_id += 1
	var id := _strike_id
	_strike_clip = clip
	_strike_phase = 1
	_strike_hit = false
	_plant = float(mv["plant"])
	_lunge_v = float(mv["lunge"])
	_drift_t = 0.0
	stance_t = 0.0
	_whoosh(clip, float(mv["weight"]))
	VoBank.effort(role, float(mv["weight"]))
	if startup > 0.0:
		await get_tree().create_timer(startup, false).timeout
	if id != _strike_id or downed or not is_inside_tree():
		return
	_strike_phase = 2
	_lunge_v = 0.0
	if _anim != null and _anim.animation == clip:
		_anim.speed_scale = 1.0
	# The box's front edge sits just past the drawn fist/foot on the contact
	# frame, so a blow only lands where the art visibly reaches.
	var art := _art_reach(clip, hit_f)
	if art > 0.0:
		var front := maxf(art + 6.0, 26.0)
		reach = (front - size.x * SpriteBook.ACTOR_K * 0.5) / SpriteBook.ACTOR_K
	_spawn_hit(kind, size, life, Vector2(reach * facing, _hit_y + hop / SpriteBook.ACTOR_K))
	_hit_y = -34.0
	if _combo != null:
		_combo.beat(_clock)
	await get_tree().create_timer(life + 0.02, false).timeout
	if id != _strike_id or not is_inside_tree():
		return
	_strike_phase = 3
	if not _strike_hit:
		_strike_whiff(mv)


## How far (world units, from the body's centre) the limb reaches on frame
## `f` of `clip`, measured from the sprite sheet; 0 when unknown.
func _art_reach(clip: String, f: int) -> float:
	if _anim == null or f < 0:
		return 0.0
	var meta := SpriteBook.clip_meta(role, clip)
	var frames: Array = meta.get("frames", [])
	var cell: Array = meta.get("cell", [0, 0])
	if f >= frames.size() or cell.size() < 1:
		return 0.0
	var fr: Dictionary = frames[f]
	var tex := float(fr.get("ox", 0)) + float(fr.get("w", 0)) - float(cell[0]) * 0.5
	return maxf(0.0, tex) * absf(_anim.scale.x)


## Physics of a strike on the street: feet planted (stick input mostly
## cancelled), the step-in lunge during wind-up, and the stumble forward
## after a whiff.
func _strike_motion() -> void:
	if _strike_phase == 1 or _strike_phase == 2:
		velocity.x *= _plant
		velocity.y *= _plant
		velocity.x += float(facing) * _lunge_v
	if _drift_t > 0.0:
		velocity.x += float(facing) * _drift_v * clampf(_drift_t / 0.18, 0.0, 1.0)


## Missed: the weight carries through. Drift forward, slow retract (the
## arm has to be dragged back), longer recovery, short chain window.
func _strike_whiff(mv: Dictionary) -> void:
	_drift_v = float(mv["whiff_drift"])
	_drift_t = 0.18
	Juice.whiff(global_position + Vector2(float(facing) * 10.0, -34.0 + hop), facing, 40.0 + 30.0 * float(mv["weight"]), _strike_clip == "uppercut")
	var kick := _strike_clip.ends_with("kick") or _strike_clip == "roundhouse"
	var wp := "res://assets/audio/sfx/whiff_%s.ogg" % ("kick" if kick else "punch")
	if ResourceLoader.exists(wp):
		Mixer.play_sfx(wp, randf_range(0.92, 1.08) * (1.08 if role == "son" else 0.92), -8.0)
	attack_cd = maxi(attack_cd, int(mv["whiff_cd"]))
	if _anim != null and _anim.animation == _strike_clip:
		_anim.speed_scale = float(mv["whiff_rate"])
		_atk_t /= maxf(0.3, float(mv["whiff_rate"]))
	stance = str(mv["stance"])
	stance_t = MoveBook.STANCE_LIVE_WHIFF
	if float(mv["weight"]) >= 0.8:
		# A missed haymaker or roundhouse spins you off balance.
		string_n = 0
		stumble_t = maxf(stumble_t, 0.18)
	_strike_grade = ""


## Connected: the impact is felt on both bodies. Hitstop holds the extension
## frame, the camera kicks, the attacker pushes off the target, the retract
## snaps back faster and the chain window opens early and stays open longer.
func _strike_impact(at: Vector2) -> void:
	if _strike_hit or _strike_phase != 2:
		return
	_strike_hit = true
	var mv := MoveBook.move(_strike_clip)
	var wt := float(mv["weight"])
	Juice.hitstop(int(mv["stop"]))
	Juice.pulse_shake(float(mv["shake"]))
	# The camera gets shoved the way the blow travels, and the body
	# stretches into it: every connect reads, light ones included.
	Juice.kick(Vector2(float(facing), 0.2 + 0.3 * wt), 2.0 + 5.0 * wt)
	_squash_to(Vector2(1.06 + 0.08 * wt, 0.96 - 0.05 * wt))
	Juice.impact(at, float(mv["weight"]), facing)
	_weapon_contact(at, wt)
	if copay >= 1.0 and hp > 0:
		var back := int(minf(copay, 2.0 + 4.0 * wt))
		hp = mini(max_hp, hp + back)
		copay -= float(back)
		_copay_hold = 0.6
		Juice.popup_number(global_position + Vector2(0, -100), "+%d COPAY" % back, Color(1.0, 0.85, 0.3))
	velocity.x -= float(facing) * float(mv["push"])
	_drift_t = 0.0
	attack_cd = mini(attack_cd, int(mv["hit_cd"]))
	if _anim != null and _anim.animation == _strike_clip:
		_anim.speed_scale = 1.25
	stance = str(mv["stance"])
	stance_t = MoveBook.STANCE_LIVE_HIT
	# Every strike has its own impact (jab snap, gut thud, roundhouse whip,
	# knee, elbow...) and a weapon in hand sounds like that weapon.
	var real := _impact_sfx()
	if real != "":
		Mixer.play_sfx(real, randf_range(0.94, 1.06) * (1.04 if role == "son" else 0.95), -1.0)
	match _strike_grade:
		"jab":
			Juice.shout(HitGrade.shout("jab"))
			if real == "":
				KitSfx.hit(role, "jab")
		"cross":
			Juice.shout(HitGrade.shout("cross"))
			if real == "":
				KitSfx.hit(role, "cross")
		"":
			if real == "":
				KitSfx.hit(role, _strike_sfx())
		_:
			Juice.shout(HitGrade.shout(_strike_grade))
			if real == "":
				KitSfx.hit(role, "bam")
			VoBank.bam(role)
	_strike_grade = ""


## Blocked: a guard spark and a short clack, no impact burst, no damage
## shout - a blocked blow must read differently from a hit.
func _strike_blocked(at: Vector2) -> void:
	if _strike_hit:
		return
	_strike_hit = true
	Juice.sparks(at + Vector2(0, -28))
	Juice.hitstop(2)
	velocity.x -= float(facing) * 70.0
	attack_cd = maxi(attack_cd, 10)
	_strike_grade = ""


## Got hit mid-swing: the strike never lands, the stance is gone.
func _cancel_strike() -> void:
	_strike_id += 1
	_strike_phase = 0
	_lunge_v = 0.0
	_drift_t = 0.0
	stance = "guard"
	stance_t = 0.0
	anim_atk = ""
	_atk_t = 0.0


const IMPACT := {
	"jab": "hit_jab", "cross": "hit_cross", "gut": "hit_gut", "body_hook": "hit_gut",
	"heavy": "hit_heavy", "superman_punch": "hit_heavy", "hammer": "hit_heavy", "snap": "hit_heavy",
	"uppercut": "hit_uppercut", "getup_upper": "hit_uppercut",
	"front_kick": "hit_front_kick", "boot_kick": "hit_front_kick",
	"side_kick": "hit_side_kick", "dropkick": "hit_side_kick",
	"roundhouse": "hit_roundhouse", "jump_roundhouse": "hit_roundhouse", "air_spin_kick": "hit_roundhouse",
	"jump_spin_kick": "hit_roundhouse", "cartwheel_kick": "hit_roundhouse", "backflip_kick": "hit_roundhouse",
	"getup_kick": "hit_roundhouse", "jump_high_kick": "hit_roundhouse", "spin_backfist": "hit_roundhouse",
	"flying_knee": "hit_knee", "clinch_knee": "hit_knee", "elbow": "hit_elbow", "stomp": "hit_stomp",
	"headbutt": "hit_headbutt", "sweep": "hit_sweep", "dive": "hit_dive", "air_mix": "hit_dive",
	"shoulder_charge": "hit_dive", "slide": "hit_sweep",
}


func _impact_sfx() -> String:
	if pickup != "" and not (pickup in GUNS):
		var w := str(WeaponBook.spec(pickup).get("sfx", ""))
		if w.contains("/melee_") and ResourceLoader.exists(w):
			return w
	var p := "res://assets/audio/sfx/%s.ogg" % str(IMPACT.get(_strike_clip, "hit_cross"))
	return p if ResourceLoader.exists(p) else ""


func _strike_sfx() -> String:
	match _strike_clip:
		"roundhouse":
			return "roundhouse"
		"uppercut":
			return "uppercut"
		"air_mix":
			return "air-mix"
		"heavy", "side_kick", "snap":
			return "heavy"
	return "light"


## Air being cut: pitch and length follow the limb (kicks are longer and
## lower than jabs, heavies the lowest).
func _whoosh(clip: String, weight: float) -> void:
	var kick := clip.ends_with("kick") or clip == "roundhouse" or clip == "air_mix"
	var path := "res://assets/audio/whoosh_kick.wav" if kick else ("res://assets/audio/whoosh_heavy.wav" if weight >= 0.6 else "res://assets/audio/whoosh_light.wav")
	if not ResourceLoader.exists(path):
		return
	var pitch := (1.14 if role == "son" else 0.94) * randf_range(0.95, 1.06)
	Mixer.play_sfx(path, pitch)


func _dive() -> void:
	charge_frames = 0
	if attack_cd > 0:
		return
	attack_cd = 20
	anim_atk = "dive" if _anim != null and _anim.sprite_frames.has_animation("dive") else "jump"
	_atk_t = 0.55
	if plane == "street":
		hop_v = 520.0
	else:
		velocity.y = 520.0
	Juice.shout(Copy.DIVE)
	_spawn_hit("dive", Vector2(58, 44), 0.24, Vector2(20 * facing, -18 + hop / SpriteBook.ACTOR_K))


## One press as a combo token: button plus stick, forward/back measured
## against the way the body faced before this frame's turn.
func _combo_tok(btn: String) -> String:
	var st := _stick()
	var d := ""
	if absf(st.y) > 0.5 and absf(st.y) >= absf(st.x):
		d = "U" if st.y < 0.0 else "Dn"
	elif absf(st.x) > 0.5:
		d = "F" if signf(st.x) == float(_pre_face) else "B"
	return d + "+" + btn if d != "" else btn


## A chain is running: let a press count even mid-air (the dropkick's
## heavy comes after the jump).
func _combo_air_ok() -> bool:
	return _combo != null and not _combo.hist.is_empty()


## Feed a press to the chain reader. True when it finished a combo (the
## caller skips the normal move).
func _combo_press(btn: String) -> bool:
	if _combo == null:
		return false
	var pool := ComboBook.learned(role)
	if pool.is_empty():
		return false
	var tok := _combo_tok(btn)
	var c := _combo.feed(tok, _clock, pool)
	if OS.has_environment("HNT_COMBO_DEBUG"):
		print("stick=%s combo tok=%s t=%.2f beat=%.2f hist=%s grades=%s -> %s" % [str(_stick()), tok, _clock, _combo.beat_t, str(_combo.hist.map(func(h: Dictionary) -> String: return str(h["tok"]))), str(_combo.grades), str(c.get("id", ""))])
	var chained := not c.is_empty() or not _combo.hist.is_empty()
	if tok.begins_with("B+") and chained:
		# Back is a direction in the chain, not a turn: keep facing the target.
		facing = _pre_face
		visual.scale.x = float(facing)
	if combo_ring:
		combo_ring.pressed(_combo.last_grade)
	if btn == "J" or btn == "D":
		_combo.beat(_clock)
	if c.is_empty():
		return false
	_combo_finish(c)
	return true


## The last press of a learned combo: the finisher clip, its travel, its
## damage (x1.5 when every beat was perfect) and what it does to the target.
func _combo_finish(c: Dictionary) -> void:
	var clip := str(c.get("clip", "heavy"))
	var perfect := _combo.all_perfect()
	combo_id = str(c.get("id", ""))
	combo_dmg = int(round(float(c.get("dmg", 24)) * (1.5 if perfect else 1.0)))
	combo_dmg += 2 * FamilyProfile.dojo_rank(combo_id)
	combo_fx = str(c.get("fx", ""))
	charge_frames = 0
	string_n = 0
	_cancel_strike()
	var has := _anim != null and _anim.sprite_frames.has_animation(clip)
	anim_atk = clip if has else ("roundhouse" if role == "son" else "heavy")
	var box: Array = c.get("box", [70, 48])
	if bool(c.get("low", false)):
		_hit_y = -10.0
	if c.has("hop") and plane == "street":
		hop_v = float(c["hop"])
		hop = minf(hop, -1.0)
	_atk_t = 0.7
	_begin_strike("combo", Vector2(float(box[0]), float(box[1])), 0.2, float(c.get("reach", 32)))
	# The finisher owns the body for the whole clip: travel for most of it.
	_combo_vx = float(c.get("vx", 0.0))
	_combo_t = _atk_t * 0.55 if _combo_vx != 0.0 else 0.0
	attack_cd = maxi(attack_cd, int(_atk_t * 60.0 * 0.8))
	invuln = maxi(invuln, 14 if perfect else 6)
	Juice.shout(str(c.get("title", "COMBO")))
	VoBank.line(role, "combo", 0.45)
	if perfect:
		Juice.named_slowmo()
		Juice.popup_number(global_position + Vector2(0, -96), "PERFECT", UiKit.GOLD)
		Mixer.play_sfx("res://assets/audio/sfx/perfect_sting.ogg")
		Mixer.play_sfx("res://assets/audio/vo/ann_perfect.ogg", 1.0, -1.0)
	else:
		Mixer.play_sfx("res://assets/audio/sfx/combo_sting.ogg", 1.0, -3.0)
		Juice.popup_number(global_position + Vector2(0, -96), "COMBO", Palette.READY)
	FamilyProfile.data["combos_landed"] = int(FamilyProfile.data.get("combos_landed", 0)) + 1
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points"):
		rs.add_points(role, 40 if perfect else 24, "combo")
	if combo_ring:
		combo_ring.finished(perfect)
	combo_landed.emit(combo_id, perfect)


## Block + dash: a combat roll along the stick (backwards with no stick).
## Through people, untouchable for most of it, out on your feet.
func _roll() -> void:
	if not _spend(14.0):
		return
	var x := _stick().x
	_roll_dir = signf(x) if absf(x) > 0.3 else -float(facing)
	roll_t = 0.42 * (1.5 if Trees.has("p_roll") else 1.0)
	invuln = maxi(invuln, 22)
	BrawlPlus.dodge(self)
	blocking = false
	_cancel_strike()
	if _anim != null and _anim.sprite_frames.has_animation("roll"):
		anim_atk = "roll"
		var n := _anim.sprite_frames.get_frame_count("roll")
		_anim.play("roll")
		_anim.frame = 0
		_anim.speed_scale = float(n) / maxf(1.0, _anim.sprite_frames.get_animation_speed("roll")) / 0.5
		_atk_t = 0.5
	if _roll_dir != float(facing) and absf(x) > 0.3:
		facing = int(_roll_dir)
		visual.scale.x = float(facing)
	Mixer.play_sfx("res://assets/audio/sfx/roll.ogg")
	Juice.land_puff(global_position)
	Juice.shout("ROLL")


## On the floor after a knockdown: once the body starts to rise, a press
## turns the get-up into an attack (Son: kip-up kick, Father: rising
## uppercut). Ends the knockdown early.
func _try_getup_attack() -> bool:
	if _getup_done or _anim == null:
		return false
	var clip := "getup_kick" if role == "son" else "getup_upper"
	if not _anim.sprite_frames.has_animation(clip):
		return false
	var n := _anim.sprite_frames.get_frame_count("knockdown")
	var fps := maxf(1.0, _anim.sprite_frames.get_animation_speed("knockdown"))
	var total := float(n) / fps
	# Only once flat on the ground (after the fall, before standing).
	if knock_t > total * 0.55 or knock_t < 0.12:
		return false
	if not (_just("light") or _just("heavy")):
		return false
	_getup_done = true
	knock_t = 0.0
	invuln = maxi(invuln, 24)
	combo_dmg = 18
	combo_fx = "launch"
	combo_id = "getup"
	anim_atk = clip
	_atk_t = 0.7
	_begin_strike("combo", Vector2(60, 70), 0.2, 26.0)
	Juice.shout("GET-UP ATTACK")
	KitSfx.hit(role, "heavy")
	return true


func _on_hit_landed(kind: String, _global_pos: Vector2) -> void:
	_strike_impact(_global_pos)
	_suit_contact(_global_pos)
	_wear_melee(_global_pos)
	if kind == "light" or kind == "jump-kick" or kind == "gut-punch" or kind == "slide":
		attack_cd = mini(attack_cd, 7)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("steam_tax") and (kind == "heavy" or kind == "launcher"):
		steam = minf(STEAM_MAX, steam + 8.0)
	if kind == "dive":
		var lift := -580.0
		if rs != null and rs.has_method("has_card"):
			if bool(rs.call("has_card", "dive_bounce")):
				lift = -680.0
		if plane == "street":
			hop_v = lift
			hop = minf(hop, -8.0)
		else:
			velocity.y = lift
		Juice.shout(Copy.SLAM_BOUNCE)
		Juice.named_slowmo()
		FamilyProfile.mark_dive()
		VoBank.dive()
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("spray"):
			blood.spray(global_position, "dive", float(facing))
		if rs and rs.has_method("add_points"):
			rs.add_points(role, 18, "dive")


func _shoot() -> void:
	if throw_n > 0 and throw_kind != "" and _stick().y < -0.35 and attack_cd <= 0:
		throw_n -= 1
		attack_cd = 16
		ThrowLob.lob(self, throw_kind)
		if throw_n <= 0:
			throw_kind = ""
		return
	if grenades > 0 and _stick().y < -0.35 and attack_cd <= 0:
		grenades -= 1
		attack_cd = 16
		ThrowLob.lob(self, "grenade")
		return
	if pickup in GUNS:
		if pistol_shots <= 0:
			start_reload()
		else:
			_fire_gun()
		return
	if pickup == "" and ItemRack.shoot(self):
		return
	if ammo <= 0 or attack_cd > 0:
		return
	ammo -= 1
	ammo_cd = 2.4
	attack_cd = 12
	_fire_shot()
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("tutoring") and lights_clean > 0 and lights_clean % 8 == 0:
		_fire_shot(Vector2(0, -12))
		Juice.shout("TUTORING")


## The frame of the cross where the arm is fully out (the aim pose).
func _hand_frame() -> int:
	var info := SpriteBook.clip_info(role, "cross")
	return clampi(int(info.get("hit", 6)), 0, maxi(0, int(info.get("count", 1)) - 1))


## Where the fist is in that frame, in the AnimatedSprite's local texels:
## the furthest-forward solid pixel in the shoulder band of the body.
func _hand_point() -> Vector2:
	if _hands.has(role):
		return _hands[role]
	var out := Vector2(40, -60)
	var tex := _anim.sprite_frames.get_frame_texture("cross", _hand_frame()) if _anim != null else null
	if tex != null:
		var img := tex.get_image()
		if img != null:
			var w := img.get_width()
			var h := img.get_height()
			var top := -1
			var bot := -1
			for y in range(0, h, 2):
				for x in range(0, w, 3):
					if img.get_pixel(x, y).a > 0.5:
						if top < 0:
							top = y
						bot = y
						break
			if top >= 0:
				var body := float(bot - top)
				var best := Vector2(-1, -1)
				for y in range(int(top + body * 0.16), int(top + body * 0.42)):
					for x in range(w - 1, -1, -1):
						if img.get_pixel(x, y).a > 0.5:
							if x > best.x:
								best = Vector2(x, y)
							break
				if best.x >= 0:
					# get_image() is only the atlas region: add the margin
					# offset and centre on the full padded cell.
					var off := Vector2.ZERO
					var full := Vector2(w, h)
					if tex is AtlasTexture:
						var at := tex as AtlasTexture
						off = at.margin.position
						full = at.get_size()
					out = best + off - full * 0.5
	_hands[role] = out
	return out


## Coping-hour move speed (traits / items), 1 outside the hour.
func _surv_speed() -> float:
	var srun := SurviveRun.get_run(get_tree()) if is_inside_tree() else null
	return srun.speed_mul() if srun else 1.0


## Stacks of a halfway-cart buy this night (0 outside a run).
func _cart(id: String) -> int:
	var rs := get_tree().get_first_node_in_group("run_state") if is_inside_tree() else null
	return int(rs.call("buff", id)) if rs != null and rs.has_method("buff") else 0


## Radius that pulls insight gems (XP) in: grows with every level-up of the
## run, faster with the XP MAGNET upgrade.
func xp_magnet() -> float:
	var r := 60.0 + (magnet_r - 72.0) + 60.0 * float(_cart("magnet_charm"))
	var per := 14.0
	if FamilyProfile.has_cbt("xp_magnet"):
		r += 50.0
		per = 30.0
	var rs := get_tree().get_first_node_in_group("run_state") if is_inside_tree() else null
	if rs != null:
		r += per * float(rs.get("level_ups"))
	return r


func _mount_gun(kind: String) -> void:
	if _anim == null:
		return
	if _gun == null:
		_gun = Sprite2D.new()
		_gun.centered = false
		_gun.texture_filter = SpriteBook.world_filter()
		_gun.z_index = 1
		squash_root.add_child(_gun)
	var path := "res://assets/sprites/guns/%s.png" % kind
	_gun.texture = load(path) if ResourceLoader.exists(path) else null
	_gun.set_meta("kind", kind)
	_gun.visible = false
	var gm := _gun_meta(kind)
	var mz: Array = gm.get("muzzle", [28, 5])
	var gp: Array = gm.get("grip", [8, 12])
	Attach.dress(_gun, kind, Vector2(float(mz[0]), float(mz[1])), Vector2(float(gp[0]), float(gp[1])))


static var _gun_cache: Dictionary = {}


func _gun_meta(kind: String) -> Dictionary:
	if _gun_cache.is_empty():
		var all: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/guns/guns.json"))
		if all is Dictionary:
			_gun_cache = all
	return _gun_cache.get(kind, {}) as Dictionary


## Gun in the fist: grip on the hand point, a touch of recoil lift.
func _place_gun() -> void:
	if _gun == null or _anim == null or _gun.texture == null:
		return
	var m := _gun_meta(str(_gun.get_meta("kind", "pistol")))
	var grip: Array = m.get("grip", [8, 12])
	var hand := _anim.position + _hand_point() * _anim.scale
	_gun.scale = _anim.scale
	# Recoil per gun: muzzle climbs and the gun slides back with its kick;
	# reloads tilt it (mag guns muzzle-up, the shotgun down for shells).
	var spec := WeaponBook.spec(str(_gun.get_meta("kind", "pistol")))
	var rec := float(spec.get("recoil", 6.0))
	var k := clampf(gun_cd / maxf(0.05, float(spec.get("rate", 0.3))), 0.0, 1.0)
	k = k * k
	var kick := k * rec * 0.016 + (0.12 if _pump_t > 0.0 else 0.0)
	var back := k * rec * 0.35 + (5.0 if _pump_t > 0.0 else 0.0)
	if reload_t > 0.0 and _reload_len > 0.0:
		var ph := 1.0 - reload_t / _reload_len
		var env := sin(clampf(ph, 0.0, 1.0) * PI)
		kick += (-0.55 if str(_gun.get_meta("kind", "")) == "shotgun" else 0.9) * env
		back += 4.0 * env
	_gun.rotation = -kick
	_gun.position = hand - Vector2(float(grip[0]) + back, float(grip[1])).rotated(-kick) * _gun.scale
	_gun.visible = true


func _muzzle_global() -> Vector2:
	if _gun != null and _gun.texture != null:
		var m := _gun_meta(str(_gun.get_meta("kind", "pistol")))
		var mz: Array = m.get("muzzle", [28, 5])
		var kind := str(_gun.get_meta("kind", "pistol"))
		return _gun.to_global(Vector2(float(mz[0]) + Attach.muzzle_ext(kind), float(mz[1])))
	return global_position + Vector2(float(facing) * 30.0, -44.0 + hop)


## Pull the trigger of the gun in hand: rounds per the weapon (one, a fan of
## pellets, a nail, an orb), aimed at head / chest / legs with the stick.
func _fire_gun() -> void:
	# Shells already fed can be fired: a shot cuts the shotgun's reload.
	if pickup == "shotgun" and reload_t > 0.0 and pistol_shots > 0:
		reload_t = 0.0
	if gun_cd > 0.0 or pistol_shots <= 0 or downed or reload_t > 0.0:
		return
	var id := pickup
	var spec := WeaponBook.spec(id)
	gun_cd = float(spec.get("rate", 0.3)) * Attach.rate_mul(id)
	aim_t = maxf(aim_t, gun_cd + 0.45)
	attack_cd = maxi(attack_cd, int(gun_cd * 60.0))
	pistol_shots -= 1
	if _gun == null or str(_gun.get_meta("kind", "")) != id:
		_mount_gun(id)
	_tick_sprite()
	var y := _stick().y
	var zone := "head" if y < -0.4 else ("legs" if y > 0.4 else "chest")
	if zone == "chest" and Attach.has(id, "red_dot") and randf() < 0.25:
		zone = "head"
	var at := _muzzle_global()
	var host := get_parent()
	var n := int(spec.get("pellets", 1))
	var spread := float(spec.get("spread", 0.0)) * Attach.spread_mul(id)
	var spd := float(spec.get("speed", 2000.0))
	for i in n:
		var r := Round.new()
		r.weapon = id
		r.round_kind = str(spec.get("round", "bullet"))
		r.dmg = int(round(float(spec.get("dmg", 10)) * (1.0 + 0.25 * float(_cart("gun_oil"))) * Arsenal.power_mul(id) * Attach.dmg_mul(id)))
		r.owner_role = role
		r.shooter = self
		r.lane_y = global_position.y
		r.range_left = float(spec.get("range", 900.0)) * Attach.range_mul(id)
		r.pierce = r.round_kind == "orb"
		r.pierce_left = int(spec.get("pierce", 0)) + (1 if Attach.has(id, "ap_rounds") else 0)
		var z := zone
		if spread > 0.0 and randf() < spread * 4.0:
			# Spray: some rounds land a zone off.
			z = ["head", "chest", "gut", "legs"][randi() % 4]
		r.zone = z
		var ang := randf_range(-spread, spread)
		r.vel = Vector2(float(facing) * spd, 0.0).rotated(ang * float(facing))
		r.global_position = at
		host.add_child(r)
	var recoil := float(spec.get("recoil", 6)) * Attach.recoil_mul(id)
	velocity.x -= float(facing) * recoil * 9.0
	var quiet := Attach.has(id, "suppressor")
	if not quiet:
		GunFx.flash(host, at, id, facing)
	else:
		Juice.sparks(at)
	if id == "shotgun":
		# Pump-action: the shell comes out on the pump, a beat after the shot.
		get_tree().create_timer(0.24).timeout.connect(func() -> void:
			if not is_instance_valid(self) or pickup != "shotgun":
				return
			_pump_t = 0.2
			Mixer.play_sfx(_sfx_or("res://assets/audio/sfx/shotgun_pump.ogg", "res://assets/audio/cling.wav"), randf_range(0.95, 1.05), -4.0)
			GunFx.casing(get_parent(), _muzzle_global() - Vector2(float(facing) * 30.0, 0), "shotgun", facing, global_position.y + 6.0)
		)
	elif not (id in ["revolver", "flare_gun", "ray"]):
		# A revolver keeps its brass; the flare's shell comes out on reload.
		GunFx.casing(host, at + Vector2(-float(facing) * 10.0, 0), id, facing, global_position.y + 6.0)
	# Each gun kicks the body its own way.
	_squash_to(Vector2(0.97 - 0.004 * recoil, 1.0 + 0.003 * recoil))
	var snd := str(spec.get("sfx", "res://assets/audio/pistol.wav"))
	if not ResourceLoader.exists(snd):
		snd = "res://assets/audio/pistol.wav"
	if quiet:
		Mixer.play_sfx("res://assets/audio/sfx/whiff_punch.ogg", randf_range(1.5, 1.7), -6.0)
	else:
		Mixer.play_sfx(snd, randf_range(0.95, 1.05), -2.0 if id != "smg" else -6.0)
	Juice.pulse_shake({"shotgun": 6.0, "ray": 4.0, "pistol": 2.0, "smg": 0.8, "nailgun": 1.2, "revolver": 5.0, "flare_gun": 3.0}.get(id, 2.0))
	if id == "shotgun":
		Juice.hitstop(2)
	if pistol_shots <= 0 and gun_reserve > 0:
		get_tree().create_timer(maxf(0.12, gun_cd)).timeout.connect(func() -> void:
			if is_instance_valid(self) and pickup == id:
				start_reload()
		)
	elif pistol_shots <= 0:
		# Dry: the empty gun is tossed aside.
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if is_instance_valid(self) and pickup == id:
				pickup = ""
				if _gun != null:
					_gun.visible = false
				Juice.popup_number(global_position + Vector2(0, -84), "EMPTY", Color(0.8, 0.8, 0.8))
		)


func _sfx_or(path: String, fallback: String) -> String:
	return path if ResourceLoader.exists(path) else fallback


func _clip_size() -> int:
	var spec := WeaponBook.spec(pickup)
	return int(round(float(spec.get("mag", spec.get("ammo", 6))) * (1.0 + 0.5 * float(_cart("long_mag"))) * Arsenal.clip_mul(pickup)))


## Reload: magazine guns drop the empty mag and slap in a new one; the
## shotgun feeds shells one by one (you can fire between them) and pumps.
func start_reload() -> void:
	if reload_t > 0.0 or gun_reserve <= 0 or not (pickup in GUNS) or pistol_shots >= _clip_size():
		return
	var spec_t: Array = RELOAD.get(pickup, [1.0, 1])
	if pickup == "shotgun":
		_reload_len = float(spec_t[0]) * float(mini(gun_reserve, _clip_size() - pistol_shots)) + 0.25
		_shell_t = float(spec_t[0])
	else:
		_reload_len = float(spec_t[0]) * Arsenal.reload_mul(pickup)
		GunFx.mag(get_parent(), _muzzle_global() - Vector2(float(facing) * 18.0, -6.0), pickup, facing, global_position.y + 6.0)
		Mixer.play_sfx(_sfx_or("res://assets/audio/sfx/mag_out.ogg", "res://assets/audio/cling.wav"), randf_range(0.95, 1.05), -5.0)
	reload_t = _reload_len
	Juice.popup_number(global_position + Vector2(0, -96), "RELOAD", Color(0.85, 0.85, 0.9))
	VoBank.line(role, "reload", 0.5)


func _tick_reload(delta: float) -> void:
	reload_t -= delta
	if pickup == "shotgun":
		_shell_t -= delta
		if _shell_t <= 0.0 and gun_reserve > 0 and pistol_shots < _clip_size():
			_shell_t = float((RELOAD["shotgun"] as Array)[0])
			gun_reserve -= 1
			pistol_shots += 1
			Mixer.play_sfx(_sfx_or("res://assets/audio/sfx/shell_in.ogg", "res://assets/audio/cling.wav"), randf_range(0.9, 1.1), -6.0)
		if reload_t <= 0.0:
			_pump_t = 0.2
			Mixer.play_sfx(_sfx_or("res://assets/audio/sfx/shotgun_pump.ogg", "res://assets/audio/cling.wav"), 1.0, -4.0)
	elif reload_t <= 0.0:
		var take := mini(gun_reserve, _clip_size() - pistol_shots)
		gun_reserve -= take
		pistol_shots += take
		Mixer.play_sfx(_sfx_or("res://assets/audio/sfx/mag_in.ogg", "res://assets/audio/cling.wav"), randf_range(0.95, 1.05), -4.0)
		_squash_to(Vector2(1.03, 0.97))
	if reload_t <= 0.0:
		reload_t = 0.0


func _fire_shot(extra := Vector2.ZERO) -> void:
	var id := "pistol"
	if pickup == "nailgun":
		id = "nailgun"
	elif pickup != "pistol":
		id = "batwing" if role == "son" else "snare"
	var spec := WeaponBook.spec(id)
	var shot := KitShot.new()
	shot.kind = str(spec.get("kind", "shuriken" if role == "son" else "snare"))
	shot.caliber = str(spec.get("caliber", ""))
	shot.ricochet_left = 1 if role == "son" else 0
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("ricochet_policy") and role == "son":
		shot.ricochet_left += 1
	shot.owner_role = role
	shot.hollow = FamilyProfile.has_research("hollow")
	shot.quiet = FamilyProfile.has_research("silencer")
	var spd := float(spec.get("speed", 520.0 if role == "son" else 380.0))
	shot.vel = Vector2(float(facing) * spd, 0.0)
	shot.global_position = global_position + Vector2(float(facing) * 28.0, -42.0 + hop) + extra
	var recoil := float(spec.get("recoil", 6))
	if FamilyProfile.has_research("recoil_pad"):
		recoil = maxf(1.0, recoil - 2.0)
	velocity.x -= float(facing) * recoil * 8.0
	KitSfx.gun(id, role)
	Juice.muzzle(shot.global_position, facing, shot.caliber)
	get_parent().add_child(shot)


func _spawn_hit(kind: String, size: Vector2, life: float, offset: Vector2) -> void:
	var box := Area2D.new()
	box.collision_layer = 8
	box.collision_mask = 6 if vs_mode else 4
	box.monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	# Strike boxes were tuned for the old body size: grow them with it so
	# what you see reach is what reaches.
	r.size = size * SpriteBook.ACTOR_K
	cs.shape = r
	box.position = offset * SpriteBook.ACTOR_K
	box.add_child(cs)
	add_child(box)
	var hits: Array[Node] = []
	var land := func(node: Node) -> void:
		if node in hits:
			return
		hits.append(node)
		var victim: Node = node
		if node is Area2D:
			victim = (node as Area2D).get_parent()
		if victim == self:
			return
		if victim is Fighter and not vs_mode:
			return
		if victim and victim.has_method("take_hit"):
			var hit_kind := kind
			if web_incoming:
				hit_kind = "web-slam"
			if counter_t > 0.0 and victim is Punk:
				counter_t = 0.0
				if hit_kind == "light" or hit_kind == "gut-punch":
					hit_kind = "heavy"
				Juice.shout("COUNTER")
				Juice.hitstop(4)
				Mixer.play_sfx("res://assets/audio/vo/ann_counter.ogg", 1.0, -2.0)
			if revenge_win > 0 and victim is Punk:
				if hit_kind == "light" or hit_kind == "gut-punch":
					hit_kind = "heavy"
				_spend_revenge(victim as Punk)
			victim.take_hit(hit_kind, self)
			if victim is Punk and (victim as Punk).blocked_last:
				_strike_blocked((node as Node2D).global_position)
				return
			hit_landed.emit(hit_kind, (node as Node2D).global_position)
	box.area_entered.connect(func(a: Area2D) -> void:
		land.call(a)
	)
	box.body_entered.connect(func(b: Node) -> void:
		land.call(b)
	)
	await get_tree().create_timer(life).timeout
	if is_instance_valid(box):
		box.queue_free()


func take_hit(kind: String, from: Node) -> void:
	BrawlMore.hero_hit(self)
	if downed or invuln > 0:
		return
	if kind == "none":
		return
	# Boss crush blows can't be blocked or parried: dodge, jump or step away.
	if kind == "crush":
		if rolling:
			return
		_take_crush(from)
		return
	if blocking and parry_win > 0 and kind != "snap" and kind != "throw" and attack_height(kind, from) in ["any", block_height]:
		var perfect := parry_win >= 7
		parry_win = 0
		invuln = 14
		steam = minf(STEAM_MAX, steam + 18.0)
		Juice.shout(Copy.PERFECT_PARRY if perfect else Copy.PARRY)
		Juice.sparks(global_position + Vector2(float(facing) * 24.0, -30.0))
		Juice.pulse_shake(7.0 if perfect else 5.0)
		Juice.hitstop(7 if perfect else 5)
		if perfect:
			snap_ready = true
			Juice.named_slowmo()
			FamilyProfile.mark_perfect_parry()
		Mixer.play_sfx("res://assets/audio/sfx/parry_ring.ogg")
		FamilyProfile.mark_parry()
		_spawn_hit("heavy", Vector2(70, 48), 0.16, Vector2(40 * facing, -30))
		if from is Punk:
			(from as Punk).take_hit("heavy", self)
		return
	var wrong_guard := false
	if blocking and kind != "throw" and kind != "snap":
		var need := attack_height(kind, from)
		if need == "any" or need == block_height:
			_clean_block(kind, from)
			if blocking:
				return
		else:
			# Guard in the wrong place: most of it gets through.
			wrong_guard = true
			Juice.popup_number(global_position + Vector2(0, -92), "%s!" % need.to_upper(), Color(1.0, 0.45, 0.3))
	if armored and kind == "light":
		Juice.flash_red(visual, 1)
		return
	if _sense_dodge(kind):
		return
	if web_anchor:
		_release_web(false)
	if gliding:
		gliding = false
		hop_v = 280.0
		velocity.y = 280.0
	var dmg := 6
	if kind == "heavy":
		dmg = 16
	elif kind == "snap" or kind == "special":
		dmg = 18
	if buff_t > 0.0:
		dmg = int(round(float(dmg) * 0.85))
	if from is Punk or from is Round or from is KitShot:
		dmg = maxi(1, int(round(float(dmg) * Heroes.enemy_dmg_mul() * Artifacts.enemy_dmg() * NightExtras.guard_mul())))
	if wrong_guard:
		dmg = maxi(1, int(round(float(dmg) * 0.7)))
	if suit_set() == "shaolin":
		dmg = maxi(1, int(round(float(dmg) * 0.7)))
	var srun := SurviveRun.get_run(get_tree())
	if srun and from is Punk:
		# The hour hurts more the longer it runs.
		dmg = maxi(1, int(round(float(dmg) * (1.0 + srun.time_alive / 200.0))))
	if srun and srun.armor() > 0.0:
		dmg = maxi(1, int(round(float(dmg) * (1.0 - srun.armor()))))
	if srun and SurvExtras.pact_sum("dmg") > 0.0:
		dmg = int(round(float(dmg) * (1.0 + SurvExtras.pact_sum("dmg"))))
	# THORNS: whoever hit you gets some back.
	if srun and srun.trait_n("t_thorns") > 0 and from is Punk:
		(from as Punk).hp = maxi(1, (from as Punk).hp - 6 * srun.trait_n("t_thorns"))
		Juice.popup_number((from as Punk).global_position + Vector2(0, -80), str(6 * srun.trait_n("t_thorns")), Color(0.5, 1.0, 0.5))
	hp = maxi(0, hp - dmg)
	if hp <= 0 and BrawlPlus.clutch(self):
		return
	if hp > 0:
		copay = minf(float(max_hp - hp), copay + float(dmg) * 0.5)
		_copay_hold = 1.2
	_hurt_t = 0.32
	VoBank.line(role, "hurt", 0.45)
	_cancel_strike()
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("family_discount"):
		Juice.keep_combo()
	else:
		Juice.break_combo()
	if kind == "light":
		Juice.flash_red(visual, 2)
		Juice.hitstop(1)
		Juice.play("res://assets/audio/sfx/hit_cross.ogg" if ResourceLoader.exists("res://assets/audio/sfx/hit_cross.ogg") else "res://assets/audio/hit_light.wav")
		lights_clean = 0
	else:
		Juice.flash_white_red(visual)
		Juice.hitstop(4)
		Juice.pulse_shake(3.0)
		Juice.play("res://assets/audio/sfx/hit_side_kick.ogg" if ResourceLoader.exists("res://assets/audio/sfx/hit_side_kick.ogg") else "res://assets/audio/hit_heavy.wav")
	if from is Node2D:
		var dir := signf(global_position.x - (from as Node2D).global_position.x)
		global_position.x += dir * (6.0 if kind == "light" else 16.0)
		# Getting hit should hurt to watch: the view jolts the way you are
		# knocked and the body crumples a little.
		Juice.kick(Vector2(dir, 0.35), 2.5 if kind == "light" else 6.0)
		_squash_to(Vector2(0.9, 1.06) if kind == "light" else Vector2(0.84, 1.1))
		_bleed_from(kind, from, dir)
		# The body answers where the blow landed: head snaps away, a body
		# blow folds you over, a low one buckles the knees, a round jolts.
		var h := attack_height(kind, from)
		var hz: String = "bullet" if from is KitShot or from is Round else str({"high": "head", "low": "trip"}.get(h, "gut" if kind != "light" else "head"))
		HitReact.react(visual, facing, hz, dir, 0.3 if kind == "light" else 0.8)
	if hp <= int(round(float(max_hp) * 0.3)) and bandage > 0:
		bandage -= 1
		hp = mini(max_hp, hp + int(round(float(max_hp) * 0.3)))
		Juice.shout("BANDAGE")
	if hp <= 0:
		_go_down()
		return
	_maybe_knockdown(kind, from)
	revenge_win = 36
	var rs2 := get_tree().get_first_node_in_group("run_state")
	if rs2 and rs2.has_method("has_card") and rs2.has_card("revenge_policy"):
		revenge_win = 54
	Juice.shout("REVENGE READY")


## Where an incoming blow lands: enemies call it during their wind-up
## (atk_height), otherwise read it off the kind. Bullets and blasts can be
## stopped by any guard.
static func attack_height(kind: String, from: Node) -> String:
	if from != null and from.get("atk_height") != null and str(from.get("atk_height")) != "":
		return str(from.get("atk_height"))
	if from is KitShot:
		return "any"
	match kind:
		"slide", "sweep":
			return "low"
		"jump-kick", "roundhouse", "dive":
			return "high"
	return "mid"


## Right height, guard up: nothing gets through. The hit rings off the
## forearms, both bodies jolt, the attacker bounces off (an opening) and a
## counter window opens: your next blow hits as a heavy.
func _clean_block(kind: String, from: Node) -> void:
	var heavy := kind in ["heavy", "roundhouse", "jump-kick", "blade"]
	steam = maxf(0.0, steam - (14.0 if heavy else 7.0))
	_block_flinch = 0.2
	counter_t = 0.5
	var y := -58.0 if block_height == "high" else (-12.0 if block_height == "low" else -36.0)
	var at := global_position + Vector2(float(facing) * 16.0, y)
	Juice.sparks(at)
	Juice.hitstop(4 if heavy else 2)
	Juice.pulse_shake(3.0 if heavy else 1.4)
	Mixer.play_sfx("res://assets/audio/sfx/block_hit.ogg" if ResourceLoader.exists("res://assets/audio/sfx/block_hit.ogg") else "res://assets/audio/block.wav")
	VoBank.line(role, "block", 0.08)
	Juice.popup_number(at + Vector2(0, -20), "BLOCK", Color(0.62, 0.86, 1.0))
	global_position.x -= float(facing) * (12.0 if heavy else 6.0)
	if from is Punk:
		var p := from as Punk
		p.recover = maxf(p.recover, 0.45 if heavy else 0.32)
		HitReact.react(p.visual, p.facing, "head", -float(p.facing), 0.25)
	if _anim != null:
		var tw := _anim.create_tween()
		_anim.self_modulate = Color(1.5, 1.7, 2.0)
		tw.tween_property(_anim, "self_modulate", Color.WHITE, 0.16)
	FamilyProfile.data["blocks"] = int(FamilyProfile.data.get("blocks", 0)) + 1
	if steam <= 0.0:
		blocking = false
		stumble()
		Juice.shout("GUARD BREAK")
		Mixer.play_sfx("res://assets/audio/vo/ann_guard_break.ogg")


func _go_down() -> void:
	downed = true
	_down_t = 0.0
	Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", 0.95, -4.0)
	hp = 0
	bleed = 12.0
	var ally := false
	for n in get_tree().get_nodes_in_group("players"):
		if n != self and n is Fighter and not (n as Fighter).downed:
			ally = true
	if not ally:
		bleed = 0.85
	web_anchor = null
	died.emit()
	downed_changed.emit()


func _revived() -> void:
	downed = false
	hp = int(round(float(max_hp) * 0.4))
	bleed = 0.0
	invuln = 40
	Juice.shout("GROUNDED")
	Juice.pulse_shake(10.0)
	Juice.freeze_frames(6)
	Juice.hitstop(10)
	Juice.play("res://assets/audio/slap.wav")
	if ResourceLoader.exists("res://assets/audio/vo_grounded.wav"):
		Mixer.play_vo("res://assets/audio/vo_grounded.wav")
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("double_slap"):
		hp = mini(max_hp, hp + int(round(float(max_hp) * 0.2)))
		buff_t = 2.0
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and n != self:
				(n as Fighter).hp = mini((n as Fighter).max_hp, (n as Fighter).hp + int(round(float((n as Fighter).max_hp) * 0.2)))
				(n as Fighter).buff_t = 2.0
	downed_changed.emit()


func _life_lost() -> void:
	VoBank.line(role, "death", 1.0)
	Nemesis.note_death(last_hit_by)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("spend_life"):
		rs.spend_life()
		if rs.failed:
			return
		global_position = rs.checkpoint
	downed = false
	hp = int(round(float(max_hp) * 0.6))
	_enter_street()
	downed_changed.emit()


func _attach_web(a: WebAnchor) -> void:
	web_anchor = a
	web_length = clampf(global_position.distance_to(a.global_position), WebAnchor.MIN_LEN, WebAnchor.MAX_LEN)
	plane = "air"
	motion_mode = MOTION_MODE_FLOATING
	hop = 0.0
	hop_v = 0.0
	web_line.visible = true
	Juice.play("res://assets/audio/web.wav")


func _release_web(sling: bool) -> void:
	if sling:
		velocity *= 1.35
		web_incoming = absf(velocity.x) + absf(velocity.y) > 280.0
		invuln = 8
	web_anchor = null
	web_line.visible = false
	if global_position.y < STREET_MIN - 20.0:
		plane = "roof"
		motion_mode = MOTION_MODE_GROUNDED
	else:
		_enter_street()


func _update_web_line() -> void:
	if web_anchor == null or not is_instance_valid(web_anchor):
		if web_line:
			web_line.visible = false
		return
	web_line.visible = true
	var from := to_local(web_anchor.global_position)
	var to := Vector2(0, -40)
	var pts := PackedVector2Array()
	for i in 8:
		var t := float(i) / 7.0
		var p := from.lerp(to, t)
		p.y += sin(t * PI) * 10.0
		pts.append(p)
	web_line.points = pts


func _start_climb() -> void:
	if ladder == null:
		return
	plane = "climb"
	if ladder.style == "boost":
		Juice.squash(squash_root, facing)
		Juice.land_puff(global_position)
		KitSfx.hit(role, "dash")
	hop = 0.0
	hop_v = 0.0
	web_anchor = null
	collision_mask = 0


func _enter_roof() -> void:
	plane = "roof"
	collision_mask = 1
	motion_mode = MOTION_MODE_GROUNDED
	hop = 0.0
	hop_v = 0.0
	visual.position.y = 0.0
	velocity.y = 0.0
	web_anchor = null


func _enter_street() -> void:
	plane = "street"
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	visual.position.y = hop
	global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	web_anchor = null


func _try_land_roof() -> void:
	for n in get_tree().get_nodes_in_group("roof_solids"):
		if not n.has_meta("rect"):
			continue
		var r: Rect2 = n.get_meta("rect")
		if global_position.x < r.position.x or global_position.x > r.end.x:
			continue
		if global_position.y >= r.position.y - 10.0 and global_position.y <= r.position.y + 20.0:
			if velocity.y >= -40.0:
				global_position.y = r.position.y
				_enter_roof()
				return


func _find_ladder() -> FireEscape:
	for n in get_tree().get_nodes_in_group("ladders"):
		if n is FireEscape and (n as FireEscape).covers(global_position):
			return n
	return null


var _sq := Vector2.ONE


func _squash_to(v: Vector2) -> void:
	_sq = v


func stumble() -> void:
	stumble_t = 0.55
	trick_boost = 0.85
	trick_t = 0.55
	KitSfx.foot(role, 0.2, true)
	Juice.squash(squash_root, facing)
	Juice.shout("STUMBLE")


func _on_land(fall: float) -> void:
	if _dive_pending:
		_bat_slam()
	# Knees absorb the drop: the deeper the fall, the longer the crouch.
	if fall > 160.0 and _strike_phase == 0:
		_land_t = clampf(fall / 2600.0, 0.1, 0.26)
		if _anim != null and _anim.sprite_frames.has_animation("land"):
			_anim.speed_scale = 1.0
			_anim.play("land")
			var n := _anim.sprite_frames.get_frame_count("land")
			_anim.speed_scale = float(n) / maxf(0.05, _land_t) / maxf(1.0, _anim.sprite_frames.get_animation_speed("land"))
	Juice.squash(squash_root, facing)
	Juice.land_puff(global_position)
	rolling = false
	_land_perks(fall)
	if fall < 280.0:
		KitSfx.hit(role, "land")
		return
	var want_roll := _stick().y > 0.25 or _just("dash") or FamilyProfile.dojo_learned("land_roll") or Meta.rank("iron_ankles") >= 2
	if want_roll:
		rolling = true
		trick_boost = 1.08 + 0.02 * float(FamilyProfile.dojo_rank("land_roll"))
		trick_t = 1.2
		slide_frames = 10
		sliding = true
		Juice.shout("LANDING ROLL")
		KitSfx.hit(role, "dash")
		Juice.toast("reward", "LANDING ROLL", "+SPEED  ·  VECTOR+")
		return
	# A full jump lands at JUMP * sqrt(FALL_MUL) (~800): legs absorb that.
	# Only drops beyond what a jump can produce stagger or hurt.
	var full_jump := absf(JUMP) * sqrt(FALL_MUL)
	if fall <= full_jump + 30.0 or Meta.rank("iron_ankles") >= 1 or Trees.has("p_iron"):
		KitSfx.hit(role, "land")
		return
	KitSfx.foot(role, 1.0, true)
	stumble()
	if fall > full_jump + 220.0:
		take_hit("light", self)


func _footsteps(delta: float, spd: float) -> void:
	if hop < -2.0 or not _street_grounded():
		return
	if spd < 28.0:
		_foot_cd = 0.0
		return
	_foot_cd -= delta
	if _foot_cd > 0.0:
		return
	_foot_cd = clampf(0.34 - spd / 900.0, 0.14, 0.34)
	KitSfx.foot(role, clampf(spd / 280.0, 0.2, 1.2), stumble_t > 0.0)
	# Running on the wet street throws up a splash at every footfall.
	if spd > 150.0 and get_tree().get_first_node_in_group("wet_street") != null and randf() < 0.7:
		GunFx.splash(get_parent(), global_position + Vector2(float(facing) * 6.0, 1.0))
		Mixer.play_sfx("res://assets/audio/sfx/step_wet_%d.ogg" % (randi() % 3 + 1), randf_range(0.9, 1.15), -13.0)
	# Running a while: you hear them breathe.
	if spd > 220.0:
		_run_breath += 1
		if _run_breath % 9 == 0 and ResourceLoader.exists("res://assets/audio/sfx/breath_run.ogg"):
			Mixer.play_sfx("res://assets/audio/sfx/breath_run.ogg", 1.1 if role == "son" else 0.85, -14.0)
	else:
		_run_breath = 0


func _try_stomp() -> bool:
	if not FamilyProfile.dojo_learned("stomp_finish"):
		Juice.shout("DOJO LOCK")
		return false
	if attack_cd > 0:
		return false
	var best: Punk = null
	var best_d := 72.0
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var p: Punk = n
		if not p.crush:
			continue
		var d := global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		return false
	stomp_n = mini(stomp_n + 1, 3)
	stomp_cd = 2.2 if Trees.has("p_bounce") else 1.1
	attack_cd = 16
	var kind := "stomp%d" % stomp_n
	_spawn_hit(kind, Vector2(52, 36), 0.18, Vector2(8 * facing, 8))
	KitSfx.hit(role, kind)
	Juice.shout("STOMP %d" % stomp_n)
	if stomp_n >= 3:
		FamilyProfile.mark_stomp()
		Juice.unlock_logo("FACE STOMP", "Smash. Pop. Splash. Brain on three.", "FINISHER  ·  STOMP 3")
		stomp_n = 0
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_points"):
			rs.add_points(role, 80, "stomp")
	return true


func _street_grounded() -> bool:
	return hop >= -1.0 and hop_v == 0.0


func _face(x: float) -> void:
	# No turning around mid-strike: the hips are committed.
	if _strike_phase == 1 or _strike_phase == 2:
		return
	# Mid-chain the stick is part of the input (back + heavy), not a turn.
	if _combo != null and not _combo.hist.is_empty() and not _combo.cold(_clock):
		return
	if absf(x) > 0.1:
		facing = 1 if x > 0.0 else -1
		visual.scale.x = float(facing)


func _spend(n: float) -> bool:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("steam_tax") and n <= 12.0:
		return true
	if steam < n:
		return false
	steam -= n
	steam_lock = 0.4
	return true


## A thug this hero hit went down: CHI for the arts, TEAM for both heroes.
func gain_kill() -> void:
	chi = minf(Elements.CHI_MAX, chi + Elements.CHI_KILL * ItemRack.chi_k)
	team = minf(Elements.TEAM_MAX, team + Elements.TEAM_KILL)
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and n != self:
			(n as Fighter).team = minf(Elements.TEAM_MAX, (n as Fighter).team + Elements.TEAM_ASSIST)


func gain_hit(kind: String) -> void:
	if not art_hit:
		chi = minf(Elements.CHI_MAX, chi + Elements.chi_for_hit(kind) * ItemRack.chi_k)


func _pressed(action: String) -> bool:
	if net_driven:
		return NetSession.held(action)
	return Input.is_action_pressed(StringName(str(prefix) + action))


func _just(action: String) -> bool:
	if net_driven:
		return NetSession.tapped(action)
	return Input.is_action_just_pressed(StringName(str(prefix) + action))


func _released(action: String) -> bool:
	if net_driven:
		return NetSession.released(action)
	return Input.is_action_just_released(StringName(str(prefix) + action))


func _stick() -> Vector2:
	if net_driven:
		return NetSession.stick
	return PadRouter.stick(prefix)


func _try_catch() -> bool:
	for n in get_tree().get_nodes_in_group("thrown_weapons"):
		if not (n is ThrownWeapon) or not is_instance_valid(n):
			continue
		var tw: ThrownWeapon = n
		if global_position.distance_to(tw.global_position) > 64.0:
			continue
		if tw.catch_by(self):
			return true
	return false


func _throw_held_weapon() -> bool:
	if pickup == "" or pickup in GUNS:
		return false
	attack_cd = 16
	var tw := ThrownWeapon.new()
	tw.kind = pickup
	tw.thrower = self
	tw.vel = Vector2(float(facing) * (560.0 if hop < -8.0 else 480.0), -40.0 if hop < -8.0 else -90.0)
	tw.global_position = global_position + Vector2(float(facing) * 26.0, -36.0 + hop)
	pickup = ""
	var host := get_parent()
	if host:
		host.add_child(tw)
	Juice.shout(Copy.THROW)
	KitSfx.hit(role, "dash")
	return true


func _throw() -> void:
	if _try_catch():
		return
	if attack_cd > 0:
		return
	if _throw_held_weapon():
		return
	attack_cd = 18
	Juice.play("res://assets/audio/throw.wav")
	if vs_mode:
		for n in get_tree().get_nodes_in_group("players"):
			if n == self or not (n is Fighter):
				continue
			var e: Fighter = n
			var dx := e.global_position.x - global_position.x
			if signf(dx) != float(facing) and absf(dx) > 8.0:
				continue
			if absf(dx) > 54.0 or absf(e.global_position.y - global_position.y) > 50.0:
				continue
			e.take_hit("throw", self)
			e.global_position.x += float(facing) * 86.0
			Juice.shout("DISARMED")
			return
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var e: Punk = n
		var dx := e.global_position.x - global_position.x
		if signf(dx) != float(facing) and absf(dx) > 8.0:
			continue
		if absf(dx) > 54.0 or absf(e.global_position.y - global_position.y) > 50.0:
			continue
		if FamilyProfile.dojo_learned("grab_slam") and e.crush:
			e.take_hit("finish", self)
			Juice.shout("GRAB SLAM")
			KitSfx.hit(role, "heavy")
		else:
			e.take_hit("throw", self)
		e.flung = true
		e.flung_dir = float(facing)
		e.flung_t = 0.48
		e.flung_ground = false
		e.global_position.x += float(facing) * 64.0
		_try_wall_bounce(e)
		Juice.shout("DISARMED")
		return
	if knives > 0 and not vs_mode:
		knives -= 1
		attack_cd = 14
		ThrowKnife.throw_from(self)
		_restart_clip_throw()
		return
	_suit_gadget()


func _restart_clip_throw() -> void:
	if _anim and _anim.sprite_frames.has_animation("jab"):
		anim_atk = "jab"
		_atk_t = 0.22
		_anim.stop()
		_anim.play("jab")
	Mixer.play_sfx("res://assets/audio/sfx/whoosh_spin.ogg", 1.4, -6.0)


func equip_pickup(kind: String) -> void:
	pickup = kind
	Arsenal.mark_found(kind)
	melee_uses = Arsenal.uses(kind)
	var mspec := WeaponBook.spec(kind)
	if not (kind in GUNS) and mspec.has("reach"):
		Juice.toast("reward", str(mspec.get("title", kind)).to_upper(), "%s  ·  lasts %d hits%s" % [str(mspec.get("blurb", "")), melee_uses, "  ·  MASTERED" if Arsenal.mastered(kind) else ""])
	if kind in GUNS:
		var spec := WeaponBook.spec(kind)
		pistol_shots = int(round(float(spec.get("mag", spec.get("ammo", 6))) * (1.0 + 0.5 * float(_cart("long_mag"))) * Arsenal.clip_mul(kind)))
		gun_reserve = pistol_shots * (int((RELOAD.get(kind, [1.0, 1]) as Array)[1]) + Attach.spare_mags(kind))
		reload_t = 0.0
		ammo = maxi(ammo, 3)
		_mount_gun(kind)
		Juice.toast("reward", str(spec.get("title", kind)).to_upper(), "%s  ·  %d rounds  ·  stick up: head, down: legs" % [str(spec.get("caliber", "")), pistol_shots])
	if kind == "invoice_star":
		Juice.unlock_logo("INVOICE STAR", "Legendary paperwork. Throw it like you mean the copay.", "SECRET  ·  LEGENDARY")
	Juice.shout(str(WeaponBook.spec(kind).get("title", kind.replace("_", " "))).to_upper())


func _apply_snack(kind: String) -> void:
	match kind:
		"bandage":
			bandage += 1
		"tape":
			tape_t = maxf(tape_t, 4.0)
			armored = true
		"steam":
			steam = STEAM_MAX
		"boost":
			trick_boost = 1.12
			trick_t = 8.0
	Juice.toast("reward", "SNACK", "The fridge packed a feeling. %s." % kind.to_upper())
	VoBank.fridge()


func _spend_revenge(e: Punk) -> void:
	revenge_win = 0
	hp = mini(max_hp, hp + 8)
	steam = minf(STEAM_MAX, steam + 14.0)
	Juice.shout(Copy.REVENGE)
	Juice.revenge_flash(e.global_position)
	VoBank.revenge()
	FamilyProfile.mark_revenge()
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(e.global_position, "revenge", float(facing))
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points"):
		rs.add_points(role, 22, "revenge")


func _try_wall_bounce(e: Punk) -> void:
	var hit_prop := false
	for n in get_tree().get_nodes_in_group("smashables"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var p := n as Node2D
		var dx := p.global_position.x - e.global_position.x
		if signf(dx) != float(facing) and absf(dx) > 10.0:
			continue
		if e.global_position.distance_to(p.global_position) > 78.0:
			continue
		if n.has_method("take_hit"):
			n.take_hit("throw", self)
		hit_prop = true
		break
	var rs := get_tree().get_first_node_in_group("run_state")
	var policy := false
	if rs != null and rs.has_method("has_card"):
		policy = bool(rs.call("has_card", "wall_bounce"))
	if not hit_prop and not policy:
		return
	e.flung_dir *= -1.0
	e.flung_t = maxf(e.flung_t, 0.28)
	e.global_position.x -= float(facing) * 42.0
	e.hp = maxi(1, e.hp - 10)
	Juice.shout(Copy.WALL_BOUNCE)
	Juice.named_slowmo()
	Juice.play("res://assets/audio/wall_bounce.wav" if ResourceLoader.exists("res://assets/audio/wall_bounce.wav") else "res://assets/audio/hit_heavy.wav")
	VoBank.bounce()
	FamilyProfile.mark_bounce()
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(e.global_position, "throw", e.flung_dir)


func _update_guard() -> void:
	if guard == null:
		guard = Polygon2D.new()
		guard.color = Color(0.85, 0.9, 1.0, 0.0)
		guard.polygon = PackedVector2Array([
			Vector2(10, -70), Vector2(28, -40), Vector2(22, -8), Vector2(8, -12)
		])
		visual.add_child(guard)
	guard.modulate.a = 0.85 if blocking else 0.0
	guard.scale.y = 0.55 if block_low else 1.0


func _apply_lamp() -> void:
	if squash_root == null:
		return
	var rig := get_tree().get_first_node_in_group("light_rig")
	if rig and rig.has_method("tint_at"):
		squash_root.modulate = rig.tint_at(global_position)


## Getting hit: blood from the face or the gut, the sprite gets bloodier as
## the hearts go (like the portrait in the corner), and the hit is
## remembered for the death screen.
func _bleed_from(kind: String, from: Node, dir: float) -> void:
	if from == self:
		last_hit_by = "the street"
		last_hit_kind = "fall"
		return
	if from is Punk:
		last_hit_by = (from as Punk).title
	elif from is KitShot:
		last_hit_by = str(from.get("owner_title")) if from.get("owner_title") != null else "a stray round"
	elif from is Node:
		last_hit_by = str(from.get("title")) if from.get("title") != null else from.name
	last_hit_kind = "bullet" if from is KitShot else kind
	var hurt := 1.0 - float(hp) / float(maxi(max_hp, 1))
	var zone := "bullet" if from is KitShot else ("head" if kind == "light" or kind == "heavy" else "gut")
	var power := 0.3 if kind == "light" else 0.75
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("hit"):
		blood.hit(self, zone, dir, power, hurt)
	if _anim != null:
		_splat = minf(1.0, _splat + power * 0.15)
		BloodSim.wound(_anim, hurt * 1.1, _splat, -dir * float(facing))
		if zone == "bullet":
			var head := BloodSim.head_of(_anim)
			var at := Vector2(head.x + randf_range(-6.0, 6.0), head.y + head.z * randf_range(2.6, 5.0))
			BloodSim.add_hole(_anim, at)
			# Half the rounds go clean through: a torn exit and a spray out of
			# the far side; the rest stay in and run.
			if randf() < 0.5:
				BloodSim.add_hole(_anim, at + Vector2(head.z * 0.55 * dir * (-1.0 if _anim.flip_h else 1.0), 2.0), true)
				if blood and blood.has_method("burst"):
					blood.burst(global_position + Vector2(0, -44), global_position.y, dir, {"n": 12, "speed": 280.0, "spread": 0.3, "rise": 0.12, "size": 1.0, "streak": true})
			elif blood and blood.has_method("burst"):
				blood.burst(global_position + Vector2(0, -44), global_position.y, -dir, {"n": 5, "speed": 110.0, "spread": 0.5, "rise": 0.3, "size": 0.9})


## Heavy blows (and throws, specials, SNAPs) put you on the street: a real
## fall, a beat on your back, then you get up. Damage cannot land meanwhile.
func _maybe_knockdown(kind: String, from: Node) -> void:
	if knock_t > 0.0 or _anim == null or not _anim.sprite_frames.has_animation("knockdown"):
		return
	if not (kind in ["heavy", "snap", "special", "throw"]):
		return
	if kind == "heavy" and randf() > 0.55:
		return
	var n := _anim.sprite_frames.get_frame_count("knockdown")
	var fps := maxf(1.0, _anim.sprite_frames.get_animation_speed("knockdown"))
	knock_t = float(n) / fps
	_getup_done = false
	invuln = maxi(invuln, int(knock_t * 60.0))
	_cancel_strike()
	var kdir := float(-facing)
	if from is Node2D and (from as Node2D).global_position.x != global_position.x:
		kdir = signf(global_position.x - (from as Node2D).global_position.x)
	# Not every knockdown is the same fall: big blows launch you into the
	# air first (gravity, a bounce), heavies shove you back a varied way.
	_knock_hop = 0.0
	_knock_hv = 0.0
	if kind in ["snap", "special", "throw"] or randf() < 0.3:
		_knock_hv = -randf_range(300.0, 440.0)
		_knock_hop = -0.1
		velocity.x = kdir * randf_range(240.0, 320.0)
	else:
		velocity.x = kdir * randf_range(150.0, 260.0)
	_anim.play("knockdown")
	_anim.frame = 0
	Juice.pulse_shake(5.0)
	get_tree().create_timer(knock_t * 0.28).timeout.connect(func() -> void:
		if is_instance_valid(self):
			Juice.play("res://assets/audio/stumble.wav")
			Juice.pulse_shake(4.0)
			Juice.land_puff(global_position + Vector2(-float(facing) * 22.0, 0))
	)


# --- Suit part perks -------------------------------------------------------

const SUIT_SFX_FALLBACK := {
	"batwing": "gun_throw", "cape_flap": "flip", "smoke_puff": "roll",
	"web_slam": "gun_web", "shockwave": "hit_stomp", "shadow_step": "whoosh_spin",
	"sense_dodge": "whiff_punch", "kick_flurry": "whiff_kick",
}

var _suit_hit_w := 0.0
var _suit_hit_until := 0


func _suit_sfx(id: String, db := -4.0, pitch := 1.0) -> void:
	var p := "res://assets/audio/sfx/%s.ogg" % id
	if not ResourceLoader.exists(p):
		p = "res://assets/audio/sfx/%s.ogg" % str(SUIT_SFX_FALLBACK.get(id, "whiff_punch"))
	Mixer.play_sfx(p, pitch * randf_range(0.95, 1.05), db)


## A suit strike: the box plus contact juice (specials skip the strike
## phase, so _strike_impact would not fire for them).
func _suit_hit(kind: String, size: Vector2, life: float, offset: Vector2, weight: float) -> void:
	_suit_hit_w = weight
	_suit_hit_until = Time.get_ticks_msec() + int(life * 1000.0) + 30
	_spawn_hit(kind, size, life, offset)


func _suit_contact(at: Vector2) -> void:
	if Time.get_ticks_msec() > _suit_hit_until:
		return
	var w := _suit_hit_w
	Juice.impact(at, w, facing)
	Juice.hitstop(2 + int(4.0 * w))
	Juice.kick(Vector2(float(facing), 0.3), 2.0 + 5.0 * w)
	Mixer.play_sfx("res://assets/audio/sfx/punch_heavy.ogg" if w > 0.5 else "res://assets/audio/sfx/punch_light.ogg", randf_range(0.92, 1.08), -2.0)


## A flap of the bat cape on the double jump: a burst of wind and dust.
func _cape_beat() -> void:
	_suit_sfx("cape_flap", -6.0, 0.9)
	Juice.land_puff(global_position + Vector2(0, hop))
	_squash_to(Vector2(0.9, 1.12))


## Throw with nobody in reach: the mask's gadget (or the spider top's web).
func _suit_gadget() -> bool:
	if _gadget_cd > 0.0:
		return false
	var m := suit_part("mask")
	var t := suit_part("top")
	var at := global_position + Vector2(float(facing) * 26.0, -46.0 + hop)
	if m == "bat":
		var full := suit_set() == "bat"
		var s := _gadget_shot("batwing", at, Vector2(float(facing) * 780.0, 0.0))
		s.boomerang = true
		s.pierce = 99 if full else 0
		s.life = 1.5
		_suit_sfx("batwing", -4.0)
		Juice.shout("BATWING")
		_gadget_cd = 0.55
	elif m == "ninja":
		for i in 3:
			var vy := (float(i) - 1.0) * 90.0
			_gadget_shot("shuriken", at + Vector2(0, (float(i) - 1.0) * 6.0), Vector2(float(facing) * 640.0, vy))
		_suit_sfx("batwing", -6.0, 1.35)
		Juice.shout("SHURIKEN")
		_gadget_cd = 0.6
	elif t == "spider":
		_gadget_shot("snare", at, Vector2(float(facing) * 520.0, 0.0))
		Mixer.play_sfx("res://assets/audio/sfx/gun_web.ogg", randf_range(0.95, 1.05), -3.0)
		Juice.shout("THWIP")
		_gadget_cd = 0.7
	else:
		return false
	_squash_to(Vector2(1.08, 0.94))
	anim_atk = "cross" if _anim != null and _anim.sprite_frames.has_animation("cross") else ""
	_atk_t = 0.22
	return true


func _gadget_shot(kind: String, at: Vector2, vel: Vector2) -> KitShot:
	var shot := KitShot.new()
	shot.kind = kind
	shot.owner_role = role
	shot.vel = vel
	shot.home = self
	shot.global_position = at
	get_parent().add_child(shot)
	return shot


## The bottom's special in place of the default one. False = not enough
## steam (nothing happens, like the default).
func _suit_special() -> bool:
	var b := suit_part("bottom")
	if not _spend(35.0):
		return true
	match b:
		"bat":
			_bat_dive()
		"spider":
			_web_slam()
		"shaolin":
			_hundred_kicks()
		"ninja":
			_shadow_step()
		_:
			steam += 35.0
			return false
	return true


func _bat_dive() -> void:
	Juice.shout("BAT DIVE")
	_suit_sfx("cape_flap", -3.0, 0.8)
	_dive_pending = true
	invuln = maxi(invuln, 20)
	attack_cd = 30
	if plane == "street":
		hop = minf(hop, -1.0)
		hop_v = -520.0
	else:
		velocity.y = -460.0
	velocity.x = float(facing) * 260.0
	anim_atk = "dive" if _anim != null and _anim.sprite_frames.has_animation("dive") else ""
	_atk_t = 0.9
	# Never stuck waiting for a floor (ledges, ladders): slam anyway.
	get_tree().create_timer(1.1).timeout.connect(func() -> void:
		if is_instance_valid(self) and _dive_pending:
			_bat_slam()
	)


func _bat_slam() -> void:
	_dive_pending = false
	_atk_t = 0.0
	var full := suit_set() == "bat"
	var w := 150.0 if full else 120.0
	_suit_hit("special", Vector2(w, 54), 0.18, Vector2(0, -20), 0.9)
	SuitFx.spawn(global_position, "ring", w * 0.9, 1.0, Color(0.5, 0.55, 1.0))
	SuitFx.spawn(global_position, "ring", w * 0.55, 1.0, Color(1.0, 0.9, 0.6))
	Juice.land_puff(global_position + Vector2(-30, 0))
	Juice.land_puff(global_position + Vector2(30, 0))
	Juice.pulse_shake(9.0)
	Juice.hitstop(5)
	_suit_sfx("shockwave", -1.0, 0.85)
	_squash_to(Vector2(1.25, 0.78))


func _web_slam() -> void:
	Juice.shout("WEB SLAM")
	Mixer.play_sfx("res://assets/audio/sfx/gun_web.ogg", 0.8, -1.0)
	attack_cd = 26
	anim_atk = "heavy" if _anim != null and _anim.sprite_frames.has_animation("heavy") else ""
	_atk_t = 0.4
	var at := global_position + Vector2(float(facing) * 64.0, -34.0)
	SuitFx.spawn(at, "web", 54.0)
	get_tree().create_timer(0.12).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_suit_hit("web-slam", Vector2(110, 60), 0.2, Vector2(60 * facing, -30), 0.85)
		_suit_sfx("web_slam", -2.0)
		Juice.pulse_shake(6.0)
	)


func _hundred_kicks() -> void:
	Juice.shout("HUNDRED KICKS")
	attack_cd = 40
	invuln = maxi(invuln, 24)
	var clips := ["front_kick", "side_kick", "roundhouse"]
	for i in 6:
		get_tree().create_timer(0.07 * float(i)).timeout.connect(func() -> void:
			if not is_instance_valid(self) or downed:
				return
			var last := i == 5
			var clip: String = clips[i % clips.size()] if not last else "roundhouse"
			if _anim != null and _anim.sprite_frames.has_animation(clip):
				anim_atk = clip
				_atk_t = 0.12 if not last else 0.3
				_anim.play(clip)
				_anim.frame = mini(2, _anim.sprite_frames.get_frame_count(clip) - 1)
			var y := -22.0 - 12.0 * float(i % 3)
			_suit_hit("roundhouse" if last else "jump-kick", Vector2(70 if last else 58, 44), 0.06, Vector2(44 * facing, y), 0.8 if last else 0.3)
			SuitFx.spawn(global_position + Vector2(float(facing) * 40.0, y * SpriteBook.ACTOR_K), "kicks", 24.0 if not last else 36.0, float(facing), Color(1.0, 0.65, 0.2))
			_suit_sfx("kick_flurry", -6.0, 1.0 + 0.06 * float(i))
			velocity.x = float(facing) * 60.0
	)


func _shadow_step() -> void:
	var best: Punk = null
	var bd := 260.0
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and not (n as Punk).is_queued_for_deletion() and int((n as Punk).hp) > 0:
			var d := (n as Punk).global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = n
	SuitFx.spawn(global_position + Vector2(0, -30), "smoke", 50.0)
	_suit_sfx("shadow_step", -3.0)
	attack_cd = 24
	invuln = maxi(invuln, 18)
	if best == null:
		# No one near: a quick blink forward.
		global_position.x += float(facing) * 120.0
		SuitFx.spawn(global_position + Vector2(0, -30), "smoke", 40.0)
		return
	var side := -signf(best.global_position.x - global_position.x)
	if side == 0.0:
		side = -float(facing)
	# Appear on the far side, facing back at him.
	global_position = Vector2(best.global_position.x - side * 46.0, best.global_position.y)
	facing = int(side)
	visual.scale.x = float(facing)
	SuitFx.spawn(global_position + Vector2(0, -30), "smoke", 40.0)
	Juice.shout("SHADOW STEP")
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		anim_atk = "heavy" if _anim != null and _anim.sprite_frames.has_animation("heavy") else ""
		_atk_t = 0.3
		_suit_hit("heavy", Vector2(64, 44), 0.12, Vector2(36 * facing, -30), 0.85)
		SuitFx.spawn(global_position + Vector2(float(facing) * 40.0, -40.0), "slash", 40.0, float(facing), Color(0.9, 0.15, 0.2))
	)


## SPIDER SENSE: a hit that never lands. True = dodged.
func _sense_dodge(kind: String) -> bool:
	if suit_part("mask") != "spider" or kind == "snap" or kind == "throw":
		return false
	var chance := 0.4 if suit_set() == "spider" else 0.2
	if randf() >= chance:
		return false
	invuln = 12
	var back := -float(facing)
	SuitFx.spawn(global_position, "ghost", 90.0, -back, Color(0.9, 0.2, 0.25))
	global_position.x += back * 26.0
	Juice.popup_number(global_position + Vector2(0, -100), "SENSE!", Color(1.0, 0.35, 0.35))
	_suit_sfx("sense_dodge", -4.0)
	_squash_to(Vector2(0.88, 1.08))
	return true



# --- Melee weapon in the fist ----------------------------------------------

var _melee: Sprite2D
var _melee_trail: Line2D
var _melee_ang := -1.9
static var _held_cache: Dictionary = {}
static var _front_cache: Dictionary = {}
const LIGHT_MELEE := ["knife", "stapler", "clipboard", "machete"]


func _held_meta(kind: String) -> Dictionary:
	if _held_cache.is_empty():
		var all: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/held/held.json"))
		if all is Dictionary:
			_held_cache = all
	return _held_cache.get(kind, {}) as Dictionary


## The leading hand on the frame on screen: the frontmost opaque texel in
## the arm band (a quarter to a half down the body), in the sprite's local
## (centred) texels. Measured once per frame texture.
func _front_hand() -> Vector2:
	if _anim == null or _anim.sprite_frames == null or not _anim.sprite_frames.has_animation(_anim.animation):
		return Vector2(20, -60)
	var tex := _anim.sprite_frames.get_frame_texture(_anim.animation, _anim.frame)
	if tex == null:
		return Vector2(20, -60)
	var key := tex.get_instance_id()
	if _front_cache.has(key):
		return _front_cache[key]
	var out := Vector2(20, -60)
	var img := tex.get_image()
	if img != null:
		var w := img.get_width()
		var h := img.get_height()
		var top := -1
		var bot := -1
		for y in range(0, h, 2):
			for x in range(0, w, 3):
				if img.get_pixel(x, y).a > 0.5:
					if top < 0:
						top = y
					bot = y
					break
		if top >= 0:
			var body := float(bot - top)
			var best := Vector2(-1, -1)
			for y in range(int(top + body * 0.24), int(top + body * 0.52), 2):
				for x in range(w - 1, -1, -1):
					if img.get_pixel(x, y).a > 0.5:
						if x > best.x:
							best = Vector2(x, y)
						break
			if best.x >= 0:
				var off := Vector2.ZERO
				var full := Vector2(w, h)
				if tex is AtlasTexture:
					off = (tex as AtlasTexture).margin.position
					full = tex.get_size()
				out = best + off - full * 0.5 - Vector2(3, 0)
	_front_cache[key] = out
	return out


## The held weapon rides the hand and swings with the strike: raised back on
## the wind-up, whipped through on contact (with a trail), settling after.
func _place_melee(delta: float) -> void:
	var path := "res://assets/sprites/held/%s.png" % pickup
	var want := pickup != "" and not (pickup in GUNS) and _anim != null and not downed and ResourceLoader.exists(path)
	if not want:
		if _melee:
			_melee.visible = false
		if _melee_trail:
			_melee_trail.clear_points()
		return
	if _melee == null:
		_melee = Sprite2D.new()
		_melee.centered = false
		_melee.texture_filter = SpriteBook.world_filter()
		_melee.z_index = 1
		squash_root.add_child(_melee)
		_melee_trail = Line2D.new()
		_melee_trail.width = 7.0
		_melee_trail.z_index = 1
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.0))
		g.set_color(1, Color(1.0, 0.95, 0.85, 0.75))
		_melee_trail.gradient = g
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_melee_trail.material = cm
		squash_root.add_child(_melee_trail)
	if str(_melee.get_meta("kind", "")) != pickup:
		_melee.texture = load(path)
		_melee.set_meta("kind", pickup)
		_melee.modulate = Color.WHITE
	var m := _held_meta(pickup)
	var grip: Array = m.get("grip", [6, 6])
	var tip: Array = m.get("tip", [40, 6])
	var light := pickup in LIGHT_MELEE
	var rest := -0.35 if light else -1.95
	var target := rest
	var rate := 12.0
	match _strike_phase:
		1:
			target = -1.2 if light else -2.7
			rate = 22.0
		2:
			target = 0.15 if light else 0.45
			rate = 46.0
		3:
			target = 0.3 if light else 0.7
			rate = 10.0
	if blocking:
		target = -1.45
	_melee_ang = lerp_angle(_melee_ang, target, 1.0 - exp(-rate * delta))
	var hand := _anim.position + _front_hand() * _anim.scale
	_melee.scale = _anim.scale
	_melee.rotation = _melee_ang
	_melee.position = hand - Vector2(float(grip[0]), float(grip[1])).rotated(_melee_ang) * _melee.scale
	_melee.visible = true
	var tip_at := _melee.position + Vector2(float(tip[0]), float(tip[1])).rotated(_melee_ang) * _melee.scale
	if _strike_phase == 2:
		_melee_trail.add_point(tip_at)
		while _melee_trail.get_point_count() > 6:
			_melee_trail.remove_point(0)
	elif _melee_trail.get_point_count() > 0:
		_melee_trail.remove_point(0)



## Every landed blow wears the melee weapon; at zero it breaks in the hand:
## splinters or a bent bar, a crack, and you are back to fists.
func _wear_melee(at: Vector2) -> void:
	if pickup == "" or pickup in GUNS or not Arsenal.USES.has(pickup):
		return
	melee_uses -= 1
	# The weapon wears the fight: every blow leaves it a little bloodier.
	if _melee != null:
		var worn := 1.0 - float(melee_uses) / float(maxi(1, Arsenal.uses(pickup)))
		_melee.modulate = Color(1.0, 1.0 - 0.45 * worn, 1.0 - 0.5 * worn)
	if melee_uses == 3:
		Juice.popup_number(global_position + Vector2(0, -104), "CRACKING", Color(1.0, 0.7, 0.3))
	if melee_uses > 0:
		return
	BrawlPlus.last_hit(self, at)
	var wood := pickup in Arsenal.WOOD
	var tip := _melee.global_position if _melee != null else at
	Juice.shout("%s BROKE" % str(WeaponBook.spec(pickup).get("title", pickup)).to_upper())
	Mixer.play_sfx("res://assets/audio/sfx/crate_break.ogg" if wood else "res://assets/audio/sfx/metal_bang.ogg", randf_range(1.1, 1.3), -3.0)
	var p := CPUParticles2D.new()
	p.global_position = tip
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 16
	p.lifetime = 0.6
	p.direction = Vector2(float(facing), -0.6)
	p.spread = 70.0
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Color(0.72, 0.5, 0.28) if wood else Color(0.7, 0.72, 0.78)
	get_parent().add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)
	Arsenal.bump("weapon_breaks")
	pickup = ""



## What the weapon in hand adds on contact: metal throws sparks, wood
## splinters, a blade opens a red slash, the sledge cracks the street.
func _weapon_contact(at: Vector2, wt: float) -> void:
	if pickup == "" or pickup in GUNS:
		return
	var blade := pickup in ["knife", "machete", "invoice_star", "clipboard"]
	var wood := pickup in Arsenal.WOOD
	if blade:
		SuitFx.spawn(at, "slash", 26.0 + 14.0 * wt, float(facing), Color(0.95, 0.12, 0.15))
	elif wood:
		var p := CPUParticles2D.new()
		p.global_position = at
		p.emitting = true
		p.one_shot = true
		p.explosiveness = 1.0
		p.amount = 7
		p.lifetime = 0.45
		p.direction = Vector2(float(facing), -0.8)
		p.spread = 55.0
		p.gravity = Vector2(0, 600)
		p.initial_velocity_min = 90.0
		p.initial_velocity_max = 200.0
		p.scale_amount_min = 1.2
		p.scale_amount_max = 2.6
		p.color = Color(0.78, 0.58, 0.34)
		get_parent().add_child(p)
		get_tree().create_timer(0.6).timeout.connect(p.queue_free)
	else:
		Juice.sparks(at)
	if pickup == "sledgehammer":
		SuitFx.spawn(Vector2(at.x, global_position.y), "ring", 70.0, 1.0, Color(1.0, 0.85, 0.6))
		Juice.pulse_shake(6.0)
		Juice.hitstop(3)



## A boss pattern landing: a big hit through any guard.
func _take_crush(from: Node) -> void:
	var dmg := int(round(24.0 * Heroes.enemy_dmg_mul() * Artifacts.enemy_dmg() * NightExtras.guard_mul()))
	if suit_set() == "shaolin":
		dmg = int(round(float(dmg) * 0.7))
	var srun := SurviveRun.get_run(get_tree())
	if srun and srun.armor() > 0.0:
		dmg = maxi(1, int(round(float(dmg) * (1.0 - srun.armor()))))
	if srun and SurvExtras.pact_sum("dmg") > 0.0:
		dmg = int(round(float(dmg) * (1.0 + SurvExtras.pact_sum("dmg"))))
	hp = maxi(0, hp - dmg)
	invuln = 40
	_hurt_t = 0.45
	_cancel_strike()
	Juice.break_combo()
	Juice.flash_white_red(visual)
	Juice.hitstop(7)
	Juice.pulse_shake(8.0)
	Juice.popup_number(global_position + Vector2(0, -96), "-%d" % dmg, Color(1.0, 0.3, 0.25))
	VoBank.line(role, "hurt", 0.9)
	Mixer.play_sfx("res://assets/audio/sfx/hit_side_kick.ogg", 0.8, 0.0)
	if from is Node2D:
		var dir := signf(global_position.x - (from as Node2D).global_position.x)
		global_position.x += dir * 34.0
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood:
		blood.hit(self, "gut", signf(global_position.x - (from as Node2D).global_position.x) if from is Node2D else 1.0, 0.8, 0.8)
	if hp <= int(round(float(max_hp) * 0.3)) and bandage > 0 and hp > 0:
		bandage -= 1
		hp = mini(max_hp, hp + int(round(float(max_hp) * 0.3)))
		Juice.shout("BANDAGE")
	if hp <= 0:
		_go_down()
		return
	_maybe_knockdown("heavy", from)



## PARKOUR tree landings: GROUND POUND hits everyone near a hard landing,
## METEOR stuns the whole crowd after a big drop.
func _land_perks(fall: float) -> void:
	if fall > 300.0 and Trees.has("p_quake"):
		SuitFx.spawn(global_position, "ring", 80.0, 1.0, Color(1.0, 0.85, 0.6))
		Juice.pulse_shake(4.0)
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk and (n as Punk).global_position.distance_to(global_position) < 80.0:
				(n as Punk).take_hit("heavy", self)
	if fall > 620.0 and Trees.has("p_meteor"):
		Juice.shout("METEOR")
		SuitFx.spawn(global_position, "ring", 170.0, 1.0, Color(1.0, 0.6, 0.3))
		Juice.hitstop(6)
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk and (n as Punk).global_position.distance_to(global_position) < 170.0:
				(n as Punk).recover = maxf((n as Punk).recover, 1.3)
