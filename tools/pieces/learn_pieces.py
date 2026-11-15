#!/usr/bin/env python3
"""Draws the turned-ivory 3D pieces of the Learn map and lessons, into
assets/pieces/learn/{K,Q,R,B,N,P}.svg (100 x 135).

Each turned piece is a stack of lathe segments, described by its profile
(height, radius) from top to bottom. Every segment gets its own cylinder
shading (lit from the upper left, a warm rim light on the right), a lit top
face where it steps out from the one above, a soft contact shadow under the
part resting on it, and a specular streak. The knight is carved by hand.

Run from the project root:  python3 tools/pieces/learn_pieces.py
"""

from pathlib import Path

OUT = Path("assets/pieces/learn")
CX = 50.0
TILT = 0.22  # ellipse height / radius: how far we look down on the piece

DEFS = """<defs>
<linearGradient id="body" x1="0" y1="0" x2="1" y2="0">
<stop offset="0" stop-color="#B3A586"/><stop offset=".07" stop-color="#E9DFC8"/>
<stop offset=".26" stop-color="#FFFFFF"/><stop offset=".42" stop-color="#F6EFDF"/>
<stop offset=".7" stop-color="#D9CCAE"/><stop offset=".9" stop-color="#A89A7B"/>
<stop offset=".97" stop-color="#C2B496"/><stop offset="1" stop-color="#9C8E70"/>
</linearGradient>
<linearGradient id="top" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#FFFFFF"/><stop offset=".55" stop-color="#F3EBDA"/>
<stop offset="1" stop-color="#D6C9AB"/>
</linearGradient>
<linearGradient id="hole" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#7A6D52"/><stop offset="1" stop-color="#B7A98A"/>
</linearGradient>
<radialGradient id="ball" cx=".36" cy=".3" r=".75">
<stop offset="0" stop-color="#FFFFFF"/><stop offset=".35" stop-color="#F7F0E1"/>
<stop offset=".75" stop-color="#D3C6A7"/><stop offset="1" stop-color="#9E9072"/>
</radialGradient>
<radialGradient id="ao" cx=".5" cy=".5" r=".5">
<stop offset="0" stop-color="#3A2F1E" stop-opacity=".42"/>
<stop offset="1" stop-color="#3A2F1E" stop-opacity="0"/>
</radialGradient>
<radialGradient id="floor" cx=".5" cy=".5" r=".5">
<stop offset="0" stop-color="#000" stop-opacity=".42"/>
<stop offset=".6" stop-color="#000" stop-opacity=".16"/>
<stop offset="1" stop-color="#000" stop-opacity="0"/>
</radialGradient>
<linearGradient id="spec" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#fff" stop-opacity="0"/>
<stop offset=".3" stop-color="#fff" stop-opacity=".9"/>
<stop offset=".8" stop-color="#fff" stop-opacity=".55"/>
<stop offset="1" stop-color="#fff" stop-opacity="0"/>
</linearGradient>
<linearGradient id="horse" x1="0" y1="0" x2="1" y2=".25">
<stop offset="0" stop-color="#FFFFFF"/><stop offset=".3" stop-color="#F7F0E0"/>
<stop offset=".62" stop-color="#DACDB0"/><stop offset=".86" stop-color="#AE9F80"/>
<stop offset="1" stop-color="#C9BB9C"/>
</linearGradient>
<linearGradient id="shade" x1="1" y1="0" x2="0" y2="0">
<stop offset="0" stop-color="#5E5038" stop-opacity=".45"/>
<stop offset="1" stop-color="#5E5038" stop-opacity="0"/>
</linearGradient>
</defs>"""


def f(v):
    return f"{v:.1f}"


def ry(r):
    return r * TILT


def side_path(points, sign):
    """A smooth curve through the profile points on one side of the axis."""
    xs = [(CX + sign * r, y) for y, r in points]
    d = ""
    for i in range(1, len(xs)):
        p0 = xs[i - 2] if i >= 2 else xs[i - 1]
        p1, p2 = xs[i - 1], xs[i]
        p3 = xs[i + 1] if i + 1 < len(xs) else xs[i]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{f(c1[0])} {f(c1[1])} {f(c2[0])} {f(c2[1])} {f(p2[0])} {f(p2[1])}"
    return d


def segment(points, ledge=True, spec=True):
    """One lathe segment from its profile [(y, r), ...] top to bottom."""
    (ty, tr), (by, br) = points[0], points[-1]
    left = side_path(points, -1)
    right_pts = list(reversed(points))
    right = side_path(right_pts, +1)
    d = (
        f"M{f(CX - tr)} {f(ty)}{left}"
        f" A{f(br)} {f(ry(br))} 0 0 0 {f(CX + br)} {f(by)}"
        f"{right}"
        f" A{f(tr)} {f(ry(tr))} 0 0 0 {f(CX - tr)} {f(ty)} Z"
    )
    out = [f'<path d="{d}" fill="url(#body)"/>']
    if spec and by - ty > 8:
        sx = CX - min(r for _, r in points) * 0.5 - 1
        out.append(
            f'<rect x="{f(sx)}" y="{f(ty + 2)}" width="2.4" '
            f'height="{f(by - ty - 3)}" rx="1.2" fill="url(#spec)"/>'
        )
    if ledge:
        out.append(
            f'<ellipse cx="{f(CX)}" cy="{f(ty)}" rx="{f(tr)}" ry="{f(ry(tr))}" '
            f'fill="url(#top)"/>'
        )
    return out


def contact(y, r):
    """The soft shadow where a narrower part stands on a ledge."""
    return [
        f'<ellipse cx="{f(CX + 1)}" cy="{f(y + 0.6)}" rx="{f(r + 4)}" '
        f'ry="{f(ry(r) + 2.4)}" fill="url(#ao)"/>'
    ]


def ball(cx, cy, r):
    return [
        f'<ellipse cx="{f(cx + r * 0.15)}" cy="{f(cy + r * 0.95)}" rx="{f(r * 0.9)}" '
        f'ry="{f(r * 0.3)}" fill="url(#ao)"/>',
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="url(#ball)"/>',
        f'<ellipse cx="{f(cx - r * 0.38)}" cy="{f(cy - r * 0.42)}" rx="{f(r * 0.26)}" '
        f'ry="{f(r * 0.18)}" fill="#fff" fill-opacity=".9"/>',
    ]


def stack(parts):
    """Segments from the bottom up, each casting its contact shadow."""
    out = []
    below = None
    for pts in parts:
        if below is not None:
            out += contact(pts[-1][0], pts[-1][1])
        out += segment(pts)
        below = pts
    return out


BASE = [
    [(112, 38), (117, 38.6), (122, 38)],  # foot
    [(103, 30), (107, 32.5), (112, 34)],  # plinth
]


def floor():
    return ['<ellipse cx="53" cy="124" rx="44" ry="10" fill="url(#floor)"/>']


def pawn():
    out = floor() + stack(BASE + [
        [(96, 21), (99, 23.5), (103, 24.5)],
        [(68, 9.5), (78, 11), (88, 15), (96, 19)],
        [(63, 17), (65.5, 17.6), (68, 16.5)],
    ])
    out += contact(60, 10)
    out += ball(CX, 46, 16.5)
    return out


def rook():
    out = floor() + stack(BASE + [
        [(96, 24), (99, 25.5), (103, 26)],
        [(50, 19), (66, 18), (82, 19.5), (96, 23)],
        [(44, 22), (47, 24.5), (50, 23.5)],
        [(26, 27), (35, 26.5), (44, 25.5)],
    ])
    # The hollow top and the battlements around it.
    out.append(
        f'<ellipse cx="{f(CX)}" cy="26" rx="21" ry="{f(ry(21))}" fill="url(#hole)"/>'
    )
    for x0 in (24.5, 38.5, 52.5, 66.5):
        w = 9.5
        out.append(
            f'<path d="M{f(x0)} 16 L{f(x0)} 27.5 Q{f(x0 + w / 2)} 29 {f(x0 + w)} 27.5 '
            f'L{f(x0 + w)} 16 Z" fill="url(#body)"/>'
        )
        out.append(
            f'<rect x="{f(x0)}" y="14.2" width="{f(w)}" height="3.4" rx="1.4" '
            f'fill="url(#top)"/>'
        )
    out.append('<rect x="30" y="31" width="2.4" height="11" rx="1.2" fill="url(#spec)"/>')
    return out


def bishop():
    out = floor() + stack(BASE + [
        [(96, 21), (99, 23.5), (103, 24.5)],
        [(62, 8.5), (74, 10.5), (86, 15), (96, 19.5)],
        [(56, 15), (58.5, 15.8), (62, 14.5)],
        [(52, 10), (54, 11), (56, 10)],
    ])
    out += contact(50, 9)
    # The mitre: an egg standing on the collar, with its slit.
    out.append(
        '<path d="M50 18 C61 22 66 34 63 43 C61 49 56 52 50 52 C44 52 39 49 37 43 '
        'C34 34 39 22 50 18 Z" fill="url(#ball)"/>'
    )
    out.append(
        '<path d="M57 25 L47 38" stroke="#7A6D52" stroke-width="3.4" '
        'stroke-linecap="round"/>'
    )
    out.append(
        '<path d="M56.2 24.2 L46.2 37.2" stroke="#fff" stroke-opacity=".75" '
        'stroke-width="1.1" stroke-linecap="round" transform="translate(-1.6 0.4)"/>'
    )
    out.append('<ellipse cx="43" cy="30" rx="2.6" ry="5.5" fill="#fff" fill-opacity=".8" '
               'transform="rotate(18 43 30)"/>')
    out += ball(CX, 14.5, 5.2)
    return out


def crowned(top_parts, cup, pearls):
    out = floor() + stack(BASE + [
        [(96, 22), (99, 24.5), (103, 25.5)],
        [(50, 9.5), (64, 11.5), (82, 16), (96, 21)],
    ] + top_parts)
    return out


def queen():
    out = crowned([
        [(45, 16), (47.5, 17), (50, 15.5)],
        [(40, 12.5), (42.5, 13.2), (45, 12)],
        [(23, 20.5), (29, 17), (35, 13.5), (40, 11.5)],
    ], None, None)
    # Pearls around the rim, the back ones first and smaller.
    import math
    back = [math.pi + i * math.pi / 6 for i in range(1, 6)]
    front = [i * math.pi / 6 for i in range(0, 7)]
    for t in back:
        x, y = CX + 19 * math.cos(t), 23 + ry(19) * math.sin(t)
        out += ball(x, y - 2.2, 2.6)
    out.append(
        f'<ellipse cx="{f(CX)}" cy="23" rx="16" ry="{f(ry(16))}" fill="url(#hole)"/>'
    )
    out += segment([(14, 8), (18, 11), (23, 12)])
    for t in front:
        x, y = CX + 19.5 * math.cos(t), 23 + ry(19.5) * math.sin(t)
        out += ball(x, y - 2.6, 3.2)
    out += ball(CX, 10.5, 4.8)
    return out


def king():
    out = crowned([
        [(44, 17), (47, 18), (50, 16.5)],
        [(38, 13.5), (41, 14.3), (44, 13)],
        [(25, 18.5), (30, 16), (38, 12.5)],
    ], None, None)
    out += segment([(17, 9), (20, 14), (25, 18)])
    # The cross, with a lit left face and a shaded right one.
    out.append('<path d="M46.4 2.5 h7.2 v5.2 h5.4 v6.4 h-5.4 v6 h-7.2 v-6 h-5.4 '
               'v-6.4 h5.4 Z" fill="url(#body)"/>')
    out.append('<path d="M53.6 2.5 v5.2 h5.4 v6.4 h-5.4 v6 l1.4 -1 v-4.4 h5.4 '
               'v-6.4 l-1.4 1" fill="#8E8063" fill-opacity=".55"/>')
    out.append('<rect x="47.6" y="3.6" width="2" height="15" rx="1" fill="#fff" '
               'fill-opacity=".8"/>')
    return out


def knight():
    out = floor() + stack(BASE + [[(96, 24), (99, 26.5), (103, 27.5)]])
    out += contact(96, 22)
    horse = ("M29 99 C26 82 31 64 43 49 C41 45 38 40 36 34 C40 33 44 35 46 37 "
             "C46 30 49 22 54 15 C56 20 58 24 59 27 C70 31 79 42 82 56 "
             "C84 63 83 70 79 74 C76 77 71 76 69 72 C67 69 65 67 62 67 "
             "C64 77 69 88 73 99 C66 102 36 102 29 99 Z")
    out.append(f'<path d="{horse}" fill="url(#horse)"/>')
    # Shadow on the far side of the neck and under the jaw.
    out.append('<path d="M73 99 C69 88 64 77 62 67 C65 67 67 69 69 72 C64 74 '
               '66 86 73 99 Z" fill="url(#shade)"/>')
    out.append('<path d="M82 56 C84 63 83 70 79 74 C76 77 71 76 69 72 C74 73 78 '
               '70 79 64 Z" fill="#7E7053" fill-opacity=".35"/>')
    # Mane: a carved band along the back of the neck, with tufts.
    out.append('<path d="M47 37 C41 45 35 57 34 69 C33 80 34 90 36 98" '
               'stroke="#9B8D6E" stroke-opacity=".6" stroke-width="2.4" fill="none" '
               'stroke-linecap="round"/>')
    out.append('<path d="M48.6 37.8 C42.6 45.8 36.8 57.6 35.8 69.4 C34.8 80 35.8 90 37.8 97" '
               'stroke="#fff" stroke-opacity=".75" stroke-width="1.2" fill="none" '
               'stroke-linecap="round"/>')
    for y, x in ((46, 40), (56, 35.5), (67, 33), (78, 32.4), (89, 33.2)):
        out.append(f'<path d="M{x} {y} q-3 3 -4.6 6.4" stroke="#9B8D6E" '
                   'stroke-opacity=".55" stroke-width="1.8" fill="none" '
                   'stroke-linecap="round"/>')
    # Ear, eye, nostril and mouth.
    out.append('<path d="M54 15 C56 20 58 24 59 27 C56 26 53 25 51 25 C51 21 52 18 54 15 Z" '
               'fill="#fff" fill-opacity=".6"/>')
    out.append('<ellipse cx="62" cy="41" rx="5" ry="3.6" fill="#8C7E61" fill-opacity=".45"/>')
    out.append('<ellipse cx="62.4" cy="41.4" rx="2.9" ry="2.4" fill="#2A2116"/>')
    out.append('<circle cx="61.4" cy="40.5" r="0.95" fill="#fff"/>')
    out.append('<ellipse cx="77" cy="63" rx="2.4" ry="1.7" fill="#5C4F38" '
               'transform="rotate(-25 77 63)"/>')
    out.append('<path d="M70 71 C73 72 76 71.5 78.5 70" stroke="#6E6148" '
               'stroke-opacity=".7" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    # Highlights on the forehead, muzzle and chest.
    out.append('<path d="M60 31 C68 35 74 42 77 51" stroke="#fff" stroke-opacity=".85" '
               'stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    out.append('<path d="M37 92 C34 80 36 67 44 55" stroke="#fff" stroke-opacity=".7" '
               'stroke-width="3" fill="none" stroke-linecap="round"/>')
    return out


PIECES = {"P": pawn, "R": rook, "B": bishop, "Q": queen, "K": king, "N": knight}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in PIECES.items():
        body = "\n".join(draw())
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 135" '
            f'width="100" height="135">{DEFS}\n{body}</svg>\n'
        )
        (OUT / f"{name}.svg").write_text(svg)
        print(f"wrote {OUT / name}.svg")


if __name__ == "__main__":
    main()
