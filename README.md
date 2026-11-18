# Brainrot Buffet — roblox-brainrot-01

A 3D Roblox brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01). The player
walks a 3D picnic world, collects absurd food-animal hybrids off a conveyor, keeps them on their base where each earns
money per second, climbs a ladder of rarities, mutates them, rebirths for a permanent multiplier — and dashes home
when the Hunger Wave sweeps the map, or locks their base so rivals cannot steal their best characters.

## The loop

1. Characters spawn on the central conveyor and walk it. Click one to buy it (if you can afford it and your base has
   a free slot). It moves to your base and starts earning money per second.
2. Money ticks up from everything on your base. Buy rarer characters (Common → Rare → Epic → Legendary → Mythic →
   Secret). A spawn may be Golden (x2), Rainbow (x5) or Diamond (x10).
3. Click a rival's character to steal it — unless their base is locked. Lock your own base for 60s (120s cooldown).
4. Every 3 minutes the Hunger Wave warns for 30s, then sweeps the map. Caught outside your base, you are swept home
   and lose 10% of your money. Your base is always safe.
5. Rebirth when your total earnings reach the threshold: money and characters reset, earnings double forever.

## The cast (12 original characters)

Pasta Penguin, Taco Turtle, Pizza Pigeon, Burger Beaver, Sushi Shark, Donut Duck, Ramen Rhino, Croissant Crocodile,
Boba Bear, Espresso Elephant, Golden Gnocchi Gorilla, The Infinite Ice Cream — each with its own colour, shape,
accessory, joke, rarity, price and money-per-second rate.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and
  `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json` (`rojo build default.project.json
  --output game.rbxl`). The 3D world (plaza, conveyor, 8 bases, buffet table, trees, lamps, fence, wave wall) is
  built at runtime by `src/server/World.luau`, so the world is code, not a binary blob.
- `src/shared/` holds the data both sides agree on (`Config.luau` — the cast, rarities, rates, tuning; `Util.luau`).
  `src/server/` holds the server: `init.server.luau` wires it, `World.luau` builds the world, `State.luau` keeps all
  player state, `Characters.luau` builds character models, `Spawner.luau` runs the conveyor, `Shop.luau` buys,
  `Steal.luau` steals and locks, `Wave.luau` runs the Hunger Wave, `Interact.luau` routes clicks.
  `src/client/` holds the interface: `Game.client.luau` wires the remotes, `Hud.luau` is the ScreenGui,
  `Sound.luau` plays Roblox's built-in sounds.
- `PLAY.json` names no place yet — the owner publishes from Roblox Studio and fills it in (place id, universe id).
  `screenshots/` still holds the starter's captures until the owner retakes them in Studio.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
