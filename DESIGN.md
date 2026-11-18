# VOIDSTORM: campaign design (v3)

## Direction (from playtests)
- v1, an abstract sector map with menus: the loop was unclear and there was no challenge. Replaced.
- v2: each planet is a real-time build & defend colony game. Kept as the base.
- **v3: every planet plays in a different gameplay style**, built as its own cart (PICO-8 `load()` chains
  carts, and each gets its own 8192-token budget). Original designs inspired by genre mechanics:
  1. **original_colony_defense_1** (planet Verdant): real-time colony defense plus a trade run. **Playable.**
     Named for what it is: it drifted far from classic colonization gameplay.
  2. **colonization_1** (planet Nova Terra): turn-based colonize / trade / wipe out the hives. **Playable.**
  3. **heroes_1** (planet Ironveil): hero-led turn-based strategy on one map. **Playable.**
  4. **conquest_1** (planet Tessar): multi-faction planetary conquest 4X-lite. **Playable.**
  5. **bug_battle_1** (planet Mandible): real-time-with-pause squad bug battles. **Playable.**
  6. **wasteland_1** (planet Cinder): post-apocalyptic turn-based RPG. **Playable.**
  7. **mmo_rpg_1** (planet Eldmoor): pocket fantasy MMO-style action RPG. **Playable.**
  8. **survivors_1** (planet Swarmfall): horde-survival auto-shooter. **Playable.**
  9. **lane_duel_1** (planet Ridgeback): one-lane turn-based duel with telegraphed enemy intents. **Playable.**
  10. **grid_tactics_1** (planet Bastion): grid-tactics mech defense. **Playable.**
  11. **hex_territory_1** (planet Shardmere): hex territory strategy with towers and knights. **Playable.**
- **Rule: polish each planet until it is genuinely fun before starting the next style.**
  Each planet gets its own cart named after its style.
- **Naming:** the `original_` prefix is only for our own mechanics (e.g. `original_colony_defense_1`).
  Demakes of a genre's classic mechanics get no prefix (e.g. `colonization_1`).

## Carts and sources
- `voidstorm.p8`: title + Arcade (`common.lua` + `arcade.lua`). Z on the title loads the campaign.
- `original_colony_defense_1.p8`: planet Verdant (`common.lua` + `original_colony_defense_1.lua`).
- `colonization_1.p8`: planet Nova Terra (`common.lua` + `colonization_1.lua`).
- `survivors_1.p8`: planet Swarmfall (`common.lua` + `survivors_1.lua`).
- `heroes_1.p8`: planet Ironveil (`common.lua` + `heroes_1.lua`).
- `lane_duel_1.p8`: planet Ridgeback (`common.lua` + `lane_duel_1.lua`).
- The title screen has a mode menu that loads each cart. The build strips shared helpers a cart doesn't use.
- Launch with `./play.sh`: it passes `-root_path` so the carts can `load()` each other.
- `build_cart.py` assembles the carts. All share one Krea-generated sprite sheet.

## original_colony_defense_1 (planet Verdant)
**Goal:** grow a colony, trade with the Hegemony homeworld **Aurum**, build **liberty**, declare
independence, and survive the war (3 war nights, then the Hegemony flagship).
**Lose:** the HQ is destroyed, or your ship runs out of lives.

### The loop
1. **Colony (real time on the surface).** Fly your ship over a 16×14 tile map.
   - Z auto-fires at the nearest target.
   - X on a tile opens the build menu; X on the HQ opens the HQ menu.
   - Buildings need colonist workers and produce goods every tick during the day.
2. **Load & launch (HQ menu).** Choose how much food, ore and crystal goes into the cargo hold
   (starts at 12 units).
3. **Voyage (shooter, about 20 s each way).** Asteroids and pirates. A hit costs 2 cargo units, or a
   colonist aboard on the way home, or a life if there's nothing to lose.
   **The colony keeps running while you're away:** nights still fall and aliens still attack, and only
   turrets defend it. That risk is the core tension.
4. **Aurum market (paused).** Cargo is sold automatically.
   - **Selling:** each good's price drops by 1 for every 5 units sold, and recovers each day.
     The Hegemony takes its **tax %** of every sale.
   - **Buying:** colonists (price rises each purchase), ore crates, a bigger cargo hold, or a hull repair (+1 life).
   - **Tax hikes:** after a sale the Hegemony may raise the tax. You choose:
     - **Accept** the new rate.
     - **Boycott** your best-selling good. It can never be sold again, but you gain +15 liberty.
5. **Fly home** with your purchases and land.

### Colony rules
| Building | Terrain | Cost (ore/cry) | Worker | Effect |
|---|---|---|---|---|
| Farm | grass | 2/0 | yes | +1 food per tick |
| Mine | rock | 1/0 | yes | +1 ore per tick |
| Harvester | crystal | 3/0 | yes | +1 crystal per tick |
| Habitat | grass/rock | 3/1 | no | +3 colonist capacity |
| Turret | grass/rock | 2/2 | no | auto-defends |
| Assembly | grass/rock | 4/2 | yes | +1 liberty per tick |

- **Day:** 25 s, with a production tick every 4 s.
- **Night:** each alien nest sends crawlers that chew buildings. Night ends when the wave is cleared.
- **Dawn:** every colonist eats 1 food; a shortage kills colonists. Leftover food grows the colony up to capacity.
- **Nests:** 60 HP, and they spit at your ship when it's close. Destroying one gives +3 crystal.
- **Independence:** declare it at 100 liberty (HQ menu). The market closes, then come 3 war nights of
  Hegemony saucers, and on the last one the **flagship**. Destroy it to win.

### Visuals / VFX
Native 8×8 terrain patches cut from the Krea textures, animated water and crystal sparkle, a night
palette with lit windows, nest pulse, turret muzzle flashes, production popups, explosions, shockwaves
and screen shake, cargo-loss sparks, and a warp starfield on the voyage.

## colonization_1 (planet Nova Terra)
A turn-based demake of the classic colonize-and-trade loop, simplified: **there are no rival colonizers
at all**. The only opposition is the planet's alien hives.

**Goal:** wipe out every alien hive village (7 per map).
**Lose:** every colony is overrun, or turn 150 passes with hives still alive.

### Map and turns
- 24×20 tile world with a scrolling camera and fog of war. Terrain: plains, hills (ore), crystal
  fields, sea, and alien **hive villages**.
- Each turn, units move one by one:
  - **Arrows** move the active unit.
  - **X** selects the next unit that can still move.
  - **Z** opens its order menu: found colony, join, arm soldier, board ship, fortify, open colony,
    skip, end turn.
- Units: **colonist** (1 move), **soldier** (colonist armed with 20 guns, strength 2),
  **ship** (6 moves, sea only, carries units and up to 100 cargo).

### Colonies
- Founded on land, at least 2 tiles from another colony. A colony works the 8 tiles around it plus its
  centre tile, which gives 2 food and 1 ore for free.
- **Colony screen:** arrows move spatially between slots. Z picks up or places a worker; the
  **next>** button switches colony.
  - **Tile jobs:** plains 3 food, sea 2 food, hills 3 ore, crystal 2 crystal. Experts double.
  - **Buildings:** armory (3 ore → 3 guns), refinery (3 crystal → 3 power cells),
    **watch hall** (+1 colony defense per worker).
- Every colonist eats 2 food. 20 stored food → a new colonist is born. The growth bar shows the turns left.
- The goods row shows each good's net change per turn. The preview and the real production share
  one calculation.

### Aurum (the mother world)
- Sailing east into the 2-column **space lanes** departs. Each way takes 2 turns, and each arrival is
  the **arcade flight** from colony defense. A hit costs 10 of the biggest cargo, or a colonist aboard
  on the way home.
- Market: sell food, ore, crystal, guns and cells (refined goods are worth far more, and prices fall
  as you sell); buy 20 guns; recruit colonists (the price rises each time).
- The Hegemony's tax takes a cut of every sale and rises after big sales.

### Alien hives (the enemy)
- Each village has **3 HP**. A soldier attacking it rolls soldier strength vs warrior strength, and
  each win removes 1 HP. Destroying a village gives +100 credits and angers the remaining villages.
- **Visiting** a village with a colonist trains them as an expert (farmer, miner or cutter), once per
  village. Learn first, then destroy.
- Villages near colonies (within 4 tiles) grow **angry** and spawn **hive warriors** (up to 2 per
  village; spawn chance grows with anger).
- **Warriors** hunt the nearest colony or land unit within 7 tiles, otherwise they wander.
  - **Attacking a unit:** a strength roll. A beaten colonist dies; a beaten soldier is disarmed (back to colonist).
  - **Raiding a colony:** a roll against a soldier defender, or else the colony's militia
    (1 + workers÷3 + watch hall workers). If the raid wins, goods are stolen and a colonist dies half the time.
    A colony with no colonists left is overrun.
- Warrior strength: 1.5 + turn/40, so the hives get tougher over time. Anger decays when no colony is
  near. A village fields 1 warrior at a time (2 when very angry).
- **Combat:** roll a/(a+d). Soldier 2, colonist 1, ×1.5 when fortified or in a colony.

### Art
Reuses the Krea sheet: terrain, nests as villages, crawlers as hive warriors, colonist, freighter as the
ship, dome as the colony, building and goods icons. New Krea icons: guns and power cells.

## survivors_1 (planet Swarmfall)
A demake of the horde-survival genre: you only move, and the weapons fire themselves. All weapons and
names are original sci-fi takes; no characters, items or art from any specific game.

**Goal:** survive **5:00** on Swarmfall, then destroy the Hegemony **flagship** that arrives at 5:00.
**Lose:** HP reaches 0.

### Controls
- Arrows move the colonist (the 8×8 colonist sprite) across an endless scrolling surface.
- Weapons fire automatically.
- On level up the game pauses: up/down picks 1 of 3 offers, and Z takes it.

### Growth
- Enemies drop **XP crystals** (blue 1, green 3, red 10). Crystals inside your **pickup range** fly
  to you.
- Each level needs `5 + level×4` XP and offers 3 random picks: a new weapon, a weapon upgrade
  (max level 6), or a passive (max level 5). You carry at most 4 weapons.
- Rare **ration** drops heal 3 HP.

### Weapons (start: pulse blaster)
| Weapon | Behaviour | Per level |
|---|---|---|
| Pulse blaster | auto-aims bolts at the nearest enemy | +1 bolt, faster; pierces from lv 4 |
| Orbiters | shield orbs circle you, hitting what they touch | +1 orb, bigger orbit |
| Nova | periodic shockwave hitting everything near | bigger radius, more often |
| Arc | lightning jumps between nearby enemies | +1 chain |
| Mine layer | drops mines that blast crowds | bigger blast, more often |

### Passives
Speed (+15% move), Magnet (+pickup range), Armor (+2 max HP, −damage taken), Overclock (−10% weapon
cooldowns), Power (+25% damage).

### Horde
- Spawn rate and enemy HP rise over time, capped at 110 enemies on screen.
- Enemy mix: crawlers (from 0:00), drones (1:00), divers that rush you (1:30), saucer elites (2:00
  ring ambush).
- **3:00:** the hive mothership mini-boss. **5:00:** the Hegemony flagship (final boss).

### VFX
Hit-flash, damage numbers on big hits, explosions, shockwave rings, lightning arcs, a level-up burst,
screen shake, a crystal magnet trail, and an invulnerability blink.

### Art
All existing Krea sprites: colonist (player), crawlers, drones, divers, saucers, boss, flagship, terrain
tiles (ground), icons for the level-up cards. No new generation needed.

## heroes_1 (planet Ironveil)
A demake of hero-led turn-based strategy, with local gameplay only: one hero, one town, one map. The
faction, units and names are original.

**Goal:** march your hero's army to the **hive capital** and destroy the mothership in the final battle.
**Lose:** your hero's army is wiped out, or day 90 passes.

### Adventure map
- 24×20 tile map with a scrolling camera and fog of war (3-tile sight).
- **Terrain:** plains (1 movement point), rough hills (2), crystal fields (1), sea (impassable).
- The hero has **14 movement points per day**. Arrows move one tile; Z interacts (opens the town);
  X ends the day.
- **Objects:**
  - **Resource piles** (gold, ore, crystal): stepping on one picks it up.
  - **Mines:** an ore drill, a crystal harvester and a trade post (gold). Step on one to claim it;
    it pays every day.
  - **Caches:** take 500 gold (Z) or 400 XP (X).
  - **Neutral hive stacks** guarding the map. They get stronger the farther they are from your town;
    stepping onto one starts a battle.
  - **Hive capital:** the final battle.
- **Weeks:** every 7 days the town's dwellings grow new recruits.

### Town (colony HQ)
- Income: 500 gold per day, 1000 after building the **Council**.
- **One building per day:** dwellings for tiers 2–5 (tier 1 is pre-built) and the Council.
  Each costs gold, ore and crystal.
- **Recruit** from built dwellings (Z buys one; hold Z to keep buying). Weekly growth per tier:
  12 / 8 / 5 / 3 / 1.
- The army has up to 5 stacks, one per unit type.

### Units
| Tier | Unit | HP | Atk | Def | Dmg | Spd | Special | Cost |
|---|---|---|---|---|---|---|---|---|
| 1 | Militia | 5 | 2 | 1 | 1–2 | 4 | | 60g |
| 2 | Rifleman | 8 | 4 | 2 | 2–3 | 4 | ranged | 130g |
| 3 | Drone | 15 | 5 | 5 | 3–5 | 7 | | 260g |
| 4 | Saucer | 32 | 8 | 8 | 6–10 | 5 | | 600g |
| 5 | Lander | 90 | 14 | 12 | 16–24 | 6 | | 2000g + 2 cry |

Hive creatures: crawler (weak swarm), spitter (ranged), diver (fast), brute (tough), and the
**mothership** (the final boss).

### Battle (tactical, turn-based)
- 8×6 grid. Your stacks start on the left, the enemies on the right.
- **Turn order:** each round, stacks act in speed order (on ties, yours go first).
- **Your stack's turn:** move the cursor; the reachable cells (within its speed) are dotted.
  - Z on an empty cell: move there.
  - Z on an enemy: melee (the stack auto-moves next to it), or shoot with a ranged unit
    (half damage when an enemy is adjacent).
  - X: defend (+30% defence until its next turn).
- **Damage:** count × random(min..max) × (1 + 0.1 × (attack − defence)), clamped to 0.3×–3×.
  Your hero adds their attack and defence to your stacks.
- **Retaliation:** a defender strikes back once per round when hit in melee.
- Stack HP is a pool, so losses reduce the count.
- **AI:** ranged stacks shoot the nearest target. Melee stacks close in and attack.
- **Winning** gives XP (the total HP of the enemies killed). The hero levels up every 1000×level XP:
  +1 attack and +1 defence.

### VFX
Hit flashes, damage numbers, death explosions, projectile streaks, a pulsing active-stack highlight,
a cursor marker, and a level-up burst.

### Art
Existing Krea sprites only: colonist (militia, and the rifleman in red), drones, saucers, ship (lander),
crawlers, divers, boss, terrain, mines, icons.

## lane_duel_1 (planet Ridgeback)
A demake of the one-lane tactical duel. Everything happens on a single 9-cell ridge. Every enemy
**shows its next move** (intent and countdown) and the cells it will hit, so each turn is a
positioning puzzle. Cards, enemies and setting are original.

**Goal:** win 7 fights plus the boss (the hive mothership).
**Lose:** HP reaches 0. One life per run.

### Turn
1. You take **one action**. Every action costs a turn.
   - **Left/right:** step one cell; this also sets your facing.
   - **X:** turn around.
   - **Up/down + Z:** use the selected card immediately, or **Wait**.
   (A queue-and-fire variant was tried; the instant version plays better. The queue code is archived in
   `archive/lane_duel_1_queue.lua`.)
2. Then every enemy resolves, in lane order:
   - **Wind-up countdown reaches 0:** it strikes its telegraphed cells.
   - **Otherwise:** the countdown ticks, or it steps toward you (divers step 2).
3. Enemies with no intent pick a new one: attack if you're in range, else move.

The cells about to be hit are **outlined in red**, with the countdown shown on the enemy.

### Cards (3 slots, plus Wait)
| Card | Effect | Cooldown |
|---|---|---|
| Blade | 2 damage to the adjacent cell in front | 0 |
| Pike | 1 damage to the 2 cells in front | 1 |
| Rifle | 1 damage to the first enemy in front, any range | 2 |
| Dash | jump over the adjacent enemy, landing behind it, and hit it for 1 | 2 |
| Shield | block the next hit | 3 |
| Charge | 3 damage to both adjacent cells | 4 |

- **Backstab:** hitting an enemy that faces away from you deals **double** damage.
- You start with Blade, Pike and Rifle.

### Enemies (hive)
| Enemy | HP | Intent |
|---|---|---|
| Crawler | 2 | bite the front cell, wind-up 1 |
| Spitter | 2 | spit up to 3 cells ahead, wind-up 2 |
| Diver | 2 | moves 2 cells, bites with wind-up 1 |
| Brute | 5 | slam 2 cells in front for 3 damage, wind-up 2 |
| Mothership (boss) | 14 | beam across the whole lane in front (wind-up 3), or spawn a crawler |

Enemies enter from both ends of the lane, more of them each fight.

### Between fights
Pick 1 of 3:
- a new card (replaces the selected slot)
- +1 damage to a card
- heal 3
- +2 max HP

### VFX
Telegraph outlines, intent icons with countdowns, hit flashes, damage numbers, slash streaks, dash
trails, shield bubble, explosions, screen shake.

### Art
Existing Krea sprites: colonist (player), crawler, mine (spitter), diver, asteroid (brute), boss,
and icons for the cards.

## grid_tactics_1 (planet Bastion)
A demake of grid-tactics mech defense: protect the colony's power grid from hive bugs on an 8×8 board.
Every enemy attack is **telegraphed a turn ahead**, and most weapons **push**, so each turn is a
puzzle about shoving bugs out of their own attack lines.

**Goal:** survive 3 missions of 5 rounds each. **Lose:** grid power reaches 0, or all 3 mechs are
destroyed.

### Board
- 8×8 tiles: ground, mountains (block movement and pushes), water (bugs pushed in drown),
  **buildings** (each hit costs 1 grid power), and **spawn cracks** (bugs emerge next round).
- **Grid power:** starts at 7 and carries over between missions.

### Round
1. **Enemy move (animated):** one at a time, each bug walks toward buildings and mechs. As it
   arrives, its locked attack (direction and target cells) appears in red. Then the spawn cracks
   for the next emergence appear.
2. **Your phase:** each mech may move (up to 3 tiles, around obstacles) and then fire once.
   - Arrows move the cursor.
   - Z on a mech selects it, then Z on a highlighted tile moves it, then Z on a target fires.
   - X skips firing (or cancels a selection). X with nothing selected ends the turn.
3. **Enemy attacks** resolve in order from each bug's **current** position, in its locked direction.
   A pushed bug may hit another bug, or nothing at all.
4. **Emergence:** bugs crawl out of the cracks. A unit standing on a crack blocks it and takes 1 damage.

### Mechs (4 HP each)
| Mech | Weapon |
|---|---|
| Brawler | punch an adjacent tile: 2 damage, push 1 away |
| Gunner | projectile in a straight line: hits the first thing, 1 damage, push 1 |
| Artillery | lob to a tile 2+ away in a straight line: 1 damage there, push the 4 neighbours outward |

**Bumps:** a unit pushed into a mountain, building, unit or the board edge takes 1 damage, and so does
whatever it hit.

### Bugs
| Bug | HP | Attack |
|---|---|---|
| Crawler | 2 | adjacent, 1 damage |
| Spitter | 2 | projectile, 1 damage |
| Brute | 4 | adjacent, 3 damage |

Each mission adds more bugs. New bugs per round = mission number (1, 2, 3).

### VFX
Telegraph lines and target markers, push trails, bump sparks, building explosions with a power-bar
flash, drowning splash, mech hit flash.

### Art
Existing Krea sprites: lander, freighter and saucer as mechs; crawler, mine (spitter) and asteroid
(brute) as bugs; habitat and farm as buildings; terrain tiles.

## conquest_1 (planet Tessar)
A demake of multi-faction planetary conquest. Three powers start on one planet: you (the colony),
the **Hive** and the **Hegemony**. Each turn you expand, grow, arm and attack, territory by territory.

**Goal:** control **60%** of the land territories, or wipe out both rivals.
**Lose:** you lose every territory, or a rival reaches 60% first. If nobody has won by turn 60,
the most territories wins.

### Map
8×6 territories, each with a terrain type:
| Terrain | Produces (per pop) |
|---|---|
| Plains | food |
| Hills | ore |
| Crystal fields | credits |
| Sea | impassable, can't be owned |

Each territory has **pop** (1–6), a garrison **army**, an optional building, and an owner.

### Economy (each turn, per faction)
- Every territory adds +1 credit, plus pop × its terrain yield (food/ore/credits).
- **Food:** each pop eats ½. With a food surplus, each territory gains +1 pop every 4 turns. With a
  shortage, territories lose pop.
- **Buildings** (one per territory, 30 credits): farm / mine / bank give +50% of that territory's
  output. A fort gives +2 defence.

### Actions (one per own territory per turn)
Arrows select a territory; Z opens its menu; X ends the turn.
- **Train:** 10 ore + 5 credits → army +2.
- **Settle:** needs pop ≥ 2. 1 pop moves to an adjacent unowned land territory, which becomes yours.
- **Attack:** pick an adjacent enemy or unowned territory. All but 1 of the army marches.
- **Build:** farm, mine, bank or fort.

### Combat
Rounds of dice: each side rolls once per unit (up to 6 per round), and a hit lands on a roll of
5–6 (4–6 for the defender with a fort). It ends when one side has no units. A winning attacker
takes the territory with its survivors, and the pop drops by half.

### AI factions
Each AI trains when it has the ore, settles any free neighbour, and attacks a weaker neighbour
when its army is at least 1.5× the defenders.
- **Hive:** aggressive. It prefers attacking.
- **Hegemony:** economic. It prefers building and settling.

### VFX
Faction-coloured borders, army counters, attack arrows, dice clashes with explosions, capture flash,
pop pips, turn banner.

### Art
Existing Krea sprites: terrain tiles (scaled up), colonist / crawler / saucer as faction army icons,
buildings (farm, mine, habitat, turret) as building icons.

## bug_battle_1 (planet Mandible)
A demake of squad bug battles. Your blue-shell colony fights the red hive across a meadow. You give
real-time orders, with a pause to plan.

**Goal:** win 3 battles. A battle is won when the red colony has no bugs and no food piles left.
**Lose:** all your bugs die.

### Controls
- Arrows move the cursor.
- **Z** on your bug: select it, or Z again to deselect. Z on empty ground with nothing selected
  selects your whole army.
- **Z** with a selection: on the ground it's a **move** order, on a red bug it's an **attack**
  order, and on a food pile it's a **capture** order.
- **X:** deselect, or with nothing selected, **pause/unpause**. Orders can still be given while paused.

### Bugs
| Bug | HP | Dmg | Speed | Notes |
|---|---|---|---|---|
| Ant | 6 | 1 | medium | spawns from food piles |
| Beetle | 16 | 2 | slow | tank: takes half damage from ants |
| Spitter | 5 | 1 | slow | ranged (30 px) |
| Gnat | 4 | 1 | fast | flies; each hit heals it by 1 |

Idle bugs auto-attack enemies that come within 20 px.

### Food piles
Capture a pile by keeping your bugs on it with no enemies nearby; the ring around it fills in your
colour. Every owned pile spawns an **ant** every 8 s, up to 14 bugs per side.

### Battles
1. Two piles, a small red squad.
2. Three piles, beetles and spitters.
3. Four piles, a red army of 12 including gnats.

You keep your surviving bugs between battles, plus 4 fresh ants.

### AI
Red bugs pair up on the nearest pile it doesn't own, and attack your bugs in range. Its gnats hunt
your spitters.

### VFX
Selection rings, order markers, spit projectiles, bite sparks, death splats (particles), capture-ring
fill, pause dither.

### Art
Existing Krea sprites with team palettes: crawler (ant), asteroid (beetle shell), mine (spitter),
drone (gnat), food icon (piles), grass tiles.

## hex_territory_1 (planet Shardmere)
A demake of classic hex territory strategy. The island starts as a patchwork of four kingdoms (yours
is blue). Connected land of one colour forms a **province** with a capital that banks its gold.
Grow, keep your armies paid, and take every hex.

**Goal:** own the whole island (every rival kingdom eliminated).
**Lose:** you have no land left.

### Provinces and gold
- A province of 2 or more hexes has a **capital hut** that stores its gold.
- **At the start of your turn** each province earns +1 gold per hex without a tree, and pays upkeep
  for its units:

| Unit | Upkeep | Strength |
|---|---|---|
| Peasant | 2 | 1 |
| Spearman | 6 | 2 |
| Knight | 18 | 3 |
| Baron | 54 | 4 |

- **Bankrupt:** if a province's gold would drop below 0, **all its units starve** and leave graves.
  The graves become trees next round.
- A unit standing on a hex that's cut off alone (a 1-hex "province") also starves.

### Units and capture
- **Buy:** Z on an empty hex of your province opens the buy menu: peasant (10 gold) or tower
  (15 gold; tower strength 2).
- **Upgrade:** drop a unit onto another of your units to merge them (strengths add, max 4).
- **Move:** each unit moves once per turn. Inside its own province it can go anywhere (clearing a
  tree uses the move). It can also step onto a hex **bordering** the province.
- **Capture:** an attacker takes a hex if its strength is **greater than** the hex's defence.
  Defence is the highest of: the units on that hex and on adjacent hexes of the same owner, towers
  (2), and capitals (1). Capturing a capital wipes out that province's bank.

### Trees
Trees block income. They spread to empty neighbouring land at random each round. A unit clears a tree
by moving onto it.

### Controls
- Arrows move the hex cursor.
- **Z** on your unit picks it up; Z on a target places it (move / merge / capture).
- **Z** on an empty own hex: buy menu.
- **X:** put the held unit back, or with nothing held, end the turn.

### AI kingdoms (red, yellow, green)
Each AI buys peasants while its income can pay for them, merges units into spearmen or knights when
blocked, and captures the weakest bordering hexes first (capitals first, then units).
AI turns are paced (a short pause per capture) so you can follow them.

### VFX
Province-coloured hexes, capital banners with gold counts, held-unit bob, capture burst, starvation
graves, tree growth sparkle.

### Art
Existing Krea sprites: colonist (peasant / spearman tint), drone (knight), saucer (baron), turret (tower),
dome (capital). Trees and graves are drawn procedurally.

## wasteland_1 (planet Cinder)
A demake of the classic post-apocalyptic RPG: a ruined colony world, a hub town with people to talk
to, quests with choices, a scavenged inventory, and **turn-based action-point combat**. The setting,
characters and quests are original.

**Goal:** recover the **water purifier core** from the Vault Ruins and bring it back to Rustwell.
How you get it is up to you.
**Lose:** HP reaches 0 (you can load the last checkpoint when you arrive in a new area).

### Character
- **Stats:** Strength (melee damage, carry), Agility (action points), Perception (hit chance),
  Charisma (dialogue options and prices). You start at 5 each and spend 5 extra points at character
  creation.
- **Leveling:** XP from kills, quests and successful checks. Each level gives +1 stat point and +3 max HP.
- **HP:** 20 + strength × 2.

### World (3 areas, one screen each, 16×13 tiles)
1. **Rustwell** (hub town). Merchant Vela trades for caps. Elder Orin gives the main quest. Kid
   Pip has a side quest: find his lost dog in the dunes.
2. **Ash Dunes:** raiders, radscorpions, scrap piles to loot, the dog.
3. **Vault Ruins:** turrets, the raider boss Gristle, and the purifier core.

Walk off a screen edge marked with an arrow to travel. Exploring is real-time: arrows move. Combat
starts when an enemy sees you.

### Combat (turn-based)
- Each side takes turns. You get **AP = 5 + agility÷2**.
  - Moving 1 tile costs 1 AP.
  - Attacking costs 3 AP.
  - Using a stimpak costs 2 AP.
- **Hit chance:** 50% + perception × 5% − distance × 4% (melee: 85%). Damage = the weapon's range
  of values (+ strength÷2 for melee).
- **Controls:** arrows move, Z attacks the nearest enemy in range (it cycles targets), X opens the
  combat menu (stimpak / end turn).
- **Enemies:** raider (pistol), radscorpion (melee, fast), turret (static, ranged), Gristle (boss,
  shotgun).

### Dialogue and quests
- Talk with Z next to a person. Each topic is a list of up to 3 replies, some gated by a stat check
  (e.g. `[CHA 7]`).
- **Main quest:** reach the purifier core. In the ruins, **Gristle** guards it. Kill him, or pass a
  **CHA 7** check to talk him into leaving (he'll ask for 100 caps if you fail and can pay).
- **Side quest:** find Pip's dog in the Ash Dunes and bring it back → stimpaks + XP.

### Items
- **Caps** (money).
- **Weapons:** knife, pistol, rifle, shotgun. You start with a knife and a pistol (equipped).
- **Armor:** leather (−1 damage taken), metal (−2).
- **Stimpaks:** +10 HP.
- **Scrap:** sell it to Vela.

The inventory screen opens with X while exploring (equip, use, view).

### VFX
Muzzle flashes, hit numbers, a blood/sparks burst, an AP bar, a hit-chance overlay on the target,
screen shake, and a dust haze in the dunes.

### Art
Existing Krea sprites: colonist (player, tinted), crawlers (radscorpions), drone (turret), saucer
(Gristle's rig), colony buildings (habitat, HQ, farm), terrain tiles, item icons (guns, cells, food,
coin, ore).

## mmo_rpg_1 (planet Eldmoor)
A demake of the fantasy MMO loop in one cart: a town hub, quest givers, respawning mobs, a hotbar
with cooldowns and cast times, tab-targeting, loot upgrades, chatty "other players", and a dungeon
boss with mechanics. The world, names and quests are original.

**Goal:** finish the quest chain and defeat **the Hollow King** in the Barrow dungeon.
**Death:** you respawn at the town graveyard with full HP (no game over).

### Controls
- Arrows move.
- **Z:** talk to a nearby NPC, otherwise **tab-target** (cycle the nearest enemies).
- **Hold X + a direction** casts a hotbar ability: ⬅️ Strike, ⬆️ Firebolt, ➡️ Mend, ⬇️ Nova.
  Moving interrupts a cast.
- **Auto-attack** hits your target while it's in melee range.

### Abilities (spellblade)
| Ability | Mana | Cooldown | Cast | Effect |
|---|---|---|---|---|
| Strike | 0 | 0.5 s | instant | melee, 4 + weapon damage |
| Firebolt | 10 | gcd | 0.8 s | ranged 60 px, 8 + 1.5 × weapon |
| Mend | 15 | 5 s | 1 s | heal 15 + 3 × level |
| Nova | 20 | 8 s | instant | hits everything within 24 px for 6 + weapon |

- **Global cooldown:** 0.5 s.
- **Mana** regenerates; HP regenerates out of combat.
- **Leveling:** levels 1–8; XP from kills and quests. Each level adds +HP, +mana and +damage.

### World
- **Overworld:** 32×24 tiles with a scrolling camera. Thornwick town is in the west (quest givers,
  graveyard). Then the Gloomwood (gloomfangs), the Spore Fen (spore spitters) and the Rocklands
  (brutes). The Barrow entrance is in the east.
- **Mobs** have levels, aggro radius 28 px, and leash back home (resetting HP) if you drag them
  80 px away. They respawn about 15 s after dying.
- **Other "players":** 3 adventurer NPCs wander, fight mobs and post in the chat box
  ("LFG barrow", "WTS cloth").

### Quests (❗ available, ❓ ready to turn in)
1. **Warden Elra: "Fangs in the Wood".** Kill 6 gloomfangs. Reward: a weapon upgrade and XP.
2. **Sage Thom: "Spore Samples".** Collect 4 spore sacs (dropped by spitters). Reward: an armour
   upgrade and XP.
3. **Warden Elra: "The Hollow King".** Requires level 4 or more. Enter the Barrow and defeat the
   boss. Reward: victory.

### Loot
Kills sometimes drop gear with an item level (common, rare, epic, colour-coded). Gear auto-equips
when it's better. Weapon ilvl adds damage; armour ilvl reduces damage taken.

### The Hollow King (dungeon boss)
- 400 HP.
- **Ground slam:** red circles telegraphed for 1.5 s, then they erupt. Get out of them.
- At 50% HP he summons 2 gloomfang adds.
- **Enrage:** after 90 s, damage ×2.

### HUD
Player and target frames (HP/mana bars, level), a cast bar, a hotbar with cooldown sweeps, a quest
tracker, and the chat box.

### VFX
Firebolt projectiles with trails, Nova ring, Mend sparkles, floating damage and heal numbers (crits
in yellow), level-up burst, loot beams by rarity, boss ground telegraphs.

### Art
Existing Krea sprites: colonist (player and NPCs, tinted), crawler (gloomfang), mine (spore spitter),
asteroid (brute), boss (Hollow King), habitat/HQ (town), nest (barrow entrance), terrain tiles, icons
for the hotbar.
