"""Builds the Monte "under construction" Lottie (the logo drawing itself).

Coordinates follow the 120x120 logo used by MonteLogo. Run:
    python tool/make_under_construction_lottie.py assets/lottie/under_construction.json
"""
import json
import sys

FPS = 30
END = 60  # 2 seconds, played once

DEEP = [0.043, 0.239, 0.165, 1]
MOUNTAIN = [0.102, 0.478, 0.314, 1]
GOLD = [0.961, 0.773, 0.192, 1]
WHITE = [1, 1, 1, 1]

EASE_OUT = {"i": {"x": [0.2], "y": [1]}, "o": {"x": [0.4], "y": [0]}}


def static(value):
    return {"a": 0, "k": value}


def animated(*frames):
    """frames: (time, value) pairs; every key but the last gets easing."""
    keys = []
    for index, (time, value) in enumerate(frames):
        key = {"t": time, "s": value if isinstance(value, list) else [value]}
        if index < len(frames) - 1:
            key.update(EASE_OUT)
        keys.append(key)
    return {"a": 1, "k": keys}


def layer_transform(position=None, scale=None, opacity=None):
    return {
        "o": opacity or static(100),
        "r": static(0),
        "p": position or static([0, 0, 0]),
        "a": static([0, 0, 0]),
        "s": scale or static([100, 100, 100]),
    }


def group_transform():
    return {
        "ty": "tr",
        "p": static([0, 0]),
        "a": static([0, 0]),
        "s": static([100, 100]),
        "r": static(0),
        "o": static(100),
        "sk": static(0),
        "sa": static(0),
    }


def path(points, closed):
    zeros = [[0, 0] for _ in points]
    return {
        "ty": "sh",
        "nm": "path",
        "ks": static({"i": zeros, "o": zeros, "v": points, "c": closed}),
    }


def fill(color):
    return {"ty": "fl", "nm": "fill", "c": static(color), "o": static(100), "r": 1}


def stroke(color, width):
    return {
        "ty": "st",
        "nm": "stroke",
        "c": static(color),
        "o": static(100),
        "w": static(width),
        "lc": 2,  # round cap
        "lj": 2,  # round join
    }


def trim(start_frame, end_frame):
    return {
        "ty": "tm",
        "nm": "draw",
        "s": static(0),
        "e": animated((start_frame, 0), (end_frame, 100)),
        "o": static(0),
        "m": 1,
    }


def layer(index, name, items, transform=None):
    return {
        "ddd": 0,
        "ind": index,
        "ty": 4,
        "nm": name,
        "sr": 1,
        "ks": transform or layer_transform(),
        "ao": 0,
        "shapes": [{"ty": "gr", "nm": name, "it": items + [group_transform()]}],
        "ip": 0,
        "op": END,
        "st": 0,
        "bm": 0,
    }


RIDGE = [[16, 94], [44, 50], [60, 72], [84, 36]]
ARROW = [[71, 35], [85, 34], [86, 48]]
MOUNTAIN_SHAPE = [[16, 94], [44, 50], [60, 72], [84, 36], [104, 94]]

layers = [
    layer(
        1,
        "coin",
        [
            {"ty": "el", "nm": "coin", "p": static([0, 0]), "s": static([18, 18]), "d": 1},
            fill(GOLD),
        ],
        layer_transform(
            position=animated((38, [36, 46, 0]), (54, [36, 30, 0])),
            scale=animated((38, [0, 0, 100]), (48, [120, 120, 100]), (56, [100, 100, 100])),
        ),
    ),
    layer(2, "arrow", [path(ARROW, False), trim(30, 40), stroke(WHITE, 9)]),
    layer(3, "ridge", [path(RIDGE, False), trim(4, 30), stroke(WHITE, 9)]),
    layer(
        4,
        "mountain",
        [path(MOUNTAIN_SHAPE, True), fill(MOUNTAIN)],
        layer_transform(opacity=animated((0, 0), (24, 100))),
    ),
    layer(
        5,
        "background",
        [
            {"ty": "rc", "nm": "box", "d": 1, "p": static([60, 60]), "s": static([120, 120]), "r": static(28)},
            fill(DEEP),
        ],
    ),
]

animation = {
    "v": "5.7.4",
    "fr": FPS,
    "ip": 0,
    "op": END,
    "w": 120,
    "h": 120,
    "nm": "monte-under-construction",
    "ddd": 0,
    "assets": [],
    "layers": layers,
}

with open(sys.argv[1], "w", encoding="utf-8") as out:
    json.dump(animation, out, separators=(",", ":"))
    out.write("\n")
