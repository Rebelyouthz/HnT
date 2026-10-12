extends SceneTree

## Suit showcase film: the Kid (top row) and Dad (bottom row) in every outfit
## - street clothes, BAT, SPIDER, SHAOLIN, NINJA - running a parkour
## routine in a wave across the roofs (run, jump, flips, rolls, kicks).
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1920x1080 --windowed --script res://tools/suit_show.gd -- /tmp/frames 240
## Saves every second tick (30 fps) as f_00000.png ...

const SUITS := [["", "STREET"], ["bat", "BAT"], ["spider", "SPIDER"], ["shaolin", "SHAOLIN"], ["ninja", "NINJA"]]
const ROUTINE := {
	"son": [["parkour_run", 1.4], ["jump", 0.8], ["backflip_kick", 0.9], ["parkour_run", 0.8], ["cartwheel_kick", 0.9], ["roll", 0.7], ["jump_roundhouse", 0.9], ["dive", 0.8]],
	"father": [["parkour_run", 1.4], ["jump", 0.8], ["jump_spin_kick", 0.9], ["parkour_run", 0.8], ["air_spin_kick", 0.9], ["roll", 0.7], ["jump_high_kick", 0.9], ["slide", 0.7]],
}
const AIR := ["jump", "backflip_kick", "jump_roundhouse", "jump_spin_kick", "air_spin_kick", "jump_high_kick", "cartwheel_kick"]

var _out := "/tmp/claude-0/show"
var _n := 240
var _frame := 0
var _shot := 0
var _actors: Array = []
var _t := 0.0


class Who extends Node2D:
	var velocity := Vector2(300, 0)
	var gliding := false
	var hop_v := 0.0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	if a.size() > 1:
		_n = int(a[1])
	DirAccess.make_dir_recursive_absolute(_out)


func _process(delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_build()
		return false
	if _frame < 6:
		return false
	_t += delta
	_animate()
	if _frame % 2 == 0:
		root.get_viewport().get_texture().get_image().save_png("%s/f_%05d.png" % [_out, _shot])
		_shot += 1
		if _shot >= _n:
			quit(0)
			return true
	return false


func _build() -> void:
	var fp := root.get_node("FamilyProfile")
	var stage := Node2D.new()
	root.add_child(stage)
	# Night roofs behind them, darkened so the suits pop.
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/backdrops/roofs_strip_0.png")
	bg.centered = false
	var k := 360.0 / float(bg.texture.get_height())
	bg.scale = Vector2(k, k)
	bg.position = Vector2(-120, 0)
	stage.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.45)
	shade.size = Vector2(640, 360)
	stage.add_child(shade)
	# Roof edges they run along.
	for y in [196.0, 334.0]:
		var ledge := ColorRect.new()
		ledge.color = Color(0.09, 0.08, 0.12)
		ledge.position = Vector2(0, y)
		ledge.size = Vector2(640, 26)
		stage.add_child(ledge)
		var lip := ColorRect.new()
		lip.color = Color(0.32, 0.26, 0.3)
		lip.position = Vector2(0, y)
		lip.size = Vector2(640, 3)
		stage.add_child(lip)
	var sb := load("res://src/sprites/sprite_book.gd")
	var suits := load("res://src/app/suits.gd")
	var cape_s := load("res://src/actors/cape_fx.gd")
	var rows := [["son", 196.0], ["father", 334.0]]
	for r in rows:
		var role := str(r[0])
		for i in SUITS.size():
			var code := int(suits.call("code_of", str(SUITS[i][0])))
			var holder := Who.new()
			holder.position = Vector2(68.0 + float(i) * 120.0, float(r[1]))
			stage.add_child(holder)
			var anim: AnimatedSprite2D = sb.call("make_anim", role)
			sb.call("grow", anim, float(sb.get("FIGHTER_SCALE")) * (float(sb.get("FATHER_K")) if role == "father" else 1.0) * 0.8)
			anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			holder.add_child(anim)
			if code > 0:
				_dress(anim, code)
				if str(SUITS[i][0]) == "bat":
					var cape: Node2D = cape_s.new()
					cape.set("anim", anim)
					cape.set("who", holder)
					cape.set("draw_ears", true)
					holder.add_child(cape)
					holder.move_child(cape, 0)
			# A soft back-glow so dark suits (ninja, bat) read on the night roofs.
			var glow := Sprite2D.new()
			var gimg := Image.create(64, 96, false, Image.FORMAT_RGBA8)
			for gy in 96:
				for gx in 64:
					var dd := Vector2((gx - 32) / 32.0, (gy - 48) / 48.0).length()
					gimg.set_pixel(gx, gy, Color(0.55, 0.6, 0.9, clampf(0.32 * (1.0 - dd), 0.0, 1.0)))
			glow.texture = ImageTexture.create_from_image(gimg)
			glow.position = Vector2(0, -34)
			holder.add_child(glow)
			var shadow := Polygon2D.new()
			var pts := PackedVector2Array()
			for a in 16:
				pts.append(Vector2(cos(TAU * a / 16.0) * 16.0, sin(TAU * a / 16.0) * 4.0))
			shadow.polygon = pts
			shadow.color = Color(0, 0, 0, 0.45)
			holder.add_child(shadow)
			holder.move_child(glow, 0)
			holder.move_child(shadow, 0)
			_actors.append({"node": holder, "anim": anim, "role": role, "delay": float(i) * 0.18 + (0.09 if role == "father" else 0.0), "base_y": anim.position.y})
	# Captions.
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var ui := Control.new()
	ui.size = Vector2(640, 360)
	layer.add_child(ui)
	var title := Label.new()
	title.text = "FATHER & SON  ·  SUITS"
	title.position = Vector2(0, 10)
	title.size = Vector2(640, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 5)
	var tf: Font = load("res://assets/fonts/PixelifySans.ttf")
	if tf:
		title.add_theme_font_override("font", tf)
	ui.add_child(title)
	for i in SUITS.size():
		var l := Label.new()
		l.text = str(SUITS[i][1])
		l.position = Vector2(68.0 + float(i) * 120.0 - 50.0, 344.0)
		l.size = Vector2(100, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_font_override("font", tf)
		l.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.add_theme_constant_override("outline_size", 4)
		ui.add_child(l)
	fp.set("data", fp.get("data"))


func _dress(anim: AnimatedSprite2D, code: int) -> void:
	var bs := load("res://src/juice/blood.gd")
	if bs:
		bs.call("wound", anim, 0.0, 0.0, 1.0)
	var m := anim.material as ShaderMaterial
	if m:
		m.set_shader_parameter("suit_head", code)
		m.set_shader_parameter("suit_body", code)
		m.set_shader_parameter("suit_legs", code)


func _animate() -> void:
	for a: Dictionary in _actors:
		var anim: AnimatedSprite2D = a["anim"]
		var holder: Node2D = a["node"]
		var steps: Array = ROUTINE[str(a["role"])]
		var total := 0.0
		for s in steps:
			total += float(s[1])
		var t := fmod(maxf(0.0, _t - float(a["delay"])), total)
		var clip := "parkour_run"
		var k := 0.0
		var acc := 0.0
		for s in steps:
			if t < acc + float(s[1]):
				clip = str(s[0])
				k = (t - acc) / float(s[1])
				break
			acc += float(s[1])
		if not anim.sprite_frames.has_animation(clip):
			clip = "parkour_run"
		if anim.animation != clip:
			anim.play(clip)
		# Scrub one-shots across their slot so every move finishes in time.
		if clip != "parkour_run":
			anim.pause()
			var n := anim.sprite_frames.get_frame_count(clip)
			anim.frame = clampi(int(k * float(n)), 0, n - 1)
		# Airborne moves follow a real arc (up fast, hang, drop faster).
		var lift := 0.0
		if clip in AIR:
			lift = -4.0 * 34.0 * k * (1.0 - k) * (1.0 if k < 0.5 else 1.0 + 0.15 * (k - 0.5))
		anim.position.y = float(a["base_y"]) + lift
		(holder as Who).hop_v = -400.0 if k < 0.5 and clip in AIR else (300.0 if clip in AIR else 0.0)
		(holder as Who).velocity = Vector2(320.0 if clip in ["parkour_run", "roll", "slide", "dive"] else 120.0, 0)
		var sh: Polygon2D = holder.get_child(0) as Polygon2D
		if sh:
			sh.scale = Vector2.ONE * (1.0 + lift / 60.0)
