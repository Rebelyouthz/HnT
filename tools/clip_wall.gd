extends SceneTree

## Clip wall: each enemy's idle, punch peak, hurt peak and last death frame
## side by side as the game draws them (SpriteBook.make_anim), to check the
## anchor and size of new clips.
##   xvfb-run ... --script res://tools/clip_wall.gd -- <out.png> who,who,...

var _n := 0
var _out := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0]
	var bg := ColorRect.new()
	bg.color = Color(0.22, 0.22, 0.26)
	bg.size = Vector2(640, 360)
	root.add_child(bg)
	var whos := str(a[1]).split(",")
	var clips := [["idle", 0], ["punch_high", -2], ["punch_mid", -2], ["hurt", -3], ["death", -1]]
	for r in whos.size():
		for c in clips.size():
			var an := SpriteBook.make_anim(whos[r])
			if an == null or not an.sprite_frames.has_animation(str(clips[c][0])):
				continue
			root.add_child(an)
			an.position = Vector2(60 + c * 120, 66 + r * 70)
			var clip := str(clips[c][0])
			an.animation = clip
			var n := an.sprite_frames.get_frame_count(clip)
			var at := int(clips[c][1])
			if clip.begins_with("punch"):
				at = int(SpriteBook.clip_info(whos[r], clip).get("hit", n / 2))
			elif at < 0:
				at = n + at if clip == "death" else int(n * 0.35)
			an.frame = clampi(at, 0, n - 1)
			an.pause()
			var floor := ColorRect.new()
			floor.color = Color(1, 1, 1, 0.3)
			floor.size = Vector2(100, 1)
			floor.position = an.position + Vector2(-50, 0)
			root.add_child(floor)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 10:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
