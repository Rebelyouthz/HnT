extends Node

var _sfx: AudioStreamPlayer
var _vo: AudioStreamPlayer
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _using_a := true
var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx = _make("sfx")
	_vo = _make("vo")
	_music_a = _make("music")
	_music_b = _make("music")
	for i in 6:
		var p := _make("sfx")
		_pool.append(p)
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


func play_sfx(path: String, pitch := 1.0) -> void:
	if not ResourceLoader.exists(path):
		return
	var p: AudioStreamPlayer = null
	for s in _pool:
		if not s.playing:
			p = s
			break
	if p == null:
		p = _sfx
	p.stream = load(path)
	p.pitch_scale = clampf(pitch * randf_range(0.94, 1.06), 0.8, 1.25)
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
	if not ResourceLoader.exists(path):
		return
	var incoming := _music_b if _using_a else _music_a
	var outgoing := _music_a if _using_a else _music_b
	if outgoing.playing and outgoing.stream and outgoing.stream.resource_path == path:
		return
	incoming.stream = load(path)
	if incoming.stream is AudioStreamWAV:
		(incoming.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	incoming.volume_db = -40.0
	incoming.play()
	var tw := create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(outgoing, "volume_db", -40.0, 0.7)
	tw.tween_property(incoming, "volume_db", 0.0, 0.7)
	tw.chain().tween_callback(outgoing.stop)
	_using_a = not _using_a


func stop_music() -> void:
	_music_a.stop()
	_music_b.stop()
