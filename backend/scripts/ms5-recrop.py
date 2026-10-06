#!/usr/bin/env python3
"""
Re-crop the three Harrison County supervisor portraits the operator flagged.

Each is published inside a DECORATIVE FRAME -- a white margin with a grey drop shadow -- which
is not part of the photograph. Trimming it is not a style choice: the frame was being counted as
picture, so the 4:5 crop was framing a border and the upscale factor was computed against it.

Two steps, both measured rather than eyeballed:
  1. TRIM THE FRAME. Walk in from each edge while the row or column is near-uniform and light
     (low saturation, low variance, high value). That describes the white margin and its grey
     shadow, and stops at the first row that carries real picture.
  2. ZOOM TO THE SUBJECT. Inside the trimmed picture, find the columns that hold content that is
     not the studio backdrop, then take a 4:5 box around the subject with headroom above.

CONTROL: the trim is run against a portrait known to have NO frame (Dan Cuevas, 2000x3000 straight
from a camera). It must trim nothing. A trimmer that always finds a border is not measuring one.
"""
from PIL import Image, ImageChops
import os, json, colorsys

SRC = 'data/seed-ms-2026/_assets/harrison'
OUT = 'data/seed-ms-2026/_assets/harrison-processed'
CMP = 'data/seed-ms-2026/_assets/recrop'
os.makedirs(CMP, exist_ok=True)


def row_stats(px, w, y):
    vals = [px[x, y] for x in range(w)]
    lum = [(0.299 * r + 0.587 * g + 0.114 * b) for r, g, b in vals]
    sat = [max(c) - min(c) for c in vals]
    mean = sum(lum) / len(lum)
    var = sum((v - mean) ** 2 for v in lum) / len(lum)
    return mean, var ** 0.5, sum(sat) / len(sat)


def col_stats(px, h, x):
    vals = [px[x, y] for y in range(h)]
    lum = [(0.299 * r + 0.587 * g + 0.114 * b) for r, g, b in vals]
    sat = [max(c) - min(c) for c in vals]
    mean = sum(lum) / len(lum)
    var = sum((v - mean) ** 2 for v in lum) / len(lum)
    return mean, var ** 0.5, sum(sat) / len(sat)


def is_frame(mean, sd, sat):
    """A frame row: light, flat and colourless. Real picture fails at least one."""
    return mean > 150 and sd < 34 and sat < 26


def trim_frame(img, cap=0.22):
    """Trim the decorative border. Never removes more than `cap` of a dimension."""
    px = img.load(); w, h = img.size
    top, bot, left, right = 0, h - 1, 0, w - 1
    while top < int(h * cap) and is_frame(*row_stats(px, w, top)): top += 1
    while bot > h - int(h * cap) and is_frame(*row_stats(px, w, bot)): bot -= 1
    while left < int(w * cap) and is_frame(*col_stats(px, h, left)): left += 1
    while right > w - int(w * cap) and is_frame(*col_stats(px, h, right)): right -= 1
    return (left, top, right + 1, bot + 1)


def subject_box(img):
    """Columns/rows holding something other than a plain pale backdrop."""
    px = img.load(); w, h = img.size
    cols = [x for x in range(w) if not is_frame(*col_stats(px, h, x))]
    rows = [y for y in range(h) if not is_frame(*row_stats(px, w, y))]
    if not cols or not rows:
        return (0, 0, w, h)
    return (min(cols), min(rows), max(cols) + 1, max(rows) + 1)


def crop_45_on(img, box, head_room=0.16):
    """A 4:5 box around `box`, with headroom above the subject, clamped inside the image."""
    w, h = img.size
    x0, y0, x1, y1 = box
    cx = (x0 + x1) / 2
    sh = (y1 - y0)
    ch = min(h, sh * (1 + head_room))
    cw = ch * 0.8
    if cw > w:
        cw = w; ch = cw / 0.8
    top = max(0, min(h - ch, y0 - sh * head_room))
    left = max(0, min(w - cw, cx - cw / 2))
    return (int(left), int(top), int(left + cw), int(top + ch))


TARGETS = [
    ('d2', 'Rebecca Powers', '699afdf5-18f8-4ad7-92d6-04b466fcd8fa'),
    ('d3', 'Marlin Ladner', 'e304bc6f-805e-405c-8af8-f98df3bd79ee'),
    ('d4', 'Kent Jones', '01cc7a9d-f427-49c2-ba90-928163a4eaad'),
]

# --- CONTROL: a frameless portrait must survive untrimmed ---
ctl = Image.open(f'{SRC}/d1.jpg').convert('RGB')
small = ctl.resize((ctl.width // 6, ctl.height // 6), Image.LANCZOS)
cb = trim_frame(small)
trimmed_ctl = (cb[0], cb[1], small.width - cb[2], small.height - cb[3])
print('CONTROL (Dan Cuevas, no frame): trimmed L%d T%d R%d B%d  -> %s'
      % (cb[0], cb[1], small.width - cb[2], small.height - cb[3],
         'correct, nothing trimmed' if max(trimmed_ctl) <= 2 else 'TRIMMED A FRAME THAT IS NOT THERE'))
print()

rows = []
for slug, name, pid in TARGETS:
    im = Image.open(f'{SRC}/{slug}.jpg').convert('RGB')
    w0, h0 = im.size
    fb = trim_frame(im)
    inner = im.crop(fb)
    sb = subject_box(inner)
    cb2 = crop_45_on(inner, sb)
    final = inner.crop(cb2).resize((600, 750), Image.LANCZOS)
    final.save(f'{OUT}/{pid}-headshot.jpg', 'JPEG', quality=90)
    final.save(f'{CMP}/{slug}-after.jpg', 'JPEG', quality=90)
    # the previous version, for the comparison sheet
    old = im.copy()
    tr = 4 / 5
    ow, oh = old.size
    if ow / oh > tr:
        nw = int(oh * tr); old = old.crop(((ow - nw) // 2, 0, (ow - nw) // 2 + nw, oh))
    else:
        nh = int(ow / tr); old = old.crop((0, (oh - nh) // 2, ow, (oh - nh) // 2 + nh))
    old.resize((600, 750), Image.LANCZOS).save(f'{CMP}/{slug}-before.jpg', 'JPEG', quality=90)
    eff = cb2[2] - cb2[0]
    print(f'{slug} {name:<16} {w0}x{h0} -> frame trim {fb} -> subject {sb} -> crop {cb2}'
          f'  effective width {eff}px, upscale {600/eff:.2f}x')
    rows.append({'slug': slug, 'name': name, 'politician_id': pid,
                 'src': [w0, h0], 'frame_trim': fb, 'crop': list(cb2),
                 'effective_w': eff, 'upscale': round(600 / eff, 2)})

json.dump(rows, open('data/seed-ms-2026/_assets/recrop.json', 'w'), indent=2)

# side-by-side sheet
sheet = Image.new('RGB', (600 * 2 + 30, 750 * 3 + 40), (245, 243, 238))
for i, (slug, name, pid) in enumerate(TARGETS):
    sheet.paste(Image.open(f'{CMP}/{slug}-before.jpg'), (10, 10 + i * 760))
    sheet.paste(Image.open(f'{CMP}/{slug}-after.jpg'), (620, 10 + i * 760))
sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS).save(f'{CMP}/compare.png')
print('\nwrote', f'{CMP}/compare.png', '(left = before, right = after)')
