#!/usr/bin/env python3
"""Tiny client for the Sorceress Tool API (https://sorceress.games/api/v1).

The key is read from $SORCERESS_KEY or ~/.config/sorceress/key and is never
written anywhere else (keep it out of git).

    python3 tools/sorceress.py ping
    python3 tools/sorceress.py upload file.png          -> publicUrl
    python3 tools/sorceress.py call image_generate '{"model":"gpt-image-2","prompt":"..."}'
    python3 tools/sorceress.py job <jobId>               (polls until done)
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.request
from pathlib import Path

BASE = "https://sorceress.games/api/v1"


def key() -> str:
    k = os.environ.get("SORCERESS_KEY", "").strip()
    if not k:
        k = (Path.home() / ".config/sorceress/key").read_text().strip()
    return k


def req(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(BASE + path, data=data, method=method)
    r.add_header("Authorization", "Bearer " + key())
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=120) as f:
            return json.loads(f.read())
    except urllib.error.HTTPError as e:
        return {"ok": False, "status": e.code, "error": e.read().decode(errors="ignore")[:800]}


def call(tool: str, inp: dict) -> dict:
    return req("POST", "/tools/" + tool, inp)


def job(jid: str, every: float = 6.0, timeout: float = 1800.0) -> dict:
    t0 = time.time()
    while True:
        j = req("GET", "/jobs/" + jid)
        st = (j.get("data") or j).get("status") if isinstance(j.get("data") or j, dict) else None
        if st in ("succeeded", "failed") or not j.get("ok", True) or time.time() - t0 > timeout:
            return j
        time.sleep(every)


def upload(path: str, ctype: str = "") -> str:
    p = Path(path)
    ctype = ctype or {".png": "image/png", ".jpg": "image/jpeg", ".mp4": "video/mp4", ".webp": "image/webp"}.get(p.suffix, "application/octet-stream")
    u = call("file_upload", {"filename": p.name, "contentType": ctype})
    d = u.get("data") or u
    r = urllib.request.Request(d["uploadUrl"], data=p.read_bytes(), method="PUT")
    for k, v in (d.get("headers") or {"Content-Type": ctype}).items():
        r.add_header(k, v)
    urllib.request.urlopen(r, timeout=300).read()
    return d["publicUrl"]


def fetch(url: str, out: str) -> None:
    with urllib.request.urlopen(url, timeout=300) as f:
        Path(out).write_bytes(f.read())


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "ping":
        print(json.dumps(call("ping", {"message": "hi"})))
    elif cmd == "upload":
        print(upload(sys.argv[2]))
    elif cmd == "call":
        print(json.dumps(call(sys.argv[2], json.loads(sys.argv[3]))))
    elif cmd == "job":
        print(json.dumps(job(sys.argv[2])))
