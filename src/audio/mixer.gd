extends Node

var _sfx: AudioStreamPlayer
var _vo: AudioStreamPlayer
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _using_a := true
var _pool: Array[AudioStreamPlayer] = []
var _grunts: Array[AudioStreamPlayer] = []
var _grunt_i := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx = _make("sfx")
	_vo = _make("vo")
	_music_a = _make("music")
	_music_b = _make("music")
	for i in 6:
		var p := _make("sfx")
		_pool.append(p)
	# Fight breath and shouts: own voices on the vo bus, so a jab's exhale
	# never cuts a spoken line and never ducks the music.
	for i in 2:
		_grunts.append(_make("vo"))
	apply_volumes()


func _make(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func apply_volumes() -> void:
	_set_bus("Master", float(FamilyProfile.data.get("vol_master", 1.0)))
	_set_bus("sfx", float(FamilyProfile.data.get("vol_sfx", 1.0)))
	_set_bus("vo", float(FamilyProfile.data.get("vol_vo", 1.0)))
	_set_bus("music", float(FamilyProfile.data.get("vol_music", 0.72)))


func _set_bus(name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func play_sfx(path: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not ResourceLoader.exists(path):
		return
	var p: AudioStreamPlayer = null
	for s in _pool:
		if not s.playing:
			p = s
			break
	if p == null:
		p = _sfx
	var quiet := vol_db
	if quiet == 0.0:
		if path.ends_with("ui_click.wav"):
			quiet = -18.0
		elif path.ends_with("foot.wav"):
			quiet = -16.0
	p.stream = load(path)
	p.pitch_scale = clampf(pitch * randf_range(0.94, 1.06), 0.8, 1.25)
	p.volume_db = quiet
	p.play()


## A fighter's breath / grunt / kiai: round-robin over two players so a
## fast jab chain overlaps naturally instead of chopping itself off.
func play_grunt(path: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not ResourceLoader.exists(path):
		return
	if _vo.playing and vol_db < -3.0:
		return
	var p := _grunts[_grunt_i]
	_grunt_i = (_grunt_i + 1) % _grunts.size()
	p.stream = load(path)
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func play_vo(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	_vo.stream = load(path)
	_vo.play()
	_duck(true)
	if not _vo.finished.is_connected(_on_vo_done):
		_vo.finished.connect(_on_vo_done)


func _on_vo_done() -> void:
	_duck(false)


func _duck(on: bool) -> void:
	var idx := AudioServer.get_bus_index("music")
	if idx < 0:
		return
	var target := -12.0 if on else linear_to_db(maxf(float(FamilyProfile.data.get("vol_music", 0.72)), 0.0001))
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v: float) -> void:
		AudioServer.set_bus_volume_db(idx, v)
	, AudioServer.get_bus_volume_db(idx), target, 0.18)


func play_music(path: String) -> void:
	# Composed tracks (tools/music_gen.py) sit next to the old synth loops as
	# .ogg with the same name and win when present.
	# Tracks in assets/audio/music/ (tools/ace_music.py) win over both.
	var named := "res://assets/audio/music/%s.ogg" % path.get_file().get_basename()
	var ogg := path.get_basename() + ".ogg"
	if ResourceLoader.exists(named):
		path = named
	elif ResourceLoader.exists(ogg):
		path = ogg
	if not ResourceLoader.exists(path):
		return
	var incoming := _music_b if _using_a else _music_a
	var outgoing := _music_a if _using_a else _music_b
	if outgoing.playing and outgoing.stream and outgoing.stream.resource_path == path:
		return
	_music_path = path
	incoming.stream = load(path)
	if incoming.stream is AudioStreamWAV:
		(incoming.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif incoming.stream is AudioStreamOggVorbis:
		(incoming.stream as AudioStreamOggVorbis).loop = true
	incoming.volume_db = -40.0
	incoming.play()
	var tw := create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(outgoing, "volume_db", -40.0, 0.7)
	tw.tween_property(incoming, "volume_db", 0.0, 0.7)
	tw.chain().tween_callback(outgoing.stop)
	_using_a = not _using_a


var _music_path := ""
var _music_saved := ""


## Swap to a track for a while (a shop) and come back to what played.
func push_music(path: String) -> void:
	_music_saved = _music_path
	play_music(path)


func pop_music() -> void:
	if _music_saved != "":
		play_music(_music_saved)
		_music_saved = ""


func stop_music() -> void:
	_music_a.stop()
	_music_b.stop()


func set_tension(on: bool) -> void:
	if on:
		if ResourceLoader.exists("res://assets/audio/music_tension.wav"):
			play_music("res://assets/audio/music_tension.wav")
		elif ResourceLoader.exists("res://assets/audio/music_chase.wav"):
			play_music("res://assets/audio/music_chase.wav")
