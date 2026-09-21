extends Node

## The Son Hosts. The Father Joins. LAN, then UPnP/direct (~3s), then TCP relay.

signal status_changed
signal hosted
signal connected
signal failed(reason: String)
signal cancelled

const GAME_PORT := 24567
const RELAY_PORT := 8789
const ROOM_FILE := "user://open_room.json"
const ALPHA := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
const ACTIONS := [
	"jump", "light", "heavy", "special", "shoot", "block", "throw", "dash", "snap", "pause"
]

var room_code := ""
var lan_ip := ""
var wan_ip := ""
var backup_ip := ""
var path_name := ""
var status_line := ""
var upnp_ok := false
var role := "" ## host | client | ""
var stick := Vector2.ZERO
var bits := 0
var just_bits := 0
var prev_bits := 0
var _peer: ENetMultiplayerPeer
var _tcp: StreamPeerTCP
var _tcp_buf := PackedByteArray()
var _http: HTTPRequest
var _son: Fighter
var _dad: Fighter
var _snap_acc := 0.0
var _input_acc := 0.0
var _busy := false
var _rooms_booted := false
var _handshake_done := false
var _relay_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = 2.5
	add_child(_http)
	multiplayer.peer_connected.connect(_on_peer_in)
	multiplayer.peer_disconnected.connect(_on_peer_out)
	multiplayer.connected_to_server.connect(_on_enet_ok)
	multiplayer.connection_failed.connect(_on_enet_fail)
	multiplayer.server_disconnected.connect(_on_enet_drop)


func active() -> bool:
	return role != ""


func is_host() -> bool:
	return role == "host"


func is_client() -> bool:
	return role == "client"


func rooms_url() -> String:
	return str(FamilyProfile.data.get("rooms_url", "http://127.0.0.1:8787")).rstrip("/")


func _set_status(s: String) -> void:
	status_line = s
	status_changed.emit()


func bind_run(son: Fighter, dad: Fighter) -> void:
	_son = son
	_dad = dad
	if not active() or dad == null or son == null:
		return
	if is_host():
		dad.net_driven = true
		dad.prefix = &"p2_"
	else:
		son.puppeted = true
		dad.prefix = &"p1_"
		dad.net_report = true


func shutdown() -> void:
	role = ""
	path_name = ""
	room_code = ""
	_handshake_done = false
	_relay_started = false
	_son = null
	_dad = null
	App.remote_coop = false
	if _peer:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if _tcp:
		_tcp.disconnect_from_host()
		_tcp = null
	_tcp_buf.clear()
	if FileAccess.file_exists(ROOM_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOM_FILE))


func mint_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := ""
	for i in 6:
		s += ALPHA[rng.randi_range(0, ALPHA.length() - 1)]
	return s


func lan_ips() -> PackedStringArray:
	var out: PackedStringArray = []
	for ip in IP.get_local_addresses():
		if ":" in ip or ip.begins_with("127."):
			continue
		out.append(ip)
	return out


func host() -> void:
	if _busy:
		return
	shutdown()
	role = "host"
	room_code = mint_code()
	var ips := lan_ips()
	lan_ip = ips[0] if not ips.is_empty() else "127.0.0.1"
	backup_ip = "%s:%d" % [lan_ip, GAME_PORT]
	wan_ip = ""
	upnp_ok = false
	path_name = ""
	_set_status(Copy.WAITING)
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(GAME_PORT, 1)
	if err != OK:
		_fail("Could not bind UDP %d" % GAME_PORT)
		return
	multiplayer.multiplayer_peer = _peer
	_write_room_file()
	_busy = true
	ensure_rooms()
	_register_room()
	WorkerThreadPool.add_task(Callable(self, "_upnp_task"))
	hosted.emit()


func _upnp_task() -> void:
	var u := UPNP.new()
	var d := u.discover(2000, 2, "InternetGatewayDevice")
	var wan := ""
	var ok := false
	if d == 0:
		wan = u.query_external_address()
		var mapped := u.add_port_mapping(GAME_PORT, GAME_PORT, "HnT", "UDP", 0)
		ok = mapped == 0
	call_deferred("_upnp_done", wan, ok)


func _upnp_done(wan: String, ok: bool) -> void:
	wan_ip = wan
	upnp_ok = ok
	if wan != "":
		backup_ip = "%s:%d" % [wan if wan != "" else lan_ip, GAME_PORT]
	_write_room_file()
	_register_room()
	status_changed.emit()


func join(code: String, ip_backup: String) -> void:
	if _busy:
		return
	shutdown()
	role = "client"
	room_code = code.strip_edges().to_upper().replace(" ", "")
	_set_status(Copy.CONNECTING)
	_busy = true
	_join_flow(ip_backup.strip_edges())


func _join_flow(ip_backup: String) -> void:
	var info := _read_room_file()
	if room_code != "" and (info.is_empty() or str(info.get("code", "")) != room_code):
		info = await _http_lookup(room_code)
	var targets: Array[String] = []
	if not info.is_empty():
		for ip in info.get("lan", []):
			targets.append(str(ip))
		if str(info.get("wan", "")) != "":
			targets.append(str(info.get("wan")))
	if ip_backup != "":
		if ":" in ip_backup:
			targets.append(ip_backup.get_slice(":", 0))
		else:
			targets.append(ip_backup)
	var seen := {}
	for t in targets:
		if t == "" or seen.has(t):
			continue
		seen[t] = true
		_set_status("%s %s" % [Copy.CONNECTING, t])
		if await _try_enet(t, 2.4):
			path_name = Copy.PATH_DIRECT
			_busy = false
			App.remote_coop = true
			App.density_coop = true
			connected.emit()
			status_changed.emit()
			return
	var relay := "127.0.0.1"
	if not info.is_empty() and str(info.get("relay", "")) != "":
		relay = str(info.get("relay"))
	_set_status("%s %s" % [Copy.CONNECTING, Copy.PATH_RELAY])
	if await _try_relay(relay):
		path_name = Copy.PATH_RELAY
		_pipe_send({"t": "hello"})
		_busy = false
		App.remote_coop = true
		App.density_coop = true
		connected.emit()
		status_changed.emit()
		return
	_fail("Could not reach the host. Check the code, or paste the IP backup.")


func _try_enet(ip: String, wait_s: float) -> bool:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(ip, GAME_PORT)
	if err != OK:
		_peer = null
		return false
	multiplayer.multiplayer_peer = _peer
	var left := wait_s
	while left > 0.0:
		await get_tree().create_timer(0.1).timeout
		left -= 0.1
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			break
		if path_name == Copy.PATH_DIRECT:
			return true
		if _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			return true
		if _peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			break
	if _peer:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	return false


func _on_enet_ok() -> void:
	if is_client():
		path_name = Copy.PATH_DIRECT


func _on_enet_fail() -> void:
	pass


func _on_enet_drop() -> void:
	if active():
		_fail("Host left. The feelings did not.")


func _on_peer_in(id: int) -> void:
	if not is_host():
		return
	if id == 1:
		return
	path_name = Copy.PATH_DIRECT if path_name == "" else path_name
	App.remote_coop = true
	App.density_coop = true
	_busy = false
	connected.emit()
	_set_status("FATHER CONNECTED")
	broadcast_begin("dock_street")


func _on_peer_out(_id: int) -> void:
	if is_host() and active():
		Juice.toast("challenge", "FATHER DROPPED", "The other chair went dark.")


func broadcast_begin(map_id: String, extra: Dictionary = {}) -> void:
	if extra.is_empty():
		extra = App.begin_extra()
	if is_host() and _peer:
		net_begin.rpc(map_id, extra)
	if is_host() and _tcp:
		_pipe_send({"t": "begin", "map": map_id, "extra": extra})
	if is_host():
		App.apply_begin_extra(extra)
		App.enter_map(map_id)


@rpc("authority", "call_remote", "reliable")
func net_begin(map_id: String, extra: Dictionary = {}) -> void:
	App.remote_coop = true
	App.density_coop = true
	App.apply_begin_extra(extra)
	App.enter_map(map_id)


@rpc("any_peer", "unreliable")
func net_input(p_bits: int, sx: float, sy: float) -> void:
	if not is_host():
		return
	prev_bits = bits
	bits = p_bits
	just_bits = p_bits & ~prev_bits
	stick = Vector2(sx, sy)


@rpc("authority", "unreliable")
func net_snap(payload: Dictionary) -> void:
	_apply_snap(payload)


func held(action: String) -> bool:
	var i := ACTIONS.find(action)
	if i < 0:
		return false
	return (bits & (1 << i)) != 0


func tapped(action: String) -> bool:
	var i := ACTIONS.find(action)
	if i < 0:
		return false
	return (just_bits & (1 << i)) != 0


func released(action: String) -> bool:
	var i := ACTIONS.find(action)
	if i < 0:
		return false
	return (prev_bits & (1 << i)) != 0 and (bits & (1 << i)) == 0


func _process(_delta: float) -> void:
	just_bits = 0


func _physics_process(delta: float) -> void:
	if is_client() and _dad and is_instance_valid(_dad) and _dad.net_report:
		_input_acc += delta
		if _input_acc >= 1.0 / 60.0:
			_input_acc = 0.0
			_send_local_input()
	if is_host() and App.remote_coop:
		_snap_acc += delta
		if _snap_acc >= 0.05:
			_snap_acc = 0.0
			_send_snap()
	if _tcp:
		_poll_tcp()


func _send_local_input() -> void:
	var b := 0
	for i in ACTIONS.size():
		if Input.is_action_pressed(StringName("p1_" + ACTIONS[i])):
			b |= 1 << i
	var ax := PadRouter.stick(&"p1_")
	if _peer:
		net_input.rpc_id(1, b, ax.x, ax.y)
	elif _tcp:
		_pipe_send({"t": "in", "b": b, "x": ax.x, "y": ax.y})


func _send_snap() -> void:
	var payload := {"t": "snap", "bodies": []}
	for f in [_son, _dad]:
		if f == null or not is_instance_valid(f):
			continue
		(payload["bodies"] as Array).append({
			"role": f.role,
			"x": f.global_position.x,
			"y": f.global_position.y,
			"hop": f.hop,
			"hp": f.hp,
			"steam": f.steam,
			"facing": f.facing,
			"plane": f.plane,
			"downed": f.downed,
			"ammo": f.ammo
		})
	if _peer:
		net_snap.rpc(payload)
	elif _tcp:
		_pipe_send(payload)


func _apply_snap(payload: Dictionary) -> void:
	for row in payload.get("bodies", []):
		var f := _son if str(row.get("role")) == "son" else _dad
		if f == null or not is_instance_valid(f):
			continue
		var pos := Vector2(float(row.get("x", f.global_position.x)), float(row.get("y", f.global_position.y)))
		f.snap_pos = pos
		f.snap_hop = float(row.get("hop", 0.0))
		f.hp = int(row.get("hp", f.hp))
		f.steam = float(row.get("steam", f.steam))
		f.facing = int(row.get("facing", f.facing))
		f.plane = str(row.get("plane", f.plane))
		f.downed = bool(row.get("downed", false))
		f.ammo = int(row.get("ammo", f.ammo))
		if f.puppeted or f.global_position.distance_to(pos) > 28.0:
			f.global_position = f.global_position.lerp(pos, 0.45)


func ensure_rooms() -> void:
	if _rooms_booted:
		return
	_rooms_booted = true
	var script := ProjectSettings.globalize_path("res://tools/hnt_rooms.py")
	if not FileAccess.file_exists(script):
		return
	OS.create_process("python3", [script])


func _write_room_file() -> void:
	var f := FileAccess.open(ROOM_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"code": room_code,
		"lan": Array(lan_ips()),
		"wan": wan_ip,
		"port": GAME_PORT,
		"relay": "127.0.0.1",
		"relay_port": RELAY_PORT,
		"upnp": upnp_ok
	}))


func _read_room_file() -> Dictionary:
	if not FileAccess.file_exists(ROOM_FILE):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOM_FILE))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _register_room() -> void:
	var body := JSON.stringify({
		"code": room_code,
		"lan": Array(lan_ips()),
		"wan": wan_ip,
		"port": GAME_PORT,
		"relay": "127.0.0.1",
		"relay_port": RELAY_PORT,
		"upnp": upnp_ok
	})
	_http.request(rooms_url() + "/rooms", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func _http_lookup(code: String) -> Dictionary:
	var url := rooms_url() + "/rooms/" + code
	var err := _http.request(url)
	if err != OK:
		return {}
	var got: Array = await _http.request_completed
	if got.size() < 4:
		return {}
	var rc := int(got[1])
	if rc != 200:
		return {}
	var parsed: Variant = JSON.parse_string((got[3] as PackedByteArray).get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _try_relay(host_ip: String) -> bool:
	_tcp = StreamPeerTCP.new()
	var err := _tcp.connect_to_host(host_ip, RELAY_PORT)
	if err != OK:
		_tcp = null
		return false
	var left := 4.0
	while left > 0.0:
		_tcp.poll()
		if _tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			_tcp.put_data(("HNT1 JOIN %s\n" % room_code).to_utf8_buffer())
			var wait := 2.0
			while wait > 0.0:
				_tcp.poll()
				if _tcp.get_available_bytes() > 0:
					var rec := _tcp.get_utf8_string(_tcp.get_available_bytes())
					if rec.contains("OK"):
						_handshake_done = true
						return true
				await get_tree().create_timer(0.1).timeout
				wait -= 0.1
			break
		await get_tree().create_timer(0.1).timeout
		left -= 0.1
	if _tcp:
		_tcp.disconnect_from_host()
		_tcp = null
	return false


func host_open_relay() -> void:
	# Host also dials out so CGNAT still reaches rooms.
	var t := StreamPeerTCP.new()
	var err := t.connect_to_host("127.0.0.1", RELAY_PORT)
	if err != OK:
		return
	_tcp = t
	var left := 2.0
	while left > 0.0:
		_tcp.poll()
		if _tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			_tcp.put_data(("HNT1 HOST %s\n" % room_code).to_utf8_buffer())
			var wait := 2.0
			while wait > 0.0:
				_tcp.poll()
				if _tcp.get_available_bytes() > 0:
					var rec := _tcp.get_utf8_string(_tcp.get_available_bytes())
					if rec.contains("OK"):
						_handshake_done = true
						return
				await get_tree().create_timer(0.1).timeout
				wait -= 0.1
			return
		await get_tree().create_timer(0.1).timeout
		left -= 0.1


func _pipe_send(d: Dictionary) -> void:
	if _tcp == null:
		return
	_tcp.poll()
	if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	var raw := JSON.stringify(d).to_utf8_buffer()
	var hdr := PackedByteArray()
	hdr.resize(4)
	hdr.encode_u32(0, raw.size())
	_tcp.put_data(hdr)
	_tcp.put_data(raw)


func _poll_tcp() -> void:
	_tcp.poll()
	if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	var n := _tcp.get_available_bytes()
	if n <= 0:
		return
	var chunk: Array = _tcp.get_data(n)
	if int(chunk[0]) != OK:
		return
	_tcp_buf.append_array(chunk[1])
	if not _handshake_done:
		var text := _tcp_buf.get_string_from_utf8()
		var nl := text.find("\n")
		if nl < 0:
			return
		_handshake_done = true
		_tcp_buf = _tcp_buf.slice(nl + 1)
	while _tcp_buf.size() >= 4:
		var sz := _tcp_buf.decode_u32(0)
		if sz < 0 or sz > 100000:
			_tcp_buf.clear()
			break
		if _tcp_buf.size() < 4 + sz:
			break
		var body := _tcp_buf.slice(4, 4 + sz)
		_tcp_buf = _tcp_buf.slice(4 + sz)
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = parsed
		match str(d.get("t", "")):
			"hello":
				_on_relay_peer()
			"in":
				net_input(int(d.get("b", 0)), float(d.get("x", 0.0)), float(d.get("y", 0.0)))
			"snap":
				_apply_snap(d)
			"begin":
				var extra: Variant = d.get("extra", {})
				if typeof(extra) != TYPE_DICTIONARY:
					extra = {}
				net_begin(str(d.get("map", "dock_street")), extra)


func _on_relay_peer() -> void:
	if not is_host() or _relay_started:
		return
	_relay_started = true
	path_name = Copy.PATH_RELAY
	App.remote_coop = true
	App.density_coop = true
	_busy = false
	connected.emit()
	_set_status("FATHER CONNECTED")
	broadcast_begin("dock_street")


func _fail(reason: String) -> void:
	_busy = false
	_set_status(reason)
	failed.emit(reason)
	shutdown()
