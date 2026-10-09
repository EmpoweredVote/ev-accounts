#!/usr/bin/env python3
"""
Prove each 2025/08 full-size portrait IS the person the page captions, instead of trusting
a filename that is already known to lie.

The page displays a small 2025/06 thumbnail directly beside the caption "Ward N <Name>",
and that thumbnail LINKS to the 2025/08 -scaled original. So if a thumbnail matches its
linked original, the caption's binding carries to the big file. Ward 6 is the case that
matters: its original is named Ward-6-Kenny-GLAVIN and its thumbnail is named
Kenny-Glavin-Ward-5 -- two different wrong labels on one man.

Method: downscale both to a common size, mean absolute difference per pixel.
CONTROLS: every thumbnail is also compared against a DIFFERENT ward's original. If the
matched pairs do not score far below the mismatched ones, the comparison is blind.
"""
import io, json, urllib.request
from PIL import Image

UA = {'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)'}
B = 'https://biloxi.ms.us/wp-content/uploads/'

THUMBS = {  # ward -> (thumbnail url, the caption the PAGE places beside it)
 1: (B+'2025/06/Wayne-Gray-Ward-1.jpg',            'Ward 1 Wayne Gray'),
 2: (B+'2025/06/Anthony-Marshall-Ward-2.jpg',      'Ward 2 Anthony Marshall'),
 3: (B+'2025/06/Mike-Nail-Ward-3.jpg',             'Ward 3 Mike Nail'),
 4: (B+'2025/06/Jamie-Creel-Ward-4.jpg',           'Ward 4 Jamie Creel'),
 5: (B+'2025/06/Ward-5-Dr.-Paul-Tisdale-240x300.jpg','Ward 5 Paul Tisdale'),
 6: (B+'2025/06/Kenny-Glavin-Ward-5.jpg',          'Ward 6 Kenny Glavan'),
 7: (B+'2025/06/David-Shoemaker-Ward-7.jpg',       'Ward 7 David Shoemaker'),
}
ORIGS = {n: f'data/seed-ms-2026/_assets/biloxi/ward{n}.jpg' for n in range(1, 8)}

def get(url):
    r = urllib.request.Request(url, headers=UA)
    return Image.open(io.BytesIO(urllib.request.urlopen(r).read())).convert('RGB')

def mad(a, b, size=(96, 120)):
    a = a.resize(size, Image.LANCZOS); b = b.resize(size, Image.LANCZOS)
    pa, pb = a.load(), b.load()
    tot = 0
    for y in range(size[1]):
        for x in range(size[0]):
            ca, cb = pa[x, y], pb[x, y]
            tot += abs(ca[0]-cb[0]) + abs(ca[1]-cb[1]) + abs(ca[2]-cb[2])
    return tot / (size[0]*size[1]*3)

thumbs = {n: get(u) for n, (u, _) in THUMBS.items()}
origs  = {n: Image.open(p).convert('RGB') for n, p in ORIGS.items()}

print('MATCHED PAIRS -- thumbnail beside the caption vs the original it links to')
matched = {}
for n in range(1, 8):
    m = mad(thumbs[n], origs[n]); matched[n] = m
    print(f'  ward {n}  {THUMBS[n][1]:<26} MAD {m:6.2f}')

print('\nCONTROLS -- each thumbnail against a DIFFERENT ward\'s original')
worst = 1e9
for n in range(1, 8):
    other = 1 if n != 1 else 2
    m = mad(thumbs[n], origs[other])
    worst = min(worst, m)
    print(f'  ward {n} thumb vs ward {other} original   MAD {m:6.2f}')

best_mismatch, worst_match = worst, max(matched.values())
print(f'\nworst MATCH {worst_match:.2f}   best MISMATCH {best_mismatch:.2f}   '
      f'separation {best_mismatch - worst_match:.2f}')
print('VERDICT:', 'SEPARATED -- the comparison can tell people apart'
      if best_mismatch > worst_match * 2 else 'NOT SEPARATED -- comparison is blind, do not rely on it')
json.dump({'matched': matched, 'best_mismatch': best_mismatch},
          open('data/seed-ms-2026/_assets/biloxi-identity.json', 'w'), indent=2)
