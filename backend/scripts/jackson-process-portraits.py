#!/usr/bin/env python3
"""
Crop the 8 Jackson portraits to 600x750 (4:5), placing each crop from a MEASURED face box.

🔴 MEASURE, DON'T EYEBALL. Biloxi's originals were exactly 4:5 so a centred crop was a no-op.
Jackson's are 720x780 (0.923) and 1140x1600 (0.713), so every one needs a real crop decision.
The face is detected and the crop placed around it, with headroom of 0.6 x face height.

🔴 NOTHING THIS REPO RUNS ASKS WHETHER A HEADSHOT CONTAINS A FACE -- a seal, a map, a blank or a
torso all pass. So detection is run here and a miss is REPORTED, not silently centre-cropped.

CONTROLS:
  * a synthetic flat-grey image must yield NO face, so the detector can report absence;
  * channel spread is measured on every image, because a monochrome portrait is a defect and
    shape and size cannot tell a face from a graphic.
"""
import json, os, sys
import cv2
import numpy as np
from PIL import Image

SP = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SP, 'jx-processed')
os.makedirs(OUT, exist_ok=True)

cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
if cascade.empty():
    sys.exit('🔴 cascade failed to load')

# ── CONTROL: a flat grey image must yield no face ────────────────────────────
blank = np.full((780, 720), 128, dtype=np.uint8)
if len(cascade.detectMultiScale(blank, 1.1, 5)) != 0:
    sys.exit('🔴 CONTROL: the detector found a face in flat grey — it cannot report absence')
print('CONTROL ✅ flat grey yields no face, so the detector can report absence')

man = json.load(open(os.path.join(SP, 'jx-manifest.json')))
rows = []
for p in man:
    src = os.path.join(SP, p['file'])
    img = Image.open(src).convert('RGB')
    w, h = img.size
    arr = np.array(img)

    # monochrome test: mean per-pixel spread across channels
    spread = float(np.mean(arr.max(axis=2).astype(int) - arr.min(axis=2).astype(int)))
    lum = float(np.mean(0.2126 * arr[:, :, 0] + 0.7152 * arr[:, :, 1] + 0.0722 * arr[:, :, 2]))

    gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
    faces = cascade.detectMultiScale(gray, 1.08, 6, minSize=(int(w * 0.10), int(w * 0.10)))
    if len(faces):
        fx, fy, fw, fh = sorted(faces, key=lambda f: f[2] * f[3])[-1]
        face = f'{fw}x{fh} at ({fx},{fy})'
    else:
        fx = fy = fw = fh = None
        face = 'NONE FOUND'

    # 4:5 crop, placed from the face when there is one
    # 🔴 FACE-PROPORTIONAL, so all eight are framed alike rather than each filling its own source.
    # The city's seven council portraits sit at face/width ~0.36-0.45; 0.40 is the target. The crop
    # is only ever made SMALLER than the source allows, never larger, so nothing is invented.
    tr = 4 / 5
    if w / h > tr:
        maxw, maxh = int(h * tr), h
    else:
        maxw, maxh = w, int(w / tr)
    # ⚠ FACE-PROPORTIONAL ZOOM WAS TRIED AND REVERTED. Normalising every face to 0.40 of the crop
    # width put FIVE of the eight into upscaling (up to 1.31x) to buy a consistency the city's own
    # set already had -- its seven council portraits sit at face/width 0.36-0.45 as published.
    # The largest crop the source allows is taken instead, so only the mayor is ever enlarged.
    nw, nh = maxw, maxh
    if fw:
        cx = fx + fw / 2
        left = int(round(cx - nw / 2))
        top = int(round(fy - 0.6 * fh))          # headroom above the hairline
    else:
        left, top = (w - nw) // 2, (h - nh) // 2
    left = max(0, min(left, w - nw))
    top = max(0, min(top, h - nh))

    out = img.crop((left, top, left + nw, top + nh)).resize((600, 750), Image.LANCZOS)
    dest = os.path.join(OUT, f"{p['key']}.jpg")
    out.save(dest, 'JPEG', quality=90)

    upscale = round(600 / nw, 3)
    rows.append({**p, 'src_w': w, 'src_h': h, 'face': face, 'spread': round(spread, 1),
                 'lum': round(lum, 1), 'crop': f'{nw}x{nh}+{left}+{top}', 'upscale': upscale,
                 'processed': f"jx-processed/{p['key']}.jpg"})
    flag = '' if fw else '   🔴 NO FACE DETECTED'
    mono = '   🔴 MONOCHROME' if spread < 12 else ''
    up = '   ⚠ UPSCALED' if upscale > 1.0 else ''
    print(f"{p['key']:6} {w}x{h} -> crop {nw}x{nh}+{left}+{top}  face {face:22} "
          f"spread {spread:5.1f}  lum {lum:5.1f}  x{upscale}{flag}{mono}{up}")

json.dump(rows, open(os.path.join(SP, 'jx-processed.json'), 'w'), indent=1)
print(f'\nwrote {len(rows)} files to {OUT}')
