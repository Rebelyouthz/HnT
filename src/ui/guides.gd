class_name Guides
extends RefCounted

## What Dad and the Kid say the first time each thing opens (see Guide).
## Keys point at controls by their meta "key" or "button:TEXT".

const STEPS := {
	"hub": [
		{"text": "Welcome home. This is the clinic. Everything we buy, build and learn lives in these menus."},
		{"key": "pill_gold", "text": "GOLD. We earn it on the street. When we get some, the coins fly up here and the number counts."},
		{"key": "pill_gems", "text": "GEMS are rare. Bosses, secrets, the CODEX and AWARDS give them. Spend them on the good stuff."},
		{"key": "button:RUN", "text": "RUN takes us out for a night. That is where gold, gear and new thugs come from."},
		{"key": "button:HEROES", "text": "HEROES: level the two of us up, raise our rarity with shards and buy META upgrades that last forever."},
		{"key": "button:CODEX", "text": "Everything we meet gets written down in the CODEX. A red dot there means a reward is waiting."},
		{"key": "rewards_btn", "text": "The GIFT is our REWARDS desk: a free crate every day, the CLINIC ROAD and everything waiting to be claimed. The number says how much."},
		{"key": "power", "text": "PWR is how strong the family is all together. Every upgrade pushes it up, and it counts up right here."},
		{"who": "son", "text": "And the little red squares everywhere mean something NEW. Always press them. Always."},
	],
	"rewards": [
		{"key": "crate", "text": "One free crate a day. Come back every day and it grows: day seven is the big one. Miss a day and it starts over."},
		{"key": "all", "text": "CLAIM ALL takes everything at once: the crate, road levels, codex entries, finished jobs and awards."},
		{"who": "son", "text": "The CLINIC ROAD pays out every account level. Every fifth level is a chest. Titles go under our names. I want EXECUTIONER."},
	],
	"heroes": [
		{"key": "lv_son", "text": "LEVEL UP spends gold. More health, more damage, a bit faster. Green numbers are what you gain."},
		{"key": "rk_son", "text": "At the level cap, SHARDS raise rarity: grey, green, blue, purple, orange. Every rarity lifts the cap. Hold to confirm."},
		{"key": "br_body", "text": "META upgrades are forever. One set for brawling, one for survivor, one for parkour."},
		{"key": "meta_vitality", "text": "Each upgrade has ranks. Press to buy the next rank and watch it light up."},
	],
	"build": [
		{"text": "This is the skill tree. Three trees per way of playing, three trunks each."},
		{"key": "button:BRAWL", "text": "Switch trees here: BRAWL for the streets, SURVIVOR for the coping hours, PARKOUR for the roofs."},
		{"who": "son", "text": "A glowing node is one we can buy. Grey ones need the node under them first. The strip at the bottom says what it does."},
		{"key": "button:REFUND", "text": "Changed your mind? REFUND TREE gives every coin back. No receipts needed."},
	],
	"locker": [
		{"text": "The LOCKER. We stand in the middle wearing what we have on. Pick a slot round us to see what fits."},
		{"text": "Every piece shows its stats against what we wear now: green goes up, red goes down. Grey is what we have."},
		{"who": "son", "text": "Three of the same piece COMBINE into a rarer one. Suit parts mix too: mask, top, bottom. Full set = bonus."},
	],
	"armory": [
		{"text": "The ARMORY: every weapon we ever picked up. Kills with one count toward MASTERY."},
		{"key": "button:LV", "text": "LEVEL a weapon with gold: it hits harder and opens more mod slots."},
		{"who": "son", "text": "Guns have a GUNSMITH. Muzzle, optic, barrel, magazine, ammo. Each part shows on the gun."},
	],
	"gunsmith": [
		{"text": "The bench. The gun is drawn with every part on it. Blinking markers are empty slots, padlocks open with gun level."},
		{"key": "part_suppressor", "text": "Pick a part. A ghost of it shows on the gun, and the bars say what changes: grey now, green better, red worse."},
		{"who": "son", "text": "Press to buy it with gems, then it slides on and clicks home. Press it again to take it off. Parts fit every gun."},
	],
	"sgear": [
		{"text": "Survivor gear. The Kid wears it into every coping hour: cap, jacket, shoes, charm, necklace and ring."},
		{"key": "box", "text": "A GEAR BOX costs S-COINS and gives a random piece. Bosses and elite chests drop them too."},
		{"key": "inv_0", "text": "Your pieces. Press one to WEAR it. The details below compare it with what is on him now."},
		{"key": "lv", "text": "LEVEL UP spends S-COINS. FUSE takes three of the same piece and rarity and makes the next rarity."},
	],
	"codex": [
		{"text": "The CODEX. Every thug, boss, weapon, ability, gear piece, gun part and place we meet gets an entry."},
		{"key": "cat_enemy", "text": "Each tab counts what we found. A red dot means an entry waits to be claimed."},
		{"key": "button:CLAIM ALL", "who": "son", "text": "CLAIM pays gold or gems, and every ten filed pays a bonus. Dark plates are still out there."},
	],
	"moves": [
		{"text": "MOVES. Learn new strikes with gold, then put them on your buttons in the loadout."},
		{"who": "son", "text": "ELEMENTS are special arts: press LIGHT + HEAVY together with a direction. They level up and EVOLVE with gems."},
	],
	"awards": [
		{"text": "AWARDS. Everything we pull off counts toward these. Finished ones pay out: press to claim."},
	],
	"camp": [
		{"text": "The hideout. Each room we build opens something new in the menus: the dojo, the locker, the tree."},
		{"who": "son", "text": "Build in order, the cheap ones first. When a room opens, I will show you how it works."},
	],
	"cards": [
		{"text": "LEVEL UP! Pick one card. It changes the rules for the rest of the night."},
		{"text": "The badge says what it is: PASSIVE, ACTIVE, PET, AUTOWEAPON or MANUAL weapon. The frame colour is its rarity."},
		{"who": "son", "text": "The same card again later LEVELS it up: grey bars are what you have, green is what you get."},
	],
	"starter": [
		{"text": "Pick the weapon the Kid walks into the coping hour with. It stays ours: it levels and gets rarer."},
		{"key": "lv", "text": "LEVEL UP with S-COINS: grey is the damage now, green is after. Copies from boss chests MERGE into a rarer one."},
		{"who": "son", "text": "Two MOD slots per weapon. Locked starters open with the CHALLENGES on the right."},
	],
	"spick": [
		{"text": "Survivor level up. Abilities fire on their own, traits stack, items help everything."},
		{"who": "son", "text": "MANUAL weapons fire when you press SHOOT with empty hands. REROLL and BANISH if you hate all three."},
	],
}


static func show(from: Node, gid: String, delay := 0.4) -> void:
	if STEPS.has(gid):
		Guide.play(from, gid, STEPS[gid], delay)
