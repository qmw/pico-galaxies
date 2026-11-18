#!/bin/sh
# Launch VOIDSTORM. -root_path lets the title cart load() the campaign cart (and back).
cd "$(dirname "$0")"
exec ~/pico-8-app/pico-8/pico8 -home ./pico_home -root_path "$(pwd)" -windowed 1 -run voidstorm.p8 "$@"
