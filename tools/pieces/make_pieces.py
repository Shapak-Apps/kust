#!/usr/bin/env python3
"""Draws the shaded piece sets in assets/pieces/<set>/.

Every set is the classic pieces (assets/pieces/*.svg, by Colin M.L. Burnett,
CC BY-SA 3.0) lit from the upper left: the flat white and black fills become
gradients, and the outline and detail lines take the set's own colours.

  shaded  ivory and graphite
  wood    boxwood and rosewood, like a wooden club set
  carpet  the carpet's ivory wool and madder red

Run from the project root:  python3 tools/pieces/make_pieces.py
The classic set in assets/pieces/*.svg is not touched.
"""

import re
from pathlib import Path

OUT = Path("assets/pieces")
ROLES = "KQRBNP"

# Per set and side: gradient stops from the lit corner to the far one, the
# outline colour, and the colour of the detail lines drawn on black pieces.
SETS = {
    "shaded": {
        "w": dict(stops=["#ffffff", "#f6eedc", "#dccaa2"], line="#000000"),
        "b": dict(stops=["#6a6a6a", "#353535", "#161616"], line="#000000",
                  detail="#ececec"),
    },
    "wood": {
        "w": dict(stops=["#fff3d6", "#ecd2a0", "#c99a5b"], line="#3d2410"),
        "b": dict(stops=["#9a5a36", "#6b3519", "#3a1a0b"], line="#1f0f05",
                  detail="#f2d3a6"),
    },
    "carpet": {
        "w": dict(stops=["#fffbf2", "#f4e6c6", "#e2b965"], line="#4a2a06"),
        "b": dict(stops=["#c9503a", "#8e1e1e", "#4a0e0e"], line="#240505",
                  detail="#f7d6c8"),
    },
}


def piece_svg(set_name: str, side: str, role: str) -> str:
    c = SETS[set_name][side]
    src = (OUT / f"{side}{role}.svg").read_text()
    gid = f"{set_name}{side}{role}"
    offsets = ["0", "0.55", "1"]
    stops = "".join(
        f'<stop offset="{o}" stop-color="{col}"/>'
        for o, col in zip(offsets, c["stops"])
    )
    defs = (
        f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1">'
        f"{stops}</linearGradient></defs>"
    )
    paint = f'fill="url(#{gid})"'
    flat = "#fff" if side == "w" else "#000"
    svg = src.replace(f'fill="{flat}"', paint)
    # Black pieces leave some parts to the default black fill: give the first
    # group (or the lone path) without a fill the gradient too.
    svg = re.sub(r"<g (?![^>]*fill=)", f"<g {paint} ", svg, count=1)
    if "<g" not in svg:
        svg = re.sub(r"<path (?![^>]*fill=)", f"<path {paint} ", svg, count=1)
    svg = svg.replace('stroke="#000"', f'stroke="{c["line"]}"')
    if "detail" in c:
        svg = svg.replace('stroke="#ececec"', f'stroke="{c["detail"]}"')
    svg = re.sub(r"(<svg[^>]*>)", lambda m: m.group(1) + defs, svg, count=1)
    return svg.rstrip() + "\n"


def main() -> None:
    for set_name in SETS:
        folder = OUT / set_name
        folder.mkdir(parents=True, exist_ok=True)
        for side in "wb":
            for role in ROLES:
                (folder / f"{side}{role}.svg").write_text(
                    piece_svg(set_name, side, role)
                )
        print(f"wrote {folder}/ (12 pieces)")


if __name__ == "__main__":
    main()
