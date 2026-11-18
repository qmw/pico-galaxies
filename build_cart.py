"""Pack Krea-generated sprites into a PICO-8 cart.

assets/raw/<name>.png (32x32 sprites from the Space)
  -> background flood-removed, cropped, area-downsampled to its slot size
  -> mapped to the PICO-8 16-colour palette in OKLab (colour 0 reserved for transparency)
  -> written into __gfx__ of voidstorm.p8 together with main.lua and generated SFX/music.
Also writes assets/sheet_preview.png (4x) for inspection.
"""
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "assets", "raw")

PICO = [
    (0, 0, 0), (29, 43, 83), (126, 37, 83), (0, 135, 81), (171, 82, 54), (95, 87, 79), (194, 195, 199), (255, 241, 232),
    (255, 0, 77), (255, 163, 0), (255, 236, 39), (0, 228, 54), (41, 173, 255), (131, 118, 156), (255, 119, 168), (255, 204, 170),
]

# name: (x, y, w, h) slot in the 128x128 sprite sheet (pixels). Must match main.lua.
LAYOUT = {
    "ship": (0, 0, 16, 16),
    "drone_a": (16, 0, 16, 16), "drone_b": (32, 0, 16, 16),
    "saucer_a": (48, 0, 16, 16), "saucer_b": (64, 0, 16, 16),
    "mine": (80, 0, 16, 16), "diver": (96, 0, 16, 16), "asteroid": (112, 0, 16, 16),
    "expl_1": (0, 16, 16, 16), "expl_2": (16, 16, 16, 16), "expl_3": (32, 16, 16, 16),
    "power": (48, 16, 8, 8), "shield": (56, 16, 8, 8), "bomb": (48, 24, 8, 8),
    "boss": (64, 16, 32, 32), "planet": (96, 16, 32, 32),
    # strategy layer
    "p_lush": (0, 48, 16, 16), "p_rock": (16, 48, 16, 16), "p_ice": (32, 48, 16, 16), "p_hive": (48, 48, 16, 16),
    "freighter": (64, 48, 16, 16), "dome": (80, 48, 8, 8), "i_food": (88, 48, 8, 8), "i_ore": (80, 56, 8, 8),
    "i_coin": (88, 56, 8, 8), "i_colonist": (96, 48, 8, 8),
    "flagship": (0, 64, 32, 32),
    # colony surface (v2): 8x8 tiles/buildings in row y=64, HQ 16x16 below
    "t_grass": (32, 64, 8, 8), "t_rock": (40, 64, 8, 8), "t_crystal": (48, 64, 8, 8), "t_water": (56, 64, 8, 8),
    "nest": (64, 64, 8, 8), "b_farm": (72, 64, 8, 8), "b_mine": (80, 64, 8, 8), "b_harv": (88, 64, 8, 8),
    "b_hab": (96, 64, 8, 8), "b_turret": (104, 64, 8, 8), "crawl_a": (112, 64, 8, 8), "crawl_b": (120, 64, 8, 8),
    "b_hq": (32, 72, 16, 16),
    "i_guns": (48, 72, 8, 8), "i_cells": (56, 72, 8, 8),
}


def srgb_to_oklab(rgb):
    c = rgb / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    l = 0.4122214708 * lin[..., 0] + 0.5363325363 * lin[..., 1] + 0.0514459929 * lin[..., 2]
    m = 0.2119034982 * lin[..., 0] + 0.6806995451 * lin[..., 1] + 0.1073969566 * lin[..., 2]
    s = 0.0883024619 * lin[..., 0] + 0.2817188376 * lin[..., 1] + 0.6299787005 * lin[..., 2]
    l, m, s = np.cbrt(l), np.cbrt(m), np.cbrt(s)
    return np.stack([
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    ], -1)


PICO_LAB = srgb_to_oklab(np.array(PICO, dtype=np.float64))


def background_mask(rgb):
    """True where pixel is background: the region matching the corner colour, flood-filled from the border.

    The model usually honours "plain black background" but sometimes returns white/grey, so the key colour is
    taken from the most common corner pixel instead of assuming black.
    """
    corners = [tuple(rgb[0, 0]), tuple(rgb[0, -1]), tuple(rgb[-1, 0]), tuple(rgb[-1, -1])]
    key = np.array(max(set(corners), key=corners.count))
    dark = np.abs(rgb - key).max(-1) < 40
    h, w = dark.shape
    bg = np.zeros_like(dark)
    stack = [(y, x) for y in range(h) for x in (0, w - 1)] + [(y, x) for x in range(w) for y in (0, h - 1)]
    while stack:
        y, x = stack.pop()
        if 0 <= y < h and 0 <= x < w and dark[y, x] and not bg[y, x]:
            bg[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    return bg


def to_pico(name, w, h):
    rgb = np.asarray(Image.open(os.path.join(RAW, f"{name}.png")).convert("RGB"), dtype=np.float64)
    if name.startswith("t_"):
        # terrain: the sprite is already pixel art on a 32x32 grid, so cut a native-resolution
        # patch from its centre instead of downsampling (downsampling flattens the texture)
        c0 = (rgb.shape[0] - h) // 2
        patch = srgb_to_oklab(rgb[c0:c0 + h, c0:c0 + w])
        d = ((patch[..., None, :] - PICO_LAB[None, None, 1:]) ** 2).sum(-1)
        tile = (1 + d.argmin(-1)).astype(np.uint8)
        if name == "t_crystal":
            tile[tile == 1] = 13  # frost ground so crystal never reads as water
        return tile
    opaque = ~background_mask(rgb)
    ys, xs = np.nonzero(opaque)
    if len(ys) == 0:
        return np.zeros((h, w), np.uint8)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rgb, opaque = rgb[y0:y1, x0:x1], opaque[y0:y1, x0:x1]
    sh, sw = opaque.shape
    scale = min(w / sw, h / sh, 1.0)  # never upscale
    tw, th = max(1, round(sw * scale)), max(1, round(sh * scale))
    lab = srgb_to_oklab(rgb)
    out = np.zeros((h, w), np.uint8)
    ox, oy = (w - tw) // 2, (h - th) // 2
    for ty in range(th):
        for tx in range(tw):
            ya, yb = int(ty * sh / th), max(int((ty + 1) * sh / th), int(ty * sh / th) + 1)
            xa, xb = int(tx * sw / tw), max(int((tx + 1) * sw / tw), int(tx * sw / tw) + 1)
            cell_o = opaque[ya:yb, xa:xb]
            if cell_o.mean() < 0.4:
                continue
            c = lab[ya:yb, xa:xb][cell_o]
            # majority vote of per-pixel palette matches (keeps highlights/outlines crisper than averaging);
            # ties broken toward the cell's mean colour
            idx = ((c[:, None, :] - PICO_LAB[None, 1:]) ** 2).sum(-1).argmin(1)
            votes = np.bincount(idx, minlength=15).astype(float)
            votes -= 1e-3 * ((PICO_LAB[1:] - c.mean(0)) ** 2).sum(-1)
            out[oy + ty, ox + tx] = 1 + int(votes.argmax())
    return out


def sfx_line(notes, speed=8, loop=(0, 0)):
    """notes: list of up to 32 (pitch 0-63, wave 0-7, vol 0-7, fx 0-7)."""
    notes = list(notes) + [(0, 0, 0, 0)] * (32 - len(notes))
    head = f"{0:02x}{speed:02x}{loop[0]:02x}{loop[1]:02x}"
    return head + "".join(f"{p:02x}{wv:x}{v:x}{fx:x}" for p, wv, v, fx in notes[:32])


def make_sfx():
    s = [""] * 64
    # 0 laser
    s[0] = sfx_line([(48 - i * 3, 4, 5 - i // 2, 0) for i in range(6)], speed=1)
    # 1 small explosion (noise down)
    s[1] = sfx_line([(30 - i * 2, 6, 7 - i // 2, 0) for i in range(12)], speed=2)
    # 2 big explosion
    s[2] = sfx_line([(24 - i, 6, 7 - i // 4, 0) for i in range(24)], speed=3)
    # 3 pickup
    s[3] = sfx_line([(p, 1, 5, 0) for p in (36, 40, 43, 48, 52, 55)], speed=3)
    # 4 player hit
    s[4] = sfx_line([(40 - i * 3, 2, 7, 1) for i in range(10)], speed=3)
    # 5 enemy shot
    s[5] = sfx_line([(30 - i, 3, 3, 0) for i in range(4)], speed=2)
    # 6 bomb whoosh
    s[6] = sfx_line([(10 + i * 2, 6, 7 - i // 5, 2) for i in range(28)], speed=3)
    # 7 hit tick
    s[7] = sfx_line([(55, 6, 3, 0), (50, 6, 2, 0)], speed=1)
    # 8 start / wave fanfare
    s[8] = sfx_line([(p, 4, 5, 0) for p in (36, 36, 43, 43, 48, 48, 55, 55, 60, 60, 60, 60)], speed=4)
    # 9 boss warning siren
    s[9] = sfx_line([((30 if (i // 4) % 2 else 36), 2, 5, 1) for i in range(32)], speed=6)
    # music: 16-21. bass, arp, drums in a minor groove
    roots = [21, 21, 17, 19]  # A, A, F, G (pitch numbers)
    for k, r in enumerate(roots):
        s[16 + k] = sfx_line([(r if i % 4 != 3 else r + 12, 1, 5 if i % 2 == 0 else 3, 0) for i in range(32)], speed=14)
    arp = [[45, 48, 52, 57], [45, 48, 52, 57], [41, 45, 48, 53], [43, 47, 50, 55]]
    for k, a in enumerate(arp):
        s[20 + k] = sfx_line([(a[i % 4], 4, 2 if i % 8 else 3, 0) for i in range(32)], speed=14)
    s[24] = sfx_line([((12, 6, 6, 0) if i % 8 == 0 else (40, 6, 3, 0) if i % 8 == 4 else (60, 6, 1, 0) if i % 2 == 0 else (0, 0, 0, 0)) for i in range(32)], speed=14)
    return [x or sfx_line([]) for x in s]


def make_music():
    lines = []
    for k in range(4):
        flag = 1 if k == 0 else (2 if k == 3 else 0)  # loop start / loop back
        lines.append(f"{flag:02x} {16 + k:02x}{20 + k:02x}{24:02x}41")
    lines += ["00 41424344"] * (64 - len(lines))
    return lines


def label_lines():
    """Cart label (needed for HTML export): assets/label.png, 128x128, mapped to the PICO-8 palette."""
    path = os.path.join(HERE, "assets", "label.png")
    if not os.path.exists(path):
        return []
    rgb = np.asarray(Image.open(path).convert("RGB").resize((128, 128), Image.NEAREST)).astype(int)
    pal = np.array(PICO)
    idx = ((rgb[:, :, None, :] - pal[None, None]) ** 2).sum(-1).argmin(-1)
    return ["__label__", *["".join(f"{v:x}" for v in row) for row in idx]]


def strip_unused(common, own):
    """Drop top-level functions from common.lua that the cart never calls (directly or via other
    kept common functions). Each cart has its own 8192-token budget, so unused helpers are waste."""
    import re
    blocks = re.split(r"(?m)^(?=function \w+\()", common)
    head, funcs = blocks[0], {}
    for b in blocks[1:]:
        funcs[re.match(r"function (\w+)\(", b).group(1)] = b
    keep, todo = set(), [own]
    while todo:
        text = todo.pop()
        for name, body in funcs.items():
            if name not in keep and re.search(r"\b" + name + r"\b", text):
                keep.add(name)
                todo.append(body)
    return head + "".join(b for name, b in funcs.items() if name in keep)


def main():
    sheet = np.zeros((128, 128), np.uint8)
    missing = []
    for name, (x, y, w, h) in LAYOUT.items():
        if not os.path.exists(os.path.join(RAW, f"{name}.png")):
            missing.append(name)
            # TEMPORARY placeholder until the Krea asset is generated: a checkered disc.
            if name != "logo":
                yy, xx = np.mgrid[0:h, 0:w]
                disc = (xx - w / 2 + 0.5) ** 2 + (yy - h / 2 + 0.5) ** 2 < (min(w, h) / 2 - 0.5) ** 2
                sheet[y:y + h, x:x + w] = np.where(disc, np.where((xx // 2 + yy // 2) % 2, 14, 8), 0)
            continue
        sheet[y:y + h, x:x + w] = to_pico(name, w, h)
    if missing:
        print("PLACEHOLDERS (not yet generated):", missing)
    pal = np.array(PICO, np.uint8)
    Image.fromarray(pal[sheet]).resize((512, 512), Image.NEAREST).save(os.path.join(HERE, "assets", "sheet_preview.png"))

    # Two carts share the sheet/sfx/music; each gets its own 8192-token code budget.
    # Usage: build_cart.py                      -> every cart whose .lua exists
    #        build_cart.py CART                 -> just CART
    #        build_cart.py CART EXTRA.lua OUT   -> CART + EXTRA (test code) into OUT
    import sys
    carts = {"arcade": "voidstorm.p8", "original_colony_defense_1": "original_colony_defense_1.p8",
             "colonization_1": "colonization_1.p8", "survivors_1": "survivors_1.p8",
             "heroes_1": "heroes_1.p8", "lane_duel_1": "lane_duel_1.p8",
             "grid_tactics_1": "grid_tactics_1.p8", "conquest_1": "conquest_1.p8",
             "bug_battle_1": "bug_battle_1.p8", "wasteland_1": "wasteland_1.p8", "mmo_rpg_1": "mmo_rpg_1.p8",
             "hex_territory_1": "hex_territory_1.p8"}
    # carts whose source doesn't exist yet are skipped (planets are added one at a time)
    jobs = [(k, None, v) for k, v in carts.items() if os.path.exists(os.path.join(HERE, f"{k}.lua"))]
    if len(sys.argv) == 2:
        jobs = [(sys.argv[1], None, carts[sys.argv[1]])]
    if len(sys.argv) == 4:
        jobs = [(sys.argv[1], sys.argv[2], sys.argv[3])]
    gfx = ["".join(f"{v:x}" for v in row) for row in sheet]
    for kind, extra, out in jobs:
        own = open(os.path.join(HERE, f"{kind}.lua")).read()
        if extra:
            own += "\n" + open(os.path.join(HERE, extra)).read()
        lua = strip_unused(open(os.path.join(HERE, "common.lua")).read(), own) + "\n" + own
        cart = ["pico-8 cartridge // http://www.pico-8.com", "version 42", "__lua__", lua.rstrip("\n"),
                "__gfx__", *gfx, *label_lines(), "__sfx__", *make_sfx(), "__music__", *make_music(), ""]
        with open(os.path.join(HERE, out), "w") as f:
            f.write("\n".join(cart))
        print("wrote", out)


if __name__ == "__main__":
    main()
