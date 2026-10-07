class_name LootDrop
extends Node2D

## Things that fall out of broken stuff: cash (gold), a red flask (heals a
## quarter), and the one adrenaline syringe hidden on every map (full
## refill). They pop out in an arc, bounce, bob and glint, and fly to
## whoever walks close.

const KINDS := {
	"cash": {"tex": "res://assets/sprites/loot/cash.png", "scale": 0.7},
	"coin": {"tex": "res://assets/sprites/loot/coin.png", "scale": 0.55},
	"flask": {"tex": "res://assets/sprites/loot/flask.png", "scale": 0.72},
	"syringe": {"tex": "res://assets/sprites/loot/syringe.png", "scale": 0.8},
	"shard_son": {"tex": "res://assets/sprites/loot/shard_son.png", "scale": 0.62},
	"shard_father": {"tex": "res://assets/sprites/loot/shard_father.png", "scale": 0.62},
	"gear": {"tex": "res://assets/sprites/loot/gear_box.png", "scale": 0.62},
	"card_token": {"tex": "res://assets/sprites/icons/cur_card_token.png", "scale": 3.4},
}

var kind := "cash"
var amount := 5
## For "gear": which piece and at what rarity.
var item := ""
var item_tier := 0
var floor_y := 500.0
var _v := Vector2.ZERO
var _sp: Sprite2D
var _shadow: Polygon2D
var _t := 0.0
var _landed := false
var _taken := false
var _glow: PointLight2D


static func spawn(host: Node, at: Vector2, what: String, n: int = 0, toss: float = 1.0) -> LootDrop:
	var d := LootDrop.new()
	d.kind = what
	d.amount = n
	d.floor_y = clampf(at.y, 432.0, 600.0)
	d.position = Vector2(at.x, d.floor_y - 20.0)
	d._v = Vector2(randf_range(-70.0, 70.0) * toss, randf_range(-230.0, -160.0))
	host.add_child(d)
	return d


func _ready() -> void:
	z_index = 4
	add_to_group("loot")
	_shadow = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a) * 7.0, sin(a) * 1.8))
	_shadow.polygon = pts
	_shadow.color = Color(0, 0, 0, 0.45)
	_shadow.z_as_relative = false
	_shadow.z_index = 2
	add_child(_shadow)
	var row: Dictionary = KINDS.get(kind, KINDS["cash"])
	_sp = Sprite2D.new()
	_sp.texture = load(str(row["tex"]))
	_sp.centered = true
	var s := float(row["scale"]) * SpriteBook.DRAW_SCALE
	# Gear shows the piece itself (its painted icon), not a box.
	var gp := "res://assets/sprites/gear/%s.png" % item
	if kind == "gear" and item != "" and ResourceLoader.exists(gp):
		_sp.texture = load(gp)
		s = 22.0 / float(_sp.texture.get_height())
	_sp.scale = Vector2(s, s)
	_sp.offset = Vector2(0, -float(_sp.texture.get_height()) * 0.5)
	_sp.texture_filter = SpriteBook.world_filter()
	add_child(_sp)
	if kind == "syringe" or kind == "flask" or kind.begins_with("shard") or kind == "gear" or kind == "card_token":
		_glow = PointLight2D.new()
		_glow.texture = LightRig.radial_tex()
		_glow.texture_scale = 0.35
		_glow.color = Color(0.4, 1.0, 0.5) if kind == "syringe" else Color(1.0, 0.3, 0.3)
		if kind == "card_token":
			_glow.color = Color(1.0, 0.8, 0.3)
		if kind == "shard_son":
			_glow.color = Color(1.0, 0.85, 0.3)
		elif kind == "shard_father":
			_glow.color = Color(1.0, 0.35, 0.3)
		elif kind == "gear":
			_glow.color = Rarity.color(Rarity.ORDER[clampi(item_tier, 0, 4)])
			_glow.energy = 1.3
		_glow.energy = 0.9
		_glow.position = Vector2(0, -10)
		add_child(_glow)


var _beam: Polygon2D
var _sparks: CPUParticles2D


## Loot that matters announces itself: a light pillar in its rarity colour
## for gear (taller the rarer), twinkling sparks around shards.
func _dress_up() -> void:
	if kind == "gear":
		var col := Rarity.color(Rarity.ORDER[clampi(item_tier, 0, 4)])
		var h := 60.0 + 30.0 * float(item_tier)
		_beam = Polygon2D.new()
		_beam.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(2, -h), Vector2(-2, -h)])
		_beam.vertex_colors = PackedColorArray([Color(col.r, col.g, col.b, 0.55), Color(col.r, col.g, col.b, 0.55), Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.0)])
		var bm := CanvasItemMaterial.new()
		bm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		bm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_beam.material = bm
		_beam.z_index = -1
		add_child(_beam)
	if kind.begins_with("shard") or kind == "gear":
		_sparks = CPUParticles2D.new()
		_sparks.amount = 6
		_sparks.lifetime = 0.9
		_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		_sparks.emission_sphere_radius = 9.0
		_sparks.gravity = Vector2(0, -18)
		_sparks.initial_velocity_min = 2.0
		_sparks.initial_velocity_max = 8.0
		_sparks.scale_amount_min = 0.8
		_sparks.scale_amount_max = 1.6
		_sparks.position = Vector2(0, -10)
		var sc := Color(1.0, 0.9, 0.5)
		if kind == "shard_father":
			sc = Color(1.0, 0.5, 0.45)
		elif kind == "gear":
			sc = Rarity.color(Rarity.ORDER[clampi(item_tier, 0, 4)]).lightened(0.3)
		_sparks.color = sc
		var sm := CanvasItemMaterial.new()
		sm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_sparks.material = sm
		add_child(_sparks)


func _process(delta: float) -> void:
	_t += delta
	if _landed and _beam == null and _sparks == null and (kind == "gear" or kind.begins_with("shard")):
		_dress_up()
	if _beam:
		_beam.modulate.a = 0.75 + 0.25 * sin(_t * 3.0)
	if _taken:
		if _beam:
			_beam.visible = false
		return
	if not _landed:
		_v.y += 900.0 * delta
		position += _v * delta
		_sp.rotation += _v.x * delta * 0.03
		if position.y >= floor_y and _v.y > 0.0:
			position.y = floor_y
			if _v.y > 120.0:
				_v.y *= -0.38
				_v.x *= 0.6
				Juice.play("res://assets/audio/cling.wav")
			else:
				_landed = true
				_sp.rotation = 0.0
		_shadow.position.y = floor_y - position.y
		_shadow.scale = Vector2.ONE * clampf(1.0 - (floor_y - position.y) / 80.0, 0.3, 1.0)
		return
	if kind == "gear" and _glow:
		_glow.color = Rarity.color(Rarity.ORDER[clampi(item_tier, 0, 4)])
	# Bob and glint while waiting.
	_sp.position.y = -2.0 - 2.0 * sin(_t * 3.2)
	_sp.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.5, 1.2), maxf(0.0, sin(_t * 2.4)) ** 8.0)
	if _glow:
		_glow.energy = 0.7 + 0.3 * sin(_t * 4.0)
	if _t < 0.35:
		return
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter) or (n as Fighter).downed:
			continue
		var f := n as Fighter
		var d := f.global_position - global_position
		if absf(d.x) < 22.0 and absf(d.y) < 18.0:
			_take(f)
			return
		if absf(d.x) < 48.0 and absf(d.y) < 26.0 and (kind in ["cash", "coin"] or kind.begins_with("shard")):
			position += d.normalized() * 140.0 * delta


func _take(f: Fighter) -> void:
	_taken = true
	match kind:
		"cash", "coin":
			var g := maxi(1, amount)
			if Charms.has("lucky_coin"):
				g = int(ceil(float(g) * 1.5))
			g = int(ceil(float(g) * Meta.gold_mul() * Artifacts.gold()))
			if Trees.has("f_gold") and SurviveRun.get_run(get_tree()) != null:
				g = int(ceil(float(g) * 1.5))
			FamilyProfile.add_gold(g)
			Juice.popup_number(global_position + Vector2(0, -24), "+%d" % g, UiKit.GOLD)
			Juice.rewards.give("gold", g, get_global_transform_with_canvas().origin, false)
			Juice.play("res://assets/audio/cash.wav" if ResourceLoader.exists("res://assets/audio/cash.wav") else "res://assets/audio/cling.wav")
		"flask":
			var heal := 0 if Artifacts.has("no_lunch") else int(round(float(f.max_hp) * 0.25))
			f.hp = mini(f.max_hp, f.hp + heal)
			Juice.popup_number(global_position + Vector2(0, -24), "+%d HP" % heal, Palette.READY)
			Juice.play("res://assets/audio/heal.wav" if ResourceLoader.exists("res://assets/audio/heal.wav") else "res://assets/audio/cling_ok.wav")
			Juice.pulse_shake(1.5)
		"shard_son", "shard_father":
			var who := "son" if kind == "shard_son" else "father"
			var n := maxi(1, amount)
			Heroes.add_shards(who, n)
			var nm := FamilyProfile.son_name() if who == "son" else FamilyProfile.father_name()
			Juice.popup_number(global_position + Vector2(0, -28), "+%d %s SHARD%s" % [n, nm.to_upper(), "S" if n > 1 else ""], Color(1.0, 0.85, 0.3) if who == "son" else Color(1.0, 0.4, 0.35))
			Juice.play("res://assets/audio/card.wav")
		"gear":
			GearInv.add(item, item_tier)
			FamilyProfile.flag_unseen("gear_" + item)
			var spec := GearBook.item(item)
			var rn := Rarity.ORDER[clampi(item_tier, 0, 4)]
			Juice.toast("reward", "%s  ·  %s" % [str(spec.get("title", spec.get("name", item))).to_upper(), rn.to_upper()], "Gear found. Three alike combine in GEAR.", item)
			Rarity.juice(rn, str(spec.get("title", item)))
			Juice.play("res://assets/audio/chest.wav")
		"card_token":
			VaultCards.add_tokens(maxi(1, amount), "Dropped by the thug. Spend it in the CARD VAULT.")
			Juice.play("res://assets/audio/card.wav")
			Rarity.juice("epic", "CARD TOKEN")
		"syringe":
			f.hp = f.max_hp
			f.steam = Fighter.STEAM_MAX
			Juice.popup_number(global_position + Vector2(0, -30), "FULL REFILL", Palette.READY)
			Juice.toast("reward", "ADRENALINE", "One per street. Every heart back, steam full.")
			Juice.play("res://assets/audio/trick_perfect.wav")
			Juice.hitstop(4)
			Juice.pulse_shake(4.0)
			FamilyProfile.data["syringes"] = int(FamilyProfile.data.get("syringes", 0)) + 1
			_heal_wounds(f)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_sp, "position:y", -40.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sp, "scale", _sp.scale * 1.8, 0.3)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(queue_free)


## A full refill cleans the face up a bit too.
func _heal_wounds(f: Fighter) -> void:
	var a: AnimatedSprite2D = f.get("_anim")
	if a != null and a.material is ShaderMaterial:
		(a.material as ShaderMaterial).set_shader_parameter("wound", 0.0)
		f.set("_splat", 0.0)
		(a.material as ShaderMaterial).set_shader_parameter("splat", 0.0)
