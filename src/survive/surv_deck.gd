class_name SurvDeck
extends RefCounted

## THE SURVIVOR DECK: the hour's own card collection (separate from the
## street's level-up cards and the vault). Every survivor level-up card is a
## card here: the auto weapons, the traits and the items.
##   * Base cards are yours from the start (1 copy). DECK cards (rows with
##     "deck": true in data/survive.json) only show up in level-ups once
##     you own a copy.
##   * PACKS cost S-COINS: three cards, rarity-weighted. Copies raise a
##     card's STARS (1-5): each star past the first is +6% damage for a
##     weapon and +12% chance to be offered.
##   * BENCH up to 6 cards you never want to see in a level-up.
## Saved in FamilyProfile.data["surv_deck"] = {own: {id: copies}, bench: [ids], packs: n}.

const STAR_AT := [1, 3, 6, 10, 15]
const MAX_BENCH := 6
const PACK_BASE := 120
const PACK_STEP := 40
const PACK_MAX := 600
const RAR_W := {"common": 10.0, "uncommon": 6.0, "rare": 3.0, "epic": 1.4, "legendary": 0.6}

static var _book: Dictionary = {}


static func book() -> Dictionary:
	if _book.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
		if d is Dictionary:
			_book = d
	return _book


static func _state() -> Dictionary:
	var s: Dictionary = FamilyProfile.data.get("surv_deck", {})
	if not s.has("own"):
		s["own"] = {}
	if not s.has("bench"):
		s["bench"] = []
	FamilyProfile.data["surv_deck"] = s
	return s


## Every card: {id, kind, name, icon, rarity, deck, blurb}.
static func cards() -> Array:
	var out: Array = []
	for kind in ["abilities", "traits", "items"]:
		for r: Dictionary in book().get(kind, []):
			out.append({"id": str(r["id"]), "kind": kind, "name": str(r.get("name", r["id"])), "icon": str(r.get("icon", r["id"])),
				"rarity": str(r.get("rarity", _default_rar(kind, r))), "deck": bool(r.get("deck", false)),
				"manual": bool(r.get("manual", false)), "blurb": str(r.get("blurb", ""))})
	return out


static func _default_rar(kind: String, r: Dictionary) -> String:
	if kind == "items":
		return "rare"
	if kind == "traits":
		return "common"
	return "uncommon" if str(r.get("unlock", "")) != "" else "common"


static func card(id: String) -> Dictionary:
	for c: Dictionary in cards():
		if str(c["id"]) == id:
			return c
	return {}


static func copies(id: String) -> int:
	var own: Dictionary = _state()["own"]
	if own.has(id):
		return int(own[id])
	# Base cards come with one copy.
	return 0 if bool(card(id).get("deck", false)) else 1


static func owned(id: String) -> bool:
	return copies(id) > 0


static func stars(id: String) -> int:
	var n := copies(id)
	var s := 0
	for at in STAR_AT:
		if n >= int(at):
			s += 1
	return s


## Copies needed for the next star (0 at max).
static func next_at(id: String) -> int:
	var s := stars(id)
	return int(STAR_AT[s]) if s < STAR_AT.size() else 0


static func power(id: String) -> float:
	return 1.0 + 0.06 * float(maxi(0, stars(id) - 1))


static func weight(id: String) -> float:
	return 1.0 + 0.12 * float(maxi(0, stars(id) - 1))


static func benched(id: String) -> bool:
	return (_state()["bench"] as Array).has(id)


static func bench_count() -> int:
	return (_state()["bench"] as Array).size()


## Bench / unbench. False when the bench is full.
static func toggle_bench(id: String) -> bool:
	var b: Array = _state()["bench"]
	if b.has(id):
		b.erase(id)
	elif b.size() >= MAX_BENCH:
		return false
	else:
		b.append(id)
	FamilyProfile.save()
	return true


static func pack_cost() -> int:
	return mini(PACK_MAX, PACK_BASE + PACK_STEP * int(_state().get("packs", 0)))


## Pays and opens a pack: three card ids (new deck cards weigh more until
## you own them). Empty when the S-coins are short.
static func open_pack() -> Array:
	var cost := pack_cost()
	if int(FamilyProfile.data.get("tokens", 0)) < cost:
		return []
	FamilyProfile.data["tokens"] = int(FamilyProfile.data.get("tokens", 0)) - cost
	var s := _state()
	s["packs"] = int(s.get("packs", 0)) + 1
	var pool := cards()
	var out: Array = []
	for i in 3:
		var total := 0.0
		var ws: Array = []
		for c: Dictionary in pool:
			var w := float(RAR_W.get(str(c["rarity"]), 5.0))
			if bool(c["deck"]) and not owned(str(c["id"])):
				w *= 2.5
			if stars(str(c["id"])) >= STAR_AT.size():
				w *= 0.15
			ws.append(w)
			total += w
		var roll := randf() * total
		for k in pool.size():
			roll -= float(ws[k])
			if roll <= 0.0:
				var id := str(pool[k]["id"])
				var own: Dictionary = s["own"]
				own[id] = copies(id) + 1
				out.append(id)
				break
	FamilyProfile.save()
	return out


static func icon(id: String) -> Texture2D:
	return SurviveIcons.tex(str(card(id).get("icon", id)))
