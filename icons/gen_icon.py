#!/usr/bin/env python3
"""Generate the BowleramaXR synthwave bowling-ball icon set.

Emits three SVGs into icons/:
  icon_background.svg  - synthwave sky, retro sun, perspective grid (adaptive bg)
  icon_foreground.svg  - the cartoon bowling ball alone (adaptive fg)
  icon.svg             - both composed, rounded corners (editor + legacy icon)

Canvas is 432x432 to match Android's adaptive-icon spec: the art is 108dp and
only the inner 72dp survives every launcher mask, so the ball is sized to stay
inside that centred 288x288 safe zone.

Rasterise with icons/render_icons.gd (Godot/ThorVG) -- NOT ImageMagick, whose
built-in SVG renderer silently drops gradients.
"""
import pathlib

S = 432             # canvas (108dp @ 4x)
CX = S / 2          # 216
SAFE = 288          # 72dp @ 4x - adaptive-icon safe zone

HORIZON = 256       # where sky meets the grid floor
SUN_R = 155
BALL_R = 100        # 200px wide, comfortably inside SAFE
BALL_CY = 196       # nudged above centre so the sun haloes out around it

OUT = pathlib.Path(__file__).resolve().parent          # icons/
ROOT = OUT.parent                                      # project root


def defs():
    return f'''  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0.00" stop-color="#0d0420"/>
      <stop offset="0.42" stop-color="#2d1155"/>
      <stop offset="0.75" stop-color="#7d1f83"/>
      <stop offset="1.00" stop-color="#ff4d9d"/>
    </linearGradient>
    <linearGradient id="sun" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0.00" stop-color="#ffe95c"/>
      <stop offset="0.42" stop-color="#ff9a4d"/>
      <stop offset="1.00" stop-color="#ff2d95"/>
    </linearGradient>
    <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0.00" stop-color="#3a0f52"/>
      <stop offset="1.00" stop-color="#080213"/>
    </linearGradient>
    <radialGradient id="ballBody" cx="0.34" cy="0.28" r="0.88">
      <stop offset="0.00" stop-color="#5b3488"/>
      <stop offset="0.42" stop-color="#2a1450"/>
      <stop offset="1.00" stop-color="#0b0518"/>
    </radialGradient>
    <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0.00" stop-color="#ffffff" stop-opacity="0.90"/>
      <stop offset="1.00" stop-color="#8be9ff" stop-opacity="0.00"/>
    </linearGradient>
    <clipPath id="skyClip">
      <rect x="0" y="0" width="{S}" height="{HORIZON}"/>
    </clipPath>
    <clipPath id="groundClip">
      <rect x="0" y="{HORIZON}" width="{S}" height="{S - HORIZON}"/>
    </clipPath>
    <clipPath id="sunClip">
      <circle cx="{CX}" cy="{HORIZON}" r="{SUN_R}"/>
    </clipPath>
    <clipPath id="ballClip">
      <circle cx="{CX}" cy="{BALL_CY}" r="{BALL_R}"/>
    </clipPath>
  </defs>
'''


def background():
    """Sky + retro sun + perspective grid floor."""
    p = [f'  <rect x="0" y="0" width="{S}" height="{S}" fill="url(#sky)"/>']

    # Retro sun, sitting on the horizon. Wider than the ball, so it haloes out
    # around it in the composed icon rather than being eclipsed.
    p.append('  <g clip-path="url(#skyClip)">')
    p.append(f'    <circle cx="{CX}" cy="{HORIZON}" r="{SUN_R}" fill="url(#sun)"/>')

    # Scanline bands, clipped to the sun (unclipped they paint bars across the
    # sky). Fixed count keeps the easing bounded -- an unbounded shrinking gap
    # never reaches the bottom.
    p.append('    <g clip-path="url(#sunClip)">')
    bands = 8
    for i in range(bands):
        t = (i + 1) / bands                     # 0..1 descending the sun
        y = HORIZON - SUN_R + SUN_R * (0.42 + 0.58 * t ** 1.5)
        thick = 2.0 + 11.0 * t                  # thicker as they descend
        p.append(f'      <rect x="{CX - SUN_R}" y="{y:.1f}" '
                 f'width="{2 * SUN_R}" height="{thick:.1f}" '
                 f'fill="#1a0a2e" opacity="0.92"/>')
    p.append('    </g>')
    p.append('  </g>')

    # Neon horizon line.
    p.append(f'  <rect x="0" y="{HORIZON - 2}" width="{S}" height="4" '
             f'fill="#ff5ec4" opacity="0.95"/>')

    # Grid floor.
    p.append(f'  <rect x="0" y="{HORIZON}" width="{S}" height="{S - HORIZON}" '
             f'fill="url(#ground)"/>')
    p.append('  <g clip-path="url(#groundClip)" fill="none" stroke-width="2">')

    # Verticals fan out from the vanishing point.
    for i in range(-10, 11):
        p.append(f'    <line x1="{CX}" y1="{HORIZON}" x2="{CX + i * 68:.0f}" '
                 f'y2="{S}" stroke="#00e5ff" stroke-opacity="0.55"/>')

    # Horizontals: geometric spacing reads as receding distance.
    d, y = 5.0, HORIZON + 5.0
    while y < S:
        p.append(f'    <line x1="0" y1="{y:.1f}" x2="{S}" y2="{y:.1f}" '
                 f'stroke="#ff2d95" stroke-opacity="0.5"/>')
        d *= 1.45
        y += d
    p.append('  </g>')
    return "\n".join(p)


def ball():
    """Cartoon bowling ball: neon rim light, gloss, three finger holes."""
    cy = BALL_CY
    p = []

    # Neon bloom behind the silhouette.
    p.append(f'  <circle cx="{CX}" cy="{cy}" r="{BALL_R + 11}" '
             f'fill="#ff2d95" opacity="0.28"/>')
    p.append(f'  <circle cx="{CX}" cy="{cy}" r="{BALL_R + 5}" '
             f'fill="#00e5ff" opacity="0.22"/>')

    # Body.
    p.append(f'  <circle cx="{CX}" cy="{cy}" r="{BALL_R}" fill="url(#ballBody)"/>')

    # Rim light: magenta upper-right, cyan lower-left. Offset circles clipped to
    # the ball hug the silhouette like a cartoon highlight.
    p.append('  <g clip-path="url(#ballClip)">')
    p.append(f'    <circle cx="{CX + 23}" cy="{cy - 23}" r="{BALL_R - 2}" '
             f'fill="none" stroke="#ff4dae" stroke-width="8" opacity="0.8"/>')
    p.append(f'    <circle cx="{CX - 21}" cy="{cy + 21}" r="{BALL_R - 3}" '
             f'fill="none" stroke="#00e5ff" stroke-width="9" opacity="0.85"/>')
    p.append('  </g>')

    # Bold cartoon outline.
    p.append(f'  <circle cx="{CX}" cy="{cy}" r="{BALL_R}" fill="none" '
             f'stroke="#07030f" stroke-width="6"/>')

    # Gloss.
    p.append(f'  <ellipse cx="{CX - 38}" cy="{cy - 45}" rx="29" ry="19" '
             f'fill="url(#gloss)" transform="rotate(-28 {CX - 38} {cy - 45})"/>')

    # Finger holes: the classic two-up, one-down triangle, tilted.
    for dx, dy, rx, ry in [(-26, -4, 15, 13), (5, -15, 14, 12), (12, 20, 13, 11)]:
        hx, hy = CX + dx, cy + dy
        p.append(f'  <g transform="rotate(-18 {hx} {hy})">')
        p.append(f'    <ellipse cx="{hx}" cy="{hy}" rx="{rx}" ry="{ry}" '
                 f'fill="#05020b" stroke="#00e5ff" stroke-width="2.5" '
                 f'stroke-opacity="0.6"/>')
        # Inner lip so the hole reads as depth, not a sticker.
        p.append(f'    <ellipse cx="{hx - 2}" cy="{hy - 2}" rx="{rx - 5}" '
                 f'ry="{ry - 5}" fill="#241046" opacity="0.85"/>')
        p.append('  </g>')
    return "\n".join(p)


def svg(body, extra_defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" '
            f'viewBox="0 0 {S} {S}">\n{defs()}{extra_defs}{body}\n</svg>\n')


def main():
    (OUT / "icon_background.svg").write_text(svg(background()))
    (OUT / "icon_foreground.svg").write_text(svg(ball()))

    # The composed icon is the project icon, so it goes where project.godot's
    # config/icon already points.
    round_def = (f'  <defs><clipPath id="roundClip">'
                 f'<rect x="0" y="0" width="{S}" height="{S}" rx="76"/>'
                 f'</clipPath></defs>\n')
    composed = ('  <g clip-path="url(#roundClip)">\n'
                + background() + "\n" + ball() + "\n  </g>")
    (ROOT / "icon.svg").write_text(svg(composed, extra_defs=round_def))

    print(f"wrote icon_foreground.svg, icon_background.svg -> {OUT}")
    print(f"wrote icon.svg -> {ROOT}")


if __name__ == "__main__":
    main()
