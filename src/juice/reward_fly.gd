class_name RewardFly
extends CanvasLayer

## Rewards you can see, and upgrades you can feel. One lives under Juice
## (`Juice.rewards`); everything is drawn on the 640x360 pixel grid.
##
## give(key, amount, from)
##     The currency icon bursts in at `from` with rays behind it, the number
##     counts up with ticking coins, then it breaks into coins that fly in an
##     arc to that currency's counter (a control that called register()).
##     The counter only ticks up as each coin lands: screens show
##     `balance - pending(key)` and refresh on `landed`.
##
## upgrade(control, color, text, big)
##     Reward-grow juice on anything that was bought or levelled: the control
##     punches up and flashes, a ring and sparks burst out of it, the text
##     rises out of it, and a rising chime (plus a boom when big) plays.

signal landed(key: String)

const ICON := {"gold": "cur_gold", "gems": "cur_gem", "tokens": "cur_scoin", "rep": "cur_rep", "flow": "cur_flow", "xp": "cur_xp"}
const NAME := {"gold": "GOLD", "gems": "GEMS", "tokens": "S-COINS", "rep": "REP", "flow": "FLOW", "xp": "XP"}
const COL := {
	"gold": Color(1.0, 0.82, 0.3), "gems": Color(0.45, 0.8, 1.0), "tokens": Color(0.45, 1.0, 0.75),
	"rep": Color(0.82, 0.84, 0.9), "flow": Color(0.4, 0.95, 1.0), "xp": Color(0.6, 1.0, 0.4),
}
## Where coins go when no counter is on screen (top-right corner).
const CORNER := {"gold": Vector2(470, 14), "gems": Vector2(530, 14), "tokens": Vector2(590, 14), "rep": Vector2(610, 14), "flow": Vector2(590, 14), "xp": Vector2(320, 14)}
const SND := "res://assets/audio/ui/%s.wav"
## How big a reward stands in the middle of the screen before it flies home.
const BIG := 2.3
## Scale of an upgrade / equip showcase while it holds centre stage.
const SHOW := 1.9

var _targets := {}
var _pending := {}
var _tick_t := 0.0


func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS


static func vp_of(c: CanvasItem) -> Vector2:
	if c is Control:
		var k := c as Control
		return k.get_global_transform_with_canvas() * (k.size * 0.5)
	return c.get_global_transform_with_canvas().origin


static func snd(name: String, pitch := 1.0, db := 0.0) -> void:
	Mixer.play_sfx(SND % name, pitch, db)


## A counter for `key` (the newest registered visible one wins).
func register(key: String, c: Control) -> void:
	var list: Array = _targets.get(key, [])
	list.append(weakref(c))
	_targets[key] = list


func pending(key: String) -> int:
	return int(_pending.get(key, 0))


func _target(key: String) -> Control:
	var list: Array = _targets.get(key, [])
	for i in range(list.size() - 1, -1, -1):
		var c: Variant = (list[i] as WeakRef).get_ref()
		if c is Control and (c as Control).is_inside_tree() and (c as Control).is_visible_in_tree():
			return c
	return null


func _to(key: String) -> Vector2:
	var t := _target(key)
	return vp_of(t) if t != null else Vector2(CORNER.get(key, Vector2(600, 14)))


func _center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5


# --- rewards ---------------------------------------------------------------

func give(key: String, amount: int, from := Vector2(-1, -1), banner := true) -> void:
	if amount <= 0 or not ICON.has(key):
		return
	if from.x < 0.0:
		from = _center()
	_pending[key] = pending(key) + amount
	landed.emit(key)
	if banner:
		# Centre stage first (big, counted up), then it shrinks and the coins
		# fly home. Several at once queue up instead of piling on each other.
		var wait := maxf(0.0, _stage_free - _now())
		# Whole banner: pop 0.38 + count + hold 0.4 + shrink 0.26.
		_stage_free = _now() + wait + 1.0 + clampf(0.35 + float(amount) / 300.0, 0.35, 0.9)
		if wait > 0.0:
			get_tree().create_timer(wait, true, false, true).timeout.connect(func() -> void: _banner(key, amount, from))
		else:
			_banner(key, amount, from)
	else:
		_burst(key, amount, from, 0.0)


var _stage_free := 0.0
## Rapid buys (a row of tree nodes) do not stack showcases: the next one
## inside this window juices the control directly.
var _show_busy := 0.0


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _banner(key: String, amount: int, from: Vector2) -> void:
	var col: Color = COL[key]
	var mid := _center() + Vector2(0, -10)
	var root := Node2D.new()
	root.position = from
	root.scale = Vector2(0.2, 0.2)
	add_child(root)
	var veil := _veil(0.5)
	var rays := Rays.new()
	rays.color = col
	root.add_child(rays)
	var ic := Sprite2D.new()
	ic.texture = IconBook.tex(str(ICON[key]))
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.position = Vector2(0, -8)
	root.add_child(ic)
	var lab := Label.new()
	lab.text = "+0"
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_override("font", UiKit.title_font())
	lab.add_theme_font_size_override("font_size", 16)
	lab.add_theme_color_override("font_color", col.lightened(0.2))
	lab.add_theme_color_override("font_outline_color", UiKit.INK)
	lab.add_theme_constant_override("outline_size", 4)
	lab.size = Vector2(160, 20)
	lab.position = Vector2(-80, 9)
	root.add_child(lab)
	var nm := Label.new()
	nm.text = str(NAME[key])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UiKit.pixel_font())
	nm.add_theme_font_size_override("font_size", 8)
	nm.add_theme_color_override("font_color", col)
	nm.add_theme_color_override("font_outline_color", UiKit.INK)
	nm.add_theme_constant_override("outline_size", 3)
	nm.size = Vector2(160, 12)
	nm.position = Vector2(-80, 27)
	root.add_child(nm)
	snd("reward_pop")
	var count_t := clampf(0.35 + float(amount) / 300.0, 0.35, 0.9)
	var tw := create_tween()
	tw.tween_property(root, "position", mid, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "scale", Vector2(BIG * 1.2, BIG * 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "scale", Vector2(BIG, BIG), 0.1)
	tw.tween_method(func(v: float) -> void:
		var n := int(round(v))
		if lab.text != "+%d" % n:
			lab.text = "+%d" % n
			_tick_t -= 1.0
			if _tick_t <= 0.0:
				_tick_t = 2.0
				snd("coin_tick", 1.0 + 0.8 * v / float(amount), -6.0)
	, 0.0, float(amount), count_t)
	tw.tween_callback(func() -> void:
		lab.add_theme_color_override("font_color", Color.WHITE)
		snd("coin_tick", 2.0, -3.0))
	tw.tween_property(root, "scale", Vector2(BIG * 1.12, BIG * 1.12), 0.08)
	tw.tween_interval(0.32)
	# Shrink to coin size, drift toward the counter, then break into coins.
	tw.tween_property(root, "scale", Vector2(0.45, 0.45), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(root, "position", mid.lerp(_to(key), 0.25), 0.16)
	tw.parallel().tween_property(veil, "color:a", 0.0, 0.2)
	tw.tween_callback(func() -> void: _burst(key, amount, root.position + Vector2(0, -8), 0.0))
	tw.tween_property(root, "scale", Vector2(0.0, 0.0), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		root.queue_free()
		veil.queue_free())


func _burst(key: String, amount: int, from: Vector2, delay: float) -> void:
	var n := clampi(amount if key != "gold" else int(ceil(float(amount) / 3.0)), 1, 14 if key == "gold" else 10)
	var tex := IconBook.tex(str(ICON[key]) + "_s")
	var left := amount
	snd("whoosh", 1.0, -4.0)
	for i in n:
		var share := left / (n - i)
		left -= share
		var c := Sprite2D.new()
		c.texture = tex
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.position = from
		add_child(c)
		var a := randf() * TAU
		var spread := from + Vector2(cos(a), sin(a) * 0.7) * randf_range(14.0, 30.0)
		var tw := create_tween()
		tw.tween_interval(delay + 0.03 * float(i))
		tw.tween_property(c, "position", spread, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var idx := i
		var bend := Vector2(randf_range(-60.0, 60.0), randf_range(-50.0, 10.0))
		tw.tween_method(func(t: float) -> void:
			var to := _to(key)
			var mid := (spread + to) * 0.5 + bend
			var p := spread.lerp(mid, t).lerp(mid.lerp(to, t), t)
			c.position = p.round()
			c.scale = Vector2.ONE * lerpf(1.0, 0.7, t)
		, 0.0, 1.0, randf_range(0.42, 0.56)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			_land(key, share, idx)
			c.queue_free())


func _land(key: String, share: int, idx: int) -> void:
	_pending[key] = maxi(0, pending(key) - share)
	landed.emit(key)
	snd("gem_land" if key == "gems" else "coin_land", 1.0 + minf(0.6, 0.05 * float(idx)), -5.0)
	var at := _to(key)
	_sparks(at, COL[key], 5, 18.0)
	var t := _target(key)
	if t != null:
		t.pivot_offset = t.size * 0.5
		var tw := t.create_tween()
		tw.tween_property(t, "scale", Vector2(1.22, 1.22), 0.05)
		tw.tween_property(t, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- upgrades ----------------------------------------------------------------

func upgrade(target: Control, color: Color, text := "", big := false, icon := "") -> void:
	if text != "" and target != null and target.is_inside_tree() and _now() >= _show_busy:
		_show_busy = _now() + 0.6
		# Seen first: the word (and icon) stands big in the middle, then
		# shrinks and flies into the thing that was bought / levelled / worn.
		_showcase(icon, text, color, "", big, func() -> Vector2: return vp_of(target) if is_instance_valid(target) and target.is_inside_tree() else _center(),
			func() -> void:
				if is_instance_valid(target) and target.is_inside_tree():
					_hit_target(target, color, "", big)
				else:
					_hit_target(null, color, "", big))
		return
	_hit_target(target, color, text, big)


## Showcase centre stage, then fly to `to.call()` and run `arrive`.
func _showcase(icon_name: String, title: String, color: Color, sub: String, big: bool, to: Callable, arrive: Callable, hold := -1.0) -> void:
	var c := _center() + Vector2(0, -14)
	var veil := _veil(0.55 if big else 0.45)
	var root := Node2D.new()
	root.position = c
	root.scale = Vector2(0.15, 0.15)
	add_child(root)
	var rays := Rays.new()
	rays.color = color
	rays.scale = Vector2(1.6, 1.6) if big else Vector2(1.25, 1.25)
	root.add_child(rays)
	var y := 6.0
	if icon_name != "":
		var ic := Sprite2D.new()
		ic.texture = IconBook.tex(icon_name)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.scale = Vector2(2, 2)
		ic.position = Vector2(0, -14)
		root.add_child(ic)
		y = 20.0
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", UiKit.title_font())
	t.add_theme_font_size_override("font_size", 20 if big else 16)
	t.add_theme_color_override("font_color", color.lightened(0.35))
	t.add_theme_color_override("font_outline_color", UiKit.INK)
	t.add_theme_constant_override("outline_size", 5)
	t.size = Vector2(420, 24)
	t.position = Vector2(-210, y - 12)
	root.add_child(t)
	if sub != "":
		var s2 := Label.new()
		s2.text = sub
		s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s2.add_theme_font_override("font", UiKit.pixel_font())
		s2.add_theme_font_size_override("font_size", 8)
		s2.add_theme_color_override("font_color", Palette.TEXT)
		s2.add_theme_color_override("font_outline_color", UiKit.INK)
		s2.add_theme_constant_override("outline_size", 3)
		s2.size = Vector2(420, 14)
		s2.position = Vector2(-210, y + 12)
		root.add_child(s2)
	snd("reward_pop", 1.1 if big else 1.25, -2.0)
	if big:
		snd("up_boom", 1.0, -5.0)
	_sparks(c, color, 16 if big else 8, 70.0 if big else 46.0)
	var keep := hold if hold >= 0.0 else (0.55 if big else 0.32)
	var tw := create_tween()
	var hs := SHOW * (1.2 if big else 1.0)
	tw.tween_property(root, "scale", Vector2(hs * 1.2, hs * 1.2), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "scale", Vector2(hs, hs), 0.08)
	tw.tween_interval(keep)
	tw.tween_property(root, "scale", Vector2(0.55, 0.55), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(veil, "color:a", 0.0, 0.2)
	var bend := Vector2(randf_range(-40.0, 40.0), -50.0)
	tw.tween_method(func(k: float) -> void:
		var dest: Vector2 = to.call()
		var m := (c + dest) * 0.5 + bend
		root.position = c.lerp(m, k).lerp(m.lerp(dest, k), k).round()
		root.scale = Vector2.ONE * lerpf(0.55, 0.16, k)
		root.modulate.a = lerpf(1.0, 0.75, k)
	, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		snd("whoosh", 1.4, -8.0)
		arrive.call()
		root.queue_free()
		veil.queue_free())
	snd("whoosh", 0.9, -9.0)


## A thin dark veil so whatever is centre stage reads over a busy menu.
func _veil(a: float) -> ColorRect:
	var v := ColorRect.new()
	v.color = Color(0, 0, 0.02, a)
	v.size = get_viewport().get_visible_rect().size
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	move_child(v, 0)
	return v


## Something new landed in a slot / list: showcase, then into `slot`
## (or the top-right corner where the bag lives when there is none).
func equip(icon_name: String, title: String, color: Color, slot: Control = null, sub := "") -> void:
	_showcase(icon_name, title, color, sub, false,
		func() -> Vector2: return vp_of(slot) if slot != null and is_instance_valid(slot) and slot.is_inside_tree() else Vector2(get_viewport().get_visible_rect().size.x - 30.0, 16.0),
		func() -> void: _hit_target(slot if slot != null and is_instance_valid(slot) and slot.is_inside_tree() else null, color, "", false))


func _hit_target(target: Control, color: Color, text := "", big := false) -> void:
	var at := vp_of(target) if target != null and target.is_inside_tree() else _center()
	if target != null and target.is_inside_tree():
		target.pivot_offset = target.size * 0.5
		var tw := target.create_tween()
		tw.tween_property(target, "scale", Vector2(1.2, 1.2), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(target, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		var m0 := target.modulate
		var tf := target.create_tween()
		tf.tween_property(target, "modulate", Color(2.2, 2.2, 2.0, m0.a), 0.04)
		tf.tween_property(target, "modulate", m0, 0.25)
	var ring := Ring.new()
	ring.color = color
	ring.position = at
	add_child(ring)
	var tr := create_tween()
	tr.tween_property(ring, "r", 46.0 if big else 30.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tr.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tr.tween_callback(ring.queue_free)
	_sparks(at, color, 18 if big else 10, 60.0 if big else 40.0)
	if text != "":
		var lab := Label.new()
		lab.text = text
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_override("font", UiKit.title_font())
		lab.add_theme_font_size_override("font_size", 16 if big else 12)
		lab.add_theme_color_override("font_color", color.lightened(0.35))
		lab.add_theme_color_override("font_outline_color", UiKit.INK)
		lab.add_theme_constant_override("outline_size", 4)
		lab.size = Vector2(240, 20)
		lab.position = at + Vector2(-120, -18)
		lab.pivot_offset = Vector2(120, 10)
		lab.scale = Vector2(0.3, 0.3)
		add_child(lab)
		var tl := create_tween()
		tl.tween_property(lab, "scale", Vector2(1.2, 1.2), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tl.tween_property(lab, "scale", Vector2.ONE, 0.08)
		tl.parallel().tween_property(lab, "position:y", lab.position.y - 26.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tl.tween_property(lab, "modulate:a", 0.0, 0.25)
		tl.tween_callback(lab.queue_free)
	snd("up_rise", 1.0, -3.0)
	if big:
		snd("up_boom", 1.0, -2.0)
		Juice.pulse_shake(3.0)


## A new thing revealed: dark veil, rarity rays, the icon slams in big
## (whole pixel steps), its name and a line under it. Clears itself.
func reveal(icon_name: String, title: String, color: Color, sub := "", secs := 1.6, to: Control = null) -> void:
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0.02, 0.0)
	veil.size = get_viewport().get_visible_rect().size
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var c := _center() + Vector2(0, -16)
	var root := Node2D.new()
	root.position = c
	root.scale = Vector2(0.1, 0.1)
	add_child(root)
	var rays := Rays.new()
	rays.color = color
	rays.scale = Vector2(2.2, 2.2)
	root.add_child(rays)
	var ic := Sprite2D.new()
	ic.texture = IconBook.tex(icon_name)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.scale = Vector2(2, 2)
	ic.position = Vector2(0, -16)
	root.add_child(ic)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", UiKit.title_font())
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", color.lightened(0.3))
	t.add_theme_color_override("font_outline_color", UiKit.INK)
	t.add_theme_constant_override("outline_size", 4)
	t.size = Vector2(400, 20)
	t.position = c + Vector2(-200, 24)
	t.modulate.a = 0.0
	add_child(t)
	var s2 := Label.new()
	s2.text = sub
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s2.add_theme_font_override("font", UiKit.pixel_font())
	s2.add_theme_font_size_override("font_size", 8)
	s2.add_theme_color_override("font_color", Palette.TEXT)
	s2.add_theme_color_override("font_outline_color", UiKit.INK)
	s2.add_theme_constant_override("outline_size", 3)
	s2.size = Vector2(400, 14)
	s2.position = c + Vector2(-200, 44)
	s2.modulate.a = 0.0
	add_child(s2)
	snd("reward_pop")
	snd("up_boom", 1.0, -4.0)
	_sparks(c, color, 24, 90.0)
	var tw := create_tween()
	tw.tween_property(veil, "color:a", 0.68, 0.12)
	tw.parallel().tween_property(root, "scale", Vector2(1.75, 1.75), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "scale", Vector2(1.5, 1.5), 0.1)
	tw.parallel().tween_property(t, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(s2, "modulate:a", 1.0, 0.2)
	tw.tween_interval(secs)
	# Then it shrinks and is pulled to where it now lives (the slot that
	# got it, or the bag in the top-right corner).
	tw.tween_property(root, "scale", Vector2(0.6, 0.6), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(veil, "color:a", 0.0, 0.25)
	tw.parallel().tween_property(t, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(s2, "modulate:a", 0.0, 0.15)
	var bend := Vector2(randf_range(-40.0, 40.0), -60.0)
	tw.tween_method(func(k: float) -> void:
		var dest := vp_of(to) if to != null and is_instance_valid(to) and to.is_inside_tree() else Vector2(get_viewport().get_visible_rect().size.x - 30.0, 16.0)
		var m := (c + dest) * 0.5 + bend
		root.position = c.lerp(m, k).lerp(m.lerp(dest, k), k).round()
		root.scale = Vector2.ONE * lerpf(0.6, 0.14, k)
	, 0.0, 1.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_hit_target(to if to != null and is_instance_valid(to) and to.is_inside_tree() else null, color, "", false)
		for n in [veil, root, t, s2]:
			(n as Node).queue_free())


func deny(target: Control) -> void:
	snd("deny")
	if target == null or not target.is_inside_tree():
		return
	var x0 := target.position.x
	var tw := target.create_tween()
	for i in 4:
		tw.tween_property(target, "position:x", x0 + (4.0 if i % 2 == 0 else -4.0), 0.035)
	tw.tween_property(target, "position:x", x0, 0.035)


func _sparks(at: Vector2, color: Color, n: int, speed: float) -> void:
	for i in n:
		var s := ColorRect.new()
		s.size = Vector2(2, 2) if i % 3 else Vector2(3, 3)
		s.color = color.lightened(randf_range(0.0, 0.5))
		s.position = at
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		var a := TAU * float(i) / float(n) + randf_range(-0.3, 0.3)
		var v := Vector2(cos(a), sin(a)) * speed * randf_range(0.6, 1.1)
		var tw := create_tween()
		tw.tween_method(func(t: float) -> void:
			s.position = (at + v * t + Vector2(0, 40.0 * t * t)).round()
		, 0.0, 0.6, 0.45)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
		tw.tween_callback(s.queue_free)


## Rotating light rays behind a reward.
class Rays extends Node2D:
	var color := Color.WHITE
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# A dark pool first so the number reads over any busy menu.
		for k in 4:
			draw_circle(Vector2(0, 6), 40.0 - float(k) * 7.0, Color(0.02, 0.02, 0.05, 0.14))
		for i in 12:
			var a := _t * 1.4 + TAU * float(i) / 12.0
			var b := a + 0.13
			draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(cos(a), sin(a)) * 44.0 + Vector2(0, -8), Vector2(cos(b), sin(b)) * 44.0 + Vector2(0, -8)]), Color(color.r, color.g, color.b, 0.16 if i % 2 == 0 else 0.08))
		draw_circle(Vector2(0, -8), 20.0, Color(color.r, color.g, color.b, 0.18))


## An expanding pixel ring.
class Ring extends Node2D:
	var color := Color.WHITE
	var r := 4.0:
		set(v):
			r = v
			queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, color, 2.0)
		draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 24, Color(color.r, color.g, color.b, 0.4), 1.0)
