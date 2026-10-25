#!/usr/bin/env python3
"""Draws the shaded piece sets in assets/pieces/<set>/.

Every set shares one family of chunky silhouettes. A piece is drawn in
layers so it reads as rounded and lit from the upper left:

  1. a soft shadow on the square,
  2. the silhouette once more, thicker, as a single outline,
  3. each part filled with a sideways gradient, like a turned cylinder,
  4. a sheen over the top half,
  5. dark lines where the parts meet, and small highlights.

Run from the project root:  python3 tools/pieces/make_pieces.py
The classic set in assets/pieces/*.svg is not touched.
"""

from pathlib import Path

OUT = Path("assets/pieces")

# Colours per set and side: outline, gradient (light, mid, dark), sheen
# strength, highlight colour and opacity, line colour for details.
SETS = {
    "neo": {
        "w": dict(line="#3b3b3b", light="#ffffff", mid="#f1f1f1",
                  dark="#bdbdbd", sheen=0.55, shine="#ffffff", shine_o=0.95),
        "b": dict(line="#151515", light="#7a7a7a", mid="#4a4a4a",
                  dark="#1f1f1f", sheen=0.28, shine="#ffffff", shine_o=0.55),
    },
    "walnut": {
        "w": dict(line="#6b4423", light="#fff6e2", mid="#f1dcb4",
                  dark="#c9a26b", sheen=0.45, shine="#fffaf0", shine_o=0.9),
        "b": dict(line="#26140a", light="#a8703f", mid="#7a4a26",
                  dark="#3f2311", sheen=0.25, shine="#ffd9a8", shine_o=0.55),
    },
    # The carpet: ivory wool with a saffron edge against deep madder.
    "carpet": {
        "w": dict(line="#8a5a12", light="#fffaf0", mid="#f4ead6",
                  dark="#e0b25a", sheen=0.5, shine="#ffffff", shine_o=0.95),
        "b": dict(line="#2a0707", light="#c24a36", mid="#8e1e1e",
                  dark="#4e1010", sheen=0.25, shine="#ffc9b8", shine_o=0.6),
    },
}

BASE = '<rect x="20" y="78" width="60" height="12" rx="5"/>'

# Each piece: the parts of its silhouette (drawn back to front), detail lines
# and highlight strokes. Coordinates are on a 100 x 100 square; the base sits
# on y = 90.
PIECES = {
    "P": dict(
        parts=[
            BASE,
            '<path d="M39 47 C39 60 31 69 29 80 L71 80 C69 69 61 60 61 47 Z"/>',
            '<ellipse cx="50" cy="46" rx="16" ry="5.5"/>',
            '<circle cx="50" cy="28" r="13.5"/>',
        ],
        lines=["M23 79 H77", "M35 46 H65"],
        shine=["M41 22 A10 10 0 0 1 49 17", "M37 74 C38 66 41 59 43 52"],
    ),
    "R": dict(
        parts=[
            BASE,
            '<rect x="26" y="68" width="48" height="12" rx="3"/>',
            '<path d="M33 70 L36 39 L64 39 L67 70 Z"/>',
            '<rect x="27" y="29" width="46" height="12" rx="3"/>',
            '<path d="M27 31 V15 Q27 13 29 13 H37 Q39 13 39 15 V21 H44 V15 '
            'Q44 13 46 13 H54 Q56 13 56 15 V21 H61 V15 Q61 13 63 13 H71 '
            'Q73 13 73 15 V31 Z"/>',
        ],
        lines=["M23 79 H77", "M29 69 H71", "M30 40 H70", "M30 30 H70"],
        shine=["M31 26 V17", "M39 66 L41 44"],
    ),
    "N": dict(
        parts=[
            BASE,
            '<path d="M33 80 C33 68 38 60 45 54 C39 54 32 58 26 60 '
            'C19 62 14 56 16 50 C19 42 28 35 34 29 C36 22 39 16 45 13 '
            'L47 6 L53 12 C67 14 80 28 80 50 C80 62 74 71 72 80 Z"/>',
        ],
        lines=["M23 79 H77", "M45 54 C49 50 52 46 53 41"],
        dots=[(41, 27, 3), (22, 53, 1.8)],
        shine=["M21 49 C25 43 31 37 36 32", "M41 18 C43 15 45 14 47 13",
               "M63 22 C71 30 74 40 74 52"],
    ),
    "B": dict(
        parts=[
            BASE,
            '<path d="M36 80 C38 74 40 72 40 70 L60 70 C60 72 62 74 64 80 Z"/>',
            '<ellipse cx="50" cy="69" rx="18" ry="5.5"/>',
            '<path d="M38 68 C29 57 32 40 50 22 C68 40 71 57 62 68 Z"/>',
            '<circle cx="50" cy="16" r="6.5"/>',
        ],
        lines=["M23 79 H77", "M33 69 H67", "M57 34 L47 47"],
        shine=["M41 58 C38 50 41 41 48 32", "M46 13 A5 5 0 0 1 50 11"],
    ),
    "Q": dict(
        parts=[
            BASE,
            '<ellipse cx="50" cy="71" rx="21" ry="6"/>',
            '<path d="M31 71 L18 35 L35 51 L35 27 L46 49 L50 22 L54 49 '
            'L65 27 L65 51 L82 35 L69 71 Z"/>',
            '<circle cx="18" cy="32" r="5"/>',
            '<circle cx="35" cy="24" r="5"/>',
            '<circle cx="50" cy="18" r="5.5"/>',
            '<circle cx="65" cy="24" r="5"/>',
            '<circle cx="82" cy="32" r="5"/>',
        ],
        lines=["M23 79 H77", "M30 66 H70"],
        shine=["M33 63 L24 41", "M47 15 A4 4 0 0 1 51 13"],
    ),
    "K": dict(
        parts=[
            BASE,
            '<ellipse cx="50" cy="71" rx="21" ry="6"/>',
            '<path d="M31 71 C22 58 20 43 33 38 C42 35 48 41 50 46 '
            'C52 41 58 35 67 38 C80 43 78 58 69 71 Z"/>',
            '<path d="M42 44 C42 35 46 31 50 30 C54 31 58 35 58 44 Z"/>',
            '<rect x="46" y="6" width="8" height="26" rx="2"/>',
            '<rect x="39" y="13" width="22" height="8" rx="2"/>',
        ],
        lines=["M23 79 H77", "M30 66 H70", "M50 46 V64"],
        shine=["M27 52 C26 46 29 42 34 41", "M48 9 V12"],
    ),
}


def piece_svg(set_name: str, side: str, role: str) -> str:
    c = SETS[set_name][side]
    p = PIECES[role]
    parts = "".join(p["parts"])
    gid = f"{set_name}{side}{role}"
    lines = "".join(f'<path d="{d}"/>' for d in p["lines"])
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in p.get("dots", [])
    )
    shine = "".join(f'<path d="{d}"/>' for d in p["shine"])
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
        "<defs>"
        f'<linearGradient id="{gid}b" x1="0" y1="0" x2="1" y2="0">'
        f'<stop offset="0" stop-color="{c["mid"]}"/>'
        f'<stop offset="0.3" stop-color="{c["light"]}"/>'
        f'<stop offset="1" stop-color="{c["dark"]}"/>'
        "</linearGradient>"
        f'<linearGradient id="{gid}s" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="#ffffff" stop-opacity="{c["sheen"]}"/>'
        '<stop offset="0.55" stop-color="#ffffff" stop-opacity="0"/>'
        "</linearGradient>"
        "</defs>"
        '<ellipse cx="51" cy="91" rx="31" ry="4" fill="#000" opacity="0.22"/>'
        f'<g fill="{c["line"]}" stroke="{c["line"]}" stroke-width="5" '
        f'stroke-linejoin="round">{parts}</g>'
        f'<g fill="url(#{gid}b)">{parts}</g>'
        f'<g fill="url(#{gid}s)">{parts}</g>'
        f'<g fill="none" stroke="{c["line"]}" stroke-width="2.2" '
        f'stroke-linecap="round" stroke-opacity="0.75">{lines}</g>'
        f'<g fill="{c["line"]}">{dots}</g>'
        f'<g fill="none" stroke="{c["shine"]}" stroke-opacity="{c["shine_o"]}" '
        f'stroke-width="2.6" stroke-linecap="round">{shine}</g>'
        "</svg>\n"
    )


def main() -> None:
    for set_name in SETS:
        folder = OUT / set_name
        folder.mkdir(parents=True, exist_ok=True)
        for side in "wb":
            for role in PIECES:
                (folder / f"{side}{role}.svg").write_text(
                    piece_svg(set_name, side, role)
                )
        print(f"wrote {folder}/ (12 pieces)")


if __name__ == "__main__":
    main()
