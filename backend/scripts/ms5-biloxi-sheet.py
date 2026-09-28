#!/usr/bin/env python3
"""Side-by-side proof sheet: the thumbnail the page prints beside each caption, and the
full-size original that thumbnail links to. The mechanical comparison could not separate
matches from mismatches, so this is looked at."""
import io, sys, urllib.request
from PIL import Image, ImageDraw

UA = {'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)'}
B = 'https://biloxi.ms.us/wp-content/uploads/'
ROWS = [
 (1,'Ward 1 Wayne Gray',       B+'2025/06/Wayne-Gray-Ward-1.jpg'),
 (2,'Ward 2 Anthony Marshall', B+'2025/06/Anthony-Marshall-Ward-2.jpg'),
 (3,'Ward 3 Mike Nail',        B+'2025/06/Mike-Nail-Ward-3.jpg'),
 (4,'Ward 4 Jamie Creel',      B+'2025/06/Jamie-Creel-Ward-4.jpg'),
 (5,'Ward 5 Paul Tisdale',     B+'2025/06/Ward-5-Dr.-Paul-Tisdale-240x300.jpg'),
 (6,'Ward 6 Kenny Glavan',     B+'2025/06/Kenny-Glavin-Ward-5.jpg'),
 (7,'Ward 7 David Shoemaker',  B+'2025/06/David-Shoemaker-Ward-7.jpg'),
]
lo, hi = int(sys.argv[1]), int(sys.argv[2])
sel = [r for r in ROWS if lo <= r[0] <= hi]
CW, CH, PAD, LBL = 300, 375, 12, 26
sheet = Image.new('RGB', (CW*2 + PAD*3, (CH+LBL+PAD)*len(sel) + PAD), (245,245,245))
d = ImageDraw.Draw(sheet)
for i,(n,label,turl) in enumerate(sel):
    y = PAD + i*(CH+LBL+PAD)
    d.text((PAD, y), f'{label}   [left: page thumbnail]   [right: linked 2025/08 original]', fill=(0,0,0))
    t = Image.open(io.BytesIO(urllib.request.urlopen(urllib.request.Request(turl, headers=UA)).read())).convert('RGB')
    o = Image.open(f'data/seed-ms-2026/_assets/biloxi/ward{n}.jpg').convert('RGB')
    for j,im in enumerate((t,o)):
        im = im.copy(); im.thumbnail((CW,CH), Image.LANCZOS)
        sheet.paste(im, (PAD + j*(CW+PAD), y+LBL))
out = f'data/seed-ms-2026/_assets/biloxi-proof-{lo}-{hi}.png'
sheet.save(out); print('wrote', out, sheet.size)
