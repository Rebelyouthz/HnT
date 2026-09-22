extends SceneTree

## Boot in-engine rooms and hit /health + POST/GET a code. Ports 8787/8789.

var _rs: Node
var _started := false
var _frames := 0


func _initialize() -> void:
	_rs = get_root().get_node_or_null("RoomsServer")
	if _rs == null:
		push_error("RoomsServer missing")
		quit(1)
		return
	if not bool(_rs.call("boot")):
		push_error("RoomsServer.boot failed")
		quit(1)
		return
	print("ROOMS_BOOT_OK")


func _process(_delta: float) -> bool:
	if _rs:
		_rs.call("pump")
	_frames += 1
	if not _started and _frames >= 3:
		_started = true
		_probe()
	return false


func _probe() -> void:
	var h := HTTPRequest.new()
	h.timeout = 2.5
	root.add_child(h)
	var err := h.request("http://127.0.0.1:8787/health")
	if err != OK:
		push_error("health request failed")
		quit(1)
		return
	var got: Array = await h.request_completed
	var body_text := (got[3] as PackedByteArray).get_string_from_utf8()
	if int(got[1]) != 200 or not body_text.contains("hnt-rooms"):
		push_error("health bad result=%s code=%s body=%s" % [got[0], got[1], body_text])
		quit(1)
		return
	var body := JSON.stringify({
		"code": "ABC234",
		"lan": ["10.0.0.2"],
		"wan": "",
		"port": 24567,
		"relay": "10.0.0.2",
		"relay_port": 8789,
		"upnp": false
	})
	err = h.request("http://127.0.0.1:8787/rooms", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("post failed")
		quit(1)
		return
	got = await h.request_completed
	if int(got[1]) != 200:
		push_error("post status %s" % got[1])
		quit(1)
		return
	err = h.request("http://127.0.0.1:8787/rooms/ABC234")
	if err != OK:
		push_error("get failed")
		quit(1)
		return
	got = await h.request_completed
	var parsed: Variant = JSON.parse_string((got[3] as PackedByteArray).get_string_from_utf8())
	if int(got[1]) != 200 or typeof(parsed) != TYPE_DICTIONARY or str((parsed as Dictionary).get("code", "")) != "ABC234":
		push_error("get room bad")
		quit(1)
		return
	print("ROOMS_HTTP_OK")
	var host_tcp := StreamPeerTCP.new()
	if host_tcp.connect_to_host("127.0.0.1", 8789) != OK:
		push_error("relay host connect")
		quit(1)
		return
	var join_tcp := StreamPeerTCP.new()
	if join_tcp.connect_to_host("127.0.0.1", 8789) != OK:
		push_error("relay join connect")
		quit(1)
		return
	var left := 2.0
	var host_ok := false
	var join_ok := false
	while left > 0.0:
		host_tcp.poll()
		join_tcp.poll()
		if not host_ok and host_tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			host_tcp.put_data("HNT1 HOST ABC234\n".to_utf8_buffer())
			host_ok = true
		if not join_ok and join_tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			join_tcp.put_data("HNT1 JOIN ABC234\n".to_utf8_buffer())
			join_ok = true
		if host_ok and join_ok:
			break
		await create_timer(0.05).timeout
		left -= 0.05
	if not host_ok or not join_ok:
		push_error("relay handshake send")
		quit(1)
		return
	left = 2.0
	var host_got := ""
	var join_got := ""
	while left > 0.0:
		host_tcp.poll()
		join_tcp.poll()
		if host_tcp.get_available_bytes() > 0:
			host_got += host_tcp.get_utf8_string(host_tcp.get_available_bytes())
		if join_tcp.get_available_bytes() > 0:
			join_got += join_tcp.get_utf8_string(join_tcp.get_available_bytes())
		if host_got.contains("OK") and join_got.contains("OK"):
			break
		await create_timer(0.05).timeout
		left -= 0.05
	if not host_got.contains("OK") or not join_got.contains("OK"):
		push_error("relay OK missing host=%s join=%s" % [host_got, join_got])
		quit(1)
		return
	host_tcp.put_data("ping-from-host".to_utf8_buffer())
	left = 2.0
	var bounced := ""
	while left > 0.0:
		join_tcp.poll()
		if join_tcp.get_available_bytes() > 0:
			bounced += join_tcp.get_utf8_string(join_tcp.get_available_bytes())
		if bounced.contains("ping-from-host"):
			break
		await create_timer(0.05).timeout
		left -= 0.05
	if not bounced.contains("ping-from-host"):
		push_error("relay splice missed ping: %s" % bounced)
		quit(1)
		return
	print("ROOMS_RELAY_OK")
	quit(0)
