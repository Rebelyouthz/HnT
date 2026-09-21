#!/usr/bin/env python3
"""HnT Rooms — room codes + TCP splice relay. No accounts. Codes die in 30 minutes."""
from __future__ import annotations

import json
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HTTP_PORT = 8787
RELAY_PORT = 8789
TTL = 30 * 60
ROOMS: dict[str, dict] = {}
LOCK = threading.Lock()
WAITING: dict[str, socket.socket] = {}


def prune() -> None:
    now = time.time()
    dead = [c for c, r in ROOMS.items() if now - r.get("t", now) > TTL]
    for c in dead:
        ROOMS.pop(c, None)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        return

    def _send(self, code: int, payload: dict) -> None:
        raw = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:  # noqa: N802
        with LOCK:
            prune()
        if self.path in ("/", "/health"):
            self._send(200, {"ok": True, "service": "hnt-rooms"})
            return
        if self.path.startswith("/rooms/"):
            code = self.path.split("/rooms/", 1)[1].split("?")[0].upper()
            with LOCK:
                row = ROOMS.get(code)
            if not row:
                self._send(404, {"error": "gone"})
                return
            self._send(200, {k: v for k, v in row.items() if k != "t"})
            return
        self._send(404, {"error": "no"})

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", "0") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            body = {}
        with LOCK:
            prune()
        if self.path in ("/rooms", "/rooms/"):
            code = str(body.get("code", "")).upper()
            if len(code) != 6:
                self._send(400, {"error": "code"})
                return
            row = {
                "code": code,
                "lan": body.get("lan") or [],
                "wan": body.get("wan") or "",
                "port": int(body.get("port") or 24567),
                "relay": body.get("relay") or "127.0.0.1",
                "relay_port": int(body.get("relay_port") or RELAY_PORT),
                "upnp": bool(body.get("upnp")),
                "t": time.time(),
            }
            with LOCK:
                ROOMS[code] = row
            self._send(200, {k: v for k, v in row.items() if k != "t"})
            return
        if "/join" in self.path and self.path.startswith("/rooms/"):
            code = self.path.split("/rooms/", 1)[1].split("/")[0].upper()
            with LOCK:
                row = ROOMS.get(code)
            if not row:
                self._send(404, {"error": "gone"})
                return
            self._send(200, {k: v for k, v in row.items() if k != "t"})
            return
        self._send(404, {"error": "no"})


def splice(a: socket.socket, b: socket.socket) -> None:
    def pump(src: socket.socket, dst: socket.socket) -> None:
        try:
            while True:
                buf = src.recv(65536)
                if not buf:
                    break
                dst.sendall(buf)
        except OSError:
            pass
        try:
            dst.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass

    threading.Thread(target=pump, args=(a, b), daemon=True).start()
    pump(b, a)


def relay_loop() -> None:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", RELAY_PORT))
    srv.listen(16)
    while True:
        conn, _addr = srv.accept()
        threading.Thread(target=handle_relay, args=(conn,), daemon=True).start()


def handle_relay(conn: socket.socket) -> None:
    conn.settimeout(8.0)
    try:
        data = b""
        while b"\n" not in data:
            chunk = conn.recv(256)
            if not chunk:
                conn.close()
                return
            data += chunk
        line = data.split(b"\n", 1)[0].decode("utf-8", "replace").strip()
        parts = line.split()
        if len(parts) < 3 or parts[0] != "HNT1":
            conn.close()
            return
        kind, code = parts[1].upper(), parts[2].upper()
        conn.sendall(b"HNT1 OK\n")
        with LOCK:
            other = WAITING.pop(code, None)
            if other is None:
                WAITING[code] = conn
                return
        splice(conn, other)
    except OSError:
        try:
            conn.close()
        except OSError:
            pass


def main() -> None:
    threading.Thread(target=relay_loop, daemon=True).start()
    httpd = ThreadingHTTPServer(("0.0.0.0", HTTP_PORT), Handler)
    print("hnt-rooms http %d  relay %d" % (HTTP_PORT, RELAY_PORT), flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
