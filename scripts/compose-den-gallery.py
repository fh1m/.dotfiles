#!/usr/bin/env python3
"""Frame reviewed captures in the real Den layout; never reads the room photo.

Requires Pillow and DejaVu Sans. Inputs are reviewed PNGs plus optional
frames/<screen>-00.png ... sequences. Screen contents are never retouched.
"""
import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PINK = '#ff1b83'
TEXT = '#ede7ee'
MUTED = '#a599a6'
BG = '#0b090f'
SCREENS = [
    ('arete-upper', (80, 220, 1000, 562), 'ARETE / READ + DERIVE', 'Obsidian · equations · Canvas'),
    ('homie-live', (1150, 300, 1000, 562), 'HOMIE / BUILD + OBSERVE', 'Ryzen 5 · GTX 1660 SUPER · native telemetry'),
    ('arete-lower', (80, 900, 1000, 562), 'ARETE / REFERENCE + DAY', 'ROS docs · calendar · weather'),
    ('arete-main', (1280, 1000, 740, 416), 'ARETE / CODE + REVIEW', 'Neovim · tmux · Mongla on GitHub'),
    ('arete-screenpad', (1280, 1507, 740, 212), 'SCREENPAD / SMALL JOBS', ''),
]


def font(size):
    return ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans.ttf', size)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('captures', type=Path)
    parser.add_argument('--out', type=Path, default=ROOT / 'docs/assets/digital-den')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    sequences = {}
    for stem, _, _, _ in SCREENS:
        paths = sorted((args.captures / 'frames').glob(stem + '-[0-9][0-9].png'))
        if not paths:
            paths = [args.captures / (stem + '.png')]
        sequences[stem] = [Image.open(p).convert('RGB') for p in paths]
    sprites = Image.open(args.out / 'fh1m-sprites.png').convert('RGBA')
    cell = sprites.width // 2
    poses = [sprites.crop((x * cell, y * cell, (x + 1) * cell, (y + 1) * cell))
             .resize((275, 275), Image.Resampling.LANCZOS) for y in range(2) for x in range(2)]
    routes = [[(1089, 501), (1116, 501), (1116, 580), (1141, 580)],
              [(1950, 991), (1950, 946), (2110, 946), (2110, 874)]]

    def compose(index, still=False):
        canvas = Image.new('RGB', (2200, 1800), BG)
        draw = ImageDraw.Draw(canvas)
        draw.text((80, 50), 'DIGITAL DEN', font=font(58), fill=TEXT)
        if index == 13 and not still:
            # A one-frame title echo; never modifies the actual screenshots.
            draw.text((83, 51), 'DIGITAL DEN', font=font(58), fill=PINK)
        draw.text((83, 126), 'FH1M / OUT IN THE FIELD. BACK AT THE DEN.', font=font(19), fill=PINK)
        draw.line((80, 163, 2120, 163), fill='#352331', width=2)
        for number, (stem, box, title, detail) in enumerate(SCREENS):
            x, y, width, height = box
            draw.text((x, y - 34), title, font=font(19), fill=TEXT)
            draw.rounded_rectangle((x-9, y-9, x+width+9, y+height+9), radius=12,
                                   fill='#18121b', outline='#5b354e', width=2)
            images = sequences[stem]
            step = (index // 4 + (number % 2)) % len(images)
            picture = images[step].resize((width, height), Image.Resampling.LANCZOS)
            canvas.paste(picture, (x, y))
            draw.text((x, y+height+22), detail, font=font(17), fill=MUTED)
        for number, path in enumerate(routes):
            draw.line(path, fill='#54223d', width=6, joint='curve')
            draw.line(path, fill='#c52b70', width=2, joint='curve')
            lengths = [math.dist(p, q) for p, q in zip(path, path[1:])]
            distance = ((index / 8 + number * .35) % 1) * sum(lengths)
            for p, q, length in zip(path, path[1:], lengths):
                if distance <= length:
                    x = p[0] + (q[0]-p[0]) * distance/length
                    y = p[1] + (q[1]-p[1]) * distance/length
                    draw.ellipse((x-6, y-6, x+6, y+6), fill=PINK)
                    draw.ellipse((x-2, y-2, x+2, y+2), fill='#fff0f8')
                    break
                distance -= length
        canvas.paste(poses[index % 4], (795, 1480), poses[index % 4])
        draw.text((80, 1545), 'One keyboard. Two hosts.', font=font(31), fill=TEXT)
        draw.text((83, 1600), 'Five panels. Still looking for the semicolon.', font=font(21), fill=MUTED)
        line = 'read. derive. build. break. repeat.'
        shown = line if still else line[:min(len(line), index * 3 + 4)]
        draw.text((83, 1650), shown + ('' if still or index % 2 else '_'), font=font(23), fill=PINK)
        draw.text((83, 1730), 'REAL APPS / REAL WORK / ILLUSTRATIVE SIGNALS + AVATAR', font=font(15), fill=MUTED)
        return canvas

    compose(0, still=True).save(args.out / 'den-layout.png', optimize=True)
    palette = compose(0, still=True).quantize(colors=128, dither=Image.Dither.NONE)
    frames = [compose(i).quantize(palette=palette, dither=Image.Dither.NONE) for i in range(24)]
    frames[0].save(args.out / 'den-layout.gif', save_all=True, append_images=frames[1:],
                   duration=250, loop=0, optimize=False, disposal=1)
    for stem, images in sequences.items():
        images[0].save(args.out / (stem + '.png'), optimize=True)
        width = min(1440, images[0].width)
        size = (width, round(images[0].height * width / images[0].width))
        clip = [im.resize(size, Image.Resampling.LANCZOS).quantize(colors=128, dither=Image.Dither.NONE)
                for im in images]
        clip[0].save(args.out / (stem + '.gif'), save_all=True, append_images=clip[1:],
                     duration=1100, loop=0, optimize=True, disposal=2)
    for name, index in [('homie-monitor', 0), ('homie-system', 2), ('homie-code', 4)]:
        sequences['homie-live'][index].save(args.out / (name + '.png'), optimize=True)


if __name__ == '__main__':
    main()
