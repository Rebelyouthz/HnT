class_name IconBook
extends RefCounted

## Every pixel-art icon (tools/icon_pack.py, 32x32 texels) and where each
## thing in the game finds its own. Icons are drawn nearest-filtered at whole
## multiples of the pixel grid: a texel is 2 design px, so 32 texels sit in
## 64 design px (SIZE_M), 128/3 (SIZE_S, 2 screen px a texel) or 128 (SIZE_L).

const SIZE_S := 128.0 / 3.0
const SIZE_M := 64.0
const SIZE_L := 128.0
const DIR := "res://assets/sprites/icons/%s.png"
const SURV := "res://assets/sprites/survive/%s.png"

## Old PixelIcon glyph names -> icon.
const GLYPH := {
	"gold": "cur_gold", "gem": "cur_gem", "gems": "cur_gem", "rep": "cur_rep", "lock": "cur_lock",
	"heart": "cur_heart", "tokens": "cur_scoin", "scoin": "cur_scoin", "s-coins": "cur_scoin",
	"flow": "cur_flow", "xp": "cur_xp", "chi": "cur_chi", "ammo": "cur_ammo", "knives": "cur_knife",
	"knife": "cur_knife", "chest": "cur_chest", "key": "cur_key", "wheel": "cur_wheel",
	"shield": "t_armor", "boot": "node_speed", "fist": "t_dmg", "bolt": "bolt", "cross": "node_heal",
	"drop": "node_steam", "star": "node_score", "eye": "node_eyes",
}

## Card tags -> icon, for rule cards without their own.
const TAG := {
	"AIR": "card_head_trampoline", "COOP": "card_family_discount", "BLEED": "card_office_rage",
	"SNAP": "card_quiet_lunch", "REVIVE": "card_double_slap", "SHOT": "card_ricochet_policy",
	"STEAM": "card_steam_tax", "GOLD": "cur_gold", "BLOCK": "t_armor", "PARRY": "t_armor",
	"THROW": "card_weapon_catch", "HEAVY": "t_dmg", "LIGHT": "t_dmg", "STOMP": "card_stomp_policy",
	"HEAT": "card_molotov_lob", "PARKOUR": "card_named_line", "COMBO": "node_combo", "RULE": "node_score",
}

## Skill tree nodes (all three trees) -> icon.
const NODE := {
	# brawl
	"thick_skin": "node_hp", "second_lungs": "node_steam", "bandage_pocket": "node_bandage",
	"wardrobe_stats": "node_wardrobe", "iron_gut": "node_gut", "farm_patience": "node_patience",
	"disarm_habit": "node_disarm", "pocket_sand": "node_sand", "heavy_wrist": "node_heavy",
	"cling_callus": "node_cling", "long_commute": "node_commute", "quiet_hands": "node_quiet",
	"xp_magnet": "node_xp", "crown": "node_crown", "night_eyes": "node_eyes", "pinball_brain": "node_pinball",
	"school_pride": "node_school", "group_rate": "node_group", "summit_joke": "node_joke",
	# survivor
	"s_slot": "i_hands", "s_reroll": "meta_reroll", "s_banish": "meta_banish", "s_evolve": "evolve",
	"s_item_slot": "gear_box", "s_ult2": "u_dome", "s_ult3": "u_friday", "f_start": "t_luck",
	"f_chest": "cur_chest", "f_magnet": "t_pickup", "f_tokens": "cur_scoin", "f_luck": "i_receipt",
	"f_revive": "meta_revival", "f_gold": "meta_greed", "s_boxes": "gear_box", "s_four": "i_card",
	"f_gear": "gear_hi_vis", "f_wheel": "cur_wheel", "u_limit": "t_dmg", "u_start2": "coffee",
	"u_cart": "cart", "u_bag": "bag", "u_hydrant": "hydrant", "u_mail": "mailbomb",
	"u_sprinkler": "sprinkler", "u_audit": "audit", "u_gravy": "gravy",
	# parkour
	"p_trick_steam": "node_steam", "p_flow_heal": "node_heal", "p_chain": "node_chain",
	"p_combo_keep": "node_combo", "p_speed": "node_speed", "p_ghost": "node_ghost",
	"p_score": "node_score", "p_air_jump": "node_jump", "p_float": "node_float",
	"p_coyote": "card_dive_bounce", "p_high": "card_head_trampoline", "p_wall": "node_wall",
	"p_air_ctrl": "card_shuttle_rip", "p_hang": "node_hang", "p_stomp": "node_stomp",
	"p_bounce": "card_stomp_policy", "p_slide_kick": "node_slide", "p_quake": "node_quake",
	"p_roll": "node_roll", "p_meteor": "node_meteor", "p_iron": "node_iron",
}

## META upgrades -> icon.
const META := {
	"vitality": "node_hp", "strength": "meta_strength", "second_wind": "node_steam",
	"fortune": "meta_fortune", "shard_sense": "meta_shard", "scavenger": "meta_scavenger",
	"starter_kit": "meta_starter", "extra_life": "meta_life", "spring_legs": "node_jump",
	"wall_runner": "node_wall", "air_control": "card_shuttle_rip", "flow_state": "cur_flow",
	"iron_ankles": "node_iron", "trick_value": "node_score", "sprint": "node_speed",
	"s_might": "t_dmg", "s_armor": "t_armor", "s_maxhp": "t_hp", "s_recovery": "t_regen",
	"s_cooldown": "t_cd", "s_area": "t_area", "s_speed": "t_speed", "s_amount": "meta_amount",
	"s_magnet": "t_pickup", "s_luck": "t_luck", "s_growth": "t_xp", "s_greed": "meta_greed",
	"s_reroll": "meta_reroll", "s_banish": "meta_banish", "s_revival": "meta_revival",
}

static var _cache := {}


static func has(name: String) -> bool:
	return tex(name) != null


static func tex(name: String) -> Texture2D:
	if name == "":
		return null
	if _cache.has(name):
		return _cache[name]
	var t: Texture2D = null
	for pat in [DIR, SURV]:
		var p: String = pat % name
		if ResourceLoader.exists(p):
			t = load(p) as Texture2D
			break
	_cache[name] = t
	return t


static func for_glyph(kind: String) -> String:
	var k := kind.to_lower()
	if has(k):
		return k
	return str(GLYPH.get(k, ""))


static func for_card(info: Dictionary) -> String:
	var id := str(info.get("id", ""))
	if has("card_" + id):
		return "card_" + id
	var ic := str(info.get("icon", ""))
	if ic != "" and has(ic):
		return ic
	return str(TAG.get(str(info.get("tag", "RULE")).to_upper(), "node_score"))


static func for_node(id: String) -> String:
	return str(NODE.get(id, ""))


static func for_meta(id: String) -> String:
	return str(META.get(id, "node_score"))


static func for_gear(id: String) -> String:
	return "gear_" + id


static func for_part(id: String) -> String:
	return "part_" + id


## A crisp TextureRect for an icon at `px` design size (use SIZE_*).
static func rect(name: String, px: float = SIZE_M) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.custom_minimum_size = Vector2(px, px)
	r.size = Vector2(px, px)
	r.pivot_offset = Vector2(px, px) * 0.5
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
