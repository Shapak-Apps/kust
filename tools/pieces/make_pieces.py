#!/usr/bin/env python3
"""Draws the shaded piece sets in assets/pieces/<set>/.

The shaded set is the classic pieces (assets/pieces/*.svg, by Colin M.L. Burnett,
CC BY-SA 3.0) lit from the upper left: the flat white and black fills become
gradients, and the outline and detail lines take the set's own colours.

The textured sets (graphite, brushed) are painted by textured.html.

Run from the project root:  python3 tools/pieces/make_pieces.py
The classic set in assets/pieces/*.svg is not touched.
"""

import copy as copy_module
import xml.etree.ElementTree as ET
from pathlib import Path

OUT = Path("assets/pieces")
ROLES = "KQRBNP"

# Per side: body gradient from the lit corner to the far one, how strong the
# gloss on the upper half is, the outline colour and, on black pieces, the
# colour of the detail lines.
WHITE = dict(stops=["#ffffff", "#f9f3e8", "#e2d4b6"], gloss=0.6,
             line="#111111")
BLACK = dict(stops=["#7a7a7a", "#444444", "#1c1c1c"], gloss=0.32,
             line="#000000", detail="#ececec")
SIDES = {"w": WHITE, "b": BLACK}

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)


def _defs(gid: str, c: dict, size: float) -> str:
    """One light for the whole piece: the gradients are laid over the square,
    not over each part, so every part is lit from the same corner."""
    offsets = ["0", "0.5", "1"]
    stops = "".join(
        f'<stop offset="{o}" stop-color="{col}"/>'
        for o, col in zip(offsets, c["stops"])
    )
    s = size
    return (
        "<defs>"
        f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" '
        f'x1="{0.22 * s:g}" y1="{0.12 * s:g}" x2="{0.78 * s:g}" '
        f'y2="{0.92 * s:g}">{stops}</linearGradient>'
        f'<linearGradient id="{gid}g" gradientUnits="userSpaceOnUse" '
        f'x1="0" y1="{0.1 * s:g}" x2="0" y2="{0.58 * s:g}">'
        f'<stop offset="0" stop-color="#ffffff" stop-opacity="{c["gloss"]}"/>'
        '<stop offset="1" stop-color="#ffffff" stop-opacity="0"/>'
        "</linearGradient>"
        "</defs>"
    )


def _shadow(size: float, bottom: float) -> str:
    """A soft contact shadow: two stacked ellipses fake a blur."""
    s = size
    return (
        f'<ellipse cx="{0.5 * s:g}" cy="{bottom:g}" rx="{0.34 * s:g}" '
        f'ry="{0.045 * s:g}" fill="#000" opacity="0.10"/>'
        f'<ellipse cx="{0.5 * s:g}" cy="{bottom:g}" rx="{0.26 * s:g}" '
        f'ry="{0.028 * s:g}" fill="#000" opacity="0.14"/>'
    )


def shaded_svg(side: str, role: str) -> str:
    c = SIDES[side]
    root = ET.fromstring((OUT / f"{side}{role}.svg").read_text())
    gid = f"shaded{side}{role}"
    paint = f"url(#{gid})"
    flat = "#fff" if side == "w" else "#000"

    def walk(el, inherited):
        fill = el.get("fill")
        if fill == flat:
            el.set("fill", paint)
            fill = paint
        own = fill if fill is not None else inherited
        if fill is None and inherited == "#000" and side == "b" and el.tag != f"{{{SVG_NS}}}svg":
            # Parts left to the default black fill take the gradient too.
            el.set("fill", paint)
            own = paint
        for child in el:
            walk(child, own)

    walk(root, "#000")
    for el in root.iter():
        # A finer line than the classic 1.5 reads sharper at the larger size.
        if el.get("stroke-width") == "1.5":
            el.set("stroke-width", "1.3")
        # The black queen's balls have no outline; outlined, they read as
        # solid beads instead of grey smudges.
        if side == "b" and el.get("stroke") == "none" and any(
            child.tag == f"{{{SVG_NS}}}circle" for child in el
        ):
            del el.attrib["stroke"]
        if el.get("stroke") == "#000":
            el.set("stroke", c["line"])
        if el.get("stroke") == "#ececec":
            el.set("stroke", c["detail"])

    # The gloss: every filled part again, in a white fade without outlines.
    gloss = ET.Element(f"{{{SVG_NS}}}g", {"stroke": "none"})
    for el in list(root):
        copy = copy_module.deepcopy(el)
        for part in copy.iter():
            if part.get("fill") == paint:
                part.set("fill", f"url(#{gid}g)")
            elif part.get("fill") not in (None, "none"):
                part.set("fill", "none")
            part.set("stroke", "none")
        if any(part.get("fill") == f"url(#{gid}g)" for part in copy.iter()):
            gloss.append(copy)
    # Outlines go back on top so the gloss never softens an edge.
    root.append(gloss)
    for el in list(root)[:-1]:
        lines = copy_module.deepcopy(el)
        for part in lines.iter():
            if part.get("fill") is not None or part is lines:
                part.set("fill", "none")
        root.append(lines)

    # Fill more of the square: the classic pieces leave a wide margin.
    root.set("viewBox", "2 1.5 41 41")
    body = ET.tostring(root, encoding="unicode")
    head, rest = body.split(">", 1)
    return head + ">" + _defs(gid, c, 45) + _shadow(45, 39.6) + rest + "\n"


def main() -> None:
    folder = OUT / "shaded"
    folder.mkdir(parents=True, exist_ok=True)
    for side in "wb":
        for role in ROLES:
            (folder / f"{side}{role}.svg").write_text(shaded_svg(side, role))
    print(f"wrote {folder}/ (12 pieces)")


if __name__ == "__main__":
    main()
