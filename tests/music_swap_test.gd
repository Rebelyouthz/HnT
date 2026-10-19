extends SceneTree

## Results -> camp asks for two tracks in one frame: the second must keep
## playing once the first swap's fade would have ended.


func _init() -> void:
	await process_frame
	var mixer := root.get_node("Mixer")
	mixer.play_music("res://assets/audio/music_street.wav")
	await create_timer(1.0).timeout
	mixer.play_music("res://assets/audio/music/music_menu.ogg")
	mixer.play_music("res://assets/audio/music/music_camp.ogg")
	await create_timer(1.2).timeout
	var on := false
	for p in mixer.get_children():
		var a := p as AudioStreamPlayer
		if a and a.playing and a.stream and a.stream.resource_path.ends_with("music_camp.ogg") and a.volume_db > -3.0:
			on = true
	print("MUSIC SWAP OK" if on else "MUSIC SWAP FAIL")
	quit(0 if on else 1)
