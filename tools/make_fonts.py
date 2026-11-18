#!/usr/bin/env python3
"""Generate the big stopwatch digit fonts (BMFont text format + PNG) used by
SplitWatchView. Only the characters 0-9 : . are included.

    python3 tools/make_fonts.py

One set per screen size, in fonts/<set>/ (picked per watch in monkey.jungle).

Each font is cropped so its line height equals the digit height, so
TEXT_JUSTIFY_VCENTER centres the digits exactly.
"""
import os
from PIL import Image, ImageDraw, ImageFont

TTF = "/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Bold.ttf"
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "fonts")
# Per screen size: digit heights in pixels, biggest first. Ids are Big0..BigN.
SETS = {
# The smallest ones are for the hundredths, drawn smaller after a stopped
# time over a minute (SplitWatchView uses the size 3 steps down).
    "240": [116, 100, 88, 78, 68, 60, 52, 46, 40],          # Forerunner 945 (240x240)
    "454": [220, 190, 166, 147, 128, 113, 98, 87, 76],      # Forerunner 965 (454x454)
    "215x180": [96, 84, 74, 64, 56, 48, 42, 37, 32],        # Forerunner 735XT (215x180)
}
CHARS = "0123456789:."
GAP = 2                      # pixels between glyphs in the sheet
PUNCT_SIDE = 4               # side bearing kept around ':' and '.'
DIGIT_SPACING = 4            # extra space between digits


def make(OUT, idx, digit_h):
    # Find the point size that gives the wanted height for '8'.
    size = digit_h
    for _ in range(40):
        f = ImageFont.truetype(TTF, size)
        l, t, r, b = f.getbbox("8")
        h = b - t
        if h == digit_h:
            break
        size = max(1, round(size * digit_h / h))
    f = ImageFont.truetype(TTF, size)
    _, top8, _, bot8 = f.getbbox("8")

    digit_adv = max(f.getmask(d).getbbox()[2] - f.getmask(d).getbbox()[0] for d in "0123456789") + DIGIT_SPACING

    glyphs = []
    pad = digit_h
    for ch in CHARS:
        canvas = Image.new("L", (digit_h * 2, digit_h * 3), 0)
        ImageDraw.Draw(canvas).text((pad // 2, pad), ch, font=f, fill=255)
        l, t, r, b = canvas.getbbox()          # real ink box
        img = canvas.crop((l, t, r, b))
        w = r - l
        yoff = (t - pad) - top8
        if ch.isdigit():
            xoff = (digit_adv - w) // 2
            adv = digit_adv
        else:
            xoff = PUNCT_SIDE
            adv = w + 2 * PUNCT_SIDE
        glyphs.append((ch, img, xoff, yoff, adv))

    sheet_w = sum(g[1].width + GAP for g in glyphs)
    sheet_h = max(g[1].height for g in glyphs)
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    x = 0
    lines = []
    for ch, img, xoff, yoff, adv in glyphs:
        white = Image.new("RGBA", img.size, (255, 255, 255, 255))
        white.putalpha(img)
        sheet.paste(white, (x, 0))
        lines.append(
            f"char id={ord(ch)} x={x} y=0 width={img.width} height={img.height} "
            f"xoffset={xoff} yoffset={yoff} xadvance={adv} page=0 chnl=15"
        )
        x += img.width + GAP

    name = f"big{idx}"
    sheet.save(os.path.join(OUT, name + ".png"))
    line_h = bot8 - top8
    with open(os.path.join(OUT, name + ".fnt"), "w") as fh:
        fh.write(f'info face="SplitWatchBig" size={size} bold=1 italic=0 charset="" unicode=1 '
                 f'stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing={GAP},0\n')
        fh.write(f"common lineHeight={line_h} base={line_h} scaleW={sheet_w} scaleH={sheet_h} pages=1 packed=0\n")
        fh.write(f'page id=0 file="{name}.png"\n')
        fh.write(f"chars count={len(lines)}\n")
        fh.write("\n".join(lines) + "\n")
    print(name, "height", line_h, "pt", size, "digit advance", digit_adv)


if __name__ == "__main__":
    for name, heights in SETS.items():
        out = os.path.join(ROOT, name)
        os.makedirs(out, exist_ok=True)
        for i, h in enumerate(heights):
            make(out, i, h)
        with open(os.path.join(out, "fonts.xml"), "w") as fh:
            fh.write("<fonts>\n")
            for i in range(len(heights)):
                fh.write(f'    <font id="Big{i}" filename="big{i}.fnt" antialias="true" filter="0123456789:." />\n')
            fh.write("</fonts>\n")
