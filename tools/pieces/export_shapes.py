#!/usr/bin/env python3
"""Flattens the classic pieces (assets/pieces/*.svg, by Colin M.L. Burnett,
CC BY-SA 3.0) into a list of drawing steps per piece, for the textured sets
painted by tools/pieces/textured.html.

Each step is one path or circle with its fill and stroke resolved (SVG lets
groups pass them down). Run from the project root:

    python3 tools/pieces/export_shapes.py > tools/pieces/shapes.json
"""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

NS = "{http://www.w3.org/2000/svg}"
ROLES = "KQRBNP"
INHERITED = ("fill", "stroke", "stroke-width", "stroke-linecap",
             "stroke-linejoin", "fill-rule")
DEFAULTS = {"fill": "#000", "stroke": "none", "stroke-width": "1",
            "stroke-linecap": "butt", "stroke-linejoin": "miter",
            "fill-rule": "nonzero"}

# The pawn of the graphite set has a flat collar under its head instead of
# the classic gourd shape.
COLLAR_PAWN = [
    {"d": "M18.6 21.6C18.6 27.4 13.4 31 12.8 39H32.2C31.6 31 26.4 27.4 26.4 21.6Z"},
    {"d": "M16.2 20.1Q16.2 18.3 18 18.3H27Q28.8 18.3 28.8 20.1Q28.8 21.9 27 21.9H18Q16.2 21.9 16.2 20.1Z"},
    {"circle": [22.5, 12.9, 4.9]},
]


def steps(el, inherited, out):
    attrs = dict(inherited)
    for key in INHERITED:
        if el.get(key) is not None:
            attrs[key] = el.get(key)
    tag = el.tag.replace(NS, "")
    if tag == "path":
        out.append({"d": el.get("d"), **attrs})
    elif tag == "circle":
        # The black queen's balls have no outline in the classic set; the
        # textured sets outline them like every other part.
        if attrs["stroke"] == "none":
            attrs = {**attrs, "stroke": "#000", "stroke-width": "1.5"}
        out.append({"circle": [float(el.get(k)) for k in ("cx", "cy", "r")],
                    **attrs})
    for child in el:
        steps(child, attrs, out)


def main() -> None:
    result = {}
    for side in "wb":
        for role in ROLES:
            root = ET.parse(Path("assets/pieces") / f"{side}{role}.svg").getroot()
            out = []
            steps(root, DEFAULTS, out)
            result[f"{side}{role}"] = out
            if role == "P":
                body = "#fff" if side == "w" else "#000"
                result[f"{side}P_collar"] = [
                    {**DEFAULTS, "fill": body, "stroke": "#000",
                     "stroke-width": "1.5", "stroke-linejoin": "round", **s}
                    for s in COLLAR_PAWN
                ]
    json.dump(result, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
