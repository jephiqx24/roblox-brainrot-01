# Brainrot Buffet (The Great Picnic)

A food-themed brainrot game for the make.fun roblox-brainrot-01 competition.

Twelve original food-animal characters — Pasta Penguin, Taco Turtle, Pizza
Pigeon, Burger Beaver, Sushi Shark, Donut Duck, Ramen Rhino, Croissant
Crocodile, Boba Bear, Espresso Elephant, Golden Gnocchi Gorilla and The
Infinite Ice Cream — ride a conveyor belt through the middle of a picnic
plaza. Click one to buy it and it walks to your base and earns $/s.

- **Mutations**: Golden x2 (4%), Rainbow x5 (1.5%), Diamond x10 (0.5%) on spawn.
- **Rebirths**: at $25K / $250K / $2.5M / $25M / $250M total earned, each doubling income.
- **Steal**: click a rival's character to steal it (30s cooldown).
- **Base lock**: lock your base for 60s (120s cooldown) so rivals can't steal from you.
- **Hunger Wave**: every 180s, with a 30s warning — anyone caught outside their
  base is teleported home and loses 10% of their money, and the conveyor is cleared.

Eight bases ring the plaza, each with six character slots. The HUD shows money,
rebirths and multiplier, rebirth progress, the next wave timer, and toasts.

## Build

```sh
rojo build default.project.json --output game.rbxl
```

## Layout

- `src/shared/` — Config (characters, rates, timings) and Util (money formatting).
- `src/server/` — World, State, Characters, Spawner, Shop, Steal, Interact, Wave, init.
- `src/client/` — Game client entry, Hud, Sound (built-in sounds only).
