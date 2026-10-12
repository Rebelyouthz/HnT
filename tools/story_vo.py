#!/usr/bin/env python3
"""Voice the story's spoken lines (films, prologue, act talk, rescues,
bridges, tower talks, ending) with the cast's ElevenLabs voices.

Each clip is assets/audio/vo/story/<md5(who|text)[:10]>.ogg, the same name
StoryVo.path() builds in game, so an edited line just goes quiet until it is
recorded again. Narrator captions (who "") stay silent. Lines go in story
order and the run stops before the account's character quota runs out, so a
free tier voices the start of the game first. Skips clips already on disk.

    python3 tools/story_vo.py [--dry]
"""
import hashlib, json, sys, tempfile, subprocess, time, urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import eleven_vo as E

ROOT = E.ROOT
OUT = ROOT / "assets/audio/vo/story"
ORDER = ["dock_street", "intake_lot", "fire_escapes", "group_circle", "neon_exchange", "waiting_room",
         "rail_bridge", "city_hall", "copay_orchard", "sleet_hour", "raven_grid", "ledger_dive",
         "invoice_pier", "processing_floor"]
CAST = {"father": "father", "son": "son", "benny": "repo", "rico": "runner", "dot": "npc_woman", "collector": "gant"}
KEEP = 40  # characters left on the quota, never spent
CAMP_HERO = [
    "Home. Technically a basement.",
    "Fridge first. Then we argue about the map.",
    "Fridge first. Then I argue with the map.",
    "You made it back. The portal's still humming.",
    "Made it back. The portal's still humming.",
    "Patch up, gear up, then we go back out.",
    "Before we go back out, we build something. Follow the arrow.",
    "Benny would have this up in a minute. We need him back from Dock Street.",
    "That's Rico's counter. Nobody touches the till till he's home.",
]
CAMP_CREW = [
    ("benny", "Love the plan. Love it more with gold for lumber."),
    ("benny", "Stand back. Art is happening."),
]


def lines_of(o):
    if isinstance(o, dict):
        if "who" in o and "text" in o:
            yield str(o["who"]), str(o["text"])
            return
        for v in o.values():
            yield from lines_of(v)
    elif isinstance(o, list):
        for v in o:
            yield from lines_of(v)


def queue():
    s = json.loads((ROOT / "data/story.json").read_text())
    t = json.loads((ROOT / "data/towers.json").read_text())
    q = []
    q += list(lines_of(s["intro"].get("film1", [])))
    q += list(lines_of(s["intro"].get("film2", [])))
    q += list(lines_of(s.get("prologue", [])))
    done_talks = set()
    for i, m in enumerate(ORDER):
        act = s.get("acts", {}).get(m, {})
        q += list(lines_of(act.get("talk", [])))
        q += list(lines_of(act.get("rescue", {})))
        tid = t.get("maps", {}).get(m, {}).get("talk", "")
        if tid and tid not in done_talks and tid in t["talks"]:
            done_talks.add(tid)
            tk = t["talks"][tid]
            if tk.get("eat_joke"):
                q.append(("son", str(tk["eat_joke"])))
            q += list(lines_of(tk))
        if i + 1 < len(ORDER):
            q += list(lines_of(s.get("bridges", {}).get(m + "->" + ORDER[i + 1], {})))
    q += list(lines_of(s.get("ending", {})))
    # The hideout: fixed lines in src/world/camp_hideout.gd (either hero may
    # say the hero ones), then the crew's idle chatter.
    for hero in ("father", "son"):
        q += [(hero, t) for t in CAMP_HERO]
    q += CAMP_CREW
    for who, pool in s.get("crew_talk", {}).items():
        q += [(who, str(t)) for t in pool]
    for tid, tk in t["talks"].items():
        if tid not in done_talks:
            if tk.get("eat_joke"):
                q.append(("son", str(tk["eat_joke"])))
            q += list(lines_of(tk))
    seen, out = set(), []
    for who, text in q:
        if who and text and (who, text) not in seen:
            seen.add((who, text))
            out.append((who, text))
    return out


def clip(who, text):
    return OUT / (hashlib.md5((who + "|" + text).encode()).hexdigest()[:10] + ".ogg")


def left() -> int:
    r = urllib.request.Request("https://api.elevenlabs.io/v1/user/subscription")
    r.add_header("xi-api-key", E.key())
    with urllib.request.urlopen(r, timeout=30) as f:
        d = json.load(f)
    return int(d["character_limit"]) - int(d["character_count"])


def main():
    dry = "--dry" in sys.argv
    q = [(w, t) for w, t in queue() if not clip(w, t).exists()]
    unknown = sorted({w for w, _ in q if w not in CAST})
    print(f"{len(q)} lines to voice, {sum(len(t) for _, t in q)} chars; no voice for: {unknown}")
    if dry:
        return
    OUT.mkdir(parents=True, exist_ok=True)
    budget = left()
    print("quota left", budget)
    for who, text in q:
        v = E.VOICE.get(CAST.get(who, ""))
        if not v:
            continue
        if len(text) > budget - KEEP:
            print("quota reached at", who, repr(text[:40]))
            break
        try:
            mp3 = E.tts(text, v, 0.5, 0.3)
        except Exception as e:
            print("ERR", who, str(e)[:160], flush=True)
            if "401" in str(e) or "402" in str(e) or "quota" in str(e).lower():
                break
            continue
        budget -= len(text)
        with tempfile.NamedTemporaryFile(suffix=".mp3") as tmp:
            tmp.write(mp3)
            tmp.flush()
            subprocess.run([E.ffmpeg(), "-y", "-loglevel", "error", "-i", tmp.name, "-af",
                            "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5",
                            "-ac", "1", "-ar", "32000", "-c:a", "libvorbis", "-q:a", "1", str(clip(who, text))], check=True)
        print("OK", who, clip(who, text).name, len(text), "left", budget, flush=True)
        time.sleep(0.25)


if __name__ == "__main__":
    main()
