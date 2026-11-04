#!/usr/bin/env python3
"""
Crop the Hinds County portraits to 600x750 (4:5), placing each crop from a MEASURED face box.

Same contract as the Jackson wave (scripts/jackson-process-portraits.py), plus a border trim.

CONTROLS, all watched FAILING before use:
  * flat grey must yield NO face, so the detector can report absence;
  * the border trimmer must find a planted noisy frame and must leave an unframed image, and a
    dark TEXTURED image, untouched (deframe._control);
  * channel spread is measured, because a monochrome portrait is a defect.
"""
import json, os, sys, argparse
import cv2
import numpy as np
from PIL import Image, ImageOps
from hinds_deframe import border_box, _control as deframe_control

sys.stdout.reconfigure(encoding='utf-8')
ap = argparse.ArgumentParser(); ap.add_argument('--dir', default='.')
args = ap.parse_args()
os.chdir(args.dir)
OUT = 'processed'
os.makedirs(OUT, exist_ok=True)

cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
if cascade.empty():
    sys.exit('CONTROL FAILED: cascade did not load')

blank = np.full((780, 720), 128, dtype=np.uint8)
if len(cascade.detectMultiScale(blank, 1.1, 5)) != 0:
    sys.exit('CONTROL FAILED: the detector found a face in flat grey')
print('CONTROL OK  flat grey yields no face, so the detector can report absence')
deframe_control()
print('CONTROL OK  the border trimmer finds a planted frame, and spares unframed/dark-textured')

man = json.load(open('hc-manifest.json'))
rows = []
for p in man:
    src = next((f'src/{p["key"]}{e}' for e in ('.jpg', '.jpeg', '.png')
                if os.path.exists(f'src/{p["key"]}{e}')), None)
    if not src:
        print(f'  MISSING SOURCE  {p["key"]}'); continue

    img = ImageOps.exif_transpose(Image.open(src))
    if img.mode in ('RGBA', 'LA', 'P'):
        img = img.convert('RGBA')
        img = Image.alpha_composite(Image.new('RGBA', img.size, (255, 255, 255, 255)), img)
    img = img.convert('RGB')
    ow, oh = img.size

    # Trim a decorative frame. The Atlanta ruling makes a framed source a defect, and no numeric
    # check this repo owns can see one -- licence, resolution, spread and face box all pass it.
    a0 = np.array(img)
    bl, bt, br, bb = border_box(a0)
    framed = (bl, bt, br, bb) != (0, 0, ow, oh)
    if framed:
        img = img.crop((bl, bt, br, bb))
    border_px = f'L{bl} T{bt} R{ow-br} B{oh-bb}' if framed else ''

    w, h = img.size
    arr = np.array(img)
    spread = float(np.mean(arr.max(axis=2).astype(int) - arr.min(axis=2).astype(int)))

    # Normalise the longest edge into 400-1200px before detecting: a face FILLING a huge frame
    # scores like no face at all (the detector failed on the BEST source, not the worst).
    scale = 1.0
    le = max(w, h)
    if le > 1200: scale = 1200 / le
    elif le < 400: scale = 400 / le
    det = np.array(img.resize((max(1, int(w*scale)), max(1, int(h*scale))), Image.LANCZOS))
    gray = cv2.cvtColor(det, cv2.COLOR_RGB2GRAY)
    faces = cascade.detectMultiScale(gray, 1.08, 6,
                                     minSize=(int(det.shape[1]*0.10), int(det.shape[1]*0.10)))
    n_faces = len(faces)
    if n_faces:
        fx, fy, fw, fh = sorted(faces, key=lambda f: f[2]*f[3])[-1]
        fx, fy, fw, fh = [int(round(v/scale)) for v in (fx, fy, fw, fh)]
        face = f'{fw}x{fh} at ({fx},{fy})'
    else:
        fx = fy = fw = fh = None
        face = 'NONE FOUND'

    tr = 4/5
    if w/h > tr: nw, nh = int(h*tr), h
    else:        nw, nh = w, int(w/tr)
    if fw:
        left = int(round(fx + fw/2 - nw/2))
        top  = int(round(fy - 0.6*fh))        # headroom above the hairline; never centred
    else:
        left, top = (w-nw)//2, (h-nh)//2
    left = max(0, min(left, w-nw)); top = max(0, min(top, h-nh))

    out = img.crop((left, top, left+nw, top+nh)).resize((600, 750), Image.LANCZOS)
    dest = f'{OUT}/{p["key"]}.jpg'
    out.save(dest, 'JPEG', quality=90)

    upscale = round(600/nw, 3)
    hair_pct = round(100*(top and 0 or 0), 1)
    rows.append({**p, 'orig_w': ow, 'orig_h': oh, 'src_w': w, 'src_h': h,
                 'border_trimmed': border_px, 'face': face, 'n_faces': n_faces,
                 'spread': round(spread, 1), 'crop': f'{nw}x{nh}+{left}+{top}',
                 'upscale': upscale, 'processed': dest, 'src_file': src})
    flags = []
    if not fw: flags.append('NO FACE DETECTED')
    if n_faces > 1: flags.append(f'{n_faces} faces')
    if spread < 12: flags.append('MONOCHROME')
    if upscale > 1.0: flags.append(f'UPSCALED x{upscale}')
    if border_px: flags.append(f'frame trimmed {border_px}')
    print(f'{p["key"]:16} {ow}x{oh} -> {nw}x{nh}+{left}+{top}  face {face:20} '
          f'spread {spread:5.1f}  x{upscale}' + ('   !! ' + '; '.join(flags) if flags else ''))

json.dump(rows, open('processed.json', 'w'), indent=1)
print(f'\nwrote {len(rows)} crops')
