# HnT — Revenge & Therapy

Couch, **solo**, or **remote Host/Join** brawler for **The Father** and **The Son**. Godot **4.7.2**, GDScript, 60 fps, English only.

The Basement Clinic billed them for family therapy they never attended. Mayor Raven holds the eviction **and** the invoice. They collect coping evidence so the clinic does not seize the apartment or the Son's tutoring license. The night is one plot: **story films between every act**, then a late-act climax on **The Processing Floor**.

Playable tonight: hub, **intro film + comic + tutorial + second film**, **fourteen campaign maps** (brawl + five survivor hours + chase crash + Invoice Pier + Processing Floor), **Versus**, Host/Join, **Options + Reset**, pinball scores, avatar gear. Solo spawns fewer enemies. Couch 2P keeps the full roster. Drop-in does **not** restock punks.

## Run locally

1. Install [Godot 4.7.2 Standard](https://godotengine.org/download) (not the .NET build).
2. Open this folder in the editor, or from a terminal:

```bash
godot --path .
```

Headless smoke:

```bash
godot --headless --path . --script res://tests/smoke.gd
```

Host/Join rooms live **inside the game** (HTTP `8787`, TCP relay `8789`). The Son does not install Python or Godot. Optional standalone rooms for a shared server:

```bash
python3 tools/hnt_rooms.py
```

Change the rooms URL in **Options** if the Father is on another PC. Windows Setup: `tools/windows/pack_windows.sh` → `build/windows/FatherAndSonSetup.exe`.

## How to see the inter-act films

Play a campaign run (**GO ALONE** / **GO TOGETHER** / Host). Clear an act (miniboss then boss). On the results sheet tap the **NEXT** button (or the named next act).

The game hops to a letterbox **act film** (SoR4 comic-between-stages):

1. **Chapter card** — act title.
2. **Lines** — The Father and The Son keep the plot moving.
3. Then the next map loads.

**PAUSE** skips the current beat (chapter card, or the rest of the film). **LIGHT / JUMP** advances a line. Same as the intro.

Remote Host/Join: both peers see the film. The host still advances; the guest gets `film_from` / `film_next` with the begin packet.

**Options → SKIP INTER-ACT FILMS** jumps the night straight to the next map. Intro films still play the first time unless you already filed intake. The campaign parachute and the skinwalker film still play.

Replay intro anytime: Run tab **PLAY INTRO**.

## How the final boss starts

1. File **City Hall** (Mayor Raven). Film to **Copay Orchard**.
2. File orchard → sleet → **Raven Grid** (chase crash) → **Ledger Dive** → **Invoice Pier**.
3. File **Invoice Pier** (Usher Prime, then Dr. Splint). Film to **The Processing Floor**.
3. Bandage desk at the start (24/7 Blood Mart). Mini **Adjuster Prime**. Then **The Family Plan** / Director Binder.

The Family Plan is the late-act climax, not a Mayor palette-swap:

- **Strip armor first.** Four plates. Lights go *CLINK*. Heavies strip plates. SNAP is denied until the suit is a receipt.
- After **ARMOR STRIPPED**, a long pattern fight: X-slash, horizontal sweep, triple slam, invoice rain, then frenzy.
- Portrait + boss sting, then **finale music** when the plates are gone.
- Dedicated **boss HP bar** (armor count while plated).
- **FILE ALIVE:** SNAP while stunned for extra gold (Huntdown take-alive). Still have to finish him.
- Pre-fight film on the way in. **Ending film** after the results **WATCH THE ENDING** button (or auto after the floor files).

## Campaign order (14 maps)

Brawl acts mix **parkour / gun / brawl**. Every act: **miniboss**, later content, **boss** with portrait + name + sting + boss music. Parallax is **multi-layer and themed**.

1. **Dock Street** — Collector Gant. Film.
2. **The Intake Lot** (survivor) — Lot Hydra.
3. **The Fire Escapes** — Lease Hawk.
4. **Group Circle** (survivor) — The Facilitator.
5. **Neon Exchange** — Agent Prime.
6. **The Waiting Room** (survivor) — Skinwalker miniboss (already sitting), then Number 88.
7. **Rail Bridge** — Conductor 9.
8. **City Hall** — Deputy Raven, then **Mayor Raven**.
9. **Copay Orchard** (brawl, farm/lake/forest/fields) — Scarecrow Ken, then Combine Brute.
10. **Sleet Hour** (survivor, snow) — Plow Cop, then Snowmobile.
11. **Raven Grid** (brawl, cyberpunk + chase) — Grid Kid, lemon courier chase, canal crash, then Invoice Chopper.
12. **Ledger Dive** (survivor, flooded vault / brine spa) — Vault Guard, then Cenote Elite.
13. **Invoice Pier** — Usher Prime, then **Dr. Splint**.
14. **The Processing Floor** — Adjuster Prime, then **The Family Plan**. Ending film.

Survivor hours sit between/after their pair. Solo thinner spawn + slower horde. Co-op denser. Seed encounters stay **solo 3 / coop 6** on every map.

### How to start a viewpoint tower

Every campaign map has a mast with the plaque **140M · HELL IS BELOW**. Walk up to it (Fire Escapes: the mast sits on the **roof**, not the unused street). **LIGHT** or **JUMP** starts a guided climb (Tomb Raider shrinking ring: red until the cling window, then green). Miss a ring and you fall (HP chip, try again). Pause does not fail a street cling. Raven Grid's tower stays at **x 1640**; the lemon van waits if you are on the mast. Camera follows the climb.

Pack **lunch** (buy at Blood Mart / street shop, loot a fridge, or find a unique secret) or sit anyway. Eat at 140m is a mission: fridge / shop / tin. Talks are yes / no / deflect — **LIGHT confirms the focused button**, not auto-yes. A no is never punished. Deflect is one short Father line. The farm / last-push talk is **Processing Floor only**. Descent rotates: parachute / zip / water / ledge — never the same twice in a row.

### How the parachute setpiece starts

1. File **Copay Orchard** (Scarecrow Ken, then Combine Brute).
2. On the results sheet tap **NEXT** (Sleet Hour). The game hops to the **Wellness Shuttle** fall — it is not an optional film, and **SKIP INTER-ACT FILMS** does not skip it.
3. Or, after the Combine is down, walk to the **Wellness Shuttle** at orchard **x ≈ 3320** and tap **SPECIAL**. That files orchard gold / results; **NEXT** still starts the fall.

The craft fails like the van. Long fall. **SPECIAL** toggles first person (visor). Mid-air hand slap (cling when green; **SHUTTLE RIP** lengthens the window). Host hops Join into Sleet with `broadcast_begin`. You land in **Sleet Hour**, a survivor hour. **PAUSE** shouts **WATCH THE FALL** and does not skip.

### How the skinwalker film starts

1. File **Neon Exchange** (Badge Broker, then Agent Prime).
2. On the results sheet tap **NEXT** (The Waiting Room). The game hops to the **skinwalker film** — human and a clinic dog first, then the slip. **SKIP INTER-ACT FILMS** does not skip it.
3. **LIGHT / JUMP** advances a beat. **PAUSE** shouts **WATCH THE SLIP** and does not skip.

Dad still says the word because the son asked a hundred times with trash photos. In the Waiting Room the dog is already sitting. Get close, hit it, or wait for the elite pack. Unmask. Fight the shapeshift set. **FILE** it. Number 88 still closes the hour.

### How the Raven Grid chase starts (and ends)

1. File **Grid Kid** (miniboss). Toast: steal the lemon clinic courier.
2. Walk past **x 1320**. The van spawns. **The Son drives**, **The Father rails 360°**. SPECIAL swaps. Solo: stick steers, shoot 360, SPECIAL hops rail. Not a mil truck.
3. Mix: on-foot before the steal, van through the underpass, then **forced onto a ramp**.
4. **Slow-mo** from in front of the ramp: debris, enemies, the lemon **skewed / tumbling / upside-down**. Close-ups: Father **NOOOO**, Son **AAAA**.
5. New camera. The van **crashes on the far side of the canal**. Enemies do not follow.
6. Gameplay: they **crawl out of different spots**, talk (black humor), then **Invoice Chopper walks in**. The crash is the boss intro.

Wanted 1 = **Meter Maid** (scooter citation, extra). Wanted 2 = **Phone Ghost**. Wanted 3 = extra patrol. Wanted 4 = **Dumpster King**. Wanted 5 = heli spotlight. Smash a **billboard** and **Billboard Witch** walks in. Smash a **kiosk** and **Coupon Cart** rams. Smash a **cop car** and **Ticket Skipper** slides. Smash a **booth** and a **pipe** drops. Smash a **fridge** and **Fridge Imp** bites. Smash a **hydrant** and a **geyser** launches you while **Hydrant Cop** tickets the spray. Smash a **mailbox** and **Envelope Clerk** stabs with certified mail. Smash a **newsstand** and **Paper Boy** rams. Smash a **vending** machine for a throwable **can**. Smash an **oil drum** (SoR4 barrel) and it **explodes** — throw a punk into it — then **Oil Ghost** arcs invoices. Smash a **manhole** and steam launches you while **Steam Mole** bills the lid. Bounce an **awning** and **Awning Acrobat** kicks from the canvas. Bounce a **car hood** and **Hood Hopper** kicks the bumper. Vault a **bench** and **Bench Clerk** still wants you to sit. Swing a **streetlight pole** and **Pole Clerk** bills the orbit. Grind and **Rail Rat** sparks. Wall-run and **Wall Kid** kicks. Jump during a wall-run for a **WALL KICK**. Down+heavy **DIVE** that lands **slam-bounces**. First **slide** of the night hires **Slide Clerk**. **Lottery Goon** drops a gem. Seed encounters stay **solo 3 / coop 6**.

Smashable **booths / kiosks / dumpsters / fridges / billboards / hydrants / mail / news / vending / oil drums / manholes** keep the combo on lights (SoR4 barrels) and pop scrap on heavies. Oil drums detonate on a heavy or a thrown body. Manholes launch you on a geyser and chip nearby punks with **STEAM LID**. Throw a **pipe / board / knife / envelope / chain / crowbar / clipboard / stapler / invoice star** (SoR4 throw-and-catch): tap THROW again to **catch**. **INVOICE STAR** is legendary and secret-locked (City Hall extra tin). **Nailgun** shoots like the pre-owned 9. **WEAPON CATCH** card boomerangs the pipe once. Heavy vs a telegraphing punk is a **CLASH** (Huntdown katana, billed). First three parry frames are a **perfect parry** (SNAP loads). Throw a punk into a prop for a **wall bounce**. Tap block in a 10-frame window for a **parry** counter. Two bodies near a SNAP victim = **Dual SNAP**. Finish / stomp 3 gets a **kill cam** (skipped during the Raven Grid crash). Blood tints per biome (snow / brine / neon / sap). Clash, geyser, dive, drum, manhole, and slide spray extra blood; kill cam / named slow-mo still skip the crash.

Parkour toys on every map: **dumpster lift, billboard trampoline, wall-run, grind, cart, awning bounce, scaffold hang, streetlight pole, car hood, bench vault**. Hydrant or manhole smash leaves a short **geyser**. Jump during a wall-run for a **WALL KICK**. Raven Grid extras sit **before the ramp** (nothing in the canal). Perfect tricks get a named slow-mo.

## Pinball, results, death

Everything scores. Father vs Son on the same run (HUD bottom, pause overlay). After every act and on death: results sheet with table scores, winner line, **account XP bar**, toasts, HIGH TABLE if you beat the fridge. Death still grants XP. High table lives on the Family Profile. Versus ends with the same XP bar energy.

## Avatar / rarity

Locker is clothes / hats / shoes plus Profile **frames / banners / badges**. Every piece has stats and three upgrades. **Common → Uncommon → Rare → Epic → Legendary** on cards, gear, CBT, awards, shop, pickups, crates, cosmetics, research, dojo ranks. Colored borders. Legendary juice. Pause shows the pinball table.

## Options / Reset

Hub **OPTIONS**: volumes, gore, PIN, rooms URL, skip films, **RESET PROGRESS**. Reset asks confirm (**THIS IS GROWTH**), writes `user://family.json.bak` first, then wipes.

## Host / Join

**The Son (Stockholm):** Run tab → **HOST (THE SON)** → text the 6-character code.

**The Father (Dalarna):** **JOIN (THE FATHER)** → paste code → **Connect**. Direct, then automatic relay.

Connect pipeline: LAN UDP → UPnP/direct (~3 s) → TCP relay. Room code is the product. Ports unchanged: game `24567`, rooms HTTP `8787`, relay `8789`.

## Controls

| Action | The Son (P1) | The Father (P2, after join) |
| --- | --- | --- |
| Move | A/D, W/S | Arrows |
| Jump / glide | Space (hold in air) | Ctrl |
| Light / string | J | `.` |
| Heavy (hold to charge) | K | `/` |
| Special (cape / web) | L | `;` |
| Shoot (batwing / snare) | O | `'` |
| Dash / slide (down+dash) | Shift | Alt |
| SNAP / revive | F | N |
| Pause | Esc | P or Start (P also joins if the chair is empty) |

**Pad (Xbox layout).** 0 pads: keyboard. 1 pad: that pad is P2 once he exists; P1 stays keyboard. 2 pads: pad 0 The Son, pad 1 The Father.

| Action | Button |
| --- | --- |
| Move | Left stick / D-pad (radial deadzone 0.22) |
| Jump / glide | A |
| Light / SNAP confirm | X |
| Heavy | Y |
| Special | B |
| Shoot | RB |
| Block | LB |
| Throw | LT |
| Dash / slide | RT (RT + down = slide) |
| SNAP | Right stick click |
| Pause / drop-in | Start |

On a remote Join, The Father uses **P1** on his machine. The Son stays host-authoritative.

## Hub

Clinic, Run, Build, Locker, Awards. Family Profile at `user://family.json`.

### Profile / account

**Top-left avatar** (names + LV) opens **Family Profile**. First launch still files names (intake). Rename lives on the Profile.

Profile shows account level, XP bar, avatar card with **frame / banner / badge**. Equip Steam-like **badges** as proof. Swap **avatar frame**, **profile banner**, and **badge**. Unlocks come from in-game accomplishments (runs, stomps, tricks, dojo masters, finale).

Red **new** dots sit on the avatar, the HnT logo, **every hub tab**, the run HUD banner, and the new item itself until you open Profile / the camp sheet and look at the reward. Big unlock logos always print **YOU GOT** plus the reward. Account **level-up** is a full overlay (XP bar, names, +8 gold, frame check).

### Camp buildings (Clinic tab)

The camp grid is the home screen. **BUILD** plays a carpenter animation in front of you. Upgrade expands stock.

| Building | Where | What |
| --- | --- | --- |
| **Camp Shop** | Clinic camp → BUILD CAMP SHOP → **OPEN** | Chests, lucky wheel, slots. Upgrade the stall: claw at lv2, scratch cards at lv3. Always shows what you got. |
| **Quick Patrol** | Clinic camp → BUILD QUICK PATROL → **OPEN** | **2×/day**, 12 minutes. Idle gold + XP + a coil **while the game is closed and while you play**. Claim when the alley comes home. |
| **Research Center** | Clinic camp → BUILD RESEARCH CENTER → **OPEN** | Silencers, extended mags, hollow rounds, recoil pads, tape wrap. Spend gold + parts. |
| **Martial Arts School** | Clinic camp → BUILD MARTIAL ARTS SCHOOL → **OPEN** | Learn / upgrade moves (uppercut, roundhouse, face stomp, vaults, landing roll). Rank 3 = master + shaolin badge. |
| **Workshop** | Clinic camp → BUILD WORKSHOP → **OPEN** | Craft from scrap coil, clinic thread, invoice ink. Gear + clothes + equipment are one character build. |
| **Blood Fridge** | Clinic camp → BUILD BLOOD FRIDGE → **OPEN** | Between-run snacks. Gold in. Bandage / tape / fizz / tutoring bar packed for the next spawn. |
| **Streak Locker** | Clinic camp → BUILD STREAK LOCKER → **OPEN** | Consecutive files. Chests at 3 / 5 / 8. Die and the rail resets. Claim required. |
| **Invoice Lottery** | Clinic camp → BUILD INVOICE LOTTERY → **OPEN** | Two gems, one spin. Civic engagement, billed as luck. |
| **Punching Bag** | Clinic camp → BUILD PUNCHING BAG → **OPEN** | Eight seconds. LIGHT or click the dummy. Combo toaster. Gold for hits. |
| **Warrant Fax** | Clinic camp → BUILD WARRANT FAX → **OPEN** | Once a day. Fax a complaint. +8 gold and packs intake ice for the next spawn. |
| **Tip Jar** | Clinic camp → BUILD TIP JAR → **OPEN** | Five gold. Toss it. Gem, snack, or the jar eats it. |
| **Lost and Found** | Clinic camp → BUILD LOST AND FOUND → **OPEN** | Once a day. Pack a pipe into the next spawn. |
| **Payphone** | Clinic camp → BUILD PAYPHONE → **OPEN** | Once a day. Dial City Hall. +8 gold. Mayor Raven still talks. |
| **Water Cooler** | Clinic camp → BUILD WATER COOLER → **OPEN** | Once a day. +4 gold. Packs a fizz. The gossip is billed. |
| **Coat Check** | Clinic camp → BUILD COAT CHECK → **OPEN** | Once a day. Packs intake tape for the next spawn. |
| **Time Clock** | Clinic camp → BUILD TIME CLOCK → **OPEN** | Once a day. Punch in. +6 gold. The shift is billed. |
| **Bleach Closet** | Clinic camp → BUILD BLEACH CLOSET → **OPEN** | Once a day. Packs a fizz for the next spawn. |

Patrol, research, and the dojo are **camp buildings**, not extra bottom tabs. Front Desk is already built (Profile). Street Map is already built (Run). The Blood Fridge is now a real snack sheet, not a dead plaque.

## Combat / parkour (this slice)

SoR4 mix: duck, jump, air attacks, uppercut (up+heavy), roundhouse (two lights then heavy), air mix (special in the air), dive (down+heavy in the air) that **slam-bounces** on a hit. Unique finishers score more. **Three stomps on a crushed face**: smash / pop / splash, brain on three. **Parry** (tap block on the incoming hit). **Perfect parry** (first three frames) loads SNAP. **Clash** a telegraphing punk with a heavy. **Throw and catch** pipes (SoR4). **Revenge** after you eat a hit — next strike restores HP like a SoR4 special follow-up. **Wall bounce** and **ground bounce** throws. **Dual SNAP**. **Cart ride**, **awning bounce**, **pole swing**, **hood bounce**, **bench vault**, **grind**, **wall kick**, **slide** (Sunset Overdrive / Vector, billed as copays). **Geyser** from a smashed hydrant or manhole. **Oil drums** explode. Father vs Son SFX. Footsteps scale with speed, silent in air, louder on stumble. High land: **landing roll** (down or dash) or stumble / hard fall. Combo toaster pops at 5 / 10 / 20. Pause never skips the Raven Grid ramp-crash.

Guns: unique caliber, recoil, muzzle flash, sparks, bullet holes. Blood simulator: spray, drip, run, pool, stain. HP changes how injured they look and limp.

Parkour gates show **three named tricks** (Vector): just-jump is easy. Up = mid. Special / dash = hard. Perfect window +5–10% speed. Fail: stumble / hard fall / splat and minus points. Combo multiplier stays on the pinball table.

## Layout

```
scenes/     hub + intro, tutorial, fourteen acts, films, versus
src/        actors, story, survive, vs, juice, world, ui, coop, net
data/       story, kits, gear, buildings, awards, CBT, cards, shop, encounters, cosmetics, dojo, research, tricks, dopamine
tools/      hnt_rooms.py, synth_story.py, synth_kit.py
assets/     audio + icon + pixel sprites (Father, Dock Street, collector punk, skinwalker)
```

Encounter counts live in `data/encounters.json`. Recount from that file.

## Sprites

Timmie does not draw. Sheets live in `assets/sprites/`. **The Father** is an unemployed-dad casual: worn grey hoodie, grey sweatpants, sneakers — not a polo. `AnimatedSprite2D` on the existing fighter (Son stays the blockout body). Clips are 8–12 frames (never fewer than 6): idle, walk, parkour run, jump, duck, hurt, jab, cross, gut, heavy, front kick, side kick, roundhouse, uppercut, air mix, SNAP. Hitboxes, Host/Join, 3/6, crash, towers, parachute stay.

**Dock Street** is the only map with pixel tiles and smash/parkour props. Other maps stay blockout. Street punks use one collector-punk sheet. Skinwalker sheet is wired on Waiting Room if the frames load.

Re-slice after new atlases (sources in `tools/sprite_src/`):

```bash
python3 tools/slice_sprites.py
```

Contract: Project game plan. Superpolish2 lives in `.cursor/skills/superpolish2/`.
