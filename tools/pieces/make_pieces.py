#!/usr/bin/env python3
"""Draws the shaded piece sets in assets/pieces/<set>/.

The shaded set is the classic pieces (assets/pieces/*.svg, by Colin M.L. Burnett,
CC BY-SA 3.0) lit from the upper left: the flat white and black fills become
gradients, and the outline and detail lines take the set's own colours.

Two more sets use the same light and colours on shapes of their own:

  neo     bold, rounded pieces
  modern  pieces built from plain geometric shapes

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
WHITE = dict(stops=["#ffffff", "#f4ecdc", "#d0bf9b"], gloss=0.6,
             line="#111111")
BLACK = dict(stops=["#666666", "#333333", "#101010"], gloss=0.32,
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


# The shapes of the other sets, on a 100 x 100 square with the base on
# y = 90. Each piece lists its parts back to front; every part is filled and
# outlined like the classic pieces, so parts that overlap show their joint.
# `marks` are lines drawn on top (light on black pieces), `dots` are eyes.

NEO_FOOT = ('<path d="M22 90 H78 Q82 90 82 86 V83 Q82 79 77 78 L71 77 '
            'H29 L23 78 Q18 79 18 83 V86 Q18 90 22 90 Z"/>')

NEO = {
    "P": dict(parts=[
        NEO_FOOT,
        '<path d="M37 48 C37 60 28 68 25 78 H75 C72 68 63 60 63 48 Z"/>',
        '<path d="M31 47 Q31 42 38 42 H62 Q69 42 69 47 Q69 51 62 51 '
        'H38 Q31 51 31 47 Z"/>',
        '<circle cx="50" cy="27" r="16.5"/>',
    ]),
    "R": dict(parts=[
        NEO_FOOT,
        '<path d="M29 78 L32 46 H68 L71 78 Z"/>',
        '<path d="M27 47 V14 Q27 11 30 11 H37 Q40 11 40 14 V20 H45 V14 '
        'Q45 11 48 11 H52 Q55 11 55 14 V20 H60 V14 Q60 11 63 11 H70 '
        'Q73 11 73 14 V47 Q73 49 71 49 H29 Q27 49 27 47 Z"/>',
    ], marks=["M27 31 H73"]),
    "N": dict(parts=[
        NEO_FOOT,
        '<path d="M30 78 C29 66 35 57 44 51 C37 52 30 56 25 59 '
        'C18 62 12 56 14 49 C17 40 26 33 32 27 C34 20 38 14 44 11 '
        'L46 3 L53 9 C70 11 84 27 83 52 C83 63 78 71 76 78 Z"/>',
    ], marks=["M44 51 C49 47 52 43 53 37", "M58 13 C67 18 74 27 77 38"],
        dots=[(40, 25, 3.2), (20, 52, 2)]),
    "B": dict(parts=[
        NEO_FOOT,
        '<path d="M35 78 C38 72 40 69 40 66 H60 C60 69 62 72 65 78 Z"/>',
        '<path d="M35 60 C23 47 28 29 50 17 C72 29 77 47 65 60 Z"/>',
        '<path d="M31 64 Q31 59 38 59 H62 Q69 59 69 64 Q69 69 62 69 '
        'H38 Q31 69 31 64 Z"/>',
        '<circle cx="50" cy="12" r="7"/>',
    ], marks=["M64 29 L49 44"]),
    "Q": dict(parts=[
        NEO_FOOT,
        '<path d="M30 78 C32 72 34 69 33 64 H67 C66 69 68 72 70 78 Z"/>',
        '<circle cx="15" cy="27" r="6"/>',
        '<circle cx="35" cy="20" r="6"/>',
        '<circle cx="50" cy="15" r="6.5"/>',
        '<circle cx="65" cy="20" r="6"/>',
        '<circle cx="85" cy="27" r="6"/>',
        '<path d="M32 66 L16 30 L35 50 L36 24 L46 48 L50 20 L54 48 '
        'L64 24 L65 50 L84 30 L68 66 Q50 71 32 66 Z"/>',
    ]),
    "K": dict(parts=[
        NEO_FOOT,
        '<path d="M30 78 C32 72 34 69 33 64 H67 C66 69 68 72 70 78 Z"/>',
        '<rect x="45" y="4" width="10" height="27" rx="3"/>',
        '<rect x="38" y="11" width="24" height="9" rx="3"/>',
        '<path d="M43 43 C42 34 46 29 50 28 C54 29 58 34 57 43 Z"/>',
        '<path d="M33 66 C20 56 16 40 30 35 C40 32 47 38 50 45 '
        'C53 38 60 32 70 35 C84 40 80 56 67 66 Q50 71 33 66 Z"/>',
    ], marks=["M50 45 V62"]),
}

MODERN_FOOT = '<rect x="22" y="80" width="56" height="10" rx="2"/>'

MODERN = {
    "P": dict(parts=[
        MODERN_FOOT,
        '<path d="M39 46 H61 L68 80 H32 Z"/>',
        '<circle cx="50" cy="30" r="14"/>',
    ]),
    "R": dict(parts=[
        MODERN_FOOT,
        '<path d="M33 42 H67 L70 80 H30 Z"/>',
        '<path d="M26 44 V14 H38 V23 H44 V14 H56 V23 H62 V14 H74 V44 Z"/>',
    ]),
    "N": dict(parts=[
        MODERN_FOOT,
        '<path d="M31 80 L35 60 L20 58 L17 46 L37 24 L40 9 L50 18 '
        'Q74 22 76 52 L72 80 Z"/>',
    ], marks=["M35 60 L48 48", "M50 18 Q68 26 70 50"], dots=[(36, 32, 3)]),
    "B": dict(parts=[
        MODERN_FOOT,
        '<path d="M37 80 L42 58 H58 L63 80 Z"/>',
        '<path d="M50 14 C70 28 70 50 58 60 H42 C30 50 30 28 50 14 Z"/>',
        '<circle cx="50" cy="11" r="5.5"/>',
    ], marks=["M60 30 L47 43", "M40 58 H60"]),
    "Q": dict(parts=[
        MODERN_FOOT,
        '<path d="M33 80 L36 56 H64 L67 80 Z"/>',
        '<path d="M34 58 L20 24 L37 40 L50 16 L63 40 L80 24 L66 58 Z"/>',
        '<circle cx="20" cy="22" r="5.5"/>',
        '<circle cx="50" cy="13" r="6"/>',
        '<circle cx="80" cy="22" r="5.5"/>',
    ]),
    "K": dict(parts=[
        MODERN_FOOT,
        '<path d="M33 80 L36 54 H64 L67 80 Z"/>',
        '<rect x="45" y="5" width="10" height="28" rx="1.5"/>',
        '<rect x="37" y="12" width="26" height="9" rx="1.5"/>',
        '<rect x="28" y="32" width="44" height="24" rx="11"/>',
    ]),
}

FAMILIES = {"neo": NEO, "modern": MODERN}


def shape_svg(name: str, piece: dict, side: str, role: str) -> str:
    c = SIDES[side]
    gid = f"{name}{side}{role}"
    parts = "".join(piece["parts"])
    marks = "".join(f'<path d="{d}"/>' for d in piece.get("marks", []))
    mark_colour = c.get("detail", c["line"])
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="{r}"/>'
        for x, y, r in piece.get("dots", [])
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
        f"{_defs(gid, c, 100)}"
        f"{_shadow(100, 90.5)}"
        f'<g fill="url(#{gid})" stroke="{c["line"]}" stroke-width="2.9" '
        f'stroke-linejoin="round">{parts}</g>'
        f'<g fill="url(#{gid}g)">{parts}</g>'
        f'<g fill="none" stroke="{c["line"]}" stroke-width="2.9" '
        f'stroke-linejoin="round">{parts}</g>'
        f'<g fill="none" stroke="{mark_colour}" stroke-width="3" '
        f'stroke-linecap="round">{marks}</g>'
        f'<g fill="{mark_colour}">{dots}</g>'
        "</svg>\n"
    )


def main() -> None:
    folder = OUT / "shaded"
    folder.mkdir(parents=True, exist_ok=True)
    for side in "wb":
        for role in ROLES:
            (folder / f"{side}{role}.svg").write_text(shaded_svg(side, role))
    print(f"wrote {folder}/ (12 pieces)")
    for name, family in FAMILIES.items():
        folder = OUT / name
        folder.mkdir(parents=True, exist_ok=True)
        for side in "wb":
            for role in ROLES:
                (folder / f"{side}{role}.svg").write_text(
                    shape_svg(name, family[role], side, role)
                )
        print(f"wrote {folder}/ (12 pieces)")


if __name__ == "__main__":
    main()
