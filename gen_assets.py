"""Generate all game art with the Krea 2 Pixel Art Space (maszynopisarz/krea2-pixel-art).

Saves each asset's native 32x32 sprite + raw render into assets/raw/. Skips assets that already exist,
so re-running only fills gaps. Usage: HF_TOKEN=... python gen_assets.py [--local] [name ...]
Falls back to the LAN server (KREA_LOCAL_URL, default http://192.168.1.18:7862) when the HF quota runs out;
--local uses it directly.
"""
import os
import shutil
import sys

from gradio_client import Client

STYLE = "game sprite, centered, single object, plain pure black background"

# name: (prompt, seed). Animation frames share a seed so the composition stays consistent.
ASSETS = {
    "ship": ("a sleek cyan and white space fighter ship seen from directly above, nose pointing up, twin engines", 11),
    "drone_a": ("a purple alien insect drone seen from above, wings spread wide open, glowing green eyes", 21),
    "drone_b": ("a purple alien insect drone seen from above, wings folded tight against its body, glowing green eyes", 21),
    "saucer_a": ("a green alien flying saucer with a glass dome and yellow lights around the rim, front view", 31),
    "saucer_b": ("a green alien flying saucer with a glass dome and red lights around the rim, front view", 31),
    "mine": ("a red spiked space mine orb with a glowing yellow core", 41),
    "diver": ("an orange arrowhead kamikaze alien ship seen from above, nose pointing down, flames", 51),
    "asteroid": ("a craggy brown and gray space asteroid rock with craters", 61),
    "boss": ("a huge menacing alien mothership seen from above, dark red armor plating, a big glowing magenta eye in the center, cannons", 71),
    "planet": ("a ringed purple and orange gas giant planet", 81),
    "power": ("a glowing yellow power crystal gem", 91),
    "shield": ("a glowing blue energy shield bubble orb", 92),
    "bomb": ("a round red bomb power-up icon with a white star", 93),
    "expl_1": ("a small bright white and yellow explosion flash burst", 101),
    "expl_2": ("a big orange and red fireball explosion", 102),
    # strategy layer
    "p_lush": ("a small green and blue earthlike planet with oceans and forests", 201),
    "p_rock": ("a small rocky orange desert planet with craters and ore veins", 202),
    "p_ice": ("a small icy white and cyan planet covered in glowing crystals", 203),
    "p_hive": ("a small purple organic alien hive planet with glowing green pustules", 204),
    "freighter": ("a bulky gray and yellow cargo freighter spaceship seen from above, nose pointing up, cargo containers", 205),
    "flagship": ("a huge imperial battleship seen from above, white and gold armor, blue engines, many cannons, menacing", 206),
    "dome": ("a small colony habitat dome with green lights", 207),
    "i_food": ("a golden wheat bundle icon", 208),
    "i_ore": ("a shiny steel metal ingot bar icon", 209),
    "i_coin": ("a shiny gold coin icon", 210),
    "i_colonist": ("a tiny colonist settler person in a blue space suit, front view, full body", 211),
    # colony surface (v2)
    "t_grass": ("top-down seamless green grass ground texture tile, flat, fills the whole image", 301),
    "t_rock": ("top-down seamless gray rocky ground texture tile with orange ore veins, flat, fills the whole image", 302),
    "t_crystal": ("top-down seamless ground tile covered with small glowing cyan crystals, fills the whole image", 303),
    "t_water": ("top-down seamless deep blue water texture tile with small waves, flat, fills the whole image", 304),
    "nest": ("a pulsing purple alien hive nest mound with glowing green holes, top-down view", 305),
    "b_farm": ("a tiny farm field with green crops in rows and a small red barn, top-down view", 306),
    "b_mine": ("a tiny mining drill rig with a yellow frame on rocks, top-down view", 307),
    "b_harv": ("a tiny crystal harvester machine with a cyan glowing crystal tank, top-down view", 308),
    "b_hab": ("a tiny white colony habitat dome with lit windows, top-down view", 309),
    "b_turret": ("a tiny defense gun turret with a twin barrel cannon, top-down view", 310),
    "b_hq": ("a colony lander spaceship headquarters base landed on the ground with landing legs, top-down view", 311),
    "crawl_a": ("a small green alien crawler bug with legs spread out, top-down view", 312),
    "crawl_b": ("a small green alien crawler bug with legs tucked in, top-down view", 312),
    # colonization_1
    "i_tools": ("a crossed hammer and wrench tools icon", 401),
    "i_guns": ("a futuristic blaster rifle gun icon, side view", 403),
    "i_cells": ("a glowing green power cell battery icon", 402),
    "expl_3": ("a dissipating gray and dark red smoke cloud puff", 103),
}

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "raw")


def generate(client, name):
    prompt, seed = ASSETS[name]
    full = f"{prompt}, {STYLE}"
    refined, raw, sprite, used = client.predict(
        prompt=full, resolution="32", colors=16, seed=seed, randomize_seed=False, api_name="/generate",
    )
    shutil.copy(sprite, os.path.join(OUT, f"{name}.png"))
    shutil.copy(raw, os.path.join(OUT, f"{name}_raw.png"))
    return name


# Fallback image server on the user's LAN, used once the HF Space's ZeroGPU quota runs out.
# Assumed to run the same app (same /generate API) as the Space.
LOCAL_URL = os.environ.get("KREA_LOCAL_URL", "http://192.168.1.18:7862")


def main():
    os.makedirs(OUT, exist_ok=True)
    args = [a for a in sys.argv[1:] if a != "--local"]
    names = args or list(ASSETS)
    todo = [n for n in names if args or not os.path.exists(os.path.join(OUT, f"{n}.png"))]
    client = None
    if "--local" not in sys.argv:
        client = Client("maszynopisarz/krea2-pixel-art", token=os.environ["HF_TOKEN"], httpx_kwargs={"timeout": 600})
    # One at a time: each call reserves ZeroGPU quota up front.
    for name in todo:
        try:
            if client is None:
                raise RuntimeError("local requested")
            generate(client, name)
        except Exception as e:
            if client is not None and "quota" not in str(e).lower():
                raise
            # HF quota exhausted (or --local): switch to the LAN server for the rest of the run
            if client is not None:
                print("HF quota exhausted -> falling back to", LOCAL_URL, flush=True)
            client = None
            generate(Client(LOCAL_URL, httpx_kwargs={"timeout": 600}), name)
        print("done", name, flush=True)


if __name__ == "__main__":
    main()
