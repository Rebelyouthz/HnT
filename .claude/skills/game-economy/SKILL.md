---
name: game-economy
description: Gold, gems, rep, XP and every shop in this game - where currency comes from, what it buys, balance targets and how to verify purchases actually work. Use when changing prices, drops, rewards, shops (BUILD tree, dojo, halfway cart, pawn shop, workshop, locker) or when asked whether the economy is balanced.
---

# Economy

## Audit procedure
1. List every **source**: `grep -rn "add_gold\|add_gems\|add_rep" src` (enemy
   drops in `punk.gd _drops`, LootDrop coins, side jobs, awards/claims,
   stage results, coping hour).
2. List every **sink**: `grep -rn "spend_gold\|spend_gems\|try_spend\|cost" src data`
   (BUILD nodes, dojo training, halfway cart `data/cart.json`, pawn shop,
   workshop, gear, research).
3. Estimate income per stage (normal play, no deaths) from encounter counts
   and drop rates; compare to prices.
4. Verify each purchase path in code: price shown == price charged; can't buy
   when short (button says NEED GOLD and is disabled); owned/max state is
   saved (`FamilyProfile.save()`); effects are actually read by gameplay.

## Targets
- First stage clear (~5-8 min) buys **one** meaningful upgrade (BUILD tier 1
  or one dojo move), not three, not zero.
- The halfway cart is a tease on stage 1 (cheapest item just out of reach on
  an average run), affordable from stage 2.
- Gems are rare (milestones, awards, elites/chests); they gate cosmetics and
  late nodes, never the core moveset.
- Prices scale roughly 1.3-1.5x per tier; nothing costs more than ~3 stages of
  income except long-term goals.
- No dead currencies: every currency the HUD shows has something to buy now
  or clearly soon.
