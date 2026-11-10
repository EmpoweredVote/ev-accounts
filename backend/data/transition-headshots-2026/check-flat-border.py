# Is there a flat RING of constant colour around the whole perimeter?
# A border is (a) uniform along its length, (b) the same on all four sides, (c) distinct
# from the interior. "Distance to the first brightness change" is NOT a border test: on any
# graduated studio backdrop it fires metres inside the frame. That was the first attempt.
import sys, json, os
sys.path.insert(0, r'C:/EV-Accounts/backend/scripts'); sys.path.insert(0, r'C:/EV-Accounts/backend/scripts/lib')
from headshot_crop import crop_4x5, flatten
from PIL import Image
import numpy as np

def ring_report(img, depth=6):
    a = np.array(flatten(img).convert('RGB')).astype(float)
    H, W = a.shape[:2]
    d = max(2, int(min(H, W) * depth / 600))
    sides = {'top': a[:d, :, :].reshape(-1, 3), 'bottom': a[-d:, :, :].reshape(-1, 3),
             'left': a[:, :d, :].reshape(-1, 3), 'right': a[:, -d:, :].reshape(-1, 3)}
    means = {k: v.mean(axis=0) for k, v in sides.items()}
    sds = {k: v.std(axis=0).mean() for k, v in sides.items()}
    interior = a[H//4:3*H//4, W//4:3*W//4, :].reshape(-1, 3).mean(axis=0)
    # all four sides agree with each other?
    ms = np.array(list(means.values()))
    side_spread = float(np.abs(ms - ms.mean(axis=0)).max())
    flatness = float(max(sds.values()))                       # low = uniform along its length
    contrast = float(np.abs(ms.mean(axis=0) - interior).max())
    framed = flatness < 12 and side_spread < 14 and contrast > 35
    return dict(depth=d, flatness=round(flatness,1), side_spread=round(side_spread,1),
                contrast=round(contrast,1), framed=framed)

HS = r'C:/Users/Chris/AppData/Local/Temp/claude/eef8bd18862e071c/3b53d4ba-6009-4448-9795-250c951cec78/scratchpad/hs'
print('CONTROLS (the detector must go RED on the first and GREEN on the second):')
ctl = [('Lee ORIGINAL, known 505px black border', HS + '/jpg/wvwd_lee_nat.jpg', True),
       ('Lee DE-BORDERED, same photograph',       HS + '/src/wvwd_lee_deborder.jpg', False)]
ok = True
for label, path, want in ctl:
    r = ring_report(Image.open(path))
    got = r['framed']
    mark = 'PASS' if got == want else 'CONTROL FAILED'
    if got != want: ok = False
    print(f"  {label:42} flat={r['flatness']:>5} spread={r['side_spread']:>5} contrast={r['contrast']:>5} framed={got}  want={want}  {mark}")
if not ok:
    print('\nthe controls did not behave -- the scan below proves nothing'); sys.exit(1)

print('\nTHE 14 PRODUCTION CROPS:')
rows = [c for c in json.load(open(HS + '/sheet-input.json', encoding='utf-8')) if c.get('bytes_from')]
bad = 0
for c in rows:
    img, _ = crop_4x5(Image.open(c['bytes_from']), **c.get('crop', {}))
    r = ring_report(img.resize((600, 750), Image.LANCZOS))
    if r['framed']: bad += 1
    print(f"  {c['name'][:22]:24} flat={r['flatness']:>5} spread={r['side_spread']:>5} contrast={r['contrast']:>5}  {'BORDER' if r['framed'] else 'no border'}")
print(f"\nframes carrying a flat border ring: {bad} of {len(rows)}")
