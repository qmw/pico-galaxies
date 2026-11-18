# Pico Galaxies

A PICO-8 anthology: one title cart plus eleven "planet" carts, each a different game genre,
all sharing one sprite sheet generated with the Krea 2 Pixel Art LoRA
(`e-n-v-y/Krea-2-Pixel-Art` on Krea 2 Turbo, via the `maszynopisarz/krea2-pixel-art` Space).

| Menu entry | Cart | Genre |
|---|---|---|
| arcade | `voidstorm.p8` | vertical arcade shooter (also the title screen) |
| colony defense | `original_colony_defense_1.p8` | real-time colony defense + trade runs (original design) |
| colonization | `colonization_1.p8` | turn-based colonize / trade / clear the hives |
| survivors | `survivors_1.p8` | horde survival auto-shooter |
| heroes | `heroes_1.p8` | hero-led turn-based strategy |
| lane duel | `lane_duel_1.p8` | one-lane duel with telegraphed intents |
| grid tactics | `grid_tactics_1.p8` | grid-tactics mech defense |
| conquest | `conquest_1.p8` | multi-faction planetary conquest |
| bug battle | `bug_battle_1.p8` | real-time-with-pause squad bug battles |
| hex lords | `hex_territory_1.p8` | hex territory strategy (towers & knights) |
| wasteland | `wasteland_1.p8` | post-apocalyptic turn-based RPG |
| mmo rpg | `mmo_rpg_1.p8` | pocket fantasy MMO-style action RPG |

Carts with no `original_` prefix are demakes of a genre's classic mechanics with original content.
Full designs: [DESIGN.md](DESIGN.md).

## Build & run
- `python3 -m venv .venv && .venv/bin/pip install numpy pillow gradio_client`
- `.venv/bin/python build_cart.py` builds every cart from `common.lua` + `<cart>.lua` + `assets/raw/*.png`.
- `./play.sh` runs it in PICO-8 (passes `-root_path` so carts can `load()` each other).
- `./export_html.sh` exports the browser build (all carts bundled) to `pico_galaxies_html/`.
- `gen_assets.py` regenerates sprites with the Krea Space (falls back to a LAN server when the HF quota runs out).
