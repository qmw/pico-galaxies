#!/bin/sh
# Build every cart and export the browser version (all carts bundled; load() works between them)
# into pico_galaxies_html/ (index.html + pico_galaxies.js) for itch.io.
set -e
cd "$(dirname "$0")"
.venv/bin/python -I build_cart.py
rm -rf pico_galaxies_html
~/pico-8-app/pico-8/pico8 -home ./test_home -root_path "$(pwd)" voidstorm.p8 -export "-f pico_galaxies.html \
 original_colony_defense_1.p8 colonization_1.p8 survivors_1.p8 heroes_1.p8 lane_duel_1.p8 grid_tactics_1.p8 \
 conquest_1.p8 bug_battle_1.p8 hex_territory_1.p8 wasteland_1.p8 mmo_rpg_1.p8"
sed -i 's|<title>PICO-8 Cartridge</title>|<title>Pico Galaxies</title>|' pico_galaxies_html/index.html
echo "exported: pico_galaxies_html/"
