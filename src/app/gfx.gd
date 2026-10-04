class_name Gfx
extends RefCounted

## Video settings, stored in the family profile under "gfx" and applied at
## boot and whenever the options change: window mode, resolution, vsync,
## anti-aliasing, bloom, menu blur, brightness, screen shake, CRT scanlines
## and a quality preset that the world reads (reflections, rain, blood).

const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const QUALITY := ["LOW", "MEDIUM", "HIGH", "ULTRA"]
const MODES := ["WINDOWED", "BORDERLESS", "FULLSCREEN"]
const AA := ["OFF", "FXAA", "MSAA 2X", "MSAA 4X"]

const DEFAULTS := {
	"mode": 1, "res": 2, "vsync": true, "aa": 1, "bloom": 0.45, "blur": 0.6,
	"bright": 0.5, "shake": 0.8, "crt": 0.0, "quality": 2, "fps_cap": 60,
}

static var _env: WorldEnvironment
static var _crt: CanvasLayer


static func get_v(key: String) -> Variant:
	var g: Variant = FamilyProfile.data.get("gfx", {})
	if g is Dictionary and (g as Dictionary).has(key):
		return (g as Dictionary)[key]
	return DEFAULTS.get(key)


static func set_v(key: String, v: Variant) -> void:
	var g: Variant = FamilyProfile.data.get("gfx", {})
	if not (g is Dictionary):
		g = {}
	(g as Dictionary)[key] = v
	FamilyProfile.data["gfx"] = g
	FamilyProfile.save()
	apply(Engine.get_main_loop() as SceneTree)


static func quality() -> int:
	return int(get_v("quality"))


static func reflections() -> bool:
	return quality() >= 1


static func apply(tree: SceneTree) -> void:
	if tree == null:
		return
	var root := tree.root
	var scripted := "--script" in OS.get_cmdline_args() or "-s" in OS.get_cmdline_args()
	if not OS.has_feature("web") and not scripted:
		match int(get_v("mode")):
			0:
				if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				DisplayServer.window_set_size(RESOLUTIONS[clampi(int(get_v("res")), 0, RESOLUTIONS.size() - 1)])
			1:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_v("vsync")) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(get_v("fps_cap"))
	var aa := int(get_v("aa"))
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if aa == 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	root.msaa_2d = [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clampi(aa, 0, 3)]
	_apply_env(root)
	_apply_crt(root)


## Bloom and brightness through a canvas environment on the root viewport.
static func _apply_env(root: Window) -> void:
	if _env == null or not is_instance_valid(_env):
		_env = WorldEnvironment.new()
		_env.name = "GfxEnv"
		var e := Environment.new()
		e.background_mode = Environment.BG_CANVAS
		_env.environment = e
		root.call_deferred("add_child", _env)
	var env := _env.environment
	var bloom := float(get_v("bloom"))
	env.glow_enabled = bloom > 0.01 and quality() >= 1
	env.glow_intensity = 0.4 + bloom * 1.2
	env.glow_strength = 0.9 + bloom * 0.4
	env.glow_bloom = bloom * 0.12
	env.glow_hdr_threshold = 0.95 - bloom * 0.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.5 * bloom)
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.8 + float(get_v("bright")) * 0.4
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.05


## Optional scanlines + vignette, very light, for the CRT crowd.
static func _apply_crt(root: Window) -> void:
	var amt := float(get_v("crt"))
	if amt <= 0.01:
		if _crt and is_instance_valid(_crt):
			_crt.visible = false
		return
	if _crt == null or not is_instance_valid(_crt):
		_crt = CanvasLayer.new()
		_crt.layer = 120
		_crt.name = "GfxCrt"
		var r := ColorRect.new()
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/shaders/crt.gdshader")
		r.material = m
		_crt.add_child(r)
		root.call_deferred("add_child", _crt)
	_crt.visible = true
	((_crt.get_child(0) as ColorRect).material as ShaderMaterial).set_shader_parameter("amount", amt)


## Menus: blur what is behind them by the player's taste (0 = none).
static func blur_backdrop(parent: Control) -> ColorRect:
	var amt := float(get_v("blur"))
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.size = Vector2(1280, 720)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://src/shaders/menu_blur.gdshader")
	m.set_shader_parameter("lod", amt * 3.5)
	r.material = m
	parent.add_child(r)
	return r
