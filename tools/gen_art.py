#!/usr/bin/env python3
"""Generates PLACEHOLDER pixel art for Hose Survivors.

Every file written here is a clearly-labelled placeholder that can be replaced
by final art of the same dimensions/frame layout (see ASSET_GUIDE.md) without
touching gameplay code. Re-run with:  python3 tools/gen_art.py
"""
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
T = (0, 0, 0, 0)


def save(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", rel, img.size)


def from_ascii(rows, pal):
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, len(rows)), T)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row.ljust(w, ".")):
            if ch != ".":
                img.putpixel((x, y), pal[ch] + (255,) if len(pal[ch]) == 3 else pal[ch])
    return img


def sheet(frames):
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), T)
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    return out


def bob(img, keep_bottom=3):
    """Second animation frame: squash the body 1px down, keeping the feet planted."""
    w, h = img.size
    out = Image.new("RGBA", (w, h), T)
    top = img.crop((0, 0, w, h - keep_bottom - 1))
    out.paste(top, (0, 1))
    out.paste(img.crop((0, h - keep_bottom, w, h)), (0, h - keep_bottom))
    return out


def silhouette(img, color=(14, 12, 20, 255)):
    out = Image.new("RGBA", img.size, T)
    px, po = img.load(), out.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            if px[x, y][3] > 0:
                po[x, y] = color
    return out


# --------------------------------------------------------------------------
# Jon Hose
# --------------------------------------------------------------------------
JON_PAL = {
    "O": (12, 10, 14), "H": (58, 36, 24), "S": (224, 172, 128), "s": (188, 134, 96),
    "e": (20, 20, 30), "B": (30, 30, 38), "b": (58, 58, 72), "P": (44, 48, 66),
    "p": (30, 32, 46), "K": (22, 18, 18), "G": (70, 120, 70),
}
JON_TOP = [
    "....OOOOOOO.....",
    "...OHHHHHHHO....",
    "...OHHHHHHHHO...",
    "...OHHSSSSSSO...",
    "...OHSSeSSeSO...",
    "...OSSSSSSSSO...",
    "....OSSsssSO....",
    "..OOOOOSSOOOO...",
    ".OBBBBBBBBBBBO..",
    "OSSBBbBBBbBBSSO.",
    "OSSSBBBBBBBSSSO.",
    "OSSOBBBBBBBOSSO.",
    "OSsOBBBBBBBOsSO.",
    ".OSOBBBBBBBOSO..",
    ".OSOBBBBBBBOSO..",
    "..OOPPPPPPPOO...",
    "...OPPPPPPPO....",
    "...OPPPOPPPO....",
]
JON_LEGS = {
    "idle": ["...OPPPOPPPO....", "...OPPPOPPPO....", "...OPPO.OPPO....", "...OPpO.OPpO....",
             "..OKKKO.OKKKO...", "..OOOOO.OOOOO..."],
    "a": ["...OPPPOPPPO....", "..OPPPO.OPPPO...", ".OPPPO...OPPO...", ".OPpO....OPpO...",
          "OKKKO....OKKKO..", "OOOOO....OOOOO.."],
    "b": ["...OPPPOPPPO....", "...OPPPPPPO.....", "....OPPPPO......", "....OPpPpO......",
          "...OKKKKKKO.....", "...OOOOOOOO....."],
    "c": ["...OPPPOPPPO....", "..OPPPO.OPPPO...", "..OPPO...OPPPO..", "..OPpO....OPpO..",
          ".OKKKO....OKKKO.", ".OOOOO....OOOOO."],
}


def jon_frame(legs, dy=0):
    img = from_ascii(JON_TOP + JON_LEGS[legs], JON_PAL)
    if dy:
        out = Image.new("RGBA", img.size, T)
        out.paste(img.crop((0, 0, 16, 18)), (0, dy))
        out.paste(img.crop((0, 18, 16, 24)), (0, 18))
        return out
    return img


def gen_jon():
    frames = [jon_frame("idle"), jon_frame("idle", 1),
              jon_frame("a"), jon_frame("b", 1), jon_frame("c"), jon_frame("b", 1)]
    save(sheet(frames), "characters/jon_hose.png")  # 6 frames 16x24: idle x2, walk x4
    save(silhouette(frames[0]), "characters/locked_silhouette.png")
    nozzle = from_ascii([
        "................",
        "...OOOOOOOOO....",
        "GGOkkkkkYYYYOO..",
        "GGOkkkkkYyyYYYO.",
        "GGOkkkkkYyyYYYO.",
        "GGOkkkkkYYYYOO..",
        "...OOOOOOOOO....",
        "................",
    ], {"O": (12, 10, 14), "G": (56, 104, 60), "k": (34, 34, 40), "Y": (214, 168, 64), "y": (255, 226, 130)})
    save(nozzle, "weapons/hose_nozzle.png")


# --------------------------------------------------------------------------
# Enemies
# --------------------------------------------------------------------------
def gen_enemies():
    dry = from_ascii([
        "....OOOOOOO.....",
        "...ODDDDDDDO....",
        "..ODDDcDDDDDO...",
        "..ODeeDDDeeDO...",
        "..ODeeDcDeeDO...",
        "..ODDDDcDDDDO...",
        "..ODDmmmmmDdO...",
        "...ODDDDDDdO....",
        "..OODDcDDDdOO...",
        ".ODODDDcDDdODO..",
        ".ODODDDDDddODO..",
        ".OO.ODDcDdO.OO..",
        "....ODDDddO.....",
        "....ODO.OdO.....",
        "...ODDO.OddO....",
        "...OOOO.OOOO....",
    ], {"O": (50, 32, 22), "D": (206, 166, 116), "d": (160, 120, 80), "c": (100, 66, 42),
        "e": (255, 120, 40), "m": (60, 30, 20)})
    save(sheet([dry, bob(dry)]), "enemies/dry_one.png")

    hours = from_ascii([
        "..OOOOOOOOOO....",
        ".OWWWWWWWWWwO...",
        ".OWllllllWWwO...",
        ".OWWWWWWWWWwO...",
        ".OWRRWWWRRWwO...",
        ".OWWRRWRRWWwO...",
        ".OWWWWWWWWWwO...",
        ".OWlllWlllWwO...",
        ".OWWWWWWWWWwO...",
        ".OWWOOOOOWWwO...",
        ".OWWOWOWOWWwO...",
        ".OWWWWWWWWWwO...",
        ".OWllllllWWwO...",
        ".OWWWWWWWRRwO...",
        ".OwwwwwwwwwwO...",
        "..OOOOOOOOOO....",
    ], {"O": (60, 56, 70), "W": (238, 232, 214), "w": (198, 190, 170), "l": (120, 130, 165), "R": (214, 48, 48)})
    tilted = hours.rotate(-8, resample=Image.NEAREST)
    save(sheet([hours, tilted]), "enemies/unregistered_hours.png")

    thirsty = from_ascii([
        ".....OOOOOO.....",
        "....OTTTTTTO....",
        "...OTeeTTeeTO...",
        "...OTeeTTeeTO...",
        "...OTTTTTTTTO...",
        "...OTMMMMMMTO...",
        "...OTMggggMTO...",
        "...OTMMggMMtO...",
        "....OTTggTtO....",
        "..OOOTTTTttOOO..",
        ".OTTOTTTTttOTTO.",
        ".OTO.OTTttO.OTO.",
        ".OO..OTTttO..OO.",
        ".....OTOOtO.....",
        "....OTTOOttO....",
        "....OOOOOOOO....",
    ], {"O": (40, 22, 40), "T": (156, 112, 146), "t": (112, 78, 106), "M": (40, 10, 20),
        "g": (236, 92, 112), "e": (255, 244, 170)})
    save(sheet([thirsty, bob(thirsty)]), "enemies/thirsty.png")

    bureaucrat = from_ascii([
        "......OOOOOOOO......",
        ".....OhhhhhhhhO.....",
        ".....OhFFFFFFhO.....",
        ".....OFGGFFGGFO.....",
        ".....OFGGFFGGFO.....",
        ".....OFFFFFFFFO.....",
        ".....OFFmmmmFFO.....",
        "......OFFFFFFO......",
        "...OOOOOWRRWOOOO....",
        "..OUUUUUWRRWUUUUO...",
        ".OUUUUUUURRUUUUUUO..",
        ".OUUuUUUURRUUUUuUO..",
        ".OUUuUUUURRUUUUuUO..",
        ".OUUuUUUURRUUUUuUO..",
        ".OUUuUUUUUUUUUUuUO..",
        ".OFFOUUUUUUUUUUOFFO.",
        "..OOOUUUUUUUUUUOBBBO",
        "....OUUUUUUUUUUOBbBO",
        "....OUUUUOOUUUUOBBBO",
        "....OUUUO..OUUUOOOO.",
        "....OUUUO..OUUUO....",
        "....OUUUO..OUUUO....",
        "....OuuuO..OuuuO....",
        "...OKKKKO..OKKKKO...",
        "...OOOOOO..OOOOOO...",
    ], {"O": (16, 16, 24), "h": (150, 150, 160), "F": (226, 196, 170), "G": (40, 60, 90),
        "m": (120, 60, 60), "W": (240, 240, 240), "R": (200, 40, 50), "U": (62, 70, 96),
        "u": (42, 48, 70), "B": (120, 80, 44), "b": (220, 190, 90), "K": (20, 18, 22)})
    save(sheet([bureaucrat, bob(bureaucrat, 2)]), "enemies/bureaucrat.png")

    # Boss: The Great Drying -- procedural cracked sun-baked colossus, 64x64, 2 frames.
    def boss(frame):
        rnd = random.Random(7)
        img = Image.new("RGBA", (64, 64), T)
        px = img.load()
        for y in range(64):
            for x in range(64):
                dx, dy = x - 31.5, y - 33.5
                ang = math.atan2(dy, dx)
                edge = 26 + 3.0 * math.sin(ang * 7 + 1.3) + 2.0 * math.sin(ang * 13)
                d = math.hypot(dx, dy)
                if d < edge:
                    shade = 1.0 - 0.45 * (d / edge) + 0.12 * math.sin(x * 0.9) * math.cos(y * 0.7)
                    lit = 1.0 + 0.25 * (-dx - dy) / 40.0
                    r = int(min(255, 214 * shade * lit))
                    g = int(min(255, 150 * shade * lit))
                    b = int(min(255, 84 * shade * lit))
                    px[x, y] = (r, g, b, 255)
                elif d < edge + 1.5:
                    px[x, y] = (54, 28, 16, 255)
        d = ImageDraw.Draw(img)
        # cracks
        for _ in range(11):
            x, y = 32 + rnd.uniform(-8, 8), 34 + rnd.uniform(-8, 8)
            a = rnd.uniform(0, math.tau)
            for _ in range(rnd.randint(8, 16)):
                nx, ny = x + math.cos(a) * 2.2, y + math.sin(a) * 2.2
                if math.hypot(nx - 32, ny - 34) > 24:
                    break
                d.line([x, y, nx, ny], fill=(88, 46, 24, 255))
                x, y = nx, ny
                a += rnd.uniform(-0.7, 0.7)
        # horns of dust
        for sx in (-1, 1):
            d.polygon([(32 + sx * 14, 12), (32 + sx * 24, 1), (32 + sx * 20, 15)], fill=(120, 70, 40, 255),
                      outline=(54, 28, 16, 255))
        # eyes
        glow = (255, 240, 150, 255) if frame == 0 else (255, 255, 230, 255)
        for sx in (-1, 1):
            cx = 32 + sx * 10
            d.polygon([(cx - 6, 24), (cx + 6, 27 + sx * -2), (cx + 5, 32), (cx - 5, 31)], fill=(60, 14, 8, 255))
            d.rectangle([cx - 3, 27, cx + 2, 30], fill=(255, 90, 30, 255))
            d.rectangle([cx - 1, 28, cx, 29], fill=glow)
        # mouth
        my = 44 if frame == 0 else 45
        d.polygon([(18, my - 3), (46, my - 3), (42, my + 7), (22, my + 7)], fill=(40, 10, 6, 255))
        for i in range(6):
            tx = 20 + i * 4.4
            d.polygon([(tx, my - 3), (tx + 4, my - 3), (tx + 2, my + 1)], fill=(244, 226, 190, 255))
            d.polygon([(tx + 2, my + 7), (tx + 6, my + 7), (tx + 4, my + 3)], fill=(244, 226, 190, 255))
        return img

    save(sheet([boss(0), boss(1)]), "enemies/great_drying.png")


# --------------------------------------------------------------------------
# Projectiles, pickups, effects
# --------------------------------------------------------------------------
def gen_small():
    water = {"b": (36, 104, 214), "B": (84, 172, 255), "W": (224, 246, 255)}
    save(from_ascii(["..bbBBBBWW..", ".bbBBBBBWWWW.", "bbBBBBBWWWWWW", ".bbBBBBBWWWW.", "..bbBBBBWW.."], water), "weapons/water_droplet.png")
    save(from_ascii([
        "..bbbBBBBBBWW...",
        ".bbBBBBBBBWWWWW.",
        "bbBBBBBBBBWWWWWW",
        "bbBBBBBBBBWWWWWW",
        ".bbBBBBBBBWWWWW.",
        "..bbbBBBBBBWW...",
    ], {"b": (240, 190, 60), "B": (150, 220, 255), "W": (255, 255, 255)}), "weapons/judgment_torrent.png")
    save(from_ascii(["..dDDd..", ".dDDDDd.", "dDDDDDDd", "dDDDDDDd", ".dDDDDd.", "..dDDd.."],
                    {"d": (120, 76, 40), "D": (232, 170, 96)}), "weapons/dust_orb.png")

    def gem(rows, c1, c2, c3, name):
        save(from_ascii(rows, {"O": (10, 20, 50), "a": c1, "b": c2, "W": c3}), "pickups/" + name)

    gem(["..OO..", ".OabO.", "OaWbbO", "OabbbO", ".OOOO."], (120, 200, 255), (50, 130, 240), (240, 250, 255), "xp_small.png")
    gem(["...OO...", "..OabO..", ".OaWbbO.", "OaWbbbbO", "OabbbbbO", "OabbbbbO", ".ObbbbO.", "..OOOO.."],
        (150, 255, 200), (40, 190, 130), (240, 255, 250), "xp_medium.png")
    gem(["....OO....", "...OabO...", "..OaWbbO..", ".OaWWbbbO.", "OaaWbbbbbO", "OabbbbbbbO", "OabbbbbbbO",
         "OabbbbbbbO", ".ObbbbbbO.", "..OOOOOO.."], (255, 230, 140), (240, 150, 40), (255, 255, 240), "xp_large.png")
    save(from_ascii(["..OOOO..", ".OYYYYO.", "OYyOOyYO", "OYyOOyYO", "OYyOOyYO", "OYyOOyYO", ".OYYYYO.", "..OOOO.."],
                    {"O": (90, 56, 10), "Y": (250, 200, 60), "y": (255, 240, 150)}), "pickups/coin.png")
    save(from_ascii([
        "..OOOO..", ".OssssO.", ".OGGGGO.", ".OGWWGO.", ".OGWGGO.", ".OGGGGO.", ".OWWWWO.", ".OGGGGO.",
        ".OGGGGO.", ".OGGgGO.", ".OssssO.", "..OOOO..",
    ], {"O": (20, 40, 30), "s": (200, 206, 214), "G": (60, 180, 110), "g": (40, 130, 80), "W": (240, 250, 245)}),
        "pickups/kristall.png")
    save(from_ascii([
        ".OOOOOOOOOOOOOO.",
        "OBBBBBBBBBBBBBBO",
        "ObBBBBBYYBBBBBbO",
        "ObBBBBYyyYBBBBbO",
        "OOOOOOYyyYOOOOOO",
        "OBBBBBBYYBBBBBBO",
        "OBbBBBBBBBBBBbBO",
        "OBbBBBBBBBBBBbBO",
        "OBbBBBBBBBBBBbBO",
        "OBBBBBBBBBBBBBBO",
        "ObbbbbbbbbbbbbbO",
        ".OOOOOOOOOOOOOO.",
    ], {"O": (40, 22, 10), "B": (150, 96, 50), "b": (110, 66, 34), "Y": (250, 200, 60), "y": (255, 240, 150)}),
        "pickups/supply_crate.png")
    save(from_ascii(["..OOOOOO..", ".OMMMMMMO.", "OMRMOOMBMO", "OMRMOOMBMO", "OMRMOOMBMO", "OWWO..OWWO", ".OO....OO."],
                    {"O": (20, 16, 30), "M": (150, 150, 165), "R": (220, 50, 50), "B": (60, 110, 230),
                     "W": (240, 240, 240)}), "pickups/magnet.png")

    # soft shadow blob
    sh = Image.new("RGBA", (16, 6), T)
    ImageDraw.Draw(sh).ellipse([0, 0, 15, 5], fill=(0, 0, 0, 90))
    save(sh, "effects/shadow.png")
    # vignette overlay at internal resolution
    vg = Image.new("RGBA", (640, 360), T)
    px = vg.load()
    for y in range(360):
        for x in range(640):
            d = math.hypot((x - 320) / 320.0, (y - 180) / 180.0) / 1.414
            a = max(0.0, d - 0.55) / 0.45
            a = int(150 * a * a)
            a = (a // 12) * 12  # banded for a retro feel
            px[x, y] = (20, 8, 4, a)
    save(vg, "effects/vignette.png")


# --------------------------------------------------------------------------
# Environment: The Dry Wastelands
# --------------------------------------------------------------------------
def gen_environment():
    S = 128
    rnd = random.Random(42)
    grid = [[rnd.random() for _ in range(16)] for _ in range(16)]

    def noise(x, y, cells):
        fx, fy = x / S * cells, y / S * cells
        x0, y0 = int(fx) % cells, int(fy) % cells
        x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
        tx, ty = fx - int(fx), fy - int(fy)
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        a = grid[y0][x0] * (1 - tx) + grid[y0][x1] * tx
        b = grid[y1][x0] * (1 - tx) + grid[y1][x1] * tx
        return a * (1 - ty) + b * ty

    img = Image.new("RGBA", (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            n = 0.6 * noise(x, y, 4) + 0.4 * noise(x, y, 16)
            n = round(n * 5) / 5  # posterize
            px[x, y] = (int(138 + 34 * n), int(100 + 26 * n), int(64 + 18 * n), 255)
    # cracks, wrapping at the edges so the tile is seamless
    for _ in range(16):
        x, y = rnd.uniform(0, S), rnd.uniform(0, S)
        a = rnd.uniform(0, math.tau)
        for _ in range(rnd.randint(14, 40)):
            px[int(x) % S, int(y) % S] = (96, 66, 42, 255)
            if rnd.random() < 0.3:
                px[int(x + 1) % S, int(y + 1) % S] = (176, 134, 88, 255)
            x += math.cos(a)
            y += math.sin(a)
            a += rnd.uniform(-0.5, 0.5)
            if rnd.random() < 0.05:
                a += rnd.choice((-1.2, 1.2))
    for _ in range(40):
        x, y = rnd.randrange(S), rnd.randrange(S)
        px[x, y] = (112, 80, 52, 255)
        px[(x + 1) % S, y] = (184, 142, 96, 255)
    save(img, "environment/wasteland_ground.png")

    # dead bush
    bush = Image.new("RGBA", (20, 18), T)
    d = ImageDraw.Draw(bush)
    r2 = random.Random(3)
    for i in range(7):
        a = -math.pi / 2 + (i - 3) * 0.33
        ln = r2.uniform(9, 15)
        ex, ey = 10 + math.cos(a) * ln, 17 + math.sin(a) * ln
        d.line([10, 17, ex, ey], fill=(74, 50, 32, 255))
        d.line([ex, ey, ex + r2.uniform(-3, 3), ey - 2], fill=(98, 70, 44, 255))
    save(bush, "environment/dead_bush.png")

    # broken pipe
    pipe = Image.new("RGBA", (40, 14), T)
    d = ImageDraw.Draw(pipe)
    d.rectangle([0, 3, 30, 11], fill=(96, 104, 112, 255), outline=(36, 38, 46, 255))
    d.line([1, 5, 29, 5], fill=(150, 160, 168, 255))
    d.rectangle([8, 2, 11, 12], fill=(70, 76, 84, 255), outline=(36, 38, 46, 255))
    d.rectangle([22, 6, 26, 9], fill=(150, 84, 44, 255))
    d.polygon([(30, 3), (36, 5), (33, 7), (38, 10), (30, 11)], fill=(80, 86, 94, 255), outline=(36, 38, 46, 255))
    save(pipe, "environment/broken_pipe.png")

    # rusty barrel
    barrel = Image.new("RGBA", (14, 18), T)
    d = ImageDraw.Draw(barrel)
    d.rectangle([1, 1, 12, 16], fill=(140, 78, 44, 255), outline=(40, 22, 14, 255))
    d.line([2, 5, 11, 5], fill=(90, 48, 28, 255))
    d.line([2, 12, 11, 12], fill=(90, 48, 28, 255))
    d.line([3, 2, 3, 15], fill=(190, 120, 70, 255))
    save(barrel, "environment/barrel.png")

    # ruined Council of Hose monument: pedestal + snapped hose statue
    mon = Image.new("RGBA", (34, 44), T)
    d = ImageDraw.Draw(mon)
    st, sd, so = (150, 146, 138, 255), (108, 104, 98, 255), (46, 42, 40, 255)
    d.rectangle([2, 32, 31, 42], fill=st, outline=so)
    d.rectangle([6, 26, 27, 32], fill=sd, outline=so)
    d.line([4, 36, 29, 36], fill=sd)
    d.rectangle([13, 8, 20, 26], fill=st, outline=so)           # column / hose body
    d.arc([8, 0, 26, 18], 180, 320, fill=so, width=3)           # coiled hose arc (snapped)
    d.arc([9, 1, 25, 17], 180, 320, fill=st, width=1)
    d.polygon([(13, 8), (17, 4), (20, 9)], fill=sd, outline=so)  # broken top
    d.rectangle([9, 37, 24, 39], fill=(190, 150, 60, 255))       # brass plaque
    d.line([15, 12, 18, 20], fill=so)
    save(mon, "environment/monument.png")

    skull = from_ascii([".OOOO..", "OWWWWO.", "OWOWOWO", "OWWWWWO", ".OWOWO.", ".OOOOO."],
                       {"O": (60, 46, 36), "W": (226, 214, 190)})
    save(skull, "environment/skull.png")


# --------------------------------------------------------------------------
# Upgrade / weapon icons (16x16)
# --------------------------------------------------------------------------
def gen_icons():
    O = (14, 12, 20, 255)

    def icon(name, fn, bg=(34, 40, 64, 255)):
        img = Image.new("RGBA", (16, 16), T)
        d = ImageDraw.Draw(img)
        d.rectangle([0, 0, 15, 15], fill=bg, outline=O)
        fn(d, img)
        save(img, "ui/icons/%s.png" % name)

    def hose(d, img, brass=(214, 168, 64, 255), jet=(84, 172, 255, 255)):
        d.rectangle([2, 7, 7, 10], fill=(34, 34, 40, 255))
        d.rectangle([7, 6, 11, 11], fill=brass)
        d.line([12, 8, 14, 6], fill=jet)
        d.line([12, 9, 14, 9], fill=jet)
        d.line([12, 10, 14, 12], fill=jet)
        d.line([2, 11, 2, 13], fill=(56, 104, 60, 255))

    icon("holy_hose", hose)
    icon("hose_of_judgment", lambda d, i: hose(d, i, (255, 236, 140, 255), (255, 255, 255, 255)), bg=(120, 60, 20, 255))

    def gauge(d, img):
        d.ellipse([2, 2, 13, 13], fill=(230, 230, 230, 255), outline=O)
        d.line([8, 8, 11, 4], fill=(220, 40, 40, 255))
        d.point([8, 8], fill=O)
        d.arc([4, 4, 11, 11], 180, 270, fill=(60, 160, 60, 255))

    icon("industrial_pressure", gauge)

    def clock(d, img):
        d.ellipse([2, 2, 13, 13], fill=(250, 240, 200, 255), outline=O)
        d.line([8, 8, 8, 4], fill=O)
        d.line([8, 8, 11, 8], fill=O)

    icon("mandatory_overtime", clock)

    def shield(d, img):
        d.polygon([(3, 3), (12, 3), (12, 9), (8, 13), (7, 13), (3, 9)], fill=(90, 140, 220, 255), outline=O)
        d.line([7, 5, 7, 10], fill=(240, 240, 255, 255))
        d.line([5, 7, 10, 7], fill=(240, 240, 255, 255))

    icon("administrative_immunity", shield)

    def envelope(d, img):
        d.rectangle([2, 4, 13, 12], fill=(240, 240, 240, 255), outline=O)
        d.line([2, 4, 7, 9], fill=O)
        d.line([13, 4, 8, 9], fill=O)
        d.ellipse([10, 1, 14, 5], fill=(60, 180, 90, 255))

    icon("inbox_zero", envelope)

    def droplet_plus(d, img):
        d.polygon([(7, 2), (11, 8), (11, 11), (9, 13), (6, 13), (4, 11), (4, 8)], fill=(84, 172, 255, 255), outline=O)
        d.line([7, 7, 7, 11], fill=(255, 255, 255, 255))
        d.line([5, 9, 9, 9], fill=(255, 255, 255, 255))

    icon("hydration_nation", droplet_plus)

    def stamp(d, img):
        d.ellipse([2, 2, 13, 13], outline=(220, 50, 50, 255), width=2)
        d.line([5, 8, 7, 10], fill=(220, 50, 50, 255), width=1)
        d.line([7, 10, 11, 5], fill=(220, 50, 50, 255), width=1)

    icon("council_approval", stamp, bg=(236, 228, 204, 255))

    def arrow_up(d, img):
        d.polygon([(8, 2), (13, 8), (10, 8), (10, 13), (5, 13), (5, 8), (2, 8)], fill=(255, 220, 90, 255), outline=O)

    icon("unpaid_overtime", arrow_up)

    def rings(d, img):
        d.ellipse([1, 1, 14, 14], outline=(84, 172, 255, 255))
        d.ellipse([4, 4, 11, 11], outline=(150, 210, 255, 255))
        d.rectangle([7, 7, 8, 8], fill=(255, 255, 255, 255))

    icon("the_hose_must_flow", rings)

    def boot(d, img):
        d.polygon([(4, 2), (8, 2), (8, 9), (13, 10), (13, 13), (4, 13)], fill=(150, 96, 50, 255), outline=O)
        d.line([1, 5, 2, 5], fill=(255, 255, 255, 255))
        d.line([1, 8, 2, 8], fill=(255, 255, 255, 255))

    icon("sprint_planning", boot)

    def heart(d, img):
        d.polygon([(3, 5), (5, 3), (7, 5), (8, 5), (10, 3), (12, 5), (12, 8), (8, 13), (7, 13), (3, 8)],
                  fill=(230, 60, 80, 255), outline=O)
        d.point([5, 5], fill=(255, 200, 210, 255))

    icon("protein_shake", heart)

    def magnet(d, img):
        d.arc([3, 2, 12, 12], 180, 360, fill=(160, 160, 175, 255), width=3)
        d.rectangle([3, 7, 5, 12], fill=(220, 50, 50, 255))
        d.rectangle([10, 7, 12, 12], fill=(60, 110, 230, 255))

    icon("magnetic_personality", magnet)

    def mug(d, img):
        d.rectangle([3, 6, 10, 13], fill=(240, 240, 240, 255), outline=O)
        d.arc([9, 7, 13, 11], 270, 90, fill=O)
        d.line([5, 2, 5, 4], fill=(200, 200, 200, 255))
        d.line([8, 2, 8, 4], fill=(200, 200, 200, 255))
        d.rectangle([4, 7, 9, 8], fill=(110, 70, 40, 255))

    icon("coffee_break", mug)

    def coin(d, img):
        d.ellipse([3, 3, 12, 12], fill=(250, 200, 60, 255), outline=(90, 56, 10, 255))
        d.line([6, 6, 6, 10], fill=(90, 56, 10, 255))
        d.line([9, 6, 9, 10], fill=(90, 56, 10, 255))
        d.line([6, 8, 9, 8], fill=(90, 56, 10, 255))

    icon("petty_cash", coin)

    # game icon
    ic = Image.new("RGBA", (16, 16), (24, 60, 130, 255))
    d = ImageDraw.Draw(ic)
    hose(d, ic)
    save(ic.resize((128, 128), Image.NEAREST), "ui/icon.png")


if __name__ == "__main__":
    gen_jon()
    gen_enemies()
    gen_small()
    gen_environment()
    gen_icons()
