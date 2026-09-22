extends Node

## In-process room board + TCP splice relay. Same ports as tools/hnt_rooms.py.
## Host/Join from the exported exe does not need Python.

const HTTP_PORT := 8787
const RELAY_PORT := 8789
const TTL := 30.0 * 60.0
const MAX_BUF := 65536

var _http: TCPServer
var _relay: TCPServer
var _rooms: Dictionary = {}
var _http_peers: Array[Dictionary] = []
var _relay_peers: Array[Dictionary] = []
var _waiting: Dictionary = {}
var _pairs: Array[Dictionary] = []
var _booted := false


func boot() -> bool:
	if _booted:
		return true
	var http := TCPServer.new()
	var err := http.listen(HTTP_PORT, "0.0.0.0")
	if err != OK:
		return false
	var relay := TCPServer.new()
	err = relay.listen(RELAY_PORT, "0.0.0.0")
	if err != OK:
		http.stop()
		return false
	_http = http
	_relay = relay
	_booted = true
	set_process(true)
	return true


func _ready() -> void:
	set_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if not _booted:
		return
	_prune()
	_accept_http()
	_pump_http()
	_accept_relay()
	_pump_relay_handshake()
	_pump_pairs()


func _prune() -> void:
	var now := Time.get_unix_time_from_system()
	var dead: Array[String] = []
	for code in _rooms.keys():
		var row: Variant = _rooms[code]
		if typeof(row) != TYPE_DICTIONARY:
			dead.append(str(code))
			continue
		if now - float((row as Dictionary).get("t", now)) > TTL:
			dead.append(str(code))
	for code in dead:
		_rooms.erase(code)


func _accept_http() -> void:
	while _http.is_connection_available():
		var peer := _http.take_connection()
		if peer:
			_http_peers.append({"peer": peer, "buf": PackedByteArray()})


func _accept_relay() -> void:
	while _relay.is_connection_available():
		var peer := _relay.take_connection()
		if peer:
			_relay_peers.append({"peer": peer, "buf": PackedByteArray()})


func _read_into(peer: StreamPeerTCP, buf: PackedByteArray) -> PackedByteArray:
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return buf
	var n := peer.get_available_bytes()
	if n <= 0:
		return buf
	var rec: Array = peer.get_data(n)
	if int(rec[0]) != OK:
		return buf
	buf.append_array(rec[1])
	if buf.size() > MAX_BUF:
		buf = buf.slice(buf.size() - MAX_BUF)
	return buf


func _pump_http() -> void:
	var keep: Array[Dictionary] = []
	for row in _http_peers:
		var peer: StreamPeerTCP = row["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue
		row["buf"] = _read_into(peer, row["buf"])
		if _try_http(peer, row["buf"]):
			peer.disconnect_from_host()
		else:
			keep.append(row)
	_http_peers = keep


func _header_break(text: String) -> int:
	var cr := text.find("\r\n\r\n")
	if cr >= 0:
		return cr
	return text.find("\n\n")


func _try_http(peer: StreamPeerTCP, buf: PackedByteArray) -> bool:
	var text := buf.get_string_from_utf8()
	var br := _header_break(text)
	if br < 0:
		return false
	var sep_len := 4 if text.find("\r\n\r\n") == br else 2
	var header := text.substr(0, br)
	var lines := header.replace("\r\n", "\n").split("\n")
	if lines.is_empty():
		_http_reply(peer, 400, {"error": "no"})
		return true
	var start := lines[0].split(" ")
	if start.size() < 2:
		_http_reply(peer, 400, {"error": "no"})
		return true
	var method := start[0]
	var path := start[1].split("?")[0]
	var length := 0
	for line in lines:
		var low := line.to_lower()
		if low.begins_with("content-length:"):
			length = int(line.get_slice(":", 1).strip_edges())
	var body_off := br + sep_len
	var have := buf.size() - body_off
	if have < length:
		return false
	var body := buf.slice(body_off, body_off + length).get_string_from_utf8()
	_handle_http(peer, method, path, body)
	return true


func _handle_http(peer: StreamPeerTCP, method: String, path: String, body: String) -> void:
	if method == "GET" and path in ["/", "/health"]:
		_http_reply(peer, 200, {"ok": true, "service": "hnt-rooms"})
		return
	if method == "GET" and path.begins_with("/rooms/"):
		var code := path.substr(7).split("/")[0].to_upper()
		if _rooms.has(code):
			_http_reply(peer, 200, _public_room(_rooms[code]))
		else:
			_http_reply(peer, 404, {"error": "gone"})
		return
	if method == "POST" and path in ["/rooms", "/rooms/"]:
		var parsed: Variant = JSON.parse_string(body if body != "" else "{}")
		if typeof(parsed) != TYPE_DICTIONARY:
			_http_reply(peer, 400, {"error": "code"})
			return
		var d: Dictionary = parsed
		var code := str(d.get("code", "")).to_upper()
		if code.length() != 6:
			_http_reply(peer, 400, {"error": "code"})
			return
		var row := {
			"code": code,
			"lan": d.get("lan", []),
			"wan": str(d.get("wan", "")),
			"port": int(d.get("port", 24567)),
			"relay": str(d.get("relay", "127.0.0.1")),
			"relay_port": int(d.get("relay_port", RELAY_PORT)),
			"upnp": bool(d.get("upnp", false)),
			"t": Time.get_unix_time_from_system()
		}
		_rooms[code] = row
		_http_reply(peer, 200, _public_room(row))
		return
	_http_reply(peer, 404, {"error": "no"})


func _public_room(row: Dictionary) -> Dictionary:
	var out := row.duplicate()
	out.erase("t")
	return out


func _http_reply(peer: StreamPeerTCP, code: int, payload: Dictionary) -> void:
	var raw := JSON.stringify(payload).to_utf8_buffer()
	var reason := "OK" if code == 200 else "ERR"
	var head := "HTTP/1.1 %d %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [code, reason, raw.size()]
	peer.put_data(head.to_utf8_buffer())
	peer.put_data(raw)


func _pump_relay_handshake() -> void:
	var keep: Array[Dictionary] = []
	for row in _relay_peers:
		var peer: StreamPeerTCP = row["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue
		row["buf"] = _read_into(peer, row["buf"])
		var text := (row["buf"] as PackedByteArray).get_string_from_utf8()
		var nl := text.find("\n")
		if nl < 0:
			keep.append(row)
			continue
		var line := text.substr(0, nl).strip_edges()
		var leftover := (row["buf"] as PackedByteArray).slice(nl + 1)
		var parts := line.split(" ")
		if parts.size() < 3 or parts[0] != "HNT1":
			peer.disconnect_from_host()
			continue
		var kind := parts[1].to_upper()
		var code := parts[2].to_upper()
		if kind not in ["HOST", "JOIN"] or code == "":
			peer.disconnect_from_host()
			continue
		peer.put_data("HNT1 OK\n".to_utf8_buffer())
		var incoming := {"peer": peer, "buf": leftover}
		if _waiting.has(code):
			var other: Dictionary = _waiting[code]
			_waiting.erase(code)
			_pairs.append({
				"a": incoming["peer"],
				"b": other["peer"],
				"ab": incoming["buf"],
				"ba": other["buf"]
			})
		else:
			_waiting[code] = incoming
	_relay_peers = keep


func _pump_pairs() -> void:
	var keep: Array[Dictionary] = []
	for row in _pairs:
		var a: StreamPeerTCP = row["a"]
		var b: StreamPeerTCP = row["b"]
		a.poll()
		b.poll()
		if a.get_status() != StreamPeerTCP.STATUS_CONNECTED or b.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			a.disconnect_from_host()
			b.disconnect_from_host()
			continue
		row["ab"] = _drain(a, b, row["ab"])
		row["ba"] = _drain(b, a, row["ba"])
		keep.append(row)
	_pairs = keep


func _drain(src: StreamPeerTCP, dst: StreamPeerTCP, pending: PackedByteArray) -> PackedByteArray:
	pending = _read_into(src, pending)
	if pending.is_empty():
		return pending
	var err := dst.put_data(pending)
	if err != OK:
		return pending
	return PackedByteArray()
