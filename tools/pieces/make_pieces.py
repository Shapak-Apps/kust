#!/usr/bin/env python3
"""Draws the piece sets in assets/pieces/<set>/.

  neo     bold, rounded pieces lit from above: no black outline, a thin
          darker rim, a soft top-to-bottom shade and a shadow on the square.
  carpet  the neo pieces in the carpet's ivory and madder.
  shaded  the classic pieces (assets/pieces/*.svg, by Colin M.L. Burnett,
          CC BY-SA 3.0) with gradient fills instead of flat white and black.

Run from the project root:  python3 tools/pieces/make_pieces.py
The classic set in assets/pieces/*.svg is not touched.
"""

import re
from pathlib import Path

OUT = Path("assets/pieces")

# rim: edge and detail lines; top/bottom: the body shade; base: the shade of
# the foot; shine: the highlight.
NEO_COLOURS = {
    "neo": {
        "w": dict(rim="#a9a9a9", top="#ffffff", bottom="#d9d9d9",
                  base="#cfcfcf", shine="#ffffff", detail="#b5b5b5"),
        "b": dict(rim="#2f2d2b", top="#6e6b68", bottom="#46433f",
                  base="#3a3734", shine="#8f8b87", detail="#2f2d2b"),
    },
    "carpet": {
        "w": dict(rim="#b8892f", top="#fffaf0", bottom="#f1e2c0",
                  base="#e3c88c", shine="#ffffff", detail="#c99a3e"),
        "b": dict(rim="#3a0a0a", top="#b53a2a", bottom="#7c1a1a",
                  base="#5e1212", shine="#d4614c", detail="#3a0a0a"),
    },
}

# The foot every piece stands on: a plinth and a wider base, 100 x 100 grid.
FOOT = ('<path d="M22 90 H78 Q82 90 82 86 V83 Q82 79 77 78 L71 77 '
        'H29 L23 78 Q18 79 18 83 V86 Q18 90 22 90 Z"/>')

# Each piece: the parts of its silhouette, lines where parts meet or are cut,
# and highlight strokes along the lit side.
NEO = {
    "P": dict(
        parts=[
            FOOT,
            '<path d="M37 48 C37 60 28 68 25 78 H75 C72 68 63 60 63 48 Z"/>',
            '<path d="M31 47 Q31 42 38 42 H62 Q69 42 69 47 Q69 51 62 51 '
            'H38 Q31 51 31 47 Z"/>',
            '<circle cx="50" cy="27" r="16.5"/>',
        ],
        lines=["M24 79 H76", "M36 51 H64"],
        shine=["M40 20 A11 11 0 0 1 48 15", "M37 73 C38 66 41 60 42 55"],
    ),
    "R": dict(
        parts=[
            FOOT,
            '<path d="M29 78 L32 46 H68 L71 78 Z"/>',
            '<path d="M27 47 V14 Q27 11 30 11 H37 Q40 11 40 14 V20 H45 V14 '
            'Q45 11 48 11 H52 Q55 11 55 14 V20 H60 V14 Q60 11 63 11 H70 '
            'Q73 11 73 14 V47 Q73 49 71 49 H29 Q27 49 27 47 Z"/>',
        ],
        lines=["M24 79 H76", "M30 49 H70", "M27 31 H73"],
        shine=["M31 27 V16", "M38 73 L40 54"],
    ),
    "N": dict(
        parts=[
            FOOT,
            '<path d="M30 78 C29 66 35 57 44 51 C37 52 30 56 25 59 '
            'C18 62 12 56 14 49 C17 40 26 33 32 27 C34 20 38 14 44 11 '
            'L46 3 L53 9 C70 11 84 27 83 52 C83 63 78 71 76 78 Z"/>',
        ],
        lines=["M24 79 H76", "M44 51 C49 47 52 43 53 37",
               "M58 13 C67 18 74 27 77 38"],
        dots=[(40, 25, 3.2), (20, 52, 2)],
        shine=["M19 48 C23 42 29 36 34 31", "M40 16 C42 13 44 12 46 11"],
    ),
    "B": dict(
        parts=[
            FOOT,
            '<path d="M35 78 C38 72 40 69 40 66 H60 C60 69 62 72 65 78 Z"/>',
            '<path d="M31 64 Q31 59 38 59 H62 Q69 59 69 64 Q69 69 62 69 '
            'H38 Q31 69 31 64 Z"/>',
            '<path d="M35 60 C23 47 28 29 50 17 C72 29 77 47 65 60 Z"/>',
            '<circle cx="50" cy="12" r="7"/>',
        ],
        lines=["M24 79 H76", "M38 69 H62", "M37 59 H63"],
        # The cut through the mitre, drawn in the square's own colour.
        cut="M66 28 L49 45",
        shine=["M39 52 C36 44 39 36 46 28", "M46 9 A5 5 0 0 1 50 7"],
    ),
    "Q": dict(
        parts=[
            FOOT,
            '<path d="M30 78 C32 72 34 69 33 64 H67 C66 69 68 72 70 78 Z"/>',
            '<path d="M32 66 L16 30 L35 50 L36 24 L46 48 L50 20 L54 48 '
            'L64 24 L65 50 L84 30 L68 66 Q50 71 32 66 Z"/>',
            '<circle cx="15" cy="27" r="6"/>',
            '<circle cx="35" cy="20" r="6"/>',
            '<circle cx="50" cy="15" r="6.5"/>',
            '<circle cx="65" cy="20" r="6"/>',
            '<circle cx="85" cy="27" r="6"/>',
        ],
        lines=["M24 79 H76", "M33 66 Q50 71 67 66"],
        shine=["M34 61 L24 41", "M12 24 A4 4 0 0 1 16 22",
               "M47 12 A4 4 0 0 1 51 10"],
    ),
    "K": dict(
        parts=[
            FOOT,
            '<path d="M30 78 C32 72 34 69 33 64 H67 C66 69 68 72 70 78 Z"/>',
            '<path d="M33 66 C20 56 16 40 30 35 C40 32 47 38 50 45 '
            'C53 38 60 32 70 35 C84 40 80 56 67 66 Q50 71 33 66 Z"/>',
            '<path d="M43 43 C42 34 46 29 50 28 C54 29 58 34 57 43 Z"/>',
            '<rect x="45" y="4" width="10" height="27" rx="3"/>',
            '<rect x="38" y="11" width="24" height="9" rx="3"/>',
        ],
        lines=["M24 79 H76", "M33 66 Q50 71 67 66", "M50 45 V62"],
        shine=["M24 50 C23 43 26 38 32 37", "M48 7 V10"],
    ),
}


def neo_svg(set_name: str, side: str, role: str) -> str:
    c = NEO_COLOURS[set_name][side]
    p = NEO[role]
    parts = "".join(p["parts"])
    body = "".join(p["parts"][1:])
    gid = f"{set_name}{side}{role}"
    lines = "".join(f'<path d="{d}"/>' for d in p["lines"])
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in p.get("dots", [])
    )
    shine = "".join(f'<path d="{d}"/>' for d in p["shine"])
    cut = ""
    if "cut" in p:
        # A dark groove with a lit lower lip reads as a cut into the mitre.
        cut = (
            f'<path d="{p["cut"]}" fill="none" stroke="{c["rim"]}" '
            'stroke-width="5" stroke-linecap="round"/>'
            f'<path d="{p["cut"]}" fill="none" stroke="{c["bottom"]}" '
            'stroke-width="2" stroke-linecap="round" '
            'transform="translate(0.8 0.8)"/>'
        )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
        "<defs>"
        f'<linearGradient id="{gid}b" x1="0" y1="0" x2="0.35" y2="1">'
        f'<stop offset="0" stop-color="{c["top"]}"/>'
        f'<stop offset="1" stop-color="{c["bottom"]}"/>'
        "</linearGradient>"
        "</defs>"
        '<ellipse cx="51" cy="91.5" rx="33" ry="3.5" fill="#000" '
        'opacity="0.18"/>'
        f'<g fill="{c["rim"]}" stroke="{c["rim"]}" stroke-width="3.2" '
        f'stroke-linejoin="round">{parts}</g>'
        f'<g fill="{c["base"]}">{FOOT}</g>'
        f'<g fill="url(#{gid}b)">{body}</g>'
        f'<g fill="none" stroke="{c["detail"]}" stroke-width="1.8" '
        f'stroke-linecap="round">{lines}</g>'
        f'<g fill="{c["rim"]}">{dots}</g>'
        f"{cut}"
        f'<g fill="none" stroke="{c["shine"]}" stroke-opacity="0.9" '
        f'stroke-width="2.4" stroke-linecap="round">{shine}</g>'
        "</svg>\n"
    )


# The classic pieces with a light from the upper left: ivory for white,
# graphite for black.
SHADE = {
    "w": [("0", "#ffffff"), ("0.55", "#f6eedc"), ("1", "#dccaa2")],
    "b": [("0", "#6a6a6a"), ("0.5", "#353535"), ("1", "#161616")],
}


def shaded_svg(side: str, role: str) -> str:
    src = (OUT / f"{side}{role}.svg").read_text()
    gid = f"shaded{side}{role}"
    stops = "".join(
        f'<stop offset="{o}" stop-color="{col}"/>' for o, col in SHADE[side]
    )
    defs = (
        f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1">'
        f"{stops}</linearGradient></defs>"
    )
    paint = f'fill="url(#{gid})"'
    flat = "#fff" if side == "w" else "#000"
    svg = src.replace(f'fill="{flat}"', paint)
    # Black pieces leave some parts to the default black fill: give the first
    # group without a fill the gradient too.
    svg = re.sub(r"<g (?![^>]*fill=)", f"<g {paint} ", svg, count=1)
    if "<g" not in svg:
        svg = re.sub(r"<path (?![^>]*fill=)", f"<path {paint} ", svg, count=1)
    svg = re.sub(r"(<svg[^>]*>)", lambda m: m.group(1) + defs, svg, count=1)
    return svg.rstrip() + "\n"


def main() -> None:
    for set_name in NEO_COLOURS:
        folder = OUT / set_name
        folder.mkdir(parents=True, exist_ok=True)
        for side in "wb":
            for role in NEO:
                (folder / f"{side}{role}.svg").write_text(
                    neo_svg(set_name, side, role)
                )
        print(f"wrote {folder}/ (12 pieces)")
    folder = OUT / "shaded"
    folder.mkdir(parents=True, exist_ok=True)
    for side in "wb":
        for role in NEO:
            (folder / f"{side}{role}.svg").write_text(shaded_svg(side, role))
    print(f"wrote {folder}/ (12 pieces)")


if __name__ == "__main__":
    main()
