"""Father & Son online relay: pairs the Son's game and Dad's game by a room
code and passes their messages back and forth over one WebSocket each, so
two houses in two cities connect without opening router ports.

  wss://<space>.hf.space/ws?room=482917&role=host   (the Son)
  wss://<space>.hf.space/ws?room=482917&role=join   (Dad)

Both get the text frame "PAIRED" when the other side is in; every frame after
that is forwarded as-is. "PEER_LEFT" when the other side drops. No accounts,
nothing stored: a room lives only while its two sockets are open."""
import asyncio
import os
import time

from aiohttp import WSMsgType, web

MAX_ROOMS = 300
MAX_FRAME = 64 * 1024
IDLE_S = 15 * 60
rooms: dict[str, dict] = {}


def _clean(code: str) -> str:
    return "".join(ch for ch in code.upper() if ch.isalnum())[:12]


async def health(_req: web.Request) -> web.Response:
    return web.Response(text="Father & Son relay: ok · rooms %d\n" % len(rooms))


async def ws_handler(req: web.Request) -> web.WebSocketResponse:
    code = _clean(req.query.get("room", ""))
    role = req.query.get("role", "")
    ws = web.WebSocketResponse(heartbeat=20.0, max_msg_size=MAX_FRAME)
    await ws.prepare(req)
    if len(code) < 4 or role not in ("host", "join"):
        await ws.send_str("BAD_REQUEST")
        await ws.close()
        return ws
    room = rooms.get(code)
    if room is None:
        if len(rooms) >= MAX_ROOMS:
            await ws.send_str("FULL")
            await ws.close()
            return ws
        room = {"host": None, "join": None, "t": time.time()}
        rooms[code] = room
    old = room.get(role)
    if old is not None and not old.closed:
        # Same role reconnecting (a dropped wifi): the new socket wins.
        await old.close()
    room[role] = ws
    room["t"] = time.time()
    other = room["join" if role == "host" else "host"]
    if other is not None and not other.closed:
        await ws.send_str("PAIRED")
        await other.send_str("PAIRED")
    else:
        await ws.send_str("WAITING")
    try:
        async for msg in ws:
            room["t"] = time.time()
            peer = room["join" if role == "host" else "host"]
            if peer is None or peer.closed:
                continue
            if msg.type == WSMsgType.TEXT:
                await peer.send_str(msg.data)
            elif msg.type == WSMsgType.BINARY:
                await peer.send_bytes(msg.data)
    finally:
        if room.get(role) is ws:
            room[role] = None
            peer = room["join" if role == "host" else "host"]
            if peer is not None and not peer.closed:
                try:
                    await peer.send_str("PEER_LEFT")
                except Exception:
                    pass
        if room.get("host") is None and room.get("join") is None:
            rooms.pop(code, None)
    return ws


async def sweeper(_app: web.Application) -> None:
    while True:
        await asyncio.sleep(60)
        now = time.time()
        for code, room in list(rooms.items()):
            if now - room["t"] > IDLE_S:
                for r in ("host", "join"):
                    s = room.get(r)
                    if s is not None and not s.closed:
                        await s.close()
                rooms.pop(code, None)


async def start_bg(app: web.Application) -> None:
    app["sweeper"] = asyncio.create_task(sweeper(app))


app = web.Application()
app.router.add_get("/", health)
app.router.add_get("/ws", ws_handler)
app.on_startup.append(start_bg)

if __name__ == "__main__":
    web.run_app(app, host="0.0.0.0", port=int(os.environ.get("PORT", "7860")))
